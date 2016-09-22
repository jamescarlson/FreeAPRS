//
//  Filter.swift
//  Modulator
//
//  Created by James on 8/21/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation
import Accelerate

enum FilterType {
    case lowpass
    case bandpass
    case highpass
    case complexbandpass
}

class FIRFilter {
    var kernel: [Float]
    fileprivate var overlapBuffer : [Float]
    var reversedKernel: [Float]
    var fftSetup: FFTSetup
    var fftSetupSize: Int
    var kernelFfts: [Int: DSPSplitComplex]

    init(kernel: [Float]) {
        self.kernel = kernel
        self.reversedKernel = kernel.reversed()
        overlapBuffer = [Float](repeating: 0.0, count: kernel.count - 1)
        print("Kernel count: \(kernel.count)")
        fftSetupSize = max(12, fftSize(forCount: kernel.count))
        kernelFfts = [Int: DSPSplitComplex]()
        fftSetup = vDSP_create_fftsetup(vDSP_Length(fftSetupSize), FFTRadix(kFFTRadix2))!
        getKernelFft(forLog2Size: fftSetupSize)
    }
    
    func getKernelFft(forLog2Size: Int) -> DSPSplitComplex {
        if let returnValue = kernelFfts[forLog2Size] {
            return returnValue
        } else {
            let originalKernelLength = kernel.count
            if originalKernelLength % 2 != 0 {
                kernel.append(0.0)
            }
            let thisFftSetup : FFTSetup = getFftSetup(forLog2Size: forLog2Size)
            var realPart : [Float] = [Float](repeating: 0, count: 1 << (forLog2Size - 1))
            var imagPart : [Float] = [Float](repeating: 0, count: 1 << (forLog2Size - 1))
            var inputArray = DSPSplitComplex(realp: &realPart, imagp: &imagPart)
            
            let ptrToKernelSamples : UnsafeRawPointer = convertToUnsafeFromFloatArray(ptr: &kernel)
            
            let dspComplexPtrToKernelSamples : UnsafePointer<DSPComplex> = ptrToKernelSamples.assumingMemoryBound(to: DSPComplex.self)
            vDSP_ctoz(dspComplexPtrToKernelSamples, 2, &inputArray, 1, vDSP_Length(kernel.count / 2))
            
            if (originalKernelLength != kernel.count) {
                kernel.removeLast()
            }
            
            var outputReal : [Float] = [Float](repeating: 0, count: 1 << (forLog2Size - 1))
            outputReal.reserveCapacity(1 << (forLog2Size - 1))
            var outputImag : [Float] = [Float](repeating: 0, count: 1 << (forLog2Size - 1))
            outputImag.reserveCapacity(1 << (forLog2Size - 1))
            var outputArray = DSPSplitComplex(realp: &outputReal, imagp: &outputImag)
            
            vDSP_fft_zrop(thisFftSetup, &inputArray, 1, &outputArray, 1, vDSP_Length(forLog2Size), -1)

            kernelFfts[forLog2Size] = outputArray
            return outputArray
        }
    }
    
    func getFftSetup(forLog2Size: Int) -> FFTSetup {
        if (fftSetupSize >= forLog2Size) {
            return fftSetup
        } else {
            fftSetupSize = forLog2Size
            fftSetup = vDSP_create_fftsetup(vDSP_Length(forLog2Size), FFTRadix(kFFTRadix2))!
            return fftSetup
        }
    }
    
    convenience init(filterType: FilterType, length: Int, fs: Int, cutoff: Float, window: [Float]) {
        assert(length == window.count)
        if (filterType == FilterType.lowpass) {
            let sincImpulse = sinc(length, fs: Float(fs), cutoff: cutoff)
            let s = slowDotProduct(sincImpulse, y: window)
            self.init(kernel: s)
        } else {
            self.init(kernel: [Float(1.0)])
        }
    }
    
    convenience init(filterType: FilterType, length: Int, fs: Int, cutoff: Float) {
        /** Create an FIR filter using a hann-windowed Sinc function. */
        let window = hann(length)
        self.init(filterType: filterType, length: length, fs: fs, cutoff: cutoff, window: window)
    }
    
    func filter(_ inputSamples: inout [Float]) -> [Float] {
        /* First need to decide whether to convolve the input with FFT or directly */
        /* For now going to do it directly */
        let useFastConvolution: Bool = true
        let useVectorizedSlowConvolution: Bool = true
        var outputSamples : [Float]
        
        let fullLength = inputSamples.count + kernel.count - 1
        var temporaryOutputBuffer = [Float](repeating: 0.0 , count: fullLength)
        
        if (useFastConvolution) {
            /* Do FFT Convolution */
            //return [Float](count: 0, repeatedValue: 0.0)
            
            let thisFftSize : Int
            if (inputSamples.count % 2 != 0) {
                inputSamples.append(0.0)
                thisFftSize = fftSize(forCount: inputSamples.count + kernel.count - 2)
            } else {
                thisFftSize = fftSize(forCount: inputSamples.count + kernel.count - 1)
            }
            
            if (fullLength % 2 != 0) {
                temporaryOutputBuffer.append(0.0)
            }
            
            // Make sure FFTSetup is big enough
            let thisFftSetup = getFftSetup(forLog2Size: thisFftSize)
            let bufferLength = 1 << thisFftSize;
            let halfBufferLength = bufferLength / 2;
            
            // Create array for FFT of input
            var temporaryInputReal = [Float](repeating: 0, count: halfBufferLength)
            var temporaryInputImag = [Float](repeating: 0, count: halfBufferLength)
            var temporaryInputComplex = DSPSplitComplex(realp: &temporaryInputReal, imagp: &temporaryInputImag)

            // Cast input Floats as a DSPComplex to be used with vDSP_ctoz
            // Allows fast interleaving setup for data
            
            let sizeofDSPComplex = MemoryLayout<DSPComplex>.size
            let sizeofFloat = MemoryLayout<Float>.size
            print(sizeofDSPComplex)
            print(sizeofFloat)
            let ptrToInputSamples : UnsafeRawPointer = convertToUnsafeFromFloatArray(ptr: &inputSamples)
            
            let dspComplexPtrToInputSamples : UnsafePointer<DSPComplex> = ptrToInputSamples.assumingMemoryBound(to: DSPComplex.self)
            vDSP_ctoz(dspComplexPtrToInputSamples, 2, &temporaryInputComplex, 1, vDSP_Length(inputSamples.count / 2))
            
            var kernelFrDomain : DSPSplitComplex = getKernelFft(forLog2Size: thisFftSize)
            
            // Create array for FFT
            var inputFrDomainReal : [Float] = [Float](repeating: 0, count: halfBufferLength)
            var inputFrDomainImag : [Float] = [Float](repeating: 0, count: halfBufferLength)
            var inputFrDomain = DSPSplitComplex(realp: &inputFrDomainReal, imagp: &inputFrDomainImag)
            
            // Do FFT on Input
            vDSP_fft_zrop(thisFftSetup, &temporaryInputComplex, 1, &inputFrDomain, 1, vDSP_Length(thisFftSize), -1)
            
            // Now multiply pointwise the Kernel FFT and the input data FFT
            // Since we have packed data, the first of which is not an actual
            // Complex number, we need to calculate that first (DC and NY component)
            // Then we will reinsert it into the old
            // temporaryInputArray
            
            let newDC = inputFrDomain.realp[0] * kernelFrDomain.realp[0]
            let newNY = inputFrDomain.imagp[0] * kernelFrDomain.imagp[0]
            
            
            vDSP_zvmul(&inputFrDomain, 1, &kernelFrDomain, 1, &temporaryInputComplex, 1, vDSP_Length(halfBufferLength), 1)
            
            temporaryInputComplex.realp[0] = newDC
            temporaryInputComplex.imagp[0] = newNY
            
            // Now do the Inverse FFT to get back our original samples
            // Put the packed data into one of the arrays we already have
            // inputFrDomain
            
            vDSP_fft_zrop(thisFftSetup, &temporaryInputComplex, 1, &inputFrDomain, 1, vDSP_Length(thisFftSize), 1)
            
            // Unpack the data using ztoc
            // Truncate the array at the point where there wouldn't have been
            // any more samples
            
            /* Side note. Swift makes working with C APIs that play fast and
               loose with types really hard. */
            let ptrToOutputSamples : UnsafeRawPointer = convertToUnsafeFromFloatArray(ptr: &temporaryOutputBuffer)
            let thisDSPComplexConst = ptrToOutputSamples.bindMemory(to: DSPComplex.self, capacity: temporaryOutputBuffer.count)
            let thisDSPComplex = UnsafeMutablePointer<DSPComplex>(mutating: thisDSPComplexConst)
            
            vDSP_ztoc(&inputFrDomain, 1, thisDSPComplex, 1, vDSP_Length(temporaryOutputBuffer.count))
            
            if (temporaryOutputBuffer.count != fullLength) {
                temporaryOutputBuffer.removeLast()
            }
            
            var scalingFactor : Float = 1.0 / (4.0 * Float(bufferLength))
            vDSP_vsmul(&temporaryOutputBuffer, 1, &scalingFactor, &temporaryOutputBuffer, 1, vDSP_Length(fullLength))
            
            for outputIndex in 0..<kernel.count - 1 {
                temporaryOutputBuffer[outputIndex] += overlapBuffer[outputIndex]
            }
            
            overlapBuffer = Array(temporaryOutputBuffer[inputSamples.count..<fullLength])
            outputSamples = Array(temporaryOutputBuffer[0..<inputSamples.count])
            return outputSamples

        } else {
            /* Do direct convolution */
            if (useVectorizedSlowConvolution) {
                /* Do vDSP Convolution */
                var temporaryLongerInputBuffer = [Float](repeating: 0.0, count: fullLength + kernel.count)
                cblas_scopy(Int32(inputSamples.count), inputSamples, 1, &temporaryLongerInputBuffer[kernel.count - 1], 1)
                
                
                vDSP_conv(&temporaryLongerInputBuffer, 1, reversedKernel, 1, &temporaryOutputBuffer, 1, vDSP_Length(fullLength), vDSP_Length(kernel.count))
                
                for outputIndex in 0..<kernel.count - 1 {
                    temporaryOutputBuffer[outputIndex] += overlapBuffer[outputIndex]
                }
                
                overlapBuffer = Array(temporaryOutputBuffer[inputSamples.count..<fullLength])
                outputSamples = Array(temporaryOutputBuffer[0..<inputSamples.count])
                return outputSamples
                
            } else {
                /* Do nonvectorized naive convolution */
                
                for outputIndex in 0..<fullLength {
                    for kernelIndex in 0..<kernel.count {
                        let inputIndex = outputIndex - kernelIndex
                        if (inputIndex >= 0 && inputIndex < inputSamples.count) {
                            temporaryOutputBuffer[outputIndex] += inputSamples[inputIndex]
                                * kernel[kernelIndex]
                        }
                    }
                }
                
                for outputIndex in 0..<kernel.count - 1 {
                    temporaryOutputBuffer[outputIndex] += overlapBuffer[outputIndex]
                }
                
                overlapBuffer = Array(temporaryOutputBuffer[inputSamples.count..<fullLength])
                outputSamples = Array(temporaryOutputBuffer[0..<inputSamples.count])
                return outputSamples
            }
        }
    }
    
}

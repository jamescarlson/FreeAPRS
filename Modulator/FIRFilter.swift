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
    var kernelFftStorage: [Int: SplitComplex]

    init(kernel: [Float]) {
        self.kernel = kernel
        self.reversedKernel = kernel.reversed()
        overlapBuffer = [Float](repeating: 0.0, count: kernel.count - 1)
        
        fftSetupSize = max(12, fftSize(forCount: kernel.count))
        
        fftSetup = vDSP_create_fftsetup(vDSP_Length(fftSetupSize),
                                        FFTRadix(kFFTRadix2))!
        
        kernelFftStorage = [Int: SplitComplex]()
    }
    
    /* Create an FIRFilter using an arbitrary window. */
    convenience init(filterType: FilterType,
                     length: Int,
                     fs: Int,
                     cutoff: Float,
                     window: [Float],
                     center: Float) {
        assert(length == window.count)
        
        let sincImpulse = sinc(length, fs: Float(fs), cutoff: cutoff)
        
        if (filterType == FilterType.lowpass) {
            
            let s = slowPointwiseMultiply(sincImpulse, y: window)
            self.init(kernel: s)
            
        } else if (filterType == FilterType.bandpass) {
            
            assert(center != 0.0)
            let modulation = cosine(length, fs: Float(fs),
                                    fc: center, centered: true)
            var s = slowPointwiseMultiply(sincImpulse, y: modulation)
            s = slowPointwiseMultiply(s, y: window)
            self.init(kernel: s)
            
        } else if (filterType == FilterType.highpass) {
            
            let modulation = cosine(length, fs: Float(fs),
                                    fc: Float(fs)/2, centered: false)
            
            var s = slowPointwiseMultiply(sincImpulse, y: modulation)
            s = slowPointwiseMultiply(s, y: window)
            self.init(kernel: s)
            
        } else {
            
            self.init(kernel: [Float(1.0)])
            
        }
    }
    
    /* Create an FIR filter using a hann-windowed Sinc function. */
    convenience init(filterType: FilterType,
                     length: Int,
                     fs: Int,
                     cutoff: Float) {
        
        assert(filterType != FilterType.bandpass)
        
        let window = hann(length)
        self.init(filterType: filterType,
                  length: length,
                  fs: fs,
                  cutoff:cutoff,
                  window: window,
                  center: 0)
    }
    
    
    convenience init(filterType: FilterType,
                     length: Int,
                     fs: Int,
                     cutoff: Float,
                     center: Float) {
        
        let window = hann(length)
        self.init(filterType: filterType,
                  length: length,
                  fs: fs,
                  cutoff:cutoff,
                  window: window,
                  center: center)
    }

    
    /* Computes or retrieves an already computed FFT of size
        FORLOG2SIZE of the kernel of this FIRFilter. */
    func getKernelFft(forLog2Size: Int) -> SplitComplex {
        
        if var returnValue = kernelFftStorage[forLog2Size] {
            
            return returnValue
            
        } else {
            
            /* May need to make kernel even length to allow vDSP_ctoz to copy
                entire length. vDSP_ctoz copies two elements at a time. */
            let originalKernelLength = kernel.count
            if originalKernelLength % 2 != 0 {
                kernel.append(0.0)
            }
            
            let halfBufferSize = 1 << (forLog2Size) - 1
            
            let thisFftSetup : FFTSetup = getFftSetup(forLog2Size: forLog2Size)
            
            var inputArray = SplitComplex(count: halfBufferSize)
            
            /* Unsafe Pointer land - here be dragons */
            let ptrToKernelSamples : UnsafeRawPointer
                = convertToUnsafeFromFloatArray(ptr: &kernel)
            let dspComplexPtrToKernelSamples : UnsafePointer<DSPComplex>
                = ptrToKernelSamples.assumingMemoryBound(to: DSPComplex.self)
 
            /* original kernel ---> deinterlaced into inputArray */
            vDSP_ctoz(dspComplexPtrToKernelSamples, 2,
                      inputArray.dspSCPtr,            1,
                      vDSP_Length(kernel.count / 2))
            
            /* Fix what we may have added earlier to make vDSP_ctoz work right. */
            if (originalKernelLength != kernel.count) {
                kernel.removeLast()
            }
            
            /* These will store the Frequency domain version of the kernel */
            var output = SplitComplex(count: halfBufferSize)
            
            /* Make sure ARC knows not to throw away the arrays */
            kernelFftStorage[forLog2Size] = output
            
            /* Do the actual FFT */
            vDSP_fft_zrop(thisFftSetup,
                          inputArray.dspSCConst,    1,
                          output.dspSCPtr,        1,
                          vDSP_Length(forLog2Size), 1)

            return output
        }
    }
    
    /* Computes or retrieves and already computed FFTSetup of size at least
        FORLOG2SIZE. */
    func getFftSetup(forLog2Size: Int) -> FFTSetup {
        if (fftSetupSize >= forLog2Size) {
            
            return fftSetup
            
        } else {
            
            fftSetupSize = forLog2Size
            
            vDSP_destroy_fftsetup(fftSetup)
            
            fftSetup = vDSP_create_fftsetup(vDSP_Length(forLog2Size),
                                            FFTRadix(kFFTRadix2))!
            return fftSetup
            
        }
    }
    
    /* Filter a set of inputSamples using the overlap-add method. Input may be
        mutated during execution but will be in its original state when finished.
    */
    func filter(_ inputSamples: inout [Float]) -> [Float] {
        /* First need to decide whether to convolve the input with FFT or directly */
        /* For now going to do it directly */
        let useFastConvolution: Bool = true
        let useVectorizedSlowConvolution: Bool = true
        var outputSamples : [Float]
        
        let originalInputLength = inputSamples.count
        let fullLength = inputSamples.count + kernel.count - 1
        var tempOutBuffer = [Float](repeating: 0.0 , count: fullLength)
        
        /* Do FFT Convolution */
        if (useFastConvolution) {

            let thisFftSize : Int
                = fftSize(forCount: originalInputLength + kernel.count - 2)
            
            /* Make sure our inputs and outputs are of even length so
             vDSP_ctoz and vDSP_ztoc copy all elements. */
            if (inputSamples.count % 2 != 0) {
                inputSamples.append(0.0)
            }
            if (fullLength % 2 != 0) {
                tempOutBuffer.append(0.0)
            }
            
            /* Make sure FFTSetup is big enough */
            let thisFftSetup = getFftSetup(forLog2Size: thisFftSize)
            let bufferLength = 1 << thisFftSize;
            let halfBufferLength = bufferLength / 2;
            
            /* Create array for FFT of input */
            var temporaryInputComplex
                = SplitComplex(count: halfBufferLength)

            /* Cast input Floats as a DSPComplex to be used with vDSP_ctoz
            Allows fast interleaving setup for data
            Unsafe pointer land -- here be dragons! */
            
            let ptrToInputSamples : UnsafeRawPointer
                = convertToUnsafeFromFloatArray(ptr: &inputSamples)
            let dspComplexPtrToInputSamples : UnsafePointer<DSPComplex>
                = ptrToInputSamples.assumingMemoryBound(to: DSPComplex.self)
            
            /* Deinterlace inputSamples into temporaryInputComplex */
            vDSP_ctoz(dspComplexPtrToInputSamples,      2,
                      temporaryInputComplex.dspSCPtr,     1,
                      vDSP_Length(inputSamples.count / 2))
            
            /* Retrieve FFT of kernel */
            var kernelFrDomain : SplitComplex
                = getKernelFft(forLog2Size: thisFftSize)
            
            /* Create space for the FFT of the input samples */
            var inputFrDomain = SplitComplex(count: halfBufferLength)
            
            /* Do the FFT of the input. */
            vDSP_fft_zrop(thisFftSetup,
                          temporaryInputComplex.dspSCConst, 1,
                          inputFrDomain.dspSCPtr,         1,
                          vDSP_Length(thisFftSize),     1)
            
            /* Now multiply pointwise the Kernel FFT and the input data FFT
            Since we have packed data, the first of which is not an actual
            Complex number, we need to calculate that first (DC and NY component)
            Then we will reinsert it into the old
            temporaryInputArray 
             
            Trying to save memory here but it does look slightly more confusing. */
            
            let newDC = inputFrDomain.real[0] * kernelFrDomain.real[0]
            let newNY = inputFrDomain.imag[0] * kernelFrDomain.imag[0]
            
            /* Do the actual multiplication */
            vDSP_zvmul(inputFrDomain.dspSCConst,          1,
                       kernelFrDomain.dspSCConst,         1,
                       temporaryInputComplex.dspSCPtr,    1,
                       vDSP_Length(halfBufferLength), 1)
            
            temporaryInputComplex.real[0] = newDC
            temporaryInputComplex.imag[0] = newNY
            
            /* Now do the Inverse FFT to get back the convolved data
            Put the packed data into one of the arrays we already have
            inputFrDomain */
            
            vDSP_fft_zrop(thisFftSetup,
                          temporaryInputComplex.dspSCConst, 1,
                          inputFrDomain.dspSCPtr,         1,
                          vDSP_Length(thisFftSize), -1)
            
            /* Yes this does look rather scary
             but Swift seems to want you to be REALLY sure that you want to use
             unsafe pointers. */
            let ptrToOutputSamples : UnsafeRawPointer
                = convertToUnsafeFromFloatArray(ptr: &tempOutBuffer)
            let thisDSPComplexConst
                = ptrToOutputSamples.bindMemory(to: DSPComplex.self,
                                                capacity: tempOutBuffer.count)
            let thisDSPComplex
                = UnsafeMutablePointer<DSPComplex>(mutating: thisDSPComplexConst)
            
            /* Unpack the data using ztoc */
            vDSP_ztoc(inputFrDomain.dspSCConst, 1,
                      thisDSPComplex,       2,
                      vDSP_Length(tempOutBuffer.count / 2))
            
            /* Fix any modifications we did to make vDSP_{ctoz|ztoc} work right */
            if (tempOutBuffer.count != fullLength) {
                tempOutBuffer.removeLast()
            }
            if (inputSamples.count != originalInputLength) {
                inputSamples.removeLast()
            }
            
            /* Scale the output back down to it's mathematical value. */
            var scalingFactor : Float = 1.0 / (4.0 * Float(bufferLength))
            vDSP_vsmul(&tempOutBuffer, 1,
                       &scalingFactor,
                       &tempOutBuffer, 1,
                       vDSP_Length(fullLength))
            
            /* Add the overlapped samples from last time. */
            for outputIndex in 0..<kernel.count - 1 {
                tempOutBuffer[outputIndex] += overlapBuffer[outputIndex]
            }
            
            /* Save the end of the output here for use in the next operation */
            overlapBuffer = Array(tempOutBuffer[originalInputLength..<fullLength])
            outputSamples = Array(tempOutBuffer[0..<originalInputLength])
            return outputSamples

        } else {
            /* Do direct convolution */
            if (useVectorizedSlowConvolution) {
                /* Do vDSP Convolution */
                
                /* Input needs to be padded on both sides */
                var tempLongerInputBuffer
                    = [Float](repeating: 0.0, count: fullLength + kernel.count)
                
                /* Copy starts part way into tempLongerInputBuffer to account
                for padding */
                cblas_scopy(Int32(inputSamples.count),
                            inputSamples,                               1,
                            &tempLongerInputBuffer[kernel.count - 1],   1)
                
                vDSP_conv(&tempLongerInputBuffer,   1,
                          reversedKernel,           1,
                          &tempOutBuffer,   1,
                          vDSP_Length(fullLength), vDSP_Length(kernel.count))
                
                /* Add in overlapping samples from last time */
                for outputIndex in 0..<kernel.count - 1 {
                    tempOutBuffer[outputIndex] += overlapBuffer[outputIndex]
                }
                
                /* Save the end of this for use in the next operation */
                overlapBuffer = Array(tempOutBuffer[inputSamples.count..<fullLength])
                outputSamples = Array(tempOutBuffer[0..<inputSamples.count])
                return outputSamples
                
            } else {
                /* Do nonvectorized naive convolution
                :( */
                
                for outputIndex in 0..<fullLength {
                    for kernelIndex in 0..<kernel.count {
                        let inputIndex = outputIndex - kernelIndex
                        if (inputIndex >= 0 && inputIndex < inputSamples.count) {
                            tempOutBuffer[outputIndex] += inputSamples[inputIndex]
                                * kernel[kernelIndex]
                        }
                    }
                }
                
                for outputIndex in 0..<kernel.count - 1 {
                    tempOutBuffer[outputIndex] += overlapBuffer[outputIndex]
                }
                
                overlapBuffer = Array(tempOutBuffer[inputSamples.count..<fullLength])
                outputSamples = Array(tempOutBuffer[0..<inputSamples.count])
                return outputSamples
            }
        }
    }
    
    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }
    
}

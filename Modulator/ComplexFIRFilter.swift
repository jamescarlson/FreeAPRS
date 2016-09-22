//
//  ComplexFIRFilter.swift
//  Modulator
//
//  Created by James on 9/21/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//
/*
import Foundation
import Accelerate

class ComplexFIRFilter {
    var kernel : [DSPComplex]
    fileprivate var overlapBuffer : [Float]
    var reversedKernel: [Float]
    
    init(kernel: [Float]) {
        self.kernel = kernel
        self.reversedKernel = kernel.reversed()
        overlapBuffer = [Float](repeating: 0.0, count: kernel.count - 1)
        // TODO: create FFT Setup
    }
    
    convenience init(filterType: FilterType, length: Int, fs: Int, cutoff: Float, window: [Float]) {
        assert(length == window.count)
        if (filterType == FilterType.lowpass) {
            let sincImpulse = FIRFilter.sinc(length, fs: Float(fs), cutoff: cutoff)
            let s = FIRFilter.slowDotProduct(sincImpulse, y: window)
            self.init(kernel: s)
        } else {
            self.init(kernel: [Float(1.0)])
        }
    }
    
    convenience init(filterType: FilterType, length: Int, fs: Int, cutoff: Float) {
        /** Create an FIR filter using a hann-windowed Sinc function. */
        let window = FIRFilter.hann(length)
        self.init(filterType: filterType, length: length, fs: fs, cutoff: cutoff, window: window)
    }
    
    class func slowDotProduct(_ x: [Float], y: [Float]) -> [Float] {
        assert(x.count == y.count)
        var result : [Float] = [Float](repeating: 0.0, count: x.count)
        for i in 0..<x.count {
            result[i] = x[i] * y[i]
        }
        return result
    }
    
    class func sinc(_ length: Int, fs: Float, cutoff: Float) -> [Float] {
        var result : [Float] = [Float](repeating: 0.0, count: length)
        
        let scale = (cutoff / fs)
        let increment = 2.0 * Float(M_PI) * scale
        var start : Float = -1 * increment * Float(length - 1) / 2
        for i in 0..<length {
            result[i] = 2 * scale * sin(start) / start
            start += increment
        }
        
        return result
    }
    
    class func hann(_ length: Int) -> [Float] {
        var result : [Float] = [Float](repeating: 0.0, count: length)
        
        let increment = 2.0 * Float(M_PI) / Float(length - 1)
        var start : Float = 0.0
        
        for i in 0..<length {
            result[i] = (1.0 / 2.0) * (1.0 - (cos(start)))
            start += increment
        }
        
        return result
    }
    
    func filter(_ inputSamples: [Float]) -> [Float] {
        /* First need to decide whether to convolve the input with FFT or directly */
        /* For now going to do it directly */
        let useFastConvolution: Bool = false
        let useVectorizedSlowConvolution: Bool = true
        var outputSamples : [Float]
        
        let fullLength = inputSamples.count + kernel.count - 1
        var temporaryOutputBuffer = [Float](repeating: 0.0 , count: fullLength)
        
        if (useFastConvolution) {
            /* Do FFT Convolution */
            //return [Float](count: 0, repeatedValue: 0.0)
            
            // Create array for FFT of input
            
            // Create array for FFT
            
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
*/

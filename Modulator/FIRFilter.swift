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
    case Lowpass
    case Bandpass
    case Highpass
}

class FIRFilter {
    var kernel: [Float]
    private var overlapBuffer : [Float]
    var reversedKernel: [Float]

    init(kernel: [Float]) {
        self.kernel = kernel
        self.reversedKernel = kernel.reverse()
        overlapBuffer = [Float](count: kernel.count - 1, repeatedValue: 0.0)
    }
    
    convenience init(filterType: FilterType, length: Int, fs: Int, cutoff: Float, window: [Float]) {
        assert(length == window.count)
        if (filterType == FilterType.Lowpass) {
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
    
    class func slowDotProduct(x: [Float], y: [Float]) -> [Float] {
        assert(x.count == y.count)
        var result : [Float] = [Float](count: x.count, repeatedValue: 0.0)
        for i in 0..<x.count {
            result[i] = x[i] * y[i]
        }
        return result
    }
    
    class func sinc(length: Int, fs: Float, cutoff: Float) -> [Float] {
        var result : [Float] = [Float](count: length, repeatedValue: 0.0)
        
        let scale = (cutoff / fs)
        let increment = 2.0 * Float(M_PI) * scale
        var start : Float = -1 * increment * Float(length - 1) / 2
        for i in 0..<length {
            result[i] = 2 * scale * sin(start) / start
            start += increment
        }
        
        return result
    }
    
    class func hann(length: Int) -> [Float] {
        var result : [Float] = [Float](count: length, repeatedValue: 0.0)
        
        let increment = 2.0 * Float(M_PI) / Float(length - 1)
        var start : Float = 0.0
        
        for i in 0..<length {
            result[i] = (1.0 / 2.0) * (1.0 - (cos(start)))
            start += increment
        }
        
        return result
    }
    
    func filter(inputSamples: [Float]) -> [Float] {
        /* First need to decide whether to convolve the input with FFT or directly */
        /* For now going to do it directly */
        let useFastConvolution: Bool = false
        let useVectorizedSlowConvolution: Bool = false
        var outputSamples : [Float]
        
        let fullLength = inputSamples.count + kernel.count - 1
        var temporaryOutputBuffer = [Float](count: fullLength , repeatedValue: 0.0)
        
        if (useFastConvolution) {
            /* Do FFT Convolution */
            //return [Float](count: 0, repeatedValue: 0.0)
        } else {
            /* Do direct convolution */
            if (useVectorizedSlowConvolution) {
                /* Do vDSP Convolution */
                cblas_scopy(Int32(inputSamples.count), inputSamples, 1, &temporaryOutputBuffer, 1)
                
                
                vDSP_conv(&temporaryOutputBuffer, 1, reversedKernel, 1, <#T##__C: UnsafeMutablePointer<Float>##UnsafeMutablePointer<Float>#>, <#T##__IC: vDSP_Stride##vDSP_Stride#>, <#T##__N: vDSP_Length##vDSP_Length#>, <#T##__P: vDSP_Length##vDSP_Length#>)
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
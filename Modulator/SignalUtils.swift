//
//  utils.swift
//  Modulator
//
//  Created by James on 9/21/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//
//  Utility functions to support the signal processing we're doing
//  These are not very fast and should be used only during setup rather
//  than in realtime. 

import Foundation
import Accelerate

func realToDSPSplitComplex(input: inout [Float]) -> DSPSplitComplex {
    /* Points the real part to the input and creates a new imaginary array */
    var imagp = [Float](repeating: 0.0, count: input.count)
    let output = DSPSplitComplex(realp: &input, imagp: &imagp)
    return output
}

func magnitude(input: inout DSPSplitComplex, length: Int) -> [Float] {
    /* Returns the magnitude each complex element. */
    
    var output = [Float](repeating: 0.0, count: length)
    
    vDSP_zvabs(&input, 1, &output, 1, vDSP_Length(length))
    
    return output
}


func fftSize(forCount: Int) -> Int {
    return 1 + Int(log2(Float(forCount - 1)))
}

func slowPointwiseMultiply(_ x: [Float], y: [Float]) -> [Float] {
    assert(x.count == y.count)
    var result : [Float] = [Float](repeating: 0.0, count: x.count)
    for i in 0..<x.count {
        result[i] = x[i] * y[i]
    }
    return result
}

func scale(_ x: [Float], y: Float) -> [Float] {
    var result : [Float] = [Float](repeating: 0.0, count: x.count)
    for i in 0..<x.count {
        result[i] = x[i] * y
    }
    return result
}

func sinc(_ length: Int, fs: Float, cutoff: Float) -> [Float] {
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

func sine(_ length: Int, fs: Float, fc: Float, centered: Bool) -> [Float] {
    var result = [Float](repeating: 0.0, count: length)
    
    let scale = (fc / fs)
    let increment = 2.0 * Float(M_PI) * scale
    var start : Float = centered ?
        -1 * increment * Float(length - 1) / 2
        : 0
    
    for i in 0..<length {
        result[i] = sin(start)
        start += increment
    }
    
    return result
}

func cosine(_ length: Int, fs: Float, fc: Float, centered: Bool) -> [Float] {
    var result = [Float](repeating: 0.0, count: length)
    
    let scale = (fc / fs)
    let increment = 2.0 * Float(M_PI) * scale
    var start : Float = centered ?
        -1 * increment * Float(length - 1) / 2
        : 0
    
    for i in 0..<length {
        result[i] = cos(start)
        start += increment
    }
    
    return result
}


func hann(_ length: Int) -> [Float] {
    var result : [Float] = [Float](repeating: 0.0, count: length)
    
    let increment = 2.0 * Float(M_PI) / Float(length - 1)
    var start : Float = 0.0
    
    for i in 0..<length {
        result[i] = (1.0 / 2.0) * (1.0 - (cos(start)))
        start += increment
    }
    
    return result
}

func complexExponential(_ length: Int, fs: Float, fc: Float, centered: Bool) -> SplitComplex {
    var result = SplitComplex(count: length)
    
    let scale = (fc / fs)
    let increment = 2.0 * Float(M_PI) * scale
    var start : Float = centered ?
        -1 * increment * Float(length - 1) / 2
        : 0
    
    for i in 0..<length {
        result.real[i] = cos(start)
        result.imag[i] = sin(start)
        start += increment
    }
    
    return result
}

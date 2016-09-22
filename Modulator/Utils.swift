//
//  utils.swift
//  Modulator
//
//  Created by James on 9/21/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

func fftSize(forCount: Int) -> Int {
    return 1 + Int(log2(Float(forCount - 1)))
}

func slowDotProduct(_ x: [Float], y: [Float]) -> [Float] {
    assert(x.count == y.count)
    var result : [Float] = [Float](repeating: 0.0, count: x.count)
    for i in 0..<x.count {
        result[i] = x[i] * y[i]
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

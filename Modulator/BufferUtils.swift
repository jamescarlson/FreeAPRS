//
//  File.swift
//  Modulator
//
//  Created by James on 9/21/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

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

func convertToUnsafeFromFloatArray (ptr: UnsafePointer<Float>) -> UnsafeRawPointer {
    return UnsafeRawPointer(ptr)
}

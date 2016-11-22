//
//  Abs.swift
//  Modulator
//
//  Created by James on 10/24/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Accelerate
import Foundation

func abs(input: inout SplitComplex) -> [Float] {
    var output = [Float](repeating: 0.0, count: input.count)
    
    vDSP_zvabs(&input.dspSC, 1, &output, 1, vDSP_Length(input.count))
    
    return output
}

func +(left: [Float], right: [Float]) -> [Float] {
    assert(left.count == right.count)
    
    var output = [Float](repeating: 0.0, count: left.count)

    vDSP_vadd(left, 1, right, 1, &output, 1, vDSP_Length(left.count))
    
    return output
}

func -(left: [Float], right: [Float]) -> [Float] {
    assert(left.count == right.count)
    
    var output = [Float](repeating: 0.0, count: left.count)
    
    /* First is subtracted from second according to vDSP docs. */
    vDSP_vsub(right, 1, left, 1, &output, 1, vDSP_Length(left.count))
    
    return output
}

func *(left: [Float], right: Float) -> [Float] {
    var output = [Float](repeating: 0.0, count: left.count)
    
    var scalar = right
    vDSP_vsmul(left, 1, &scalar, &output, 1, vDSP_Length(left.count))
    
    return output
}

func *(left: Float, right: [Float]) -> [Float] {
    return right * left
}

func sampleValues<T>(input: [T], sampleLocations: [Int]) -> [T] {
    var output = [T]()
    output.reserveCapacity(sampleLocations.count)
    
    for i in 0..<sampleLocations.count {
        output.append(input[sampleLocations[i]])
    }
    
    return output
}
/*
func sampleValues(input: [Float], sampleLocations: [Float]) -> [Float] {
    var output = [Float]()
    output.reserveCapacity(sampleLocations.count)
    
    for i in 0..<sampleLocations.count {
        let previousSample = input[Int(floorf(sampleLocations[i]))]
        let nextSample = input[Int(ceilf(sampleLocations[i]))]
    }
}
 */

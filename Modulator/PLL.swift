//
//  PLL.swift
//  Modulator
//
//  Created by James on 7/21/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation
import Accelerate

class PLL {
    var lastPll: Float
    var sampleRate: Float
    var baud: Float
    
    init(_ sampleRate: Float, baud: Float) {
        lastPll = 0
        self.sampleRate = sampleRate
        self.baud = baud
    }
    
    func findSamples(_ data: [Float]) {
        
    }
    
    fileprivate func findZeroCrossings(_ data: [Float]) -> [Int32] {
        let coefficients: [Double] = [1.0, -1.0, 0.0, 0, 0]
        let biquadFilter: vDSP_biquad_Setup = vDSP_biquad_CreateSetup(
            coefficients, 1)!
        var delayState: [Float] = [0, 0]
        
        var limit : Float = 0;
        var signValue : Float = 1;
        var signData = [Float](repeating: 0.0, count: data.count)
        
        vDSP_vlim(data, 1, &limit, &signValue, &signData, 1, vDSP_Length(data.count))
        
        var diffData = [Float](repeating: 0.0, count: data.count + 2)
        let N: vDSP_Length = UInt(data.count)
        vDSP_biquad(biquadFilter, &delayState, signData, 1, &diffData, 1, N)
        
        
        var indexData = [Float](repeating: 0.0, count: data.count + 2)
        var rampStart : Float = 0
        var rampStep : Float = 0.5
        vDSP_vrampmul(diffData, 1, &rampStart, &rampStep, &indexData, 1, vDSP_Length(data.count + 2))
        
        var outputIndices = [Float](repeating: 0.0, count: data.count + 2)
        
        vDSP_vcmprs(indexData, 1, indexData, 1, &outputIndices, 1, vDSP_Length(data.count + 2))
        
        var counter : Int = 0
        while (counter < data.count + 2) {
            if (outputIndices[counter] == 0) {
                break
            }
            counter += 1
        }
        
        outputIndices.removeLast(data.count + 1 - counter)
        var output = [Int32](repeating: 0, count: outputIndices.count)
        
        vDSP_vfixr32(outputIndices, 1, &output, 1, vDSP_Length(outputIndices.count))
        
        output.removeLast()
        
        vDSP_vabsi(output, 1, &output, 1, vDSP_Length(output.count))
        
        return output
    }
    
}


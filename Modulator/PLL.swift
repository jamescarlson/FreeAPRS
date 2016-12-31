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
    var a: Float
    let samplesPerSymbol : Float
    
    init(sampleRate: Float, baud: Float, a: Float) {
        self.lastPll = 0
        self.sampleRate = sampleRate
        self.baud = baud
        self.a = a
        self.samplesPerSymbol = Float(sampleRate / baud)
    }
    
    func findSamples(data: [Float]) -> [Int] {
        var maxPllOffset = 0
        var sampleIndices = [Int]()
        sampleIndices.reserveCapacity(Int(Float(data.count) / samplesPerSymbol) + 1)
        
        let zeroCrossings = findZeroCrossings(data: data)
        
        /* Make this a float in order to retain precision in case of non-integer
            samplesPerSymbol values. */
        var nextSampleIndex = self.lastPll + self.samplesPerSymbol / 2
        assert(nextSampleIndex >= 0 && Float(nextSampleIndex) <= self.samplesPerSymbol)
        
        for nextCrossingIndex in zeroCrossings {
            while nextSampleIndex < Float(nextCrossingIndex) {
                sampleIndices.append(Int(nextSampleIndex))
                nextSampleIndex += self.samplesPerSymbol
            }
            
            let samplesPastCrossing = nextSampleIndex - Float(nextCrossingIndex)
            assert(samplesPastCrossing >= 0 && samplesPastCrossing <= self.samplesPerSymbol)
            
            var pllAtCrossing = samplesPastCrossing - self.samplesPerSymbol / 2
            
            maxPllOffset = max(maxPllOffset, Int(pllAtCrossing))
            pllAtCrossing *= self.a
            
            nextSampleIndex = Float(nextCrossingIndex) + pllAtCrossing + self.samplesPerSymbol / 2
        }
        
        while (nextSampleIndex < Float(data.count)) {
            sampleIndices.append(Int(nextSampleIndex))
            nextSampleIndex += self.samplesPerSymbol
        }
        
        let samplesPastCrossing = nextSampleIndex - Float(data.count)
        assert(samplesPastCrossing >= 0 && samplesPastCrossing <= self.samplesPerSymbol)
        self.lastPll = samplesPastCrossing - self.samplesPerSymbol / 2
        
        return sampleIndices
    }
    
    func findZeroCrossings(data: [Float]) -> [Int32] {
        /* Gratuitous vectorization that isn't actually needed (!)
 
        let coefficients: [Double] = [1.0, -1.0, 0.0, 0, 0]
        let biquadFilter: vDSP_biquad_Setup = vDSP_biquad_CreateSetup(
            coefficients, 1)!
        var delayState: [Float] = [0, 0, 0, 0]
        
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
        
        vDSP_biquad_DestroySetup(biquadFilter)
        return output
 
        */
        
        var zeroCrossings = [Int32]()
        
        var prev = data[0]
        
        for index in 1..<data.count {
            if (prev.sign != data[index].sign) {
                zeroCrossings.append(Int32(index))
            }
            prev = data[index]
        }
        
        return zeroCrossings
    }
    
}


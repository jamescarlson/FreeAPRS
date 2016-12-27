//
//  APRSEncoder.swift
//  FreeAPRS
//
//  Created by James on 12/25/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Accelerate
import UIKit

/** Encodes APRSPackets into raw Float samples that can be played through the
 audio output. */
class APRSEncoder {
    
    /// Duration of a flag octet
    static let flagTime : Float = 8.0 / 1200.0
    
    /// Boolean array representation of a flag
    static let flag : [Bool] = [false, true, true, true, true, true, true, false]
    
    /// Sample rate of the generated packet
    var sampleRate : Float
    
    /// Number of packets to remember for memoization
    var numPacketsToRemember = 4
    
    /// Queue of packets so we can forget the oldest one
    var rememberedPackets : CircularBufferQueue<APRSPacket>
    
    /// Mapping of packets to encoded samples
    var encodedRememberedPackets = [APRSPacket : [Float]]()
    
    var nrziEncoder = NRZIEncoder()
    
    init(sampleRate: Float, numPacketsToRemember: Int) {
        self.sampleRate = sampleRate
        rememberedPackets = CircularBufferQueue<APRSPacket>(withCapacity: numPacketsToRemember)
    }
    
    init(sampleRate: Float) {
        self.sampleRate = sampleRate
        rememberedPackets = CircularBufferQueue<APRSPacket>(withCapacity: self.numPacketsToRemember)
    }
    
    /** Translate an APRSPacket to raw samples. Memoized for the last
    `numPacketsToRemember` packets. */
    func encode(packet: APRSPacket) -> [Float] {
        var encodedPacket = encodedRememberedPackets[packet]
        
        if (encodedPacket != nil) {
            return encodedPacket!
        }
        
        let preFlagTime = UserDefaults.standard.float(forKey: "preFlagTime")
        let postFlagTime = UserDefaults.standard.float(forKey: "postFlagTime")
        let numPreFlags = max(1, Int(preFlagTime / APRSEncoder.flagTime))
        let numPostFlags = max(1, Int(postFlagTime / APRSEncoder.flagTime))
        
        // TODO: If this takes up any significant amount of time, find a way to
        // better optimize this appending
        
        var toEncode = APRSEncoder.flag.tile(numberOfTimes: numPreFlags)
        toEncode.append(contentsOf: packet.getStuffedBits())
        toEncode.append(contentsOf: APRSEncoder.flag.tile(numberOfTimes: numPostFlags))
        
        let nrzi = nrziEncoder.encode(input: toEncode)
        
        let samplesPerBit = sampleRate / 1200.0
        let minSamplesPerBitInt = Int(samplesPerBit)
        let fractionalSamplesPerBit = samplesPerBit.remainder(dividingBy: 1.0)
        
        var remainder : Float = 0
        
        var totalSamples = nrzi.count * Int(samplesPerBit)
        
        // Amount that x (in cos(x)) needs to increase over one second to
        // produce frequencies of 1200 and 2200 Hz
        let markIncrement = Float(M_PI * 2.0 * 1200.0)
        let spaceIncrement = Float(M_PI * 2.0 * 2200.0)
        
        var outputIndex = 0
        var inputIndex = 0
        
        var toIntegrate = [Float](repeating: 0.0, count: Int(totalSamples))
        
        
        /* To deal with sample rates where a single bit of AFSK data is not an
        integer number of samples, keep track of a "remainder" which will
        determine the value of the samples that lie between regions of one
        frequency only.
 
        */
 
        while outputIndex < totalSamples {
            assert(inputIndex < nrzi.count, "Shouldn't be continuing any further")
            
            let thisIncrement = nrzi[inputIndex] ? markIncrement : spaceIncrement
            inputIndex += 1
            
            let howManyFlat : Int
            if remainder >= 1 {
                remainder -= 1
                howManyFlat = minSamplesPerBitInt + 1
            } else {
                howManyFlat = minSamplesPerBitInt
            }
            
            remainder += fractionalSamplesPerBit
            
            for i in outputIndex..<outputIndex + howManyFlat {
                toIntegrate[i] = thisIncrement
            }
            
            outputIndex += howManyFlat
        }
        
        
        var integrated = [Float](repeating: 0.0, count: toIntegrate.count)
        
        var inverseFs = 1.0 / sampleRate
        vDSP_vtrapz(toIntegrate, 1, &inverseFs, &integrated, 1, vDSP_Length(integrated.count))
        
        for i in 0..<integrated.count {
            integrated[i] = cos(integrated[i])
        }
        
        if rememberedPackets.count >= numPacketsToRemember {
            let toRemove = rememberedPackets.pop()
            encodedRememberedPackets.removeValue(forKey: toRemove!)
        }
        
        rememberedPackets.push(packet)
        encodedRememberedPackets[packet] = integrated
        
        return integrated
    }
    
}

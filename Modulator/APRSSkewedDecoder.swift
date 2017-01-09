//
//  APRSSkewedDecoder.swift
//  FreeAPRS
//
//  Created by James on 11/21/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

class APRSSkewedDecoder {
    let spaceToneSkew : Float
    let pll: PLL
    let nrziDecoder: NRZIDecoder
    let aprsPacketFinder: APRSPacketFinder
    
    init(spaceToneSkew: Float,
         pll: PLL,
         nrziDecoder: NRZIDecoder,
         aprsPacketFinder: APRSPacketFinder) {
        self.spaceToneSkew = spaceToneSkew
        self.pll = pll
        self.nrziDecoder = nrziDecoder
        self.aprsPacketFinder = aprsPacketFinder
        NSLog("Initialilzed Skewed Decoder with Skew: \(spaceToneSkew)")
    }
    
    func decode(absMark: [Float], absSpace: [Float]) -> [APRSPacket] {
        let difference = absMark - (absSpace * spaceToneSkew)
        
        let sampleLocations = pll.findSamples(data: difference)
        
        let nrziFloat = sampleValues(input: difference, sampleLocations: sampleLocations)
        
        let nrzi = sign(input: nrziFloat)
        
        let nrz = nrziDecoder.decode(input: nrzi)
        
        return aprsPacketFinder.findPackets(nrz)
    }
}

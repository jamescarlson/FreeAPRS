//
//  AudioProcessOperationBuilder.swift
//  Modulator
//
//  Created by James on 10/24/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

class AudioProcessOperationFactory {
    let prefilter: FIRFilter
    let downsampler: Downsampler<Float>
    let complex1200Filter: ComplexFIRFilter
    let complex2200Filter: ComplexFIRFilter
    let pll: PLL
    let nrziDecoder: NRZIDecoder
    let aprsPacketFinder: APRSPacketFinder
    let outputQueue: CircularBufferQueue<APRSPacket>
    
    init(prefilter: FIRFilter,
         downsampler: Downsampler<Float>,
         complex1200Filter: ComplexFIRFilter,
         complex2200Filter: ComplexFIRFilter,
         pll: PLL,
         nrziDecoder: NRZIDecoder,
         aprsPacketFinder: APRSPacketFinder,
         outputQueue: CircularBufferQueue<APRSPacket>) {
        self.prefilter = prefilter
        self.downsampler = downsampler
        self.complex1200Filter = complex1200Filter
        self.complex2200Filter = complex2200Filter
        self.pll = pll
        self.nrziDecoder = nrziDecoder
        self.aprsPacketFinder = aprsPacketFinder
        self.outputQueue = outputQueue
    }
    
    func getOperation() -> AudioProcessOperation {
        return AudioProcessOperation(
            prefilter: prefilter,
            downsampler: downsampler,
            complex1200Filter: complex1200Filter,
            complex2200Filter: complex2200Filter,
            pll: pll,
            nrziDecoder: nrziDecoder,
            APRSPacketFinder: aprsPacketFinder,
            outputQueue: outputQueue)
        
    }
}

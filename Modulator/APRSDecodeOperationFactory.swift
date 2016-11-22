//
//  AudioProcessOperationBuilder.swift
//  Modulator
//
//  Created by James on 10/24/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

class APRSDecodeOperationFactory : AudioProcessOperationFactory {
    let prefilter: FIRFilter
    let downsampler: Downsampler<Float>
    let complex1200Filter: ComplexFIRFilter
    let complex2200Filter: ComplexFIRFilter
    let skewedDecoders: [APRSSkewedDecoder]
    let deduplicator: APRSPacketSimpleDeduplicator
    let outputQueue: APRSPacketDataStore
    
    init(prefilter: FIRFilter,
         downsampler: Downsampler<Float>,
         complex1200Filter: ComplexFIRFilter,
         complex2200Filter: ComplexFIRFilter,
         skewedDecoders: [APRSSkewedDecoder],
         deduplicator: APRSPacketSimpleDeduplicator,
         outputQueue: APRSPacketDataStore) {
        self.prefilter = prefilter
        self.downsampler = downsampler
        self.complex1200Filter = complex1200Filter
        self.complex2200Filter = complex2200Filter
        self.skewedDecoders = skewedDecoders
        self.deduplicator = deduplicator
        self.outputQueue = outputQueue
    }
    
    func getOperation() -> AudioProcessOperation {
        return APRSDecodeOperation(
            prefilter: prefilter,
            downsampler: downsampler,
            complex1200Filter: complex1200Filter,
            complex2200Filter: complex2200Filter,
            skewedDecoders: skewedDecoders,
            deduplicator: deduplicator,
            outputQueue: outputQueue)
    }
}

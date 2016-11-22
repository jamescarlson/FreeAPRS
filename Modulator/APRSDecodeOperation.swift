//
//  AudioProcessOperation.swift
//  Modulator
//
//  Created by James on 10/23/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

class APRSDecodeOperation : AudioProcessOperation {
    let prefilter: FIRFilter
    let downsampler: Downsampler<Float>
    let complex1200Filter: ComplexFIRFilter
    let complex2200Filter: ComplexFIRFilter
    let skewedDecoders: [APRSSkewedDecoder]
    let deduplicator: APRSPacketSimpleDeduplicator
    var outputPackets = [APRSPacket]()
    var outputQueue : APRSPacketDataStore
    
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
    
    override func process(inputSamples: inout [Float]) {
        if (self.isCancelled) { return }
        
        let rms = rmsValue(input: inputSamples)
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("RMSValue"), object: nil, userInfo: ["value": rms])
        }
        
        if (self.isCancelled) { return }
        
        let filteredInputSamples = prefilter.filter(&inputSamples)
        
        if (self.isCancelled) { return }
        
        let downsampledSamples = downsampler.downsample(input: filteredInputSamples)
        
        if (self.isCancelled) { return }
        
        var filteredMark = complex1200Filter.filter(SplitComplex(real: downsampledSamples))
        
        if (self.isCancelled) { return }
        
        var filteredSpace = complex2200Filter.filter(SplitComplex(real: downsampledSamples))
        
        if (self.isCancelled) { return }
        
        let absMark = abs(input: &filteredMark)
        let absSpace = abs(input: &filteredSpace)
        
        for skewedDecoder in skewedDecoders {
            if (self.isCancelled) { return }
            
            let decodedPackets = skewedDecoder.decode(absMark: absMark, absSpace: absSpace)
            
            self.outputPackets.append(contentsOf: deduplicator.add(packets: decodedPackets))
        }
        
        outputQueue.append(packets: self.outputPackets)
    }

}

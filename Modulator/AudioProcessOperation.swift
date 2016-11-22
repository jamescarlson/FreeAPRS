//
//  AudioProcessOperation.swift
//  Modulator
//
//  Created by James on 10/23/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

/* TODO: Make the APRS processing thing a subclass of AudioProcessOperation. */

class AudioProcessOperation : Operation {
    let prefilter: FIRFilter
    let downsampler: Downsampler<Float>
    let complex1200Filter: ComplexFIRFilter
    let complex2200Filter: ComplexFIRFilter
    let skewedDecoders: [APRSSkewedDecoder]
    let deduplicator: APRSPacketSimpleDeduplicator
    var inputSamples : [Float]?
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
    
    override func main() {
        if (self.isCancelled) { return }
        
        if (self.inputSamples == nil) {
            return
        }
        
        let filteredInputSamples = prefilter.filter(&inputSamples!)
        
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

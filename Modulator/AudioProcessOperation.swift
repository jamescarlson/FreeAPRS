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
    let pll: PLL
    let nrziDecoder: NRZIDecoder
    let aprsListener: APRSListener
    var inputSamples : [Float]?
    var outputPackets : [APRSPacket]?
    var outputQueue : CircularBufferQueue<APRSPacket>
    
    init(prefilter: FIRFilter,
         downsampler: Downsampler<Float>,
         complex1200Filter: ComplexFIRFilter,
         complex2200Filter: ComplexFIRFilter,
         pll: PLL,
         nrziDecoder: NRZIDecoder,
         aprsListener: APRSListener,
         outputQueue: CircularBufferQueue<APRSPacket>) {
        self.prefilter = prefilter
        self.downsampler = downsampler
        self.complex1200Filter = complex1200Filter
        self.complex2200Filter = complex2200Filter
        self.pll = pll
        self.nrziDecoder = nrziDecoder
        self.aprsListener = aprsListener
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
        
        if (self.isCancelled) { return }
        
        let difference = absMark - absSpace
        
        let sampleLocations = pll.findSamples(data: difference)
        
        if (self.isCancelled) { return }
        
        let nrziFloat = sampleValues(input: difference, sampleLocations: sampleLocations)
        
        let nrzi = sign(input: nrziFloat)
        
        let nrz = nrziDecoder.decode(input: nrzi)
        
        if (self.isCancelled) { return }
        
        self.outputPackets = aprsListener.findPackets(nrz)
        
        if (self.outputPackets != nil) {
            for packet in self.outputPackets! {
                outputQueue.push(packet)
            }
        }
    }

}

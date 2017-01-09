//
//  APRSListener.swift
//  FreeAPRS
//
//  Created by James on 11/15/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

class APRSListener {
    var dataStore : APRSPacketDataStore
    var audioIOManager : AudioIOManagerProtocol
    let opQueue = OperationQueue()
    let skews : [Float]
    
    init(withDataStore dataStore: APRSPacketDataStore, audioIOManager: AudioIOManagerProtocol,
         userDefaults: UserDefaults) {
        self.dataStore = dataStore
        opQueue.maxConcurrentOperationCount = 1
        self.audioIOManager = audioIOManager
        self.skews = userDefaults.array(forKey: "spaceToneSkews") as? [Float] ?? [1.0]
    }
    
    init(withDataStore dataStore: APRSPacketDataStore,
         skews: [Float],
         audioIOManager: AudioIOManagerProtocol) {
        self.dataStore = dataStore
        opQueue.maxConcurrentOperationCount = 1
        self.audioIOManager = audioIOManager
        self.skews = skews
    }
    
    func startListening() {
        
        let fs = Int(audioIOManager.sampleRate)
        NSLog("Listener FS: \(fs)")
        
        let tbw = 2
        let prefilterLowLimit = 900
        let prefilterHighLimit = 2500
        
        /* How much downsampling to fit 1.25x the bandwidth of the prefilter
         into the new signal? */
        let downsampleFactor = Float(fs) / (Float(prefilterHighLimit) * Float(5))
        
        /* When in doubt, don't downsample too far (flooring the downsampleFactor) */
        let newFs = fs / Int(downsampleFactor)
        
        let prefilterHalfBandwidth = (prefilterHighLimit - prefilterLowLimit) / 2
        let prefilterCenter = (prefilterHighLimit + prefilterLowLimit) / 2
        let markFreq = 1200
        let spaceFreq = 2200
        let markSpaceHalfBandwidth = 300
        let prefilterLength = Int(Float(fs) * (Float(tbw) / Float(prefilterHalfBandwidth) / 2))
        let markSpaceLength = Int(Float(newFs) * (Float(tbw) / Float(markSpaceHalfBandwidth) / 2))
        
        let prefilter = FIRFilter(filterType: .bandpass,
                                  length: prefilterLength,
                                  fs: fs,
                                  cutoff: Float(prefilterHalfBandwidth),
                                  center: Float(prefilterCenter))
        
        let markFilter = ComplexFIRFilter(filterType: .complexbandpass,
                                          length: markSpaceLength,
                                          fs: newFs,
                                          cutoff: Float(markSpaceHalfBandwidth),
                                          center: Float(markFreq))
        
        let spaceFilter = ComplexFIRFilter(filterType: .complexbandpass,
                                           length: markSpaceLength,
                                           fs: newFs,
                                           cutoff: Float(markSpaceHalfBandwidth),
                                           center: Float(spaceFreq))
        
        let downsampler = Downsampler<Float>(factor: Int(downsampleFactor), defaultValue: 0)
        
        let deduplicator = APRSPacketSimpleDeduplicator(numPacketsToRemember: 16)
        
        var skewedDecoders = [APRSSkewedDecoder]()
        
        for skew in skews {
            let thisPLL = PLL(sampleRate: Float(newFs), baud: 1200, a: 0.7)
            let thisNrziDecoder = NRZIDecoder()
            let thisAprsPacketFinder = APRSPacketFinder()
            
            let thisSkewedDecoder = APRSSkewedDecoder(spaceToneSkew: skew,
                                                      pll: thisPLL,
                                                      nrziDecoder: thisNrziDecoder,
                                                      aprsPacketFinder: thisAprsPacketFinder)

            skewedDecoders.append(thisSkewedDecoder)
        }

        
        let factory = APRSDecodeOperationFactory(
            prefilter: prefilter,
            downsampler: downsampler,
            complex1200Filter: markFilter,
            complex2200Filter: spaceFilter,
            skewedDecoders: skewedDecoders,
            deduplicator: deduplicator,
            outputQueue: dataStore)
        
        let dispatcher = AudioDispatcher(operationQueue: opQueue, opFactory: factory)
        
        audioIOManager.addAudioDispatcher(dispatcher)
        
        audioIOManager.startAudioIn()
    }
    
    func stopListening() {
        audioIOManager.endAudioIn()
    }
    
    deinit {
        self.stopListening()
    }
}

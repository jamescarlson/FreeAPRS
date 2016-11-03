//
//  ViewController.swift
//  Modulator
//
//  Created by James on 7/14/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import UIKit

class ReceiveViewController: UIViewController {

    let opQueue = OperationQueue()
    let packetQueue = CircularBufferQueue<APRSPacket>(withCapacity: 16)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NSLog("Lit")
        
        /* TODO: put all this code somewhere else. */
        
        let opQueue = OperationQueue()
        opQueue.maxConcurrentOperationCount = 1
        
        let fs = 44100
        let downsampleFactor = 7
        let newFs = fs / downsampleFactor
        let tbw = 1.5
        let prefilterLowLimit = 900
        let prefilterHighLimit = 2500
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
        
        let downsampler = Downsampler<Float>(factor: downsampleFactor, defaultValue: 0)
        
        let pll = PLL(sampleRate: Float(newFs), baud: 1200, a: 0.96)
        
        let nrziDecoder = NRZIDecoder()
        
        let aprsListener = APRSListener()
        
        let factory = AudioProcessOperationFactory(
            prefilter: prefilter,
            downsampler: downsampler,
            complex1200Filter: markFilter,
            complex2200Filter: spaceFilter,
            pll: pll,
            nrziDecoder: nrziDecoder,
            aprsListener: aprsListener,
            outputQueue: packetQueue)
        
        let dispatcher = AudioDispatcher(operationQueue: opQueue, opFactory: factory)
        
        
        let ai : SAMicrophoneInput = SAMicrophoneInput(dispatcher)
        ai.startAudioIn()
    }

    @IBAction func logReceivedPacketCount(_ sender: AnyObject) {
        
        NSLog("Number of received packets: \(self.packetQueue.size())")
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


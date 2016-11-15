//
//  ViewController.swift
//  Modulator
//
//  Created by James on 7/14/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import UIKit

class ReceiveViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    let opQueue = OperationQueue()
    let packetQueue = CircularBufferQueue<APRSPacket>(withCapacity: 16)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateTextView), name: packetQueue.notificationIdentifier, object: nil)
        // Do any additional setup after loading the view, typically from a nib.
        NSLog("Lit")
        
        /* TODO: put all this code somewhere else. */
        
        let opQueue = OperationQueue()
        opQueue.maxConcurrentOperationCount = 1
        
        let audioInput : SAMicrophoneInput = SAMicrophoneInput();
        
        let preferredFs = 44100.0
        audioInput.configureAudioIn(withPreferredSampleRate: Float(preferredFs),
                                    preferredNumberOfChannels: 1,
                                    singleChannelOutput: true,
                                    channelIndexForSingleChannelOutput: 0,
                                    preferredSamplesPerBuffer: 4096)

        
        let fs = Int(audioInput.sampleRate)
        
        let tbw = 1.5
        let prefilterLowLimit = 900
        let prefilterHighLimit = 2500
        
        /* How much downsampling to fit 1.25x the bandwidth of the prefilter
            into the new signal? */
        let downsampleFactor = Float(fs) / (Float(prefilterHighLimit) * Float(2.5))
        
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
        
        let pll = PLL(sampleRate: Float(newFs), baud: 1200, a: 0.85)
        
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
        
        audioInput.add(dispatcher)
        
        audioInput.startAudioIn()
    }

    @IBAction func logReceivedPacketCount(_ sender: AnyObject) {
        
        NSLog("Number of received packets: \(self.packetQueue.size())")
        
    }
    
    func updateTextView() {
        if let newPacket = packetQueue.pop() {
            textView.text.append("\n" + String(describing: newPacket))
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


//
//  AudioSource.swift
//  FreeAPRS
//
//  Created by James on 12/22/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import UIKit
import AudioToolbox
import Accelerate

/** Supplies audio output to AudioIOManager - Simple Swift interface to it which
 allows dumping an array of float samples in and then not worrying about it. 
 
 FIXME: Still tightly coupled to AudioIOManager, there is probably a better way
 for these two classes to interact rather than this circular reference. */
@objc class AudioSource: NSObject {
    let audioIOManager : AudioIOManagerProtocol
    var samplesToPlay : [Float]? = nil
    var playingIndex : Int? = nil
    var floatToIntScaleFactor : Float = 32767.0
    
    var sampleRate : Float {
        get {
            return self.audioIOManager.sampleRate
        }
    }
    
    
    init(audioIOManager: AudioIOManagerProtocol) {
        self.audioIOManager = audioIOManager
        super.init()
        audioIOManager.addAudioSource(self)
    }
    
    /** Play samples at the sample rate given by the `sampleRate` property
    through all channels */
    func play(monoSamples: [Float]) {
        if (playingIndex != nil) {
            return;
        }
        
        playingIndex = 0
        samplesToPlay = monoSamples
        vDSP_vsmul(&samplesToPlay!, 1, &floatToIntScaleFactor, &samplesToPlay!, 1, vDSP_Length(samplesToPlay!.count))
        audioIOManager.oneShotPlayAudioOut()
    }
    
    /** AudioIOManager will call this to fill up a buffer with output samples
    after oneShotPlay... has been called. Returns the number of mono samples
    put into the buffer. */
    @objc func getSamples(buffer : AudioQueueBufferRef) -> Int {
        let bytesCapacity = buffer.pointee.mAudioDataBytesCapacity
        let bytesPerSample = 2 * audioIOManager.numberOfOutputChannels
        
        let bufferPtr = buffer.pointee.mAudioData
        let numberOfSamples = Int(bytesCapacity) / Int(bytesPerSample)
        
        let howMany = numberOfSamples <= (samplesToPlay!.count - playingIndex!) ?
        numberOfSamples : samplesToPlay!.count - playingIndex!
        
        if (howMany <= 0) {
            playingIndex = nil
            samplesToPlay = nil
            return 0
        }
        
        // Copy mono float samples into correct position into output buffer,
        // Possibly with multiple channels of Int16
        samplesToPlay?.withUnsafeBufferPointer( {ptr in
        for channelIndex in 0..<audioIOManager.numberOfOutputChannels {
            vDSP_vfixr16(
                ptr.baseAddress!.advanced(by: playingIndex!),
                1,
                bufferPtr.assumingMemoryBound(to: Int16.self).advanced(by: Int(channelIndex)),
                vDSP_Stride(audioIOManager.numberOfOutputChannels),
                vDSP_Length(howMany))
            }
        }
        )
        
        playingIndex! += howMany
        
        return howMany * Int(bytesPerSample)
    }
}
    

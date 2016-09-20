//
//  AudioInput.swift
//  Modulator
//
//  Created by James on 8/9/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation
import AudioToolbox
import AVFoundation

var myInstance : AudioInput?

func processBufferGlobal(inUserData : UnsafeMutablePointer<Void>,
                       _ inAQ : AudioQueueRef,
                       _ inBuffer : AudioQueueBufferRef,
                       _ inStartTime : UnsafePointer<AudioTimeStamp>,
                       _ inNumberPacketDescriptions : UInt32,
                       _ inPacketDescriptions : UnsafePointer<AudioStreamPacketDescription>) -> (){
   myInstance!.processBuffer(inUserData, inAQ, inBuffer, inStartTime, inNumberPacketDescriptions, inPacketDescriptions)
}

struct AQInputState {
    var mDataFormat : AudioStreamBasicDescription?
    var mQueue : AudioQueueRef?
    var mBuffers : [AudioQueueBufferRef]?
    var bufferByteSize : UInt32?
    var mIsRunning : Bool?
}

class AudioInput {
    let kNumberBuffers : Int = 3;
    var format : AudioStreamBasicDescription?
    var state : AQInputState
    var sampleBlockSize : UInt32
    
    init(sampleBlockSize: UInt32 = 2048) {
        state = AQInputState()
        state.mQueue = AudioQueueRef(bitPattern: 0)
        state.mBuffers = [AudioQueueBufferRef](count: kNumberBuffers, repeatedValue: AudioQueueBufferRef(bitPattern: 0))
        self.sampleBlockSize = sampleBlockSize
        myInstance = self
    }
    
    func startAudioIn() {
        ensureRecordPermission()
        configureAudioSession()
        activateAudioSession()
        setupBasicDescription()
        setupState()
        
        assert(state.mQueue == AudioQueueRef(bitPattern: 0), "Queue is already set up")
        
        let status : OSStatus =
            AudioQueueNewInput(&format!, processBufferGlobal, &state, nil, nil, 0, &state.mQueue!)
        
        allocateBuffers()
        
        AudioQueueStart(state.mQueue!, nil)
    }
    
    /* TODO: Figure out how to queue these up into power of two sized blocks.
    They aren't guaranteed to come that way from the audio queue.
 
    May Not really need this though unless we're doing an FFT. FM demodulation
    can be done with whatever sized blocks we want. 
 
    Implement FM demodulation first probably.
 
    Discriminator types?: Conjugate differentiation multiply could work.
    Filtering directly and taking amplitude of analytic signal - another option.
    Both are very similar, and would require demodulation to baseband to remove 
    DC offset.
    */
    
    
    func processBuffer(inUserData : UnsafeMutablePointer<Void>?,
                       _ inAQ : AudioQueueRef,
                       _ inBuffer : AudioQueueBufferRef,
                       _ inStartTime : UnsafePointer<AudioTimeStamp>,
                       _ inNumberPacketDescriptions : UInt32,
                       _ inPacketDescriptions : UnsafePointer<AudioStreamPacketDescription>?) -> Void{
        NSLog("First sample: " + String(inBuffer.memory.mAudioData[0]))
        NSLog("Length: " + String(inBuffer.memory.mAudioDataByteSize))
        
        var status : OSStatus = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil)
        if (status != noErr) {
            NSLog("Error enqueing buffer: \(status)")
        }
    }
    
    func ensureRecordPermission() {
        AVAudioSession.sharedInstance()
            .requestRecordPermission(
                    { (permission: Bool) -> Void in
                NSLog("Record Permission: \(permission)")
                })
    }
    
    func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
            NSLog("Set category")
            try session.setMode(AVAudioSessionModeMeasurement)
            NSLog("Set mode")
        } catch {
            NSLog("Unable to configure Audio Session")
            NSLog("error info: \(error)")
        }
    }
    
    func activateAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session
                .setActive(true)
            try session.setPreferredInputNumberOfChannels(1)
            NSLog("Set input channels")
            if (session.inputNumberOfChannels != 1) {
                NSLog("Number of input channels not 1")
            }
        } catch {
            NSLog("Unable to acitvate audio session")
        }
    }
    
    func setupBasicDescription() {
        let formatFlags : UInt32 = (0
        | kAudioFormatFlagIsPacked
        | kAudioFormatFlagIsSignedInteger
        )
        
        let numChannels : UInt32 = UInt32(AVAudioSession.sharedInstance().inputNumberOfChannels)
    
        format = AudioStreamBasicDescription(mSampleRate: AVAudioSession.sharedInstance().sampleRate, mFormatID: kAudioFormatLinearPCM, mFormatFlags: formatFlags, mBytesPerPacket: 2 * numChannels, mFramesPerPacket: 1, mBytesPerFrame: 2 * numChannels, mChannelsPerFrame: numChannels, mBitsPerChannel: 16, mReserved: 0)
    }
    
    func setupState() {
        setupBasicDescription()
        state.mDataFormat = format
        state.mIsRunning = true
        state.bufferByteSize = self.bufferSizeForSamples(self.sampleBlockSize)
        
    }
    
    func bufferSizeForSamples(samples : UInt32) -> UInt32 {
        let maxPacketSize = format?.mBytesPerPacket
        return maxPacketSize! * samples;
    }
    
    func allocateBuffers() {
        for i in 0 ..< kNumberBuffers {
            var status : OSStatus = noErr
            status = AudioQueueAllocateBuffer(state.mQueue!, state.bufferByteSize!, &state.mBuffers![i])
            if (status != noErr) {
                NSLog("Error allocating buffers, \(status)")
            }
            status = AudioQueueEnqueueBuffer(state.mQueue!, state.mBuffers![i], 0, nil)
            if (status != noErr) {
                NSLog("Error enqueuing buffers, \(status)")
            }
        }
        
        
    }
    
    
}

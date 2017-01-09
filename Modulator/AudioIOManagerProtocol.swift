//
//  AudioIOManagerProtocol.swift
//  FreeAPRS
//
//  Created by James on 12/26/16.
//  Copyright © 2016 dimnsionofsound. All rights reserved.
//

import Foundation

@objc protocol AudioIOManagerProtocol {
    
    var preferredSampleRate : Float { get }
    var sampleRate : Float { get }
    /* Might be different than the requested sample rate. */
    
    var preferredNumberOfInputChannels : Int32 { get }
    var numberOfInputChannels : Int32 { get }
    /* The actual number of channels given by the AudioSession. If
     singleChannelInput is enabled, then if this is more than one, a single
     channel will be selected for output. */
    
    var singleChannelInput : Bool { get }
    /* Set to True if a single channel's worth of samples should be picked out of
     the buffer being passed to the AudioProcessOperation */
    
    var channelIndexForSingleChannelInput : Int32 { get }
    /* Used to pick which channel is passed to the AudioProcessOperation if there is
     more than one input channel present */
    
    var preferredNumberOfOutputChannels : Int32 { get }
    var numberOfOutputChannels : Int32 { get }
    
    var preferredSamplesPerBuffer : Int32 { get }
    /* The AudioQueue will not always perfectly respect this but usually there will
     be this many samples in the given buffer. */
    
    
    /** Call this once after initialization to configure parameters, and then check
     what the actual values of those parameters are on those properties. */
    func configureAudioInOut(withPreferredSampleRate: Float,
                             preferredNumberOfInputChannels: Int32,
                             preferredNumberOfOutputChannels: Int32,
                             singleChannelInput: Bool,
                             channelIndexForSingleChannelInput: Int32,
                             preferredSamplesPerBuffer: Int32)
    
    /** After initialization and configuration, add an AudioDispatcher to accept
     buffers and initiate processing of buffers. */
    func addAudioDispatcher(_ audioDispatcher: AudioDispatcher!)
    
    /** After initialization and configuration, add an AudioSource to supply
     sample buffers to the output. */
    func addAudioSource(_ audioSource: AudioSource!)
    
    /** After configuration and adding an AudioDispatcher, start getting sample
     buffers from the microphone. */
    func startAudioIn() -> Bool
    
    /** End audio input. */
    func endAudioIn() -> Bool
    
    /** After configuration and adding an AudioSource, prime the output buffers and
     initiate playback/audio output for as long as the AudioSource supplies more
     than 0 samples. Stops the Audio Queue once AudioSource supplies no more
     samples. */
    func oneShotPlayAudioOut() -> Bool
}

//
//  SAMicrophoneInput.h
//  Sound Analyzer
//
//  Created by amddude on 7/25/14.
//  Copyright (c) 2014 dimnsionofsound. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AudioDispatcher;
@class AudioSource;

@interface SoundIOManager : NSObject

@property (nonatomic) float preferredSampleRate;
@property (nonatomic) float sampleRate;
/* Might be different than the requested sample rate. */

@property (nonatomic) int preferredNumberOfInputChannels;
@property (nonatomic) int numberOfInputChannels;
/* The actual number of channels given by the AudioSession. If
 singleChannelInput is enabled, then if this is more than one, a single
 channel will be selected for output. */

@property (nonatomic) BOOL singleChannelInput;
/* Set to True if a single channel's worth of samples should be picked out of
 the buffer being passed to the AudioProcessOperation */

@property (nonatomic) int channelIndexForSingleChannelInput;
/* Used to pick which channel is passed to the AudioProcessOperation if there is
 more than one input channel present */

@property (nonatomic) int preferredNumberOfOuputChannels;
@property (nonatomic) int numberOfOutputChannels;

@property (nonatomic) int preferredSamplesPerBuffer;
/* The AudioQueue will not always perfectly respect this but usually there will
 be this many samples in the given buffer. */


/** Call this once after initialization to configure parameters, and then check
 what the actual values of those parameters are on those properties. */
- (void)configureAudioInOutWithPreferredSampleRate:(float)sampleRate
                    preferredNumberOfInputChannels:(int)inputChannels
                   preferredNumberOfOutputChannels:(int)outputChannels
                                singleChannelInput:(BOOL)singleChannelInput
                 channelIndexForSingleChannelInput:(int)channelIndex
                         preferredSamplesPerBuffer:(int)preferredSamplesPerBuffer;

/** After initialization and configuration, add an AudioDispatcher to accept
 buffers and initiate processing of buffers. */
- (void) addAudioDispatcher: (AudioDispatcher *) audioDispatcher;

/** After initialization and configuration, add an AudioSource to supply
 sample buffers to the output. */
- (void) addAudioSource: (AudioSource *) audioSource;

/** After configuration and adding an AudioDispatcher, start getting sample
 buffers from the microphone. */
- (BOOL) startAudioIn;

/** End audio input. */
- (BOOL) endAudioIn;

/** After configuration, arm the audio output. Allocates buffers and sets up
 output queues. */
- (BOOL) armAudioOut;

/** Once Audio has finished playing (AudioSource supplies no more samples),
 disarm the audio output. Deallocates buffers and shuts down output Queues. */
- (BOOL) disarmAudioOut;

/** After configuration and adding an AudioSource, prime the output buffers and
 initiate playback/audio output for as long as the AudioSource supplies more
 than 0 samples. Stops the Audio Queue once AudioSource supplies no more 
 samples. */
- (void) oneShotPlayAudioOut;

- (instancetype) init;

@end

const int kNumberBuffers;

//
//  SAMicrophoneInput.h
//  Sound Analyzer
//
//  Created by amddude on 7/25/14.
//  Copyright (c) 2014 dimnsionofsound. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AudioDispatcher;

@interface SAMicrophoneInput : NSObject

@property (nonatomic) float preferredSampleRate;
@property (nonatomic) float sampleRate;
/* Might be different than the requested sample rate. */

@property (nonatomic) int preferredNumberOfChannels;
@property (nonatomic) int numberOfChannels;
/* The actual number of channels given by the AudioSession. If
 singleChannelOutput is enabled, then if this is more than one, a single
 channel will be selected for output. */

@property (nonatomic) BOOL singleChannelOutput;
/* Set to True if a single channel's worth of samples should be picked out of
 the buffer being passed to the AudioProcessOperation */

@property (nonatomic) int channelIndexForSingleChannelOutput;
/* Used to pick which channel is passed to the AudioProcessOperation if there is
 more than one input channel present */

@property (nonatomic) int preferredSamplesPerBuffer;
/* The AudioQueue will not always perfectly respect this but usually there will
 be this many samples in the given buffer. */


- (void) configureAudioInWithPreferredSampleRate: (float) sampleRate
                       preferredNumberOfChannels: (int) numChannels
                             singleChannelOutput: (BOOL) singleChannelOutput
              channelIndexForSingleChannelOutput: (int) channelIndex
                       preferredSamplesPerBuffer: (int) preferredSamplesPerBuffer;
- (void) addAudioDispatcher: (AudioDispatcher *) audioDispatcher;
- (BOOL) startAudioIn;
- (BOOL) endAudioIn;
- (instancetype) init;

@end

const int kNumberBuffers;

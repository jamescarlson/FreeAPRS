//
//  SAMicrophoneInput.m
//  Sound Analyzer
//
//  Created by amddude on 7/25/14.
//  Copyright (c) 2014 dimnsionofsound. All rights reserved.
//



#import "SAMicrophoneInput.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#include <Accelerate/Accelerate.h>
#define FAIL_ON_ERR(_X_) if ((status = (_X_)) != noErr) { goto failed; }

@implementation SAMicrophoneInput


const int kNumberBuffers = 3;

struct AQInputState {
AudioStreamBasicDescription  mDataFormat;                   // 2
AudioQueueRef                mQueue;                        // 3
AudioQueueBufferRef          mBuffers[kNumberBuffers];      // 4
AudioFileID                  mAudioFile;                    // 5
UInt32                       bufferByteSize;                // 6
SInt64                       mCurrentPacket;                // 7
bool                         mIsRunning;
};

SAMicrophoneInput *selfAlias;
FFTSetup fftSupport;
struct AQInputState state;

#pragma mark -- Audio session stuff

SAMicrophoneInput *selfAlias;
- (void) initializeSelfAlias {
    selfAlias = self;
}

- (SAMicrophoneInput *)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter]
         addObserver:self
            selector:@selector(handleInterruption:)
                name:@"AVAudioSessionInterruptionNotification"
              object:nil];
        [[NSNotificationCenter defaultCenter]
         addObserver:self
            selector:@selector(handleMediaServerReset:)
                name:@"AVAudioSessionMediaServicesWereResetNotification"
              object:nil];
        NSLog(@"SAMicrophoneInput was initialized");
        [self initializeSelfAlias];
    }
    return self;
}


- (void)ensureRecordPermission {
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        NSLog(@"Permission %u", granted);
    }];
}

- (void)configureAudioInput {

}

- (void)configureAudioSessionCategoryMode {
    NSError *setCategoryError = nil;
    NSError *setModeError = nil;
    BOOL success = [[AVAudioSession sharedInstance]
                    setCategory: AVAudioSessionCategoryPlayAndRecord
                    error: &setCategoryError];
    BOOL modeSuccess = [[AVAudioSession sharedInstance]
                        setMode:AVAudioSessionModeMeasurement
                        error:&setModeError];
    
    if (!success) { /* handle the error in setCategoryError */
        NSLog(@"Could not set audio session category, %@ %@", setCategoryError,
              [setCategoryError userInfo]);
    }
    if (!modeSuccess) {
        NSLog(@"Could not set audio session mode, %@ %@", setModeError,
              [setModeError userInfo]);
    }
}

- (void)handleMediaServerReset:(NSNotification *)note {
    BOOL success = [self endAudioIn];
    success = success && [self startAudioIn];
    if (!success) {
        NSLog(@"Failed to reinstate Audio Queue after media server reset");
    }
}

- (void)handleInterruption:(NSNotification *)note {
    NSDictionary *ud = [note userInfo];
    if (ud != nil) {
        NSNumber *what = [ud objectForKey:@"AVAudioSessionInterruptionTypeKey"];
        if ([what intValue] == AVAudioSessionInterruptionTypeBegan) {
            [self handleInterruptionStart];
        } else if ([what intValue] == AVAudioSessionInterruptionTypeEnded) {
            [self handleInterruptionEnd];
        } else {
            NSLog(@"Gooby pls, why interruption not well defined...");
        }
    }
}

- (void)handleInterruptionStart {
    [self endAudioIn];
    //FIXME??
}

- (void)handleInterruptionEnd {
    [self startAudioIn];
    //FIXME??
}

- (void)activateAudioSession;
{
    NSError * error = nil;
    AVAudioSession * session = [AVAudioSession sharedInstance];
    if (![session setActive:YES error:&error]) {
        NSLog(@"Could not activate audio session: %@ %@", error, [error userInfo]);
        return;
    }
}

#pragma mark - Get ready for Audio queues
#pragma mark Setup functions for AQ.

- (void) setupBasicDescription {
    UInt32 formatFlags = (0
                          | kAudioFormatFlagIsPacked
                          | kAudioFormatFlagIsSignedInteger
                          | 0 //kAudioFormatFlagsNativeEndian
                          );
    [[AVAudioSession sharedInstance] setPreferredInputNumberOfChannels:1 error:nil];
    NSInteger numChannelsP = [[AVAudioSession sharedInstance] inputNumberOfChannels];
    int numChannels = numChannelsP;
    NSLog(@"Number of channels: %d", numChannels);
    
    
    state.mDataFormat = (AudioStreamBasicDescription) {
        .mFormatID = kAudioFormatLinearPCM,
        .mFormatFlags = formatFlags,
        .mSampleRate = [[AVAudioSession sharedInstance] sampleRate],
        .mBitsPerChannel = 16,
        .mChannelsPerFrame = numChannels,
        .mBytesPerFrame = 2*numChannels,
        .mBytesPerPacket = 2*numChannels,
        .mFramesPerPacket = 1,
    };
    self.sampleRate = state.mDataFormat.mSampleRate;
    
    
}

- (void) setupState {
    [self setupBasicDescription];
    state.mIsRunning = YES;
    state.bufferByteSize = [self deriveBufferSizeForSamples:FFT_LEN];
}

- (void) allocateBuffers {
    OSStatus status = noErr;
    for (int i = 0; i < kNumberBuffers; i += 1) {           // 1
        FAIL_ON_ERR(AudioQueueAllocateBuffer (                       // 2
                                  state.mQueue,                               // 3
                                  state.bufferByteSize,                       // 4
                                  &state.mBuffers[i]                          // 5
                                              ));
        
        FAIL_ON_ERR(AudioQueueEnqueueBuffer (                        // 6
                                 state.mQueue,                               // 7
                                 state.mBuffers[i],                          // 8
                                 0,                                           // 9
                                 NULL                                         // 10
                                 ));
    }
failed:
    NSLog(@"Failed to allocate buffers, code %d", (int)status);
    //NSLog(@"Buffer byte size for buffer 1: %d", (uint)state.mBuffers[0]->mAudioDataByteSize);
}


- (UInt32) deriveBufferSizeForSeconds:(Float64) seconds {
    static const int maxBufferSize = 0x50000;
    
    int maxPacketSize = state.mDataFormat.mBytesPerPacket;
    
    Float64 numBytesForTime =
    state.mDataFormat.mSampleRate * maxPacketSize * seconds;
    UInt32 result = (numBytesForTime < maxBufferSize ?
                     numBytesForTime : maxBufferSize);
    return result;
}

- (UInt32) deriveBufferSizeForSamples:(UInt32) samples {
    int maxPacketSize = state.mDataFormat.mBytesPerPacket;
    UInt32 result = maxPacketSize * samples;
    return result;
}

static void HandleInputBuffer (
                               void                                *aqData,             // 1
                               AudioQueueRef                       inAQ,                // 2
                               AudioQueueBufferRef                 inBuffer,            // 3
                               const AudioTimeStamp                *inStartTime,        // 4
                               UInt32                              inNumPackets,        // 5
                               const AudioStreamPacketDescription  *inPacketDesc        // 6
) {
    //do stuff
    
    SInt16 *frame = inBuffer->mAudioData;
    if (state.mIsRunning == 0) {
        NSLog(@"Audio queue callback called when AQ was not running");
        return;
    }
    NSLog(@"First sample: %d", frame[0]);
    
    AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
}

#pragma mark - Start and Stop

- (BOOL) startAudioIn {
    [self configureAudioSessionCategoryMode];
    [self activateAudioSession];
    [self ensureRecordPermission];
    [self setupState];
    
    NSAssert(state.mQueue == NULL, @"Queue is already setup");
    
    OSStatus status;
    
    FAIL_ON_ERR(AudioQueueNewInput(&state.mDataFormat,
                       HandleInputBuffer,
                       &state,
                       CFRunLoopGetMain(),
                       nil,
                       0,
                                   &state.mQueue));
    [self allocateBuffers];
    
    FAIL_ON_ERR(AudioQueueStart(state.mQueue, NULL));
    
    state.mIsRunning = YES;
    NSLog(@"Audio Started");
    return YES;

failed:
    NSLog(@"Aduio failed to start");
    // Error handling...
    if (state.mQueue != NULL) {
        AudioQueueDispose(state.mQueue, YES);
        state.mQueue = NULL;
    }
    
    return NO;
}

- (BOOL) endAudioIn {
    NSLog(@"Audio stopped");
    NSAssert(state.mQueue != NULL, @"Queue is not setup");
    
    OSStatus status;
    
    FAIL_ON_ERR(AudioQueueStop(state.mQueue, YES));
    FAIL_ON_ERR(AudioQueueDispose(state.mQueue, YES));
    state.mQueue = NULL;
    state.mIsRunning = NO;
    return YES;
    
failed:
    // Error handling...
    
    NSLog(@"Failed to stop audio queue.");
    
    return NO;
}


-(void) dealloc {
    //Don't crash the app! Get out of notification center before going away~~~
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end

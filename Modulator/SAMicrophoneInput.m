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
#import <FreeAPRS-Swift.h>

#define FAIL_ON_ERR(_X_) if ((status = (_X_)) != noErr) { goto failed; }

@interface SAMicrophoneInput()

@property (strong, nonatomic) AudioDispatcher* dispatcher;

@end



@implementation SAMicrophoneInput

const int kNumberBuffers = 3;

struct AQInputState {
AudioStreamBasicDescription mDataFormat;                   // 2
AudioQueueRef               mQueue;                        // 3
AudioQueueBufferRef         mBuffers[kNumberBuffers];      // 4
AudioFileID                 mAudioFile;                    // 5
UInt32                      bufferByteSize;                // 6
SInt64                      mCurrentPacket;                // 7
bool                        mIsRunning;
__unsafe_unretained
    AudioDispatcher*        audioDispatcher;
};


FFTSetup fftSupport;
struct AQInputState state;

#pragma mark -- Audio session stuff


- (SAMicrophoneInput *)init{
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
        [[AVAudioSession sharedInstance] addObserver:self forKeyPath:@"sampleRate" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)configureAudioInWithPreferredSampleRate:(float)sampleRate
                      preferredNumberOfChannels:(int)numChannels
                            singleChannelOutput:(BOOL)singleChannelOutput
             channelIndexForSingleChannelOutput:(int)channelIndex
                      preferredSamplesPerBuffer:(int)preferredSamplesPerBuffer {
    self.preferredSampleRate = sampleRate;
    self.preferredNumberOfChannels = numChannels;
    self.singleChannelOutput = singleChannelOutput;
    self.channelIndexForSingleChannelOutput = channelIndex;
    self.preferredSamplesPerBuffer = preferredSamplesPerBuffer;

    [self configureAudioSession];
    
}

- (void)configureAudioSession {
    [self configureAudioSessionCategoryMode];
    [self activateAudioSession];
    [self ensureRecordPermission];
    [self configureAudioSessionParameters];
    [self setupBasicDescription];
}

- (void)addAudioDispatcher:(AudioDispatcher *) audioDispatcher {
    self.dispatcher = audioDispatcher;
}

- (void)ensureRecordPermission {
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        NSLog(@"Permission %u", granted);
    }];
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
    [self configureAudioSession];
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
    [self configureAudioSession];
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

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"sampleRate"]) {
        self.sampleRate = [[AVAudioSession sharedInstance] sampleRate];
        NSLog(@"observed sample rate change, is now %f", self.sampleRate);
    }
}

/* Should be called after the AudioSession is activated to get correct values
 of sampleRate and numberOfChannels. Would assert this but there is no way to
 check. */
- (void) configureAudioSessionParameters {
    [[AVAudioSession sharedInstance] setPreferredInputNumberOfChannels:self.preferredNumberOfChannels error:nil];
    [[AVAudioSession sharedInstance] setPreferredSampleRate:self.preferredSampleRate error:nil];
    
    /* Cast because if we have more channels than 2**31 we're having other issues. */
    self.numberOfChannels = (int)[[AVAudioSession sharedInstance] inputNumberOfChannels];
    self.sampleRate = [[AVAudioSession sharedInstance] sampleRate];
    
    NSLog(@"Number of channels: %d", self.numberOfChannels);
    NSLog(@"sampleRate: %f", self.sampleRate);
}

/* Should be called after AudioSession's parameters have been set and verified. */
- (void) setupBasicDescription {
    UInt32 formatFlags = (0
                          | kAudioFormatFlagIsPacked
                          | kAudioFormatFlagIsSignedInteger
                          | 0 //kAudioFormatFlagsNativeEndian
                          );

    state.mDataFormat = (AudioStreamBasicDescription) {
        .mFormatID = kAudioFormatLinearPCM,
        .mFormatFlags = formatFlags,
        .mSampleRate = self.sampleRate,
        .mBitsPerChannel = 16,
        .mChannelsPerFrame = self.numberOfChannels,
        .mBytesPerFrame = 2*self.numberOfChannels,
        .mBytesPerPacket = 2*self.numberOfChannels,
        .mFramesPerPacket = 1,
    };
    
}

- (void) setupState {
    state.mIsRunning = YES;
    state.bufferByteSize = self.preferredSamplesPerBuffer;
    state.audioDispatcher = self.dispatcher;
}

- (void) allocateBuffers {
    OSStatus status = noErr;
    for (int i = 0; i < kNumberBuffers; i += 1) {           // 1
        FAIL_ON_ERR(AudioQueueAllocateBuffer (                       // 2
                                  state.mQueue,                              // 3
                                  state.bufferByteSize,                      // 4
                                  &state.mBuffers[i]                         // 5
                                              ));
        
        FAIL_ON_ERR(AudioQueueEnqueueBuffer (                        // 6
                                 state.mQueue,                               // 7
                                 state.mBuffers[i],                          // 8
                                 0,                                          // 9
                                 NULL                                        // 10
                                 ));
        
    }
    
    return;
    
failed:
    NSLog(@"Failed to allocate buffers, code %d", (int)status);
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
    
    int16_t *frame = inBuffer->mAudioData;
    if (state.mIsRunning == 0 || frame == NULL) {
        NSLog(@"Audio queue callback called when AQ was not running");
        return;
    }
    
    SAMicrophoneInput *this = (__bridge SAMicrophoneInput *)aqData;
    
    int lengthSamples = inBuffer->mAudioDataByteSize / 2;
    
    [this.dispatcher processWithSamples:frame length:lengthSamples
                               channels:state.mDataFormat.mChannelsPerFrame
                           channelIndex:this.channelIndexForSingleChannelOutput];
    
    AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
}

#pragma mark - Start and Stop

- (BOOL) startAudioIn {
    [self setupState];
    
    NSAssert(state.mQueue == NULL, @"Queue is already setup");
    
    OSStatus status;
    
    FAIL_ON_ERR(AudioQueueNewInput(&state.mDataFormat,
                       HandleInputBuffer,
                       CFBridgingRetain(self),
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
    [[AVAudioSession sharedInstance] removeObserver:self forKeyPath:@"sampleRate"];
}


@end

//
//  SAMicrophoneInput.m
//  Sound Analyzer
//
//  Created by amddude on 7/25/14.
//  Copyright (c) 2014 dimnsionofsound. All rights reserved.
//



#import "AudioIOManager.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#include <Accelerate/Accelerate.h>
#import <FreeAPRS-Swift.h>

#define FAIL_ON_ERR(_X_) if ((status = (_X_)) != noErr) { goto failed; }

@interface AudioIOManager()

@property (strong, nonatomic) AudioDispatcher* dispatcher;
@property (strong, nonatomic) AudioSource* source;

@end



@implementation AudioIOManager

const int kNumberBuffers = 3;

struct AQInputState {
AudioStreamBasicDescription mDataFormat;                   // 2
AudioQueueRef               mQueue;                        // 3
AudioQueueBufferRef         mBuffers[kNumberBuffers];      // 4
UInt32                      bufferByteSize;                // 6
bool                        mIsRunning;
__unsafe_unretained
    AudioDispatcher*        audioDispatcher;
};

struct AQOutputState {
    AudioStreamBasicDescription   mDataFormat;                    // 2
    AudioQueueRef                 mQueue;                         // 3
    AudioQueueBufferRef           mBuffers[kNumberBuffers];       // 4
    UInt32                        bufferByteSize;                 // 6
    bool                          mIsRunning;                     // 10
    bool                          primed;
};

FFTSetup fftSupport;
struct AQInputState inputState;
struct AQOutputState outputState;

#pragma mark -- Audio session stuff

+ (id<AudioIOManagerProtocol>)sharedInstance {
    static AudioIOManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (AudioIOManager *)init{
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

- (void)configureAudioInOutWithPreferredSampleRate:(float)sampleRate
                    preferredNumberOfInputChannels:(int)inputChannels
                   preferredNumberOfOutputChannels:(int)outputChannels
                                singleChannelInput:(BOOL)singleChannelInput
                 channelIndexForSingleChannelInput:(int)channelIndex
                         preferredSamplesPerBuffer:(int)preferredSamplesPerBuffer {
    self.preferredSampleRate = sampleRate;
    self.preferredNumberOfInputChannels = inputChannels;
    self.preferredNumberOfOutputChannels = outputChannels;
    self.singleChannelInput = singleChannelInput;
    self.channelIndexForSingleChannelInput = channelIndex;
    self.preferredSamplesPerBuffer = preferredSamplesPerBuffer;

    [self configureAudioSession];
    
    NSLog(@"AudioIOManager configured");
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

- (void)addAudioSource:(AudioSource *)audioSource {
    self.source = audioSource;
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

- (void)activateAudioSession
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
    [[AVAudioSession sharedInstance] setPreferredInputNumberOfChannels:self.preferredNumberOfInputChannels error:nil];
    [[AVAudioSession sharedInstance] setPreferredSampleRate:self.preferredSampleRate error:nil];
    [[AVAudioSession sharedInstance] setPreferredOutputNumberOfChannels:self.preferredNumberOfOutputChannels error:nil];
    /* Cast because if we have more channels than 2**31 we're having other issues. */
    self.numberOfInputChannels = (int)[[AVAudioSession sharedInstance] inputNumberOfChannels];
    self.sampleRate = [[AVAudioSession sharedInstance] sampleRate];
    self.numberOfOutputChannels = (int)[[AVAudioSession sharedInstance] outputNumberOfChannels];
    
    NSLog(@"Number of input channels: %d", self.numberOfInputChannels);
    NSLog(@"sampleRate: %f", self.sampleRate);
    NSLog(@"Number of output channels: %d", self.numberOfOutputChannels);
}

/* Should be called after AudioSession's parameters have been set and verified. */
- (void) setupBasicDescription {
    UInt32 formatFlags = (0
                          | kAudioFormatFlagIsPacked
                          | kAudioFormatFlagIsSignedInteger
                          | 0 //kAudioFormatFlagsNativeEndian
                          );

    inputState.mDataFormat = (AudioStreamBasicDescription) {
        .mFormatID = kAudioFormatLinearPCM,
        .mFormatFlags = formatFlags,
        .mSampleRate = self.sampleRate,
        .mBitsPerChannel = 16,
        .mChannelsPerFrame = self.numberOfInputChannels,
        .mBytesPerFrame = 2*self.numberOfInputChannels,
        .mBytesPerPacket = 2*self.numberOfInputChannels,
        .mFramesPerPacket = 1,
    };
    
    outputState.mDataFormat = (AudioStreamBasicDescription) {
        .mFormatID = kAudioFormatLinearPCM,
        .mFormatFlags = formatFlags,
        .mSampleRate = self.sampleRate,
        .mBitsPerChannel = 16,
        .mChannelsPerFrame = self.numberOfOutputChannels,
        .mBytesPerFrame = 2*self.numberOfOutputChannels,
        .mBytesPerPacket = 2*self.numberOfOutputChannels,
        .mFramesPerPacket = 1,
    };
    
}

- (void) setupInputState {
    inputState.mIsRunning = YES;
    inputState.bufferByteSize = self.preferredSamplesPerBuffer;
    inputState.audioDispatcher = self.dispatcher;
}

- (void) setupOutputState {
    outputState.mIsRunning = YES;
    outputState.bufferByteSize = self.preferredSamplesPerBuffer;
    outputState.primed = NO;
}

- (void) allocateInputBuffers {
    OSStatus status = noErr;
    for (int i = 0; i < kNumberBuffers; i += 1) {           // 1
        FAIL_ON_ERR(AudioQueueAllocateBuffer (                       // 2
                                  inputState.mQueue,                              // 3
                                  inputState.bufferByteSize,                      // 4
                                  &inputState.mBuffers[i]                         // 5
                                              ));
        
        FAIL_ON_ERR(AudioQueueEnqueueBuffer (                        // 6
                                 inputState.mQueue,                               // 7
                                 inputState.mBuffers[i],                          // 8
                                 0,                                          // 9
                                 NULL                                        // 10
                                 ));
        
    }
    
    return;
    
failed:
    NSLog(@"Failed to allocate buffers, code %d", (int)status);
}

- (void) allocateOutputBuffers {
    OSStatus status = noErr;
    for (int i = 0; i < kNumberBuffers; i += 1) {
        FAIL_ON_ERR(AudioQueueAllocateBuffer (
                                  outputState.mQueue,
                                  outputState.bufferByteSize,
                                  &outputState.mBuffers[i]
                                              ));
    }
    
    return;
    
failed:
    NSLog(@"Failed to allocate buffers, code %d", (int)status);
}

- (void) primeOutputBuffers {
    for (int i = 0; i < kNumberBuffers; i += 1) {
        if (outputState.mIsRunning) {
            NSLog(@"Calling callback to prime buffers, %d", i);
            HandleOutputBuffer((__bridge void *)(self), outputState.mQueue, outputState.mBuffers[i]);
            
        }
    }
}

- (UInt32) deriveBufferSizeForSeconds:(Float64) seconds {
    static const int maxBufferSize = 0x50000;
    
    int maxPacketSize = inputState.mDataFormat.mBytesPerPacket;
    
    Float64 numBytesForTime =
    inputState.mDataFormat.mSampleRate * maxPacketSize * seconds;
    UInt32 result = (numBytesForTime < maxBufferSize ?
                     numBytesForTime : maxBufferSize);
    return result;
}

- (UInt32) deriveBufferSizeForSamples:(UInt32) samples {
    int maxPacketSize = inputState.mDataFormat.mBytesPerPacket;
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
    int16_t *frame = inBuffer->mAudioData;
    if (inputState.mIsRunning == 0 || frame == NULL) {
        NSLog(@"Audio queue callback called when AQ was not running");
        return;
    }
    
    AudioIOManager *this = (__bridge AudioIOManager *)aqData;
    
    int lengthSamples = inBuffer->mAudioDataByteSize / 2;
    
    [this.dispatcher processWithSamples:frame length:lengthSamples
                               channels:inputState.mDataFormat.mChannelsPerFrame
                           channelIndex:this.channelIndexForSingleChannelInput];
    
    AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
}

static void HandleOutputBuffer (
                                void                 *aqData,
                                AudioQueueRef        inAQ,
                                AudioQueueBufferRef  inBuffer
                                ) {
    AudioIOManager *this = (__bridge AudioIOManager *)aqData;
    
    // Get audio to output from Swift Code
    
    if (outputState.mIsRunning) {
        int numBytes = [this.source getSamplesWithBuffer:inBuffer];
        
        if (numBytes <= 0) { outputState.mIsRunning = NO; }
        
        
        inBuffer->mAudioDataByteSize = numBytes;
        AudioQueueEnqueueBuffer(outputState.mQueue, inBuffer, 0, NULL);
        
        NSLog(@"Enqueued buffer with %d bytes", numBytes);
        return;
    }
    // Stop the queue if there are no more samples to play
    outputState.mIsRunning = NO;
    if (outputState.primed) {
        AudioQueueStop(outputState.mQueue, NO);
        CFBridgingRelease(aqData);
        
        [this disarmAudioOut];
    }
    
}

#pragma mark - Start and Stop

    /** After configuration, arm the audio output. Allocates buffers and sets up
     output queues. */
- (BOOL) armAudioOut {
    [self setupOutputState];
    
    NSAssert(outputState.mQueue == NULL, @"Queue is already setup");
    
    OSStatus status;
    
    FAIL_ON_ERR(AudioQueueNewOutput(&outputState.mDataFormat,
                                    HandleOutputBuffer,
                                    CFBridgingRetain(self),
                                    CFRunLoopGetCurrent(),
                                    kCFRunLoopCommonModes,
                                    0,
                                    &outputState.mQueue))
    
    Float32 gain = 1.0;
    AudioQueueSetParameter (
                            outputState.mQueue,
                            kAudioQueueParam_Volume,
                            gain
                            );
    
    [self allocateOutputBuffers];
    NSLog(@"Audio Out Ready");
    return YES;
    
failed:
    NSLog(@"Audio output failed to start");
    
    if (outputState.mQueue != NULL) {
        AudioQueueDispose(outputState.mQueue, YES);
        outputState.mQueue = NULL;
    }
    
    return NO;
}

- (BOOL) oneShotPlayAudioOut {
    if (outputState.mQueue != NULL) {
        NSLog(@"Stop mashing this function!");
        return NO;
    }
    
    [self armAudioOut];
    
    outputState.mIsRunning = YES;
    if (!outputState.primed) {
        [self primeOutputBuffers];
        outputState.primed = YES;
    }
    AudioQueueStart(outputState.mQueue, NULL);
    return YES;
}

    /** Once Audio has finished playing (AudioSource supplies no more samples),
     disarm the audio output. Deallocates buffers and shuts down output Queues. */
- (BOOL) disarmAudioOut {
    NSLog(@"Audio output disarmed");
    NSAssert(outputState.mQueue != NULL, @"Queue is not setup");
    
    OSStatus status;
    
    FAIL_ON_ERR(AudioQueueDispose(outputState.mQueue, NO));
    outputState.mQueue = NULL;
    outputState.mIsRunning = NO;
    outputState.primed = NO;
    return YES;
    
failed:
    // Error handling...
    
    NSLog(@"Failed to stop input audio queue.");
    
    return NO;
}

- (BOOL) startAudioIn {
    [self setupInputState];
    
    NSAssert(inputState.mQueue == NULL, @"Queue is already setup");
    
    OSStatus status;
    
    FAIL_ON_ERR(AudioQueueNewInput(&inputState.mDataFormat,
                       HandleInputBuffer,
                       CFBridgingRetain(self),
                       CFRunLoopGetMain(),
                       nil,
                       0,
                                   &inputState.mQueue));
    [self allocateInputBuffers];
    
    FAIL_ON_ERR(AudioQueueStart(inputState.mQueue, NULL));
    
    inputState.mIsRunning = YES;
    NSLog(@"Audio input Started");
    return YES;

failed:
    NSLog(@"Audio input failed to start");
    // Error handling...
    if (inputState.mQueue != NULL) {
        AudioQueueDispose(inputState.mQueue, YES);
        inputState.mQueue = NULL;
    }
    
    return NO;
}

- (BOOL) endAudioIn {
    NSLog(@"Audio input stopped");
    NSAssert(inputState.mQueue != NULL, @"Queue is not setup");
    
    OSStatus status;
    
    FAIL_ON_ERR(AudioQueueStop(inputState.mQueue, YES));
    FAIL_ON_ERR(AudioQueueDispose(inputState.mQueue, YES));
    inputState.mQueue = NULL;
    inputState.mIsRunning = NO;
    return YES;
    
failed:
    // Error handling...
    
    NSLog(@"Failed to stop input audio queue.");
    
    return NO;
}


-(void) dealloc {
    //Don't crash the app! Get out of notification center before going away~~~
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[AVAudioSession sharedInstance] removeObserver:self forKeyPath:@"sampleRate"];
}


@end

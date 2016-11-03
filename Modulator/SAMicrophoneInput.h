//
//  SAMicrophoneInput.h
//  Sound Analyzer
//
//  Created by amddude on 7/25/14.
//  Copyright (c) 2014 dimnsionofsound. All rights reserved.
//

#import <Foundation/Foundation.h>

#define FFT_LEN 4096

@class AudioDispatcher;

@interface SAMicrophoneInput : NSObject

@property (nonatomic) float sampleRate;

- (BOOL) startAudioIn;
- (BOOL) endAudioIn;
- (instancetype) initWith:(AudioDispatcher *) audioDispatcher;

@end

const int kNumberBuffers;

//
//  SAMicrophoneInput.h
//  Sound Analyzer
//
//  Created by amddude on 7/25/14.
//  Copyright (c) 2014 dimnsionofsound. All rights reserved.
//

#import <Foundation/Foundation.h>
#define FFT_LEN 8192

@interface SAMicrophoneInput : NSObject

@property (nonatomic) long sampleRate;


- (BOOL) startAudioIn;
- (BOOL) endAudioIn;

@end

const int kNumberBuffers;

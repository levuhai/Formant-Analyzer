//
//  AudioDeviceManager.h
//  FormantPlotter
//
//  Created by Muhammad Akmal Butt on 1/20/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

/*
 *******************************************************
 
 This is the main audio capturing file. It uses AudioUnit and AudioToolbox frameworks.
 There is a call-back routine that is called every time our speech sampler hardware
 has captured 1024 samples from the speech input (microphone). The default sampling
 rate of 44100 is left as it. We could have gone to 22050.
 
 *******************************************************
 */

#import <Foundation/Foundation.h>
#include <AudioUnit/AudioUnit.h>
#include <AudioToolbox/AudioServices.h>
#include <stdio.h>
#import <complex.h>
#import "Constants.h"

# define ORDER 20

#define EPS 2.0e-6
#define EPSS 1.0e-7
#define MR 8
#define MT 10
#define MAXIT (MT*MR)

@interface LPCAudioController : NSObject {
    
@public
	int audioproblems; 
    unsigned long bufferEnergy;        // Sum of squres of 1024 captured samples.
    unsigned long energyThreshold;     // This gets value from FirstViewController through slider update function.
    short int *longBuffer;             // Just declared here. Actual buffer is part of FirstViewController.
    int bufferSegCount;
    int bufferLenght;
    BOOL drawing;
    BOOL needReset;           // Flags that are visible in the FirstViewController. Indicate status of capturing

}

//-(short int*)buffer;
-(void)calculateFormants;
-(double)firstFFreq;
-(double)secondFFreq;
-(double)thirdFFreq;
-(double)fourthFFreq;

- (BOOL)deactivateAudioSession;
- (BOOL)activateAudioSession;

@end

//
//  AudioDeviceManager.m
//  FormantPlotter
//
//  Created by Muhammad Akmal Butt on 1/20/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "LPCAudioController.h"

@implementation LPCAudioController {
    int decimatedEndIdx;
    int truncatedStartIdx, truncatedEndIdx;
    int strongStartIdx, strongEndIdx;
    short int *dataBuffer;
    int dataBufferLength;
    double _firstFFreq, _secondFFreq, _thirdFFreq, _fourthFFreq;
}

AudioComponentInstance audioUnit;
AudioStreamBasicDescription audioFormat;
AudioBufferList* bufferList;
BOOL startedCallback;
BOOL noInterrupt;

//called when there is a new buffer of 1024 input samples available. 
static OSStatus recordingCallback(void* inRefCon,AudioUnitRenderActionFlags* ioActionFlags,const AudioTimeStamp* inTimeStamp,UInt32 inBusNumber,UInt32 inNumberFrames,AudioBufferList* ioData)
{
    int j;
    unsigned long bufferEnergy;
    
    // Create a local copy inside static function so that data could be accessed
    LPCAudioController *manager = (__bridge LPCAudioController *)inRefCon;
    
	if(startedCallback && noInterrupt)
    {
        OSStatus result = AudioUnitRender(audioUnit,ioActionFlags,inTimeStamp,inBusNumber,inNumberFrames,bufferList);
		switch(result){
			case kAudioUnitErr_InvalidProperty: 
            {
                NSLog(@"AudioUnitRender Failed: Invalid Property"); 
                break;
            }
			case -50: 
            {
                NSLog(@"AudioUnitRender Failed: Invalid Parameter(s)"); 
                break;
            }
		}
	}
    
    if (manager->needReset == TRUE)
    {
        manager->bufferSegCount = 0;
        manager->bufferLenght = 0;
        manager->needReset = FALSE;
        // Clear all entries from the long audio buffer in audioDeviceManager.
//        for (int j=0; j<1024000; j++) {
//            manager->longBuffer[j] = 0;
//        }
        
    }
    
    // If everything is OK above and we did not exit, we have a valid buffer. Compute its energy.
    short signed int *source= (short signed int *)bufferList->mBuffers[0].mData;
    bufferEnergy = 0;
    for (j = 0; j < inNumberFrames; j++) {
        bufferEnergy = bufferEnergy + source[j]*source[j];
    }
    
    // If energy is above the threshold, copy 1024 samples to the long buffer.
    
    if (bufferEnergy > manager->energyThreshold/8 )
    {
        short signed int *source= (short signed int *)bufferList->mBuffers[0].mData; 
        for (j = 0; j < inNumberFrames; j++) {
            manager->longBuffer[j + manager->bufferSegCount * inNumberFrames] = source[j];
        }
        manager->bufferSegCount += 1;
    }
//    else       // energy in 1024 sample buffer is below 20% of starting threshold. Stop capturing.
//    {
//        for (j = 0; j < inNumberFrames; j++) {
//            manager->longBuffer[j + manager->bufferSegCount * inNumberFrames] = 0;
//        }
//        manager->bufferSegCount += 1;
//    }
    manager->bufferLenght = manager->bufferSegCount *inNumberFrames;
    manager->drawing = YES;
    return noErr;
}

void callbackInterruptionListener(void* inClientData, UInt32 inInterruption)
{
	LPCAudioController *manager = (__bridge LPCAudioController *)inClientData;
	if(inInterruption) {
		noInterrupt = NO;
		[manager closeDownAudioDevice];
		startedCallback	= NO;
	}
	else {
		if (noInterrupt==NO) {
			[manager setUpAudioDevice]; //restart audio session
			noInterrupt = YES;
		}
	}
}

-(void)setUpData {
	bufferList = (AudioBufferList*) malloc(sizeof(AudioBufferList));
	bufferList->mNumberBuffers = 1; //mono input
	for(UInt32 i=0;i<bufferList->mNumberBuffers;i++)
        
	{
		bufferList->mBuffers[i].mNumberChannels = 1;
		bufferList->mBuffers[i].mDataByteSize = (1024*2) * 2; 
		bufferList->mBuffers[i].mData = malloc(bufferList->mBuffers[i].mDataByteSize);
	}
    
    longBuffer = (short int *)(malloc(1024*5 * sizeof(short int)));
}

-(void)freeData {
	for(UInt32 i=0;i<bufferList->mNumberBuffers;i++) {
		free(bufferList->mBuffers[i].mData);
	}	
	free(bufferList);
    
    free(longBuffer);
}

//lots of setup required
-(OSStatus)setUpAudioDevice {
	OSStatus status;
    drawing = NO;
	startedCallback = NO;
	noInterrupt = YES; 
	
	// Describe audio component
	AudioComponentDescription desc;
	desc.componentType = kAudioUnitType_Output;
	desc.componentSubType = kAudioUnitSubType_RemoteIO;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
	//setup AudioSession for safety (interruption handling):
	AudioSessionInitialize(NULL,NULL,callbackInterruptionListener,(__bridge void *)(self));
	AudioSessionSetActive(true);
	
	UInt32 sizeofdata;
    
	NSLog(@"Audio session details\n");
	
	UInt32 audioavailableflag; 
	
	//can check whether input plugged in
	sizeofdata= sizeof(audioavailableflag); 
	status= AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable,&sizeofdata,&audioavailableflag);
	
	//no input capability
	if(audioavailableflag==0) {
		
		return 1; 
	}
		
	UInt32 numchannels; 
	sizeofdata= sizeof(numchannels); 
	status= AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareInputNumberChannels,&sizeofdata,&numchannels);
		
	sizeofdata= sizeof(numchannels); 
	status= AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareOutputNumberChannels,&sizeofdata,&numchannels);
	
	Float64 samplerate; 
	samplerate = 44100.0; //44100.0; //supports and changes to 22050.0 or 48000.0 too!; //44100.0; 
	status= AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareSampleRate,sizeof(samplerate),&samplerate);
	
	sizeofdata= sizeof(samplerate); 
	status= AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate,&sizeofdata,&samplerate);
    
	NSLog(@"Device sample rate %5.0f \n",samplerate);
	
	//set preferred hardward buffer size of 1024; part of assumptions in callbacks
	
	Float32 iobuffersize = 1024.0/44100.0; 
	status= AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration,sizeof(iobuffersize),&iobuffersize);
	
	
	sizeofdata= sizeof(iobuffersize); 
	status= AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareIOBufferDuration,&sizeofdata,&iobuffersize);
	
	NSLog(@"Hardware buffer size %4.1f mSec.\n",iobuffersize*1000);
	
	//there are other possibilities
	UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord; //both input and output
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,sizeof(audioCategory),&audioCategory);
	
	// Get component
	AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
	
	// Get audio units
	status = AudioComponentInstanceNew(inputComponent, &audioUnit);
	
	if(status!= noErr) {
		
		NSLog(@"failure at AudioComponentInstanceNew\n"); 
		
		return status; 
	}; 
	
	UInt32 flag = 1;
	//UInt32 kOutputBus = 0;
	UInt32 kInputBus = 1;
	
	// Enable IO for recording
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioOutputUnitProperty_EnableIO, 
								  kAudioUnitScope_Input, 
								  kInputBus,
								  &flag, 
								  sizeof(flag));
	
	if(status!= noErr) {
		NSLog(@"failure at AudioUnitSetProperty 1\n");
		return status; 
	};
    
    //will be used by code below for defining bufferList, critical that this is set-up second
	// Describe format; not stereo for audio input! 
	audioFormat.mSampleRate			= 44100.00;
	audioFormat.mFormatID			= kAudioFormatLinearPCM;
	audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	audioFormat.mFramesPerPacket	= 1;
	audioFormat.mChannelsPerFrame	= 1;
	audioFormat.mBitsPerChannel		= 16;
	audioFormat.mBytesPerPacket		= 2;
	audioFormat.mBytesPerFrame		= 2;
	
	
	//for input recording
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioUnitProperty_StreamFormat, 
								  kAudioUnitScope_Output, 
								  kInputBus, 
								  &audioFormat, 
								  sizeof(audioFormat));
	
	
	if(status!= noErr) {
		
		NSLog(@"failure at AudioUnitSetProperty 4\n"); 
		
		return status; 
	}; 
	
	// Set input callback
	AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc = recordingCallback;
	callbackStruct.inputProcRefCon = (__bridge void *)(self);
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioOutputUnitProperty_SetInputCallback, 
								  kAudioUnitScope_Global, 
								  kInputBus, 
								  &callbackStruct, 
								  sizeof(callbackStruct));
	
	if(status!= noErr) {
		NSLog(@"failure at AudioUnitSetProperty 5\n");
		return status; 
	}; 
    	
	UInt32 allocFlag = 1;
	status= AudioUnitSetProperty(audioUnit,kAudioUnitProperty_ShouldAllocateBuffer,kAudioUnitScope_Input,1,&allocFlag,sizeof(allocFlag)); // == noErr)
	
	if(status!= noErr) {
		NSLog(@"failure at AudioUnitSetProperty 7\n");
		return status; 
	}; 
	
	status = AudioUnitInitialize(audioUnit);
	
	if(status == noErr)
	{
        
	}
	else {
		
		NSLog(@"failure at AudioUnitSetProperty 8\n"); 
		
		return status; 
	}	
	
	status = AudioOutputUnitStart(audioUnit);
	
	if (status == noErr) {
		
		audioproblems = 0; 
        
		startedCallback = YES;
        
	} else
	{
		
		UIAlertView *anAlert = [[UIAlertView alloc] initWithTitle:@"Problem with audio setup" message:@"Are you on an ipod touch without headphone microphone? Concat requires audio input, please make sure you have a microphone. Either set this up or hit Home button to exit" delegate:self cancelButtonTitle:@"Press me then plugin in microphone" otherButtonTitles:nil];
		[anAlert show];
	}
	return status; 
}

-(void)closeDownAudioDevice{
	OSStatus status = AudioOutputUnitStop(audioUnit);
	if(startedCallback) {
        startedCallback	= NO;
	}
	AudioUnitUninitialize(audioUnit);
	AudioSessionSetActive(false);
}

// Four getter functions to export four formant frequencies back to firstViewController
-(double) firstFFreq
{
    return _firstFFreq;
}

-(double) secondFFreq
{
    return _secondFFreq;
}

-(double) thirdFFreq
{
    return _thirdFFreq;
}

-(double) fourthFFreq
{
    return _fourthFFreq;
}

-(void)calculateFormants {
    // A few variable used in plotting of H(w).
    int i,j, k, dummo;
    double *formantFrequencies;
    double dummyFrequency;
    
    dataBuffer = self->longBuffer;
    dataBufferLength = self->bufferLenght;
    //NSLog(@"bufferLenght %d",self->bufferLenght);
    self->needReset = TRUE;
    
    // https://github.com/fulldecent/formant-analyzer
    // First we find the truncating start and end indices
    [self removeSilence];
    [self removeTails];
    [self decimateDataBuffer];
    
    // Find ORDER+1 autocorrelation coefficient
    double *Rxx = (double *)(malloc((ORDER + 1) * sizeof(double)));
    double *pCoeff = (double *)(malloc((ORDER + 1) * sizeof(double)));
    
    for (int delayIdx = 0; delayIdx <= ORDER; delayIdx++) {
        double corrSum = 0;
        for (int dataIdx = 0; dataIdx < (decimatedEndIdx - delayIdx); dataIdx++) {
            corrSum += (dataBuffer[dataIdx] * dataBuffer[dataIdx + delayIdx]);
        }
        
        Rxx[delayIdx] = corrSum;
    }
    
    // Now solve for the predictor coefficiens.
    double pError = Rxx[0];                             // initialise error to total power
    pCoeff[0] = 1.0;                                    // first coefficient must be = 1
    
    // for each coefficient in turn
    for (k = 1 ; k <= ORDER ; k++) {
        
        // find next reflection coeff from pCoeff[] and Rxx[]
        double rcNum = 0;
        for (int i = 1 ; i <= k ; i++)
        {
            rcNum -= pCoeff[k-i] * Rxx[i];
        }
        
        pCoeff[k] = rcNum/pError;
        
        // perform recursion on pCoeff[]
        for (i = 1 ; i <= k/2 ; i++) {
            double pci  = pCoeff[i] + pCoeff[k] * pCoeff[k-i];
            double pcki = pCoeff[k-i] + pCoeff[k] * pCoeff[i];
            pCoeff[i] = pci;
            pCoeff[k-i] = pcki;
        }
        
        // calculate residual error
        pError = pError * (1.0 - pCoeff[k]*pCoeff[k]);
    }
    
    // Now work with a lot of complex variables to find complex roots of LPC filter.
    // These roots will give us formant frequencies.
    
    _Complex double *compCoeff = (_Complex double *)(malloc((ORDER + 1) * sizeof(_Complex double)));
    
    // Transfer pCoeff (real-valued) to compCoeff (complex-valued).
    for (dummo=0; dummo <= ORDER; dummo++) {
        compCoeff[dummo] = pCoeff[ORDER - dummo] + 0.0 * I;
    }
    
    // Formant frequencies are computed in a separate function.
    
    formantFrequencies = [self findFormants:compCoeff];
    
    //Now clean formant frequencies. Remove all that are negative, < 50 Hz, or > (Fs/2 - 50).
    for (dummo = 1; dummo <= ORDER; dummo++) {
        if (formantFrequencies[dummo] > (5512.5 - 50.0))  formantFrequencies[dummo] = 5512.5;
        if (formantFrequencies[dummo] < 50.0)  formantFrequencies[dummo] = 5512.5;
    }
    
    // Now sort formant frequencies. Simple in-place bubble sort.
    for (i = 1 ; i <= ORDER ; i++) {
        for (j = i ; j <= ORDER ; j++) {
            if (formantFrequencies[i] > formantFrequencies[j]) {
                dummyFrequency = formantFrequencies[i];
                formantFrequencies[i] = formantFrequencies[j];
                formantFrequencies[j] = dummyFrequency;
            }
        }
    }
    
    // Now list first 8 sorted frequencies.
//    for (dummo = 1; dummo <= 8; dummo++) {
//        NSLog(@"Format frequency for index %d is %5.0f\n",dummo, formantFrequencies[dummo]);
//    }
    
    // Print a blank line
    //NSLog(@"saf");
    
    // Now assign FFreq values so that they can be viewed in calling class
    _firstFFreq = formantFrequencies[1];
    _secondFFreq = formantFrequencies[2];
    _thirdFFreq = formantFrequencies[3];
    _fourthFFreq = formantFrequencies[4];
}

-(void) decimateDataBuffer
{
    int dumidx;
    
    for (dumidx=0; dumidx < (truncatedEndIdx - truncatedStartIdx)/4; dumidx++) {
        dataBuffer[dumidx] = dataBuffer[4*dumidx + truncatedStartIdx];
    }
    
    decimatedEndIdx = dumidx - 1;
}
-(void) removeSilence
{
    int chunkEnergy, energyThres;
    int maxEnergyValue;
    int chunkIdx;
    int j;
    
    int chunkSize = dataBufferLength / 300;
    
    maxEnergyValue = 0;
    for (chunkIdx=0; chunkIdx<300; chunkIdx++) {
        chunkEnergy = 0;
        for (j=0; j<chunkSize; j++) {
            chunkEnergy += dataBuffer[j + chunkIdx*chunkSize] * dataBuffer[j + chunkIdx*chunkSize]/1000;
        }
        maxEnergyValue = MAX(maxEnergyValue, chunkEnergy);
    }
    
    energyThres = maxEnergyValue / 10;
    
    // Find strong starting index.
    strongStartIdx = 0;
    for (chunkIdx=0; chunkIdx<300; chunkIdx++) {
        chunkEnergy = 0;
        for (j=0; j<chunkSize; j++) {
            chunkEnergy += dataBuffer[j + chunkIdx*chunkSize] * dataBuffer[j + chunkIdx*chunkSize]/1000;
        }
        if (chunkEnergy > energyThres) {
            strongStartIdx = chunkIdx * chunkSize;
            strongStartIdx = MAX(0, strongStartIdx);
            break;
        }
    }
    
    // Find strong ending index
    strongEndIdx = dataBufferLength;
    for (chunkIdx = 299; chunkIdx >= 0; chunkIdx--) {
        chunkEnergy = 0;
        for (j=0; j<chunkSize; j++) {
            chunkEnergy += dataBuffer[j + chunkIdx*chunkSize] * dataBuffer[j + chunkIdx*chunkSize]/1000;
        }
        if (chunkEnergy > energyThreshold) {
            strongEndIdx = chunkIdx * chunkSize + chunkSize - 1;
            strongEndIdx = MIN(dataBufferLength, strongEndIdx);
            break;
        }
    }
}

// The follosing function removes 15% from both ends of strong section of the buffer
-(void) removeTails
{
    truncatedStartIdx = strongStartIdx + (strongEndIdx - strongStartIdx)*15/100;
    truncatedEndIdx = strongEndIdx - (strongEndIdx - strongStartIdx)*15/100;
}

// Following function implement Laguerre root finding algorithm. It uses a lot of
// complex variables and operations of complex variables. It does not implement
// root polishing so answers are not very accurate.

-(double *) findFormants:(_Complex double*) a;
{
    
    // Allocate space for complex roots
    _Complex double *roots = (_Complex double *)(malloc((ORDER+1) * sizeof(_Complex double)));
    
    int j , jj;
    _Complex double x, b, c;
    
    _Complex double *ad = (_Complex double *)(malloc((ORDER+1) * sizeof(_Complex double)));
    
    for (j = 0 ; j <= ORDER ; j++)
    {
        ad[j] = a[j];
    }
    
    for (j = ORDER ; j >= 1 ; j--)
    {
        x = [self laguer:ad currentOrder:j];
        
        // If imaginary part is very small, ignore it
        if (fabs(cimag(x)) <= 2.0*EPS*fabs(creal(x)))
        {
            x = creal(x) + 0.0 * I;
        }
        
        roots[j] = x;
        
        // Perform forward deflation. Divide by the factor of the root found above
        b = ad[j];
        for (jj = j-1 ; jj >= 0 ; jj--)
        {
            c = ad[jj];
            ad[jj] = b;
            b = x * b + c;
        }
    }
    
    // Find real-frequencies corresponding to all roots and fill the array.
    
    // Allocate space for real-world frequencies
    double *formantFrequencies = (double *)(malloc((ORDER+1) * sizeof(double)));
    
    for (int dummo=0; dummo<=ORDER; dummo++)
    {
        formantFrequencies[dummo] = 0.0;
    }
    
    for (int dummo=0; dummo<=ORDER; dummo++)
    {
        formantFrequencies[dummo] = 5512.5 * carg(roots[dummo]) / M_PI;
    }
    
    return formantFrequencies;
}

// Heart of Laguerre algorithm. Solved the polynomial equation of a certain order.
// This functions is called repeatedly to find all the complex roots one by one.

-(_Complex double) laguer:(_Complex double *) a currentOrder:(int) m;
{
    int iter , j;
    double abx , abp , abm , err;
    _Complex double dx , x , x1 , b , d , f , g , h , sq , gp , gm , g2;
    static float frac[MR+1] = {0.0,0.5,0.25,0.75,0.13,0.38,0.62,0.88,1.0};
    
    x = 0.0 + 0.0 * I;
    
    for (iter = 1 ; iter <= MAXIT ; iter++)
    {
        b = a[m];
        err = cabs(b);
        d = f = 0.0 + 0.0 * I;
        abx = cabs(x);
        
        for (j = m - 1 ; j >= 0 ; j--)
        {
            f = x * f + d;
            d = x * d + b;
            b = x * b + a[j];
            err = cabs(b) + abx * err;
        }
        
        err *= EPSS;
        if (cabs(b) <= err)    // error is small, return x even if iterations are not exhausted
        {
            return x;
        }
        
        g = d / b;
        g2 = g * g;
        h = g2 - f / b;
        sq = csqrt( (m-1) * (m * h - g2) );
        gp = g + sq;
        gm = g - sq;
        abp = cabs(gp);
        abm = cabs(gm);
        if (abp < abm)
        {
            gp=gm;
        }
        
        dx = ((MAX(abp,abm) > 0.0 ? (m + 0.0 * I) / gp
               : (1+abx) * (cos((float)iter) + sin((float)iter) * I)));
        x1 = x - dx;
        if (creal(x) == creal(x1) && cimag(x) == cimag(x1))
        {
            return x;
        }
        
        if (iter % MT) x = x1; else x = x - frac[iter/MT] * dx;
    }
    return x;
}

@end

//
//  FirstViewController.h
//  FormantPlotter
//
//  Created by William Entriken on 1/15/14.
//  Copyright (c) 2014 William Entriken. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioDeviceManager.h"
#import "PlotView.h"



@interface FirstViewController : UIViewController {
    
    AudioDeviceManager *audioDeviceManager;
    
    IBOutlet UIImageView *indicatorImageView;      // Displayes an image based on strength of imput audio
    IBOutlet PlotView *plotView;                   // An instance of PlotView, for plotting of results.
    
    NSTimer *masterTimer;                          // Timer to manage three phases of soud capturing process
    
    short int *soundDataBuffer;                    // A pointer to long sound buffer to be captured.
    
    // Different GUI elements. They are declared IBOutlet as they need to be hidden.
    IBOutlet UILabel *statusLabel;
    IBOutlet UILabel *firstFormantLabel;
    IBOutlet UILabel *secondFormantLabel;
    IBOutlet UILabel *thirdFormantLabel;
    IBOutlet UILabel *fourthFormantLabel;
    IBOutlet UILabel *sliderLabel;
    IBOutlet UISlider *thresholdSlider;
    IBOutlet UISegmentedControl *graphingMode;
    
    int dummyTimerTickCounter;
    BOOL liveSpeechSegments;               // Whether we are processing live speech or stored samples.
    int soundFileIdentifier;               // Which stored file (1 out of 7) is being processed
    int displayIdentifier;                 // What type of information (1 out of 5) is to be displayed in plotView.
    
    NSArray *soundFileBaseNames;           // Array of names of 7 stored sound files.
}

@property (nonatomic, retain) UIImageView *indicatorImageView;
@property (nonatomic, retain) NSTimer *masterTimer;
@property (nonatomic, retain) UILabel *statusLabel;

@property (nonatomic, retain) UILabel *firstFormantLabel;
@property (nonatomic, retain) UILabel *secondFormantLabel;
@property (nonatomic, retain) UILabel *thirdFormantLabel;
@property (nonatomic, retain) UILabel *fourthFormantLabel;
@property (nonatomic, retain) UILabel *sliderLabel;
@property (nonatomic, retain) UISlider *thresholdSlider;
@property (weak, nonatomic) IBOutlet UIButton *inputSelector;

@property (nonatomic, retain) UISegmentedControl *graphingMode;

-(IBAction) processThresholdSlider;

-(void) processRawBuffer;
- (IBAction)graphingModeChanged:(UISegmentedControl *)sender;

-(void) displayFormantFrequencies;

- (IBAction)showInputSelectSheet:(id)sender;

- (IBAction)showHelp;

@end

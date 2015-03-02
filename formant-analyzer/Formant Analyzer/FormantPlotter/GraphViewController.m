//
//  GraphViewController.m
//  FormantPlotter
//
//  Created by Hai Le on 2/10/15.
//  Copyright (c) 2015 William Entriken. All rights reserved.
//

#import "GraphViewController.h"
#import "LPCView.h"

@interface GraphViewController () <LPCDelegate>

@property (strong, nonatomic) IBOutlet LPCView *fftView;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;

@end

@implementation GraphViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    self.fftView.delegate = self;
    [self.fftView startDrawing];
}
- (IBAction)saveTapped:(id)sender {
    [self.fftView saveGraph];
}

@end

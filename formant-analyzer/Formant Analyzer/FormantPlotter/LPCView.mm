//
//  LPCView.m
//  Spectrum
//
//  Created by Hai Le on 29/9/14.
//  Copyright (c) 2014 Earthling Studio. All rights reserved.
//

#import "LPCView.h"
#import "LPCAudioController.h"
#import "ViewFrameAccessor.h"
#import <complex.h>

@interface LPCView () {
    LPCAudioController *lpcController;
    double* _savedData;
    
    double* _plotData;
}

@end

@implementation LPCView
{
    int decimatedEndIdx;
    int truncatedStartIdx, truncatedEndIdx;
    int strongStartIdx, strongEndIdx;
    short int *dataBuffer;
    int dataBufferLength;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        // Setup LPC
        lpcController = [[LPCAudioController alloc] init];
        [self setBackgroundColor:[UIColor cloudsColor]];
    }
    return self;
}

- (void)startDrawing {
    [NSTimer scheduledTimerWithTimeInterval:(1.0f / 50) target:self selector:@selector(refresh) userInfo:nil repeats:YES];
}

- (void)saveGraph {
    int bufferSize = lpcController.width;
    if( _savedData != NULL ){
        delete []_savedData;
        _savedData = NULL;
    }
    _savedData = new double[bufferSize];
    // Copy the buffer
    memcpy(_savedData,
           _plotData,
           (size_t)bufferSize*sizeof(double));
}



- (void)refresh
{
    //if (lpcController->drawing) {
        [self setNeedsDisplay];
    //}
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    // Context
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGPoint startPoint, endPoint;
    CGFloat dashPattern[2];
    UIColor* lineColor;
    double maxFreqResp, minFreqResp, freqRespScale;
    
    // get plot data from audio controller
    _plotData = lpcController->plotData;
    
    // =================================================================
    // DRAW VERTICAL LINES
    // Draw four dashed vertical lines at 1kHz, 2kHz, 3kHz, and 4 kHz.
    lineColor = [[UIColor silverColor] colorWithAlphaComponent:0.8];
    
    dashPattern[0] = 3.0;
    dashPattern[1] = 3.0;
    CGContextSetLineWidth(ctx, 1);
    CGContextSetStrokeColorWithColor(ctx, lineColor.CGColor);
    
    for (int k=1; k<5; k++) {
        CGContextMoveToPoint(ctx, self.width/5*k - 1, 0);
        CGContextAddLineToPoint(ctx, self.width/5*k - 1, self.height);
        CGContextStrokePath(ctx);
    }
    
    // =================================================================
    // DRAW SAVED GRAPH
    // Now plot the frequency response
    if (_savedData != NULL) {
        maxFreqResp = -100.0;
        minFreqResp = 100.0;
        
        for (int degIdx = 0; degIdx < lpcController.width; degIdx++) {
            maxFreqResp = MAX(maxFreqResp, _savedData[degIdx]);
            minFreqResp = MIN(minFreqResp, _savedData[degIdx]);
        }
        
        freqRespScale = 180.0 / (maxFreqResp - minFreqResp);
        
        lineColor = [UIColor asbestosColor];
        CGContextSetStrokeColorWithColor(ctx, lineColor.CGColor);
        CGContextSetLineWidth(ctx, 2.0);
        startPoint = CGPointMake(0, 190 - freqRespScale * (_savedData[0] - minFreqResp));
        
        for (int chunkIdx=0; chunkIdx<self.width; chunkIdx++) {
            endPoint = CGPointMake(chunkIdx, 190 - freqRespScale * (_savedData[chunkIdx] - minFreqResp));
            if (isnan(startPoint.y)) {
                startPoint.y = 0;
            }
            if (isnan(endPoint.y)) {
                endPoint.y = 0;
            }
            CGContextMoveToPoint(ctx, startPoint.x, startPoint.y);
            CGContextAddLineToPoint(ctx, endPoint.x, endPoint.y);
            startPoint = endPoint;
        }
        
        CGContextStrokePath(ctx);

    }
    
    // =================================================================
    // DRAW REAL-TIME GRAPH
    // Now plot the frequency response
    maxFreqResp = -100.0;
    minFreqResp = 100.0;
    
    maxFreqResp = 0;
    minFreqResp = 0;
    for (int degIdx = 0; degIdx < lpcController.width; degIdx++) {
        maxFreqResp = MAX(maxFreqResp, _plotData[degIdx]);
        minFreqResp = MIN(minFreqResp, _plotData[degIdx]);
    }
    
    freqRespScale = 180.0 / (maxFreqResp - minFreqResp);
    
    lineColor = [UIColor carrotColor];
    CGContextSetStrokeColorWithColor(ctx, lineColor.CGColor);
    CGContextSetLineWidth(ctx, 2.0);
    startPoint = CGPointMake(0, 190 - freqRespScale * (_plotData[0] - minFreqResp));
    
    for (int chunkIdx=0; chunkIdx<self.width; chunkIdx++) {
        endPoint = CGPointMake(chunkIdx, 190 - freqRespScale * (_plotData[chunkIdx] - minFreqResp));
        if (isnan(startPoint.y)) {
            startPoint.y = 0;
        }
        if (isnan(endPoint.y)) {
            endPoint.y = 0;
        }
        CGContextMoveToPoint(ctx, startPoint.x, startPoint.y);
        CGContextAddLineToPoint(ctx, endPoint.x, endPoint.y);
        startPoint = endPoint;
    }
    
    CGContextStrokePath(ctx);
    
    lpcController->needReset = YES;
}

#pragma mark - LPC

@end

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

- (void)startDrawing {
    
    [NSTimer scheduledTimerWithTimeInterval:(1.0f / 60) target:self selector:@selector(refresh) userInfo:nil repeats:YES];
    
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        // Setup LPC
        lpcController = [[LPCAudioController alloc] init];
    }
    return self;
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
    
    CGPoint startPoint, endPoint;
    CGFloat dashPattern[2];
    double maxFreqResp, minFreqResp, freqRespScale;
    
    double* plotData = lpcController->plotData;
    
    // Now plot the frequency response
    maxFreqResp = -100.0;
    minFreqResp = 100.0;
    
    for (int degIdx = 0; degIdx < lpcController.width; degIdx++) {
        maxFreqResp = MAX(maxFreqResp, plotData[degIdx]);
        minFreqResp = MIN(minFreqResp, plotData[degIdx]);
    }
    
    freqRespScale = 180.0 / (maxFreqResp - minFreqResp);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIColor* mycolor = [UIColor blackColor];
    CGContextSetStrokeColorWithColor(ctx, mycolor.CGColor);
    CGContextSetLineWidth(ctx, 2.0);
    startPoint = CGPointMake(0, 190 - freqRespScale * (plotData[0] - minFreqResp));
    
    for (int chunkIdx=0; chunkIdx<self.width; chunkIdx++) {
        endPoint = CGPointMake(chunkIdx, 190 - freqRespScale * (plotData[chunkIdx] - minFreqResp));
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
    
    // Draw four dashed vertical lines at 1kHz, 2kHz, 3kHz, and 4 kHz.
    mycolor = [UIColor blueColor];
    
    dashPattern[0] = 3.0;
    dashPattern[1] = 3.0;
    CGContextSetLineDash(ctx, 0, dashPattern, 1);
    CGContextSetStrokeColorWithColor(ctx, mycolor.CGColor);
    
    for (int k=1; k<5; k++) {
        CGContextMoveToPoint(ctx, self.width/5*k - 1, 0);
        CGContextAddLineToPoint(ctx, self.width/5*k - 1, self.height);
        CGContextStrokePath(ctx);
    }
    lpcController->needReset = YES;
}

#pragma mark - LPC

@end

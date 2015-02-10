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
    BOOL _needResetLPC;
    
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
    double firstFFreq, secondFFreq, thirdFFreq, fourthFFreq;
}

// Four getter functions to export four formant frequencies back to firstViewController
-(double) firstFFreq
{
    return firstFFreq;
}

-(double) secondFFreq
{
    return secondFFreq;
}

-(double) thirdFFreq
{
    return thirdFFreq;
}

-(double) fourthFFreq
{
    return fourthFFreq;
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
    //if (_drawing) {
        [NSTimer scheduledTimerWithTimeInterval:(1.0f / 25) target:self selector:@selector(refresh) userInfo:nil repeats:YES];
    //}
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        // Setup LPC
        lpcController = [[LPCAudioController alloc] init];
        [lpcController setUpData];
        lpcController->bufferSegCount = 0;
        
        // Set a starting value of silence threshold = 30x10000000
        lpcController->energyThreshold = 300000000;
        [lpcController setUpAudioDevice];

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
    if (!lpcController->drawing) return;
    
    // A few variable used in plotting of H(w).
    double omega, realHw, imagHw, maxFreqResp, minFreqResp, freqRespScale;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGFloat dashPattern[2];
    int i,j, k, degIdx, chunkIdx, dummo;
    CGPoint startPoint, endPoint;
    double *formantFrequencies;
    double dummyFrequency;
    
    dataBuffer = lpcController->longBuffer;
    dataBufferLength = lpcController->bufferLenght;
    NSLog(@"bufferLenght %d",lpcController->bufferLenght);
    lpcController->needReset = TRUE;
    
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
    for (dummo = 1; dummo <= 8; dummo++) {
        NSLog(@"Format frequency for index %d is %5.0f",dummo, formantFrequencies[dummo]);
    }
    
    // Print a blank line
    NSLog(@" ");
    
    // Now assign FFreq values so that they can be viewed in calling class
    firstFFreq = formantFrequencies[1];
    secondFFreq = formantFrequencies[2];
    thirdFFreq = formantFrequencies[3];
    fourthFFreq = formantFrequencies[4];
    if ([self.delegate respondsToSelector:@selector(calculateDidFinish)]) {
        [self.delegate calculateDidFinish];
    }
    
    // Now we find frequency response of the inverse of the predictor filter
    
    double *freqResponse = (double *)(malloc((self.width) * sizeof(double)));
    for (degIdx=0; degIdx < self.width; degIdx++) {
        omega = degIdx * M_PI / (self.width*1.1);
        realHw = 1.0;
        imagHw = 0.0;
        
        for (int k = 1 ; k <= ORDER ; k++) {
            realHw = realHw + pCoeff[k] * cos(k * omega);
            imagHw = imagHw - pCoeff[k] * sin(k * omega);
        }
        
        freqResponse[degIdx] = 20*log10(1.0 / sqrt(realHw * realHw + imagHw * imagHw));
    }
    
    // Now plot the frequency response
    maxFreqResp = -100.0;
    minFreqResp = 100.0;
    
    for (degIdx = 0; degIdx < self.width; degIdx++) {
        maxFreqResp = MAX(maxFreqResp, freqResponse[degIdx]);
        minFreqResp = MIN(minFreqResp, freqResponse[degIdx]);
    }
    
    freqRespScale = 180.0 / (maxFreqResp - minFreqResp);
    
    double *plotData = (double *)(malloc((self.width) * sizeof(double)));
    plotData[0] = freqResponse[0];
    //TODO: find right alpha
    float alpha = 0.05;
    for(i = 1; i < self.width; i++) {
        plotData[i] = plotData[i-1] * (1.0f - alpha) + freqResponse[i]*alpha;
    }
    UIColor* mycolor = [UIColor blackColor];
    CGContextSetStrokeColorWithColor(ctx, mycolor.CGColor);
    CGContextSetLineWidth(ctx, 2.0);
    startPoint = CGPointMake(0, 190 - freqRespScale * (plotData[0] - minFreqResp));
    
    for (chunkIdx=0; chunkIdx<self.width; chunkIdx++) {
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
    
    for (k=1; k<5; k++) {
        CGContextMoveToPoint(ctx, self.width/5*k - 1, 0);
        CGContextAddLineToPoint(ctx, self.width/5*k - 1, self.height);
        CGContextStrokePath(ctx);
    }
    
    // Free two buffers started with malloc()
    free(Rxx);
    free(pCoeff);
    free(freqResponse);
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
    int chunkEnergy, energyThreshold;
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
    
    energyThreshold = maxEnergyValue / 10;
    
    // Find strong starting index.
    strongStartIdx = 0;
    for (chunkIdx=0; chunkIdx<300; chunkIdx++) {
        chunkEnergy = 0;
        for (j=0; j<chunkSize; j++) {
            chunkEnergy += dataBuffer[j + chunkIdx*chunkSize] * dataBuffer[j + chunkIdx*chunkSize]/1000;
        }
        if (chunkEnergy > energyThreshold) {
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

#pragma mark - LPC

@end

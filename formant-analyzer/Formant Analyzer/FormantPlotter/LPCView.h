//
//  LPCView.h
//  Spectrum
//
//  Created by Hai Le on 29/9/14.
//  Copyright (c) 2014 Earthling Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LPCDelegate;

// A few constants to be used in LPC and Laguerre algorithms.
# define ORDER 20

#define EPS 2.0e-6
#define EPSS 1.0e-7
#define MR 8
#define MT 10
#define MAXIT (MT*MR)

@interface LPCView : UIView

@property (nonatomic,assign) id<LPCDelegate> delegate;

- (void)startDrawing;
- (void)saveGraph;

@end

@protocol LPCDelegate <NSObject>

@optional
- (void)calculateDidFinish;

@end

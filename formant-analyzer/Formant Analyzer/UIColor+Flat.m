//
//  UIColor+GraphKit.m
//  GraphKit
//
//  Copyright (c) 2014 Michal Konturek
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "UIColor+Flat.h"

@implementation UIColor (Flat)

+ (UIColor *)turquoiseColor {
    return [UIColor colorFromHexCode:@"1ABC9C"];
}

+ (UIColor *)greenSeaColor {
    return [UIColor colorFromHexCode:@"16A085"];
}

+ (UIColor *)emerlandColor {
    return [UIColor colorFromHexCode:@"2ECC71"];
}

+ (UIColor *)nephritisColor {
    return [UIColor colorFromHexCode:@"27AE60"];
}

+ (UIColor *)peterRiverColor {
    return [UIColor colorFromHexCode:@"3498DB"];
}

+ (UIColor *)belizeHoleColor {
    return [UIColor colorFromHexCode:@"2980B9"];
}

+ (UIColor *)amethystColor {
    return [UIColor colorFromHexCode:@"9B59B6"];
}

+ (UIColor *)wisteriaColor {
    return [UIColor colorFromHexCode:@"8E44AD"];
}

+ (UIColor *)wetAsphaltColor {
    return [UIColor colorFromHexCode:@"34495E"];
}

+ (UIColor *)midnightBlueColor {
    return [UIColor colorFromHexCode:@"2C3E50"];
}

+ (UIColor *)sunflowerColor {
    return [UIColor colorFromHexCode:@"F1C40F"];
}

+ (UIColor *)orangeFlatColor {
    // F39C12
    return [UIColor colorFromHexCode:@"E67E22"];
}

+ (UIColor *)carrotColor {
    // E67E22 FD940A
    return [UIColor colorFromHexCode:@"E67E22"];
}

+ (UIColor *)pumpkinColor {
    return [UIColor colorFromHexCode:@"D35400"];
}

+ (UIColor *)alizarinColor {
    return [UIColor colorFromHexCode:@"E74C3C"];
}

+ (UIColor *)pomegranateColor {
    return [UIColor colorFromHexCode:@"C0392B"];
}

+ (UIColor *)cloudsColor {
    return [UIColor colorFromHexCode:@"FDFDFD"];
}

+ (UIColor *)silverColor {
    return [UIColor colorFromHexCode:@"BDC3C7"];
}

+ (UIColor *)concreteColor {
    return [UIColor colorFromHexCode:@"95A5A6"];
}

+ (UIColor *)asbestosColor {
    return [UIColor colorFromHexCode:@"7F8C8D"];
}

+ (UIColor *)stableColor {
    return [UIColor colorFromHexCode:@"F8F8F8"];
}

+ (UIColor *)positiveColor {
    return [UIColor colorFromHexCode:@"4A87EE"];
}

+ (UIColor *)colorFromHexCode:(NSString *)hex {
    
    /*
     source: http://stackoverflow.com/questions/3805177/how-to-convert-hex-rgb-color-codes-to-uicolor
     */
    
    NSString *cleanString = [hex stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if([cleanString length] == 3) {
        cleanString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                       [cleanString substringWithRange:NSMakeRange(0, 1)],[cleanString substringWithRange:NSMakeRange(0, 1)],
                       [cleanString substringWithRange:NSMakeRange(1, 1)],[cleanString substringWithRange:NSMakeRange(1, 1)],
                       [cleanString substringWithRange:NSMakeRange(2, 1)],[cleanString substringWithRange:NSMakeRange(2, 1)]];
    }
    if([cleanString length] == 6) {
        cleanString = [cleanString stringByAppendingString:@"ff"];
    }
    
    unsigned int baseValue;
    [[NSScanner scannerWithString:cleanString] scanHexInt:&baseValue];
    
    float red = ((baseValue >> 24) & 0xFF)/255.0f;
    float green = ((baseValue >> 16) & 0xFF)/255.0f;
    float blue = ((baseValue >> 8) & 0xFF)/255.0f;
    float alpha = ((baseValue >> 0) & 0xFF)/255.0f;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

@end

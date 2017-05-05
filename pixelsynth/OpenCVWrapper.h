//
//  OpenCVWrapper.h
//  pixelsynth
//
//  Created by Malte Bünz on 28.04.17.
//  Copyright © 2017 Malte Bünz. All rights reserved.
//
#import "opencv-header.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCVWrapper : NSObject

+ (UIImage *) convert2GreyscaleImage: (UIImage *)image;
+ (NSArray *) getPixelLineBrightntessValues: (UIImage *)image;

@end

//
//  OpenCVWrapper.m
//  pixelsynth
//
//  Created by Malte Bünz on 28.04.17.
//  Copyright © 2017 Malte Bünz. All rights reserved.
//

#import "OpenCVWrapper.h"
#import "UIImage+OpenCV.h"

@implementation OpenCVWrapper

+ (UIImage *) convert2GreyscaleImage: (UIImage *)image {
    cv::Mat uiToMat = [image cvMat];
    return [UIImage imageWithCVMat:uiToMat
                     andColorSpace:0];
}

@end

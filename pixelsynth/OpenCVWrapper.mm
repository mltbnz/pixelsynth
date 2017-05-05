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


/**
 Returns an array with the pixels brightness values from 0-255
 - Parameter image: the input image
 */
+ (NSArray *)getPixelLineBrightntessValues: (UIImage *)image {
    // convert uiimage to cv::Mat
    cv::Mat img = [image cvMat];
    int cols = img.cols; // width
    // Allocates a vector to hold the brightness values
    std::vector<unsigned char> bValues;
    //
    int halfCol = cols / 2;
    // Loop to run through the image and store brightness values of a pixelline
    for(int i=0; i<cols; i++) {
        unsigned char brightnessValue = img.at<unsigned char>(i, halfCol);
        bValues.push_back(brightnessValue);
    }
    NSArray *convertedValues = [self convertArray:bValues];
    return convertedValues;
}

/**
 Converts a vector of unsigned chars to an NSArray with nice NSNumbers
 - parameter values:
 */
+ (NSArray *) convertArray: (const std::vector<unsigned char>&) values{
    NSMutableArray* brightnessValues = [[NSMutableArray alloc] init];
    for(std::vector<unsigned char>::size_type i = 0; i != values.size(); i++) {
        NSNumber* val = [NSNumber numberWithUnsignedChar:values[i]];
        [brightnessValues addObject:val];
    }
    return brightnessValues;
}


@end

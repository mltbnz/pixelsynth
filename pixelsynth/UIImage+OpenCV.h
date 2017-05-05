//
//  UIImage+OpenCV.h
//  pixelsynth
//
//  Created by Malte Bünz on 28.04.17.
//  Copyright © 2017 Malte Bünz. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import <opencv2/opencv.hpp>
#import "opencv-header.h"

typedef enum : NSUInteger {
    grey,
    color
} UserColorSpace;


@interface UIImage (OpenCV)

//cv::Mat to UIImage
+ (UIImage *)imageWithCVMat:(const cv::Mat&)cvMat andColorSpace:(UInt8)colorSpace;
- (id)initWithCVMat:(const cv::Mat&)cvMat andColorSpace:(UInt8)userSpace;

//UIImage to cv::Mat
- (cv::Mat)cvMat;
- (cv::Mat)cvMat3;  // no alpha channel
- (cv::Mat)cvGrayscaleMat;

// Iterate through pixels


@end

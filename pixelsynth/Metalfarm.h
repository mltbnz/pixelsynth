//
//  Metalfarm.h
//  pixelsynth
//
//  Created by Malte Bünz on 17.05.17.
//  Copyright © 2017 Malte Bünz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "opencv-header.h"

@interface Metalfarm : NSObject

+ (cv::Mat) genarateMatFromTexture: (id<MTLTexture>) texture;

@end

//
//  ImageSoundBridge.swift
//  pixelsynth
//
//  Created by Malte Bünz on 05.05.17.
//  Copyright © 2017 Malte Bünz. All rights reserved.
//

import Foundation

struct ImageSoundBridge {
    
    /**
     Returns an array holding the brightness values of a line at the center of the screen in 1D array
     - parameter image: The input image
     */
    internal func imageBrightnessValues(from image: UIImage) -> Array<UInt16>? {
        let values = OpenCVWrapper.getPixelLineBrightntessValues(image)
        return values as? Array<UInt16>
    }

    
}

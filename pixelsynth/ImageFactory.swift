//
//  ImageUtil.swift
//  pixelsynth
//
//  Created by Malte Bünz on 22.04.17.
//  Copyright © 2017 Malte Bünz. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import MetalKit

struct ImageFactory {
    
    // Connection to the openCV wrapper class
    private let openCVWrapper: OpenCVWrapper = OpenCVWrapper()
    
    // TODO: Observable
    private var greyScaleMode: Bool = true
    
    /**
     Converts a sampleBuffer into an UIImage
     - parameter sampleBuffer:The input samplebuffer
     */
    public func image(from sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        let image = UIImage(cgImage: cgImage)
        guard greyScaleMode == false else {
            let greyScaleImage = OpenCVWrapper.convert2GreyscaleImage(image)
            return greyScaleImage
        }
        return image
    }

    /**
     Returns an array holding the brightness values of a line at the center of the screen in 1D array
     - parameter image: The input image
     */
    public func imageBrightnessValues(from image: UIImage) -> Array<UInt8>? {
        // convert uiimage to cv::Mat
        let values = OpenCVWrapper.getPixelLineBrightntessValues(image)
        return values as? Array<UInt8>
    }
}

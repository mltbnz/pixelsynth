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

struct ImageUtil {
    
    public func image(from sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
}

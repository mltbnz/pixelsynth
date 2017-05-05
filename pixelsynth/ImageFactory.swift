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

    
    /**
     Converts a sample buffer received from camera to a Metal texture
     
     - parameter sampleBuffer: Sample buffer
     - parameter textureCache: Texture cache
     - parameter planeIndex:   Index of the plane for planar buffers. Defaults to 0.
     - parameter pixelFormat:  Metal pixel format. Defaults to `.BGRA8Unorm`.
     
     - returns: Metal texture or nil
     */
    public func texture(sampleBuffer: CMSampleBuffer?, textureCache: CVMetalTextureCache?, planeIndex: Int = 0, pixelFormat: MTLPixelFormat = .bgra8Unorm) throws -> MTLTexture {
        guard let sampleBuffer = sampleBuffer else {
            throw MetalCameraSessionError.missingSampleBuffer
        }
        guard let textureCache = textureCache else {
            throw MetalCameraSessionError.failedToCreateTextureCache
        }
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            throw MetalCameraSessionError.failedToGetImageBuffer
        }
        
        let isPlanar = CVPixelBufferIsPlanar(imageBuffer)
        let width = isPlanar ? CVPixelBufferGetWidthOfPlane(imageBuffer, planeIndex) : CVPixelBufferGetWidth(imageBuffer)
        let height = isPlanar ? CVPixelBufferGetHeightOfPlane(imageBuffer, planeIndex) : CVPixelBufferGetHeight(imageBuffer)
        
        var imageTexture: CVMetalTexture?
        
        let result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, imageBuffer, nil, pixelFormat, width, height, planeIndex, &imageTexture)
        
        guard
            let unwrappedImageTexture = imageTexture,
            let texture = CVMetalTextureGetTexture(unwrappedImageTexture),
            result == kCVReturnSuccess
            else {
                throw MetalCameraSessionError.failedToCreateTextureFromImage
        }
        
        return texture
    }
    
}

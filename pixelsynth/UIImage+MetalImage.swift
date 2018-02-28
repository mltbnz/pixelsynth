//
//  UIImage+Sugar.swift
//  pixelsynth
//
//  Created by Malte Bünz on 05.05.17.
//  Copyright © 2017 Malte Bünz. All rights reserved.
//

import Foundation

public extension UIImage {
    
    public func toMTLTexture() -> MTLTexture {
        let imageRef: CGImage = self.cgImage!
        let width: Int = imageRef.width
        let height: Int = imageRef.height
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let rawData  = malloc(height * width * 4)//byte
        let bytesPerPixel: Int = 4
        let bytesPerRow: Int = bytesPerPixel * width
        let bitsPerComponent: Int = 8
        let bitmapContext: CGContext = CGContext(data: rawData,
                                                 width: width,
                                                 height: height,
                                                 bitsPerComponent: bitsPerComponent,
                                                 bytesPerRow: bytesPerRow,
                                                 space: colorSpace,
                                                 bitmapInfo: (CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))!
        
        bitmapContext.translateBy(x: 0,
                                  y: CGFloat(height))
        bitmapContext.scaleBy(x: 1, y: -1)
        bitmapContext.draw(imageRef,
                           in: CGRect(x: 0,
                                      y: 0,
                                      width: CGFloat(width),
                                      height: CGFloat(height)))
        let textureDescriptor: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
        let texture: MTLTexture = MTLCreateSystemDefaultDevice()!.makeTexture(descriptor: textureDescriptor)!
        let region: MTLRegion = MTLRegionMake2D(0, 0, width, height)
        texture.replace(region: region, mipmapLevel: 0, withBytes: rawData!, bytesPerRow: bytesPerRow)
        free(rawData)
        return texture
    }
}

//
//  MTLTexture+Sugar.swift
//  pixelsynth
//
//  Created by Malte Bünz on 05.05.17.
//  Copyright © 2017 Malte Bünz. All rights reserved.
//

import Metal

extension MTLTexture {
    
    public func toImage() -> UIImage? {
        let bytesPerPixel: Int = 4
        let imageByteCount = self.width * self.height * bytesPerPixel
        let bytesPerRow = self.width * bytesPerPixel
        var src = [UInt8](repeating: 0,
                          count: Int(imageByteCount))
        
        let region = MTLRegionMake2D(0, 0, self.width, self.height)
        self.getBytes(&src, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
        
        let grayColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitsPerComponent = 8
        let context = CGContext(data: &src, width: self.width, height: self.height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: grayColorSpace, bitmapInfo: bitmapInfo.rawValue)
        
        let dstImageFilter = context!.makeImage()
        return UIImage(cgImage: dstImageFilter!,
                       scale: 0.0,
                       orientation: .downMirrored)
    }
    
    
}

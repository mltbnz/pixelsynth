//
//  MTLTexture+Threads.swift
//  pixelsynth
//
//  Created by Malte Bünz on 07.06.17.
//  Copyright © 2017 Malte Bünz. All rights reserved.
//

import Metal

extension MTLTexture {
    
    var threadGroupCount: MTLSize {
        return MTLSize(width: 8,
                       height: 8,
                       depth: 1)
    }
    
    var threadGroups: MTLSize {
        return MTLSize(width: self.width / threadGroupCount.width,
                       height: self.height / threadGroupCount.height,
                       depth: 1)
    }
}

//
//  MetalView.swift
//  pixelsynth
//
//  Created by Malte Bünz on 07.06.17.
//  Copyright © 2017 Malte Bünz. All rights reserved.
//

import UIKit
import MetalKit

final class MetalView: MTKView {
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect,
                   device: device)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        framebufferOnly = false
        colorPixelFormat = .bgra8Unorm
        contentScaleFactor = UIScreen.main.scale
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
}

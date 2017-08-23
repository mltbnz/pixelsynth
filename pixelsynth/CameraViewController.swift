//
//  CameraViewController.swift
//  pixelsynth
//
//  Created by Malte Bünz on 19.04.17.
//  Copyright © 2017 Malte Bünz. All rights reserved.
//

import UIKit
import AVFoundation
import MetalKit

class CameraViewController: MTKViewController {
    
    // MARK: PROPERTIES
    var metalCameraSession: MetalCameraSession!
    
    // VIEW PROPERTIES
    lazy var previewImageView = UIImageView()
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        metalCameraSession = MetalCameraSession(delegate: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        metalCameraSession.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        metalCameraSession.stop()
    }
}

extension CameraViewController: MetalCameraSessionDelegate {
    
    func metalCameraSession(_ session: MetalCameraSession, didReceiveFrameAs textures: [MTLTexture], with timestamp: Double) {
        self.texture = textures[0]
        
        let _ = ImageSoundBridge.imageBrightnessValues(from: textures[0].toImage()!)
//        print(values)
    }
    
    func metalCameraSession(_ session: MetalCameraSession,
                            didUpdate state: MetalCameraSessionState,
                            _ error: MetalCameraSessionError?) {
        if error == .captureSessionRuntimeError {
            metalCameraSession.start()
        }
        DispatchQueue.main.async {
            self.title = "Metal camera: \(state)"
        }
        NSLog("Session changed state to \(state) with error: \(error?.localizedDescription ?? "None").")
    }
    
}

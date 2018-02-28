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
    var soundBridge: ImageSoundBridge!
    
    // VIEW PROPERTIES
    lazy var previewImageView = UIImageView()
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.metalCameraSession = MetalCameraSession(delegate: self)
        soundBridge = ImageSoundBridge()
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
    
    /**
     Gets the MTLTexture Buffer.
     From here you can process the pixel values.
     */
    func metalCameraSession(_ session: MetalCameraSession, didReceiveFrameAs textures: [MTLTexture], with timestamp: Double) {
        self.texture = textures[0]
        let _ = soundBridge.imageBrightnessValues(from: textures[0].toImage()!)
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

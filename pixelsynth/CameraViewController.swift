//
//  CameraViewController.swift
//  pixelsynth
//
//  Created by Malte Bünz on 19.04.17.
//  Copyright © 2017 Malte Bünz. All rights reserved.
//

import UIKit
import AVFoundation
import SnapKit

class CameraViewController: UIViewController {
    
    // PROPERTIES
    var cameraFrameExtractor = FrameExtractor()
    
    // TODO: Implement Observable property called renderingEnababled
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview =  AVCaptureVideoPreviewLayer(session: self.cameraFrameExtractor.captureSession)
        preview?.bounds = CGRect(x: 0,
                                 y: 0,
                                 width: self.view.bounds.width,
                                 height: self.view.bounds.height)
        preview?.position = CGPoint(x: self.view.bounds.midX,
                                    y: self.view.bounds.midY)
        preview?.videoGravity = AVLayerVideoGravityResize
        return preview!
    }()
    
    // VIEW PROPERTIES
    lazy var previewImageView = UIImageView()
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        previewImageView.backgroundColor = .red
        cameraFrameExtractor.delegate = self
        layoutViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraFrameExtractor.startCamera()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraFrameExtractor.teardownCamera()
    }
    
    
    private func layoutViews() {
        view.addSubview(previewImageView)
        previewImageView.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalToSuperview()
        }
    }
}

extension CameraViewController: FrameExtractorDelegate {
    
    func captured(image: UIImage) {
        previewImageView.image = image
    }
}

//
//  VideoDataOutputSampleBufferDelegate.swift
//  pixelsynth
//
//  Created by Malte Bünz on 21.04.17.
//  Copyright © 2017 Malte Bünz. All rights reserved.
//

import Foundation
import AVFoundation

class VideoDataOutputSampleBufferDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // MARK: AVCaptureVideoDataOutput Delegate
    
    /**
     */
    func captureOutput(_ captureOutput: AVCaptureOutput!,
                       didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,
                       from connection: AVCaptureConnection!) {
        // TODO: Implement subscribor that listens to renderingEnabled from the CameraViewController
//        if !renderingEnabled {
//            return
//        }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            return
        }
        
        
        
    }
    
    /**
     */
    func captureOutput(_ captureOutput: AVCaptureOutput!,
                       didDrop sampleBuffer: CMSampleBuffer!,
                       from connection: AVCaptureConnection!) {
        // Here you can count how many frames are dopped
    }
    
}

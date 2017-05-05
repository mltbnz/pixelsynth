//
//  CameraCaptureDevice.swift
//  pixelsynth
//
//  Created by Malte Bünz on 05.05.17.
//  Copyright © 2017 Malte Bünz. All rights reserved.
//

import AVFoundation

/// A wrapper for the `AVFoundation`'s `AVCaptureDevice` that has instance methods instead of the class ones. This wrapper will make unit testing so much easier.
internal class CameraCaptureDevice {
    
    internal func device(mediaType: String, position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        guard let devices = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera,
                                                                          .builtInDuoCamera,
                                                                          .builtInTelephotoCamera],
                                                            mediaType: AVMediaTypeVideo,
                                                            position: .unspecified).devices else {
                                                                return nil
        }
        if let index = devices.index(where: { $0.position == position }) {
            return devices[index]
        }
        
        return nil
    }
    
    internal func requestAccessForMediaType(_ mediaType: String!, completionHandler handler: ((Bool) -> Void)!) {
        AVCaptureDevice.requestAccess(forMediaType: mediaType, completionHandler: handler)
    }
}

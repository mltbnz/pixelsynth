//
//  Properties.swift
//  pixelsynth
//
//  Created by Malte Bünz on 18.04.17.
//  Copyright © 2017 Malte Bünz. All rights reserved.
//

import Foundation

enum Properties {
    static let Frequency = "Frequency"
}

enum Queues {
    static let CameraSessionController = "CameraSessionController Session"
    static let SessionQueue =  "session queue"
    static let VideoDataQueue = "video data queue"
    static let MetalCameraSessionQueue = "MetalCameraSessionQueue"
}

enum Notifications {
    static let CouldNotUseCamera = "Could not use camera!"
    static let MissingCameraPermission = "This application does not have permission to use camera. Please update your privacy settings."
}

enum Exceptions {
    static let delegate = "MetalCameraSession calls delegate with an updated state and error."
    
}

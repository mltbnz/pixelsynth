//
//  Properties.swift
//  pixelsynth
//
//  Created by Malte Bünz on 18.04.17.
//  Copyright © 2017 Malte Bünz. All rights reserved.
//

import Foundation

enum Properties: String {
    case frequency = "Frequency"
    
}

enum Queues: String {
    case cameraSessionController = "CameraSessionController Session"
    case sessionQueue =  "session queue"
    case videoDataQueue = "video data queue"
}

enum Notifications: String {
    case couldNotUseCamera = "Could not use camera!"
    case missingCameraPermission = "This application does not have permission to use camera. Please update your privacy settings."
}

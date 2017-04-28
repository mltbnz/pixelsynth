//
//  AppDelegate.swift
//  pixelsynth
//
//  Created by Malte Bünz on 18.04.17.
//  Copyright © 2017 Malte Bünz. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let cameraViewController = CameraViewController()
        window?.rootViewController = cameraViewController
        self.window?.makeKeyAndVisible()
        return true
    }
}


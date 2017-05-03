//
//  CameraSessionController.swift
//  pixelsynth
//
//  Created by Malte Bünz on 19.04.17.
//  Copyright © 2017 Malte Bünz. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia
import CoreImage

protocol FrameExtractorDelegate: class {
    func captured(image: UIImage)
}

class CameraSessionController: NSObject {
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private var setupResult: SessionSetupResult = .success
    // Camera properties
    lazy var cameraSession = AVCaptureSession()
    var sessionQueue: DispatchQueue! = DispatchQueue(label: Queues.sessionQueue.rawValue,
                                                     attributes: [],
                                                     autoreleaseFrequency: .workItem)
    private var videoDeviceInput: AVCaptureDeviceInput!
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: Queues.videoDataQueue.rawValue,
                                                     qos: .userInitiated,
                                                     attributes: [],
                                                     autoreleaseFrequency: .workItem)
    
    // Delegates
    weak var delegate: FrameExtractorDelegate?
    // Observers
    var runtimeErrorHandlingObserver: AnyObject?
    // Util
    let imageUtil = ImageUtil()
    
    private var renderingEnabled = true
    static var sessionRunningContext = 0
    private var isSessionRunning = false
    
    
    // MARK: Lifecycle
    override init() {
        super.init()
        authorizeCamera()
        configureSession()
    }
    
    // MARK: Instance Methods
    
    /***/
    func didEnterBackground(notification: NSNotification) {
        // Free up resources
        videoDataOutputQueue.async { [unowned self] in
            self.renderingEnabled = false
        }
    }
    
    /***/
    func willEnterForground(notification: NSNotification) {
        videoDataOutputQueue.async { [unowned self] in
            self.renderingEnabled = true
        }
    }
    
    /**
     */
    func sessionRuntimeError(notification: NSNotification) {
        guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else {
            return
        }
        let error = AVError(_nsError: errorValue)
        print("Capture session runtime error: \(error)")
        /*
         Automatically try to restart the session running if media services were
         reset and the last start running succeeded. Otherwise, enable the user
         to try to resume the session running.
         */
        if error.code == .mediaServicesWereReset {
            sessionQueue.async {
                if self.isSessionRunning {
                    self.cameraSession.startRunning()
                    self.isSessionRunning = self.cameraSession.isRunning
                }
            }
        }
    }
    
    // MARK: Camera Setup
    // MARK: AVSession configuration
    private func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { granted in
            if !granted {
                self.setupResult = .notAuthorized
            }
            self.sessionQueue.resume()
        })
    }
    
    /**
     */
    private func authorizeCamera() {
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
        case .authorized:
            // The user has previously granted access to the camera
            break
        case .notDetermined:
            /*
             The user has not yet been presented with the option to grant video access
             We suspend the session queue to delay session setup until the access request has completed
             */
            requestPermission()
        default:
            // The user has previously denied access
            setupResult = .notAuthorized
        }
    }
    
    /**
     Configures the camerasession and adds an in- and output to the camerasession
     */
    private func configureSession() {
        // Check
        if setupResult != .success {
            return
        }
        sessionQueue.async { [unowned self] in
            self.cameraSession.beginConfiguration()
            self.cameraSession.sessionPreset = AVCaptureSessionPresetHigh
            self.addVideoOutput()
            self.addVideoInput()
            self.cameraSession.commitConfiguration()
            self.cameraSession.startRunning()
        }
    }
    
    
    
    /**
     Sets the capture device property.
     #Cameraside #WideAngleCamera
     */
    private func captureDevice(with position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        let devices = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera,
                                                                    .builtInDuoCamera,
                                                                    .builtInTelephotoCamera],
                                                      mediaType: AVMediaTypeVideo,
                                                      position: .unspecified).devices
        if let devices = devices {
            for device in devices {
                if device.position == position {
                    return device
                }
            }
        }
        return nil
    }
    
    /**
     Swaps the camera input between front and back camera
     */
    public func swapCamera() {
        guard let input = cameraSession.inputs[0] as? AVCaptureDeviceInput else {
            return
        }
        cameraSession.beginConfiguration()
        defer {
            cameraSession.commitConfiguration()
        }
        
        var newDevice: AVCaptureDevice?
        if input.device.position == .back {
            newDevice = captureDevice(with: .front)
        } else {
            newDevice = captureDevice(with: .back)
        }
        
        // Create new capture input
        var deviceInput: AVCaptureDeviceInput!
        do {
            deviceInput = try AVCaptureDeviceInput(device: newDevice)
        } catch let error {
            print(error.localizedDescription)
            return
        }
        
        // Swap capture device inputs
        cameraSession.removeInput(input)
        cameraSession.addInput(deviceInput)
    }
    
    
    /**
     Adds an input to the camerasession
     */
    private func addVideoInput() {
        guard let captureDevice = captureDevice(with: .back) else {
            return
        }
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        guard cameraSession.canAddInput(captureDeviceInput) else {
            print("Could not add video device input to the session")
            setupResult = .configurationFailed
            cameraSession.commitConfiguration()
            return
        }
        cameraSession.addInput(captureDeviceInput)
    }
    
    /**
     Adds an output to the camerasession
     */
    
    private func addVideoOutput() {
        guard cameraSession.canAddOutput(videoDataOutput) else {
            return
        }
        videoDataOutput.setSampleBufferDelegate(self,
                                                queue: sessionQueue)
        if cameraSession.canAddOutput(videoDataOutput) {
            cameraSession.addOutput(videoDataOutput)
        } else {
            print("Could not add video data output to the session")
            setupResult = .configurationFailed
            return
        }
    }
    
    /**
     */
    func startCamera() {
        sessionQueue.async { [unowned self] in
            self.runtimeErrorHandlingObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVCaptureSessionRuntimeError,
                                                                                       object: self.sessionQueue,
                                                                                       queue: nil,
                                                                                       using: { [unowned self] (notification: Notification) in
                                                                                        let strongSelf: CameraSessionController = self
                                                                                        strongSelf.sessionQueue.async(execute: {
                                                                                            strongSelf.cameraSession.startRunning()
                                                                                        })
                                                                                        self.cameraSession.startRunning()
            })
        }
    }
    
    /**
     */
    func teardownCamera() {
        sessionQueue.async(execute: {
            self.cameraSession.stopRunning()
            NotificationCenter.default.removeObserver(self.runtimeErrorHandlingObserver!)
        })
    }
    
    /**
     */
    func sessionWasInterrupted(notification: NSNotification) {
        // In iOS 9 and later, the userInfo dictionary contains information on why the session was interrupted.
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?, let reasonIntegerValue = userInfoValue.integerValue, let reason = AVCaptureSessionInterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason \(reason)")
            if reason == .videoDeviceInUseByAnotherClient {
                // Simply fade-in a button to enable the user to try to resume the session running.
                //                resumeButton.isHidden = false
                //                resumeButton.alpha = 0.0
                //                UIView.animate(withDuration: 0.25) {
                //                    self.resumeButton.alpha = 1.0
                //                }
            }
            else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
                // Simply fade-in a label to inform the user that the camera is unavailable.
                //                cameraUnavailableLabel.isHidden = false
                //                cameraUnavailableLabel.alpha = 0.0
                UIView.animate(withDuration: 0.25) {
                    //                    self.cameraUnavailableLabel.alpha = 1.0
                }
            }
        }
    }
    
    
    /**
     */
    public func focusAndExpose(in view: UIView, _ gestureRecognizer: UIGestureRecognizer) {
        //        let location = gestureRecognizer.location(in: view)
        //        guard let texturePoint = view.layer.anchorPoint != nil/*(FilterMetalView)previewView.texturePointForView(point: location)*/ else {
        //            return
        //        }
        let textureRect = CGRect(origin: .zero,
                                 size: .zero)
        let deviceRect = videoDataOutput.metadataOutputRectOfInterest(for: textureRect)
        focus(with: .autoFocus,
              exposureMode: .autoExpose,
              at: deviceRect.origin,
              monitorSubjectAreaChange: true)
    }
    
    private func focus(with focusMode: AVCaptureFocusMode, exposureMode: AVCaptureExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
        sessionQueue.async {
            guard let videoDevice = self.videoDeviceInput.device else {
                return
            }
            do {
                try videoDevice.lockForConfiguration()
                if videoDevice.isFocusPointOfInterestSupported && videoDevice.isFocusModeSupported(focusMode) {
                    videoDevice.focusPointOfInterest = devicePoint
                    videoDevice.focusMode = focusMode
                }
                
                if videoDevice.isExposurePointOfInterestSupported && videoDevice.isExposureModeSupported(exposureMode) {
                    videoDevice.exposurePointOfInterest = devicePoint
                    videoDevice.exposureMode = exposureMode
                }
                
                videoDevice.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                videoDevice.unlockForConfiguration()
            }
            catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
}

extension CameraSessionController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    /**
     */
    func captureOutput(_ captureOutput: AVCaptureOutput!,
                       didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,
                       from connection: AVCaptureConnection!) {
        // TODO: Implement subscribor that listens to renderingEnabled from the CameraViewController
        //        if !renderingEnabled {
        //            return
        //        }
        guard let uiImage = imageUtil.image(from: sampleBuffer) else {
            return
        }
        DispatchQueue.main.async { [unowned self] in
            self.delegate?.captured(image: uiImage)
        }
    }
    
    /**
     */
    func captureOutput(_ captureOutput: AVCaptureOutput!,
                       didDrop sampleBuffer: CMSampleBuffer!,
                       from connection: AVCaptureConnection!) {
        // Here you can count how many frames are dopped
        
        // When Frames are droppped play some glitchy weird sound
    }
    
    
}


import AVFoundation
import Metal

/**
 *  A protocol for a delegate that may be notified about the capture session events.
 */
public protocol MetalCameraSessionDelegate: class {
    
    /**
     Camera session did receive a new frame and converted it to an array of Metal textures. For instance, if the RGB pixel format was selected, the array will have a single texture, whereas if YCbCr was selected, then there will be two textures: the Y texture at index 0, and CbCr texture at index 1 (following the order in a sample buffer).
     
     - parameter session:                   Session that triggered the update
     - parameter didReceiveFrameAsTextures: Frame converted to an array of Metal textures
     - parameter withTimestamp:             Frame timestamp in seconds
     */
    func metalCameraSession(_ session: MetalCameraSession, didReceiveFrameAs textures: [MTLTexture], with timestamp: Double)
    
    /**
     Camera session did update capture state
     
     - parameter session:        Session that triggered the update
     - parameter didUpdateState: Capture session state
     - parameter error:          Capture session error or `nil`
     */
    func metalCameraSession(_ session: MetalCameraSession, didUpdate state: MetalCameraSessionState, _ error: MetalCameraSessionError?)
}


/**
 * A convenient hub for accessing camera data as a stream of Metal textures with corresponding timestamps.
 *
 * Keep in mind that frames arrive in a hardware orientation by default, e.g. `.LandscapeRight` for the rear camera. You can set the `frameOrientation` property to override this behavior and apply auto rotation to each frame.
 */
public final class MetalCameraSession: NSObject {
    
    // MARK: Public interface
    
    /// Frame orienation. If you want to receive frames in orientation other than the hardware default one, set this `var` and this value will be picked up when converting next frame. Although keep in mind that any rotation comes at a performance cost.
    public var frameOrientation: AVCaptureVideoOrientation? {
        didSet {
            guard
                let frameOrientation = frameOrientation,
                let outputData = outputData,
                (outputData.connection(with: AVMediaType.video)?.isVideoOrientationSupported)!
                else { return }
            outputData.connection(with: AVMediaType.video)?.videoOrientation = frameOrientation
        }
    }
    /// Requested capture device position, e.g. camera
    public let captureDevicePosition: AVCaptureDevice.Position
    
    /// Delegate that will be notified about state changes and new frames
    public var delegate: MetalCameraSessionDelegate?
    
    /// Pixel format to be used for grabbing camera data and converting textures
    public let pixelFormat: MetalCameraPixelFormat
    
    // MARK: Private properties and methods
    
    /// `AVFoundation` capture session object.
    fileprivate var captureSession = AVCaptureSession()
    
    /// Our internal wrapper for the `AVCaptureDevice`. Making it internal to stub during testing.
    internal var captureDevice = CameraCaptureDevice()
    
    /// Dispatch queue for capture session events.
    fileprivate var captureSessionQueue = DispatchQueue(label: Queues.MetalCameraSessionQueue,
                                                        attributes: [])
    
    #if arch(i386) || arch(x86_64)
    #else
        internal var textureCache: CVMetalTextureCache?
    /// Texture cache we will use for converting frame images to textures
    #endif
    
    /// `MTLDevice` we need to initialize texture cache
    fileprivate var metalDevice = MTLCreateSystemDefaultDevice()
    
    ///
    var videoTextureCache: CVMetalTextureCache?
    
    /// Current capture input device.
    internal var inputDevice: AVCaptureDeviceInput? {
        didSet {
            if let oldValue = oldValue {
                captureSession.removeInput(oldValue)
            }
            captureSession.addInput(inputDevice!)
        }
    }
    
    /// Current capture output data stream.
    internal var outputData: AVCaptureVideoDataOutput? {
        didSet {
            if let oldValue = oldValue {
                captureSession.removeOutput(oldValue)
            }
            captureSession.addOutput(outputData!)
        }
    }
    
    /// Current session state.
    fileprivate var state: MetalCameraSessionState = .waiting {
        didSet {
            guard state != .error else { return }
            delegate?.metalCameraSession(self,
                                         didUpdate: state,
                                         nil)
        }
    }
    
    // MARK: Lifecycle
    /**
     initialized a new instance, providing optional values.
     - parameter pixelFormat:           Pixel format. Defaults to `.RGB`
     - parameter captureDevicePosition: Camera to be used for capturing. Defaults to `.Back`.
     - parameter delegate:              Delegate. Defaults to `nil`.
     */
    public init(pixelFormat: MetalCameraPixelFormat = .rgb, captureDevicePosition: AVCaptureDevice.Position = .back, delegate: MetalCameraSessionDelegate? = nil) {
        self.pixelFormat = pixelFormat
        self.captureDevicePosition = captureDevicePosition
        CVMetalTextureCacheCreate(kCFAllocatorDefault,
                                  nil,
                                  self.metalDevice!,
                                  nil,
                                  &videoTextureCache)
        self.delegate = delegate
        super.init();
        setupSession()
        NotificationCenter.default.addObserver(self, selector: #selector(captureSessionRuntimeError), name: NSNotification.Name.AVCaptureSessionRuntimeError, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Camera
    
    /**
     Requests access to camera hardware.
     */
    fileprivate func requestCameraAccess() {
        captureDevice.requestAccessForMediaType(AVMediaType.video.rawValue) {
            (granted: Bool) -> Void in
            guard granted else {
                self.handleError(.noHardwareAccess)
                return
            }
            if self.state != .streaming && self.state != .error {
                self.state = .ready
            }
        }
    }
    
    /**
     Sets up the capture session.
     */
    public func setupSession() {
        requestCameraAccess()
        captureSessionQueue.async {
            do {
                self.captureSession.beginConfiguration()
                try self.initializeInputDevice()
                try self.initializeOutputData()
                self.captureSession.commitConfiguration()
                try self.initializeTextureCache()
                self.captureSession.startRunning()
                self.state = .streaming
            }
            catch let error as MetalCameraSessionError {
                self.handleError(error)
            }
            catch {}
        }
    }
    
    /// Starts the capture session
    public func start() {
        captureSessionQueue.async { [unowned self] in
            self.captureSession.startRunning()
            self.state = .streaming
        }
    }
    
    
    /// Stops the capture session.
    public func stop() {
        captureSessionQueue.async { [unowned self] in
            self.captureSession.stopRunning()
            self.state = .stopped
        }
    }
    
    ///
    fileprivate func handleError(_ error: MetalCameraSessionError) {
        if error.isStreamingError() {
            state = .error
        }
        delegate?.metalCameraSession(self,
                                     didUpdate: state,
                                     nil)
    }
    
    /**
     initialized the texture cache. We use it to convert frames into textures.
     
     */
    fileprivate func initializeTextureCache() throws {
        #if arch(i386) || arch(x86_64)
            throw MetalCameraSessionError.failedToCreateTextureCache
        #else
            guard
                let metalDevice = metalDevice,
                CVMetalTextureCacheCreate(kCFAllocatorDefault,
                                          nil,
                                          metalDevice,
                                          nil,
                                          &textureCache) == kCVReturnSuccess
                else {
                    throw MetalCameraSessionError.failedToCreateTextureCache
            }
        #endif
    }
    
    /**
     initializes capture input device with specified media type and device position.
     - throws: `MetalCameraSessionError` if we failed to initialize and add input device.
     */
    fileprivate func initializeInputDevice() throws {
        var captureInput: AVCaptureDeviceInput!
        guard let inputDevice = captureDevice.device(mediaType: AVMediaType.video.rawValue,
                                                     position: captureDevicePosition) else {
            throw MetalCameraSessionError.requestedHardwareNotFound
        }
        do {
            captureInput = try AVCaptureDeviceInput(device: inputDevice)
        }
        catch {
            throw MetalCameraSessionError.inputDeviceNotAvailable
        }
        guard captureSession.canAddInput(captureInput) else {
            throw MetalCameraSessionError.failedToAddCaptureInputDevice
        }
        self.inputDevice = captureInput
    }
    
    /**
     initializes capture output data stream.
     - throws: `MetalCameraSessionError` if we failed to initialize and add output data stream.
     */
    fileprivate func initializeOutputData() throws {
        let outputData = AVCaptureVideoDataOutput()
        
        outputData.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String : Int(pixelFormat.coreVideoType)
        ]
        outputData.alwaysDiscardsLateVideoFrames = true
        outputData.setSampleBufferDelegate(self,
                                           queue: captureSessionQueue)
        
        guard captureSession.canAddOutput(outputData) else {
            throw MetalCameraSessionError.failedToAddCaptureOutput
        }
        
        self.outputData = outputData
        
        guard let connection = outputData.connection(with: AVFoundation.AVMediaType.video) else {
            return
        }
        guard connection.isVideoOrientationSupported else {
            return
        }
        guard connection.isVideoMirroringSupported else {
            return
        }
        frameOrientation = .portrait
        connection.videoOrientation = frameOrientation!
        connection.isVideoMirrored = AVCaptureDevice.Position.back == .front
    }
    
    /**
     `AVCaptureSessionRuntimeErrorNotification` callback.
     */
    @objc
    fileprivate func captureSessionRuntimeError() {
        if state == .streaming {
            handleError(.captureSessionRuntimeError)
        }
    }
    
    /**
     Swaps the camera input between front and back camera
     */
    public func swapCamera() {
        guard let input = captureSession.inputs[0] as? AVCaptureDeviceInput else {
            return
        }
        captureSession.beginConfiguration()
        defer {
            captureSession.commitConfiguration()
        }
        
        var newDevice: AVCaptureDevice?
        if input.device.position == .back {
            newDevice = captureDevice.device(mediaType: AVMediaType.video.rawValue,
                                             position: .front)
        } else {
            newDevice = captureDevice.device(mediaType: AVMediaType.video.rawValue,
                                             position: .back)
        }
        
        // Create new capture input
        var deviceInput: AVCaptureDeviceInput!
        do {
            deviceInput = try AVCaptureDeviceInput(device: newDevice!)
        } catch let error {
            print(error.localizedDescription)
            return
        }
        // Swap capture device inputs
        captureSession.removeInput(input)
        captureSession.addInput(deviceInput)
    }
    
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension MetalCameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    /**
     Converts a sample buffer received from camera to a Metal texture
     
     - parameter sampleBuffer: Sample buffer
     - parameter textureCache: Texture cache
     - parameter planeIndex:   Index of the plane for planar buffers. Defaults to 0.
     - parameter pixelFormat:  Metal pixel format. Defaults to `.BGRA8Unorm`.
     
     - returns: Metal texture or nil
     */
    private func texture(sampleBuffer: CMSampleBuffer?,
                         textureCache: CVMetalTextureCache?,
                         planeIndex: Int = 0,
                         pixelFormat: MTLPixelFormat = .bgra8Unorm) throws -> MTLTexture {
        guard let sampleBuffer = sampleBuffer else {
            throw MetalCameraSessionError.missingSampleBuffer
        }
        guard let textureCache = textureCache else {
            throw MetalCameraSessionError.failedToCreateTextureCache
        }
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            throw MetalCameraSessionError.failedToGetImageBuffer
        }
        
        let isPlanar = CVPixelBufferIsPlanar(imageBuffer)
        let width = isPlanar ? CVPixelBufferGetWidthOfPlane(imageBuffer, planeIndex) : CVPixelBufferGetWidth(imageBuffer)
        let height = isPlanar ? CVPixelBufferGetHeightOfPlane(imageBuffer, planeIndex) : CVPixelBufferGetHeight(imageBuffer)
        
        var imageTexture: CVMetalTexture?
        
        let result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                               textureCache,
                                                               imageBuffer,
                                                               nil,
                                                               pixelFormat,
                                                               width,
                                                               height,
                                                               planeIndex,
                                                               &imageTexture)
        
        guard
            let unwrappedImageTexture = imageTexture,
            let texture = CVMetalTextureGetTexture(unwrappedImageTexture),
            result == kCVReturnSuccess
            else {
                throw MetalCameraSessionError.failedToCreateTextureFromImage
        }
        
        return texture
    }
    
    /**
     Strips out the timestamp value out of the sample buffer received from camera.
     - parameter sampleBuffer: Sample buffer with the frame data
     - returns: Double value for a timestamp in seconds or nil
     */
    private func timestamp(sampleBuffer: CMSampleBuffer?) throws -> Double {
        guard let sampleBuffer = sampleBuffer else {
            throw MetalCameraSessionError.missingSampleBuffer
        }
        
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        guard time != kCMTimeInvalid else {
            throw MetalCameraSessionError.failedToRetrieveTimestamp
        }
        
        return (Double)(time.value) / (Double)(time.timescale);
    }
    
    @objc public func captureOutput(_ captureOutput: AVCaptureOutput,
                                    didOutput sampleBuffer: CMSampleBuffer,
                                    from connection: AVCaptureConnection) {
        do {
            var textures: [MTLTexture]!
            switch pixelFormat {
            case .rgb:
                let textureRGB = try texture(sampleBuffer: sampleBuffer,
                                             textureCache: textureCache)
                textures = [textureRGB]
            case .yCbCr:
                let textureY = try texture(sampleBuffer: sampleBuffer,
                                           textureCache: textureCache,
                                           planeIndex: 0,
                                           pixelFormat: .r8Unorm)
                let textureCbCr = try texture(sampleBuffer: sampleBuffer,
                                              textureCache: textureCache,
                                              planeIndex: 1,
                                              pixelFormat: .rg8Unorm)
                textures = [textureY, textureCbCr]
            }
            let timestamp = try self.timestamp(sampleBuffer: sampleBuffer)
            delegate?.metalCameraSession(self,
                                         didReceiveFrameAs: textures,
                                         with: timestamp)
        }
        catch let error as MetalCameraSessionError {
            self.handleError(error)
        }
        catch {
            /**
             * We only throw `MetalCameraSessionError` errors.
             */
        }
    }
    
    
}

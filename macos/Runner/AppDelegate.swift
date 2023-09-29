import Cocoa
import FlutterMacOS
import AVFoundation

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
    
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    override func applicationDidBecomeActive(_ notification: Notification) {
        guard let controller: FlutterViewController = NSApplication.shared.mainWindow?.contentViewController as? FlutterViewController else {
            return
        }
        
        let videoChannel = FlutterMethodChannel(name: "com.time_tracker/screen_recording", binaryMessenger: controller.engine.binaryMessenger)
        
        videoChannel.setMethodCallHandler({
            [weak self](call, result) -> Void in
            switch call.method {
            case "startRecording":
                let args = call.arguments as? [String:Any]
                let fileName = args!["file_name"] as? String
                let path = args!["path"] as? String
                self?.startRecording(fileName: fileName!,path: path!) { path in
                    if let path = path {
                        result(path)
                    } else {
                        result(FlutterError(code: "UNAVAILABLE", message: "Couldn't start recording", details: nil))
                    }
                }
            case "stopRecording":
                self?.stopRecording { success in
                    if success {
                        result(nil)
                    } else {
                        result(FlutterError(code: "ERROR", message: "Couldn't stop recording", details: nil))
                    }
                }
            case "compressVideo":
                let args = call.arguments as? [String:Any]
                let inputUrl = args!["input_url"] as? String
                let outputUrl = args!["output_url"] as? String
                self?.compressVideo(inputURL: inputUrl!, outputURL: outputUrl!){
                    status in
                    switch status {
                    case .completed:
                        result("Compression succeeded")
                    case .failed, .cancelled:
                        result("Compression failed or was cancelled")
                    default:
                        result("Compression is still in process or was not configured correctly")
                    }
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        })
    }
    
    var captureSessions = [AVCaptureSession]()
    var movieOutput: AVCaptureMovieFileOutput?
    
    func startRecording(fileName:String,path:String, result: @escaping FlutterResult) {
        var outputs = [AVCaptureMovieFileOutput]()
        var outputFiles = [URL]()
        let screens = NSScreen.screens
        for  i in 1...screens.count{
            let captureSession = AVCaptureSession()
            captureSessions.append(captureSession)
            let screen = screens[i-1]
            guard let displayId = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")]as? CGDirectDisplayID else {
                return // Jika tidak bisa mendapatkan displayId, lewati layar ini
            }
            let screenInput = AVCaptureScreenInput(displayID: displayId)
            let nameFile = "\(fileName)\(i).mp4"
            if let sInput = screenInput {
                if captureSession.canAddInput(sInput){
                    captureSession.addInput(sInput)
                }
            }
            
            let movieOutput = AVCaptureMovieFileOutput()
            outputs.append(movieOutput)
            if captureSession.canAddOutput(movieOutput) {
                captureSession.addOutput(movieOutput)
            }
            // Custom path
            let customDirectory = URL(fileURLWithPath: path)
            // memastikan directory ada
            try? FileManager.default.createDirectory(at: customDirectory, withIntermediateDirectories: true,attributes: nil)
            let outputFileLocation = customDirectory.appendingPathComponent(nameFile)
            outputFiles.append(outputFileLocation)
            captureSession.startRunning()
            movieOutput.startRecording(to: outputFileLocation, recordingDelegate: self)
        }
        result(outputFiles.map {$0.path})
    }
    
    func compressVideo(inputURL:String, outputURL:String, handler: @escaping (AVAssetExportSession.Status?) -> Void){
        if let url = URL(string: inputURL){
            let asset = AVAsset(url: url)
            let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality)!
            if let output = URL(string: outputURL){
                exportSession.outputURL = output
                exportSession.outputFileType = .mp4
                exportSession.exportAsynchronously {
                    handler(exportSession.status)
                }
            }
        }
        
    }
    
    func stopRecording(completion: @escaping (Bool) -> Void) {
        movieOutput?.stopRecording()
        for capture in captureSessions{
            capture.stopRunning()
        }
        completion(true)
    }
    
}

extension AppDelegate: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        // Handle the completion of the recording
        if let err = error {
            print("Recording error: \(err.localizedDescription)")
        } else {
            print("Successfully saved video to \(outputFileURL.path)")
        }
    }
}



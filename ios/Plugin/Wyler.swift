//
//  ScreenRecorder.swift
//  Wyler
//
//  Created by Cesar Vargas on 10.04.20.
//  Copyright © 2020 Cesar Vargas. All rights reserved.
//

import Foundation
import ReplayKit
import Photos

public enum ScreenRecorderError: Error {
    case notAvailable
    case photoLibraryAccessNotGranted
}

public final class ScreenRecorder {
    private var videoOutputURL: URL?
    private var videoWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var micAudioWriterInput: AVAssetWriterInput?
    private var appAudioWriterInput: AVAssetWriterInput?
    private var saveToCameraRoll = false
    let recorder = RPScreenRecorder.shared()

    /**
     Starts recording the content of the application screen. It works together with stopRecording

     - Parameter outputURL: The output where the video will be saved. If nil, it saves it in the documents directory.
     - Parameter size: The size of the video. If nil, it will use the app screen size.
     - Parameter saveToCameraRoll: Whether to save it to camera roll. False by default.
     - Parameter errorHandler: Called when an error is found
     */
    public func startRecording(to outputURL: URL? = nil,
                               size: CGSize? = nil,
                               saveToCameraRoll: Bool = false,
                               handler: @escaping (Error?) -> Void) {
        // recorder.isMicrophoneEnabled = true
        do {
            try createVideoWriter(in: outputURL)
            addVideoWriterInput(size: size)
            self.micAudioWriterInput = createAndAddAudioInput()
            self.appAudioWriterInput = createAndAddAudioInput()
            startCapture(handler: handler)
        } catch let err {
            handler(err)
        }
    }

    private func checkPhotoLibraryAuthorizationStatus() {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization({ _ in })
        }
    }

    private func createVideoWriter(in outputURL: URL? = nil) throws {
        let newVideoOutputURL: URL

        if let passedVideoOutput = outputURL {
            self.videoOutputURL = passedVideoOutput
            newVideoOutputURL = passedVideoOutput
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let dateString = dateFormatter.string(from: Date())
            let videoFileName = "record_\(dateString).mp4"
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
            newVideoOutputURL = URL(fileURLWithPath: documentsPath.appendingPathComponent(videoFileName))
            self.videoOutputURL = newVideoOutputURL
        }

        do {
            try FileManager.default.removeItem(at: newVideoOutputURL)
        } catch {}

        do {
            try videoWriter = AVAssetWriter(outputURL: newVideoOutputURL, fileType: AVFileType.mp4)
        } catch let writerError as NSError {
            videoWriter = nil
            throw writerError
        }
    }

    private func addVideoWriterInput(size: CGSize?) {
        let passingSize: CGSize = size ?? UIScreen.main.bounds.size

        let videoSettings: [String: Any] = [AVVideoCodecKey: AVVideoCodecType.h264,
                                            AVVideoWidthKey: passingSize.width,
                                            AVVideoHeightKey: passingSize.height]

        let newVideoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        self.videoWriterInput = newVideoWriterInput
        newVideoWriterInput.expectsMediaDataInRealTime = true
        videoWriter?.add(newVideoWriterInput)
    }

    private func createAndAddAudioInput() -> AVAssetWriterInput {
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: settings)

        audioInput.expectsMediaDataInRealTime = true
        videoWriter?.add(audioInput)

        return audioInput
    }

    private func startCapture(handler: @escaping (Error?) -> Void) {
        guard recorder.isAvailable else {
            return handler(ScreenRecorderError.notAvailable)
        }
        var sent = false
        recorder.startCapture(handler: { (sampleBuffer, sampleType, passedError) in
            if let passedError = passedError {
                if !sent {
                    handler(passedError)
                    sent = true
                }
            }

            switch sampleType {
            case .video:
                self.handleSampleBuffer(sampleBuffer: sampleBuffer)
            case .audioApp:
                self.add(sample: sampleBuffer, to: self.appAudioWriterInput)
            case .audioMic:
                self.add(sample: sampleBuffer, to: self.micAudioWriterInput)
            default:
                break
            }
            if !sent {
                handler(nil)
                sent = true
            }
        })
    }

    private func handleSampleBuffer(sampleBuffer: CMSampleBuffer) {
        guard let videoWriter = self.videoWriter else { return }
        if videoWriter.status == .unknown {
            videoWriter.startWriting()
            videoWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        }
        if videoWriter.status == .writing,
        let videoWriterInput = self.videoWriterInput,
        videoWriterInput.isReadyForMoreMediaData {
        videoWriterInput.append(sampleBuffer)
        }
    }

    private func add(sample: CMSampleBuffer, to writerInput: AVAssetWriterInput?) {
        if writerInput?.isReadyForMoreMediaData ?? false {
            writerInput?.append(sample)
        }
    }

    /**
     Stops recording the content of the application screen, after calling startRecording

     - Parameter errorHandler: Called when an error is found
     */
    // public func stoprecording(handler: @escaping (Error?) -> Void) {
    //     recorder.stopCapture( handler: { error in
    //         if let error = error {
    //             handler(error)
    //         } else {
    //             self.videoWriterInput?.markAsFinished()
    //             self.micAudioWriterInput?.markAsFinished()
    //             self.appAudioWriterInput?.markAsFinished()
    //             self.videoWriter?.finishWriting {
    //                 self.saveVideoToCameraRollAfterAuthorized(handler: handler)
    //             }
    //         }
    //     })
    // }

    public func stoprecording(handler: @escaping (String?, Error?) -> Void) {
        recorder.stopCapture { error in
            if let error = error {
                handler(nil, error)
            } else {
                self.videoWriterInput?.markAsFinished()
                self.micAudioWriterInput?.markAsFinished()
                self.appAudioWriterInput?.markAsFinished()
                self.videoWriter?.finishWriting {
                    self.saveVideoToCameraRollAfterAuthorized { error in
                        handler(self.videoOutputURL?.path, error)
                    }
                }
            }
        }
    }


    private func saveVideoToCameraRollAfterAuthorized(handler: @escaping (Error?) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()

        switch status {
        case .authorized:
            // User has already granted access, proceed to save the video
            self.saveVideoToCameraRoll(handler: handler)
        
        case .notDetermined:
            // Request access
            PHPhotoLibrary.requestAuthorization { newStatus in
                if newStatus == .authorized {
                    self.saveVideoToCameraRoll(handler: handler)
                } else {
                    self.showSettingsAlert(handler: handler)
                }
            }
        
        case .denied, .restricted:
            // Access was denied or restricted, inform the user they need to enable it in Settings
            self.showSettingsAlert(handler: handler)
        
        @unknown default:
            // Handle any future cases
            handler(ScreenRecorderError.photoLibraryAccessNotGranted)
        }
    }

    private func showSettingsAlert(handler: @escaping (Error?) -> Void) {
        let alert = UIAlertController(title: "Photo Library Access Denied",
                                    message: "Please enable access to the photo library in Settings to save recordings.",
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }))
    
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            handler(ScreenRecorderError.photoLibraryAccessNotGranted)
        }))
    
        // Present the alert on the main thread
        DispatchQueue.main.async {
            // Assuming you have a reference to the current view controller
            if let topController = UIApplication.shared.keyWindow?.rootViewController {
                topController.present(alert, animated: true, completion: nil)
            }
        }
    }

    private func saveVideoToCameraRoll(handler: @escaping (Error?) -> Void) {
        guard let videoOutputURL = self.videoOutputURL else {
            return handler(nil)
        }

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoOutputURL)
        }, completionHandler: { _, error in
            if let error = error {
                handler(error)
            } else {
                handler(nil)
            }
        })
    }
}
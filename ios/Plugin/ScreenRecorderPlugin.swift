import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(ScreenRecorderPlugin)
public class ScreenRecorderPlugin: CAPPlugin {
    private let implementation = ScreenRecorder()

    @objc func start(_ call: CAPPluginCall) {
        //  let outputPath = call.getString("outputPath") ?? "default.mov"

        // // Create a full file URL in app's documents directory
        // let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        // let fileURL = documents.appendingPathComponent(outputPath)
        implementation.startRecording(saveToCameraRoll: true, handler: { error in
            if let error = error {
                debugPrint("Error when start recording \(error)")
                call.reject("Cannot start recording")
            } else {
                call.resolve()
            }
        })
    }
    @objc func stop(_ call: CAPPluginCall) {
        implementation.stoprecording(handler: { error, outputURL in
            if let error = error {
                debugPrint("Error when stop recording \(error)")
                call.reject("Cannot stop recording")
            } else if let url = outputURL {
                call.resolve([
                "outputUrl": url.absoluteString
                ])
            }   else {
                call.reject("Unknown error stopping recording.")
            }
        })
    }
}

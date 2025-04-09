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
        implementation.stoprecording(handler: { path, error in
            if let error = error {
                call.reject("Recording failed", error.localizedDescription)
            } else if let path = path {
                let result = JSObject()
                result["path"] = path
                call.resolve(result)
            } else {
                call.reject("Unknown error")
            }
        })
    }
}

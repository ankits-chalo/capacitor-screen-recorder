package ee.forgr.plugin.screenrecorder;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import java.util.function.BiConsumer;

import dev.chalo.scrcast.ScrCast;
import dev.chalo.scrcast.config.Options;

@CapacitorPlugin(name = "ScreenRecorder")
public class ScreenRecorderPlugin extends Plugin {

  private ScrCast recorder;

  @Override
  public void load() {
    recorder = ScrCast.use(this.bridge.getActivity());
    Options options = new Options();
    recorder.updateOptions(options);
  }

  @PluginMethod
  public void start(PluginCall call) {
    startRecording(call);
  }

  private void startRecording(PluginCall call) {
    recorder.setRecordingCallback((success, message) -> {
      if (success) {
        call.resolve();
      } else {
        call.reject(message);
      }
    });
    recorder.record(( success,  message) -> {
        if (!success) {
          call.reject(message != null ? message : "Unknown error"); // Reject with an error message
        }
    });
  }

  @PluginMethod
  public void stop(PluginCall call) {
    recorder.onRecordingComplete(file -> {
      JSObject result = new JSObject();
      result.put("filePath", file.getAbsolutePath());
      call.resolve(result);
      return null;
    });
    recorder.stopRecording();
  }
}
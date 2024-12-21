
import 'plugin_demo_platform_interface.dart';

class PluginDemo {
  Future<String?> getPlatformVersion() {
    return PluginDemoPlatform.instance.getPlatformVersion();
  }

  Future<void> getNativeAlert() {
    return PluginDemoPlatform.instance.getNativeAlert();
  }

  Future<int?> sum(int a, int b) {
    return PluginDemoPlatform.instance.sum(a, b);
  }

  Stream<String> streamDemo() {
    return PluginDemoPlatform.instance.streamDemo();
  }
}

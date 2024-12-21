
import 'plugin_demo_platform_interface.dart';

class PluginDemo {
  Future<String?> getPlatformVersion() {
    return PluginDemoPlatform.instance.getPlatformVersion();
  }

  Future<void> getNativeAlert() {
    return PluginDemoPlatform.instance.getNativeAlert();
  }
}

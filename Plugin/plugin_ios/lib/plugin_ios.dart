
import 'plugin_ios_platform_interface.dart';

class PluginIos {
  Future<String?> getPlatformVersion() {
    return PluginIosPlatform.instance.getPlatformVersion();
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'plugin_ios_platform_interface.dart';

/// An implementation of [PluginIosPlatform] that uses method channels.
class MethodChannelPluginIos extends PluginIosPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('plugin_ios');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}

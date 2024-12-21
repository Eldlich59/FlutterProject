import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'plugin_demo_platform_interface.dart';

/// An implementation of [PluginDemoPlatform] that uses method channels.
class MethodChannelPluginDemo extends PluginDemoPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('plugin_demo');
  final eventChannel = const EventChannel('event_channel');
  Stream<String> get evenStream async* {
    await for(String message in eventChannel.receiveBroadcastStream()) {
      yield message;
    }
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> getNativeAlert() async {
    return await methodChannel.invokeMethod<void>('getNativeAlert');
  }

  @override
  Future<int?> sum(int a, int b) async {
    return await methodChannel.invokeMethod<int?>('sum',[a, b]);
  }

  @override
  Stream<String> streamDemo() {
    return evenStream;
  }
}

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'plugin_ios_method_channel.dart';

abstract class PluginIosPlatform extends PlatformInterface {
  /// Constructs a PluginIosPlatform.
  PluginIosPlatform() : super(token: _token);

  static final Object _token = Object();

  static PluginIosPlatform _instance = MethodChannelPluginIos();

  /// The default instance of [PluginIosPlatform] to use.
  ///
  /// Defaults to [MethodChannelPluginIos].
  static PluginIosPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PluginIosPlatform] when
  /// they register themselves.
  static set instance(PluginIosPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'plugin_demo_method_channel.dart';

abstract class PluginDemoPlatform extends PlatformInterface {
  /// Constructs a PluginDemoPlatform.
  PluginDemoPlatform() : super(token: _token);

  static final Object _token = Object();

  static PluginDemoPlatform _instance = MethodChannelPluginDemo();

  /// The default instance of [PluginDemoPlatform] to use.
  ///
  /// Defaults to [MethodChannelPluginDemo].
  static PluginDemoPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PluginDemoPlatform] when
  /// they register themselves.
  static set instance(PluginDemoPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> getNativeAlert() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

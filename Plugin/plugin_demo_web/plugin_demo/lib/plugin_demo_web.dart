// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;
import 'dart:js' as js;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'plugin_demo_platform_interface.dart';

/// A web implementation of the PluginDemoPlatform of the PluginDemo plugin.
class PluginDemoWeb extends PluginDemoPlatform {
  /// Constructs a PluginDemoWeb
  PluginDemoWeb();

  static void registerWith(Registrar registrar) {
    PluginDemoPlatform.instance = PluginDemoWeb();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = html.window.navigator.userAgent;
    return version;
  }

  @override
  Future<int> sum(int a, int b) {
    int r = js.context.callMethod('sum', [a, b]);
    return Future(() => r);
  }

  @override
  Future<void> getNativeAlert() {
    js.context.callMethod('nativeAlert', ["hello from js"]);
    return Future(() => null);
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_demo/plugin_demo.dart';
import 'package:plugin_demo/plugin_demo_platform_interface.dart';
import 'package:plugin_demo/plugin_demo_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPluginDemoPlatform
    with MockPlatformInterfaceMixin
    implements PluginDemoPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<void> getNativeAlert() async {
    // Mock implementation that does nothing
    return;
  }

  @override
  Future<int> sum(int a, int b) async {
    // Mock implementation that returns a dummy value
    return a + b;
  }
}

void main() {
  final PluginDemoPlatform initialPlatform = PluginDemoPlatform.instance;

  test('$MethodChannelPluginDemo is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPluginDemo>());
  });

  test('getPlatformVersion', () async {
    PluginDemo pluginDemoPlugin = PluginDemo();
    MockPluginDemoPlatform fakePlatform = MockPluginDemoPlatform();
    PluginDemoPlatform.instance = fakePlatform;

    expect(await pluginDemoPlugin.getPlatformVersion(), '42');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_ios/plugin_ios.dart';
import 'package:plugin_ios/plugin_ios_platform_interface.dart';
import 'package:plugin_ios/plugin_ios_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPluginIosPlatform
    with MockPlatformInterfaceMixin
    implements PluginIosPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PluginIosPlatform initialPlatform = PluginIosPlatform.instance;

  test('$MethodChannelPluginIos is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPluginIos>());
  });

  test('getPlatformVersion', () async {
    PluginIos pluginIosPlugin = PluginIos();
    MockPluginIosPlatform fakePlatform = MockPluginIosPlatform();
    PluginIosPlatform.instance = fakePlatform;

    expect(await pluginIosPlugin.getPlatformVersion(), '42');
  });
}

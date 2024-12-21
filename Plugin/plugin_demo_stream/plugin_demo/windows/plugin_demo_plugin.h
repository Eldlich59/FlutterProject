#ifndef FLUTTER_PLUGIN_PLUGIN_DEMO_PLUGIN_H_
#define FLUTTER_PLUGIN_PLUGIN_DEMO_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace plugin_demo {

class PluginDemoPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  PluginDemoPlugin();

  virtual ~PluginDemoPlugin();

  // Disallow copy and assign.
  PluginDemoPlugin(const PluginDemoPlugin&) = delete;
  PluginDemoPlugin& operator=(const PluginDemoPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace plugin_demo

#endif  // FLUTTER_PLUGIN_PLUGIN_DEMO_PLUGIN_H_

#include "include/plugin_demo/plugin_demo_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "plugin_demo_plugin.h"

void PluginDemoPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  plugin_demo::PluginDemoPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

#include "plugin_demo_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>
#include <flutter/method_call.h>
#include <flutter/method_result_functions.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>


#include "plugin_demo_plugin.h"

namespace plugin_demo {
    namespace {

        using flutter::EncodableMap;
        using flutter::EncodableValue;
        using flutter::MethodCall;
        using flutter::MethodResultFunctions;

    }  // namespace
// static
    void PluginDemoPlugin::RegisterWithRegistrar(
            flutter::PluginRegistrarWindows *registrar) {
        auto channel =
                std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
                        registrar->messenger(), "plugin_demo",
                                &flutter::StandardMethodCodec::GetInstance());

        auto plugin = std::make_unique<PluginDemoPlugin>();

        channel->SetMethodCallHandler(
                [plugin_pointer = plugin.get()](const auto &call, auto result) {
                    plugin_pointer->HandleMethodCall(call, std::move(result));
                });

        registrar->AddPlugin(std::move(plugin));
    }

    PluginDemoPlugin::PluginDemoPlugin() {}

    PluginDemoPlugin::~PluginDemoPlugin() {}

    void PluginDemoPlugin::HandleMethodCall(
            const flutter::MethodCall<flutter::EncodableValue> &method_call,
            std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (method_call.method_name().compare("getPlatformVersion") == 0) {
            std::ostringstream version_stream;
            version_stream << "Windows ";
            if (IsWindows10OrGreater()) {
                version_stream << "10+";
            } else if (IsWindows8OrGreater()) {
                version_stream << "8";
            } else if (IsWindows7OrGreater()) {
                version_stream << "7";
            }
            result->Success(flutter::EncodableValue(version_stream.str()));
        } else if (method_call.method_name().compare("sum") == 0) {
            const auto *arguments = std::get_if<EncodableMap>(method_call.arguments());
            int a = 0;
            auto aa = arguments->find(EncodableValue("x"));
            if (aa != arguments->end())
            {
                a = std::get<int>(aa->second);
            }
            int b = 0;
            auto bb = arguments->find(EncodableValue("y"));
            if (bb != arguments->end())
            {
                b = std::get<int>(bb->second);
            }
            result->Success(a+b);
        } else {
            result->NotImplemented();
        }
    }

}  // namespace plugin_demo

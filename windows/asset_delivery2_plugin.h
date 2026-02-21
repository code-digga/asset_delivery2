#ifndef FLUTTER_PLUGIN_ASSET_DELIVERY2_PLUGIN_H_
#define FLUTTER_PLUGIN_ASSET_DELIVERY2_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace asset_delivery2 {

class AssetDelivery2Plugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  AssetDelivery2Plugin();

  virtual ~AssetDelivery2Plugin();

  // Disallow copy and assign.
  AssetDelivery2Plugin(const AssetDelivery2Plugin&) = delete;
  AssetDelivery2Plugin& operator=(const AssetDelivery2Plugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace asset_delivery2

#endif  // FLUTTER_PLUGIN_ASSET_DELIVERY2_PLUGIN_H_

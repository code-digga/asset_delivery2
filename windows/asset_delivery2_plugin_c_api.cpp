#include "include/asset_delivery2/asset_delivery2_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "asset_delivery2_plugin.h"

void AssetDelivery2PluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  asset_delivery2::AssetDelivery2Plugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

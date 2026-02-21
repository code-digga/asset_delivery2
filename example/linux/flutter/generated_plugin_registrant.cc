//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <asset_delivery2/asset_delivery2_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) asset_delivery2_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "AssetDelivery2Plugin");
  asset_delivery2_plugin_register_with_registrar(asset_delivery2_registrar);
}

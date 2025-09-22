name = "FarmerMerm"
description = "IdkF"
author = "Lobato"
version = "0.0.1"
forumthread = ""
icon_atlas = "modicon.xml"
icon = "modicon.tex"
client_only_mod = false
all_clients_require_mod = true
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
priority = 0
api_version = 10

local bannertweak = { { description = "", data = false, } } --needed for banners to work
configuration_options = {
  {
    name = "banner1",
    label = "Merm Farmer",
    hover = "",
    options = bannertweak,
    default = false,
  },
  {
    name = "mermexp_mermfarmer_unloads",
    label = "Enable Unloading",
    hover = "Makes Farmers able to work even when you're away or in caves!",
    options =
    {
      { description = "No",  data = false },
      { description = "Yes", data = true },
    },
    default = false,
  },
}

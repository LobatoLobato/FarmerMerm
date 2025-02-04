modimport "init/config.lua"
modimport "init/actions"
modimport "init/recipes"
modimport "init/popups.lua"
modimport "init/RPCs.lua"
modimport "init/strings.lua"
modimport "init/stategraphs/SGmerm.lua"
modimport "init/widgets/containerwidget.lua"
modimport "postinit/brains/friendlyfruitflybrain.lua"

PrefabFiles = {
  "mermexp_merm_farmer",
  "mermexp_mermhouse_farmer",
  "mermexp_mermfarm_blueprint",
  -- classifieds
  "mermexp_mermfarmblueprint_classified"
}

Assets = {
  Asset("ATLAS", "images/mermexp/inventoryimages.xml"),
  Asset("IMAGE", "images/mermexp/inventoryimages.tex"),

  Asset("ATLAS", "images/mermexp/ui_hud.xml"),
  Asset("IMAGE", "images/mermexp/ui_hud.tex"),

  Asset("ATLAS", "images/mermexp/ui_containers.xml"),
  Asset("IMAGE", "images/mermexp/ui_containers.tex"),

  Asset("ATLAS", "images/mermexp/ui_icons.xml"),
  Asset("IMAGE", "images/mermexp/ui_icons.tex"),

  Asset("ATLAS", "minimap/mermexp/minimap_atlas.xml"),
  Asset("IMAGE", "minimap/mermexp/minimap_data.tex"),
}
AddMinimapAtlas("minimap/mermexp/minimap_atlas.xml")

AddReplicableComponent("mermexp_mermfarmblueprint")
AddReplicableComponent("mermexp_waterreservoir")

local ENABLE_DEBUG_FNS = true
-- debugging
if ENABLE_DEBUG_FNS then
  ---comment
  ---@param amount number
  function GiveEverySeed(amount)
    for _, v in pairs(require("prefabs.farm_plant_defs").PLANT_DEFS) do c_give(v.seed, 40) end
  end
end

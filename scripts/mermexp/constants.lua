local PLANT_DEFS = require("prefabs.farm_plant_defs").PLANT_DEFS
local WEED_DEFS = require("prefabs.weed_defs").WEED_DEFS
local MOD_NAME = "mermexp"
local UI_HUD_ATLAS = "images/mermexp/ui_hud.xml"
local UI_ICONS_ATLAS = "images/mermexp/ui_icons.xml"
local UI_CONTAINERS_ATLAS = "images/mermexp/ui_containers.xml"
local INVENTORYIMAGES_ATLAS = "images/mermexp/inventoryimages.xml"

local PlantLookupTable = require "mermexp.plantlookuptable"
local SEEDS = PlantLookupTable(PLANT_DEFS, "crop_seed", "seed")
do
  local _, seeds_pos = SEEDS:At("seeds")
  table.insert(SEEDS, table.remove(SEEDS, seeds_pos))
end
local VEGGIES = PlantLookupTable(PLANT_DEFS, "crop_seed", "product", { "randomseed" })
local WEEDS = PlantLookupTable(WEED_DEFS, "crop_small", "product")
local PLANTABLES = PlantLookupTable.Join(SEEDS, WEEDS, { "weed_ivy" })

local TILE3x3 = {
  { 1.333,  1.333 },
  { 0,      1.333 },
  { -1.333, 1.333 },
  { 1.333,  0 },
  { 0,      0 },
  { -1.333, 0 },
  { 1.333,  -1.333 },
  { 0,      -1.333 },
  { -1.333, -1.333 },
}

return {
  SEEDS                 = SEEDS,
  VEGGIES               = VEGGIES,
  WEEDS                 = WEEDS,
  PLANTABLES            = PLANTABLES,
  MOD_NAME              = MOD_NAME,
  UI_HUD_ATLAS          = UI_HUD_ATLAS,
  UI_ICONS_ATLAS        = UI_ICONS_ATLAS,
  UI_CONTAINERS_ATLAS   = UI_CONTAINERS_ATLAS,
  INVENTORYIMAGES_ATLAS = INVENTORYIMAGES_ATLAS,
  FARM_PLANT_TAGS       = { "farm_plant" },
  TILE3x3               = TILE3x3
}

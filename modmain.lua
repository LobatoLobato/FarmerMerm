PrefabFiles = {
  "merm_farmer",
  "mermhouse_farmer",
  "farm_layout_blueprint"
}

Assets = {
  Asset("ATLAS", "minimap/mermhouse_farmer.xml"),
  Asset("ATLAS", "images/farm_soil.xml"),
  Asset("IMAGE", "images/farm_soil.tex")
}
AddMinimapAtlas("minimap/mermhouse_farmer.xml")

_G = GLOBAL
TUNING = _G.TUNING
Vector3 = _G.Vector3
WORLD_TILES = _G.WORLD_TILES

_G.STRINGS.NAMES.MERMHOUSE_FARMER = "Farmmerm House"
_G.STRINGS.RECIPE_DESC.MERMHOUSE_FARMER = "CLT"
_G.STRINGS.CHARACTERS.GENERIC.DESCRIBE.MERMHOUSE_FARMER = ">:)"


local function oldfish_widgetcreation()
  local params = {}
  params.oldfish_farmer = {
    widget = {
      slotpos = {},
      animbank = "ui_chest_8x8",
      animbuild = "ui_chest_8x8",
      pos = GLOBAL.Vector3(0, 200, 0),
      side_align_tip = 160,
    },
    type = "chest"
  }

  for y = 7, 0, -1 do
    for x = 0, 7 do
      table.insert(params.oldfish_farmer.widget.slotpos, GLOBAL.Vector3(70 * x - 250, 70 * y - 270, 0))
    end
  end

  local containers = GLOBAL.require "containers"
  containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS,
    params.oldfish_farmer.widget.slotpos ~= nil and #params.oldfish_farmer.widget.slotpos or 0)
  local old_widgetsetup = containers.widgetsetup
  function containers.widgetsetup(container, prefab, data)
    local pref = prefab or container.inst.prefab
    if pref == "oldfish_farmer" then
      local t = params[pref]
      if t ~= nil then
        for k, v in pairs(t) do
          container[k] = v
        end
        container:SetNumSlots(container.widget.slotpos ~= nil and #container.widget.slotpos or 0)
      end
    else
      return old_widgetsetup(container, prefab)
    end
  end
end

oldfish_widgetcreation()

local REGISTER_SOIL = GLOBAL.Action({ tile_placer = "gridplacer" })
REGISTER_SOIL.id = "REGISTER_SOIL"
REGISTER_SOIL.str = "Register Soil Tile"
REGISTER_SOIL.fn = function(act)
  if act.invobject then
    return act.invobject.components.farmlayout:RegisterFarmTile(act:GetActionPoint())
  end
end
AddAction(REGISTER_SOIL)

local UNREGISTER_SOIL = GLOBAL.Action({ tile_placer = "gridplacer" })
UNREGISTER_SOIL.id = "UNREGISTER_SOIL"
UNREGISTER_SOIL.str = "Unregister Soil Tile"
UNREGISTER_SOIL.fn = function(act)
  if act.invobject then
    return act.invobject.components.farmlayout:UnregisterFarmTile(act:GetActionPoint())
  end
end
AddAction(UNREGISTER_SOIL)

AddComponentAction("POINT", "farmlayout", function(inst, doer, pos, actions, right, target)
  local isfarmablesoil = GLOBAL.TheWorld.Map:GetTileAtPoint(pos.x, pos.y, pos.z) == WORLD_TILES.FARMING_SOIL

  if right and isfarmablesoil then
    if inst.components.farmlayout:IsRegisteredFarmTile(pos) then
      table.insert(actions, GLOBAL.ACTIONS.UNREGISTER_SOIL)
    else
      table.insert(actions, GLOBAL.ACTIONS.REGISTER_SOIL)
    end
  end
end)

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(GLOBAL.ACTIONS.REGISTER_SOIL, "dolongaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(GLOBAL.ACTIONS.REGISTER_SOIL, "dolongaction"))
AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(GLOBAL.ACTIONS.UNREGISTER_SOIL, "dolongaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(GLOBAL.ACTIONS.UNREGISTER_SOIL, "dolongaction"))

function dump(o)
  if type(o) == 'table' then
    local s = '{ \n'
    for k, v in pairs(o) do
      if type(k) ~= 'number' then k = '"' .. k .. '"' end
      s = s .. '[' .. k .. '] = ' .. dump(v) .. ',\n'
    end
    return s .. '} \n'
  else
    return tostring(o)
  end
end

-- Farm layout is defined on an item made with papyrus and pen maybe something like that blueprint like
-- FarmMerm House unlocked on merm king upgrade
-- FarmerMerm must have seeds on inventory, or on a container nearby
--  Players can store seeds on FarmMerm House
-- after harvesting the farmer stores the food in his house, which stores infinite amount of food? or can be extended with chests?
--  [] house stores infinite amount of food, players cant place any food or any other items inside the house, only collecting from it is permitted
--  [] house storage can be extended with chests or something
-- retills and replants the available seeds, then tends to them by talking, fertilizing and watering
-- if there's no storage available farmers will drop seeds and food next to the house
-- FarmerMerm does not unload, this can be disabled in the configurations

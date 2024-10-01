local CONSTANTS = require "mermexp.constants"
local FARM_PLANT_TAGS = CONSTANTS.FARM_PLANT_TAGS
local Util = require "mermexp.util"

local MAP_3x3 = {
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

local function Replica_RegisterTile(self, tag, tile)
  self.inst.replica.mermexp_mermfarmblueprint:RegisterFarmTile(tag, tile)
end

local function Replica_UnregisterTile(self, tag)
  self.inst.replica.mermexp_mermfarmblueprint:UnregisterFarmTile(tag)
end

local function on_registeredtiles(self, registeredtiles)
  print("on_registeredtiles:", CalledFrom())
  self.inst.replica.mermexp_mermfarmblueprint:SetRegisteredTiles(registeredtiles)
end

-- local function OnEnterLimbo(inst, data)
--   local self = inst.components.mermexp_mermfarmblueprint
--   for k, tile in pairs(self.registeredtiles) do
--     for _, slot in ipairs(tile.slots) do
--       print(k, slot.assigned_plant)
--     end
--   end
-- end

local function OnExitLimbo(inst, data)
  local self = inst.components.mermexp_mermfarmblueprint
  on_registeredtiles(self, self.registeredtiles)
end

local FarmBlueprint = Class(function(self, inst)
    self.inst = inst

    self.onchangefn = nil
    self.registeredtiles = {}

    -- self.inst:ListenForEvent("enterlimbo", OnEnterLimbo)
    self.inst:ListenForEvent("exitlimbo", OnExitLimbo)
  end,
  nil,
  {
    registeredtiles = on_registeredtiles,
  }
)

function FarmBlueprint:SetOnChangeFn(fn)
  self.onchangefn = fn
end

local function MakeTile(x, y, z, capturelayout)
  local tcx, tcy, tcz = TheWorld.Map:GetTileCenterPoint(x, y, z)

  local slots = {}
  for i, offsets in ipairs(MAP_3x3) do
    slots[i] = {
      assigned_plant = nil,
      x = tcx + offsets[1],
      y = 0,
      z = tcz + offsets[2]
    }

    if capturelayout then
      local plant = TheSim:FindEntities(slots[i].x, slots[i].y, slots[i].z, 0.21, FARM_PLANT_TAGS)[1]
      if plant ~= nil then
        slots[i].assigned_plant = CONSTANTS.PLANTABLES:At(plant.prefab)
      end
    end
  end

  return { x = tcx, y = tcy, z = tcz, slots = slots }
end

function FarmBlueprint:GetAssignedPlant(tile_tag, slot_index)
  if self.registeredtiles[tile_tag] == nil then return nil end

  local slot_array = self.registeredtiles[tile_tag].slots
  if not slot_array or not slot_array[slot_index] then return nil end

  return slot_array[slot_index].assigned_plant
end

function FarmBlueprint:SetAssignedPlant(tile_tag, slot_index, plant)
  local tile = self.registeredtiles[tile_tag]
  local slot_array = tile.slots

  if not slot_array or not slot_array[slot_index] then return end

  slot_array[slot_index].assigned_plant = plant and CONSTANTS.PLANTABLES:At(plant) or nil

  if self.onchangefn ~= nil then self.onchangefn() end
end

function FarmBlueprint:RegisterFarmTile(x, y, z, capturelayout)
  local tiletag = Util.TileTag(x, y, z)
  if self.registeredtiles[tiletag] ~= nil and not capturelayout then return false end

  self.registeredtiles[tiletag] = MakeTile(x, y, z, capturelayout)

  Replica_RegisterTile(self, tiletag, self.registeredtiles[tiletag])

  if self.onchangefn ~= nil then self.onchangefn() end

  return true
end

function FarmBlueprint:UnregisterFarmTile(tilept, y, z)
  local tiletag = type(tilept) == "string" and tilept or Util.TileTag(tilept, y, z)

  if self.registeredtiles[tiletag] == nil then return false end

  self.registeredtiles[tiletag] = nil

  Replica_UnregisterTile(self, tiletag)

  if self.onchangefn ~= nil then self.onchangefn() end

  return true
end

function FarmBlueprint:GetUnregisteredConnectedTiles()
  local tiles = {}

  local function InsertTile(x, y, z)
    local tcx, tcy, tcz = TheWorld.Map:GetTileCenterPoint(x, y, z)
    tiles[Util.TileTag(x, y, z)] = { x = tcx, y = tcy, z = tcz }
  end
  local function IsInserted(x, y, z) return tiles[Util.TileTag(x, y, z)] ~= nil end
  local function IsFarmingSoil(x, y, z) return TheWorld.Map:GetTileAtPoint(x, y, z) == WORLD_TILES.FARMING_SOIL end

  for tile_tag, tile in pairs(self.registeredtiles) do
    if tiles[tile_tag] == nil then
      Util.FloodTileSearch(tile.x, tile.y, tile.z, InsertTile, IsInserted, IsFarmingSoil)
    end
  end

  return tiles
end

function FarmBlueprint:GetRegisteredFarmTiles()
  return self.registeredtiles
end

function FarmBlueprint:GetRegisteredFarmTileAtPoint(x, y, z)
  return self.registeredtiles[Util.TileTag(x, y, z)]
end

function FarmBlueprint:IsRegisteredFarmTile(x, y, z)
  local tiletag = type(x) == "string" and x or Util.TileTag(x, y, z)

  return self.registeredtiles[tiletag] ~= nil
end

function FarmBlueprint:OnSave()
  print("vou me cagar heing")
  return { registeredtiles = self.registeredtiles }
end

function FarmBlueprint:OnLoad(data)
  print("me caguei gente")
  if data.registeredtiles then
    self.registeredtiles = data.registeredtiles
  end
end

return FarmBlueprint

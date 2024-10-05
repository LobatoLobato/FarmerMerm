local CONSTANTS = require "mermexp.constants"
local FARM_PLANT_TAGS = CONSTANTS.FARM_PLANT_TAGS
local Util = require "mermexp.util"

local function Classified_RegisterFarmTile(self, tile)
  local classified = self.inst.replica.mermexp_mermfarmblueprint.classified
  if classified ~= nil then classified:RegisterFarmTile(tile) end
end

local function Classified_UnregisterFarmTile(self, x, y, z)
  local classified = self.inst.replica.mermexp_mermfarmblueprint.classified
  if classified ~= nil then classified:UnregisterFarmTile(x, y, z) end
end

local function Classified_ClearFarmTiles(self)
  local classified = self.inst.replica.mermexp_mermfarmblueprint.classified
  if classified ~= nil then classified:ClearFarmTiles() end
end

local function Classified_SetAssignedPlant(self, tag, slotidx, plant)
  local classified = self.inst.replica.mermexp_mermfarmblueprint.classified
  if classified ~= nil then classified:SetAssignedPlant(tag, slotidx, plant) end
end

local function Classified_SetRegisteredFarmTiles(self, registeredtiles)
  local classified = self.inst.replica.mermexp_mermfarmblueprint.classified
  if classified ~= nil then classified:SetRegisteredFarmTiles(registeredtiles) end
end

local function OnEnterLimbo(inst)
  local self = inst.components.mermexp_mermfarmblueprint
  local owner = inst.components.inventoryitem.owner

  if owner ~= nil and owner:HasTag("player") and owner ~= self.owner then
    Classified_SetRegisteredFarmTiles(self, self:GetRegisteredFarmTiles())
  end

  self.owner = owner
end

local function OnDropped(inst)
  local self = inst.components.mermexp_mermfarmblueprint
  self.owner = nil
end

---@class FarmTileSlot
---@field x number
---@field y number
---@field z number
---@field assigned_plant Plant?

---@class FarmTile
---@field x number
---@field y number
---@field z number
---@field slots FarmTileSlot[]

local FarmBlueprint = Class(function(self, inst)
    self.inst = inst

    self.registeredtiles = {}

    self.owner = nil
    self.inst:ListenForEvent("enterlimbo", OnEnterLimbo)
    self.inst:ListenForEvent("ondropped", OnDropped)
  end,
  nil,
  {
    registeredtiles = Classified_SetRegisteredFarmTiles,
  }
)

---comment
---@param x number
---@param y number
---@param z number
---@param capturelayout boolean
---@return FarmTile
local function MakeTile(x, y, z, capturelayout)
  local tcx, tcy, tcz = TheWorld.Map:GetTileCenterPoint(x, y, z)

  local slots = {}
  for i, offsets in ipairs(CONSTANTS.TILE3x3) do
    local slot = {
      assigned_plant = nil,
      x = tcx + offsets[1],
      y = 0,
      z = tcz + offsets[2]
    }

    if capturelayout then
      local plant = TheSim:FindEntities(slot.x, slot.y, slot.z, 0.21, FARM_PLANT_TAGS)[1]
      if plant ~= nil then
        slot.assigned_plant = CONSTANTS.PLANTABLES:At(plant.prefab)
      end
    end

    slots[tostring(i)] = slot
  end

  return { x = tcx, y = tcy, z = tcz, slots = slots }
end

---Registers a farm tile to the blueprint
---@param x number
---@param y number
---@param z number
---@param capturelayout boolean
---@return boolean
function FarmBlueprint:RegisterFarmTile(x, y, z, capturelayout)
  local tiletag = Util.TileTag(x, y, z)
  if self.registeredtiles[tiletag] ~= nil and not capturelayout then return false end

  self.registeredtiles[tiletag] = MakeTile(x, y, z, capturelayout)

  Classified_RegisterFarmTile(self, self.registeredtiles[tiletag])

  self.inst:PushEvent("registerfarmtile")
  self.inst:PushEvent("change")

  return true
end

---Unregisters a farm tile from the blueprint
---@param x_or_tag number | string
---@param y number
---@param z number
---@return boolean
function FarmBlueprint:UnregisterFarmTile(x_or_tag, y, z)
  local tiletag = type(x_or_tag) == "string" and x_or_tag or Util.TileTag(x_or_tag, y, z)

  if self.registeredtiles[tiletag] == nil then return false end

  self.registeredtiles[tiletag] = nil

  Classified_UnregisterFarmTile(self, x_or_tag, y, z)

  self.inst:PushEvent("unregisterfarmtile")
  self.inst:PushEvent("change")

  return true
end

---Removes assigned plants in all the tiles's slots
function FarmBlueprint:ClearFarmTiles()
  for _, tile in pairs(self.registeredtiles) do
    for _, slot in pairs(tile.slots) do
      slot.assigned_plant = nil
    end
  end

  Classified_ClearFarmTiles(self)

  self.inst:PushEvent("clearfarmtiles")
  self.inst:PushEvent("change")
end

---Gets all registered farm tiles
---@return { [string]: FarmTile }
function FarmBlueprint:GetRegisteredFarmTiles()
  return self.registeredtiles
end

---Gets the tile's slot's assigned plant
---@param tag string
---@param slotidx number
---@return Plant?
function FarmBlueprint:GetAssignedPlant(tag, slotidx)
  if self.registeredtiles[tag] == nil then return nil end
  local slotkey = tostring(slotidx)
  local slots = self.registeredtiles[tag].slots
  if not slots or not slots[slotkey] then return nil end

  return slots[slotkey].assigned_plant
end

---Gets the assigned plant that corresponds to x, z
---@param x number
---@param z number
---@return Plant?
function FarmBlueprint:GetAssignedPlantAt(x, z)
  for _, tile in pairs(self.registeredtiles) do
    for _, slot in pairs(tile.slots) do
      local sx, sz = slot.x, slot.z
      local range = 0.21

      if sx - range <= x and x <= sx + range and sz - range <= z and z <= sz + range then
        return slot.assigned_plant
      end
    end
  end

  return nil
end

---Sets the tile's slot's assigned plant
---@param tag string
---@param slotidx number
---@param plant string
function FarmBlueprint:SetAssignedPlant(tag, slotidx, plant)
  local tile = self.registeredtiles[tag]
  local slots = tile.slots
  local slotkey = tostring(slotidx)

  if not slots or not slots[slotkey] then return end

  local plant = plant and CONSTANTS.PLANTABLES:At(plant) or nil
  slots[slotkey].assigned_plant = plant

  Classified_SetAssignedPlant(self, tag, slotidx, plant)

  self.inst:PushEvent("setassignedplant")
  self.inst:PushEvent("change")
end

---Gets the registered tile by its world coordinates
---@param x number
---@param y number
---@param z number
---@return FarmTile?
function FarmBlueprint:GetRegisteredFarmTileAtPoint(x, y, z)
  return self.registeredtiles[Util.TileTag(x, y, z)]
end

---Checks if tile is registered
---@param x_or_tag number | string
---@param y number
---@param z number
---@return boolean
function FarmBlueprint:IsRegisteredFarmTile(x_or_tag, y, z)
  local tiletag = type(x_or_tag) == "string" and x_or_tag or Util.TileTag(x_or_tag, y, z)

  return self.registeredtiles[tiletag] ~= nil
end

---Gets all unregistered tiles connected to the blueprint's registered tiles
---@return { [string]: FarmTile }
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

function FarmBlueprint:OnSave()
  return { registeredtiles = self.registeredtiles }
end

function FarmBlueprint:OnLoad(data)
  if data.registeredtiles then
    self.registeredtiles = data.registeredtiles
  end
end

return FarmBlueprint

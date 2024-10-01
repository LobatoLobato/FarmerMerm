local CONSTANTS = require "mermexp.constants"
local Util = require "mermexp.util"
local JSON = require "mermexp.util.json"

local FarmBlueprint = Class(function(self, inst)
  self.inst = inst
  self._onchangefn = nil
  self._registeredtiles = {}

  self._initializeevent = net_event(inst.GUID, "mxp.mermfarmblueprint._initializeevent")
  self._registertileevent = net_event(inst.GUID, "mxp.mermfarmblueprint._registertileevent")
  self._unregistertileevent = net_event(inst.GUID, "mxp.mermfarmblueprint._unregistertileevent")
  self._eventdata = net_string(inst.GUID, "mxp.mermfarmblueprint._eventdata")

  if not TheNet:IsDedicated() then
    self.initialized = false

    inst:ListenForEvent("mxp.mermfarmblueprint._initializeevent", function()
      if self.initialized then return end
      print("event.initializetile:", CalledFrom())
      local data = self._eventdata:value()
      if data == "" then return end

      for tag, tile in pairs(JSON.decode(data)) do
        if tile.x and tile.y and tile.z and tile.slots then
          self._registeredtiles[tag] = tile
        end
      end

      self.initialized = true
    end)

    inst:ListenForEvent("mxp.mermfarmblueprint._registertileevent", function()
      print("event.registertile:", CalledFrom())
      local data = JSON.decode(self._eventdata:value())
      self._registeredtiles[data.tag] = data.tile
      if self._onchangefn then self._onchangefn() end
    end)

    inst:ListenForEvent("mxp.mermfarmblueprint._unregistertileevent", function()
      print("event.unregistertile:", CalledFrom())
      local tag = self._eventdata:value()
      self._registeredtiles[tag] = nil
      if self._onchangefn then self._onchangefn() end
    end)
  end
end)

local function component(self)
  return self.inst.components.mermexp_mermfarmblueprint
end

local function _SendRPCToServer(self, command, ...)
  Util.SendComponentRPCToServer(self.inst, "mermexp_mermfarmblueprint", command, ...)
end

--------------------------------------------------------------------------
--Common interface
--------------------------------------------------------------------------

---@class Plant
---@field name string
---@field prefab string
---@field build string
---@field bank string
---@field anim string
---@field index number

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

---comment
---@param tag string
---@param tile FarmTile
function FarmBlueprint:RegisterFarmTile(tag, tile)
  if component(self) then
    -- print(debug.getinfo(2).name)
    print("replica.RegisterFarmTile:", CalledFrom())
    self._eventdata:set(JSON.encode({ tag = tag, tile = tile }))
    self._registertileevent:push()
  else
    _SendRPCToServer(self, "RegisterFarmTile", tile.x, tile.y, tile.z)
  end
end

---comment
---@param tag string
function FarmBlueprint:UnregisterFarmTile(tag)
  if component(self) then
    self._eventdata:set(tag)
    self._unregistertileevent:push()
  else
    _SendRPCToServer(self, "UnregisterFarmTile", tag)
  end
end

---comment
---@param tile_tag string
---@param slot_index number
---@return Plant?
function FarmBlueprint:GetAssignedPlant(tile_tag, slot_index)
  if component(self) then
    return component(self):GetAssignedPlant(tile_tag, slot_index)
  else
    if self._registeredtiles[tile_tag] == nil then return nil end

    local slot_array = self._registeredtiles[tile_tag].slots
    if not slot_array or not slot_array[slot_index] then return nil end

    return slot_array[slot_index].assigned_plant
  end
end

---comment
---@param tile_tag string
---@param slot_index number
---@param plant string
---@return nil
function FarmBlueprint:SetAssignedPlant(tile_tag, slot_index, plant)
  if component(self) then
    return component(self):SetAssignedPlant(tile_tag, slot_index, plant)
  else
    if self._registeredtiles[tile_tag] == nil then return end

    local slot_array = self._registeredtiles[tile_tag].slots
    if not slot_array or not slot_array[slot_index] then return end

    slot_array[slot_index].assigned_plant = plant and CONSTANTS.PLANTABLES:At(plant) or nil

    if self._onchangefn ~= nil then self._onchangefn() end

    _SendRPCToServer(self, "SetAssignedPlant", tile_tag, slot_index, plant)
  end
end

---comment
---@return { [string]: FarmTile }
function FarmBlueprint:GetRegisteredFarmTiles()
  if component(self) then
    return component(self):GetRegisteredFarmTiles()
  else
    return self._registeredtiles
  end
end

--------------------------------------------------------------------------
--Server interface
--------------------------------------------------------------------------

---comment
---@param tiles { [string]: FarmTile }
function FarmBlueprint:SetRegisteredTiles(tiles)
  if component(self) then
    self._eventdata:set(JSON.encode(tiles))
    self._initializeevent:push()
  end
end

--------------------------------------------------------------------------
--Client interface
--------------------------------------------------------------------------

---comment
---@param fn? function
function FarmBlueprint:SetOnChangeFn(fn)
  if component(self) then
    component(self):SetOnChangeFn(fn)
  else
    self._onchangefn = fn
  end
end

---comment
---@param slot FarmTileSlot
---@return boolean
function FarmBlueprint.SlotIsPlanted(slot)
  if slot.assigned_plant == nil then return false end
  local ents = TheSim:FindEntities(slot.x, slot.y, slot.z, 0.1, { "farm_plant" })
  for _, ent in ipairs(ents) do
    if ent.prefab:gsub("farm_plant_", ""):gsub("weed_", "") == slot.assigned_plant.name:gsub("_seeds", "") then
      return true
    end
  end

  return false
end

---comment
---@param slot FarmTileSlot
---@return boolean
function FarmBlueprint.SlotIsTilled(slot)
  local ents = TheSim:FindEntities(slot.x, slot.y, slot.z, 0.1, { "soil" })
  return #ents > 0
end

---comment
---@param x number
---@param y number
---@param z number
---@return FarmTile?
function FarmBlueprint:GetRegisteredFarmTileAtPoint(x, y, z)
  if component(self) then
    return component(self):GetRegisteredFarmTileAtPoint(x, y, z)
  else
    return self._registeredtiles[Util.TileTag(x, y, z)]
  end
end

---comment
---@param x number
---@param y number
---@param z number
---@return boolean
function FarmBlueprint:IsRegisteredFarmTile(x, y, z)
  if component(self) then
    return component(self):IsRegisteredFarmTile(x, y, z)
  else
    if type(x) == "string" then return self._registeredtiles[x] ~= nil end
    return self._registeredtiles[Util.TileTag(x, y, z)] ~= nil
  end
end

---comment
---@return { [string]: FarmTile }
function FarmBlueprint:GetUnregisteredConnectedTiles()
  if component(self) then
    return component(self):GetUnregisteredConnectedTiles()
  else
    local tiles = {}

    local function InsertTile(tx, ty, tz)
      local tcx, tcy, tcz = TheWorld.Map:GetTileCenterPoint(tx, ty, tz)
      tiles[Util.TileTag(tx, ty, tz)] = { x = tcx, y = tcy, z = tcz }
    end
    local function IsInserted(tx, ty, tz) return tiles[Util.TileTag(tx, ty, tz)] ~= nil end
    local function IsFarmingSoil(tx, ty, tz) return TheWorld.Map:GetTileAtPoint(tx, ty, tz) == WORLD_TILES.FARMING_SOIL end

    for tile_tag, tile in pairs(self._registeredtiles) do
      if tiles[tile_tag] == nil then
        Util.FloodTileSearch(tile.x, tile.y, tile.z, InsertTile, IsInserted, IsFarmingSoil)
      end
    end

    return tiles
  end
end

return FarmBlueprint

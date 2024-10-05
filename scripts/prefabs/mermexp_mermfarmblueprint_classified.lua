local CONSTANTS = require "mermexp.constants"
local Util = require "mermexp.util"
local JSON = require "mermexp.util.json"

local function component(inst)
  return inst._parent.components.mermexp_mermfarmblueprint
end

local function _SendRPCToServer(inst, command, ...)
  Util.SendComponentRPCToServer(inst._parent, "mermexp_mermfarmblueprint", command, ...)
end

-- 1798
-- 33-42
local function CompressSlot(slot)
  return slot.assigned_plant and CONSTANTS.PLANTABLES:Index(slot.assigned_plant.name) or 0
end
local function DecompressSlot(slot, x, y, z, index)
  local assigned_plant = slot ~= 0 and CONSTANTS.PLANTABLES:At(slot) or nil
  local x, z = x + CONSTANTS.TILE3x3[index][1], z + CONSTANTS.TILE3x3[index][2]

  return { x = x, y = y, z = z, assigned_plant = assigned_plant }
end

local function CompressTile(tile)
  local compressed_tile = { tile.x, tile.y, tile.z, {} }
  local slots = compressed_tile[4]
  for k, slot in pairs(tile.slots) do
    slots[tonumber(k)] = CompressSlot(slot)
  end

  return compressed_tile
end
local function DecompressTile(tile, maketag)
  local decompressed_tile = { x = tile[1], y = tile[2], z = tile[3], slots = {} }
  for i, slot in ipairs(tile[4]) do
    decompressed_tile.slots[tostring(i)] = DecompressSlot(slot, tile[1], tile[2], tile[3], i)
  end

  return decompressed_tile, maketag and Util.TileTag(decompressed_tile) or nil
end

local function CompressTiles(tiles)
  local compressed_tiles = {}
  for _, tile in pairs(tiles) do
    table.insert(compressed_tiles, CompressTile(tile))
  end
  return compressed_tiles
end
local function DecompressTiles(tiles)
  local decompressed_tiles = {}
  for _, tile in ipairs(tiles) do
    local tile, tag = DecompressTile(tile, true)
    decompressed_tiles[tag] = tile
  end
  return decompressed_tiles
end

--------------------------------------------------------------------------
--Common interface
--------------------------------------------------------------------------

---Registers a farm tile to the blueprint
---@param inst table
---@param tile {x: number, y:number, z:number, slots: FarmTileSlot[]?}
---@param capturelayout boolean
---@return boolean
local function RegisterFarmTile(inst, tile, capturelayout)
  local result = inst._registeredtiles[Util.TileTag(tile.x, tile.y, tile.z)] == nil or capturelayout
  if component(inst) then
    inst.synceventlistener:Push("registerfarmtile", CompressTile(tile))
  else
    _SendRPCToServer(inst, "RegisterFarmTile", tile.x, tile.y, tile.z, capturelayout)
  end

  return result
end

---Unregisters a farm tile from the blueprint
---@param inst table
---@param x_or_tag number | string
---@param y number
---@param z number
---@return boolean
local function UnregisterFarmTile(inst, x_or_tag, y, z)
  local tag = type(x_or_tag) == "string" and x_or_tag or Util.TileTag(x_or_tag, y, z)
  local result = inst._registeredtiles[tag] ~= nil
  if component(inst) then
    inst.synceventlistener:Push("unregisterfarmtile", tag)
  else
    _SendRPCToServer(inst, "UnregisterFarmTile", x_or_tag, y, z)
  end

  return result
end

---Removes assigned plants in all the tiles's slots
---@param inst table
local function ClearFarmTiles(inst)
  if component(inst) then
    inst.synceventlistener:Push("clearfarmtiles")
  else
    _SendRPCToServer(inst, "ClearFarmTiles")
  end
end

---Sets the tile's slot's assigned plant
---@param inst table
---@param tag string
---@param slotidx number
---@param plant string | Plant | nil
local function SetAssignedPlant(inst, tag, slotidx, plant)
  if component(inst) and (type(plant) == "table" or plant == nil) then
    local plant = plant ~= nil and CONSTANTS.PLANTABLES:Index(plant.name) or nil
    inst.synceventlistener:Push("setassignedplant", { tag, slotidx, plant })
  elseif (type(plant) == "string" or plant == nil) then
    _SendRPCToServer(inst, "SetAssignedPlant", tag, slotidx, plant)
  end
end

--------------------------------------------------------------------------
--Server interface
--------------------------------------------------------------------------

---Gets all registered farm tiles
---@param inst table
---@return { [string]: FarmTile }
local function GetRegisteredFarmTiles(inst)
  return inst._registeredtiles
end

---Sets registeredtiles table
---@param inst table
---@param tiles { [string]: FarmTile }
local function SetRegisteredFarmTiles(inst, tiles)
  inst.synceventlistener:Push("setregisteredfarmtiles", CompressTiles(tiles))
end

--------------------------------------------------------------------------
--Client interface
--------------------------------------------------------------------------

---Gets the tile's slot's assigned plant
---@param inst table
---@param tile_tag string
---@param slot_index number
---@return Plant?
local function GetAssignedPlant(inst, tile_tag, slot_index)
  if inst._registeredtiles[tile_tag] == nil then return nil end
  local slot_key = tostring(slot_index)
  local slot_array = inst._registeredtiles[tile_tag].slots
  if not slot_array or not slot_array[slot_key] then return nil end

  return slot_array[slot_key].assigned_plant
end

---Gets the registered tile by its world coordinates
---@param inst table
---@param x number
---@param y number
---@param z number
---@return FarmTile?
local function GetRegisteredFarmTileAtPoint(inst, x, y, z)
  return inst._registeredtiles[Util.TileTag(x, y, z)]
end

---Checks if tile is registered
---@param inst table
---@param x_or_tag number | string
---@param y number
---@param z number
---@return boolean
local function IsRegisteredFarmTile(inst, x_or_tag, y, z)
  if type(x_or_tag) == "string" then return inst._registeredtiles[x_or_tag] ~= nil end
  return inst._registeredtiles[Util.TileTag(x_or_tag, y, z)] ~= nil
end

---Gets all unregistered tiles connected to the blueprint's registered tiles
---@param inst table
---@return { [string]: FarmTile }
local function GetUnregisteredConnectedTiles(inst)
  local tiles = {}

  local function InsertTile(tx, ty, tz)
    local tcx, tcy, tcz = TheWorld.Map:GetTileCenterPoint(tx, ty, tz)
    tiles[Util.TileTag(tx, ty, tz)] = { x = tcx, y = tcy, z = tcz }
  end
  local function IsInserted(tx, ty, tz) return tiles[Util.TileTag(tx, ty, tz)] ~= nil end
  local function IsFarmingSoil(tx, ty, tz) return TheWorld.Map:GetTileAtPoint(tx, ty, tz) == WORLD_TILES.FARMING_SOIL end

  for tile_tag, tile in pairs(inst._registeredtiles) do
    if tiles[tile_tag] == nil then
      Util.FloodTileSearch(tile.x, tile.y, tile.z, InsertTile, IsInserted, IsFarmingSoil)
    end
  end

  return tiles
end

local function OnEntityReplicated(inst)
  inst._parent = inst.entity:GetParent()
  if inst._parent == nil then
    print("Unable to initialize classified data for mermexp_mermfarmblueprint")
  else
    inst._parent:AttachMermexpMermfarmBlueprintClassified(inst)
    if inst._parent.replica.mermexp_mermfarmblueprint ~= nil then
      inst._parent.replica.mermexp_mermfarmblueprint:AttachClassified(inst)
    end
  end
end

local function RegisterNetListeners(inst)
  if TheWorld.ismastersim then
    inst._parent = inst.entity:GetParent()
  end
end

local function AddSyncEventListener(inst)
  inst.synceventlistener = {
    event = net_event(inst.GUID, "mxp.mermfarmblueprint.synceventlistener.event"),
    event_type = net_string(inst.GUID, "mxp.mermfarmblueprint.synceventlistener.event_type"),
    events = {},
    listener = function()
      local event_type = inst.synceventlistener.event_type:value()
      local data_json = inst.synceventlistener.events[event_type].data:value()
      local handler = inst.synceventlistener.events[event_type].handler

      print("Handling SyncEvent [" .. event_type .. "]...")
      print("  Message Length: " .. data_json:len() .. " bytes")

      if handler == nil then print("no handler for " .. event_type) end

      if data_json ~= "" and handler ~= nil then
        handler(inst, JSON.decode(data_json))
        inst._parent:PushEvent(event_type)
        inst._parent:PushEvent("change")
      end
    end,
    Push = function(self, event_type, data)
      self.events[event_type].data:set(JSON.encode(data ~= nil and data or {}))
      self.event_type:set(event_type)
      self.event:push()
    end,
    AddHandler = function(self, event_type, handler)
      self.events[event_type] = {
        data = net_string(inst.GUID, "mxp.mermfarmblueprint.synceventlistener._" .. event_type .. ".data"),
        handler = not TheWorld.ismastersim and handler or nil
      }
    end
  }

  if not TheWorld.ismastersim then
    inst:ListenForEvent("mxp.mermfarmblueprint.synceventlistener.event", inst.synceventlistener.listener)
  end
end


local function on_setregisteredfarmtiles(inst, data)
  for tag, tile in pairs(DecompressTiles(data)) do
    inst._registeredtiles[tag] = tile
  end
end

local function on_registerfarmtile(inst, data)
  local tile, tag = DecompressTile(data, true)
  inst._registeredtiles[tag] = tile
end

local function on_unregisterfarmtile(inst, tag)
  inst._registeredtiles[tag] = nil
end

local function on_clearfarmtiles(inst)
  for _, tile in pairs(inst._registeredtiles) do
    for _, slot in pairs(tile.slots) do slot.assigned_plant = nil end
  end
end
local function on_setassignedplant(inst, data)
  local tag, slotkey, plant = data[1], tostring(data[2]), data[3]
  local tile = inst._registeredtiles[tag]

  if tile ~= nil and tile.slots[slotkey] ~= nil then
    tile.slots[slotkey].assigned_plant = plant ~= nil and CONSTANTS.PLANTABLES:At(plant) or nil
  end
end

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform() --So we can follow parent's sleep state
  inst.entity:AddNetwork()
  inst.entity:Hide()
  inst:AddTag("CLASSIFIED")

  if not TUNING.MERMEXP_MERMFARMER_UNLOADS then
    inst.entity:SetCanSleep(false)
  end

  inst._registeredtiles = {}

  AddSyncEventListener(inst)

  inst.synceventlistener:AddHandler("setregisteredfarmtiles", on_setregisteredfarmtiles)
  inst.synceventlistener:AddHandler("registerfarmtile", on_registerfarmtile)
  inst.synceventlistener:AddHandler("unregisterfarmtile", on_unregisterfarmtile)
  inst.synceventlistener:AddHandler("clearfarmtiles", on_clearfarmtiles)
  inst.synceventlistener:AddHandler("setassignedplant", on_setassignedplant)

  --Delay net listeners until after initial values are deserialized
  inst:DoTaskInTime(0, RegisterNetListeners)

  inst.entity:SetPristine()

  inst.RegisterFarmTile = RegisterFarmTile
  inst.UnregisterFarmTile = UnregisterFarmTile
  inst.ClearFarmTiles = ClearFarmTiles
  inst.SetAssignedPlant = SetAssignedPlant
  inst.GetRegisteredFarmTiles = GetRegisteredFarmTiles

  if not TheWorld.ismastersim then
    --Client interface
    inst.OnEntityReplicated = OnEntityReplicated
    inst.GetAssignedPlant = GetAssignedPlant
    inst.GetRegisteredFarmTileAtPoint = GetRegisteredFarmTileAtPoint
    inst.IsRegisteredFarmTile = IsRegisteredFarmTile
    inst.GetUnregisteredConnectedTiles = GetUnregisteredConnectedTiles

    return inst
  end

  inst.SetRegisteredFarmTiles = SetRegisteredFarmTiles

  inst.persists = false

  return inst
end

return Prefab("mermexp_mermfarmblueprint_classified", fn)

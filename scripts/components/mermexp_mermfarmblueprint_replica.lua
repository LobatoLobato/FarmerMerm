local FarmBlueprint = Class(function(self, inst)
  self.inst = inst

  if TheWorld.ismastersim then
    self.classified = inst.mermexp_mermfarmblueprint_classified
  elseif self.classified == nil and inst.mermexp_mermfarmblueprint_classified ~= nil then
    self:AttachClassified(inst.mermexp_mermfarmblueprint_classified)
  end
end)

--------------------------------------------------------------------------

function FarmBlueprint:OnRemoveFromEntity()
  if self.classified ~= nil then
    if TheWorld.ismastersim then
      self.classified = nil
    else
      self.inst:RemoveEventCallback("onremove", self.ondetachclassified, self.classified)
      self:DetachClassified()
    end
  end
end

FarmBlueprint.OnRemoveEntity = FarmBlueprint.OnRemoveFromEntity

function FarmBlueprint:AttachClassified(classified)
  self.classified = classified
  self.ondetachclassified = function() self:DetachClassified() end
  self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)
end

function FarmBlueprint:DetachClassified()
  self.classified = nil
  self.ondetachclassified = nil
end

--------------------------------------------------------------------------

local function component(self)
  return self.inst.components.mermexp_mermfarmblueprint
end

---Checks if slot has its assigned plant planted
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

---Checks if slot is tilled
---@param slot FarmTileSlot
---@return boolean
function FarmBlueprint.SlotIsTilled(slot)
  local ents = TheSim:FindEntities(slot.x, slot.y, slot.z, 0.1, { "soil" })
  return #ents > 0
end

---Registers a farm tile to the blueprint
---@param x number
---@param y number
---@param z number
---@param capturelayout boolean
---@return boolean
function FarmBlueprint:RegisterFarmTile(x, y, z, capturelayout)
  if component(self) then
    return component(self):RegisterFarmTile(x, y, z, capturelayout)
  else
    return self.classified ~= nil and self.classified:RegisterFarmTile(Vector3(x, y, z), capturelayout) or false
  end
end

---Unregisters a farm tile from the blueprint
---@param x_or_tag number | string
---@param y number
---@param z number
---@return boolean
function FarmBlueprint:UnregisterFarmTile(x_or_tag, y, z)
  if component(self) then
    return component(self):UnregisterFarmTile(x_or_tag, y, z)
  else
    return self.classified ~= nil and self.classified:UnregisterFarmTile(x_or_tag, y, z) or false
  end
end

---Removes assigned plants in all the tiles's slots
function FarmBlueprint:ClearFarmTiles()
  if component(self) then
    component(self):ClearFarmTiles()
  elseif self.classified ~= nil then
    self.classified:ClearFarmTiles()
  end
end

---Gets all registered farm tiles
---@return { [string]: FarmTile }
function FarmBlueprint:GetRegisteredFarmTiles()
  if component(self) then
    return component(self):GetRegisteredFarmTiles()
  else
    return self.classified ~= nil and self.classified:GetRegisteredFarmTiles() or {}
  end
end

---Gets the tile's slot's assigned plant
---@param tile_tag string
---@param slot_index number
---@return Plant?
function FarmBlueprint:GetAssignedPlant(tile_tag, slot_index)
  if component(self) then
    return component(self):GetAssignedPlant(tile_tag, slot_index)
  else
    return self.classified ~= nil and self.classified:GetAssignedPlant(tile_tag, slot_index) or nil
  end
end

---Sets the tile's slot's assigned plant
---@param tile_tag string
---@param slot_index number
---@param plant string
function FarmBlueprint:SetAssignedPlant(tile_tag, slot_index, plant)
  if component(self) then
    component(self):SetAssignedPlant(tile_tag, slot_index, plant)
  elseif self.classified ~= nil then
    self.classified:SetAssignedPlant(tile_tag, slot_index, plant)
  end
end

---Gets the registered tile by its world coordinates
---@param x number
---@param y number
---@param z number
---@return FarmTile?
function FarmBlueprint:GetRegisteredFarmTileAtPoint(x, y, z)
  if component(self) then
    return component(self):GetRegisteredFarmTileAtPoint(x, y, z)
  else
    return self.classified ~= nil and self.classified:GetRegisteredFarmTileAtPoint(x, y, z) or nil
  end
end

---Checks if tile is registered
---@param x_or_tag number | string
---@param y number
---@param z number
---@return boolean
function FarmBlueprint:IsRegisteredFarmTile(x_or_tag, y, z)
  if component(self) then
    return component(self):IsRegisteredFarmTile(x_or_tag, y, z)
  else
    return self.classified ~= nil and self.classified:IsRegisteredFarmTile(x_or_tag, y, z) or false
  end
end

---Gets all unregistered tiles connected to the blueprint's registered tiles
---@return { [string]: FarmTile }
function FarmBlueprint:GetUnregisteredConnectedTiles()
  if component(self) then
    return component(self):GetUnregisteredConnectedTiles()
  else
    return self.classified ~= nil and self.classified:GetUnregisteredConnectedTiles() or {}
  end
end

return FarmBlueprint

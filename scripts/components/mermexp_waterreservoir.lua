local function on_maxlevel(self, maxlevel)
  self.inst.replica.mermexp_waterreservoir:SetMaxLevel(maxlevel)
end

local function on_level(self, level)
  self.inst.replica.mermexp_waterreservoir:SetLevel(level)
end

local WaterReservoir = Class(function(self, inst)
    self.inst = inst
    self.maxlevel = math.huge
    self.level = 0
  end,
  nil,
  {
    maxlevel = on_maxlevel,
    level = on_level,
  }
)

function WaterReservoir:SetLevel(level)
  self.level = level
end

function WaterReservoir:Level()
  return self.level
end

function WaterReservoir:SetMaxLevel(maxlevel)
  self.maxlevel = maxlevel
end

function WaterReservoir:MaxLevel()
  return self.maxlevel
end

function WaterReservoir:AddWater(_, wateringcan)
  local wateringcan_remaining_uses = wateringcan.components.finiteuses:GetUses()
  local wateringcan_water_per_use = wateringcan.components.wateryprotection.addwetness
  local wateringcan_waterlevel = wateringcan_remaining_uses * wateringcan_water_per_use
  local remaining_space = self.maxlevel - self.level

  if remaining_space == 0 or wateringcan_remaining_uses == 0 then return false end

  local added_amount = math.min(remaining_space, wateringcan_waterlevel)
  self.level = self.level + added_amount

  local uses = math.min(remaining_space / wateringcan_water_per_use, wateringcan_remaining_uses)
  wateringcan.components.finiteuses:Use(uses)

  return true
end

function WaterReservoir:FillCan(_, wateringcan)
  local wateringcan_total_uses = wateringcan.components.finiteuses.total
  local wateringcan_remaining_uses = wateringcan.components.finiteuses:GetUses()
  local wateringcan_water_per_use = wateringcan.components.wateryprotection.addwetness

  if wateringcan_remaining_uses == wateringcan_total_uses or self.level < wateringcan_water_per_use then
    return false
  end

  local uses_in_container = self.level / wateringcan_water_per_use
  local uses_to_fill = math.min(wateringcan_total_uses - wateringcan_remaining_uses, uses_in_container)

  wateringcan.components.finiteuses:SetUses(wateringcan_remaining_uses + uses_to_fill)
  self.level = self.level - uses_to_fill * wateringcan_water_per_use

  return true
end

function WaterReservoir:OnSave()
  return { maxlevel = self.maxlevel, level = self.level }
end

function WaterReservoir:OnLoad(data)
  if data.maxlevel then self.maxlevel = data.maxlevel end
  if data.level then self.level = data.level end
end

return WaterReservoir

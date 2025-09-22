local WaterReservoir = Class(function(self, inst)
  self.inst = inst
  self.maxlevel = net_ushortint(inst.GUID, "mxp.waterreservoir.maxlevel", "mxp.waterreservoir.maxleveldirty")
  self.level = net_ushortint(inst.GUID, "mxp.waterreservoir.level", "mxp.waterreservoir.leveldirty")
end)

function WaterReservoir:SetLevel(level)
  if self.inst.components.mermexp_waterreservoir then
    self.level:set(level)
  end
end

function WaterReservoir:Level()
  return self.level:value()
end

function WaterReservoir:SetMaxLevel(maxlevel)
  if self.inst.components.mermexp_waterreservoir then
    self.maxlevel:set(maxlevel)
  end
end

function WaterReservoir:MaxLevel()
  return self.maxlevel:value()
end

return WaterReservoir

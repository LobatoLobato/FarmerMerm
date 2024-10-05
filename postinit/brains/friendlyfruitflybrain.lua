local CONSTANTS = require "mermexp.constants"

local function ValidPlant(inst, plant)
  local fruit = inst.components.follower.leader
  local container = fruit.components.inventoryitem:GetContainer()

  if container == nil or not container.inst:HasTag("mermhouse_farmer") or container:GetFarmBlueprint() == nil then
    return true
  end

  local farmblueprint = container:GetFarmBlueprint()

  local px, _, pz = plant.Transform:GetWorldPosition()
  local assigned_plant = farmblueprint.components.mermexp_mermfarmblueprint:GetAssignedPlantAt(px, pz)
  local is_weed_seed = CONSTANTS.WEEDS:Has(assigned_plant.name) and plant.prefab:find("randomseed")

  return assigned_plant == nil or not is_weed_seed
end

AddBrainPostInit("friendlyfruitflybrain", function(self)
  for _, child in ipairs(self.bt.root.children) do
    if child.name == "FindFarmPlant" then
      child.validplantfn = ValidPlant
    end
  end
end)

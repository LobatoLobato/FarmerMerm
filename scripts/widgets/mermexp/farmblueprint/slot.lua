local UI_ICONS_ATLAS = require "mermexp.constants".UI_ICONS_ATLAS
local Widget = require "widgets.widget"
local ImageButton = require "widgets.imagebutton"
local FarmBlueprintSeed = require "widgets.mermexp.farmblueprint.seed"

local FarmBlueprintSlot = Class(ImageButton, function(self, root, blueprint, tileid, index, width, height, x, y)
  Widget._ctor(self, "Farm Blueprint Slot")
  ImageButton._ctor(self, UI_ICONS_ATLAS, "empty_slot.tex", nil, nil, nil, nil, { 1, 1 }, { 0, 0 })

  self.root = root
  self.index = index
  self.tileid = tileid
  self.blueprint = blueprint

  self:ForceImageSize(width, height)
  local sx, sy, sz = self.image:GetScale():Get()

  self:SetPosition(x, y)
  self:SetNormalScale(sx, sy, sz)
  self:SetFocusScale(sx * 1.2, sy * 1.2, sz * 1.2)
  self:SetImageNormalColour(0.49, 0.318, 0.047, 0.6)

  local assigned_plant = blueprint:GetAssignedPlant(tileid, index)
  if assigned_plant ~= nil then
    self.planted_seeds = self:AddChild(FarmBlueprintSeed(assigned_plant.name, -TheCamera:GetHeadingTarget() + 90))
  end
end)

function FarmBlueprintSlot:AddSeeds()
  if self.planted_seeds ~= nil then self.planted_seeds:Kill() end
  self.planted_seeds = self:AddChild(FarmBlueprintSeed(self.root.carried_seeds.id, -TheCamera:GetHeadingTarget() + 90))
  self.blueprint:SetAssignedPlant(self.tileid, self.index, self.planted_seeds.id)
end

function FarmBlueprintSlot:RemoveSeeds()
  if self.planted_seeds ~= nil then self.planted_seeds:Kill() end
  self.planted_seeds = nil
  self.blueprint:SetAssignedPlant(self.tileid, self.index, nil)
end

function FarmBlueprintSlot:OnGainFocus()
  if self.root.painting and self.root.carried_seeds ~= nil then
    self:AddSeeds()
  elseif self.root.erasing and self.planted_seeds ~= nil then
    self:RemoveSeeds()
  end
  return self._base.OnGainFocus(self)
end

function FarmBlueprintSlot:OnMouseButton(button, down, x, y)
  local isleftdown, isrightdown = button == MOUSEBUTTON_LEFT and down, button == MOUSEBUTTON_RIGHT and down

  if isleftdown then self:AddSeeds() end
  if isrightdown then self:RemoveSeeds() end

  return self._base.OnMouseButton(self, button, down, x, y)
end

function FarmBlueprintSlot:OnRotate(angle)
  if self.planted_seeds ~= nil then
    self.planted_seeds:Rotate(-angle + 90)
  end
end

return FarmBlueprintSlot

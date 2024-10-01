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

function FarmBlueprintSlot:OnControl(control, down)
  local root = self.root
  local is_carrying_seed, has_planted_seeds = root.carried_seeds ~= nil, self.planted_seeds ~= nil
  local isleftup, isrightup = control == CONTROL_ACCEPT and not down, control == CONTROL_SECONDARY and not down

  if isleftup and is_carrying_seed then
    if self.planted_seeds ~= nil then self.planted_seeds:Kill() end

    self.planted_seeds = self:AddChild(FarmBlueprintSeed(root.carried_seeds.id, -TheCamera:GetHeadingTarget() + 90))

    self.blueprint:SetAssignedPlant(self.tileid, self.index, self.planted_seeds.id)
  end
  if isrightup and has_planted_seeds and not (self.dragged or self.dragging) then
    self.planted_seeds:Kill()
    self.planted_seeds = nil
    self.blueprint:SetAssignedPlant(self.tileid, self.index, nil)
  end

  return self._base.OnControl(self, control, down)
end

function FarmBlueprintSlot:OnRotate(angle)
  if self.planted_seeds ~= nil then
    self.planted_seeds:Rotate(-angle + 90)
  end
end

return FarmBlueprintSlot

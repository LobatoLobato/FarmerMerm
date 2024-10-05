local UI_HUD_ATLAS = require "mermexp.constants".UI_HUD_ATLAS
local Widget = require "widgets.widget"
local Image = require "widgets.image"
local FarmBlueprintSlot = require "widgets.mermexp.farmblueprint.slot"

local FarmBlueprintTile = Class(Image, function(self, root, blueprint, id, world_pos, width, height, x, y)
  Widget._ctor(self, "Farm Blueprint Tile")
  Image._ctor(self, UI_HUD_ATLAS, "blueprinttile.tex")

  self.root = root
  self.id = id
  self.blueprint = blueprint
  self.world_pos = world_pos
  self.w, self.h = width, height

  self:SetSize(width, height)
  self:SetPosition(x, y)

  if blueprint:IsRegisteredFarmTile(id) then
    self:DrawSlots()
  end
end)

function FarmBlueprintTile:DrawSlots()
  local frame_margin_w, frame_margin_h = self.w / 6, self.h / 6
  local slot_margin_w, slot_margin_h = self.w / 10, self.h / 10
  local slot_w, slot_h = (self.w - slot_margin_w - frame_margin_w) / 3, (self.h - slot_margin_h - frame_margin_h) / 3

  local slot_index = 0
  for y = 0, 2, 1 do
    for x = 0, 2, 1 do
      local pos_x = (slot_margin_w / 4) * (x + 1) + slot_w * x - (self.w / 2) + (slot_w / 2) + frame_margin_w / 2
      local pos_y = (slot_margin_h / 4) * (y + 1) + slot_h * y - (self.h / 2) + (slot_h / 2) + frame_margin_h / 2
      slot_index = slot_index + 1

      self:AddChild(FarmBlueprintSlot(self.root, self.blueprint, self.id, slot_index, slot_w, slot_h, pos_x, pos_y))
    end
  end
end

function FarmBlueprintTile:OnMouseButton(button, down, x, y)
  if TheInput:IsKeyDown(KEY_CTRL) and down then
    if button == MOUSEBUTTON_LEFT and not self.blueprint:IsRegisteredFarmTile(self.id) then
      self.blueprint:RegisterFarmTile(self.world_pos:Get())
      self:DrawSlots()
    else
      self:KillAllChildren()
      self.blueprint:UnregisterFarmTile(self.id)
    end
  end

  return self._base.OnMouseButton(self, button, down, x, y)
end

function FarmBlueprintTile:OnRotate(angle)
  for _, slot in pairs(self:GetChildren()) do slot:OnRotate(angle) end
end

return FarmBlueprintTile

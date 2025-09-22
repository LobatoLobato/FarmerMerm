local UI_ICONS_ATLAS = require "mermexp.constants".UI_ICONS_ATLAS
local Widget = require "widgets.widget"

local FarmBlueprintSeed = Class(Widget, function(self, seed, rotation)
  Widget._ctor(self, "Farm Blueprint Seed")

  self.image = self:AddChild(Image(UI_ICONS_ATLAS, seed .. ".tex"))
  self.id = seed

  self.image:SetScale(0.5, 0.5)
  self.image:SetClickable(false)
  if rotation ~= nil then self:Rotate(rotation) end
end)

function FarmBlueprintSeed:Rotate(angle)
  local from, to = self.rotation, angle
  if from == nil then
    self.image:SetRotation(to)
  else
    if from < 0 then from = 360 + from end
    if to < 0 then to = 360 + to end
    if from == 315 and to == 0 then to = 360 end
    if from == 0 and to == 45 then from = 0 end
    if from == 0 and to == 315 then from = 360 end

    self.image:SetRotation(from)
    self.image:RotateTo(from, to, 0.5)
  end
  self.rotation = angle
end

local function ScreenPosToWidgetPos(x, y)
  local w, h = TheSim:GetScreenSize()
  return x / w * RESOLUTION_X - RESOLUTION_X / 2, y / h * RESOLUTION_Y - RESOLUTION_Y / 2
end

function FarmBlueprintSeed:FollowMouse()
  if self.followhandler == nil then
    self.followhandler = TheInput:AddMoveHandler(function(x, y)
      self.image:UpdatePosition(ScreenPosToWidgetPos(x, y))
    end)
    self.image:SetPosition(ScreenPosToWidgetPos(TheInput:GetScreenPosition():Get()))
  end
end

function FarmBlueprintSeed:StopFollowMouse()
  if self.followhandler ~= nil then
    self.followhandler:Remove()
    self.followhandler = nil
  end
end

return FarmBlueprintSeed

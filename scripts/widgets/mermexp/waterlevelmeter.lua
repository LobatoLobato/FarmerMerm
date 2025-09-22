local MoistureMeter = require "widgets.moisturemeter"

local WaterLevelMeter = Class(MoistureMeter, function(self)
  MoistureMeter._ctor(self)
  self:SetVAnchor(ANCHOR_MIDDLE)
  self:SetHAnchor(ANCHOR_MIDDLE)

  self.backing:SetScale(2, 2)
  self.backing:SetPosition(0, 25)

  self.anim:GetAnimState():SetScale(8, 8)
  self.anim:SetPosition(0, 25)

  self.circleframe:SetScale(2, 2)
  self.circleframe:SetPosition(0, 25)

  self.arrow:SetScale(2, 2)
  self.arrow:SetPosition(0, 25)
end)

function WaterLevelMeter:SetPosition(x, y, z)
  WaterLevelMeter._base.SetPosition(self, x, y - 25, z)
end

function WaterLevelMeter:OnUpdate(dt)
  if TheNet:IsServerPaused() then return end

  local curframe = self.circleframe:GetAnimState():GetCurrentAnimationFrame()
  if curframe < 1 then
    self.anim:SetScale(.955 * 2, .096 * 2, 1)
  elseif curframe < 2 then
    self.anim:SetScale(.977 * 2, .333 * 2, 1)
  elseif curframe < 3 then
    self.anim:SetScale(1.044 * 2, 1.044 * 2, 1)
  elseif curframe < 4 then
    self.anim:SetScale(1.019 * 2, 1.019 * 2, 1)
  elseif curframe < 5 then
    self.anim:SetScale(1.005 * 2, 1.005 * 2, 1)
  else
    self.anim:SetScale(2, 2, 1)
    self:StopUpdating()
  end
end

return WaterLevelMeter

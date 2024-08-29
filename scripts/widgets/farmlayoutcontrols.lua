local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local PauseScreen = require "screens/redux/pausescreen"

local function OnRotLeft()
    ThePlayer.components.playercontroller:RotLeft()
end

local function OnRotRight()
    ThePlayer.components.playercontroller:RotRight()
end

--base class for imagebuttons and animbuttons.
local FarmLayoutControls = Class(Widget, function(self)
    Widget._ctor(self, "Map Controls")

    -- add clear button
    -- add remove tile button
    -- add seed buttons

    self.rotleft = self:AddChild(ImageButton(HUD_ATLAS, "turnarrow_icon.tex", nil, nil, nil, nil, { 1, 1 }, { 0, 0 }))
    self.rotleft:SetPosition(-40, -40, 0)
    self.rotleft:SetScale(-.7, .7, .7)
    self.rotleft:SetOnClick(OnRotLeft)

    self.rotright = self:AddChild(ImageButton(HUD_ATLAS, "turnarrow_icon.tex", nil, nil, nil, nil, { 1, 1 }, { 0, 0 }))
    self.rotright:SetPosition(40, -40, 0)
    self.rotright:SetScale(.7, .7, .7)
    self.rotright:SetOnClick(OnRotRight)

    self:RefreshTooltips()
end)

function FarmLayoutControls:RefreshTooltips()
    local controller_id = TheInput:GetControllerID()
    self.rotleft:SetTooltip(STRINGS.UI.HUD.ROTLEFT ..
        "(" .. tostring(TheInput:GetLocalizedControl(controller_id, CONTROL_ROTATE_LEFT)) .. ")")
    self.rotright:SetTooltip(STRINGS.UI.HUD.ROTRIGHT ..
        "(" .. tostring(TheInput:GetLocalizedControl(controller_id, CONTROL_ROTATE_RIGHT)) .. ")")
end

return FarmLayoutControls

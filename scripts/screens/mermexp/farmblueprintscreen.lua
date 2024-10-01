local UI_HUD_ATLAS = require "mermexp.constants".UI_HUD_ATLAS
local Screen = require "widgets.screen"
local Image = require "widgets.image"
local Widget = require "widgets.widget"
local Menu = require "widgets.menu"
local FarmBlueprint = {
    Controls = require "widgets.mermexp.farmblueprint.controls",
    Canvas = require "widgets.mermexp.farmblueprint.canvas",
    Seed = require "widgets.mermexp.farmblueprint.seed"
}

local FarmBlueprintScreen = Class(Screen, function(self, blueprint)
    Screen._ctor(self, "Farm Blueprint Screen")

    self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black:SetTint(0, 0, 0, .75)

    self.root = self:AddChild(Widget("ROOT"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetPosition(0, 0, 0)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    local window_width, window_height = 1024, 600
    self.window = self.root:AddChild(Image(UI_HUD_ATLAS, "blueprintframe.tex"))
    self.window:SetSize(window_width, window_height)

    self.canvas = self.window:AddChild(FarmBlueprint.Canvas(self.root, blueprint, window_width, window_height))
    self.canvas:MoveToBack()

    self.controls = self.window:AddChild(FarmBlueprint.Controls(self.root))
    self.controls.onrotate = function(angle) self.canvas:Rotate(angle) end

    self.buttons = {
        { text = "X", cb = function() TheFrontEnd:PopScreen() end }
    }

    self.menu = self.root:AddChild(Menu(self.buttons, 0, true))
    self.menu:SetPosition(400, 300, 0)
    self.default_focus = self.menu
end)

function FarmBlueprintScreen:OnUpdate(dt)
    self.controls:OnUpdate()
    if self.timeout then
        self.timeout.timeout = self.timeout.timeout - dt
        if self.timeout.timeout <= 0 then
            self.timeout.cb()
        end
    end
    return true
end

function FarmBlueprintScreen:OnControl(control, down)
    if control == CONTROL_SECONDARY and not down then
        self.canvas:StopDrag()
    end

    if FarmBlueprintScreen._base.OnControl(self, control, down) then
        return true
    end
end

function FarmBlueprintScreen:OnRawKey(key, down)
    if not down then return end

    if key == KEY_ESCAPE then
        if self.root.carried_seeds ~= nil then
            self.root.carried_seeds:Kill()
            self.root.carried_seeds = nil
            return true
        else
            TheFrontEnd:PopScreen()
            return false
        end
    elseif key == KEY_E then
        ThePlayer.components.playercontroller:RotRight()
        return true
    elseif key == KEY_Q then
        ThePlayer.components.playercontroller:RotLeft()
        return true
    end
end

return FarmBlueprintScreen

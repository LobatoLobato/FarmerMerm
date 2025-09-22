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

    SetAutopaused(true)
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

function FarmBlueprintScreen:OnMouseButton(button, down, x, y)
    self.canvas:OnMouseButton(button, down, x, y)
    return self._base.OnMouseButton(self, button, down, x, y)
end

function FarmBlueprintScreen:OnControl(control, down)
    if (control == CONTROL_MENU_BACK or control == CONTROL_CANCEL) then
        if self.root.carried_seeds ~= nil and down then
            self.root.carried_seeds:Kill()
        elseif self.root.carried_seeds == nil and not down then
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
            TheFrontEnd:PopScreen()
        elseif not down then
            self.root.carried_seeds = nil
        end

        return true
    end

    if FarmBlueprintScreen._base.OnControl(self, control, down) then
        return true
    end
end

function FarmBlueprintScreen:OnDestroy()
    SetAutopaused(false)

    POPUPS.MERMEXP_MERMFARMBLUEPRINT:Close(ThePlayer)

    FarmBlueprintScreen._base.OnDestroy(self)
end

function FarmBlueprintScreen:OnRawKey(key, down)
    if not down then return end

    if key == KEY_E then
        ThePlayer.components.playercontroller:RotRight()
        return true
    elseif key == KEY_Q then
        ThePlayer.components.playercontroller:RotLeft()
        return true
    end
end

return FarmBlueprintScreen

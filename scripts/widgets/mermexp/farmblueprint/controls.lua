local Widget = require "widgets.widget"
local Menu = require "widgets.menu"
local ImageButton = require "widgets.imagebutton"
local Seeds = require "widgets.mermexp.farmblueprint.seed"

local CONSTANTS = require "mermexp.constants"

local POS_Y_1 = 272
local POS_Y_2 = -272

local SEED_BUTTON_WIDTH, SEED_SPACE_BETWEEN = 22, 18

local FarmBlueprintControls = Class(Widget, function(self, root)
    Widget._ctor(self, "Farm Blueprint Controls")
    self.root = root

    self:AddSeedBar()
    self:AddRotationControls()
    self:AddCloseButton()
    self:AddClearButton()

    self:RefreshTooltips()

    self.rotation = TheCamera:GetHeadingTarget()
end)

function FarmBlueprintControls:OnUpdate()
    local current_rotation = TheCamera:GetHeadingTarget()
    if self.rotation ~= current_rotation then
        if self.onrotate then self.onrotate(current_rotation) end
        self.rotation = current_rotation
    end
end

function FarmBlueprintControls:OnRotateLeft()
    ThePlayer.components.playercontroller:RotLeft()
end

function FarmBlueprintControls:OnRotateRight()
    ThePlayer.components.playercontroller:RotRight()
end

function FarmBlueprintControls:RefreshTooltips()
    local controller_id = TheInput:GetControllerID()
    self.rotleft:SetTooltip(STRINGS.UI.HUD.ROTLEFT ..
        "(" .. tostring(TheInput:GetLocalizedControl(controller_id, CONTROL_ROTATE_LEFT)) .. ")")
    self.rotright:SetTooltip(STRINGS.UI.HUD.ROTRIGHT ..
        "(" .. tostring(TheInput:GetLocalizedControl(controller_id, CONTROL_ROTATE_RIGHT)) .. ")")
end

function FarmBlueprintControls:AddSeedBar()
    local spacing = SEED_BUTTON_WIDTH + SEED_SPACE_BETWEEN

    local seed_buttons = {}
    for _, plantable in ipairs(CONSTANTS.PLANTABLES) do
        if plantable.name ~= "seeds" then
            local button = ImageButton(CONSTANTS.UI_ICONS_ATLAS, plantable.name .. "_slot.tex",
                nil, nil, nil, nil, { 1, 1 }, { 0, 0 }
            )

            button:SetScale(SEED_BUTTON_WIDTH / 48, SEED_BUTTON_WIDTH / 48)

            button.onclick = function()
                if self.root.carried_seeds ~= nil then
                    self.root.carried_seeds:Kill()
                end

                if self.root.carried_seeds == nil or self.root.carried_seeds.id ~= plantable.name then
                    self.root.carried_seeds = self.root:AddChild(Seeds(plantable.name))
                    self.root.carried_seeds:FollowMouse()
                else
                    self.root.carried_seeds = nil
                end
            end

            table.insert(seed_buttons, { widget = button })
        end
    end

    self.seedbar = self:AddChild(Menu(seed_buttons, spacing, true))
    self.seedbar:SetPosition(-(spacing * (#seed_buttons - 1)) / 2, POS_Y_2)
end

function FarmBlueprintControls:AddRotationControls()
    local rot_pos_x, rot_pos_y = 1024 / 2 - 100, POS_Y_2
    self.rotleft = self:AddChild(ImageButton(HUD_ATLAS, "turnarrow_icon.tex", nil, nil, nil, nil, { 1, 1 }, { 0, 0 }))
    self.rotleft:SetPosition(rot_pos_x - 30, rot_pos_y, 0)
    self.rotleft:SetScale(-.7, .4, .4)
    self.rotleft:SetOnClick(function() self:OnRotateLeft() end)

    self.rotright = self:AddChild(ImageButton(HUD_ATLAS, "turnarrow_icon.tex", nil, nil, nil, nil, { 1, 1 }, { 0, 0 }))
    self.rotright:SetPosition(rot_pos_x + 30, rot_pos_y, 0)
    self.rotright:SetScale(.7, .4, .4)
    self.rotright:SetOnClick(function() self:OnRotateRight() end)
end

function FarmBlueprintControls:AddCloseButton()
    self.closebtn = self:AddChild(ImageButton(CONSTANTS.UI_HUD_ATLAS, "close_button.tex", nil, nil, nil, nil,
        { 1, 1 },
        { 0, 0 }
    ))
    self.closebtn:SetPosition(496, POS_Y_1)
    self.closebtn:SetScale(.5, .5, .5)
    self.closebtn:SetOnClick(function() TheFrontEnd:PopScreen() end)
end

function FarmBlueprintControls:AddClearButton()
    self.clearbtn = self:AddChild(ImageButton(CONSTANTS.UI_HUD_ATLAS, "clear_button.tex", nil, nil, nil, nil,
        { 1, 1 },
        { 0, 0 }
    ))
    self.clearbtn:SetPosition(-412, POS_Y_2)
    self.clearbtn:SetScale(.5, .5, .5)
    self.clearbtn:SetOnClick(function() self.root:GetParent().canvas:ClearTiles() end)
end

return FarmBlueprintControls

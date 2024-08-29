-- Don't use this on new screens! Use PopupDialogScreen with big longness
-- instead.
local Screen = require "widgets/screen"
local Button = require "widgets/button"
local AnimButton = require "widgets/animbutton"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local Menu = require "widgets/menu"
local TEMPLATES = require "widgets/templates"
local FarmLayoutControls = require "widgets/farmlayoutcontrols"

local BigPopupDialogScreen = Class(Screen, function(self, title, text, buttons, tiles, timeout)
    Screen._ctor(self, "BigPopupDialogScreen")

    --darken everything behind the dialog
    self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black:SetTint(0, 0, 0, .75)

    self.proot = self:AddChild(Widget("ROOT"))
    self.proot:SetVAnchor(ANCHOR_MIDDLE)
    self.proot:SetHAnchor(ANCHOR_MIDDLE)
    self.proot:SetPosition(0, 0, 0)
    self.proot:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.panel = self.proot:AddChild(TEMPLATES.CenterPanel(nil, nil, true))
    self.window = self.panel.bg
    local window_w, window_h = self.window:GetSize()

    local function normalize_tiles(tiles)
        local x_limits = { min = math.huge, max = -math.huge }
        local y_limits = { min = math.huge, max = -math.huge }


        for _, tile in pairs(tiles) do
            x_limits.min = math.min(tile.x, x_limits.min)
            y_limits.min = math.min(tile.z, y_limits.min)

            x_limits.max = math.max(tile.x, x_limits.max)
            y_limits.max = math.max(tile.z, y_limits.max)
        end

        local normalized_tiles = {}
        for _, tile in pairs(tiles) do
            local normalized_tile = { x = (tile.x - x_limits.min) / 4, y = (tile.z - y_limits.min) / 4 }

            table.insert(normalized_tiles, normalized_tile)
        end

        x_limits = { min = 0, max = (x_limits.max - x_limits.min) / 4 }
        y_limits = { min = 0, max = (y_limits.max - y_limits.min) / 4 }

        return normalized_tiles, x_limits, y_limits
    end

    local function Tile(tile_w, tile_h, tile_x, tile_y)
        tile_w = tile_w or 160; tile_h = tile_h or 160; tile_x = tile_x or 0; tile_y = tile_y or 0
        -- local tile = Widget("ftile")

        local tile = Image("images/farm_soil.xml", "farm_soil.tex") -- Image("images/farm_soil.xml", "farm_soil.tex")
        tile:SetSize(tile_w or 160, tile_h or 160)
        tile:SetPosition(tile_x or 0, tile_y or 0)
        -- tile:SetTint(0.49, 0.318, 0.047, 1)

        local slot_margin_w = tile_w / 10
        local slot_margin_h = tile_h / 10
        local slot_w = (tile_w - slot_margin_w) / 3
        local slot_h = (tile_h - slot_margin_h) / 3
        for x = 0, 2, 1 do
            for y = 0, 2, 1 do
                local slot = tile:AddChild(Image("images/empty_slot.xml", "empty_slot.tex"))
                local pos_x = (slot_margin_w / 4) * (x + 1) + slot_w * x - (tile_w / 2) + (slot_w / 2)
                local pos_y = (slot_margin_h / 4) * (y + 1) + slot_h * y - (tile_h / 2) + (slot_h / 2)

                slot:SetSize(slot_w, slot_h)
                slot:SetPosition(pos_x, pos_y)
                slot:SetTint(1, 1, 1, 0.5)
                -- slot:SetTint(0.49, 0.318, 0.047, 0.3)
            end
        end

        return tile
    end

    self.tiles = self.window:AddChild(Widget("registered_farm_tiles"))
    if tiles ~= nil then
        local normalized_tiles, x_limits, y_limits = normalize_tiles(tiles)
        local tile_size = 128

        for _, tile_coords in ipairs(normalized_tiles) do
            local pos_x = -((tile_coords.x - (x_limits.max / 2)) * tile_size)
            local pos_y = -((tile_coords.y - (y_limits.max / 2)) * tile_size)

            self.tiles:AddChild(Tile(tile_size, tile_size, pos_x, pos_y))
        end
    end
    self.mapcontrols = self.window:AddChild(FarmLayoutControls())
    self.mapcontrols:SetPosition(window_w / 2 - 80, -(window_h / 2) + 80)

    self.window:SetScissor(-(window_w / 2), -(window_h / 2), window_w, window_h)

    self.old_rotation = nil

    -- function Widget:SetScissor(x, y, w, h)
    --     self.inst.UITransform:SetScissor(x, y, w, h)
    -- end

    -- --title
    -- self.title = self.proot:AddChild(Text(BUTTONFONT, 50))
    -- self.title:SetPosition(0, 135, 0)
    -- self.title:SetString(title)
    -- self.title:SetColour(0, 0, 0, 1)

    -- --text
    -- if JapaneseOnPS4() then
    --     self.text = self.proot:AddChild(Text(NEWFONT, 28))
    -- else
    --     self.text = self.proot:AddChild(Text(NEWFONT, 30))
    -- end

    -- self.text:SetPosition(0, 5, 0)
    -- self.text:SetString(text)
    -- self.text:EnableWordWrap(true)
    -- if JapaneseOnPS4() then
    --     self.text:SetRegionSize(500, 300)
    -- else
    --     self.text:SetRegionSize(500, 200)
    -- end
    -- self.text:SetColour(0, 0, 0, 1)

    --create the menu itself
    local button_w = 200
    local space_between = 20
    local spacing = button_w + space_between

    self.menu = self.proot:AddChild(Menu(buttons, spacing, true))
    self.menu:SetPosition(-(spacing * (#buttons - 1)) / 2, -300, 0)
    self.buttons = buttons
    self.default_focus = self.menu
end)



function BigPopupDialogScreen:OnUpdate(dt)
    local current_rotation = TheCamera:GetHeadingTarget()
    if (self.old_rotation ~= TheCamera:GetHeadingTarget()) then
        self.tiles:SetRotation(current_rotation - 90)
        self.old_rotation = current_rotation
        print("me caguei")
    end
    if self.timeout then
        self.timeout.timeout = self.timeout.timeout - dt
        if self.timeout.timeout <= 0 then
            self.timeout.cb()
        end
    end
    return true
end

function BigPopupDialogScreen:OnControl(control, down)
    if BigPopupDialogScreen._base.OnControl(self, control, down) then
        return true
    end
end

return BigPopupDialogScreen

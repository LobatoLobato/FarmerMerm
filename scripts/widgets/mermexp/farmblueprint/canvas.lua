local UI_HUD_ATLAS = require "mermexp.constants".UI_HUD_ATLAS
local Widget = require "widgets.widget"
local Image = require "widgets.image"
local FarmBlueprintTile = require "widgets.mermexp.farmblueprint.tile"
local TILE_SIZE = 200

local FarmBlueprintCanvas = Class(Image, function(self, root, blueprint, width, height)
  Widget._ctor(self, "Farm Blueprint Canvas")
  Image._ctor(self, UI_HUD_ATLAS, "blueprintbg.tex")

  self.root = root
  self.blueprint = blueprint.replica.mermexp_mermfarmblueprint

  self:SetScaleMode(SCALEMODE_PROPORTIONAL)
  self:SetVAnchor(ANCHOR_MIDDLE)
  self:SetHAnchor(ANCHOR_MIDDLE)
  self:SetSize(width, height)
  self:SetScissor(-((width - 20) / 2), -((height - 40) / 2), width - 20, height - 40)

  self:DrawTiles(self.blueprint)

  self:Rotate(TheCamera:GetHeadingTarget())

  self.dragging = false
end)


local function NormalizeTiles(tiles)
  local x_limits = { min = math.huge, max = -math.huge }
  local y_limits = { min = math.huge, max = -math.huge }


  for _, tile in pairs(tiles) do
    x_limits.min = math.min(tile.x, x_limits.min)
    y_limits.min = math.min(tile.z, y_limits.min)

    x_limits.max = math.max(tile.x, x_limits.max)
    y_limits.max = math.max(tile.z, y_limits.max)
  end

  local normalized_tiles = {}
  for id, tile in pairs(tiles) do
    table.insert(normalized_tiles, {
      id = id,
      world_pos = { x = tile.x, y = tile.y, z = tile.z },
      x = (tile.x - x_limits.min) / 4,
      y = (tile.z - y_limits.min) / 4,
    })
  end

  x_limits = { min = 0, max = (x_limits.max - x_limits.min) / 4 }
  y_limits = { min = 0, max = (y_limits.max - y_limits.min) / 4 }

  return normalized_tiles, x_limits, y_limits
end

function FarmBlueprintCanvas:DrawTiles(blueprint)
  local tiles = blueprint:GetUnregisteredConnectedTiles()
  local normalized_tiles, x_limits, y_limits = NormalizeTiles(tiles)

  self.tiles = self:AddChild(Widget("FarmBlueprintTiles"))
  self.tiles:SetVAnchor(ANCHOR_MIDDLE)
  self.tiles:SetHAnchor(ANCHOR_MIDDLE)

  function self.tiles:GetRotatedSize()
    local w, h = (x_limits.max + 1) * TILE_SIZE, (y_limits.max + 1) * TILE_SIZE
    local angle = -self:GetRotation() * math.pi / 180
    local px1, py1 = VecUtil_RotateAroundPoint(w / 2, h / 2, 0, 0, angle)
    local px2, py2 = VecUtil_RotateAroundPoint(w / 2, h / 2, 0, h, angle)
    local px3, py3 = VecUtil_RotateAroundPoint(w / 2, h / 2, w, h, angle)
    local px4, py4 = VecUtil_RotateAroundPoint(w / 2, h / 2, w, 0, angle)

    return math.max(px1, px2, px3, px4) - math.min(px1, px2, px3, px4),
        math.max(py1, py2, py3, py4) - math.min(py1, py2, py3, py4)
  end

  for _, tile in ipairs(normalized_tiles) do
    local pos_x = -((tile.x - (x_limits.max / 2)) * TILE_SIZE)
    local pos_y = -((tile.y - (y_limits.max / 2)) * TILE_SIZE)

    local tile = FarmBlueprintTile(self.root, self.blueprint, tile.id, tile.world_pos, TILE_SIZE, TILE_SIZE, pos_x, pos_y)
    self.tiles:AddChild(tile)
  end
end

function FarmBlueprintCanvas:StartDrag()
  if self.followhandler == nil then
    local function diff(a, b) return math.max(a, b) - math.min(a, b) end
    local p_t, p_b, p_x = 80, 120, 120 -- Padding

    local window_w, window_h = self:GetScaledSize()
    local cursor_drag_origin = TheInput:GetScreenPosition()

    local tiles_w, tiles_h = self.tiles:GetRotatedSize()
    local tile_drag_origin = self.tiles:GetPosition()

    self.dragged = false

    self.followhandler = TheInput:AddMoveHandler(function(x, y)
      local pos_x = tile_drag_origin.x + (x - cursor_drag_origin.x)
      local pos_y = tile_drag_origin.y + (y - cursor_drag_origin.y)

      local diff_w, diff_h = diff(window_w, tiles_w), diff(window_h, tiles_h)
      local remaining_w = diff_w + ((tiles_w >= window_w) and (p_x) or (-p_x))
      local remaining_h_top = diff_h + ((tiles_h >= window_h - p_t) and (p_t * 2) or (-p_t))
      local remaining_h_bottom = diff_h + ((tiles_h >= window_h - p_b) and (p_b) or (-p_b * 2))

      pos_x = math.clamp(pos_x, -(remaining_w / 2), (remaining_w / 2))
      pos_y = math.clamp(pos_y, -(remaining_h_bottom / 2), (remaining_h_top / 2))

      self.tiles:UpdatePosition(pos_x, pos_y)

      local moved_x = pos_x > tile_drag_origin.x + 1 or pos_x < tile_drag_origin.x - 1
      local moved_y = pos_y > tile_drag_origin.y + 1 or pos_y < tile_drag_origin.y - 1

      self.dragged = moved_x or moved_y
    end)

    self.dragging = true
  end
end

function FarmBlueprintCanvas:StopDrag()
  if self.followhandler ~= nil then
    self.followhandler:Remove()
    self.followhandler = nil
    self.dragging = false
  end
end

function FarmBlueprintCanvas:OnControl(control, down)
  if control == CONTROL_SECONDARY and not self.dragging and down then
    self:StartDrag()
  elseif control == CONTROL_SECONDARY and self.dragging and not down then
    self:StopDrag()
  end

  return self._base.OnControl(self, control, down)
end

function FarmBlueprintCanvas:Rotate(angle)
  local from, to = self.rotation, angle - 90
  if from == nil then
    self.tiles:SetRotation(to)
  else
    if from < 0 then from = 360 + from end
    if to < 0 then to = 360 + to end
    if from == 315 and to == 0 then to = 360 end
    if from == 0 and to == 45 then from = 0 end
    if from == 0 and to == 315 then from = 360 end

    self.tiles:SetRotation(from)
    self.tiles:RotateTo(from, to, 0.5)
  end

  self.rotation = angle - 90
  for _, tile in pairs(self.tiles:GetChildren()) do tile:OnRotate(angle) end
end

function FarmBlueprintCanvas:GetRotation()
  return self.rotation
end

return FarmBlueprintCanvas

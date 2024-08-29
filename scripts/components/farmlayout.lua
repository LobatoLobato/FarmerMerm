local FarmLayout = Class(function(self, inst)
  self.inst = inst

  self.farm_tiles = {}
end)

local function MakeTileTag(tilept)
  local tcx, tcy, tcz = TheWorld.Map:GetTileCenterPoint(tilept.x, tilept.y, tilept.z)

  return tostring(tcx) .. tostring(tcy) .. tostring(tcz), { x = tcx, y = tcy, z = tcz }
end

function FarmLayout:RegisterFarmTile(tilept)
  local tiletag, tile_center = MakeTileTag(tilept)
  if self.farm_tiles[tiletag] ~= nil then return false end

  self.farm_tiles[tiletag] = tile_center

  return true
end

function FarmLayout:UnregisterFarmTile(tilept)
  local tiletag = MakeTileTag(tilept)

  if self.farm_tiles[tiletag] == nil then return false end

  self.farm_tiles[tiletag] = nil

  return true
end

function FarmLayout:GetRegisteredFarmTiles()
  return self.farm_tiles
end

function FarmLayout:IsRegisteredFarmTile(tilept)
  local tiletag = MakeTileTag(tilept)

  return self.farm_tiles[tiletag] ~= nil
end

function FarmLayout:OnSave()
  return { farm_tiles = self.farm_tiles }
end

function FarmLayout:OnLoad(data)
  if data.farm_tiles then
    self.farm_tiles = data.farm_tiles
  end
end

return FarmLayout

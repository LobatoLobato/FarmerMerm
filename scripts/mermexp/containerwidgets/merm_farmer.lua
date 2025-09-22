local PLANTABLES = require "mermexp.constants".PLANTABLES
local FarmerContainer = {
  widget = {
    pos = Vector3(0, 150, 0),
    side_align_tip = 160,
    bgimagetint = { r = .82, g = .77, b = .7, a = 1 },
    slotpos = {},
    slotbg = {}
  },
  canbeopened = false,
  ignoreoverstacked = true,
}

for _ = 1, 2, 1 do
  for _ in ipairs(PLANTABLES) do
    table.insert(FarmerContainer.widget.slotpos, Vector3(0, 0, 0))
  end
end

function FarmerContainer:Init()
  self:EnableInfiniteStackSize(true)
end

return require("mermexp.util").RegisterContainerParam(FarmerContainer, "merm_farmer")

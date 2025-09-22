local FERTILIZER_DEFS = require("prefabs/fertilizer_nutrient_defs").FERTILIZER_DEFS
local CONSTANTS = require "mermexp.constants"
local Container = require "components.container"


local SEEDS, VEGGIES, WEEDS = CONSTANTS.SEEDS, CONSTANTS.VEGGIES, CONSTANTS.WEEDS

local SLOT_SIZE, PADDING, X_OFFSET, Y_OFFSET = 48, 32, 0, 120
local MAX_SEED_STACKSIZE = 80

local FarmerHouseContainer = {
  widget = {
    pos = Vector3(0, 150, 0),
    side_align_tip = 160,
    bgatlas = CONSTANTS.UI_CONTAINERS_ATLAS,
    bgimage = "farmerhousecontainer.tex",
    bgimagetint = { r = .82, g = .77, b = .7, a = 1 },
    slotpos = {},
    slotbg = {},
  },
  type = "chest",
  usespecificslotsforitems = true,
  ignoreoverstacked = false,
  reserved_slots = {
    blueprint = #SEEDS + 1,
    wateringcan = #SEEDS + 2,
    fruitflyfruit = #SEEDS + 3,
    fertilizers = {
      multinutrient = #SEEDS + 4,
      compost = #SEEDS + 5,
      formula = #SEEDS + 6,
      manure = #SEEDS + 7,
    },
    rot = #SEEDS + 8,
    harvested = #SEEDS + 9,
  },
}

do -- Slot Positions
  local function GetCenteredPosition(x, y)
    local padded_slot_size = SLOT_SIZE + PADDING
    local offset = padded_slot_size * 2

    return Vector3(padded_slot_size * x - offset + X_OFFSET, padded_slot_size * y - offset + Y_OFFSET, 0)
  end
  local function InsertSlot(x, y) table.insert(FarmerHouseContainer.widget.slotpos, GetCenteredPosition(x, y)) end

  -- Seeds
  for y = 1.5, -0.5, -1 do
    for x = 0, 4 do InsertSlot(x, y) end
  end
  InsertSlot(2, -1.5)   -- Blueprint

  InsertSlot(-3.15, -1) -- Watering Can
  InsertSlot(-2.15, -1) -- Fruit Fly Fruit

  -- Fertilizers
  InsertSlot(6.15, 2)  -- Multinutrient
  InsertSlot(6.15, 1)  -- Compost
  InsertSlot(6.15, 0)  -- Formula
  InsertSlot(6.15, -1) -- Manure

  InsertSlot(2, -6.5)  -- Rot

  -- Harvested seeds and veggies
  for y = -2.5, -5.5, -1 do
    for x = -1.5, 5.5, 1 do InsertSlot(x, y) end
  end

  FarmerHouseContainer.waterlevelmeter_position = GetCenteredPosition(-1.21, 3)
end

do -- Slot Backgrounds
  local function InsertSlotBG(image)
    table.insert(FarmerHouseContainer.widget.slotbg, { image = image, atlas = CONSTANTS.UI_ICONS_ATLAS })
  end

  for _, seed in ipairs(SEEDS) do
    InsertSlotBG(seed.name .. "_slot_gray.tex")
  end

  InsertSlotBG("blueprint_slot.tex")

  InsertSlotBG("wateringcan_slot.tex")
  InsertSlotBG("fruitflyfruit_slot.tex")

  InsertSlotBG("compost_formula_manure_slot.tex")
  InsertSlotBG("compost_slot.tex")
  InsertSlotBG("formula_slot.tex")
  InsertSlotBG("manure_slot.tex")
end

function FarmerHouseContainer:GetFarmBlueprint()
  return self:GetItemInSlot(self.reserved_slots.blueprint)
end

function FarmerHouseContainer:GetFertilizers()
  return {
    self:GetItemInSlot(self.reserved_slots.fertilizers.multinutrient),
    self:GetItemInSlot(self.reserved_slots.fertilizers.compost),
    self:GetItemInSlot(self.reserved_slots.fertilizers.formula),
    self:GetItemInSlot(self.reserved_slots.fertilizers.manure),
  }
end

function FarmerHouseContainer:GetWateringCan()
  return self:GetItemInSlot(self.reserved_slots.wateringcan)
end

local function SetMaxStackSize(item, max_size)
  if not item.components.stackable then return end
  local _ = rawget(item.components.stackable, "_")
  local old = _.maxsize[1]
  if old ~= max_size then
    _.originalmaxsize[1] = old
    _.maxsize[1] = max_size
    item.components.stackable.inst.replica.stackable:SetIgnoreMaxSize(true)
  end
end

local function ResetMaxStackSize(item)
  if not item.components.stackable then return end
  local _ = rawget(item.components.stackable, "_")
  local original = _.originalmaxsize[1]
  if original then
    _.maxsize[1] = original
    _.originalmaxsize[1] = nil
    item.components.stackable.inst.replica.stackable:SetIgnoreMaxSize(false)
  end
end


function FarmerHouseContainer:GiveItem(item, slot, src_pos, drop_on_fail)
  local result = Container.GiveItem(self, item, slot, src_pos, drop_on_fail)

  if result and item ~= nil and item.components.stackable then
    local stored_item_slot = self:GetSpecificSlotForItem(item)
    if stored_item_slot ~= nil and stored_item_slot >= self.reserved_slots.harvested then
      item.components.stackable:SetIgnoreMaxSize(true)
    else
      SetMaxStackSize(item, MAX_SEED_STACKSIZE)
    end
  end

  return result
end

function FarmerHouseContainer:RemoveItem_Internal(item, slot, wholestack, keepoverstacked)
  local removed_item = Container.RemoveItem_Internal(self, item, slot, wholestack, keepoverstacked)

  if removed_item.components.stackable then
    local specific_slot = self:GetSpecificSlotForItem(item)
    if specific_slot ~= nil and specific_slot >= self.reserved_slots.harvested then
      removed_item.components.stackable:SetIgnoreMaxSize(false)
    else
      ResetMaxStackSize(removed_item)
    end
  end

  return removed_item
end

function FarmerHouseContainer:OnLoad(data, newents)
  self.currentuser = self.inst
  Container.OnLoad(self, data, newents)
  self.currentuser = nil
end

local function ItemExceedsStackSize(item)
  local stackable = item ~= nil and item.replica.stackable

  return item == nil or (stackable and stackable:StackSize() < MAX_SEED_STACKSIZE)
end
function FarmerHouseContainer:itemtestfn(item, slot)
  local is_rot = item.prefab == "spoiled_food"
  local is_seed = SEEDS:Has(item.prefab)
  local is_veggie = VEGGIES:Has(item.prefab)
  local is_weed = WEEDS:Has(item.prefab)
  local is_blueprint = item:HasTag("mermexp") and item:HasTag("mermfarm_blueprint")
  local is_fertilizer = FERTILIZER_DEFS[item.prefab] ~= nil
  local is_wateringcan = item.prefab:find("wateringcan")
  local is_fruitflyfruit = item.prefab == "fruitflyfruit"

  local user_is_farmer = self.currentuser ~= nil and self.currentuser:HasTag("mermexp")

  if (slot == nil) then
    if (is_seed) then
      local _, seed_slot = SEEDS:At(item.prefab)
      local stored_item = self:GetItemInSlot(seed_slot)
      return stored_item == nil or ItemExceedsStackSize(stored_item) or user_is_farmer
    end

    if (is_veggie or is_rot or is_weed) then return user_is_farmer end

    return (is_fertilizer or is_blueprint or is_wateringcan or is_fruitflyfruit)
  end

  if is_rot and user_is_farmer then return slot == self.reserved_slots.rot end
  if is_seed or is_veggie or is_weed then
    local stored_item = self:GetItemInSlot(slot)
    if SEEDS:At(slot) and SEEDS:At(slot).name == item.prefab then
      return stored_item == nil or ItemExceedsStackSize(stored_item)
    end

    if user_is_farmer and slot >= self.reserved_slots.harvested then
      return (stored_item == nil or (stored_item.prefab == item.prefab))
    end

    return false
  end
  if is_blueprint then return slot == self.reserved_slots.blueprint end
  if is_wateringcan then return slot == self.reserved_slots.wateringcan end
  if is_fruitflyfruit then return slot == self.reserved_slots.fruitflyfruit end
  if is_fertilizer then
    local c, f, m = unpack(FERTILIZER_DEFS[item:GetFertilizerKey()].nutrients)
    local is_multi_slot = c > 0 and f > 0 and m > 0 and slot == self.reserved_slots.fertilizers.multinutrient
    local is_compost_slot = c > 0 and f == 0 and m == 0 and slot == self.reserved_slots.fertilizers.compost
    local is_formula_slot = c == 0 and f > 0 and m == 0 and slot == self.reserved_slots.fertilizers.formula
    local is_manure_slot = c == 0 and f == 0 and m > 0 and slot == self.reserved_slots.fertilizers.manure

    return is_multi_slot or is_compost_slot or is_formula_slot or is_manure_slot
  end

  return false
end

function FarmerHouseContainer:priorityfn(item, slot)
  return self:itemtestfn(item, slot)
end

return require("mermexp.util").RegisterContainerParam(FarmerHouseContainer, "mermhouse_farmer")

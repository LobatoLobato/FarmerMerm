require "recipes"

local assets =
{
  Asset("ANIM", "anim/blueprint.zip"),
  Asset("INV_IMAGE", "blueprint"),
  Asset("ANIM", "anim/buildgridplacer.zip")
}

local MapScreen = require("screens/farmlayoutscreen")
local function PushFarmLayoutScreen(owner, tiles)
  local popup = MapScreen("bunda", "cu",
    {
      {
        text = "close",
        cb = function() TheFrontEnd:PopScreen() end
      }
    }, tiles
  )
  TheFrontEnd:PushScreen(popup)
end

--------------------------------------------------------------------------------
-- ASSIST EFFECTS
local ASSIST_SCALE = 2
local ASSIST_RANGE = 6
local function CreateRegisterAssist(tx, ty, tz, is_registered)
  local inst = CreateEntity()

  --[[Non-networked entity]]
  inst.entity:SetCanSleep(false)
  inst.persists = false

  inst.entity:AddTransform()
  inst.entity:AddAnimState()

  inst:AddTag("CLASSIFIED")
  inst:AddTag("NOCLICK")
  inst:AddTag("placer")

  inst.AnimState:SetBank("buildgridplacer")
  inst.AnimState:SetBuild("buildgridplacer")
  inst.AnimState:PlayAnimation("anim", true)
  inst.AnimState:SetLightOverride(1)
  inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
  inst.AnimState:SetLayer(LAYER_BACKGROUND)
  inst.AnimState:SetSortOrder(1)
  inst.AnimState:SetScale(ASSIST_SCALE, ASSIST_SCALE, ASSIST_SCALE)

  if is_registered then
    inst.AnimState:SetAddColour(0, 1, 0, 1)
  else
    inst.AnimState:SetAddColour(1, 1, 1, 1)
  end

  inst.AnimState:Hide("outer")

  inst.Transform:SetPosition(tx, ty, tz)


  return inst
end

local function OnUpdateAssistHelper(assistgen_inst)
  local px, py, pz = TheWorld.Map:GetTileCenterPoint(assistgen_inst.player.Transform:GetWorldPosition())
  local range = assistgen_inst.range * 4
  local range_offset = range / 2

  local farmlayout = assistgen_inst.owner.components.farmlayout

  for _, helper in ipairs(assistgen_inst.helpers) do
    helper:Remove()
  end

  assistgen_inst.helpers = {}
  for x = 0, range, 4 do
    for z = 0, range, 4 do
      local tx, ty, tz = TheWorld.Map:GetTileCenterPoint(px + (x - range_offset), py, pz + (z - range_offset))

      if TheWorld.Map:IsFarmableSoilAtPoint(tx, ty, tz) then
        local helper = CreateRegisterAssist(tx, ty, tz, farmlayout:IsRegisteredFarmTile(Vector3(tx, ty, tz)))
        table.insert(assistgen_inst.helpers, helper)
      end
    end
  end
end

local function CreateRegisterAssistGenerator(range, player, owner, placerinst)
  local inst = CreateEntity()
  inst.entity:SetCanSleep(false)
  inst.persists = false


  inst.range = range
  inst.owner = owner
  inst.player = player
  inst.lastplayerposition = nil
  inst.placerinst = placerinst
  inst.helpers = {}

  inst:AddComponent("updatelooper")
  inst.components.updatelooper:AddOnUpdateFn(OnUpdateAssistHelper)

  return inst
end

local function OnEnableHelper(inst, enabled, _, placerinst)
  if enabled then
    local player = inst.components.inventoryitem.owner

    inst.assist_generator = CreateRegisterAssistGenerator(ASSIST_RANGE, player, inst, placerinst)
  elseif inst.assist_generator ~= nil then
    for _, helper in ipairs(inst.assist_generator.helpers) do
      helper:Remove()
    end
    inst.assist_generator:Remove()
    inst.assist_generator = nil
  end
end

------------------------------------------------------------
local function OnLoad(inst, data)
  -- if data ~= nil and data.recipetouse ~= nil then
  --   inst.recipetouse = data.recipetouse
  --   inst.components.teacher:SetRecipe(inst.recipetouse)

  --   if data.is_rare then
  --     inst.is_rare = data.is_rare
  --     inst.components.named:SetName(subfmt(STRINGS.NAMES.BLUEPRINT_RARE,
  --       { item = STRINGS.NAMES[string.upper(inst.recipetouse)] or STRINGS.NAMES.UNKNOWN }))
  --     inst.AnimState:SetBank("blueprint_rare")
  --     inst.AnimState:SetBuild("blueprint_rare")
  --     inst.components.inventoryitem:ChangeImageName("blueprint_rare")
  --     inst:RemoveComponent("burnable")
  --     inst:RemoveComponent("propagator")
  --   else
  --     inst.components.named:SetName((STRINGS.NAMES[string.upper(inst.recipetouse)] or STRINGS.NAMES.UNKNOWN) ..
  --       " " .. STRINGS.NAMES.BLUEPRINT)
  --   end
  -- end
end

local function OnSave(inst, data)
  -- data.recipetouse = inst.recipetouse
  -- data.is_rare = inst.is_rare or nil
end

local function OnEquip(inst)
  local placer = SpawnPrefab("farm_layout_blueprint_placer")
  inst.components.deployhelper:StartHelper("bundabolas", placer)
end

local function OnUnequip(inst)
  inst.components.deployhelper:StopHelper()
end

local function OnUse(inst)
  local owner = inst.components.inventoryitem.owner
  if owner then
    PushFarmLayoutScreen(owner, inst.components.farmlayout:GetRegisteredFarmTiles())
  end
  return false
end

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  MakeInventoryPhysics(inst)

  inst.AnimState:SetBank("blueprint")
  inst.AnimState:SetBuild("blueprint")
  inst.AnimState:PlayAnimation("idle")

  MakeInventoryFloatable(inst, "med", nil, 0.75)

  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  if not TheNet:IsDedicated() then
    inst.entity:SetCanSleep(false)
    inst:AddComponent("deployhelper")
    inst.components.deployhelper.onenablehelper = OnEnableHelper
    inst.components.deployhelper.OnWallUpdate = function() end
  end

  inst:AddComponent("inspectable")
  -- inst.components.inspectable.getstatus = getstatus

  inst:AddComponent("farmlayout")

  inst:AddComponent("inventoryitem")
  inst.components.inventoryitem:ChangeImageName("blueprint")

  inst:AddComponent("equippable")
  inst.components.equippable.equipslot = EQUIPSLOTS.HANDS
  inst.components.equippable:SetOnEquip(OnEquip)
  inst.components.equippable:SetOnUnequip(OnUnequip)

  inst:AddComponent("useableitem")
  inst.components.useableitem:SetOnUseFn(OnUse)

  inst:AddComponent("fuel")
  inst.components.fuel.fuelvalue = TUNING.SMALL_FUEL

  MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
  MakeSmallPropagator(inst)

  MakeHauntableLaunch(inst)

  inst.OnLoad = OnLoad
  inst.OnSave = OnSave

  return inst
end

return Prefab("farm_layout_blueprint", fn, assets), MakePlacer("farm_layout_blueprint_placer")

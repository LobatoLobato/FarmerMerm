local INVENTORYIMAGES_ATLAS = require "mermexp.constants".INVENTORYIMAGES_ATLAS

local assets = {
  Asset("ANIM", "anim/blueprint.zip"),
  Asset("ANIM", "anim/buildgridplacer.zip"),
  Asset("ANIM", "anim/farm_plant_seeds.zip"),
}

--------------------------------------------------------------------------------
-- ASSIST EFFECTS
local ASSIST_SCALE = 2
local ASSIST_RANGE = 8

local function CreateRegisterAssist(tx, ty, tz, is_registered, plant)
  local inst = CreateEntity()

  --[[Non-networked entity]]
  inst.entity:SetCanSleep(false)
  inst.persists = false

  inst.entity:AddTransform()
  inst.entity:AddAnimState()

  inst:AddTag("CLASSIFIED")
  inst:AddTag("NOCLICK")
  inst:AddTag("placer")


  if plant then
    inst.AnimState:SetBank(plant.bank)
    inst.AnimState:SetBuild(plant.build)
    inst.AnimState:OverrideSymbol("soil01", "farm_soil", "soil01")
    inst.AnimState:PlayAnimation(plant.anim, true)
  else
    inst.AnimState:SetBank("buildgridplacer")
    inst.AnimState:SetBuild("buildgridplacer")
    inst.AnimState:PlayAnimation("anim", true)
    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)
    inst.AnimState:SetScale(ASSIST_SCALE, ASSIST_SCALE, ASSIST_SCALE)
  end

  if is_registered then
    inst.AnimState:SetAddColour(0, 0.459, 0.251, 0)
  else
    inst.AnimState:SetAddColour(1, 1, 1, 1)
  end

  inst.AnimState:Hide("outer")
  if plant then
    inst.Transform:SetPosition(tx, 0.1, tz)
  else
    inst.Transform:SetPosition(tx, ty, tz)
  end

  return inst
end

local function DrawHelper(helpers, farmblueprint, tx, ty, tz)
  local is_registered = farmblueprint:IsRegisteredFarmTile(tx, ty, tz)
  if not is_registered then return table.insert(helpers, CreateRegisterAssist(tx, ty, tz, is_registered)) end

  for _, slot in pairs(farmblueprint:GetRegisteredFarmTileAtPoint(tx, ty, tz).slots) do
    if not farmblueprint.SlotIsPlanted(slot) then
      table.insert(helpers, CreateRegisterAssist(slot.x, slot.y, slot.z, true, slot.assigned_plant))
    end
  end
end

local function OnUpdateAssistHelper(assistupdater, _, skip_position_check)
  local lastpos = assistupdater.lastplayerpos
  local currpos = Vector3(ThePlayer.Transform:GetWorldPosition())

  if lastpos ~= nil and not skip_position_check then
    if VecUtil_Dist(lastpos.x, lastpos.z, currpos.x, currpos.z) < 2 then return end
  end

  assistupdater.lastplayerpos = currpos

  local px, py, pz = TheWorld.Map:GetTileCenterPoint(currpos:Get())
  local range = assistupdater.range * 4

  local farmblueprint = assistupdater.owner.replica.mermexp_mermfarmblueprint

  for _, helper in ipairs(assistupdater.helpers) do helper:Remove() end

  assistupdater.helpers = {}
  for x = 0, range * 2, 4 do
    for z = 0, range * 2, 4 do
      local tx, ty, tz = TheWorld.Map:GetTileCenterPoint(px + (x - range), py, pz + (z - range))

      if TheWorld.Map:IsFarmableSoilAtPoint(tx, ty, tz) then
        DrawHelper(assistupdater.helpers, farmblueprint, tx, ty, tz)
      end
    end
  end
end

local function CreateRegisterAssistUpdater(range, owner)
  local inst = CreateEntity()
  inst.entity:SetCanSleep(false)
  inst.persists = false

  inst:AddTag("CLASSIFIED")
  inst:AddTag("NOCLICK")
  inst:AddTag("placer")

  inst.range = range
  inst.owner = owner
  inst.lastplayerpos = nil
  inst.helpers = {}

  inst:AddComponent("updatelooper")
  inst.components.updatelooper:AddOnUpdateFn(OnUpdateAssistHelper)
  inst.owner.replica["mermexp_mermfarmblueprint"]:SetOnChangeFn(function() OnUpdateAssistHelper(inst, 0, true) end)

  return inst
end

local function OnEnableHelper(inst, enabled)
  if enabled then
    if inst:PlayerHasOtherBlueprintEquipped() or not inst:IsActiveOrEquipped() then return end

    inst.assist_updater = CreateRegisterAssistUpdater(ASSIST_RANGE, inst)
    OnUpdateAssistHelper(inst.assist_updater)
  elseif inst.assist_updater ~= nil then
    for _, helper in ipairs(inst.assist_updater.helpers) do helper:Remove() end
    inst.replica["mermexp_mermfarmblueprint"]:SetOnChangeFn(nil)
    inst.assist_updater:Remove()
    inst.assist_updater = nil
  end
end

------------------------------------------------------------

local function OnUse(inst)
  local owner = inst.components.inventoryitem.owner

  if owner then
    if not CanEntitySeeTarget(owner, inst) then return false end
    owner:ShowPopUp(POPUPS.MERMEXP_MERMFARMBLUEPRINT, true, inst)
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

  inst:AddTag("mermexp")
  inst:AddTag("mermfarm_blueprint")

  inst.mermexp_mermfarmblueprint_classified = SpawnPrefab("mermexp_mermfarmblueprint_classified")

  if not TheNet:IsDedicated() then
    inst.entity:SetCanSleep(false)
    inst:AddComponent("deployhelper")
    inst.components.deployhelper.onenablehelper = OnEnableHelper
    inst.components.deployhelper.onstarthelper = function() inst.helper_running = true end
    inst.components.deployhelper.OnWallUpdate = function() end

    inst.StartHelper = function(inst)
      inst.components.deployhelper:StartHelper()
      inst.helper_running = true
    end

    inst.StopHelper = function(inst)
      inst.components.deployhelper:StopHelper()
      inst.helper_running = false
    end

    inst.PlayerHasOtherBlueprintEquipped = function(inst)
      local equippeditem = ThePlayer.replica.inventory:GetEquippedItem(inst.replica.equippable:EquipSlot())
      return equippeditem and equippeditem.prefab == inst.prefab and not inst.replica.equippable:IsEquipped()
    end
    inst.IsActiveOrEquipped = function(inst)
      local activeitem = ThePlayer.replica.inventory:GetActiveItem()
      return (activeitem and activeitem.GUID == inst.GUID) or inst.replica.equippable:IsEquipped()
    end

    inst:AddComponent("updatelooper")
    inst.components.updatelooper:AddOnUpdateFn(function(inst)
      if inst:PlayerHasOtherBlueprintEquipped() then
        if inst.helper_running then inst:StopHelper() end
        return
      end

      if not inst.helper_running and inst:IsActiveOrEquipped() then
        inst:StartHelper()
      elseif inst.helper_running and not inst:IsActiveOrEquipped() then
        inst:StopHelper()
      end
    end)
  end

  inst.entity:SetPristine()

  inst.persists = true

  if not TheWorld.ismastersim then
    return inst
  end

  inst:AddComponent("inspectable")

  inst:AddComponent("mermexp_mermfarmblueprint")

  inst:AddComponent("inventoryitem")
  inst.components.inventoryitem.atlasname = INVENTORYIMAGES_ATLAS
  inst.components.inventoryitem.imagename = "mermexp_mermfarm_blueprint"

  inst:AddComponent("equippable")
  inst.components.equippable.equipslot = EQUIPSLOTS.HANDS

  inst:AddComponent("useableitem")
  inst.components.useableitem:SetOnUseFn(OnUse)

  MakeHauntableLaunch(inst)

  return inst
end

return Prefab("mermexp_mermfarm_blueprint", fn, assets)

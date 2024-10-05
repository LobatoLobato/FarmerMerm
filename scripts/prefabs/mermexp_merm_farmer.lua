local MakeMerm = require "mermexp.util.makemerm"
local MermFarmerWidget = require "mermexp.containerwidgets.merm_farmer"
local assets =
{
  Asset("ANIM", "anim/merm_build.zip"),
  Asset("ANIM", "anim/merm_actions.zip"),
  Asset("ANIM", "anim/merm_actions_skills.zip"),
  Asset("ANIM", "anim/ds_pig_boat_jump.zip"),
  Asset("ANIM", "anim/pigman_yotb.zip"),
  Asset("ANIM", "anim/ds_pig_basic.zip"),
  Asset("ANIM", "anim/ds_pig_actions.zip"),
  Asset("ANIM", "anim/ds_pig_attacks.zip"),
  Asset("ANIM", "anim/ds_pig_elite.zip"),

  Asset("ANIM", "anim/merm_actions_skills.zip"),

  Asset("SOUND", "sound/merm.fsb"),
}

local prefabs = {
  "pondfish",
  "froglegs",
  "mermking",
  "merm_splash",
  "merm_spawn_fx",
  "merm_shadow",

  "mermking_buff_trident",
  "mermking_buff_crown",
  "mermking_buff_pauldron",

  "merm_soil_marker",
}

local merm_loot = {
  "pondfish",
  "froglegs",
}

local sounds = {
  hit = "dontstarve/creatures/merm/hurt",
  death = "dontstarve/creatures/merm/death",
  talk = "dontstarve/characters/wurt/merm/warrior/talk",
  buff = "dontstarve/characters/wurt/merm/warrior/yell",
}

local merm_farmer_brain = require "brains.mermexp.merm_farmerbrain"

local function farmer_common(inst)
  inst.sounds = sounds
  inst.AnimState:SetBuild("merm_build")

  inst:AddTag("merm_farmer")

  if not TUNING.MERMEXP_MERMFARMER_UNLOADS then
    inst.entity:SetCanSleep(false)
  end
end

local function on_mermking_destroyed_anywhere(inst)
  inst:DoTaskInTime(math.random(), function() inst.components.health:Kill() end)
end

local function farmer_master(inst)
  inst:SetBrain(merm_farmer_brain)

  inst.components.lootdropper:SetLoot(merm_loot)

  inst:AddComponent("container")
  inst.components.container:WidgetSetup(MermFarmerWidget)
  inst.components.container:EnableInfiniteStackSize(true)

  inst:ListenForEvent("onmermkingdestroyed_anywhere", function() on_mermking_destroyed_anywhere(inst) end, TheWorld)

  function inst:GetFarmBlueprint()
    if inst:GetHome() == nil then return nil end
    return inst:GetHome():GetFarmBlueprint()
  end

  function inst:GetWateringCan()
    return self:FetchItemInSelf("wateringcan", { equipslot = EQUIPSLOTS.HANDS, include_home = true })
  end

  function inst:GetTool()
    return self:FetchItemInSelf("merm_tool", { equipslot = EQUIPSLOTS.HANDS })
  end

  function inst:FetchSeeds(seeds, remove)
    return self:FetchItemInSelf(seeds, { remove = remove, include_home = true, exact = true })
  end

  function inst:EquipWateringCan()
    if self:GetWateringCan() then
      self:UnequipHands()
      return self:Equip("wateringcan", EQUIPSLOTS.HANDS, { try_equip_from_home = true })
    end
  end

  function inst:EquipTool()
    if self:GetTool() then
      self:UnequipHands()
      return self:Equip("merm_tool", EQUIPSLOTS.HANDS)
    end
  end

  function inst:UnequipHands()
    self:Unequip(EQUIPSLOTS.HANDS, { store_at_home_list = { "wateringcan" } })
  end

  function inst:ShowInventory()
    for _, v in pairs(self.components.inventory.itemslots) do
      print(v)
    end
  end
end

return MakeMerm("mermexp_merm_farmer", assets, prefabs, farmer_common, farmer_master)

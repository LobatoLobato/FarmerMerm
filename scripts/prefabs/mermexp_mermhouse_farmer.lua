require("worldsettingsutil")
local MakeMermHouse = require 'mermexp.util.makemermhouse'
local ContainerWidget = require "mermexp.containerwidgets.mermhouse_farmer"

local assets = {
    Asset("ANIM", "anim/mermhouse_farmer.zip"),
}

local prefabs = {
    "mermexp_merm_farmer",
    "mermexp_mermfarm_blueprint",
    "collapse_big",

    --loot:
    "boards",
    "plantregistryhat",
    "pondfish",
}

local MAX_WATER_LEVEL = 10000

local function mermhouse_farmer_common(inst)
    inst.MiniMapEntity:SetIcon("mermhouse_farmer.tex")
    inst.AnimState:SetBank("mermhouse_farmer")
    inst.AnimState:SetBuild("mermhouse_farmer")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("mermhouse_farmer")

    if not TUNING.MERMEXP_MERMFARMER_UNLOADS then
        inst.entity:SetCanSleep(false)
    end

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = function(inst) inst.replica.container:WidgetSetup(ContainerWidget) end
    end
end

local function mermhouse_farmer_master(inst)
    local container = inst:AddComponent("container")
    container:WidgetSetup(ContainerWidget)

    local waterreservoir = inst:AddComponent("mermexp_waterreservoir")
    waterreservoir:SetMaxLevel(MAX_WATER_LEVEL)

    inst.GetFarmBlueprint = function() return container:GetFarmBlueprint() end
    inst.GetFertilizers = function() return container:GetFertilizers() end
    inst.GetWateringCan = function() return container:GetWateringCan() end
    inst.GetWaterStorageLevel = function() return waterreservoir:Level() end

    local childspawner = inst.components.childspawner
    childspawner.childname = "mermexp_merm_farmer"
    childspawner.emergencychildname = "mermexp_merm_farmer"

    inst:SetNeedsKingToSpawn(true)
    inst:SetNeedsKingToRelease(true)
    inst:SetSpawnOnKingCreated(true)
end

return MakeMermHouse("mermexp_mermhouse_farmer", assets, prefabs, mermhouse_farmer_common, mermhouse_farmer_master, {
    bank = "mermhouse_farmer",
    build = "mermhouse_farmer"
})

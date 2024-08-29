require("worldsettingsutil")


local assets = {
    Asset("ANIM", "anim/mermhouse_farmer.zip"),

    Asset("ATLAS", "images/inventoryimages/mermhouse_farmer.xml"),
    Asset("IMAGE", "images/inventoryimages/mermhouse_farmer.tex"),

    Asset("IMAGE", "images/ui_chest.tex"),
    Asset("ATLAS", "images/ui_chest.xml"),

    Asset("IMAGE", "images/empty_slot.tex"),
    Asset("ATLAS", "images/empty_slot.xml"),

    Asset("ATLAS", "images/mermhouse_farmer_slots/blueprint_slot.xml"),
    Asset("IMAGE", "images/mermhouse_farmer_slots/blueprint_slot.tex"),

    Asset("ATLAS", "images/mermhouse_farmer_slots/asparagus_seeds_slot.xml"),
    Asset("IMAGE", "images/mermhouse_farmer_slots/asparagus_seeds_slot.tex"),

    Asset("ATLAS", "images/mermhouse_farmer_slots/carrot_seeds_slot.xml"),
    Asset("IMAGE", "images/mermhouse_farmer_slots/carrot_seeds_slot.tex"),

    Asset("ATLAS", "images/mermhouse_farmer_slots/corn_seeds_slot.xml"),
    Asset("IMAGE", "images/mermhouse_farmer_slots/corn_seeds_slot.tex"),

    Asset("ATLAS", "images/mermhouse_farmer_slots/dragonfruit_seeds_slot.xml"),
    Asset("IMAGE", "images/mermhouse_farmer_slots/dragonfruit_seeds_slot.tex"),

    Asset("ATLAS", "images/mermhouse_farmer_slots/durian_seeds_slot.xml"),
    Asset("IMAGE", "images/mermhouse_farmer_slots/durian_seeds_slot.tex"),

    Asset("ATLAS", "images/mermhouse_farmer_slots/eggplant_seeds_slot.xml"),
    Asset("IMAGE", "images/mermhouse_farmer_slots/eggplant_seeds_slot.tex"),

    Asset("ATLAS", "images/mermhouse_farmer_slots/garlic_seeds_slot.xml"),
    Asset("IMAGE", "images/mermhouse_farmer_slots/garlic_seeds_slot.tex"),

    Asset("ATLAS", "images/mermhouse_farmer_slots/onion_seeds_slot.xml"),
    Asset("IMAGE", "images/mermhouse_farmer_slots/onion_seeds_slot.tex"),

    Asset("ATLAS", "images/mermhouse_farmer_slots/pepper_seeds_slot.xml"),
    Asset("IMAGE", "images/mermhouse_farmer_slots/pepper_seeds_slot.tex"),

    Asset("ATLAS", "images/mermhouse_farmer_slots/pomegranate_seeds_slot.xml"),
    Asset("IMAGE", "images/mermhouse_farmer_slots/pomegranate_seeds_slot.tex"),

    Asset("ATLAS", "images/mermhouse_farmer_slots/potato_seeds_slot.xml"),
    Asset("IMAGE", "images/mermhouse_farmer_slots/potato_seeds_slot.tex"),

    Asset("ATLAS", "images/mermhouse_farmer_slots/pumpkin_seeds_slot.xml"),
    Asset("IMAGE", "images/mermhouse_farmer_slots/pumpkin_seeds_slot.tex"),

    Asset("ATLAS", "images/mermhouse_farmer_slots/tomato_seeds_slot.xml"),
    Asset("IMAGE", "images/mermhouse_farmer_slots/tomato_seeds_slot.tex"),

    Asset("ATLAS", "images/mermhouse_farmer_slots/watermelon_seeds_slot.xml"),
    Asset("IMAGE", "images/mermhouse_farmer_slots/watermelon_seeds_slot.tex"),
}


local prefabs = {
    "merm",
    "collapse_big",

    --loot:
    "boards",
    "rocks",
    "pondfish",
}

local seed_table = {
    [1] = "asparagus_seeds",
    [2] = "carrot_seeds",
    [3] = "corn_seeds",
    [4] = "dragonfruit_seeds",
    [5] = "durian_seeds",
    [6] = "eggplant_seeds",
    [7] = "garlic_seeds",
    [8] = "onion_seeds",
    [9] = "pepper_seeds",
    [10] = "pomegranate_seeds",
    [11] = "potato_seeds",
    [12] = "pumpkin_seeds",
    [13] = "tomato_seeds",
    [14] = "watermelon_seeds",
    find = function(self, seed)
        for i, s in ipairs(self) do if s == seed then return i end end
        return nil
    end
}

local mermhouse_farmer = _G.Recipe2(
    "mermhouse_farmer",
    {
        _G.Ingredient("boards", 5), _G.Ingredient("pondfish", 2),
        _G.Ingredient("farm_hoe", 1), _G.Ingredient("wateringcan", 1),
        _G.Ingredient("plantregistryhat", 1),
    },
    _G.TECH.SCIENCE_ONE,
    {
        builder_tag = "merm_builder",
        placer = "mermhouse_farmer_placer",
        testfn = function(pt, rot)
            local ground_tile = TheWorld.Map:GetTileAtPoint(pt.x, pt.y, pt.z)
            return ground_tile and (ground_tile == WORLD_TILES.MARSH or ground_tile == WORLD_TILES.FARMING_SOIL)
        end
    }
)
mermhouse_farmer.atlas = "images/inventoryimages/mermhouse_farmer.xml"


local function make_farmhouse_container_widget()
    local containers = require("containers")
    local slottexpath = "images/mermhouse_farmer_slots/"
    local mermhouse_farmer = {
        widget = {
            animbank = nil,
            animbuild = nil,
            pos = Vector3(0, 150, 0),
            side_align_tip = 160,
            bgatlas = "images/ui_chest.xml",
            bgimage = "ui_chest.tex",
            bgimagetint = { r = .82, g = .77, b = .7, a = 1 },
            slotpos = (function()
                local slotpos = {}
                for y = 1.5, -0.5, -1 do
                    for x = 0, 4 do table.insert(slotpos, Vector3(80 * x - 80 * 2, 80 * y - 80 * 2 + 120, 0)) end
                end
                return slotpos
            end)(),
            slotbg = (function()
                local slotbg = {}
                for _, seed in ipairs(seed_table) do
                    table.insert(slotbg, { image = seed .. "_slot.tex", atlas = slottexpath .. seed .. "_slot.xml" })
                end
                table.insert(slotbg, { image = "blueprint_slot.tex", atlas = slottexpath .. "blueprint_slot.xml" })
                return slotbg
            end)()
        },
        type = "chest",
        usespecificslotsforitems = true,
        itemtestfn = function(container, item, slot)
            local is_blueprint = item.prefab == ("farm_layout_blueprint")
            if (slot == nil and (seed_table[seed_table:find(item.prefab)] or is_blueprint)) then
                return true
            end
            return (seed_table[slot] == item.prefab or (is_blueprint and slot == 15))
        end
    }
    mermhouse_farmer.priorityfn = mermhouse_farmer.itemtestfn

    containers.MAXITEMSLOTS = math.max(
        containers.MAXITEMSLOTS,
        mermhouse_farmer.widget.slotpos ~= nil and #mermhouse_farmer.widget.slotpos or 0
    )

    containers.params.mermhouse_farmer = mermhouse_farmer
end
make_farmhouse_container_widget()



---------------------------------------------------------------
-- PLACER EFFECTS
local PLACER_SCALE = 1.5

local function OnUpdatePlacerHelper(helperinst)
    if not helperinst.placerinst:IsValid() then
        helperinst.components.updatelooper:RemoveOnUpdateFn(OnUpdatePlacerHelper)
        helperinst.AnimState:SetAddColour(0, 0, 0, 0)
    elseif helperinst:IsNear(helperinst.placerinst, TUNING.WURT_OFFERING_POT_RANGE) then
        helperinst.AnimState:SetAddColour(helperinst.placerinst.AnimState:GetAddColour())
    else
        helperinst.AnimState:SetAddColour(0, 0, 0, 0)
    end
end

local function CreatePlacerRing()
    local inst = CreateEntity()

    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("placer")


    inst.AnimState:SetBank("winona_battery_placement")
    inst.AnimState:SetBuild("winona_battery_placement")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetAddColour(0, .2, .5, 0)
    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)
    inst.AnimState:SetScale(PLACER_SCALE, PLACER_SCALE)

    inst.AnimState:Hide("outer")

    return inst
end

local function OnEnableHelper(inst, enabled, recipename, placerinst)
    if enabled then
        inst.helper = CreatePlacerRing()
        inst.helper.entity:SetParent(inst.entity)

        inst.helper:AddComponent("updatelooper")
        inst.helper.components.updatelooper:AddOnUpdateFn(OnUpdatePlacerHelper)
        inst.helper.placerinst = placerinst
        OnUpdatePlacerHelper(inst.helper)
    elseif inst.helper ~= nil then
        inst.helper:Remove()
        inst.helper = nil
    end
end

local function OnStartHelper(inst) --, recipename, placerinst)
    if inst.AnimState:IsCurrentAnimation("place") then
        inst.components.deployhelper:StopHelper()
    end
end

---------------------------------------------------------------------------------------------
local function StartSpawning(inst)
    if not TheWorld.state.iswinter and inst.components.childspawner ~= nil and not inst:HasTag("burnt") then
        if inst:HasTag("mermhouse_farmer") and not inst.mermkingmanager:HasKingAnywhere() then return end

        inst.components.childspawner:StartSpawning()
    end
end

local function StopSpawning(inst)
    if inst.components.childspawner ~= nil and not inst:HasTag("burnt") then
        inst.components.childspawner:StopSpawning()
    end
end

local function ReleaseAllChildren(inst, worker)
    if inst:HasTag("mermhouse_farmer") and not inst.mermkingmanager:HasKingAnywhere() then return end

    inst.components.childspawner:ReleaseAllChildren(worker)
end

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst:RemoveComponent("childspawner")
    inst.components.lootdropper:DropLoot()
    inst.components.container:DropEverything()

    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        if inst.components.childspawner ~= nil then
            ReleaseAllChildren(inst, worker)
        end
        inst.components.container:DropEverything()
        inst.components.container:Close()
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle")
    end
end

local function OnSpawned(inst, child)
    if not inst:HasTag("burnt") then
        inst.SoundEmitter:PlaySound("dontstarve/common/pighouse_door")
        if TheWorld.state.isday and
            inst.components.childspawner ~= nil and
            inst.components.childspawner:CountChildrenOutside() >= 1 and
            child.components.combat.target == nil then
            StopSpawning(inst)
        end
    end
end

local function OnGoHome(inst, child)
    if not inst:HasTag("burnt") then
        inst.SoundEmitter:PlaySound("dontstarve/common/pighouse_door")
        if inst.components.childspawner ~= nil and
            inst.components.childspawner:CountChildrenOutside() < 1 then
            StartSpawning(inst)
        end
    end
end

local function onsave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function onload(inst, data)
    if data ~= nil and data.burnt then
        inst.components.burnable.onburnt(inst)
    end
end

local function onignite(inst)
    if inst.components.childspawner ~= nil then
        ReleaseAllChildren(inst)
    end
end

local function onburntup(inst)
    inst.AnimState:PlayAnimation("burnt")
end

local function OnIsDay(inst, isday)
    if isday then
        StopSpawning(inst)
    elseif not inst:HasTag("burnt") then
        if not TheWorld.state.iswinter then
            ReleaseAllChildren(inst)
        end
        StartSpawning(inst)
    end
end

local HAUNT_TARGET_MUST_TAGS = { "character" }
local HAUNT_TARGET_CANT_TAGS = { "merm", "playerghost", "INLIMBO" }
local function OnHaunt(inst)
    if inst.components.childspawner == nil or
        not inst.components.childspawner:CanSpawn() or
        math.random() > TUNING.HAUNT_CHANCE_HALF then
        return false
    end

    local target = FindEntity(inst, 25, nil, HAUNT_TARGET_MUST_TAGS, HAUNT_TARGET_CANT_TAGS)
    if target then
        onhit(inst, target)
        return true
    else
        return false
    end
end


local function MakeMermHouse(name, common_postinit, master_postinit)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, 1)

        inst:AddTag("structure")

        MakeSnowCoveredPristine(inst)

        if common_postinit ~= nil then
            common_postinit(inst)
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("lootdropper")

        local workable = inst:AddComponent("workable")
        workable:SetWorkAction(ACTIONS.HAMMER)
        workable:SetWorkLeft(2)
        workable:SetOnFinishCallback(onhammered)
        workable:SetOnWorkCallback(onhit)

        local childspawner = inst:AddComponent("childspawner")
        childspawner.childname = "merm"
        childspawner:SetSpawnedFn(OnSpawned)
        childspawner:SetGoHomeFn(OnGoHome)

        childspawner.emergencychildname = "merm"
        childspawner:SetEmergencyRadius(TUNING.MERMHOUSE_EMERGENCY_RADIUS)

        --childspawner.calculateregenratefn = calcregenrate

        local hauntable = inst:AddComponent("hauntable")
        hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
        hauntable:SetOnHauntFn(OnHaunt)

        inst:WatchWorldState("isday", OnIsDay)

        StartSpawning(inst)

        MakeMediumBurnable(inst, nil, nil, true)
        MakeLargePropagator(inst)
        inst:ListenForEvent("onignite", onignite)
        inst:ListenForEvent("burntup", onburntup)

        inst:AddComponent("inspectable")

        MakeSnowCovered(inst)

        inst.OnSave = onsave
        inst.OnLoad = onload

        if master_postinit then
            master_postinit(inst)
        end

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

local function mermhouse_farmer_common(inst)
    local function OverrideGiveItem(container, max_seed_stacksize)
        local function SetMaxStackSize(item, maxsize)
            local stackable = item.components.stackable
            local _ = rawget(stackable, "_") --see class.lua for property setters implementation
            local old = _.maxsize[1]
            if old ~= maxsize then
                _.originalmaxsize[1] = old
                _.maxsize[1] = maxsize
                stackable.inst.replica.stackable:SetIgnoreMaxSize(true)
            end
        end

        local giveitem = container.GiveItem
        container.GiveItem = function(self, item, slot, src_pos, drop_on_fail)
            local result = giveitem(self, item, slot, src_pos, drop_on_fail)

            if result and item ~= nil and item.components.stackable then
                SetMaxStackSize(item, max_seed_stacksize)
            end

            return result
        end
    end
    local function OverrideRemoveItem(container)
        local function ResetMaxStackSize(item)
            local stackable = item.components.stackable
            local _ = rawget(stackable, "_") --see class.lua for property setters implementation
            local original = _.originalmaxsize[1]
            if original then
                _.maxsize[1] = original
                _.originalmaxsize[1] = nil
                stackable.inst.replica.stackable:SetIgnoreMaxSize(false)
            end
        end

        local removeitem_internal = container.RemoveItem_Internal
        container.RemoveItem_Internal = function(self, item, slot, wholestack, keepoverstacked)
            local result = removeitem_internal(self, item, slot, wholestack, keepoverstacked)
            if item.components.stackable then
                if not self.ignoreoverstacked then self:DropOverstackedExcess(item) end
                ResetMaxStackSize(item)
            end
            return result
        end
    end

    inst.MiniMapEntity:SetIcon("mermhouse_farmer.tex")
    inst.AnimState:SetBank("mermhouse_farmer")
    inst.AnimState:SetBuild("mermhouse_farmer")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("mermhouse_farmer")

    --Dedicated server does not need deployhelper
    if not TheNet:IsDedicated() then
        inst:AddComponent("deployhelper")
        inst.components.deployhelper.onenablehelper = OnEnableHelper
        inst.components.deployhelper.onstarthelper = OnStartHelper
    end

    -------------------------------------------------------------------------------
    local container = inst:AddComponent("container")
    container:WidgetSetup("mermhouse_farmer")
    OverrideGiveItem(container, 80)
    OverrideRemoveItem(container)

    inst.mermkingmanager = TheWorld.components.mermkingmanager
end

local function onbuilt(inst)
    inst.SoundEmitter:PlaySound("dontstarve/characters/wurt/merm/hut/place")
    inst.AnimState:PlayAnimation("place")
end

local function OnPreLoadCrafted(inst, data)
    WorldSettings_ChildSpawner_PreLoad(inst, data, TUNING.MERMHOUSE_RELEASE_TIME, TUNING.MERMHOUSE_REGEN_TIME / 2)
end

---------------------------------------------------------------------------------------------

local MAX_COUNT = 6 -- Max num slots of a offering_pot, this shouldn't be static...

local function UpdateSpawningTime(inst, data)
    if data.inst == nil or
        not data.inst:IsValid() or
        data.inst:GetDistanceSqToInst(inst) > TUNING.WURT_OFFERING_POT_RANGE * TUNING.WURT_OFFERING_POT_RANGE
    then
        return
    end

    local timer   = inst.components.worldsettingstimer
    local spawner = inst.components.childspawner

    if timer == nil or spawner == nil then
        return
    end

    inst.kelpofferings[data.inst.GUID] = data.count and data.count > 0 and data.count or nil

    local topcount = 0

    for _, count in pairs(inst.kelpofferings) do
        if count > topcount then
            topcount = count
        end
    end

    local mult = Remap(topcount, 0, MAX_COUNT, 1, TUNING.WURT_MAX_OFFERING_REGEN_MULT)

    timer:SetMaxTime("ChildSpawner_RegenPeriod", TUNING.MERMHOUSE_REGEN_TIME / 2 * mult)
    spawner:SetRegenPeriod(TUNING.MERMHOUSE_REGEN_TIME / 2 * mult)
end

---------------------------------------------------------------------------------------------

local function mermhouse_farmer_master(inst)
    local childspawner = inst.components.childspawner
    childspawner.childname = "merm_farmer"
    childspawner:SetRegenPeriod(TUNING.MERMHOUSE_REGEN_TIME / 2)
    childspawner:SetSpawnPeriod(TUNING.MERMHOUSE_RELEASE_TIME)
    childspawner:SetMaxChildren(inst.mermkingmanager:HasKingAnywhere() and 1 or 0)
    WorldSettings_ChildSpawner_SpawnPeriod(inst, TUNING.MERMHOUSE_RELEASE_TIME, TUNING.MERMHOUSE_ENABLED)
    WorldSettings_ChildSpawner_RegenPeriod(inst, TUNING.MERMHOUSE_REGEN_TIME / 2, TUNING.MERMHOUSE_ENABLED)

    if not TUNING.MERMHOUSE_ENABLED then
        childspawner.childreninside = 0
    end

    inst.UpdateSpawningTime = UpdateSpawningTime
    inst.kelpofferings = {}

    inst:ListenForEvent("onbuilt", onbuilt)
    inst:ListenForEvent("ms_updateofferingpotstate", function(_, data) inst:UpdateSpawningTime(data) end, TheWorld)

    inst.OnPreLoad = OnPreLoadCrafted

    TheWorld:ListenForEvent("onmermkingcreated", function()
        if childspawner ~= nil and childspawner:CountChildrenOutside() < 1 then
            childspawner:SetMaxChildren(1)
            childspawner:SpawnChild()
        end
    end)

    TheWorld:ListenForEvent("onmermkingdestroyed", function()
        if childspawner ~= nil and childspawner:CountChildrenOutside() >= 1 then
            childspawner.childreninside = 0
            childspawner:SetMaxChildren(0)
            for child in pairs(childspawner.childrenoutside) do child.components.health:Kill() end
        end
    end)
end

local function invalid_placement_fn(player, placer)
    if placer and placer.mouse_blocked then
        return
    end

    if player and player.components.talker then
        player.components.talker:Say(GetString(player, "ANNOUNCE_CANTBUILDHERE_HOUSE"))
    end
end

return MakeMermHouse("mermhouse_farmer", mermhouse_farmer_common, mermhouse_farmer_master), MakePlacer(
    "mermhouse_farmer_placer", "mermhouse_farmer", "mermhouse_farmer", "idle",
    nil, nil, nil, nil, nil, nil, nil, nil, invalid_placement_fn
)

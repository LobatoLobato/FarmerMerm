require "behaviours/wander"
require "behaviours/leash"
require "behaviours/standstill"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/panic"

local BrainCommon          = require "brains/braincommon"

local FACETIME_BASE        = 2
local FACETIME_RAND        = 2

local SEE_PLAYER_DIST      = 2
local MAX_WANDER_DIST      = 10

local FIND_SHED_RANGE      = 15

local TOOLSHED_ONEOF_TAGS  = { "merm_toolshed", "merm_toolshed_upgraded" }
local MERM_TOOL_CANT_TAGS  = { "INLIMBO" }
local MERM_TOOL_ONEOF_TAGS = { "merm_tool", "merm_tool_upgraded" }
local SOILMUST             = { "soil" }
local SOILMUSTNOT          = { "merm_soil_blocker", "farm_debris", "NOBLOCK" }
local FARM_PLANT_TAGS      = { "farm_plant", "weed" }
local FARM_ENTITIES_TAGS   = { "soil", "farm_debris", "farm_plant", "weed" }


local function GetSoilMoisture(x, y, z)
    local function GetUpValue(func, varname)
        local i = 1
        local n, v = debug.getupvalue(func, 1)
        while v ~= nil do
            if n == varname then
                return v
            end
            i = i + 1
            n, v = debug.getupvalue(func, i)
        end
    end

    local _overlaygrid = GetUpValue(TheWorld.components.farming_manager.AddSoilMoistureAtPoint, "_overlaygrid")
    local _moisturegrid = GetUpValue(TheWorld.components.farming_manager.AddSoilMoistureAtPoint, "_moisturegrid")
    local _x, _y = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
    local index = _overlaygrid:GetIndex(_x, _y)
    return _moisturegrid:GetDataAtIndex(index)
end

local function GetFaceTargetFn(inst)
    if inst.components.timer:TimerExists("dontfacetime") then
        return nil
    end
    local shouldface = inst.components.follower.leader or FindClosestPlayerToInst(inst, SEE_PLAYER_DIST, true)
    if shouldface and not inst.components.timer:TimerExists("facetime") then
        inst.components.timer:StartTimer("facetime", FACETIME_BASE + math.random() * FACETIME_RAND)
    end
    return shouldface
end

local function KeepFaceTargetFn(inst, target)
    if inst.components.timer:TimerExists("dontfacetime") then
        return nil
    end
    local keepface = (inst.components.follower.leader and inst.components.follower.leader == target) or
        (target:IsValid() and inst:IsNear(target, SEE_PLAYER_DIST))
    if not keepface then
        inst.components.timer:StopTimer("facetime")
    end
    return keepface
end

local function ChooseFertilizer(fertilizers, soil_nutrients)
    for _, fertilizer in ipairs(fertilizers) do
        local c, f, m = unpack(fertilizer.components.fertilizer.nutrients)
        local sc, sf, sm = unpack(soil_nutrients)

        if c > 0 and f > 0 and m > 0 then
            if sc <= 100 - c and sf <= 100 - f and sm <= 100 - m then return fertilizer end
        end

        if c > 0 and f == 0 and m == 0 and sc <= 100 - c then return fertilizer end
        if f > 0 and c == 0 and m == 0 and sf <= 100 - f then return fertilizer end
        if m > 0 and c == 0 and f == 0 and sm <= 100 - m then return fertilizer end
    end
end

local function HasCollectedHarvestToStore(inst)
    return not inst.components.container:IsEmpty()
end

local function HasWateringCan(inst)
    return inst:GetWateringCan() ~= nil
end
local function WateringCanNeedsFilling(inst)
    local wateringcan = inst:GetWateringCan()
    if wateringcan == nil then return false end

    local finiteuses = wateringcan.components.finiteuses

    return finiteuses:GetUses() < finiteuses.total / 2
end

local function HasTool(inst)
    return inst:GetTool() ~= nil
end

local function NeedsTool(inst)
    return inst:GetTool() == nil
end

local function NeedsBlueprint(inst)
    return inst:GetFarmBlueprint() == nil
end

local function GetClosestToolShed(inst, dist)
    dist = dist or FIND_SHED_RANGE

    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, dist, nil, nil, TOOLSHED_ONEOF_TAGS)

    if #ents <= 0 then
        return nil
    end

    local shed = nil

    for _, ent in ipairs(ents) do
        if ent:CanSupply() then
            if ent:HasTag("merm_toolshed_upgraded") then
                return ent -- High priority.
            end

            if shed == nil then
                shed = ent
            end
        end
    end

    return shed
end

local function NeedsToolAndFoundTool(inst)
    if not NeedsTool(inst) then
        return false
    end
    return GetClosestToolShed(inst) ~= nil
end


local function GetClosestToolShedPosition(inst, dist)
    local shed = GetClosestToolShed(inst, dist)

    if shed ~= nil then
        local distance = shed:GetPhysicsRadius(0)

        return inst:GetPositionAdjacentTo(shed, distance)
    end
end

local function GetNoLeaderHomePos(inst)
    if inst.components.follower and inst.components.follower.leader ~= nil then
        return nil
    else
        return inst.components.knownlocations:GetLocation("home")
    end
end

local function IterateAndDoActionNode(self, parameters)
    local name = parameters.name
    local starter = parameters.starter
    local action = parameters.action
    local run = parameters.run
    local iterator = {}

    local function ifnode()
        return starter(self.inst, iterator)
    end
    local function whilenode()
        return #iterator > 0
    end
    local function findnode()
        return action(self.inst, iterator)
    end
    local looper
    if parameters.chatterstring then
        looper = LoopNode { ConditionNode(whilenode), ChattyNode(self.inst, parameters.chatterstring, DoAction(self.inst, findnode, "DoAction_Chatty", run, 10)) }
    else
        looper = LoopNode { ConditionNode(whilenode), DoAction(self.inst, findnode, "DoAction_NoChatty", run, 10) }
    end

    local IteratorNode = IfThenDoWhileNode(ifnode, whilenode, name, looper)

    function IteratorNode:ClearIterator() iterator = {} end

    return IteratorNode
end

local function SortTiles(tiles)
    local sorted_tiles = {}

    for _, tile in pairs(tiles) do
        table.insert(sorted_tiles, tile)
    end

    table.sort(sorted_tiles, function(a, b) return a.x < b.x end)

    return sorted_tiles
end

local function SortSlots(slots)
    return slots
end

local function GetRegisteredFarmTiles(inst)
    return SortTiles(inst:GetFarmBlueprint().components.mermexp_mermfarmblueprint:GetRegisteredFarmTiles())
end

local function IsInSlot(target, slots)
    local tx, _, tz = target.Transform:GetWorldPosition()
    for _, slot in pairs(slots) do
        local sx, sz = slot.x, slot.z
        local range = 0.21

        if sx - range <= tx and tx <= sx + range and sz - range <= tz and tz <= sz + range then
            return slot
        end
    end
    return nil
end

local Fillers = {
    PlantsToHammer = function(inst, iterator)
        if inst:GetFarmBlueprint() == nil then return false end
        local tiles = GetRegisteredFarmTiles(inst)

        for _, tile in orderedPairs(tiles) do
            local targets = TheSim:FindEntities(tile.x, tile.y, tile.z, 2.65, { "oversized_veggie" })
            for _, target in ipairs(targets) do
                table.insert(iterator, target)
            end
        end

        return #iterator > 0
    end,
    UnwantedEntities = function(inst, iterator)
        if inst:GetFarmBlueprint() == nil or not HasTool(inst) then return false end
        local tiles = GetRegisteredFarmTiles(inst)

        for _, tile in orderedPairs(tiles) do
            local targets = TheSim:FindEntities(tile.x, tile.y, tile.z, 2.65, nil, SOILMUST, FARM_ENTITIES_TAGS)

            for _, target in ipairs(targets) do
                local target_slot = IsInSlot(target, tile.slots)

                local assigned_plant = (target_slot ~= nil and target_slot.assigned_plant ~= nil) and
                    target_slot.assigned_plant.name:gsub("_seeds", "") or nil

                local is_wrong_plant = assigned_plant == nil or
                    (not target.prefab:find(assigned_plant) and target.prefab ~= "farm_plant_randomseed")

                local is_rotten_plant = target:HasTag("farm_plant_killjoy")
                local is_debris = target.prefab == "farm_soil_debris"

                if target_slot == nil or is_debris or is_wrong_plant or is_rotten_plant then
                    table.insert(iterator, target)
                end
            end
        end

        return #iterator > 0
    end,
    SpotsToTill = function(inst, iterator)
        if inst:GetFarmBlueprint() == nil or not HasTool(inst) then return false end
        local tiles = GetRegisteredFarmTiles(inst)

        for _, tile in orderedPairs(tiles) do
            for _, slot in pairs(SortSlots(tile.slots)) do
                local pos = Vector3(slot.x, slot.y, slot.z)
                local localsoils = TheSim:FindEntities(pos.x, pos.y, pos.z, 0.21, SOILMUST, SOILMUSTNOT)

                if #localsoils < 1 and TheWorld.Map:CanTillSoilAtPoint(pos:Get()) then
                    table.insert(iterator, pos)
                end
            end
        end

        return #iterator > 0
    end,
    SoilsToPlant = function(inst, iterator)
        if inst:GetFarmBlueprint() == nil then return false end
        local tiles = GetRegisteredFarmTiles(inst)
        local home = inst.components.homeseeker.home
        local container = home.components.container

        for _, tile in orderedPairs(tiles) do
            for _, slot in pairs(SortSlots(tile.slots)) do
                local localsoils = TheSim:FindEntities(slot.x, slot.y, slot.z, 0.21, SOILMUST, SOILMUSTNOT)
                local localplants = TheSim:FindEntities(slot.x, slot.y, slot.z, 0.21, nil, nil, FARM_PLANT_TAGS)

                local home_has_seeds = slot.assigned_plant ~= nil and
                    (container:Has(slot.assigned_plant.name, 1) or container:Has("seeds", 1))

                if #localsoils > 0 and #localplants < 1 and home_has_seeds then
                    table.insert(iterator, { localsoils[1], slot.assigned_plant })
                end
            end
        end

        return #iterator > 0
    end,
    PlantsToHarvest = function(inst, iterator)
        if inst:GetFarmBlueprint() == nil or not HasTool(inst) then return false end
        local tiles = GetRegisteredFarmTiles(inst)

        for _, tile in orderedPairs(tiles) do
            for _, slot in pairs(SortSlots(tile.slots)) do
                local pos = Vector3(slot.x, slot.y, slot.z)
                local localplants = TheSim:FindEntities(pos.x, pos.y, pos.z, 0.21, nil, nil, FARM_PLANT_TAGS)

                if #localplants > 0 and localplants[1].components.inspectable:GetStatus():find("FULL") then
                    table.insert(iterator, localplants[1])
                end
            end
        end
        return #iterator > 0
    end,
    TilesToFertilize = function(inst, iterator)
        if inst:GetFarmBlueprint() == nil then return false end
        local tiles = GetRegisteredFarmTiles(inst)

        for _, tile in orderedPairs(tiles) do
            local x, z = TheWorld.Map:GetTileCoordsAtPoint(tile.x, tile.y, tile.z)
            local formula, compost, manure = TheWorld.components.farming_manager:GetTileNutrients(x, z)
            local target = { x = tile.x, y = tile.y, z = tile.z, nutrients = { formula, compost, manure } }

            if target.nutrients[1] <= 92 or target.nutrients[2] <= 92 or target.nutrients[3] <= 92 then
                table.insert(iterator, target)
            end
        end

        return #iterator > 0
    end,
    TilesToWater = function(inst, iterator)
        if inst:GetFarmBlueprint() == nil or not HasWateringCan(inst) then return false end

        local tiles = GetRegisteredFarmTiles(inst)

        for _, tile in orderedPairs(tiles) do
            if GetSoilMoisture(tile.x, tile.y, tile.z) <= 75 then table.insert(iterator, tile) end
        end

        return #iterator > 0
    end,
    PlantsToTend = function(inst, iterator)
        if inst:GetFarmBlueprint() == nil then return false end
        local tiles = GetRegisteredFarmTiles(inst)

        for _, tile in orderedPairs(tiles) do
            for _, slot in pairs(SortSlots(tile.slots)) do
                if slot.assigned_plant and not slot.assigned_plant.prefab:find("weed") then
                    local localplants = TheSim:FindEntities(slot.x, slot.y, slot.z, 0.21, nil, nil, FARM_PLANT_TAGS)

                    if #localplants > 0 and localplants[1].components.farmplanttendable.tendable then
                        if localplants[1].prefab ~= "farm_plant_randomseed" then
                            table.insert(iterator, localplants[1])
                        end
                    end
                end
            end
        end

        return #iterator > 0
    end,
    HarvestedPlants = function(inst, iterator)
        if inst:GetFarmBlueprint() == nil then return false end
        local tiles = GetRegisteredFarmTiles(inst)
        local container = inst:GetHome().components.container

        for _, tile in orderedPairs(tiles) do
            local targets = TheSim:FindEntities(tile.x, tile.y, tile.z, 4, nil, nil, {
                "edible_VEGGIE", "edible_SEEDS", "show_spoiled", "weed"
            })
            container.currentuser = inst
            for _, target in ipairs(targets) do
                if not target:IsInLimbo() and container:GetSpecificSlotForItem(target) then
                    table.insert(iterator, target)
                end
            end
            container.currentuser = nil
        end

        return #iterator > 0
    end
}

local Actions = {
    PickupTool = function(inst)
        if inst.sg:HasStateTag("busy") then
            return nil
        end

        if NeedsTool(inst) then
            local x, y, z = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, 0, z, FIND_SHED_RANGE, nil, MERM_TOOL_CANT_TAGS, MERM_TOOL_ONEOF_TAGS)

            if #ents <= 0 then
                return nil
            end

            local tool = nil
            local action = nil
            for _, ent in ipairs(ents) do
                if ent:HasTag("merm_tool_upgraded") then
                    inst:UnequipHands()
                    return BufferedAction(inst, ent, ACTIONS.PICKUP) -- High priority.
                end

                tool = ent
            end

            if tool ~= nil then
                inst:UnequipHands()
                return BufferedAction(inst, tool, ACTIONS.PICKUP)
            end
        end
    end,
    CollectTool = function(inst)
        if not NeedsTool(inst) then return end

        local shed = GetClosestToolShed(inst, 2.5)
        if shed ~= nil then
            inst:UnequipHands()
            inst:PushEvent("merm_use_building", { target = shed })
        end
    end,
    Hammer = function(inst, iterator)
        local target = table.remove(iterator, 1)
        return BufferedAction(inst, target, ACTIONS.HAMMER)
    end,
    Dig = function(inst, iterator)
        local target = table.remove(iterator, 1)
        inst:EquipTool()
        return BufferedAction(inst, target, ACTIONS.DIG)
    end,
    Till = function(inst, iterator)
        local pos = table.remove(iterator, 1)
        if pos then
            local tool = inst:EquipTool()

            SpawnPrefab("merm_soil_marker").Transform:SetPosition(pos.x, pos.y, pos.z)

            return BufferedAction(inst, nil, ACTIONS.TILL, tool, pos)
        end
    end,
    Plant = function(inst, iterator)
        local target, assigned_plant = unpack(table.remove(iterator, 1))
        local seed = inst:FetchSeeds(assigned_plant.name, true)
        if seed == nil then seed = inst:FetchSeeds("seeds", true) end

        if seed ~= nil then
            inst:UnequipHands()
            return BufferedAction(inst, target, ACTIONS.PLANTSOIL, seed)
        end
    end,
    Harvest = function(inst, iterator)
        local target = table.remove(iterator, 1)

        if target.components.inspectable:GetStatus():find("FULL") then
            inst:EquipTool()
            return BufferedAction(inst, target, ACTIONS.MERMFARMER_PICK)
        end
    end,
    Fertilize = function(inst, iterator)
        local target = table.remove(iterator, 1)
        local pos = Vector3(target.x, target.y, target.z)
        local fertilizer = ChooseFertilizer(inst:GetHome():GetFertilizers(), target.nutrients)

        if fertilizer then
            inst:UnequipHands()
            return BufferedAction(inst, nil, ACTIONS.DEPLOY, fertilizer, pos)
        end
    end,
    FillWateringCan = function(inst)
        if HasWateringCan(inst) and WateringCanNeedsFilling(inst) then
            local watering_can = inst:EquipWateringCan()
            if watering_can ~= nil then
                return BufferedAction(inst, inst:GetHome(), ACTIONS.MERMHOUSE_FARMER_FILL_CAN, watering_can)
            end
        end
    end,
    WaterTile = function(inst, iterator)
        local target = table.remove(iterator, 1)
        local watering_can = inst:EquipWateringCan()

        if watering_can ~= nil then
            local pos = Vector3(target.x, target.y, target.z)

            return BufferedAction(inst, nil, ACTIONS.POUR_WATER, watering_can, pos)
        end
    end,
    Tend = function(inst, iterator)
        local target = table.remove(iterator, 1)

        inst:UnequipHands()
        return BufferedAction(inst, target, ACTIONS.INTERACT_WITH)
    end,
    Collect = function(inst, iterator)
        local target = table.remove(iterator, 1)
        inst:UnequipHands()
        return BufferedAction(inst, target, ACTIONS.MERMFARMER_PICKUP)
    end,
    Store = function(inst)
        if HasCollectedHarvestToStore(inst) then
            inst:UnequipHands()
            return BufferedAction(inst, inst:GetHome(), ACTIONS.MERMFARMER_DUMP_INVENTORY)
        end
    end,
    GoHome = function(inst)
        if inst.components.combat.target == nil then
            return
        end

        local home = inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
        local home_is_valid = home ~= nil and home:IsValid()
            and not (home.components.burnable ~= nil and home.components.burnable:IsBurning())
            and not home:HasTag("burnt")

        if home and home_is_valid then
            inst:UnequipHands()

            for k in pairs(inst.components.inventory.itemslots) do
                local item = inst.components.inventory:RemoveItemBySlot(k)
                if item then
                    home.components.container:GiveItem(item)
                end
            end

            if HasCollectedHarvestToStore(inst) then
                return BufferedAction(inst, inst:GetHome(), ACTIONS.MERMFARMER_DUMP_INVENTORY)
            end

            return BufferedAction(inst, home, ACTIONS.GOHOME)
        end
    end
}


local MermBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function MermBrain:OnStart()
    local FleeFromCombat = DoAction(self.inst, Actions.GoHome, "Flee", true)

    local PickupToolFromGround = DoAction(self.inst, Actions.PickupTool, "collect tool", true)
    local CollectToolFromShed = IfNode(function() return NeedsToolAndFoundTool(self.inst) end, "needs a tool",
        PriorityNode({
            Leash(self.inst, GetClosestToolShedPosition, 2.1, 2, true),
            DoAction(self.inst, Actions.CollectTool, "collect tool", true),
        }, 0.25)
    )

    local StoreHarvest = DoAction(self.inst, Actions.Store, "STORE_HARVEST", true)
    local FillWateringCan = DoAction(self.inst, Actions.FillWateringCan, "FILL_WATERINGCAN", true)

    local IteratorNodes = {
        Clear = function(self)
            print("clearing iterators")
            for _, iterator_node in pairs(self) do
                if type(iterator_node) ~= "function" then iterator_node:ClearIterator() end
            end
        end,
        HammerOversized = IterateAndDoActionNode(self, {
            name = "HAMMER_OVERSIZED_PLANTS",
            starter = Fillers.PlantsToHammer,
            action = Actions.Hammer,
            run = true
        }),
        DigUnwanted = IterateAndDoActionNode(self, {
            name = "DIG_UNWANTED", -- Required.
            chatterstring = "MERM_TALK_HELP_TILL",
            starter = Fillers.UnwantedEntities,
            action = Actions.Dig,
            run = true
        }),
        Harvest = IterateAndDoActionNode(self, {
            name = "HARVEST", -- Required.
            starter = Fillers.PlantsToHarvest,
            action = Actions.Harvest,
            run = true
        }),
        CollectHarvest = IterateAndDoActionNode(self, {
            name = "COLLECT_HARVEST", -- Required.
            starter = Fillers.HarvestedPlants,
            action = Actions.Collect,
            run = true
        }),
        Plant = IterateAndDoActionNode(self, {
            name = "PLANT", -- Required.
            starter = Fillers.SoilsToPlant,
            action = Actions.Plant,
            run = true
        }),
        Till = IterateAndDoActionNode(self, {
            name = "TILL", -- Required.
            chatterstring = "MERM_TALK_HELP_TILL",
            starter = Fillers.SpotsToTill,
            action = Actions.Till,
            run = true
        }),
        Fertilize = IterateAndDoActionNode(self, {
            name = "FERTILIZE", -- Required.
            starter = Fillers.TilesToFertilize,
            action = Actions.Fertilize,
            run = true
        }),
        WaterTile = IterateAndDoActionNode(self, {
            name = "WATER_TILES", -- Required.
            starter = Fillers.TilesToWater,
            action = Actions.WaterTile,
            run = true
        }),
        Tend = IterateAndDoActionNode(self, {
            name = "TEND", -- Required.
            starter = Fillers.PlantsToTend,
            action = Actions.Tend,
            run = true
        }),
    }

    local ClearIterators = DoAction(self.inst, function() IteratorNodes:Clear() end, "ClearIterators")
    local IfNoBlueprint = IfNode(function() return NeedsBlueprint(self.inst) end, "IfNoBlueprint", PriorityNode {
        ClearIterators,
        Wander(self.inst, GetNoLeaderHomePos, MAX_WANDER_DIST)
    })

    local root = PriorityNode({
        BrainCommon.PanicTrigger(self.inst),
        FleeFromCombat,
        IfNoBlueprint,
        PickupToolFromGround,
        CollectToolFromShed,
        IteratorNodes.HammerOversized,
        IteratorNodes.DigUnwanted,
        IteratorNodes.Harvest,
        IteratorNodes.CollectHarvest,
        IteratorNodes.Till,
        IteratorNodes.Plant,
        StoreHarvest,
        IteratorNodes.Fertilize,
        FillWateringCan,
        IteratorNodes.WaterTile,
        IteratorNodes.Tend,
        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
        Wander(self.inst, GetNoLeaderHomePos, MAX_WANDER_DIST)
    }, .2)

    self.bt = BT(self.inst, root)
end

return MermBrain

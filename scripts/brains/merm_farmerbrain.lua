require "behaviours/wander"
require "behaviours/leash"
require "behaviours/standstill"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/panic"

local STOP_RUN_DIST = 10
local SEE_PLAYER_DIST = 5
local SEE_FOOD_DIST = 15
local near = 20
local SEE_BUSH_DIST = 28
local SEE_SHRINE_DIST = 30
local MIN_SHRINE_WANDER_DIST = 4
local MAX_SHRINE_WANDER_DIST = 15
local MAX_WANDER_DIST = 20
local SHRINE_LOITER_TIME = 4
local SHRINE_LOITER_TIME_VAR = 3
local LEASH_RETURN_DIST = 10
local LEASH_MAX_DIST = 20

local COOLING_TIME = 5 -- 说话冷却时间


local harvest_product = {
    "carrot",
    "watermelon",
    "dragonfruit",
    "corn",
    "eggplant",
    "durian",
    "pumpkin",
    "pomegranate",
    "forgetmelots",
    "tillweed",
    "firenettles",
    "tomato",
    "potato",
    "onion",
    "garlic",
    "pepper",
    "asparagus"
}

local excludes = { "INLIMBO", "burnt", "oldfish_farmer", "oldfish_farmhome", "playerghost", "animal", "player", "spider" }

local function changeEquipment(inst, item)
    if inst.components.inventory ~= nil then
        local equipitem = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if equipitem == nil or equipitem.prefab ~= item then
            if equipitem ~= nil then
                inst.components.inventory:Unequip(EQUIPSLOTS.HANDS)
                inst.components.inventory:RemoveItem(equipitem)
            end
            local temp = SpawnPrefab(item)
            inst.components.inventory:Equip(temp)
        end
    end
end

local function speak(inst, content)
    if inst.isSpeak == false then
        inst.isSpeak = true
        inst.components.talker:Say(content)
        inst:DoTaskInTime(COOLING_TIME, function(inst)
            inst.isSpeak = false
        end)
    end
end

local function findHome(inst)
    if inst.myHome == nil
        or not inst.myHome:IsValid()
        or not inst.myHome:IsNear(inst, SEE_SHRINE_DIST)
        or (inst.myHome.components.burnable ~= nil
            and inst.myHome.components.burnable:IsBurning()
            or inst.myHome:HasTag("burnt")) then
        local x, y, z = inst.Transform:GetWorldPosition()
        inst.myHome = TheSim:FindEntities(x, y, z, SEE_SHRINE_DIST, { "oldfish_farmhome" }, { "burnt", "fire" })[1]
    end
    return inst.myHome
end

local farmerBrain = Class(Brain,
    function(self, inst)
        Brain._ctor(self, inst)
    end)


local function IsHarvestProduct(item, inst)
    -- if not findHome(inst) then
    --     return
    -- end

    -- if not item:IsNear(inst.myHome, near) then
    --     return false
    -- end

    for i, v in ipairs(harvest_product) do
        if v == item.prefab then
            return true
        end
    end

    if item.prefab ~= nil then
        return string.find(item.prefab, "_seeds") ~= nil
    end

    return false
end

local function hasFarm(item, inst)
    if not findHome(inst) then
        return
    end

    if not item:IsNear(inst.myHome, near) then
        return
    end
    return item.prefab == "slow_farmplot"
        or item.prefab == "fast_farmplot"
end

local function hasMushroomFarm(item, inst)
    if not findHome(inst) then
        return
    end

    if not item:IsNear(inst.myHome, near) then
        return
    end
    return item.prefab == "mushroom_farm"
end

local function hateWeeds(item, inst)
    if not findHome(inst) then
        return
    end

    if not item:IsNear(inst.myHome, near) then
        return
    end

    return item.prefab == "weed_ivy"
        or item.prefab == "farm_soil_debris"
end



local function isfiresuppressor(item, inst)
    if not findHome(inst) then
        return
    end

    if not item:IsNear(inst.myHome, near) then
        return
    end
    return item.prefab == "firesuppressor"
end

local function needActivation(item, inst)
    if not findHome(inst) then
        return
    end

    if not item:IsNear(inst.myHome, near) then
        return
    end
    return item.prefab == "berrybush"
        or item.prefab == "grass"
        or item.prefab == "berrybush2"
        or item.prefab == "berrybush_juicy"
        or item.prefab == "rock_avocado_bush"
        or item.prefab == "lilybush"
        or item.prefab == "rosebush"
        or item.prefab == "orchidbush"
end

local function pickUpAction(inst)
    if inst.components.container:IsFull() then
        speak(inst, STRINGS.CONTAINER_FULL)
        return
    end

    -- if inst.myHome == nil then
    --     return
    -- end
    local target = FindEntity(inst, SEE_BUSH_DIST, IsHarvestProduct, nil, excludes)
    return target ~= nil and BufferedAction(inst, target, ACTIONS.PICKUP) or nil
end

local function isWeeds(inst)
    if inst.myHome == nil then
        return
    end

    local target = FindEntity(inst, SEE_BUSH_DIST, hateWeeds, nil, excludes)
    if target then
        changeEquipment(inst, "goldenshovel")
        return BufferedAction(inst, target, ACTIONS.DIG)
    end
end


local function hasMeatrock(item, inst)
    if not findHome(inst) then
        return
    end

    if not item:IsNear(inst.myHome, near) then
        return
    end
    return item.prefab == "meatrack"
end

local function hasSoil(item, inst)
    if not findHome(inst) then
        return
    end

    if not item:IsNear(inst.myHome, near) then
        return
    end
    return item.prefab == "farm_soil"
end

local function isSoil(inst)
    if inst.myHome == nil then
        return
    end

    local target = FindEntity(inst, SEE_BUSH_DIST, hasSoil, nil, excludes)
    if target and not target:HasTag("NOBLOCK") then
        local seends = inst.components.container:FindItem(function(v)
            return string.find(v.prefab, "_seeds") ~= nil
                and v.components.deployable ~= nil
                and v.components.deployable.ondeploy ~= nil
                and v.components.deployable.mode == DEPLOYMODE.CUSTOM
        end)
        if seends == nil then
            speak(inst, STRINGS.PLANT_NOTIFICATION)
        else
            return BufferedAction(inst, target, ACTIONS.PLANTSOIL, seends)
        end
    end
end


local function canPlant(inst)
    if inst.myHome == nil then
        return
    end

    -- local meatrack = FindEntity(inst, SEE_BUSH_DIST, hasMeatrock, { "oldfish_meatrack" }, excludes)
    -- if meatrack
    --     and meatrack.prefab == "meatrack"
    --     and meatrack.components.dryer ~= nil then
    --     local seends = inst.components.container:FindItem(function(v)
    --         return v.components.dryable ~= nil
    --     end)
    --     if seends and meatrack.components.dryer:CanDry(seends) then
    --         return BufferedAction(inst, meatrack, ACTIONS.DRY, seends)
    --     end
    -- end

    -- local target = FindEntity(inst, SEE_BUSH_DIST, hasFarm, { "structure" }, excludes)
    -- if target and target.components.grower ~= nil then
    --     if target.components.crop then
    --         if target.components.crop.onwithered == nil then
    --             return
    --         end
    --     end



    --     if target.prefab == "slow_farmplot" or target.prefab == "fast_farmplot" then
    --         if target.components.grower:GetFertilePercent() < 0.5 then
    --             local seends = inst.components.container:FindItem(function(v)
    --                 return v.prefab == "poop"
    --                     or v.prefab == "spoiled_food"
    --                     or v.prefab == "guano"
    --                     or v.prefab == "rottenegg"
    --                     or v.prefab == "fertilizer"
    --                     or v.prefab == "compost"
    --             end)
    --             if seends == nil then
    --                 speak(inst, STRINGS.FERTILIZER_NOTIFICATION)
    --             else
    --                 return BufferedAction(inst, target, ACTIONS.AUTO_FERTILIZE, seends)
    --             end
    --         end

    --         if target.components.grower:IsEmpty() then
    --             if TheWorld.state.iswinter then
    --                 return
    --             end

    --             local seends = inst.components.container:FindItem(function(v)
    --                 return string.find(v.prefab, "seeds") ~= nil
    --                     and v.components.deployable ~= nil
    --                     and v.components.deployable.ondeploy ~= nil
    --                     and v.components.deployable.mode == DEPLOYMODE.CUSTOM
    --             end)
    --             if seends == nil then
    --                 speak(inst, STRINGS.PLANT_NOTIFICATION)
    --             else
    --                 return BufferedAction(inst, target, ACTIONS.AUTO_PLANT, seends)
    --             end
    --         end
    --     end
    -- end


    local target = FindEntity(inst, SEE_BUSH_DIST, hasMushroomFarm, { "oldfish_mushroom_farm" }, excludes)
    if target and target.components.harvestable and target.components.harvestable.produce == 0 then
        if target.prefab == "mushroom_farm" then
            local seends
            if target.remainingharvests == 0 then
                seends = inst.components.container:FindItem(function(v)
                    return v.prefab == "livinglog"
                        or v.prefab == "shyerrylog"
                end)
                if seends == nil then
                    speak(inst, STRINGS.ACTIVATE_MUSHROOM)
                end
            else
                seends = inst.components.container:FindItem(function(v)
                    return v.prefab == "blue_cap"
                        or v.prefab == "green_cap"
                        or v.prefab == "red_cap"
                        or v.prefab == "spore_small"
                        or v.prefab == "spore_medium"
                        or v.prefab == "spore_tall"
                        or v.prefab == "albicans_cap"
                end)
            end
            if seends then
                if TheWorld.state.iswinter then
                    return
                end
                return BufferedAction(inst, target, ACTIONS.GIVE, seends)
            end
        end
    end
end

local function needFertilize(inst)
    if inst.myHome == nil then
        return
    end

    -- local target = FindEntity(inst, SEE_BUSH_DIST, isfiresuppressor, { "oldfish_firesuppressor" }, excludes)
    -- if target then
    --     if target.prefab == "firesuppressor" then
    --         if target.components.fueled ~= nil
    --             and target.components.fueled.currentfuel / target.components.fueled.maxfuel < 0.5 then
    --             local seends = inst.components.container:FindItem(function(v)
    --                 return v.components.fuel ~= nil
    --                     and (v.prefab == "log"
    --                         or v.prefab == "twigs"
    --                         or v.prefab == "poop"
    --                         or v.prefab == "cutgrass"
    --                         or v.prefab == "spoiled_food")
    --             end)
    --             if seends == nil then
    --                 speak(inst, STRINGS.FIRESUPPRESSOR_FUEL)
    --             else
    --                 return BufferedAction(inst, target, ACTIONS.ADDFUEL, seends)
    --             end
    --         end
    --     end
    -- end

    local target = FindEntity(inst, SEE_BUSH_DIST, needActivation, { "plant" }, excludes)
    if target and target.components.pickable ~= nil and target.components.pickable:CanBeFertilized() then
        local seends = inst.components.container:FindItem(function(v)
            return v.prefab == "poop"
                or v.prefab == "spoiled_food"
                or v.prefab == "guano"
                or v.prefab == "rottenegg"
                or v.prefab == "fertilizer"
                or v.prefab == "compost"
        end)
        if seends then
            return BufferedAction(inst, target, ACTIONS.AUTO_FERTILIZE, seends)
        end
    end
end

local function HasValidHome(inst)
    local home = inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
    return home ~= nil
        and home:IsValid()
        and not (home.components.burnable ~= nil and home.components.burnable:IsBurning())
        and not home:HasTag("burnt")
end

local function goHomeAction(inst)
    if HasValidHome(inst) then
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME)
    end
end

local function GetHomePos(inst)
    return HasValidHome(inst) and inst.components.homeseeker:GetHomePos()
end

local function getNoLeaderHomePos(inst)
    return GetHomePos(inst)
end

local function goToPlant(inst)
    if not findHome(inst) then
        return
    end

    local plant_roots = {

        ["dug_berrybush"] = 2,
        ["dug_berrybush2"] = 2,
        ["dug_berrybush_juicy"] = 2,
        ["dug_rock_avocado_bush"] = 2,
        ["rock_avocado_fruit_sprout"] = 2,
        ["pinecone"] = 2,
        ["twiggy_nut"] = 2,
        ["acorn"] = 2,
        ["marblebean"] = 2,
        ["moonbutterfly"] = 2,
        ["bigpeach"] = 2,
        ["cutted_lilybush"] = 2,
        ["cutted_rosebush"] = 2,
        ["dug_lilybush"] = 2,
        ["dug_rosebush"] = 2,
        ["miao_packbox_full"] = 2,
        ["palmcone_seed"] = 2,
    }
    local plant_root = inst.components.container
        and inst.components.container:FindItem(function(item)
            if plant_roots[item.prefab] then
                return item
            end
        end)

    local home_pos = inst.myHome:GetPosition()
    local plant_pos = { home_pos.x, home_pos.z }
    local can_plant = {
        {
            ["sta"] = { -10, -10 },
            ["end"] = { 10, -6 },
            ["pad"] = { 1, 1 },
            cnd = function(a, b) return a < b end
        },
        {
            ["sta"] = { 9, 9 },
            ["end"] = { -9, -9 },
            ["pad"] = { -2, -2 },
            cnd = function(a, b) return a > b end
        }
    }
    if plant_root and plant_root.components.deployable then
        local size = plant_roots[plant_root.prefab]
        plant_pos[1] = plant_pos[1] + can_plant[size]["sta"][1]
        plant_pos[2] = plant_pos[2] + can_plant[size]["sta"][2]
        while not plant_root.components.deployable:CanDeploy(Vector3(plant_pos[1], 0, plant_pos[2])) do
            if can_plant[size].cnd(plant_pos[1], home_pos.x + can_plant[size]["end"][1]) then
                plant_pos[1] = plant_pos[1] + can_plant[size]["pad"][1]
            else
                plant_pos[1] = home_pos.x + can_plant[size]["sta"][1]
                if can_plant[size].cnd(plant_pos[2], home_pos.z + can_plant[size]["end"][2]) then
                    plant_pos[2] = plant_pos[2] + can_plant[size]["pad"][2]
                else
                    plant_pos = nil
                    break
                end
            end
        end
    end
    if plant_root and plant_pos then
        return BufferedAction(inst, nil, ACTIONS.AUTO_FARM_PLANT, plant_root, Vector3(plant_pos[1], 0, plant_pos[2]))
    end
end

function farmerBrain:OnStart()
    local root = PriorityNode({
        WhileNode(
            function() return self.inst.components.health.takingfiredamage or self.inst.components.hauntable.panic end,
            "Panic", Panic(self.inst)),
        -- IfNode(function() return self.inst.myHome or findHome(self.inst) end, "find home",
        -- WhileNode(function()
        --         return self.inst.myHome
        --     end, "approach home",
        PriorityNode({
            -- EventNode(self.inst, "gohome", DoAction(self.inst, goHomeAction, "go home", true)),
            -- DoAction(self.inst, isWeeds, "is weeds", true),
            -- DoAction(self.inst, isSoil, "is soil", true),
            -- DoAction(self.inst, needFertilize, "need fertilize", true),
            -- DoAction(self.inst, canPlant, "can plant", true),
            DoAction(self.inst, pickUpAction, "pick up", true),
            -- DoAction(self.inst, goToPlant, "plannt pos", true),
            -- Leash(self.inst, getNoLeaderHomePos, MAX_SHRINE_WANDER_DIST, MIN_SHRINE_WANDER_DIST),
            Wander(self.inst, getNoLeaderHomePos, MAX_SHRINE_WANDER_DIST - MIN_SHRINE_WANDER_DIST,
                { minwaittime = SHRINE_LOITER_TIME * .5, randwaittime = SHRINE_LOITER_TIME_VAR })
        }, .2)

        -- ),
        -- ),
        -- RunAway(self.inst, "hostile", SEE_PLAYER_DIST, STOP_RUN_DIST),
    }, .2)
    self.bt = BT(self.inst, root)
end

return farmerBrain

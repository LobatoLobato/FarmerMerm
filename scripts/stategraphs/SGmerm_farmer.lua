require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, "gohome"),
    ActionHandler(ACTIONS.PICK, "pickup"),
    ActionHandler(ACTIONS.PICKUP, "pickup"),
    ActionHandler(ACTIONS.HARVEST, "pickup"),
    ActionHandler(ACTIONS.PERDGIVE, "pickup"),
    ActionHandler(ACTIONS.AUTO_PLANT, "pickup"),
    ActionHandler(ACTIONS.PLANTSOIL, "pickup"),
    ActionHandler(ACTIONS.AUTO_FERTILIZE, "pickup"),
    ActionHandler(ACTIONS.DIG, function(inst)
        if not inst.sg:HasStateTag("predig") then
            return inst.sg:HasStateTag("digging") and "dig" or "dig_start"
        end
    end),
    ActionHandler(ACTIONS.AUTO_FARM_PLANT, "pickup"),
    ActionHandler(ACTIONS.FERTILIZE, "pickup"),
    ActionHandler(ACTIONS.DEPLOY, "pickup"),
    ActionHandler(ACTIONS.GIVE, "pickup"),
    ActionHandler(ACTIONS.DRY, "pickup"),
    ActionHandler(ACTIONS.ADDFUEL, "pickup"),
    ActionHandler(ACTIONS.TURNON, "pickup"),
    ActionHandler(ACTIONS.TURNOFF, "pickup"),
}

local events =
{
    CommonHandlers.OnStep(),
    CommonHandlers.OnLocomote(true, true),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    EventHandler("death", function(inst)
        inst.sg:GoToState("death")
    end),
    EventHandler("doattack", function(inst)
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("transform") then
            inst.sg:GoToState("attack")
        end
    end)
}

local states =
{

    State {
        name = "idle",
        tags = { "idle", "canrotate" },

        onenter = function(inst, pushanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_loop", true)
        end,
    },

    State {
        name = "run_start",
        tags = { "moving", "running", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("run_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("run")
                end
            end),
        },

        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/maxwell/shadowmax_step")
            end),
        },
    },

    State {
        name = "run",
        tags = { "moving", "running", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:RunForward()
            if not inst.AnimState:IsCurrentAnimation("run_loop") then
                inst.AnimState:PlayAnimation("run_loop", true)
            end
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/maxwell/shadowmax_step")
            end),
            TimeEvent(15 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/maxwell/shadowmax_step")
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("run")
        end,
    },

    State {
        name = "run_stop",
        tags = { "canrotate", "idle" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("run_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "walk_start",
        tags = { "moving", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.sg.mem.dash = inst.components.locomotor.walkspeed > TUNING.BEEGUARD_SPEED
            inst.AnimState:PlayAnimation("run_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("walk")
                end
            end),
        },
    },

    State {
        name = "walk",
        tags = { "moving", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.sg.mem.dash = inst.components.locomotor.walkspeed > TUNING.BEEGUARD_SPEED
            inst.AnimState:PlayAnimation("run_loop")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("walk")
                end
            end),
        },
    },

    State {
        name = "walk_stop",
        tags = { "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("run_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "open",
        tags = { "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
        end
    },

    State {
        name = "close",
        tags = { "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.sg:GoToState("idle")
        end,
    },

    State {
        name = "death",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("death")
            inst.components.locomotor:StopMoving()
            inst.components.lootdropper:DropLoot(inst:GetPosition())
            RemovePhysicsColliders(inst)
        end,
    },

    State {
        name = "appear",
        tags = { "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("appear")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State {
        name = "pickup",
        tags = { "busy" },
        onenter = function(inst)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("pickup")
        end,

        timeline =
        {
            TimeEvent(5 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },

        events =
        {
            EventHandler("animover",
                function(inst)
                    inst.sg:GoToState("idle")
                end),
        },
    },
}
CommonStates.AddSimpleActionState(states, "gohome", "hit", 4 * FRAMES, { "busy" })
return StateGraph("merm_farmer", states, events, "idle", actionhandlers)

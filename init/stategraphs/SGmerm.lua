local env = env
GLOBAL.setfenv(1, GLOBAL)

local function go_to_idle(inst)
  inst.sg:GoToState("idle")
end

local actionhandlers = {
  -- Farmer
  ActionHandler(ACTIONS.PLANTSOIL, "plant_soil"),
  ActionHandler(ACTIONS.INTERACT_WITH, "tend_plant"),
  ActionHandler(ACTIONS.DEPLOY, "pickup"),
  ActionHandler(ACTIONS.MERMHOUSE_FARMER_FILL_CAN, "fill_wateringcan"),
  ActionHandler(ACTIONS.POUR_WATER, "use_tool"),
  ActionHandler(ACTIONS.MERMFARMER_PICK, "use_tool"),
  ActionHandler(ACTIONS.MERMFARMER_PICKUP, "pickup"),
  ActionHandler(ACTIONS.MERMFARMER_DUMP_INVENTORY, "store")
}

local states = {
  State {
    name = "use_tool",
    tags = { "busy" },

    onenter = function(inst)
      inst.Physics:Stop()
      inst.AnimState:PlayAnimation("work")
    end,

    timeline = {
      TimeEvent(14 * FRAMES, function(inst)
        local act = inst:GetBufferedAction()
        local target = act.target
        local tool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

        if tool ~= nil and target ~= nil and target:IsValid() and target.components.workable ~= nil and target.components.workable:CanBeWorked() then
          target.components.workable:WorkedBy(inst, tool.components.tool:GetEffectiveness(act.action))
          tool:OnUsedAsItem(act.action, inst, target)
        end

        if target ~= nil and act.action == ACTIONS.MINE then
          PlayMiningFX(inst, target)
        end

        if target ~= nil and target:HasTag("stump") and act.action == ACTIONS.DIG then
          inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
        elseif target ~= nil and act.action == ACTIONS.DIG then
          inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
        end

        if act.action == ACTIONS.TILL or act.action == ACTIONS.MERMFARMER_PICK then
          inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
        end

        if act.action == ACTIONS.POUR_WATER then
          inst.SoundEmitter:PlaySound("farming/common/watering_can/use")
        end

        inst:PerformBufferedAction()
      end),
    },

    events = {
      EventHandler("animover", go_to_idle),
    },
  },
  State {
    name = "plant_soil",
    tags = { "busy" },

    onenter = function(inst)
      inst.Physics:Stop()
      inst.AnimState:PlayAnimation("pig_pickup")
    end,

    timeline = {
      TimeEvent(14 * FRAMES, function(inst) inst:PerformBufferedAction() end),
    },

    events = {
      EventHandler("animover", go_to_idle),
    },
  },

  State {
    name = "tend_plant",
    tags = { "busy" },

    onenter = function(inst)
      inst.Physics:Stop()
      inst.AnimState:PlayAnimation("sit")
      inst.AnimState:PushAnimation("sit_idle")
    end,

    timeline = {
      TimeEvent(14 * FRAMES, function(inst)
        inst:PerformBufferedAction()
        inst.AnimState:PushAnimation("sit_idle")
      end),
    },

    events = {
      EventHandler("animover", function(inst) inst.sg:GoToState("getup") end),
    },
  },

  State {
    name = "fill_wateringcan",
    tags = { "busy" },

    onenter = function(inst)
      inst.Physics:Stop()
      inst.AnimState:PlayAnimation("pig_take")
    end,

    timeline = {
      TimeEvent(14 * FRAMES, function(inst) inst:PerformBufferedAction() end),
    },

    events = {
      EventHandler("animover", go_to_idle),
    },
  },

  State {
    name = "store",
    tags = { "busy" },

    onenter = function(inst)
      inst.Physics:Stop()
      inst.AnimState:PlayAnimation("pig_take")
    end,

    timeline = {
      TimeEvent(14 * FRAMES, function(inst) inst:PerformBufferedAction() end),
    },

    events = {
      EventHandler("animover", go_to_idle),
    },
  },
}

local events = {}
for _, handler in ipairs(actionhandlers) do
  env.AddStategraphActionHandler("merm", handler)
end

for _, state in ipairs(states) do
  env.AddStategraphState("merm", state)
end

for _, event in ipairs(events) do
  env.AddStategraphEvent("merm", event)
end

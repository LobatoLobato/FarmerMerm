local CONSTANTS = require "mermexp.constants"
local _AddAction = AddAction
local _AddComponentAction = AddComponentAction

local function AddAction(id, str, fn, sghandler, data)
  local action = GLOBAL.Action(data)
  action.id = id
  action.str = str
  action.fn = fn

  _AddAction(action)

  if sghandler then
    AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(GLOBAL.ACTIONS[id], sghandler))
    AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(GLOBAL.ACTIONS[id], sghandler))
  end
end

---@type {id: string, right: boolean} | nil
local mermexp_compaction = nil
AddModRPCHandler(CONSTANTS.MOD_NAME, "addcomponentactiontoplayer", function(player, id, right)
  if player and player:IsValid() and not player:HasTag("playerghost") then
    player.mermexp_compaction = { id = id, right = right }
  end
end)

GLOBAL.TheInput:AddMouseButtonHandler(function(button, down)
  if mermexp_compaction == nil or not down then return end

  local is_leftclick, is_rightclick = button == GLOBAL.MOUSEBUTTON_LEFT, button == GLOBAL.MOUSEBUTTON_RIGHT
  local right = mermexp_compaction.right

  if (not right and is_leftclick) or (right and is_rightclick) then
    SendModRPCToServer(GetModRPC(CONSTANTS.MOD_NAME, "addcomponentactiontoplayer"), mermexp_compaction.id, right)
  end
end)

local function AddComponentAction(actiontype, component, fn, modname)
  local fn = function(...)
    local args = { ... }
    local actions_pos = (actiontype == "SCENE" or actiontype == "INVENTORY") and 3 or 4
    local doer, actions, right = args[2], table.remove(args, actions_pos), args[actions_pos]

    if GLOBAL.TheNet:IsDedicated() then
      if doer.mermexp_compaction and doer.mermexp_compaction.right == right then
        table.insert(actions, GLOBAL.ACTIONS[doer.mermexp_compaction.id])
        doer.mermexp_compaction = nil
      end

      return
    end

    local action = fn(GLOBAL.unpack(args))

    if action ~= nil then
      table.insert(actions, GLOBAL.ACTIONS[action])
      mermexp_compaction = { id = action, right = right }
    end
  end
  _AddComponentAction(actiontype, component, fn, modname)
end

AddAction("REGISTER_SOIL", "Register Soil Tile", function(act)
  if act.invobject ~= nil then
    return act.invobject.components.mermexp_mermfarmblueprint:RegisterFarmTile(act:GetActionPoint():Get())
  end
end, "dolongaction", { tile_placer = "gridplacer" })

AddAction("REGISTER_SOIL_CAPTURING", "Register Soil Tile (Capture Layout)", function(act)
  if act.invobject ~= nil then
    local pt = act:GetActionPoint()
    return act.invobject.components.mermexp_mermfarmblueprint:RegisterFarmTile(pt.x, pt.y, pt.z, true)
  end
end, "dolongaction", { tile_placer = "gridplacer" })

AddAction("UNREGISTER_SOIL", "Unregister Soil Tile", function(act)
  if act.invobject ~= nil then
    return act.invobject.components.mermexp_mermfarmblueprint:UnregisterFarmTile(act:GetActionPoint():Get())
  end
end, "dolongaction", { tile_placer = "gridplacer" })

AddComponentAction("POINT", "mermexp_mermfarmblueprint", function(inst, _, pos, right)
  local isfarmablesoil = GLOBAL.TheWorld.Map:GetTileAtPoint(pos:Get()) == WORLD_TILES.FARMING_SOIL
  if right and isfarmablesoil then
    if inst.replica.mermexp_mermfarmblueprint:IsRegisteredFarmTile(pos:Get()) then
      return "UNREGISTER_SOIL"
    elseif GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_ALT) then
      return "REGISTER_SOIL_CAPTURING"
    else
      return "REGISTER_SOIL"
    end
  end
end)

AddAction("MERMHOUSE_FARMER_FILL", "Fill Water Reservoir", function(act)
  if act.invobject ~= nil and act.target ~= nil and act.target:HasTag("mermhouse_farmer") then
    return act.target.components.mermexp_waterreservoir:AddWater(act.doer, act.invobject)
  end
end, "domediumaction")

AddAction("MERMHOUSE_FARMER_FILL_CAN", "Fill Can", function(act)
  if act.invobject ~= nil and act.target ~= nil and act.target:HasTag("mermhouse_farmer") then
    return act.target.components.mermexp_waterreservoir:FillCan(act.doer, act.invobject)
  end
end, "domediumaction")

AddComponentAction("EQUIPPED", "wateryprotection", function(inst, _, target, right)
  local is_wateringcan, is_farmer_house = inst.prefab:find("wateringcan"), target:HasTag("mermhouse_farmer")
  if right and is_wateringcan and is_farmer_house then
    if GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_ALT) then
      return "MERMHOUSE_FARMER_FILL_CAN"
    else
      return "MERMHOUSE_FARMER_FILL"
    end
  end
end)

AddAction("MERMFARMER_PICK", "", function(act)
  local pick_successful = GLOBAL.ACTIONS.PICK.fn(act)
  if not pick_successful then return false end

  for _, picked_item in ipairs(act.doer.components.inventory.itemslots) do
    if picked_item.components.edible then
      local removed_item = act.doer.components.inventory:RemoveItem(picked_item)
      act.doer.components.container:GiveItem(removed_item)
    end
  end

  return true
end)

AddAction("MERMFARMER_PICKUP", "", function(act)
  if act.doer.components.container ~= nil and
      act.target ~= nil and
      act.target.components.inventoryitem ~= nil and (act.target.components.inventoryitem.canbepickedup or
        (act.target.components.inventoryitem.canbepickedupalive and not act.doer:HasTag("player"))) and
      not (act.target:IsInLimbo() or
        (act.target.components.burnable ~= nil and act.target.components.burnable:IsBurning() and act.target.components.lighter == nil) or
        (act.target.components.projectile ~= nil and act.target.components.projectile:IsThrown())) then
    act.doer:PushEvent("onpickupitem", { item = act.target })

    act.doer.components.container:GiveItem(act.target, nil, act.target:GetPosition())

    return true
  end
end)

AddAction("MERMFARMER_DUMP_INVENTORY", "", function(act)
  act.target.components.container.currentuser = act.doer
  for _, item in ipairs(act.doer.components.container:RemoveAllItems()) do
    act.target.components.container:GiveItem(item, nil, nil, false)
  end
  act.target.components.container.currentuser = nil

  return true
end)

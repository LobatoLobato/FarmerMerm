local _AddAction = AddAction
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

AddAction("REGISTER_SOIL", "Register Soil Tile", function(act)
  if act.invobject then
    GLOBAL.TheNet:SystemMessage("000000000000000000000000000", false)
    local pt = act:GetActionPoint()
    return act.invobject.components.mermexp_mermfarmblueprint:RegisterFarmTile(pt.x, pt.y, pt.z, true)
  end
end, "dolongaction", { tile_placer = "gridplacer" })

AddAction("REGISTER_SOIL_CAPTURING", "Register Soil Tile (Capture Layout)", function(act)
  print("bazinga")
  if act.invobject then
    GLOBAL.TheNet:SystemMessage("AAAAAAAAAAAAAAAAAAAAAAAAAAA", false)
    local pt = act:GetActionPoint()
    return act.invobject.components.mermexp_mermfarmblueprint:RegisterFarmTile(pt.x, pt.y, pt.z, true)
  end
end, "dolongaction", { tile_placer = "gridplacer" })

AddAction("UNREGISTER_SOIL", "Unregister Soil Tile", function(act)
  if act.invobject then
    GLOBAL.TheNet:SystemMessage("BBBBBBBBBBBBBBBBBBBBBBBBBBBB", false)
    return act.invobject.components.mermexp_mermfarmblueprint:UnregisterFarmTile(act:GetActionPoint():Get())
  end
end, "dolongaction", { tile_placer = "gridplacer" })

AddComponentAction("POINT", "mermexp_mermfarmblueprint", function(inst, doer, pos, actions, right)
  local isfarmablesoil = GLOBAL.TheWorld.Map:GetTileAtPoint(pos:Get()) == WORLD_TILES.FARMING_SOIL

  if right and isfarmablesoil then
    if inst.replica.mermexp_mermfarmblueprint:IsRegisteredFarmTile(pos:Get()) then
      table.insert(actions, GLOBAL.ACTIONS.UNREGISTER_SOIL)
    elseif GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_ALT) then
      table.insert(actions, GLOBAL.ACTIONS.REGISTER_SOIL_CAPTURING)
    else
      table.insert(actions, GLOBAL.ACTIONS.REGISTER_SOIL)
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

AddComponentAction("EQUIPPED", "wateryprotection", function(inst, _, target, actions, right)
  local is_wateringcan, is_farmer_house = inst.prefab:match("wateringcan"), target:HasTag("mermhouse_farmer")
  if right and is_wateringcan and is_farmer_house then
    if GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_ALT) then
      table.insert(actions, GLOBAL.ACTIONS.MERMHOUSE_FARMER_FILL_CAN)
    else
      table.insert(actions, GLOBAL.ACTIONS.MERMHOUSE_FARMER_FILL)
    end
  end
end)

AddAction("MERMFARMER_PICK", "", function(act)
  local pick_successful = GLOBAL.ACTIONS.PICK.fn(act)
  if pick_successful then
    for _, picked_item in ipairs(act.doer.components.inventory.itemslots) do
      if picked_item.components.edible then
        local removed_item = act.doer.components.inventory:RemoveItem(picked_item)
        act.doer.components.container:GiveItem(removed_item)
      end
    end
    return true
  end

  return false
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
  return false
end)

AddAction("MERMFARMER_DUMP_INVENTORY", "", function(act)
  act.target.components.container.currentuser = act.doer
  for _, item in ipairs(act.doer.components.container:RemoveAllItems()) do
    act.target.components.container:GiveItem(item, nil, nil, false)
  end
  act.target.components.container.currentuser = nil

  return true
end)

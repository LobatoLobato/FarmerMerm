local CONSTANTS = require "mermexp.constants"

AddModRPCHandler(CONSTANTS.MOD_NAME, "componentrpc", function(player, inst, component_name, command, ...)
  if player and player:IsValid() and not player:HasTag("playerghost") then
    local component = inst.components[component_name]
    component[command](component, ...)
  end
end)

AddClientModRPCHandler(CONSTANTS.MOD_NAME, "replicarpc", function(player, inst, replica_name, command, ...)
  if player and player:IsValid() and not player:HasTag("playerghost") then
    local replica = inst.replica[replica_name]
    replica[command](replica, ...)
  end
end)

AddClientModRPCHandler(CONSTANTS.MOD_NAME, "classifiedrpc", function(player, inst, replica_name, command, ...)
  if player and player:IsValid() and not player:HasTag("playerghost") and inst.replica[replica_name] then
    local classified = inst.replica[replica_name].classified
    classified[command](classified, ...)
  end
end)

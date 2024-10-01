local CONSTANTS = require "mermexp.constants"

AddModRPCHandler(CONSTANTS.MOD_NAME, "componentrpc", function(_, inst, component_name, command, ...)
  local component = inst.components[component_name]
  component[command](component, ...)
end)

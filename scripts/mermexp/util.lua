local CONSTANTS = require "mermexp.constants"
local function RegisterContainerParam(param, name)
  local containers = require("containers")
  local maxitemslots = param.widget.slotpos ~= nil and #param.widget.slotpos or 0

  containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, maxitemslots)

  containers.params["mermexp." .. name] = param

  return "mermexp." .. name
end


---comment
---@param x number
---@param y number
---@param z number
---@param insertfn fun(x: number, y: number, z: number)
---@param is_insertedfn fun(x: number, y: number, z: number): boolean
---@param constraintsfn fun(x: number, y: number, z: number): boolean
local function FloodTileSearch(x, y, z, insertfn, is_insertedfn, constraintsfn)
  constraintsfn = constraintsfn ~= nil and constraintsfn or function(_, _, _) return true end

  if not constraintsfn(x, y, z) then return end
  insertfn(x, y, z)

  local q = {};
  table.insert(q, { x = x, y = y, z = z })

  local step = 4
  while (#q > 0) do
    local pos = table.remove(q, 1)
    local tx, ty, tz = pos.x, pos.y, pos.z

    -- Check if the adjacent pixels are valid and enqueue
    if (constraintsfn(tx + step, ty, tz) and not is_insertedfn(tx + step, ty, tz)) then
      insertfn(tx + step, ty, tz)
      table.insert(q, { x = tx + step, y = ty, z = tz })
    end

    if (constraintsfn(tx - step, ty, tz) and not is_insertedfn(tx - step, ty, tz)) then
      insertfn(tx - step, ty, tz)
      table.insert(q, { x = tx - step, y = ty, z = tz })
    end

    if (constraintsfn(tx, ty, tz + step) and not is_insertedfn(tx, ty, tz + step)) then
      insertfn(tx, ty, tz + step)
      table.insert(q, { x = tx, y = ty, z = tz + step })
    end

    if (constraintsfn(tx, ty, tz - step) and not is_insertedfn(tx, ty, tz - step)) then
      insertfn(tx, ty, tz - step)
      table.insert(q, { x = tx, y = ty, z = tz - step })
    end
  end
end

local function _SendRPCToServer(id, ...)
  SendModRPCToServer(GetModRPC(CONSTANTS.MOD_NAME, id), ...)
end
local function SendComponentRPCToServer(inst, component_name, command, ...)
  _SendRPCToServer("componentrpc", inst, component_name, command, ...)
end


local function Dump(o)
  if type(o) == 'table' then
    local s = '{ \n'
    for k, v in pairs(o) do
      if type(k) ~= 'number' then k = '"' .. k .. '"' end
      s = s .. '[' .. k .. '] = ' .. Dump(v) .. ',\n'
    end
    return s .. '} \n'
  else
    return tostring(o)
  end
end

local function Vec3Tag(vec_or_x, y, z)
  if type(vec_or_x) == "table" then
    local vec = vec_or_x
    return tostring(vec.x) .. "_" .. tostring(vec.y) .. "_" .. tostring(vec.z)
  end

  local x = vec_or_x
  return tostring(x) .. "_" .. tostring(y) .. "_" .. tostring(z)
end

local function TileTag(vec_or_x, y, z)
  if type(vec_or_x) == "table" then
    local vec = vec_or_x
    local tcx, tcy, tcz = TheWorld.Map:GetTileCenterPoint(vec.x, vec.y, vec.z)
    return Vec3Tag(tcx, tcy, tcz)
  end

  local x = vec_or_x
  local tcx, tcy, tcz = TheWorld.Map:GetTileCenterPoint(x, y, z)
  return Vec3Tag(tcx, tcy, tcz)
end
return {
  RegisterContainerParam = RegisterContainerParam,
  FloodTileSearch = FloodTileSearch,
  Dump = Dump,
  SendRPCToServer = _SendRPCToServer,
  SendComponentRPCToServer = SendComponentRPCToServer,
  Vec3Tag = Vec3Tag,
  TileTag = TileTag
}

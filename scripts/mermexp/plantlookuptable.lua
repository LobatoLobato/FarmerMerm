---@class PlantLookupTable
---@field Has fun(self: PlantLookupTable, key: string|integer): boolean
---@field At fun(self: PlantLookupTable, key: string|integer): {name: string, build: string, bank: string, anim: string}, integer

---@class _
---@operator call:PlantLookupTable
local PlantLookupTable = Class(function(self, from, anim, key, exclude)
  if from == nil then return end
  exclude = exclude ~= nil and exclude or {}

  local i = 1
  local skip = false
  for k, plant in pairs(from) do
    for k, id in ipairs(exclude) do if id == k then skip = true end end

    if not skip then
      local name = (key ~= nil and plant[key] ~= nil) and plant[key] or k
      self[i] = { name = name, prefab = plant.prefab, build = plant.build, bank = plant.bank, anim = anim, index = i }

      i = i + 1
    end

    skip = false
  end

  table.sort(self, function(a, b) return a.name < b.name end)

  for i, v in ipairs(self) do
    self[v.name] = i
  end
end)

function PlantLookupTable.Join(table1, table2, exclude)
  exclude = exclude ~= nil and exclude or {}

  local joined_table = PlantLookupTable()
  local index = 1
  local skip = false
  for _, p in ipairs(table1) do
    for _, id in ipairs(exclude) do if id == p.name then skip = true end end
    if not skip then
      joined_table[index] = p
      joined_table[p.name] = index
      index = index + 1
    end
    skip = false
  end

  for _, p in ipairs(table2) do
    for _, id in ipairs(exclude) do if id == p.name then skip = true end end
    if not skip then
      joined_table[index] = p
      joined_table[p.name] = index
      index = index + 1
    end
    skip = false
  end

  return joined_table
end

function PlantLookupTable:Has(key)
  return self:At(key) ~= nil
end

function PlantLookupTable:At(key)
  local index
  if type(key) == "string" then
    index = self[key]
    if index == nil then
      for i, plant in ipairs(self) do
        if plant.prefab == key then index = i end
      end
    end
  else
    index = key
  end

  return self[index], index
end

return PlantLookupTable

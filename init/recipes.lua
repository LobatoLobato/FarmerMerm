---@class RecipeProps
---@field name string
---@field description string
---@field ingredients table
---@field techlevel table
---@field builder_skill string?
---@field placer boolean?
---@field marsh_only boolean?

---comment
---@param prefab string
---@param props RecipeProps
local function MakeRecipe(prefab, props)
  local ingredients = {}
  for _, ingredient in ipairs(props.ingredients) do
    table.insert(ingredients, GLOBAL.Ingredient(ingredient[1], ingredient[2]))
  end

  prefab = "mermexp_" .. prefab
  local recipe = GLOBAL.Recipe2(prefab, ingredients, props.techlevel, {
    builder_tag = "merm_builder",
    builder_skill = props.builder_skill,
    placer = props.placer and prefab .. "_placer" or nil,
    testfn = props.marsh_only and function(pt)
      local ground_tile = GLOBAL.TheWorld.Map:GetTileAtPoint(pt.x, pt.y, pt.z)
      return ground_tile and (ground_tile == WORLD_TILES.MARSH or ground_tile == WORLD_TILES.FARMING_SOIL)
    end or nil,
  })
  recipe.atlas = "images/mermexp/inventoryimages.xml"

  GLOBAL.STRINGS.NAMES[prefab:upper()] = props.name
  GLOBAL.STRINGS.RECIPE_DESC[prefab:upper()] = props.description
end

MakeRecipe("mermhouse_farmer", {
  name = "Farmmerm House",
  description = "CLT",
  ingredients = { { "boards", 5 }, { "pondfish", 2 }, { "plantregistryhat", 1 } },
  techlevel = GLOBAL.TECH.SCIENCE_ONE,
  placer = true,
  marsh_only = true,
})

MakeRecipe("mermfarm_blueprint", {
  name = "Mermfarm Blueprint",
  description = "ashassuuahsdu",
  ingredients = { { "papyrus", 2 }, { "twigs", 4 }, { "featherpencil", 1 } },
  techlevel = GLOBAL.TECH.SCIENCE_ONE,
})

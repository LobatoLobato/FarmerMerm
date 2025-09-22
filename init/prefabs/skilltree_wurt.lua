local skilltreedefs = require "prefabs/skilltree_defs"
local characterprefab = "wurt"
local DEFS = skilltreedefs.SKILLTREE_DEFS[characterprefab]
local METAINFO = skilltreedefs.SKILLTREE_METAINFO[characterprefab]

local TILEGAP = 38
local POS_Y_1 = 172
local MERMEXP_CIV_1_X = -46.5 - TILEGAP * 1.1
-- Positions

--------------------------------------------------------------------------------------------------

-- Functions

-- local function CreateAddTagFn(tag)
--   return function(inst) inst:AddTag(tag) end
-- end

-- local function CreateRemoveTagFn(tag)
--   return function(inst) inst:RemoveTag(tag) end
-- end

-- local function RefreshWetnessSkills(inst)
--   inst:RefreshWetnessSkills()
-- end

-- local function RefreshPathFinderSkill(inst)
--   inst:RefreshPathFinderSkill()
-- end

--------------------------------------------------------------------------------------------------

local skills = {
  wurt_mermexp_civ_1 = {
    pos = { MERMEXP_CIV_1_X, POS_Y_1 },
    group = "swampmaster",
    tags = { "swampmaser", "civ" },
    root = true,
    title = "Farmer Merm",
    desc =
    "Learn to craft the Farmmerm House and Mermfarm Blueprint to unleash the power of agriculture into Mermkind",
    icon = "wurt_pathfinder"
  },
}

table.insert(DEFS["wurt_civ_2"].connects, "wurt_mermexp_civ_1")

for name, skill in GLOBAL.orderedPairs(skills) do
  METAINFO.RPC_LOOKUP[#METAINFO.RPC_LOOKUP + 1] = name
  METAINFO.TOTAL_SKILLS_COUNT                   = METAINFO.TOTAL_SKILLS_COUNT + 1
  METAINFO.TOTAL_LOCKS                          = METAINFO.TOTAL_LOCKS

  DEFS[name]                                    = skill
end

local farmblueprintpopup = AddPopup("MERMEXP_MERMFARMBLUEPRINT")
farmblueprintpopup.fn = function(inst, show, blueprint)
  local function CloseFarmBlueprintScreen(inst)
    if inst.farmblueprintscreen ~= nil then
      if inst.farmblueprintscreen.inst:IsValid() then
        TheFrontEnd:PopScreen(inst.farmblueprintscreen)
      end
      inst.farmblueprintscreen = nil
    end
  end

  local function OpenFarmBlueprintScreen(inst)
    CloseFarmBlueprintScreen(inst)
    inst.farmblueprintscreen = require "screens.mermexp.farmblueprintscreen" (blueprint)
    inst.HUD:OpenScreenUnderPause(inst.farmblueprintscreen)
    return true
  end

  if inst.HUD then
    if not show then
      CloseFarmBlueprintScreen(inst)
    elseif not OpenFarmBlueprintScreen(inst) then
      farmblueprintpopup:Close(inst)
    end
  end
end

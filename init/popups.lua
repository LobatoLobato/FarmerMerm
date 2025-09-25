local farmblueprintpopup = AddPopup("MERMEXP_MERMFARMBLUEPRINT")
farmblueprintpopup.fn = function(inst, show, blueprint)
  if inst.HUD then
    if inst.farmblueprintscreen ~= nil then
      if inst.farmblueprintscreen.inst:IsValid() then
        TheFrontEnd:PopScreen(inst.farmblueprintscreen)
      end
      inst.farmblueprintscreen = nil
    end
    
    if show then
      inst.farmblueprintscreen = require "screens.mermexp.farmblueprintscreen" (blueprint)
      inst.HUD:OpenScreenUnderPause(inst.farmblueprintscreen)
      farmblueprintpopup:Close(inst)
    end
  end
end

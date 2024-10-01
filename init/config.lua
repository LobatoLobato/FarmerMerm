AddPrefabPostInit("mermexp_merm_farmer", function(inst)
  if GetModConfigData("mermfarmer_unloading_disabled") then
    inst.entity:SetCanSleep(false)
  end
end)

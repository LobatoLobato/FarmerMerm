AddClassPostConstruct("widgets/containerwidget", function(self)
  local ContainerWidget = require "widgets.containerwidget"
  function self:Open(container, owner)
    if container:HasTag("mermexp") and container:HasTag("mermhouse_farmer") then
      local waterreservoir = container.replica.mermexp_waterreservoir
      local container = container.replica.container

      self.waterlevelmeter = self:AddChild(require("widgets.mermexp.waterlevelmeter")())
      self.waterlevelmeter:SetPosition(container.waterlevelmeter_position.x, container.waterlevelmeter_position.y)
      self.waterlevelmeter:MoveToFront()

      self.setwaterlevel = function() self.waterlevelmeter:SetValue(waterreservoir:Level(), waterreservoir:MaxLevel()) end
      self.inst:ListenForEvent("mxp.waterreservoir.maxleveldirty", self.setwaterlevel, waterreservoir.inst)
      self.inst:ListenForEvent("mxp.waterreservoir.leveldirty", self.setwaterlevel, waterreservoir.inst)
      self.waterreservoir_inst = waterreservoir.inst

      self.waterlevelmeter:SetValue(waterreservoir:Level(), waterreservoir:MaxLevel())
      self.waterlevelmeter:Activate()
    end

    return ContainerWidget.Open(self, container, owner)
  end

  function self:Close()
    if self.isopen then
      if self.container:HasTag("mermexp") and self.container:HasTag("mermhouse_farmer") then
        self.inst:RemoveEventCallback("mxp.waterreservoir.maxleveldirty", self.setwaterlevel, self.waterreservoir_inst)
        self.inst:RemoveEventCallback("mxp.waterreservoir.leveldirty", self.setwaterlevel, self.waterreservoir_inst)
        self.waterlevelmeter:Deactivate()
        self.waterlevelmeter:Kill()
      end
    end
    return ContainerWidget.Close(self)
  end
end)

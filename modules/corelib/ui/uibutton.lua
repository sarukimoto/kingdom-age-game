-- @docclass
UIButton = extends(UIWidget, "UIButton")

function UIButton.create()
  local button = UIButton.internalCreate()
  button:setFocusable(false)
  return button
end

function UIButton:onMouseRelease(pos, button)
  return self:isPressed()
end

function UIButton:onMouseRelease(mousePos, mouseButton)
  g_tooltip.widgetUpdateHover(self, true)
end

function UIButton:onDestroy()
  g_tooltip.hide(self)
end

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
  if g_tooltip then
    g_tooltip.onWidgetMouseRelease(self, mousePos, mouseButton)
  end
end

function UIButton:onDestroy()
  if g_tooltip then
    g_tooltip.onWidgetDestroy(self)
  end
end

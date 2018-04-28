UIHotkeyLabel = extends(UILabel, 'UIHotkeyLabel')

function UIHotkeyLabel:onDragEnter(mousePos)
  self:setBorderWidth(1)
  g_mouse.pushCursor('target')
  return true
end

function UIHotkeyLabel:onDragLeave(droppedWidget, mousePos)
  g_mouse.popCursor('target')
  self:setBorderWidth(0)
  return true
end

function UIHotkeyLabel:onDestroy()
  if self.hoverTarget then
    self.hoverTarget:onHoverChange(false)
  end

  g_mouse.popCursor('target')
end

function UIHotkeyLabel:onMouseRelease(mousePosition, mouseButton)
  if not self:containsPoint(mousePosition) then return false end
  return false
end

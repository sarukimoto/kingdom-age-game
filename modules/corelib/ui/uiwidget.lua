-- @docclass UIWidget

function UIWidget:setMargin(...)
  local params = {...}
  if #params == 1 then
    self:setMarginTop(params[1])
    self:setMarginRight(params[1])
    self:setMarginBottom(params[1])
    self:setMarginLeft(params[1])
  elseif #params == 2 then
    self:setMarginTop(params[1])
    self:setMarginRight(params[2])
    self:setMarginBottom(params[1])
    self:setMarginLeft(params[2])
  elseif #params == 4 then
    self:setMarginTop(params[1])
    self:setMarginRight(params[2])
    self:setMarginBottom(params[3])
    self:setMarginLeft(params[4])
  end
end

function UIWidget:onDrop(widget, mousePos)
  if self == widget then
    return false
  end

  -- Avoid dropping miniwindow outside it's panel
  local miniWindowContainer = nil
  if widget:getClassName() == 'UIMiniWindow' then
    -- Finding if dropped widget is UIMiniWindowContainer
    local children = rootWidget:recursiveGetChildrenByPos(mousePos)
    for i=1,#children do
      local child = children[i]
      if child:getClassName() == 'UIMiniWindowContainer' then
        miniWindowContainer = child
        break
      end
    end
  end
  if not miniWindowContainer and widget.lastPanel then
    local oldParent = widget:getParent()
    if oldParent then
      oldParent:removeChild(widget)
    end

    if widget.movedWidget then
      local index = widget.lastPanel:getChildIndex(widget.movedWidget)
      widget.lastPanel:insertChild(index + widget.movedIndex, widget)
    else
      widget.lastPanel:addChild(widget)
    end

    widget.lastPanel:fitAll(widget)
  end

  if widget:getClassName() == 'UIHotkeybarContainer' then
    local parent = widget:getParentBar()
    if not parent then return false end
    local mod = modules.game_hotkeys
    if not mod or not mod.isOpen() then return false end

    local dropParent = self:getParent()
    if dropParent and dropParent:getClassName() == 'UIHotkeybar' then
      dropParent:onDrop(widget, mousePos)
      return true
    end

    parent:removeHotkey(widget)
    return true
  end

  return false
end

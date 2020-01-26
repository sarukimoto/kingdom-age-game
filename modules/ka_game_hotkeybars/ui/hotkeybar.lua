UIHotkeybar = extends(UIWidget, 'UIHotkeybar')

local containersLimit = 10

function UIHotkeybar.create()
  local obj = UIHotkeybar.internalCreate()
  obj:setId('hotkeybar_none')
  obj.hotkeys = {}
  obj.arrows = {}
  obj.alignment = 'none'
  obj.mapMargin = 4
  obj.hotkeySize = 36
  obj.hotkeyMargin = 4
  obj.height = obj.hotkeySize + 2
  obj.defaultTooltip = 'Drag hotkeys (%s) to this bar.'
  obj:setTooltip(tr(obj.defaultTooltip, 'Ctrl+K'))
  return obj
end

function UIHotkeybar:setHotkeybarId(id)
  self:setId('hotkeybar_' .. id)
  self.id = id
end

function UIHotkeybar:setHighlighted(value)
  self:setOn(value)
  for i = 1, #self.arrows do
    local widget = self.arrows[i]
    widget:setOn(value)
  end
end

function UIHotkeybar:addHotkey(keyCombo, mousePos)
  if #self.hotkeys >= containersLimit then
    return
  end

  for i = 1, #self.hotkeys do
    if self.hotkeys[i] == keyCombo then
      return
    end
  end

  self:setTooltip(nil)

  local hotkeyWidget = g_ui.createWidget('HotkeybarContainer')
  hotkeyWidget.keyCombo = keyCombo
  hotkeyWidget:setId(keyCombo)
  hotkeyWidget:setTooltip(keyCombo)
  hotkeyWidget:setWidth(self.hotkeySize)
  hotkeyWidget:setHeight(self.hotkeySize)
  hotkeyWidget:setMargin(2)
  hotkeyWidget:setDraggable(true)

  connect(hotkeyWidget, {
    onMousePress = function () modules.game_hotkeys.doKeyCombo(keyCombo, hotkeyWidget) end
  })

  local isVertical = (self.alignment == 'vertical')
  local isHorizontal = (self.alignment == 'horizontal')
  local inserted = false
  if mousePos then
    local index = self:getChildCount()
    if isVertical then
      for i = 1, #self.hotkeys do
        local widget = self:getChildById(self.hotkeys[i])
        if widget then
          if mousePos.y <= widget:getY() + math.floor(widget:getHeight() / 2) then
            index = i + 1
            break
          end
        end
      end
    elseif isHorizontal then
      for i = 1, #self.hotkeys do
        local widget = self:getChildById(self.hotkeys[i])
        if widget then
          if mousePos.x <= widget:getX() + math.floor(widget:getWidth() / 2) then
            index = i + 1
            break
          end
        end
      end
    end

    self:insertChild(index, hotkeyWidget)
    table.insert(self.hotkeys, index - 1, keyCombo)
  else
    self:insertChild(self:getChildCount(), hotkeyWidget)
    table.insert(self.hotkeys, keyCombo)
  end

  if isVertical then
    hotkeyWidget:addAnchor(AnchorTop, 'prev', AnchorBottom)
    hotkeyWidget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    hotkeyWidget:setMarginTop(self.hotkeyMargin)
  elseif isHorizontal then
    hotkeyWidget:addAnchor(AnchorTop, 'parent', AnchorTop)
    hotkeyWidget:addAnchor(AnchorLeft, 'prev', AnchorRight)
    hotkeyWidget:setMarginLeft(self.hotkeyMargin)
  end

  hotkeyWidget:updateLook()
  self:updateSize()
end

function UIHotkeybar:removeHotkey(widget)
  modules.game_hotkeys.cancelPower(true)

  local keyCombo = widget.keyCombo
  if #self.hotkeys > 0 then
    for i = #self.hotkeys, 1, -1 do
      if self.hotkeys[i] == keyCombo then
        table.remove(self.hotkeys, i)
      end
    end
  end

  self:removeChild(widget)
  self:updateSize()

  if #self.hotkeys == 0 then
    self:setTooltip(tr(self.defaultTooltip, 'Ctrl+K'))
  end
end

function UIHotkeybar:updateLook()
  local children = self:getChildren()
  for i = 1, #children do
    if children[i]:getClassName() == 'UIHotkeybarContainer' then
      children[i]:updateLook()
    end
  end
end

function UIHotkeybar:unload()
  local children = self:getChildren()
  for i = #children, 1, -1 do
    if children[i]:getClassName() == 'UIHotkeybarContainer' then
      self:removeChild(children[i])
    end
  end

  self.hotkeys = {}
  self:updateSize()
end

function UIHotkeybar:updateDraggable(bool)
  local children = self:getChildren()
  for i = 1, #children do
    if children[i]:getClassName() == 'UIHotkeybarContainer' then
      children[i]:setDraggable(bool)
    end
  end
end

function UIHotkeybar:load()
  local settings = modules.game_things.getPlayerSettings()
  local hotkeyBars = settings:getNode('hotkeybars') or {}

  if table.empty(hotkeyBars) then
    return
  end

  hotkeyBars = hotkeyBars['Hotkeybar' .. self.id]
  if not hotkeyBars or table.empty(hotkeyBars) then
    return
  end

  local tmp = {}
  for k, keyCombo in pairs(hotkeyBars) do
    table.insert(tmp, {k, keyCombo})
  end

  table.sort(tmp, function(a, b) return a[1] < b[1] end)
  for i = 1, #tmp do
    self:addHotkey(tmp[i][2])
  end
end

function UIHotkeybar:save()
  local settings = modules.game_things.getPlayerSettings()
  local hotkeyBars = settings:getNode('hotkeybars') or {}

  for k, v in pairs(hotkeyBars) do
    hotkeyBars[k] = v
  end

  hotkeyBars['Hotkeybar' .. self.id] = {}

  for k, v in ipairs(self.hotkeys) do
    table.insert(hotkeyBars['Hotkeybar' .. self.id], v)
  end

  self:unload()

  settings:setNode('hotkeybars', hotkeyBars)
  settings:save()
end

function UIHotkeybar:updateSize()
  local content = #self.hotkeys * (self.hotkeySize + self.hotkeyMargin) + 25
  if self.alignment == 'vertical' then
    self:setSize(string.format('%i %i', self.height, content))
  elseif self.alignment == 'horizontal' then
    self:setSize(string.format('%i %i', content, self.height))
  else
    self:setSize(string.format('%i %i', content, content))
  end
end

function UIHotkeybar:setAlignment(align)
  if align == 'vertical' then
    table.insert(self.arrows, g_ui.createWidget('HotkeybarArrowTop', self))
    table.insert(self.arrows, g_ui.createWidget('HotkeybarArrowBottom', self))
    self:addAnchor(AnchorVerticalCenter, 'gameMapPanel', AnchorVerticalCenter)
    self:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  elseif align == 'horizontal' then
    table.insert(self.arrows, g_ui.createWidget('HotkeybarArrowLeft', self))
    table.insert(self.arrows, g_ui.createWidget('HotkeybarArrowRight', self))
    self:addAnchor(AnchorHorizontalCenter, 'gameMapPanel', AnchorHorizontalCenter)
    self:addAnchor(AnchorTop, 'parent', AnchorTop)
  end

  self.alignment = align
  self:updateSize()
end

function UIHotkeybar:onHoverChange(hovered)
  UIWidget.onHoverChange(self, hovered)

  local draggingWidget = g_ui.getDraggingWidget()
  if not draggingWidget then
    return
  end

  local isHotkeybarContainer = draggingWidget:getClassName() == 'UIHotkeybarContainer'
  local isHotkeyLabel = draggingWidget:getClassName() == 'UIHotkeyLabel'
  if isHotkeybarContainer then
    local parent = draggingWidget:getParentBar()
    if parent then
      if parent == self then
        return
      end
    end
  end

  if isHotkeyLabel or isHotkeybarContainer then
    if isHotkeyLabel then
      draggingWidget.hoverTarget = (hovered and self or nil)
    end

    self:setHighlighted(hovered)
  end
end

function UIHotkeybar:onDrop(widget, mousePos)
  local isHotkeyLabel = widget:getClassName() == 'UIHotkeyLabel'
  local isHotkeybarContainer = widget:getClassName() == 'UIHotkeybarContainer'
  local isPowerButton = widget:getClassName() == 'UIPowerButton'
  local isItemButton = widget:getClassName() == 'UIItem'
  local isGameItem = widget:getClassName() == 'UIGameMap'
  if not self:canAcceptDrop(widget, mousePos) or (not(isHotkeyLabel) and not(isHotkeybarContainer) and not(isPowerButton) and not(isItemButton) and not(isGameItem)) then return false end

  if isPowerButton then
    modules.game_hotkeys.addHotkey({hotkeyBar = self, powerId = widget.power.id, mousePos = mousePos})
    return true
  end

  if isItemButton then
    modules.game_hotkeys.addHotkey({hotkeyBar = self, item = widget:getItem(), mousePos = mousePos})
    return true
  end

  if isGameItem then
    local item = widget.currentDragThing
    if not item:isItem() or not item:isPickupable() then return false end
    modules.game_hotkeys.addHotkey({hotkeyBar = self, item = widget.currentDragThing, mousePos = mousePos})
    return true
  end

  local keyCombo = widget.keyCombo
  if isHotkeybarContainer then
    local parent = widget:getParentBar()
    if parent then
      parent:removeHotkey(widget)
      return false
    end
  end

  self:setHighlighted(false)
  self:addHotkey(keyCombo, mousePos)
  return true
end

function UIHotkeybar:canAcceptDrop(widget, mousePos)
  if not widget then return false end

  local children = rootWidget:recursiveGetChildrenByPos(mousePos)
  for i=1,#children do
    local child = children[i]
    if child == self then
      return true
    elseif not child:isPhantom() and not child:getClassName() == 'UIHotkeybarContainer' then
      return false
    end
  end

  error('Widget ' .. self:getId() .. ' not in drop list.')
  return false
end

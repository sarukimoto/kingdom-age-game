UIHotkeybarContainer = extends(UIWidget, 'UIHotkeybarContainer')

function UIHotkeybarContainer:onDragEnter(mousePos)
  self:setBorderWidth(1)
  g_mouse.pushCursor('target')
  return true
end

function UIHotkeybarContainer:onDragLeave(droppedWidget, mousePos)
  g_mouse.popCursor('target')
  self:setBorderWidth(0)
  return true
end

function UIHotkeybarContainer:getParentBar()
  local parent = self:getParent()
  if parent and parent:getClassName() == 'UIHotkeybar' then
    return parent
  end

  return nil
end

function UIHotkeybarContainer:onHoverChange(hovered)
  UIWidget.onHoverChange(self, hovered)

  local parent = self:getParentBar()
  if parent then
    signalcall(parent.onHoverChange, parent, hovered)
  end
end

function UIHotkeybarContainer:updateLook()
  local tooltipText = '[' .. self.keyCombo .. ']'
  self:setTooltip(tooltipText)
  self.powerid = nil

  local itemWidget = self:getChildById('item')
  if itemWidget then
    itemWidget:setVisible(false)
  end

  local powerWidget = self:getChildById('power')
  if powerWidget then
    powerWidget:setVisible(false)
  end

  -- Text
  self:setText('')

  if modules.game_hotkeys then
    local view = modules.game_hotkeys.getHotkey(self.keyCombo)
    if view then

      if view.type == 'text' then
        self:setText('TxT')
        tooltipText = tooltipText .. (view.autoSend and ' (auto send)' or '') .. '\n' .. view.value
      elseif view.type == 'power' and powerWidget then
        powerWidget:setImageSource('/images/game/powers/' .. view.id .. '_off')
        powerWidget:setVisible(true)
        self.powerid = view.id
        if view.name and view.level then
          tooltipText = string.format("%s %s (level %d)", tooltipText, view.name, view.level)
        else
          tooltipText = string.format("%s You are not able to use this power.", tooltipText)
        end
      elseif view.type == 'item' and itemWidget then
        itemWidget:setVisible(true)
        itemWidget:setItemId(view.id)

        if view.useType == modules.game_hotkeys.HOTKEY_MANAGER_USEONSELF then
          tooltipText = tooltipText .. '\nUse on self'
        elseif view.useType == modules.game_hotkeys.HOTKEY_MANAGER_USEONTARGET then
          tooltipText = tooltipText .. '\nUse on target'
        elseif view.useType == modules.game_hotkeys.HOTKEY_MANAGER_USEWITH then
          tooltipText = tooltipText .. '\nUse with'
        end
      end
    end
  end

  self:setTooltip(tooltipText)
end

dofiles('ui')

HOTKEY_MANAGER_USE = nil
-- HOTKEY_MANAGER_USEONSELF = 1
-- HOTKEY_MANAGER_USEONTARGET = 2
HOTKEY_MANAGER_USEWITH = 3

HotkeyColors = {
  text = '#333B43',
  textAutoSend = '#FFFFFF',
  itemUse = '#AEF2FF',
  -- itemUseSelf = '#0042FF',
  -- itemUseTarget = '#EC1414',
  itemUseWith = '#F8E127',
  powerColor = '#CD4EFF'
}

hotkeysManagerLoaded = false
hotkeysWindow = nil
hotkeysButton = nil
currentHotkeyLabel = nil
hotKeyItemLabel = nil
currentItemPreview = nil
itemWidget = nil
addHotkeyButton = nil
removeHotkeyButton = nil
hotKeyTextLabel = nil
hotkeyText = nil
sendAutomatically = nil
-- selectObjectButton = nil
-- clearObjectButton = nil
-- useOnSelf = nil
-- useOnTarget = nil
-- useWith = nil
defaultComboKeys = nil
-- mouseGrabberWidget = nil
-- useRadioGroup = nil
currentHotkeys = nil
boundCombosCallback = {}
hotkeysList = {}
lastHotkeyTime = g_clock.millis()

-- Power

powerBoost_time    = 1000 -- Time difference between each boost
powerBoost_maxTime = 60 * 1000 -- boost_maxTime

powerBoost_lastPower     = 0
powerBoost_keyCombo      = nil
powerBoost_clickedWidget = nil
powerBoost_startAt       = nil

power_flag_start      = -1
power_flag_cancel     = -2
power_flag_updateList = -3 -- Used on ka_game_powers

-- Power Boost Effect

powerBoost_none  = 1
powerBoost_low   = 2
powerBoost_high  = 3
powerBoost_first = powerBoost_none
powerBoost_last  = powerBoost_high

powerBoost_fadein      = 400
powerBoost_fadeout     = 200
powerBoost_resizex     = 0.5
powerBoost_resizey     = 0.5
powerBoost_color_speed = 200

powerBoost_color_default = { r = 255, g = 255, b = 150 }
powerBoost_color =
{
  [powerBoost_none] = { r = 255, g = 255, b = 150 },
  [powerBoost_low]  = { r = 255, g = 150, b = 150 },
  [powerBoost_high] = { r = 150, g = 150, b = 255 }
}

powerBoost_state_color = false
powerBoost_event_color = nil
powerBoost_state_image = false
powerBoost_event_image = nil





function init()
  g_ui.importStyle('hotkeylabel.otui')

  hotkeysButton = modules.client_topmenu.addLeftGameButton('hotkeysButton', tr('Hotkeys') .. ' (Ctrl+K)', '/images/topbuttons/hotkeys', toggle)
  g_keyboard.bindKeyDown('Ctrl+K', toggle)
  hotkeysWindow = g_ui.displayUI('hotkeys')
  hotkeysWindow:setVisible(false)

  currentHotkeys = hotkeysWindow:getChildById('currentHotkeys')
  hotKeyItemLabel = hotkeysWindow:getChildById('hotKeyItemLabel')
  currentItemPreview = hotkeysWindow:getChildById('itemPreview')
  currentItemPreview.onDrop = dropOnItemPreview
  currentItemPreview.onDragEnter = dragEnterItemPreview
  currentItemPreview.onDragLeave = dragLeaveItemPreview
  addHotkeyButton = hotkeysWindow:getChildById('addHotkeyButton')
  removeHotkeyButton = hotkeysWindow:getChildById('removeHotkeyButton')
  hotKeyTextLabel = hotkeysWindow:getChildById('hotKeyTextLabel')
  hotkeyText = hotkeysWindow:getChildById('hotkeyText')
  sendAutomatically = hotkeysWindow:getChildById('sendAutomatically')
  -- selectObjectButton = hotkeysWindow:getChildById('selectObjectButton')
  -- clearObjectButton = hotkeysWindow:getChildById('clearObjectButton')
  -- useOnSelf = hotkeysWindow:getChildById('useOnSelf')
  -- useOnTarget = hotkeysWindow:getChildById('useOnTarget')
  -- useWith = hotkeysWindow:getChildById('useWith')

  -- useRadioGroup = UIRadioGroup.create()
  -- useRadioGroup:addWidget(useOnSelf)
  -- useRadioGroup:addWidget(useOnTarget)
  -- useRadioGroup:addWidget(useWith)
  -- useRadioGroup.onSelectionChange = function(self, selected) onChangeUseType(selected) end

  -- mouseGrabberWidget = g_ui.createWidget('UIWidget')
  -- mouseGrabberWidget:setVisible(false)
  -- mouseGrabberWidget:setFocusable(false)
  -- mouseGrabberWidget.onMouseRelease = onChooseItemMouseRelease

  currentHotkeys.onChildFocusChange = function(self, hotkeyLabel) onSelectHotkeyLabel(hotkeyLabel) end
  g_keyboard.bindKeyPress('Down', function() currentHotkeys:focusNextChild(KeyboardFocusReason) end, hotkeysWindow)
  g_keyboard.bindKeyPress('Up', function() currentHotkeys:focusPreviousChild(KeyboardFocusReason) end, hotkeysWindow)

  g_keyboard.bindKeyPress('Escape', function() cancelPower(true) end, rootWidget)
  connect(g_game, {
    onGameStart = online,
    onGameEnd = offline
  })

  removePowerBoostEffect()
end

function terminate()
  removePowerBoostEffect()

  disconnect(g_game, {
    onGameStart = online,
    onGameEnd = offline
  })

  g_keyboard.unbindKeyDown('Ctrl+K')

  hotkeysWindow:destroy()
  hotkeysButton:destroy()
  -- mouseGrabberWidget:destroy()
end

function online()
  reload()
  hide()
end

function offline()
  unload()
  hide()
end

function show()
  if not g_game.isOnline() then
    return
  end
  if modules.ka_game_hotkeybars then
    modules.ka_game_hotkeybars.updateDraggable(true)
  end
  hotkeysWindow:show()
  hotkeysWindow:raise()
  hotkeysWindow:focus()
  hotkeysButton:setOn(true)
end

function hide()
  hotkeysWindow:hide()
  if modules.ka_game_hotkeybars then
    modules.ka_game_hotkeybars.updateDraggable(false)
  end
  hotkeysButton:setOn(false)
end

function toggle()
  if not hotkeysWindow:isVisible() then
    show()
  else
    hide()
  end
end

function ok()
  save()
  if modules.ka_game_hotkeybars then
    modules.ka_game_hotkeybars.onUpdateHotkeys()
  end
  hide()
end

function cancel()
  reload()
  hide()
end

function load(forceDefaults)
  hotkeysManagerLoaded = false

  loadDefaultComboKeys()

  local settings = modules.game_things.getPlayerSettings()
  local hotkeySettings = settings:getNode('hotkeys') or {}
  local hotkeys = {}

  if not table.empty(hotkeySettings) then
    hotkeys = hotkeySettings
  end

  hotkeyList = {}
  if not forceDefaults then
    if not table.empty(hotkeys) then
      for keyCombo, setting in pairs(hotkeys) do
        keyCombo = tostring(keyCombo)
        addKeyCombo(keyCombo, setting)
        hotkeyList[keyCombo] = setting
      end
    end
  end
  hotkeysManagerLoaded = true
end

function unload()
  for keyCombo,callback in pairs(boundCombosCallback) do
    g_keyboard.unbindKeyPress(keyCombo, callback)
  end
  boundCombosCallback = {}
  currentHotkeys:destroyChildren()
  currentHotkeyLabel = nil
  updateHotkeyForm(true)
  hotkeyList = {}
end

function reset()
  unload()
  load(true)
end

function reload()
  unload()
  load()
end

function save()
  local settings = modules.game_things.getPlayerSettings()
  local hotkeySettings = settings:getNode('hotkeys') or {}
  local hotkeys = hotkeySettings

  table.clear(hotkeys)

  for _,child in pairs(currentHotkeys:getChildren()) do
    local powerId = getPowerIdByString(child.value)
    child.autoSend = powerId and true or child.autoSend
    hotkeys[child.keyCombo] = {
      autoSend = child.autoSend,
      itemId = child.itemId,
      subType = child.subType,
      useType = child.useType,
      value = child.value
    }
  end

  hotkeyList = hotkeys
  settings:setNode('hotkeys', hotkeySettings)
  settings:save()
end

function loadDefaultComboKeys()
  if not defaultComboKeys then
    for i=1,12 do
      addKeyCombo('F' .. i)
    end
    for i=1,12 do
      addKeyCombo('Shift+F' .. i)
    end
    for i=1,12 do
      addKeyCombo('Ctrl+F' .. i)
    end
  else
    for keyCombo, keySettings in pairs(defaultComboKeys) do
      addKeyCombo(keyCombo, keySettings)
    end
  end
end

function setDefaultComboKeys(combo)
  defaultComboKeys = combo
end

function onChooseItemMouseRelease(self, mousePosition, mouseButton)
  local item = nil
  if mouseButton == MouseLeftButton then
    local clickedWidget = modules.game_interface.getRootPanel():recursiveGetChildByPos(mousePosition, false)
    if clickedWidget then
      local clickedId = clickedWidget:getId()
      if clickedId:match('PowerButton_id%d+') then
        local powerId = tonumber(clickedId:match('%d+'))
        if powerId then
          currentHotkeyLabel.itemId = nil
          currentHotkeyLabel.value = '/power ' .. powerId
          currentHotkeyLabel.autoSend = true
          currentHotkeyLabel.useType = nil
          updateHotkeyLabel(currentHotkeyLabel)
          updateHotkeyForm(true)
        end
      elseif clickedWidget:getClassName() == 'UIGameMap' then
        local tile = clickedWidget:getTile(mousePosition)
        if tile then
          local thing = tile:getTopMoveThing()
          if thing and thing:isItem() then
            item = thing
          end
        end
      elseif clickedWidget:getClassName() == 'UIItem' and not clickedWidget:isVirtual() then
        item = clickedWidget:getItem()
      end
    end
  end

  if item and currentHotkeyLabel then
    currentHotkeyLabel.itemId = item:getId()
    if item:isFluidContainer() then
        currentHotkeyLabel.subType = item:getSubType()
    end
    if item:isMultiUse() then
      currentHotkeyLabel.useType = HOTKEY_MANAGER_USEWITH
    else
      currentHotkeyLabel.useType = HOTKEY_MANAGER_USE
    end
    currentHotkeyLabel.value = nil
    currentHotkeyLabel.autoSend = false
    updateHotkeyLabel(currentHotkeyLabel)
    updateHotkeyForm(true)
    if modules.ka_game_hotkeybars then
      modules.ka_game_hotkeybars.onUpdateHotkeys()
    end
  end

  show()

  g_mouse.popCursor('target')
  self:ungrabMouse()
  return true
end

--[[
function startChooseItem()
  if g_ui.isMouseGrabbed() then return end
  mouseGrabberWidget:grabMouse()
  g_mouse.pushCursor('target')
  hide()
end
]]

function clearObject()
  currentHotkeyLabel.itemId = nil
  currentHotkeyLabel.subType = nil
  currentHotkeyLabel.useType = nil
  currentHotkeyLabel.autoSend = nil
  currentHotkeyLabel.value = nil
  updateHotkeyLabel(currentHotkeyLabel)
  updateHotkeyForm(true)
  if modules.ka_game_hotkeybars then
    modules.ka_game_hotkeybars.onUpdateHotkeys()
  end
end

function addHotkey(keySettings)
  local assignWindow = g_ui.createWidget('HotkeyAssignWindow', rootWidget)
  assignWindow:grabKeyboard()

  local comboLabel = assignWindow:getChildById('comboPreview')
  comboLabel.keyCombo = ''
  assignWindow.onKeyDown = hotkeyCapture

  local addButtonWidget = assignWindow:getChildById('addButton')
  addButtonWidget.onClick = function(widget)
    local keyCombo = assignWindow:getChildById('comboPreview').keyCombo
    addKeyCombo(keyCombo, keySettings, true)
    assignWindow:destroy()
  end

  local cancelButton = assignWindow:getChildById('cancelButton')
  cancelButton.onClick = function (widget)
    assignWindow:destroy()
  end
end

function addKeyCombo(keyCombo, keySettings, focus)
  if keyCombo == nil or #keyCombo == 0 then return end
  if not keyCombo then return end
  local hotkeyLabel = currentHotkeys:getChildById(keyCombo)
  if not hotkeyLabel then
    hotkeyLabel = g_ui.createWidget('HotkeyListLabel')
    hotkeyLabel:setId(keyCombo)

    local children = currentHotkeys:getChildren()
    children[#children+1] = hotkeyLabel
    table.sort(children, function(a,b)
      if a:getId():len() < b:getId():len() then
        return true
      elseif a:getId():len() == b:getId():len() then
        return a:getId() < b:getId()
      else
        return false
      end
    end)
    for i=1,#children do
      if children[i] == hotkeyLabel then
        currentHotkeys:insertChild(i, hotkeyLabel)
        break
      end
    end
  end

  if keySettings then
    if keySettings.hotkeyBar then
      keySettings.hotkeyBar:addHotkey(keyCombo, keySettings.mousePos)
    end
    currentHotkeyLabel = hotkeyLabel
    hotkeyLabel.keyCombo = keyCombo
    if keySettings.item then
      hotkeyLabel.autoSend = true
      hotkeyLabel.itemId = keySettings.item:getId()
      if keySettings.item:isFluidContainer() then
          currentHotkeyLabel.subType = keySettings.item:getSubType()
      end
      if keySettings.item:isMultiUse() then
        currentHotkeyLabel.useType = HOTKEY_MANAGER_USEWITH
      else
        currentHotkeyLabel.useType = HOTKEY_MANAGER_USE
      end
    elseif keySettings.powerId then
      hotkeyLabel.value = '/power ' .. keySettings.powerId
      hotkeyLabel.autoSend = true
      hotkeyLabel.itemId = nil
      hotkeyLabel.subType = nil
      hotkeyLabel.useType = nil
    else
      local powerId = getPowerIdByString(keySettings.value or '')
      keySettings.autoSend = powerId and true or keySettings.autoSend
      hotkeyLabel.autoSend = toboolean(keySettings.autoSend)
      hotkeyLabel.itemId = tonumber(keySettings.itemId)
      hotkeyLabel.subType = tonumber(keySettings.subType)
      hotkeyLabel.useType = tonumber(keySettings.useType)
      if keySettings.value then hotkeyLabel.value = tostring(keySettings.value) end
    end
    ok()
  else
    hotkeyLabel.keyCombo = keyCombo
    hotkeyLabel.autoSend = false
    hotkeyLabel.itemId = nil
    hotkeyLabel.subType = nil
    hotkeyLabel.useType = nil
    hotkeyLabel.value = ''
  end
  boundCombosCallback[keyCombo] = function() doKeyCombo(keyCombo) end
  g_keyboard.bindKeyPress(keyCombo, boundCombosCallback[keyCombo])
  updateHotkeyLabel(hotkeyLabel)
  if focus then
    currentHotkeys:focusChild(hotkeyLabel)
    currentHotkeys:ensureChildVisible(hotkeyLabel)
    updateHotkeyForm(true)
  end
end

function doKeyCombo(keyCombo, clickedWidget)
  if not g_game.isOnline() then return end
  local hotKey = hotkeyList[keyCombo]
  if not hotKey then return end

  if g_clock.millis() - lastHotkeyTime < modules.client_options.getOption('hotkeyDelay') then
    return
  end
  lastHotkeyTime = g_clock.millis()

  if hotKey.itemId == nil then
    if not hotKey.value or #hotKey.value == 0 then return end
    if hotKey.autoSend then
      local powerId = getPowerIdByString(hotKey.value)
      if powerId then
        -- Should not work with right button because onMouseRelease is not working the the right mouse button
        if clickedWidget and g_mouse.isPressed(MouseRightButton) then
          return
        end

        if powerBoost_lastPower == 0 then
          powerBoost_lastPower = tonumber(powerId) or 0
          powerBoost_keyCombo = keyCombo
          powerBoost_startAt = g_clock.millis()

          sendPowerBoostStart()
          if modules.ka_game_hotkeybars then
            modules.ka_game_hotkeybars.setPowerIcon(powerBoost_keyCombo, true)
          end

          -- By mouse click
          if clickedWidget then
            powerBoost_clickedWidget = clickedWidget
            connect(clickedWidget, {
              onMouseRelease = function(widget, mousePos, mouseButton, elapsedTime)
                -- Should not work with right button because onMouseRelease is not working the the right mouse button
                if g_mouse.isPressed(MouseLeftButton) then -- If right released and left kept pressed
                  return
                end
                if not widget:containsPoint(mousePos) then
                  cancelPower()
                  return
                end
                sendPower(nil, powerBoost_keyCombo)
                disconnect(clickedWidget, 'onMouseRelease')
                if modules.ka_game_hotkeybars then
                  modules.ka_game_hotkeybars.setPowerIcon(powerBoost_keyCombo, false)
                end
                scheduleEvent(function()
                  powerBoost_lastPower = 0
                  powerBoost_keyCombo = nil
                end, 500)
            end})

          -- By keyboard press
          else
            g_keyboard.bindKeyUp(keyCombo, function ()
              g_keyboard.unbindKeyUp(keyCombo)
              sendPower(nil, powerBoost_keyCombo)
              if modules.ka_game_hotkeybars then
                modules.ka_game_hotkeybars.setPowerIcon(powerBoost_keyCombo, false)
              end
              scheduleEvent(function()
                powerBoost_lastPower = 0
                powerBoost_keyCombo = nil
              end, 500)
            end)
          end
        elseif powerBoost_lastPower > 0 then
          local elapsedTime = g_clock.millis() - powerBoost_startAt
          if elapsedTime > powerBoost_maxTime then
            cancelPower(true)
          end
        end
        return
      end

      modules.game_console.sendMessage(hotKey.value)
    else
      modules.game_console.setTextEditText(hotKey.value)
    end
  elseif hotKey.useType == HOTKEY_MANAGER_USE then
    if g_game.getClientVersion() < 780 or hotKey.subType then
      local item = g_game.findPlayerItem(hotKey.itemId, hotKey.subType or -1)
      if item then
        g_game.use(item)
      end
    else
      g_game.useInventoryItem(hotKey.itemId)
    end
  --[[
  elseif hotKey.useType == HOTKEY_MANAGER_USEONSELF then
    if g_game.getClientVersion() < 780 or hotKey.subType then
      local item = g_game.findPlayerItem(hotKey.itemId, hotKey.subType or -1)
      if item then
        g_game.useWith(item, g_game.getLocalPlayer())
      end
    else
      g_game.useInventoryItemWith(hotKey.itemId, g_game.getLocalPlayer())
    end
  elseif hotKey.useType == HOTKEY_MANAGER_USEONTARGET then
    local attackingCreature = g_game.getAttackingCreature()
    if not attackingCreature then
      local item = Item.create(hotKey.itemId)
      if g_game.getClientVersion() < 780 or hotKey.subType then
        local tmpItem = g_game.findPlayerItem(hotKey.itemId, hotKey.subType or -1)
        if not tmpItem then return end
        item = tmpItem
      end

      modules.game_interface.startUseWith(item)
      return
    end

    if not attackingCreature:getTile() then return end
    if g_game.getClientVersion() < 780 or hotKey.subType then
      local item = g_game.findPlayerItem(hotKey.itemId, hotKey.subType or -1)
      if item then
        g_game.useWith(item, attackingCreature)
      end
    else
      g_game.useInventoryItemWith(hotKey.itemId, attackingCreature)
    end
  ]]
  elseif hotKey.useType == HOTKEY_MANAGER_USEWITH then
    local item = Item.create(hotKey.itemId)
    if g_game.getClientVersion() < 780 or hotKey.subType then
      local tmpItem = g_game.findPlayerItem(hotKey.itemId, hotKey.subType or -1)
      if not tmpItem then return end
      item = tmpItem
    end
    modules.game_interface.startUseWith(item)
  end
end

function getHotkey(keyCombo)
  if not g_game.isOnline() then return nil end
  local hotKey = hotkeyList[keyCombo]
  if not hotKey then return nil end
  if hotKey.itemId == nil then
    if not hotKey.value or #hotKey.value == 0 then return nil end
    -- if hotKey.autoSend then
      local powerId = getPowerIdByString(hotKey.value)
      if powerId then
        local ret = { type = 'power', id = powerId }
        if modules.ka_game_powers then
          local power = modules.ka_game_powers.getPower(powerId)
          if power then
            ret.name  = power.name
            ret.level = power.level
          end
        end
        return ret
      end
    -- end
    return {type = 'text', autoSend = hotKey.autoSend, value = hotKey.value}
  else
    return {type = 'item', id = hotKey.itemId, useType = hotKey.useType}
  end
end

function updateHotkeyLabel(hotkeyLabel)
  if not hotkeyLabel then return end
  --[[if hotkeyLabel.useType == HOTKEY_MANAGER_USEONSELF then
    hotkeyLabel:setText(tr('%s: [Item] Use object on yourself.', hotkeyLabel.keyCombo))
    hotkeyLabel:setColor(HotkeyColors.itemUseSelf)
  elseif hotkeyLabel.useType == HOTKEY_MANAGER_USEONTARGET then
    hotkeyLabel:setText(tr('%s: [Item] Use object on target.', hotkeyLabel.keyCombo))
    hotkeyLabel:setColor(HotkeyColors.itemUseTarget)]]
  if hotkeyLabel.useType == HOTKEY_MANAGER_USEWITH then
    hotkeyLabel:setText(tr('%s: [Item] Use object with crosshair.', hotkeyLabel.keyCombo))
    hotkeyLabel:setColor(HotkeyColors.itemUseWith)
  elseif hotkeyLabel.itemId ~= nil then
    hotkeyLabel:setText(tr('%s: [Item] Use object.', hotkeyLabel.keyCombo))
    hotkeyLabel:setColor(HotkeyColors.itemUse)
  else
    local text = hotkeyLabel.keyCombo .. ': '
    local powerId = getPowerIdByString(hotkeyLabel.value)
    if hotkeyLabel.value then
      if powerId then
        local power = modules.ka_game_powers and modules.ka_game_powers.getPower(powerId) or nil
        local name  = power and power.name or nil
        local level = power and power.level or nil
        text = string.format("%s[Power] %s", text, name and string.format('%s%s', name, level and string.format(' (level %d)', level) or '') or 'You are not able to use this power.')
      elseif hotkeyLabel.value ~= '' then
        text = text .. '[Text] ' .. hotkeyLabel.value
      end
    end
    hotkeyLabel:setText(text)
    if powerId then
      hotkeyLabel:setColor(HotkeyColors.powerColor)
    elseif hotkeyLabel.autoSend then
      hotkeyLabel:setColor(HotkeyColors.autoSend)
    else
      hotkeyLabel:setColor(HotkeyColors.text)
    end
  end
end

function updateHotkeyList()
  local hotkeys = currentHotkeys:getChildren()
  for _, hotkey in pairs(hotkeys) do
    updateHotkeyLabel(hotkey)
  end
end

function updateHotkeyForm(reset)
  if currentHotkeyLabel then
    local powerId = getPowerIdByString(currentHotkeyLabel.value)
    removeHotkeyButton:enable()
    hotKeyItemLabel:enable()
    currentItemPreview:setVisible(true)
    if currentHotkeyLabel.itemId ~= nil then
      hotKeyTextLabel:disable()
      hotkeyText:clearText()
      hotkeyText:disable()
      sendAutomatically:setChecked(false)
      sendAutomatically:disable()
      -- selectObjectButton:disable()
      -- clearObjectButton:enable()
      currentItemPreview:setIcon('')
      currentItemPreview:setItemId(currentHotkeyLabel.itemId)
      if currentHotkeyLabel.subType then
        currentItemPreview:setItemSubType(currentHotkeyLabel.subType)
      end
      --[[
      if currentItemPreview:getItem():isMultiUse() then
        useOnSelf:enable()
        useOnTarget:enable()
        useWith:enable()
        if currentHotkeyLabel.useType == HOTKEY_MANAGER_USEONSELF then
          useRadioGroup:selectWidget(useOnSelf)
        elseif currentHotkeyLabel.useType == HOTKEY_MANAGER_USEONTARGET then
          useRadioGroup:selectWidget(useOnTarget)
        if currentHotkeyLabel.useType == HOTKEY_MANAGER_USEWITH then
          useRadioGroup:selectWidget(useWith)
        end
      else
        useOnSelf:disable()
        useOnTarget:disable()
        useWith:disable()
        useRadioGroup:clearSelected()
      end
      ]]

    elseif powerId then
      -- useOnSelf:disable()
      -- useOnTarget:disable()
      local oldValue = currentHotkeyLabel.value
      hotKeyTextLabel:disable()
      hotkeyText:clearText()
      hotkeyText:disable()
      sendAutomatically:setChecked(true)
      sendAutomatically:disable()
      -- selectObjectButton:disable()
      -- clearObjectButton:enable()
      currentItemPreview:setIcon('/images/game/powers/' .. powerId .. '_off')
      -- useWith:disable()
      -- useRadioGroup:clearSelected()
      -- Keeps hotkeyText invisible
      currentHotkeyLabel.value = oldValue
      updateHotkeyLabel(currentHotkeyLabel)

    else
      -- useOnSelf:disable()
      -- useOnTarget:disable()
      -- useWith:disable()
      -- useRadioGroup:clearSelected()
      hotKeyTextLabel:enable()
      hotkeyText:enable()
      hotkeyText:focus()
      if reset then
        hotkeyText:setCursorPos(-1)
      end
      hotkeyText:setText(currentHotkeyLabel.value)
      sendAutomatically:setChecked(currentHotkeyLabel.autoSend)
      sendAutomatically:setEnabled(currentHotkeyLabel.value and #currentHotkeyLabel.value > 0)
      -- selectObjectButton:enable()
      -- clearObjectButton:disable()
      currentItemPreview:setIcon('')
      currentItemPreview:clearItem()
    end
  else
    removeHotkeyButton:disable()
    hotKeyTextLabel:disable()
    hotkeyText:disable()
    hotkeyText:clearText()
    sendAutomatically:disable()
    -- selectObjectButton:disable()
    -- clearObjectButton:disable()
    -- useOnSelf:disable()
    -- useOnTarget:disable()
    -- useWith:disable()
    -- useRadioGroup:clearSelected()
    sendAutomatically:setChecked(false)
    hotKeyItemLabel:disable()
    currentItemPreview:setIcon('')
    currentItemPreview:clearItem()
    currentItemPreview:setVisible(false)
  end
end

function removeHotkey()
  if not currentHotkeyLabel then return end
  g_keyboard.unbindKeyPress(currentHotkeyLabel.keyCombo, boundCombosCallback[currentHotkeyLabel.keyCombo])
  boundCombosCallback[currentHotkeyLabel.keyCombo] = nil
  currentHotkeyLabel:destroy()
  currentHotkeyLabel = nil
end

function onHotkeyTextChange(value)
  if not hotkeysManagerLoaded then return end
  if not currentHotkeyLabel then return end
  currentHotkeyLabel.value = value
  local powerId = getPowerIdByString(currentHotkeyLabel.value)
  if value == '' then
    currentHotkeyLabel.autoSend = false
  elseif powerId then
    currentHotkeyLabel.autoSend = true
  end
  updateHotkeyLabel(currentHotkeyLabel)
  updateHotkeyForm()
end

function onSendAutomaticallyChange(autoSend)
  if not hotkeysManagerLoaded then return end
  if not currentHotkeyLabel then return end
  if not currentHotkeyLabel.value or #currentHotkeyLabel.value == 0 then return end
  currentHotkeyLabel.autoSend = autoSend
  updateHotkeyLabel(currentHotkeyLabel)
  updateHotkeyForm()
end

function onChangeUseType(useTypeWidget)
  if not hotkeysManagerLoaded then return end
  if not currentHotkeyLabel then return end
  --[[
  if useTypeWidget == useOnSelf then
    currentHotkeyLabel.useType = HOTKEY_MANAGER_USEONSELF
  elseif useTypeWidget == useOnTarget then
    currentHotkeyLabel.useType = HOTKEY_MANAGER_USEONTARGET
  ]]
  if useTypeWidget == useWith then
    currentHotkeyLabel.useType = HOTKEY_MANAGER_USEWITH
  else
    currentHotkeyLabel.useType = HOTKEY_MANAGER_USE
  end
  updateHotkeyLabel(currentHotkeyLabel)
  updateHotkeyForm()
end

function onSelectHotkeyLabel(hotkeyLabel)
  currentHotkeyLabel = hotkeyLabel
  updateHotkeyForm(true)
end

function hotkeyCapture(assignWindow, keyCode, keyboardModifiers)
  local keyCombo = determineKeyComboDesc(keyCode, keyboardModifiers)
  local comboPreview = assignWindow:getChildById('comboPreview')
  comboPreview:setText(tr('Current hotkey to add') .. ': ' .. keyCombo)
  comboPreview.keyCombo = keyCombo
  comboPreview:resizeToText()
  assignWindow:getChildById('addButton'):enable()
  return true
end

function isOpen()
  return hotkeysWindow:isVisible()
end





-- Power

-- Power.getIdByString
function getPowerIdByString(str)
  str = str and tostring(str) or ''
  return tonumber(str:match('/power (%d+)'))
end

-- Power.send
function sendPower(flag, keyCombo) -- ([flag], [keyCombo]) -- (flag: powerFlags)
  local mapWidget = modules.game_interface.getMapPanel()
  if not mapWidget then return end

  local toPos = mapWidget:getPosition(g_window.getMousePosition())

  -- If has flag, send flag instead of power id
  if flag then
    g_game.sendPowerProtocolData(string.format("%d:%d:%d:%d", flag, 0, 0, 0))
    return
  end

  -- Send power id and mouse position
  g_game.sendPowerProtocolData(string.format("%d:%d:%d:%d", powerBoost_lastPower, toPos.x, toPos.y, toPos.z))

  removePowerBoostEffect()
  if keyCombo then
    if modules.ka_game_hotkeybars and lastHotkeyTime > 0 then
      local boostTime  = g_clock.millis() - lastHotkeyTime
      local boostLevel = math.min(math.max(powerBoost_first, math.ceil(boostTime / powerBoost_time)), powerBoost_last)
      modules.ka_game_hotkeybars.addPowerSendingHotkeyEffect(keyCombo, boostLevel)
    end
  end
end

-- Power.sendBoostStart
function sendPowerBoostStart()
  sendPower(power_flag_start)
  addPowerBoostEffect()
end

-- Power.cancel
function cancelPower(forceStop)
  if not g_game.isOnline() then
    return
  end

  sendPower(power_flag_cancel)
  removePowerBoostEffect()

  if modules.ka_game_hotkeybars then
    modules.ka_game_hotkeybars.setPowerIcon(powerBoost_keyCombo, false)
  end

  if forceStop then
    powerBoost_lastPower = -1
    scheduleEvent(function() powerBoost_lastPower = 0 end, 1000)
  else
    powerBoost_lastPower = 0
  end

  if powerBoost_clickedWidget then
    disconnect(powerBoost_clickedWidget, 'onMouseRelease')
  else
    if powerBoost_keyCombo then
      g_keyboard.unbindKeyUp(powerBoost_keyCombo)
    end
  end

  powerBoost_keyCombo      = nil
  powerBoost_clickedWidget = nil
  powerBoost_startAt       = nil
end

function removePowerBoostColor()
  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer then return end

  powerBoost_state_color = false
  localPlayer:setColor(0, 0, 0, 0)

  if powerBoost_event_color then
    removeEvent(powerBoost_event_color)
    powerBoost_event_color = nil
  end
end

function removePowerBoostImage()
  powerBoost_state_image = false
  if modules.ka_game_screenimage then
    for boostLevel = powerBoost_first, powerBoost_last do
      modules.ka_game_screenimage.removeImage(string.format("system/power_boost/normal_%d.png", boostLevel), powerBoost_fadeout, 0)
      modules.ka_game_screenimage.removeImage(string.format("system/power_boost/extra_%d.png", boostLevel), powerBoost_fadeout, 0)
    end
  end

  if powerBoost_event_image then
    removeEvent(powerBoost_event_image)
    powerBoost_event_image = nil
  end
end

function setPowerBoostColor(boostTime, light) -- ([boostTime[, light]])
  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer then return end

  local boostLevel = powerBoost_first

  boostTime  = boostTime and boostTime + powerBoost_color_speed or 0
  light      = light == nil and true or not light
  boostLevel = math.min(math.max(powerBoost_first, math.ceil(boostTime / powerBoost_time)), powerBoost_last)

  if boostTime == 0 then
    removePowerBoostColor()
    powerBoost_state_color = true
  end

  local ret = false
  if powerBoost_state_color then
    localPlayer:setColor(powerBoost_color[boostLevel].r or powerBoost_color_default.r, powerBoost_color[boostLevel].g or powerBoost_color_default.g, powerBoost_color[boostLevel].b or powerBoost_color_default.b, light and 255 or 0)
    powerBoost_event_color = scheduleEvent(function() setPowerBoostColor(boostTime, light) end, powerBoost_color_speed)
    ret = true
  end
  return ret
end

function setPowerBoostImage(boostTime) -- ([boostTime])
  local boostLevel = powerBoost_first

  boostTime  = boostTime and boostTime + powerBoost_time or 0
  boostLevel = math.min(math.max(powerBoost_first, math.ceil(boostTime / powerBoost_time)), powerBoost_last)

  if boostLevel == 1 then
    removePowerBoostImage()
    powerBoost_state_image = true
  else
    if modules.ka_game_screenimage then
      modules.ka_game_screenimage.removeImage(string.format("system/power_boost/normal_%d.png", boostLevel - 1), powerBoost_fadeout, 0)
      modules.ka_game_screenimage.removeImage(string.format("system/power_boost/extra_%d.png", boostLevel - 1), powerBoost_fadeout, 0)
    end
  end

  local ret = false
  if powerBoost_state_image then
    if modules.ka_game_screenimage and boostTime ~= 0 then
      modules.ka_game_screenimage.addImage(string.format("system/power_boost/normal_%d.png", boostLevel), powerBoost_fadein, 1, powerBoost_resizex, powerBoost_resizey, 0)
      modules.ka_game_screenimage.addImage(string.format("system/power_boost/extra_%d.png", boostLevel), powerBoost_fadein, 1, powerBoost_resizex, powerBoost_resizey, 0)
    end

    powerBoost_event_image = scheduleEvent(function() setPowerBoostImage(boostTime) end, boostTime ~= 0 and powerBoost_time or 0)
    ret = true
  end
  return ret
end

function removePowerBoostEffect()
  removePowerBoostColor()
  removePowerBoostImage()
end

function addPowerBoostEffect()
  setPowerBoostColor()
  setPowerBoostImage()
end

function dropOnItemPreview(self, widget, mousePos)
  if not currentHotkeyLabel then return false end
  local item = nil
  local widgetClass = widget:getClassName()
  if widgetClass == 'UIPowerButton' then
    local powerId = widget.power.id
    currentHotkeyLabel.itemId = nil
    currentHotkeyLabel.value = '/power ' .. powerId
    currentHotkeyLabel.autoSend = true
    currentHotkeyLabel.useType = nil
  elseif widgetClass == 'UIItem' then
    item = widget:getItem()
  elseif widgetClass == 'UIGameMap' then
    item = widget.currentDragThing
  end

  if item then
    currentHotkeyLabel.itemId = item:getId()
    if item:isFluidContainer() then
        currentHotkeyLabel.subType = item:getSubType()
    end
    if item:isMultiUse() then
      currentHotkeyLabel.useType = HOTKEY_MANAGER_USEWITH
    else
      currentHotkeyLabel.useType = HOTKEY_MANAGER_USE
    end
    currentHotkeyLabel.value = nil
    currentHotkeyLabel.autoSend = false
  end
  updateHotkeyLabel(currentHotkeyLabel)
  updateHotkeyForm(true)
  if modules.ka_game_hotkeybars then
    modules.ka_game_hotkeybars.onUpdateHotkeys()
  end
  return true
end

function dragEnterItemPreview(self, mousePos)
  self:setBorderWidth(1)
  g_mouse.pushCursor('target')

  local powerId = getPowerIdByString(currentHotkeyLabel.value)
  local item    = self:getItem()
  if powerId then
    g_mouseicon.display(string.format('/images/game/powers/%d_off', powerId))
  elseif item and item:isPickupable() then
    g_mouseicon.displayItem(item)
  end

  return true
end

function dragLeaveItemPreview(self, droppedWidget, mousePos)
  g_mouseicon.hide()
  g_mouse.popCursor('target')
  self:setBorderWidth(0)
  clearObject()
  return true
end

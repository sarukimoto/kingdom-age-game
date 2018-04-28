dofiles('ui')

HOTKEY_MANAGER_USE = nil
--HOTKEY_MANAGER_USEONSELF = 1
--HOTKEY_MANAGER_USEONTARGET = 2
HOTKEY_MANAGER_USEWITH = 3

HotkeyColors = {
  text = '#333B43',
  textAutoSend = '#FFFFFF',
  itemUse = '#AEF2FF',
  itemUseSelf = '#0042FF',
  itemUseTarget = '#EC1414',
  itemUseWith = '#F8E127',
  powerColor = '#CD4EFF'
}

hotkeysManagerLoaded = false
hotkeysWindow = nil
hotkeysButton = nil
currentHotkeyLabel = nil
currentItemPreview = nil
itemWidget = nil
addHotkeyButton = nil
removeHotkeyButton = nil
hotkeyText = nil
hotKeyTextLabel = nil
sendAutomatically = nil
selectObjectButton = nil
clearObjectButton = nil
--useOnSelf = nil
--useOnTarget = nil
useWith = nil
defaultComboKeys = nil
perServer = true
perCharacter = true
mouseGrabberWidget = nil
useRadioGroup = nil
currentHotkeys = nil
boundCombosCallback = {}
hotkeysList = {}

-- Power
Power = {}
boost_lastPower         = 0
boost_keycombo          = nil
boost_clickedWidget     = nil
boost_startAt           = nil
boost_maxTime           = 60 * 1000
boost_time              = 1000
boost_timeAdditionEvent = nil

local powerFlag_boostStart  = -1
local powerFlag_boostCancel = -2
local powerFlags = { powerFlag_boostStart, powerFlag_boostCancel }

-- public functions
function init()
  g_ui.importStyle('hotkeylabel.otui')

  hotkeysButton = modules.client_topmenu.addLeftGameButton('hotkeysButton', tr('Hotkeys') .. ' (Ctrl+K)', '/images/topbuttons/hotkeys', toggle)
  g_keyboard.bindKeyDown('Ctrl+K', toggle)
  hotkeysWindow = g_ui.displayUI('hotkeys_manager')
  hotkeysWindow:setVisible(false)

  currentHotkeys = hotkeysWindow:getChildById('currentHotkeys')
  currentItemPreview = hotkeysWindow:getChildById('itemPreview')
  addHotkeyButton = hotkeysWindow:getChildById('addHotkeyButton')
  removeHotkeyButton = hotkeysWindow:getChildById('removeHotkeyButton')
  hotkeyText = hotkeysWindow:getChildById('hotkeyText')
  hotKeyTextLabel = hotkeysWindow:getChildById('hotKeyTextLabel')
  sendAutomatically = hotkeysWindow:getChildById('sendAutomatically')
  selectObjectButton = hotkeysWindow:getChildById('selectObjectButton')
  clearObjectButton = hotkeysWindow:getChildById('clearObjectButton')
  --useOnSelf = hotkeysWindow:getChildById('useOnSelf')
  --useOnTarget = hotkeysWindow:getChildById('useOnTarget')
  useWith = hotkeysWindow:getChildById('useWith')

  useRadioGroup = UIRadioGroup.create()
  --useRadioGroup:addWidget(useOnSelf)
  --useRadioGroup:addWidget(useOnTarget)
  useRadioGroup:addWidget(useWith)
  useRadioGroup.onSelectionChange = function(self, selected) onChangeUseType(selected) end

  mouseGrabberWidget = g_ui.createWidget('UIWidget')
  mouseGrabberWidget:setVisible(false)
  mouseGrabberWidget:setFocusable(false)
  mouseGrabberWidget.onMouseRelease = onChooseItemMouseRelease

  currentHotkeys.onChildFocusChange = function(self, hotkeyLabel) onSelectHotkeyLabel(hotkeyLabel) end
  g_keyboard.bindKeyPress('Down', function() currentHotkeys:focusNextChild(KeyboardFocusReason) end, hotkeysWindow)
  g_keyboard.bindKeyPress('Up', function() currentHotkeys:focusPreviousChild(KeyboardFocusReason) end, hotkeysWindow)

  g_keyboard.bindKeyPress('Escape', function() Power.cancel(true) end, rootWidget)
  connect(g_game, {
    onGameStart = online,
    onGameEnd = offline
  })

  load()
end

function terminate()
  disconnect(g_game, {
    onGameStart = online,
    onGameEnd = offline
  })

  g_keyboard.unbindKeyDown('Ctrl+K')

  unload()

  hotkeysWindow:destroy()
  hotkeysButton:destroy()
  mouseGrabberWidget:destroy()
end

function configure(savePerServer, savePerCharacter)
  perServer = savePerServer
  perCharacter = savePerCharacter
  reload()
end

function online()
  scheduleEvent(function()
    reload()
    modules.ka_hotkeybars.onUpdateHotkeys()
  end, 10)
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
  modules.ka_hotkeybars.updateDraggable(true)
  hotkeysWindow:show()
  hotkeysWindow:raise()
  hotkeysWindow:focus()
  hotkeysButton:setOn(true)
end

function hide()
  hotkeysWindow:hide()
  modules.ka_hotkeybars.updateDraggable(false)
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
  modules.ka_hotkeybars.onUpdateHotkeys()
  hide()
end

function cancel()
  reload()
  hide()
end

function load(forceDefaults)
  hotkeysManagerLoaded = false

  local hotkeySettings = g_settings.getNode('game_hotkeys')
  local hotkeys = {}

  if not table.empty(hotkeySettings) then hotkeys = hotkeySettings end
  if perServer and not table.empty(hotkeys) then hotkeys = hotkeys[G.host] end
  if perCharacter and not table.empty(hotkeys) then hotkeys = hotkeys[g_game.getCharacterName()] end

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

  if currentHotkeys:getChildCount() == 0 then
    loadDefautComboKeys()
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
  local hotkeySettings = g_settings.getNode('game_hotkeys') or {}
  local hotkeys = hotkeySettings

  if perServer then
    if not hotkeys[G.host] then
      hotkeys[G.host] = {}
    end
    hotkeys = hotkeys[G.host]
  end

  if perCharacter then
    local char = g_game.getCharacterName()
    if not hotkeys[char] then
      hotkeys[char] = {}
    end
    hotkeys = hotkeys[char]
  end

  table.clear(hotkeys)

  for _,child in pairs(currentHotkeys:getChildren()) do
    local powerId = Power.getIdByString(child.value)
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
  g_settings.setNode('game_hotkeys', hotkeySettings)
  g_settings.save()
end

function loadDefautComboKeys()
  if not defaultComboKeys then
    for i=1,12 do
      addKeyCombo('F' .. i)
    end
    for i=1,4 do
      addKeyCombo('Shift+F' .. i)
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
      if clickedId:match('power_%d+') then
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
    modules.ka_hotkeybars.onUpdateHotkeys()
  end

  show()

  g_mouse.popCursor('target')
  self:ungrabMouse()
  return true
end

function startChooseItem()
  if g_ui.isMouseGrabbed() then return end
  mouseGrabberWidget:grabMouse()
  g_mouse.pushCursor('target')
  hide()
end

function clearObject()
  currentHotkeyLabel.itemId = nil
  currentHotkeyLabel.subType = nil
  currentHotkeyLabel.useType = nil
  currentHotkeyLabel.autoSend = nil
  currentHotkeyLabel.value = nil
  updateHotkeyLabel(currentHotkeyLabel)
  updateHotkeyForm(true)
  modules.ka_hotkeybars.onUpdateHotkeys()
end

function addHotkey()
  local assignWindow = g_ui.createWidget('HotkeyAssignWindow', rootWidget)
  assignWindow:grabKeyboard()

  local comboLabel = assignWindow:getChildById('comboPreview')
  comboLabel.keyCombo = ''
  assignWindow.onKeyDown = hotkeyCapture
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

    if keySettings then
      local powerId = Power.getIdByString(keySettings.value or '')
      currentHotkeyLabel = hotkeyLabel
      hotkeyLabel.keyCombo = keyCombo
      keySettings.autoSend = powerId and true or keySettings.autoSend
      hotkeyLabel.autoSend = toboolean(keySettings.autoSend)
      hotkeyLabel.itemId = tonumber(keySettings.itemId)
      hotkeyLabel.subType = tonumber(keySettings.subType)
      hotkeyLabel.useType = tonumber(keySettings.useType)
      if keySettings.value then hotkeyLabel.value = tostring(keySettings.value) end
    else
      hotkeyLabel.keyCombo = keyCombo
      hotkeyLabel.autoSend = false
      hotkeyLabel.itemId = nil
      hotkeyLabel.subType = nil
      hotkeyLabel.useType = nil
      hotkeyLabel.value = ''
    end

    updateHotkeyLabel(hotkeyLabel)

    boundCombosCallback[keyCombo] = function() doKeyCombo(keyCombo) end
    g_keyboard.bindKeyPress(keyCombo, boundCombosCallback[keyCombo])
  end

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

  if hotKey.itemId == nil then
    if not hotKey.value or #hotKey.value == 0 then return end
    if hotKey.autoSend then
      local powerId = Power.getIdByString(hotKey.value)
      if powerId then
        if boost_lastPower == 0 then
          boost_lastPower     = tonumber(powerId)
          boost_keycombo      = keyCombo
          boost_clickedWidget = clickedWidget
          boost_startAt       = g_clock.millis()

          Power.sendBoostStart()
          modules.ka_hotkeybars.setPowerIcon(boost_keycombo, true)

          if clickedWidget then
            connect(boost_clickedWidget, {
              onMouseRelease = function(widget, mousePos, mouseButton, elapsedTime)
                if not widget:containsPoint(mousePos) then
                  Power.cancel()
                  return
                end
                Power.send()
                disconnect(boost_clickedWidget, 'onMouseRelease')
                modules.ka_hotkeybars.setPowerIcon(boost_keycombo, false)
                scheduleEvent(function()
                  boost_lastPower = 0
                  boost_keycombo = nil
                end, 500)
            end})
          else
            g_keyboard.bindKeyUp(keyCombo, function ()
              Power.send()
              g_keyboard.unbindKeyUp(keyCombo)
              modules.ka_hotkeybars.setPowerIcon(boost_keycombo, false)
              scheduleEvent(function()
                boost_lastPower = 0
                boost_keycombo = nil
              end, 500)
            end)
          end
        elseif boost_lastPower > 0 then
          local elapsedTime = g_clock.millis() - boost_startAt
          if elapsedTime > boost_maxTime then
            Power.cancel(true)
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
      if not tmpItem then return true end
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
    --if hotKey.autoSend then
      local powerId = Power.getIdByString(hotKey.value)
      if powerId then
        local ret = { type = 'power', id = powerId }
        local power = modules.ka_powerslist.getPower(powerId)
        if power then
          ret.data =
          {
            name  = power.name,
            level = power.level
          }
        end
        return ret
      end
    --end
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
    local powerId = Power.getIdByString(hotkeyLabel.value)
    if hotkeyLabel.value then
      if powerId then
        local name = Power.getNameById(powerId)
        text = text .. (name ~= '' and name or '[Power] You are not able to use this power.')
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

function updateHotkeyForm(reset)
  if currentHotkeyLabel then
    local powerId = Power.getIdByString(currentHotkeyLabel.value)
    removeHotkeyButton:enable()
    if currentHotkeyLabel.itemId ~= nil then
      hotkeyText:clearText()
      hotkeyText:disable()
      hotKeyTextLabel:disable()
      sendAutomatically:setChecked(false)
      sendAutomatically:disable()
      selectObjectButton:disable()
      clearObjectButton:enable()
      currentItemPreview:setIcon('')
      currentItemPreview:setItemId(currentHotkeyLabel.itemId)
      if currentHotkeyLabel.subType then
        currentItemPreview:setItemSubType(currentHotkeyLabel.subType)
      end
      if currentItemPreview:getItem():isMultiUse() then
        --useOnSelf:enable()
        --useOnTarget:enable()
        useWith:enable()
        --[[if currentHotkeyLabel.useType == HOTKEY_MANAGER_USEONSELF then
          useRadioGroup:selectWidget(useOnSelf)
        elseif currentHotkeyLabel.useType == HOTKEY_MANAGER_USEONTARGET then
          useRadioGroup:selectWidget(useOnTarget)]]
        if currentHotkeyLabel.useType == HOTKEY_MANAGER_USEWITH then
          useRadioGroup:selectWidget(useWith)
        end
      else
        --useOnSelf:disable()
        --useOnTarget:disable()
        useWith:disable()
        useRadioGroup:clearSelected()
      end

    elseif powerId then
      --useOnSelf:disable()
      --useOnTarget:disable()
      useWith:disable()
      useRadioGroup:clearSelected()
      hotkeyText:disable()
      hotKeyTextLabel:enable()
      sendAutomatically:setChecked(currentHotkeyLabel.autoSend)
      sendAutomatically:disable()
      selectObjectButton:disable()
      clearObjectButton:enable()
      currentItemPreview:setIcon('/images/game/powers/' .. powerId .. '_off')

    else
      --useOnSelf:disable()
      --useOnTarget:disable()
      useWith:disable()
      useRadioGroup:clearSelected()
      hotkeyText:enable()
      hotkeyText:focus()
      hotKeyTextLabel:enable()
      if reset then
        hotkeyText:setCursorPos(-1)
      end
      hotkeyText:setText(currentHotkeyLabel.value)
      sendAutomatically:setChecked(currentHotkeyLabel.autoSend)
      sendAutomatically:setEnabled(currentHotkeyLabel.value and #currentHotkeyLabel.value > 0)
      selectObjectButton:enable()
      clearObjectButton:disable()
      currentItemPreview:setIcon('')
      currentItemPreview:clearItem()
    end
  else
    removeHotkeyButton:disable()
    hotkeyText:disable()
    sendAutomatically:disable()
    selectObjectButton:disable()
    clearObjectButton:disable()
    --useOnSelf:disable()
    --useOnTarget:disable()
    useWith:disable()
    hotkeyText:clearText()
    useRadioGroup:clearSelected()
    sendAutomatically:setChecked(false)
    currentItemPreview:setIcon('')
    currentItemPreview:clearItem()
  end
end

function removeHotkey()
  if currentHotkeyLabel == nil then return end
  g_keyboard.unbindKeyPress(currentHotkeyLabel.keyCombo, boundCombosCallback[currentHotkeyLabel.keyCombo])
  boundCombosCallback[currentHotkeyLabel.keyCombo] = nil
  currentHotkeyLabel:destroy()
  currentHotkeyLabel = nil
end

function onHotkeyTextChange(value)
  if not hotkeysManagerLoaded then return end
  if currentHotkeyLabel == nil then return end
  currentHotkeyLabel.value = value
  local powerId = Power.getIdByString(currentHotkeyLabel.value)
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
  if currentHotkeyLabel == nil then return end
  if not currentHotkeyLabel.value or #currentHotkeyLabel.value == 0 then return end
  currentHotkeyLabel.autoSend = autoSend
  updateHotkeyLabel(currentHotkeyLabel)
  updateHotkeyForm()
end

function onChangeUseType(useTypeWidget)
  if not hotkeysManagerLoaded then return end
  if currentHotkeyLabel == nil then return end
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

function hotkeyCaptureOk(assignWindow, keyCombo)
  addKeyCombo(keyCombo, nil, true)
  assignWindow:destroy()
end

function isOpen()
  return hotkeysWindow:isVisible()
end





-- Power

function getPower()       return Power end
function getLastPowerId() return boost_lastPower end

function Power.getNameById(id) -- Not implemented yet
  if not id then return '' end
  local power = rootWidget:recursiveGetChildById('power_' .. id)
  return power and power.name or ''
end

function Power.getIdByString(str)
  str = str and tostring(str) or ''
  return tonumber(str:match('/power (%d+)'))
end

function Power.send(flag) -- ([flag]) -- (flag: powerFlags)
  local protocol = g_game.getProtocolGame()
  if not protocol then return end
  local mapWidget = modules.game_interface.getMapPanel()
  if not mapWidget then return end

  local toPos = mapWidget:getPosition(g_window.getMousePosition())

  -- If has flag, send flag instead of power id
  if flag and table.contains(powerFlags, flag) then
    protocol:sendExtendedOpcode(ClientOpcodes.ClientPower, string.format("%d:%d:%d:%d", flag, 0, 0, 0))
    return
  end

  -- Send power id and mouse position
  protocol:sendExtendedOpcode(ClientOpcodes.ClientPower, string.format("%d:%d:%d:%d", boost_lastPower, toPos.x, toPos.y, toPos.z))
end

function Power.sendBoostStart()
  Power.send(powerFlag_boostStart)
end

function Power.cancel(forceStop)
  Power.send(powerFlag_boostCancel)

  modules.ka_hotkeybars.setPowerIcon(boost_keycombo, false)

  if forceStop then
    boost_lastPower = -1
    scheduleEvent(function() boost_lastPower = 0 end, 1000)
  else
    boost_lastPower = 0
  end

  if boost_clickedWidget then
    disconnect(boost_clickedWidget, 'onMouseRelease')
  else
    if boost_keycombo then
      g_keyboard.unbindKeyUp(boost_keycombo)
    end
  end

  boost_keycombo      = nil
  boost_clickedWidget = nil
  boost_startAt       = nil
end

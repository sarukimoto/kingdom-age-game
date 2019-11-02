DefaultFont = 'verdana-11px-rounded'

MessageSettings = {
  none            = {},
  consoleRed      = { color = TextColors.red,       consoleTab='Default' },
  consoleOrange   = { color = TextColors.orange,    consoleTab='Default' },
  consoleBlue     = { color = TextColors.blue,      consoleTab='Default' },
  centerRed       = { color = TextColors.red,       consoleTab='Server', screenTarget='lowCenterLabel' },
  centerGreen     = { color = TextColors.green,     consoleTab='Server', screenTarget='highCenterLabel',   consoleOption='showInfoMessagesInConsole' },
  centerWhite     = { color = TextColors.white,     consoleTab='Server', screenTarget='middleCenterLabel', consoleOption='showEventMessagesInConsole' },
  bottomWhite     = { color = TextColors.white,     consoleTab='Server', screenTarget='statusLabel',       consoleOption='showEventMessagesInConsole' },
  status          = { color = TextColors.white,     consoleTab='Server', screenTarget='statusLabel',       consoleOption='showStatusMessagesInConsole' },
  statusSmall     = { color = TextColors.white,                          screenTarget='statusLabel' },
  private         = { color = TextColors.lightblue,                      screenTarget='privateLabel' },
  statusBigTop    = { color = '#e1e1e1',            consoleTab='Server', screenTarget='privateLabel',      consoleOption='showStatusMessagesInConsole', font='sans-bold-borded-16px' },
  statusBigCenter = { color = '#e1e1e1',            consoleTab='Server', screenTarget='middleCenterLabel', consoleOption='showStatusMessagesInConsole', font='sans-bold-borded-16px' },
  statusBigBottom = { color = '#e1e1e1',            consoleTab='Server', screenTarget='statusLabel',       consoleOption='showStatusMessagesInConsole', font='sans-bold-borded-16px' },
}

MessageTypes = {
  [MessageModes.MonsterSay] = MessageSettings.consoleOrange,
  [MessageModes.MonsterYell] = MessageSettings.consoleOrange,
  [MessageModes.BarkLow] = MessageSettings.consoleOrange,
  [MessageModes.BarkLoud] = MessageSettings.consoleOrange,
  [MessageModes.Failure] = MessageSettings.statusSmall,
  [MessageModes.Login] = MessageSettings.bottomWhite,
  [MessageModes.Game] = MessageSettings.centerWhite,
  [MessageModes.Status] = MessageSettings.status,
  [MessageModes.Warning] = MessageSettings.centerRed,
  [MessageModes.Look] = MessageSettings.centerGreen,
  [MessageModes.Loot] = MessageSettings.centerGreen,
  [MessageModes.Red] = MessageSettings.consoleRed,
  [MessageModes.Blue] = MessageSettings.consoleBlue,
  [MessageModes.PrivateFrom] = MessageSettings.consoleBlue,

  [MessageModes.GamemasterBroadcast] = MessageSettings.consoleRed,

  [MessageModes.DamageDealed] = MessageSettings.status,
  [MessageModes.DamageReceived] = MessageSettings.status,
  [MessageModes.Heal] = MessageSettings.status,
  [MessageModes.Exp] = MessageSettings.status,

  [MessageModes.DamageOthers] = MessageSettings.none,
  [MessageModes.HealOthers] = MessageSettings.none,
  [MessageModes.ExpOthers] = MessageSettings.none,

  [MessageModes.TradeNpc] = MessageSettings.centerWhite,
  [MessageModes.Guild] = MessageSettings.centerWhite,
  [MessageModes.Party] = MessageSettings.centerGreen,
  [MessageModes.PartyManagement] = MessageSettings.centerWhite,
  [MessageModes.TutorialHint] = MessageSettings.centerWhite,
  [MessageModes.BeyondLast] = MessageSettings.centerWhite,
  [MessageModes.Report] = MessageSettings.consoleRed,
  [MessageModes.HotkeyUse] = MessageSettings.centerGreen,

  [MessageModes.MessageGameBigTop] = MessageSettings.statusBigTop,
  [MessageModes.MessageGameBigCenter] = MessageSettings.statusBigCenter,
  [MessageModes.MessageGameBigBottom] = MessageSettings.statusBigBottom,

  [254] = MessageSettings.private
}

messagesPanel = nil
statusLabel = nil

function init()
  for messageMode, _ in pairs(MessageTypes) do
    registerMessageMode(messageMode, displayMessage)
  end

  connect(g_game, 'onGameEnd', clearMessages)
  connect(modules.game_interface.getMapPanel(), {
    onGeometryChange = onGeometryChange,
    onViewModeChange = onViewModeChange,
    onZoomChange = onZoomChange,
  })

  messagesPanel = g_ui.loadUI('textmessage', modules.game_interface.getRootPanel())
  statusLabel = messagesPanel:getChildById('statusLabel')
end

function terminate()
  for messageMode, _ in pairs(MessageTypes) do
    unregisterMessageMode(messageMode, displayMessage)
  end

  disconnect(modules.game_interface.getMapPanel(), {
    onGeometryChange = onGeometryChange,
    onViewModeChange = onViewModeChange,
    onZoomChange = onZoomChange,
  })
  disconnect(g_game, 'onGameEnd', clearMessages)

  clearMessages()
  messagesPanel:destroy()
end

local function updateStatusLabelPosition(label)
  if not modules.game_interface then return end

  local gameExpBar = modules.game_interface.getGameExpBar()

  local margin
  if ViewModes[modules.game_interface.getCurrentViewMode()].isFull then
    margin = modules.game_interface.getSplitter():getMarginBottom() + (modules.ka_game_hotkeybars and modules.ka_game_hotkeybars.isHotkeybarsVisible() and 44 or gameExpBar:isOn() and gameExpBar:getHeight() or 0) + 4
  else
    local mapPanel = modules.game_interface.getMapPanel()
    margin = math.floor((mapPanel:getHeight() - mapPanel:getMapHeight()) / 2) + (gameExpBar:isOn() and gameExpBar:getHeight() or 0) + 4
  end
  label:setMarginBottom(margin)
end

function onGeometryChange(mapPanel)
  updateStatusLabelPosition(statusLabel)
end

function onViewModeChange(mapWidget, viewMode, oldViewMode)
  updateStatusLabelPosition(statusLabel)
end

function onZoomChange(self, oldZoom, newZoom) -- Is this callback necessary?
  if oldZoom == newZoom then
    return
  end
  addEvent(function() updateStatusLabelPosition(statusLabel) end)
end

function calculateVisibleTime(text)
  return math.max(#text * 100, 4000)
end

function displayMessage(mode, text)
  if not g_game.isOnline() then return end

  local msgtype = MessageTypes[mode]
  if not msgtype then
    return
  end

  if msgtype == MessageSettings.none then return end

  if msgtype.consoleTab ~= nil and (msgtype.consoleOption == nil or modules.client_options.getOption(msgtype.consoleOption)) then
    if modules.game_console then
      modules.game_console.addText(text, msgtype, tr(msgtype.consoleTab))
    end
    --TODO move to game_console
  end

  if msgtype.screenTarget then
    local label = messagesPanel:recursiveGetChildById(msgtype.screenTarget)
    label:setText(text)
    label:setColor(msgtype.color)
    label:setFont(msgtype.font or DefaultFont)
    label:setVisible(true)
    if msgtype.screenTarget == 'statusLabel' then
      updateStatusLabelPosition(label)
    end
    removeEvent(label.hideEvent)
    label.hideEvent = scheduleEvent(function() label:setVisible(false) end, calculateVisibleTime(text))
  end
end

function displayPrivateMessage(text)
  displayMessage(254, text)
end

function displayStatusMessage(text)
  displayMessage(MessageModes.Status, text)
end

function displayFailureMessage(text)
  displayMessage(MessageModes.Failure, text)
end

function displayGameMessage(text)
  displayMessage(MessageModes.Game, text)
end

function displayBroadcastMessage(text)
  displayMessage(MessageModes.Warning, text)
end

function clearMessages()
  for _i,child in pairs(messagesPanel:recursiveGetChildren()) do
    if child:getId():match('Label') then
      child:hide()
      removeEvent(child.hideEvent)
    end
  end
end

function LocalPlayer:onAutoWalkFail(player)
  if modules.game_textmessage then
    modules.game_textmessage.displayFailureMessage(tr('There is no way.'))
  end
end

local updateTime = 1 -- seconds
local shortcut = 'Ctrl+U'

unjustifiedPointsWindow = nil
unjustifiedPointsButton = nil
contentsPanel = nil

currentSkullWidget = nil
skullTimeLabel = nil

redSkullProgressBar = nil
blackSkullProgressBar = nil

redSkullSkullWidget = nil
blackSkullSkullWidget = nil

updateMainLabelEvent = nil

local function updateMainLabelEventFunction()
  if not skullTimeLabel or not skullTimeLabel.data or skullTimeLabel.data.remainingTime <= 0 then return end
  local data = skullTimeLabel.data

  local remainingTime = data.remainingTime - updateTime
  if remainingTime >= 0 then
    onUnjustifiedPoints(remainingTime, data.fragsToRedSkull, data.fragsToBlackSkull, data.timeToRemoveFrag)
  end
end

function init()
  connect(g_game, { onGameStart = online, onGameEnd = offline })

  unjustifiedPointsButton = modules.client_topmenu.addRightGameToggleButton('unjustifiedPointsButton', 'Unjustified Frags (' .. shortcut .. ')', '/images/topbuttons/unjustifiedpoints', toggle)
  unjustifiedPointsButton:setOn(true)
  unjustifiedPointsButton:hide()

  unjustifiedPointsWindow = g_ui.loadUI('unjustifiedpoints', modules.game_interface.getRightPanel())
  unjustifiedPointsWindow:disableResize()
  unjustifiedPointsWindow:setup()

  contentsPanel = unjustifiedPointsWindow:getChildById('contentsPanel')

  currentSkullWidget = contentsPanel:getChildById('currentSkullWidget')
  skullTimeLabel = contentsPanel:getChildById('skullTimeLabel')

  redSkullProgressBar = contentsPanel:getChildById('redSkullProgressBar')
  blackSkullProgressBar = contentsPanel:getChildById('blackSkullProgressBar')
  redSkullSkullWidget = contentsPanel:getChildById('redSkullSkullWidget')
  blackSkullSkullWidget = contentsPanel:getChildById('blackSkullSkullWidget')

  onUnjustifiedPoints()

  ProtocolGame.registerExtendedOpcode(GameServerExtOpcodes.GameServerUnjustifiedPoints, parseUnjustifiedPoints)

  g_keyboard.bindKeyDown(shortcut, toggle)

  if g_game.isOnline() then
    online()
  end
end

function terminate()
  removeEvent(updateMainLabelEvent)
  updateMainLabelEvent = nil

  g_keyboard.unbindKeyDown(shortcut)

  ProtocolGame.unregisterExtendedOpcode(GameServerExtOpcodes.GameServerUnjustifiedPoints)

  disconnect(g_game, { onGameStart = online, onGameEnd = offline })

  unjustifiedPointsWindow:destroy()
  unjustifiedPointsButton:destroy()
end

function onMiniWindowOpen()
  if not g_game.isOnline() or not unjustifiedPointsWindow:isVisible() then return end
  updateMainLabelEvent = cycleEvent(updateMainLabelEventFunction, updateTime * 1000)
  sendUnjustifiedPointsRequest()

  unjustifiedPointsButton:setOn(true)
end

function onMiniWindowClose()
  removeEvent(updateMainLabelEvent)
  updateMainLabelEvent = nil

  unjustifiedPointsButton:setOn(false)
end

function toggle()
  if unjustifiedPointsButton:isOn() then
    unjustifiedPointsWindow:close()
  else
    unjustifiedPointsWindow:open()
  end
end

function sendUnjustifiedPointsRequest()
  if not g_game.isOnline() or not unjustifiedPointsWindow:isVisible() then return end

  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedOpcode(ClientExtOpcodes.ClientUnjustifiedPoints, '') -- No sending data needed, since is just a request signal
    return true
  end
  return false
end

function online()
  if g_game.getFeature(GameUnjustifiedPoints) then
    unjustifiedPointsButton:show()
    sendUnjustifiedPointsRequest()
    if unjustifiedPointsWindow:isVisible() then updateMainLabelEvent = cycleEvent(updateMainLabelEventFunction, updateTime * 1000) end
  else
    unjustifiedPointsButton:hide()
    unjustifiedPointsWindow:close()
  end
end

function offline()
  removeEvent(updateMainLabelEvent)
  updateMainLabelEvent = nil
end

local function getColorByKills(kills, fragsTo)
  local ratio = kills / fragsTo
  if ratio == 0 then return 'white' end
  return ratio < 0.334 and 'green' or ratio < 0.667 and 'yellow' or ratio >= 0.667 and 'red' or 'white'
end

function onUnjustifiedPoints(remainingTime, fragsToRedSkull, fragsToBlackSkull, timeToRemoveFrag)
  if not g_game.isOnline() or not unjustifiedPointsWindow:isVisible() then return end

  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer:isLocalPlayer() then return end

  remainingTime     = remainingTime or 0
  fragsToRedSkull   = fragsToRedSkull or 0
  fragsToBlackSkull = fragsToBlackSkull or 0
  timeToRemoveFrag  = timeToRemoveFrag or 1
  local fragsCount  = math.ceil(remainingTime / timeToRemoveFrag)
  local skull       = localPlayer:getSkull()

  local nextFragRemainingTime = remainingTime % timeToRemoveFrag
  skullTimeLabel:setText(string.format('%.2d:%.2d (frags: %d)', math.floor(nextFragRemainingTime / (60 * 60)), math.floor(nextFragRemainingTime / 60) % 60, fragsCount))

  local nextFragRemainingTimeTooltip = string.format('Next frag will be lost in: %.2d:%.2d:%.2d', math.floor(nextFragRemainingTime / (60 * 60)), math.floor(nextFragRemainingTime / 60) % 60, nextFragRemainingTime % 60)
  skullTimeLabel:setTooltip(string.format('Total frags: %d\n%s\nAll frags will be lost in: %.2d:%.2d:%.2d', fragsCount, nextFragRemainingTimeTooltip, math.floor(remainingTime / (60 * 60)), math.floor(remainingTime / 60) % 60, remainingTime % 60))

  skullTimeLabel.data =
  {
    remainingTime         = remainingTime,
    fragsToRedSkull       = fragsToRedSkull,
    fragsToBlackSkull     = fragsToBlackSkull,
    timeToRemoveFrag      = timeToRemoveFrag,
    nextFragRemainingTime = nextFragRemainingTime
  }

  if remainingTime >= 1 and table.contains({SkullWhite, SkullRed, SkullBlack}, skull) then
    currentSkullWidget:setIcon(getSkullImagePath(skull))
    currentSkullWidget:setTooltip('Your current skull')
  else
    currentSkullWidget:setIcon('')
    currentSkullWidget:setTooltip('You have no skull')
  end

  if fragsToRedSkull ~= 0 then
    redSkullProgressBar:setValue(fragsCount, 0, fragsToRedSkull)
    redSkullProgressBar:setBackgroundColor(getColorByKills(fragsCount, fragsToRedSkull))
  else
    redSkullProgressBar:setValue(0, 0, 1)
  end
  redSkullProgressBar:setTooltip('Frags until red skull: ' .. math.max(0, fragsToRedSkull - fragsCount))

  if fragsToBlackSkull ~= 0 then
    blackSkullProgressBar:setValue(fragsCount, 0, fragsToBlackSkull)
    blackSkullProgressBar:setBackgroundColor(getColorByKills(fragsCount, fragsToBlackSkull))
  else
    blackSkullProgressBar:setValue(0, 0, 1)
  end
  blackSkullProgressBar:setTooltip('Frags until black skull: ' .. math.max(0, fragsToBlackSkull - fragsCount))
end

function parseUnjustifiedPoints(protocol, opcode, buffer)
  local params = buffer:split(':')
  local remainingTime     = tonumber(params[1])
  local fragsToRedSkull   = tonumber(params[2])
  local fragsToBlackSkull = tonumber(params[3])
  local timeToRemoveFrag  = tonumber(params[4])
  if not remainingTime or not fragsToRedSkull or not fragsToBlackSkull or not timeToRemoveFrag then return end
  onUnjustifiedPoints(remainingTime, fragsToRedSkull, fragsToBlackSkull, timeToRemoveFrag)
end

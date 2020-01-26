local emoteList = nil
local emoteListByIndex = nil
local emoteWindow = nil
local consoleEmoteButton = nil
local consolePanel = modules.game_console.getConsolePanel()

local EmoteDisable = 0
local EmoteEnable  = 1

function init()
  emoteList = {}
  emoteListByIndex = {}

  emoteWindow = g_ui.loadUI('emoteWindow', consolePanel)
  emoteWindow:hide()
  setupEmotes()
  onResizeConsole(consolePanel)

  local prevButton = consolePanel:getChildById('channelsButton')
  local prevButtonIndex = consolePanel:getChildIndex(prevButton)
  consoleEmoteButton = g_ui.createWidget('EmoteWindowButton', consolePanel)
  consolePanel:moveChildToIndex(consoleEmoteButton, prevButtonIndex)

  if g_game.isOnline() then
    online()
  end

  connect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
  })
  connect(consolePanel, {
    onGeometryChange = onResizeConsole,
  })
  connect(consoleEmoteButton, {
    onHoverChange = onConsoleEmoteButtonHoverChange,
  })
  ProtocolGame.registerOpcode(GameServerOpcodes.GameServerEmote, parseEmote)
  g_keyboard.bindKeyDown('Escape', function() emoteWindow:hide() end, rootWidget)
end

function online()
  loadSettings()
  sortEmoteList()
  updateConsoleEmoteButtonIcon()
end

function offline()
  emoteWindow:hide()
  saveSettings()
end

function terminate()
  saveSettings()

  g_keyboard.unbindKeyDown('Escape')
  ProtocolGame.unregisterOpcode(GameServerOpcodes.GameServerEmote)
  disconnect(consoleEmoteButton, {
    onHoverChange = onConsoleEmoteButtonHoverChange,
  })
  disconnect(consolePanel, {
    onGeometryChange = onResizeConsole,
  })
  disconnect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
  })

  emoteList = {}
  emoteListByIndex = {}

  if emoteWindow then
    emoteWindow:destroy()
    emoteWindow = nil
  end
  if consoleEmoteButton then
    consoleEmoteButton:destroy()
    consoleEmoteButton = nil
  end
end

function updateConsoleEmoteButtonIcon()
  consoleEmoteButton:setIcon(string.format('/images/game/emotes/%d', math.random(FirstEmote, LastEmote)))
  consoleEmoteButton:setIconSize({ width = 16, height = 16 })
  consoleEmoteButton:setIconOffset({ x = 3, y = 4 })
end

function onConsoleEmoteButtonHoverChange(self, hovered)
  if not hovered then
    return
  end
  updateConsoleEmoteButtonIcon()
end

function onResizeConsole(console)
  if not emoteWindow then return end
  local realWidth = console:getWidth() - emoteWindow:getMarginRight() - emoteWindow:getMarginLeft()
  local realHeight = console:getHeight() - emoteWindow:getMarginTop() - emoteWindow:getMarginBottom()
  local area =  realWidth * realHeight
  local totalCells = emoteWindow:getChildCount()
  local cellSize = math.min(math.floor(math.sqrt(area / totalCells)), 32)
  emoteWindow:setWidth(realWidth)
  emoteWindow:getLayout():setCellSize({width = cellSize, height = cellSize})
  for _, emote in ipairs(emoteList) do
    emote:setIconSize({width = cellSize, height = cellSize})
    local lock = emote:getChildren()[1]
    lock:setSize({width = cellSize, height = cellSize})
    lock:setIconSize({width = cellSize, height = cellSize})
  end
end

function toggleWindow()
  if not emoteWindow then return end
  if emoteWindow:isHidden() then
    emoteWindow:show()
  else
    emoteWindow:hide()
  end
end

function setupEmotes()
  for id = FirstEmote, LastEmote do
    local emote = g_ui.createWidget('EmoteButton', emoteWindow)
    emote:setId(string.format('EmoteButton_%d', id))
    emote:setIcon(string.format('/images/game/emotes/%d', id))
    emote:setTooltip(emotes[id].name)
    emote.id = id
    emote.timesUsed = 0
    emote.lastUsed = 0
    emote.locked = true
    emoteList[id] = emote
    table.insert(emoteListByIndex, emote)
  end
end

function unlockEmote(id)
  local emote = emoteList[id]
  local lock = emote:getChildren()[1]
  lock:setIcon(nil)
  emote.locked = false
  emote.onClick = function() useEmote(id) end
end

function lockEmote(id)
  local emote = emoteList[id]
  local lock = emote:getChildren()[1]
  lock:setIcon('/images/game/emotes/locked')
  emote.timesUsed = 0
  emote.lastUsed = 0
  emote.locked = true
  emote.onClick = nil
end

function isLocked(id)
  local emote = emoteList[id]
  return emote.locked
end

function getTimesUsed(id)
  local emote = emoteList[id]
  return not isLocked(id) and emote.timesUsed or -1
end

-- Settings
function loadSettings()
  local settings = modules.game_things.getPlayerSettings()
  local emoteSettings = settings:getNode('emotes') or {}
  for id, emote in pairs(emoteSettings) do
    local emoteId = tonumber(id)
    if emoteList[emoteId] then
      emoteList[emoteId].timesUsed = emoteSettings[id].timesUsed
      emoteList[emoteId].lastUsed = emoteSettings[id].lastUsed
      emoteList[emoteId].locked = emoteSettings[id].locked
    end
  end
end

function saveSettings()
  local settings = modules.game_things.getPlayerSettings()
  local emoteSettings = {}
  for id, emote in pairs(emoteList) do
    emoteSettings[id] = {}
    emoteSettings[id].timesUsed = emote.timesUsed
    emoteSettings[id].lastUsed  = emote.lastUsed
    emoteSettings[id].locked  = emote.locked
  end
  settings:setNode('emotes', emoteSettings)
  settings:save()
end

-- Network
function useEmote(id)
  if not g_game.canPerformGameAction() then return end
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedOpcode(ClientExtOpcodes.ClientEmote, id)
  end
  emoteList[id].timesUsed = emoteList[id].timesUsed + 1
  emoteList[id].lastUsed = os.time()
  sortEmoteList()
end

function sortEmoteList()
  table.sort(emoteListByIndex, (function(a,b) return getTimesUsed(a.id) > getTimesUsed(b.id) or (getTimesUsed(a.id) == getTimesUsed(b.id) and a.lastUsed > b.lastUsed) or (getTimesUsed(a.id) == getTimesUsed(b.id) and a.lastUsed == b.lastUsed and a.id < b.id) end))
  for i = 1, #emoteListByIndex do
    emoteWindow:moveChildToIndex(emoteListByIndex[i], i)
  end
end

function parseEmote(protocol, msg)
  local total = msg:getU8()
  for i = 1, total do
    local emoteId = msg:getU8()
    local action  = msg:getU8()
    if action == EmoteEnable then
      unlockEmote(emoteId)
    elseif action == EmoteDisable then
      lockEmote(emoteId)
    end
  end
  if total == 1 then
    sortEmoteList()
  end
end

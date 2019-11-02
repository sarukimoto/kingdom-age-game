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

  if g_game.isOnline() then online() end

  local prevButton = consolePanel:getChildById('channelsButton')
  local prevButtonIndex = consolePanel:getChildIndex(prevButton)
  consoleEmoteButton = g_ui.createWidget('EmoteWindowButton', consolePanel)
  consolePanel:moveChildToIndex(consoleEmoteButton, prevButtonIndex)

  connect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
  })
  connect(consolePanel, {
    onGeometryChange = onResizeConsole,
  })
  ProtocolGame.registerOpcode(GameServerOpcodes.GameServerEmote, parseEmote)
end

function online()
  loadSettings()
  sortEmoteList()
end

function offline()
  emoteWindow:hide()
  saveSettings()
end

function terminate()
  saveSettings()
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

  ProtocolGame.unregisterOpcode(GameServerOpcodes.GameServerEmote)
  disconnect(consolePanel, {
    onGeometryChange = onResizeConsole,
  })
  disconnect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
  })
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
    emoteList[id] = emote
    table.insert(emoteListByIndex, emote)
  end
end

function unlockEmote(id)
  local emote = emoteList[id]
  local lock = emote:getChildren()[1]
  lock:setIcon(nil)
  emote.onClick = function() useEmote(id) end
end

function lockEmote(id)
  local emote = emoteList[id]
  local lock = emote:getChildren()[1]
  lock:setIcon('/images/game/emotes/locked')
  emote.onClick = nil
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
  table.sort(emoteListByIndex, (function(a,b) return a.timesUsed > b.timesUsed or (a.timesUsed == b.timesUsed and a.lastUsed > b.lastUsed) or (a.timesUsed == b.timesUsed and a.lastUsed == b.lastUsed and a.id < b.id) end))
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
end

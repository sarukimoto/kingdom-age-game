dofiles('ui')

local showHotkeybars = false
local currentViewmode = 0
hotkeybars = { }

function init()
  g_ui.importStyle('ka_game_hotkeybars.otui')
  initHotkeybars()

  connect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd
  })

  connect(modules.game_interface.getMapPanel(), {
    onGeometryChange = onMapPanelGeometryChange,
    onViewModeChange = onViewModeChange
  })

  if g_game.isOnline() then
    loadHotkeybars()
  end
end

function terminate()
  if g_game.isOnline() then
    saveHotkeybars()
  end

  deinitHotkeybars()

  disconnect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd
  })

  disconnect(modules.game_interface.getMapPanel(), {
    onGeometryChange = onMapPanelGeometryChange,
    onViewModeChange = onViewModeChange
  })
end

function onGameStart()
  currentViewmode = 0
  updateDisplay()
  updateHotkeybarPositions()
  loadHotkeybars()
  connect(modules.game_console.consolePanel, 'onGeometryChange', onConsoleGeometryChange)
end

function onGameEnd()
  disconnect(modules.game_console.consolePanel, 'onGeometryChange', onConsoleGeometryChange)
  saveHotkeybars()
  unloadHotkeybars()
end

function onViewModeChange(mapWidget, viewMode, oldViewMode)
  currentViewmode = viewMode

  updateHotkeybarPositions()
  updateDisplay()
end

function updateLook()
  for i = 1, #hotkeybars do
    hotkeybars[i]:updateLook()
  end
end

-- game_hotkeys has changes
function onUpdateHotkeys()
  updateLook()
end


-- mapPanel geometry has changes
function onMapPanelGeometryChange(mapWidget)
  updateHotkeybarPositions()
end

-- console geometry has changes (viewmode == 2)
function onConsoleGeometryChange(widget)
  updateHotkeybarPositions()
end

function getHotkeyBars()
  return hotkeybars
end

-- adjust positions to viewmode and geometry
function updateHotkeybarPositions()
  local mapWidget = modules.game_interface.getMapPanel()
  for alignment = 1, #hotkeybars do
    local tmpHotkeybar = hotkeybars[alignment]
    if alignment == AnchorTop then
      if currentViewmode == 2 then addEvent(function() tmpHotkeybar:setMarginTop(modules.client_topmenu.getTopMenu():getHeight() + tmpHotkeybar.mapMargin) end)
      else                         addEvent(function() tmpHotkeybar:setMarginTop(math.floor((mapWidget:getHeight() - mapWidget:getMapHeight()) / 2) - tmpHotkeybar.height - tmpHotkeybar.mapMargin) end)
      end

    elseif alignment == AnchorLeft then
      if currentViewmode == 2 then addEvent(function() local leftPanel = modules.game_interface.getLeftPanel() local marginLeft = leftPanel and leftPanel:getWidth() or 0 tmpHotkeybar:setMarginLeft(marginLeft + tmpHotkeybar.mapMargin) tmpHotkeybar:setMarginBottom(modules.game_console.consolePanel:getHeight() / 2) end)
      else                         addEvent(function() tmpHotkeybar:setMarginLeft(mapWidget:getX() + math.floor((mapWidget:getWidth() - mapWidget:getMapWidth()) / 2) - tmpHotkeybar.height - tmpHotkeybar.mapMargin) tmpHotkeybar:setMarginBottom(0) end)
      end

    elseif alignment == AnchorBottom then
      if currentViewmode == 2 then addEvent(function() tmpHotkeybar:setMarginTop(mapWidget:getHeight() - modules.game_console.consolePanel:getHeight() - tmpHotkeybar.height - tmpHotkeybar.mapMargin) end)
      else                         addEvent(function() tmpHotkeybar:setMarginTop(math.floor((mapWidget:getHeight() - mapWidget:getMapHeight()) / 2) + mapWidget:getMapHeight() + tmpHotkeybar.mapMargin) end)
      end

    elseif alignment == AnchorRight then
      if currentViewmode == 2 then addEvent(function() local rightPanel = modules.game_interface.getRightPanel() local marginRight = rightPanel and rightPanel:getWidth() or 0 tmpHotkeybar:setMarginLeft(mapWidget:getWidth() - marginRight - tmpHotkeybar.height - tmpHotkeybar.mapMargin) tmpHotkeybar:setMarginBottom(modules.game_console.consolePanel:getHeight() / 2) end)
      else                         addEvent(function() tmpHotkeybar:setMarginLeft(mapWidget:getX() + math.floor((mapWidget:getWidth() - mapWidget:getMapWidth()) / 2) + mapWidget:getMapWidth() + tmpHotkeybar.mapMargin) tmpHotkeybar:setMarginBottom(0) end)
      end
    end
  end
end

function initHotkeybars()
  for i = AnchorTop, AnchorRight do
    local hotkeybar = g_ui.createWidget('Hotkeybar', modules.game_interface.getRootPanel())
    hotkeybar:setHotkeybarId(i)
    hotkeybar:setAlignment((i == AnchorTop or i == AnchorBottom) and 'horizontal' or 'vertical')
    hotkeybars[i] = hotkeybar
  end
end

function deinitHotkeybars()
  for i = 1, #hotkeybars do
    hotkeybars[i]:destroy()
  end
end

function saveHotkeybars()
  for i = 1, #hotkeybars do
    hotkeybars[i]:save()
  end
end

function loadHotkeybars()
  for i = 1, #hotkeybars do
    hotkeybars[i]:load()
  end
  updateDraggable(false)
end

function unloadHotkeybars()
  for i = 1, #hotkeybars do
    hotkeybars[i]:unload()
  end
end

function toggleHotkeybars(show)
  for i = 1, #hotkeybars do
    hotkeybars[i]:setVisible(show)
  end
end

function updateDraggable(bool)
  for i = 1, #hotkeybars do
    hotkeybars[i]:updateDraggable(bool)
  end
end

function updateDisplay()
  if currentViewmode == 0 or currentViewmode == 1 then
    modules.game_interface.getMapPanel():setPadding(showHotkeybars and 46 or 4)

    local splitter = modules.game_interface.getSplitter()
    splitter:setMarginBottom(splitter:getMarginBottom() + 1)
  elseif currentViewmode == 2 then
    modules.game_interface.getMapPanel():setPadding(0)
  end
end

function onDisplay(show)
  showHotkeybars = show
  updateDisplay()
  toggleHotkeybars(show)
end

function isHotkeybarsVisible()
  return showHotkeybars
end

function setPowerIcon(keyCombo, enabled)
  local view = modules.game_hotkeys.getHotkey(keyCombo)
  if not view then return end

  local path = string.format('/images/game/powers/%d_%s', view.id, enabled and 'on' or 'off')

  for i = 1, #hotkeybars do
    local hotkeyWidget = hotkeybars[i]:getChildById(keyCombo)
    if hotkeyWidget then
      local powerWidget = hotkeyWidget:getChildById('power')
      if powerWidget then
        powerWidget:setImageSource(path)
      end
    end
  end
end

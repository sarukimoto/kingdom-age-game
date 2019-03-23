minimapWindow = nil
minimapButton = nil
minimapWidget = nil
minimapFloorUpButton = nil
minimapFloorDownButton = nil
minimapZoomInButton = nil
minimapZoomOutButton = nil
minimapResetButton = nil
minimapOpacityScrollbar = nil
otmm = true
preloaded = false
fullmapView = false
oldZoom = nil
oldPos = nil
instanceId = 0
instanceName = ""

function init()
  minimapButton = modules.client_topmenu.addRightGameToggleButton('minimapButton', tr('Minimap') .. ' (Ctrl+M)', '/images/topbuttons/minimap', toggle)
  minimapButton:setOn(true)

  minimapWindow = g_ui.loadUI('minimap', modules.game_interface.getRightPanel())
  minimapWindow:setContentMinimumHeight(64)

  minimapWidget = minimapWindow:recursiveGetChildById('minimap')
  minimapFloorUpButton = minimapWindow:recursiveGetChildById('floorUp')
  minimapFloorDownButton = minimapWindow:recursiveGetChildById('floorDown')
  minimapZoomInButton = minimapWindow:recursiveGetChildById('zoomIn')
  minimapZoomOutButton = minimapWindow:recursiveGetChildById('zoomOut')
  minimapResetButton = minimapWindow:recursiveGetChildById('reset')

  minimapOpacityScrollbar = minimapWindow:recursiveGetChildById('minimapOpacity')
  minimapOpacityScrollbar:setValue(g_settings.getValue('Minimap', 'opacity', 100))
  minimapWidget:setOpacity(1.0)

  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.bindKeyPress('Alt+Left', function() minimapWidget:move(1,0) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Right', function() minimapWidget:move(-1,0) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Up', function() minimapWidget:move(0,1) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Down', function() minimapWidget:move(0,-1) end, gameRootPanel)
  g_keyboard.bindKeyDown('Ctrl+M', toggle)
  g_keyboard.bindKeyDown('Ctrl+Shift+M', toggleFullMap)
  g_keyboard.bindKeyDown('Escape', function() if fullmapView then toggleFullMap() end end)

  minimapWindow:setup()

  ProtocolGame.registerExtendedOpcode(GameServerExtOpcodes.GameServerInstanceInfo, onInstanceInfo)

  connect(g_game, {
    onGameStart = online,
    onGameEnd = offline
  })

  connect(LocalPlayer, {
    onPositionChange = updateCameraPosition
  })

  if g_game.isOnline() then
    online()
  end
end

function terminate()
  if g_game.isOnline() then
    saveMap()
  end

  if fullmapView then
    toggleFullMap()
  end

  g_settings.setValue('Minimap', 'opacity', minimapOpacityScrollbar:getValue())

  disconnect(g_game, {
    onGameStart = online,
    onGameEnd = offline
  })

  disconnect(LocalPlayer, {
    onPositionChange = updateCameraPosition
  })

  ProtocolGame.unregisterExtendedOpcode(GameServerExtOpcodes.GameServerInstanceInfo)

  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.unbindKeyPress('Alt+Left', gameRootPanel)
  g_keyboard.unbindKeyPress('Alt+Right', gameRootPanel)
  g_keyboard.unbindKeyPress('Alt+Up', gameRootPanel)
  g_keyboard.unbindKeyPress('Alt+Down', gameRootPanel)
  g_keyboard.unbindKeyDown('Ctrl+M')
  g_keyboard.unbindKeyDown('Ctrl+Shift+M')
  g_keyboard.unbindKeyDown('Escape')

  minimapWindow:destroy()
  minimapButton:destroy()
end

function toggle()
  if fullmapView then
    toggleFullMap()
  end
  if minimapButton:isOn() then
    minimapWindow:close()
    minimapButton:setOn(false)
  else
    minimapWindow:open()
    minimapButton:setOn(true)
  end
end

function onMiniWindowClose()
  minimapButton:setOn(false)
end

function preload()
  loadMap(false)
  preloaded = true
end

function online()
  loadMap(not preloaded)
  updateCameraPosition()

  instanceId = 0
  instanceName = ""
  local instanceWidget = minimapWidget:recursiveGetChildById('instanceLabel')
  instanceWidget:setText("")
  instanceWidget:setVisible(false)
end

function offline()
  saveMap()
  if fullmapView then
    toggleFullMap()
  end
end

function loadMap(clean)
  local clientVersion = g_game.getClientVersion()

  if clean then
    g_minimap.clean()
  end

  if otmm then
    local minimapFile = '/minimap.otmm'
    if g_resources.fileExists(minimapFile) then
      g_minimap.loadOtmm(minimapFile)
    end
  else
    local minimapFile = '/minimap_' .. clientVersion .. '.otcm'
    if g_resources.fileExists(minimapFile) then
      g_map.loadOtcm(minimapFile)
    end
  end
  minimapWidget:load()
end

function saveMap()
  local clientVersion = g_game.getClientVersion()
  if otmm then
    local minimapFile = '/minimap.otmm'
    g_minimap.saveOtmm(minimapFile)
  else
    local minimapFile = '/minimap_' .. clientVersion .. '.otcm'
    g_map.saveOtcm(minimapFile)
  end
  minimapWidget:save()
end

function updateCameraPosition()
  local player = g_game.getLocalPlayer()
  if not player then return end
  local pos = player:getPosition()
  if not pos then return end

  local positionWidget = minimapWidget:recursiveGetChildById('positionLabel')
  positionWidget:setText(tr('X: %d | Y: %d | Z: %d', pos.x, pos.y, pos.z))
  positionWidget:setOpacity(0.80)

  if not minimapWidget:isDragging() then
    if not fullmapView then
      minimapWidget:setCameraPosition(player:getPosition())
    end
    minimapWidget:setCrossPosition(player:getPosition())
  end
end

function toggleFullMap()
  local parent
  if not fullmapView then
    fullmapView = true
    parent = modules.game_interface.getRootPanel()
    minimapWindow:hide()
    minimapWidget:setParent(parent)
    minimapWidget:fill('parent')
    minimapWidget:setAlternativeWidgetsVisible(true)
    minimapOpacityScrollbar:show()
    minimapWidget:setOpacity(minimapOpacityScrollbar:getValue()/100)
  else
    fullmapView = false
    parent = minimapWindow:getChildById('contentsPanel')
    minimapOpacityScrollbar:hide()
    minimapWidget:setParent(parent)
    minimapWidget:fill('parent')
    minimapWindow:show()
    minimapWidget:setAlternativeWidgetsVisible(false)
    minimapWidget:setOpacity(1.0)
  end

  minimapFloorUpButton:setParent(parent)
  minimapFloorDownButton:setParent(parent)
  minimapZoomInButton:setParent(parent)
  minimapZoomOutButton:setParent(parent)
  minimapResetButton:setParent(parent)
  minimapOpacityScrollbar:setParent(parent)

  -- All other buttons anchoring to northwest
  minimapFloorUpButton:addAnchor(AnchorRight, 'parent', AnchorRight)
  minimapFloorUpButton:addAnchor(AnchorBottom, 'parent', AnchorBottom)
  minimapFloorDownButton:addAnchor(AnchorRight, 'parent', AnchorRight)
  minimapFloorDownButton:addAnchor(AnchorBottom, 'parent', AnchorBottom)
  minimapZoomInButton:addAnchor(AnchorRight, 'parent', AnchorRight)
  minimapZoomInButton:addAnchor(AnchorBottom, 'parent', AnchorBottom)
  minimapZoomOutButton:addAnchor(AnchorRight, 'parent', AnchorRight)
  minimapZoomOutButton:addAnchor(AnchorBottom, 'parent', AnchorBottom)
  minimapOpacityScrollbar:addAnchor(AnchorRight, 'parent', AnchorRight)
  minimapOpacityScrollbar:addAnchor(AnchorBottom, 'parent', AnchorBottom)

  minimapResetButton:breakAnchors()
  if fullmapView then
    -- Reset button anchoring to southeast
    minimapResetButton:addAnchor(AnchorRight, 'parent', AnchorRight)
    minimapResetButton:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    minimapResetButton:setMarginBottom(52)
  else
    -- Reset button anchoring to northwest
    minimapResetButton:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    minimapResetButton:addAnchor(AnchorTop, 'parent', AnchorTop)
    minimapResetButton:setMarginBottom(0)
  end

  local zoom = oldZoom or 0
  local pos = oldPos or minimapWidget:getCameraPosition()
  oldZoom = minimapWidget:getZoom()
  oldPos = minimapWidget:getCameraPosition()
  minimapWidget:setZoom(zoom)
  minimapWidget:setCameraPosition(pos)
end

function getMinimapWidget()
  return minimapWidget
end

function getInstanceLabel()
  return minimapWidget:recursiveGetChildById('instanceLabel')
end

function onInstanceInfo(protocol, opcode, buffer)
  local params = string.split(buffer, ':')

  local id, name
  if #params == 2 then
    id   = tonumber(params[1])
    name = params[2]
  else
    id   = 0
    name = ""
  end

  if id < 1 or not name then
    name = ""
  end

  instanceId   = id
  instanceName = name

  local instanceWidget = minimapWidget:recursiveGetChildById('instanceLabel')
  instanceWidget:setText(name)
  instanceWidget:setVisible(name ~= "")
end

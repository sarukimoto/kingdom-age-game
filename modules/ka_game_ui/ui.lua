function init()
  connect(modules.game_interface.getMapPanel(), {
    onGeometryChange = onGeometryChange,
    onViewModeChange = onViewModeChange
  })

  connect(LocalPlayer, {
    onLevelChange = onLevelChange,
  })

  local localPlayer = g_game.getLocalPlayer()
  if localPlayer then
    onLevelChange(localPlayer, localPlayer:getLevel(), localPlayer:getLevelPercent())
  end
end

function terminate()
  disconnect(modules.game_interface.getMapPanel(), {
    onGeometryChange = onGeometryChange,
    onViewModeChange = onViewModeChange
  })

  disconnect(LocalPlayer, {
    onLevelChange = onLevelChange,
  })
end

function updateGameExpBarPercent(percent)
  local mod = modules.game_interface
  if not mod then return end
  local gameExpBar = mod.getGameExpBar()
  if not gameExpBar:isOn() then return end
  local localPlayer = g_game.getLocalPlayer()
  if not percent and not localPlayer then return end

  percent = percent or localPlayer:getLevelPercent()

  local emptyGameExpBar = gameExpBar:getChildById('empty')
  local fullGameExpBar  = gameExpBar:getChildById('full')
  fullGameExpBar:setWidth(emptyGameExpBar:getWidth() * (percent / 100))
end

function updateGameExpBarPos()
  local mod = modules.game_interface
  if not mod then return end
  local gameExpBar = mod.getGameExpBar()
  if not gameExpBar:isOn() then return end

  local gameMapPanel = mod.getMapPanel()
  local bottomMargin = math.floor((gameMapPanel:getHeight() - gameMapPanel:getMapHeight()) / 2)
  local leftMargin   = math.floor((gameMapPanel:getWidth() - gameMapPanel:getMapWidth()) / 2)
  local rightMargin  = leftMargin
  if mod.getCurrentViewMode() == 2 then
    bottomMargin = 0
    leftMargin   = 0
    rightMargin  = 0
  end

  gameExpBar:setMarginBottom(bottomMargin)
  gameExpBar:setMarginLeft(leftMargin)
  gameExpBar:setMarginRight(rightMargin)

  updateGameExpBarPercent()
end

function updateExpBar()
  updateGameExpBarPercent()
  updateGameExpBarPos()
end

function onGeometryChange()
  addEvent(function() updateExpBar() end)
end

function onViewModeChange(mapWidget, newMode, oldMode)
  addEvent(function() updateExpBar() end)
end

function onLevelChange(localPlayer, value, percent)
  local mod = modules.game_interface
  if not mod then return end

  mod.getGameExpBar():setTooltip(getExperienceTooltipText(localPlayer, value, percent))
  updateGameExpBarPercent(percent)
end

function setExpBar(enable)
  local mod = modules.game_interface
  if not mod then return end

  local gameExpBar = mod.getGameExpBar()
  local isOn       = gameExpBar:isOn()

  -- Enable bar
  if not isOn and enable then
    gameExpBar:setOn(true)
    updateExpBar()
  -- Disable bar
  elseif isOn and not enable then
    gameExpBar:setOn(false)
    updateExpBar()
  end
end

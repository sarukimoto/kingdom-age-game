conditionButton = nil
conditionWindow = nil
toggleFilterPanelButton = nil

filterPanel = nil
filterDefaultButton = nil
filterSelfPowersButton = nil
filterOtherPowersButton = nil
filterNonAggressiveButton = nil
filterAggressiveButton = nil

conditionPanel = nil

function init()
  g_ui.importStyle('ka_conditionbutton')
  g_keyboard.bindKeyDown('Ctrl+Shift+C', toggle)

  conditionButton = modules.client_topmenu.addRightGameToggleButton('conditionbutton', tr('Conditions') .. ' (Ctrl+Shift+C)', '/images/topbuttons/cooldowns', toggle)
  conditionButton:setOn(true)

  conditionWindow = g_ui.loadUI('ka_conditionlist', modules.game_interface.getRightPanel())
  conditionWindow:setContentMinimumHeight(80)
  conditionWindow:setup()



  -- This disables scrollbar auto hiding
  local scrollbar = conditionWindow:getChildById('miniwindowScrollBar')
  scrollbar:mergeStyle({ ['$!on'] = {} })
 --

  toggleFilterPanelButton = conditionWindow:getChildById('toggleFilterPanelButton')

  toggleFilterPanelButton = conditionWindow:getChildById('toggleFilterPanelButton')
  toggleFilterPanelButton:setOn(getFilterPanelVisibility())

  filterPanel = conditionWindow:recursiveGetChildById('filterPanel')
  filterPanel:setOn(getFilterPanelVisibility())

  filterDefaultButton       = conditionWindow:recursiveGetChildById('filterDefault')
  filterSelfPowersButton    = conditionWindow:recursiveGetChildById('filterSelfPowers')
  filterOtherPowersButton   = conditionWindow:recursiveGetChildById('filterOtherPowers')
  filterNonAggressiveButton = conditionWindow:recursiveGetChildById('filterNonAggressive')
  filterAggressiveButton    = conditionWindow:recursiveGetChildById('filterAggressive')

  conditionPanel = conditionWindow:recursiveGetChildById('conditionPanel')

  ProtocolGame.registerOpcode(GameServerOpcodes.GameServerConditionsList, parseCondition)
  connect(g_game, {
    onGameStart = online,
    onGameEnd   = offline
  })

end

function terminate()
  conditionList = {}

  disconnect(g_game, {
    onGameStart = online,
    onGameEnd   = offline
  })

  ProtocolGame.unregisterOpcode(GameServerOpcodes.GameServerConditionsList)

  conditionButton:destroy()
  conditionWindow:destroy()

  g_keyboard.unbindKeyDown('Ctrl+Shift+C')
end

function online()
end

function offline()
  conditionList = {}
  conditionPanel:destroyChildren()
end

-- Top menu button
function toggle()
  if conditionButton:isOn() then
    conditionWindow:close()
    conditionButton:setOn(false)
  else
    conditionWindow:open()
    conditionButton:setOn(true)
  end
end

function onMiniWindowClose()
  if conditionButton then
    conditionButton:setOn(false)
  end
end

-- Filter Panel
function getFilterPanelVisibility()
  local settings = g_settings.getNode('ConditionList')
  if settings and type(settings['hideFilterPanel']) == 'boolean' then
    return settings['hideFilterPanel']
  end
  return false
end

function setFilterPanelVisibility(state)
  local settings = {}
  settings['hideFilterPanel'] = not state
  g_settings.mergeNode('ConditionList', settings)

  local button = toggleFilterPanelButton
  button:setOn(not state)
  filterPanel:setOn(not state)
end

-- Filtering
function filterConditionButtons()
  for i, condition in pairs(conditionList) do
    condition.button:setOn(not conditionButtonFilter(condition))
  end
end

function conditionButtonFilter(condition)
  local filterDefault      = filterDefaultButton:isChecked()
  local filterSelfPowers    = filterSelfPowersButton:isChecked()
  local filterOtherPowers = filterOtherPowersButton:isChecked()
  local filterNonAggressive = filterNonAggressiveButton:isChecked()
  local filterAggressive    = filterAggressiveButton:isChecked()

  local isAggressive = condition.isAggressive
  local isPower = condition.power and condition.power > 0
  local isOwn = condition.originId and g_game.getLocalPlayer():getId() == condition.originId

  if filterDefault and not isPower then
    return true
  elseif filterSelfPowers and isPower and isOwn then
    return true
  elseif filterOtherPowers and isPower and not isOwn then
    return true
  elseif filterNonAggressive and not isAggressive then
    return true
  elseif filterAggressive and isAggressive then
    return true
  end
  return false
end

-- Sorting
CONDITION_SORT_NAME          = 1
CONDITION_SORT_AGE           = 2
CONDITION_SORT_REMAININGTIME = 3
CONDITION_SORT_PERCENTAGE    = 4

CONDITION_ORDER_ASCENDING    = 1
CONDITION_ORDER_DESCENDING   = 2

function getSortType()
  local settings = g_settings.getNode('ConditionList')
  return settings and settings['sortType'] or CONDITION_SORT_AGE
end

function setSortType(state)
  local settings = {}
  settings['sortType'] = state
  g_settings.mergeNode('ConditionList', settings)
  updateConditionList()
end

function getSortOrder()
  local settings = g_settings.getNode('ConditionList')
  return settings and settings['sortOrder'] or CONDITION_ORDER_DESCENDING
end

function setSortOrder(state)
  local settings = {}
  settings['sortOrder'] = state
  g_settings.mergeNode('ConditionList', settings)
  updateConditionList()
end

function onMousePressSortMenuButton(widget, mousePos, mouseButton)
  if mouseButton == MouseRightButton then
    createSortMenu()
  end
end

function createSortMenu()
  local menu = g_ui.createWidget('PopupMenu')

  local sortOrder = getSortOrder()
  if sortOrder == CONDITION_ORDER_ASCENDING then
    menu:addOption(tr('Order Descending'), function() setSortOrder(CONDITION_ORDER_DESCENDING) end)
  elseif sortOrder == CONDITION_ORDER_DESCENDING then
    menu:addOption(tr('Order Ascending'), function() setSortOrder(CONDITION_ORDER_ASCENDING) end)
  end

  menu:addSeparator()

  local sortType = getSortType()
  if sortType ~= CONDITION_SORT_NAME then
    menu:addOption(tr('Sort by Name'), function() setSortType(CONDITION_SORT_NAME) end)
  end
  if sortType ~= CONDITION_SORT_AGE then
    menu:addOption(tr('Sort by Age'), function() setSortType(CONDITION_SORT_AGE) end)
  end
  if sortType ~= CONDITION_SORT_REMAININGTIME then
    menu:addOption(tr('Sort by Remaining Time'), function() setSortType(CONDITION_SORT_REMAININGTIME) end)
  end
  if sortType ~= CONDITION_SORT_PERCENTAGE then
    menu:addOption(tr('Sort by Percentage'), function() setSortType(CONDITION_SORT_PERCENTAGE) end)
  end

  menu:display()
end

function sortConditions()
  local sortOrder = getSortOrder()
  local sortType = getSortType()
  if sortOrder == CONDITION_ORDER_ASCENDING then

    if sortType == CONDITION_SORT_NAME then
      sortFunction = function(a,b) return a.name < b.name end
    elseif sortType == CONDITION_SORT_AGE then
      sortFunction = function(a,b) return a.startTime < b.startTime end
    elseif sortType == CONDITION_SORT_REMAININGTIME then
      sortFunction = function(a,b) return a.button.clock:getRemainingTime() < b.button.clock:getRemainingTime() end
    elseif sortType == CONDITION_SORT_PERCENTAGE then
      sortFunction = function(a,b) return a.button.clock:getPercent() < b.button.clock:getPercent() end
    end

  elseif sortOrder == CONDITION_ORDER_DESCENDING then

    if sortType == CONDITION_SORT_NAME then
      sortFunction = function(a,b) return a.name > b.name end
    elseif sortType == CONDITION_SORT_AGE then
      sortFunction = function(a,b) return a.startTime > b.startTime end
    elseif sortType == CONDITION_SORT_REMAININGTIME then
      sortFunction = function(a,b) return a.button.clock:getRemainingTime() > b.button.clock:getRemainingTime() end
    elseif sortType == CONDITION_SORT_PERCENTAGE then
      sortFunction = function(a,b) return a.button.clock:getPercent() > b.button.clock:getPercent() end
    end

  end

  table.sort(conditionList, sortFunction)

end

function updateConditionList()
  sortConditions()
  for i = 1, #conditionList do
    conditionPanel:moveChildToIndex(conditionList[i].button, i)
  end
  filterConditionButtons()
end

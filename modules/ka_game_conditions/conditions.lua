conditionButton = nil
conditionWindow = nil
sortMenuButton = nil
toggleFilterPanelButton = nil

filterPanel = nil
filterDefaultButton = nil
filterSelfPowersButton = nil
filterOtherPowersButton = nil
filterNonAggressiveButton = nil
filterAggressiveButton = nil

defaultConditionPanel = nil
firstHorizontalSeparator = nil
secondHorizontalSeparator = nil

conditionPanel = nil

CONDITION_SORT_APPEAR        = 1
CONDITION_SORT_NAME          = 2
CONDITION_SORT_PERCENTAGE    = 3
CONDITION_SORT_REMAININGTIME = 4

CONDITION_ORDER_ASCENDING    = 1
CONDITION_ORDER_DESCENDING   = 2

local conditionSortStr = {
  [CONDITION_SORT_APPEAR]        = 'Appear',
  [CONDITION_SORT_NAME]          = 'Name',
  [CONDITION_SORT_PERCENTAGE]    = 'Percentage',
  [CONDITION_SORT_REMAININGTIME] = 'Remaining Time'
}

local conditionOrderStr = {
  [CONDITION_ORDER_ASCENDING]  = 'Ascending',
  [CONDITION_ORDER_DESCENDING] = 'Descending'
}

local defaultValues = {
  filterPanel = true,
  filterDefault = true,
  filterSelfPowers = true,
  filterOtherPowers = true,
  filterNonAggressive = true,
  filterAggressive = true,
  sortType = CONDITION_SORT_APPEAR,
  sortOrder = CONDITION_ORDER_DESCENDING
}

Icons = {}
Icons[PlayerStates.Poison] = { tooltip = tr('You are poisoned'), path = '/images/game/states/poisoned', id = 'condition_poisoned' }
Icons[PlayerStates.Burn] = { tooltip = tr('You are burning'), path = '/images/game/states/burning', id = 'condition_burning' }
Icons[PlayerStates.Energy] = { tooltip = tr('You are electrified'), path = '/images/game/states/electrified', id = 'condition_electrified' }
Icons[PlayerStates.Drunk] = { tooltip = tr('You are drunk'), path = '/images/game/states/drunk', id = 'condition_drunk' }
Icons[PlayerStates.ManaShield] = { tooltip = tr('You are protected by a magic shield'), path = '/images/game/states/magic_shield', id = 'condition_magic_shield' }
Icons[PlayerStates.Paralyze] = { tooltip = tr('You are paralysed'), path = '/images/game/states/slowed', id = 'condition_slowed' }
Icons[PlayerStates.Haste] = { tooltip = tr('You are hasted'), path = '/images/game/states/haste', id = 'condition_haste' }
Icons[PlayerStates.Swords] = { tooltip = tr('You may not logout during a fight'), path = '/images/game/states/logout_block', id = 'condition_logout_block' }
Icons[PlayerStates.Drowning] = { tooltip = tr('You are drowning'), path = '/images/game/states/drowning', id = 'condition_drowning' }
Icons[PlayerStates.Freezing] = { tooltip = tr('You are freezing'), path = '/images/game/states/freezing', id = 'condition_freezing' }
Icons[PlayerStates.Dazzled] = { tooltip = tr('You are dazzled'), path = '/images/game/states/dazzled', id = 'condition_dazzled' }
Icons[PlayerStates.Cursed] = { tooltip = tr('You are cursed'), path = '/images/game/states/cursed', id = 'condition_cursed' }
Icons[PlayerStates.PartyBuff] = { tooltip = tr('You are strengthened'), path = '/images/game/states/strengthened', id = 'condition_strengthened' }
Icons[PlayerStates.PzBlock] = { tooltip = tr('You may not logout or enter a protection zone'), path = '/images/game/states/protection_zone_block', id = 'condition_protection_zone_block' }
Icons[PlayerStates.Pz] = { tooltip = tr('You are within a protection zone'), path = '/images/game/states/protection_zone', id = 'condition_protection_zone' }
Icons[PlayerStates.Bleeding] = { tooltip = tr('You are bleeding'), path = '/images/game/states/bleeding', id = 'condition_bleeding' }
Icons[PlayerStates.Hungry] = { tooltip = tr('You are hungry'), path = '/images/game/states/hungry', id = 'condition_hungry' }

function init()
  conditionList = {}

  g_ui.importStyle('conditionbutton')
  g_keyboard.bindKeyDown('Ctrl+Shift+C', toggle)

  conditionButton = modules.client_topmenu.addRightGameToggleButton('conditionbutton', tr('Conditions') .. ' (Ctrl+Shift+C)', '/images/topbuttons/cooldowns', toggle)
  conditionButton:setOn(true)

  conditionWindow = g_ui.loadUI('conditions', modules.game_interface.getRightPanel())
  conditionWindow:setContentMinimumHeight(80)
  conditionWindow:setup()

  for k,v in pairs(Icons) do
    g_textures.preload(v.path)
  end

  -- This disables scrollbar auto hiding
  local scrollbar = conditionWindow:getChildById('miniwindowScrollBar')
  scrollbar:mergeStyle({ ['$!on'] = {} })

  sortMenuButton = conditionWindow:getChildById('sortMenuButton')
  setSortType(getSortType())
  setSortOrder(getSortOrder())

  toggleFilterPanelButton   = conditionWindow:getChildById('toggleFilterPanelButton')
  filterPanel               = conditionWindow:recursiveGetChildById('filterPanel')
  defaultConditionPanel     = conditionWindow:recursiveGetChildById('defaultConditionPanel')
  firstHorizontalSeparator  = conditionWindow:recursiveGetChildById('firstHorizontalSeparator')
  secondHorizontalSeparator = conditionWindow:recursiveGetChildById('secondHorizontalSeparator')
  onClickFilterPanelButton(toggleFilterPanelButton, g_settings.getValue('Conditions', 'filterPanel', defaultValues.filterPanel))

  filterDefaultButton       = conditionWindow:recursiveGetChildById('filterDefault')
  filterSelfPowersButton    = conditionWindow:recursiveGetChildById('filterSelfPowers')
  filterOtherPowersButton   = conditionWindow:recursiveGetChildById('filterOtherPowers')
  filterNonAggressiveButton = conditionWindow:recursiveGetChildById('filterNonAggressive')
  filterAggressiveButton    = conditionWindow:recursiveGetChildById('filterAggressive')
  filterDefaultButton:setChecked(g_settings.getValue('Conditions', 'filterDefault', defaultValues.filterDefault))
  filterSelfPowersButton:setChecked(g_settings.getValue('Conditions', 'filterSelfPowers', defaultValues.filterSelfPowers))
  filterOtherPowersButton:setChecked(g_settings.getValue('Conditions', 'filterOtherPowers', defaultValues.filterOtherPowers))
  filterNonAggressiveButton:setChecked(g_settings.getValue('Conditions', 'filterNonAggressive', defaultValues.filterNonAggressive))
  filterAggressiveButton:setChecked(g_settings.getValue('Conditions', 'filterAggressive', defaultValues.filterAggressive))
  onClickFilterDefault(filterDefaultButton)
  onClickFilterSelfPowers(filterSelfPowersButton)
  onClickFilterOtherPowers(filterOtherPowersButton)
  onClickFilterNonAggressive(filterNonAggressiveButton)
  onClickFilterAggressive(filterAggressiveButton)

  conditionPanel = conditionWindow:recursiveGetChildById('conditionPanel')

  ProtocolGame.registerOpcode(GameServerOpcodes.GameServerConditionsList, parseConditions)
  connect(g_game, {
    onGameEnd = offline
  })
  connect(LocalPlayer, {
    onStatesChange = onStatesChange
  })

  local localPlayer = g_game.getLocalPlayer()
  if localPlayer then
    onStatesChange(localPlayer, localPlayer:getStates(), 0)
  end
end

function terminate()
  conditionList = {}

  disconnect(LocalPlayer, {
    onStatesChange = onStatesChange
  })
  disconnect(g_game, {
    onGameEnd = offline
  })

  ProtocolGame.unregisterOpcode(GameServerOpcodes.GameServerConditionsList)

  conditionButton:destroy()
  conditionWindow:destroy()

  g_keyboard.unbindKeyDown('Ctrl+Shift+C')
end

function offline()
  clearList()
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

-- Filtering
function onClickFilterPanelButton(self, state) -- Needs 'state' because Button doesn't updates itself
  g_settings.setValue('Conditions', 'filterPanel', state)
  toggleFilterPanelButton:setOn(state)
  filterPanel:setOn(state)
  firstHorizontalSeparator:setOn(state)
end

function onClickFilterDefault(self)
  local enabled = self:isChecked()
  g_settings.setValue('Conditions', 'filterDefault', enabled)

  if enabled then
    defaultConditionPanel:show()
    firstHorizontalSeparator:show()
    secondHorizontalSeparator:show()
  else
    defaultConditionPanel:hide()
    firstHorizontalSeparator:hide()
    secondHorizontalSeparator:hide()
  end
  defaultConditionPanel:setOn(enabled)
  secondHorizontalSeparator:setOn(enabled)
end

function conditionButtonFilter(condition)
  local filterDefault       = not filterDefaultButton:isChecked()
  local filterSelfPowers    = not filterSelfPowersButton:isChecked()
  local filterOtherPowers   = not filterOtherPowersButton:isChecked()
  local filterNonAggressive = not filterNonAggressiveButton:isChecked()
  local filterAggressive    = not filterAggressiveButton:isChecked()

  local isAggressive = condition.isAggressive
  local isPower      = condition.power and condition.power > 0
  local isOwn        = condition.originId and g_game.getLocalPlayer():getId() == condition.originId
  return filterSelfPowers and isPower and isOwn or filterOtherPowers and isPower and not isOwn or filterNonAggressive and not isAggressive or filterAggressive and isAggressive or false
end

function filterConditionButtons()
  for i, condition in pairs(conditionList) do
    condition.button:setOn(not conditionButtonFilter(condition))
  end
end

function onClickFilterSelfPowers(self)
  g_settings.setValue('Conditions', 'filterSelfPowers', self:isChecked())
  filterConditionButtons()
end

function onClickFilterOtherPowers(self)
  g_settings.setValue('Conditions', 'filterOtherPowers', self:isChecked())
  filterConditionButtons()
end

function onClickFilterNonAggressive(self)
  g_settings.setValue('Conditions', 'filterNonAggressive', self:isChecked())
  filterConditionButtons()
end

function onClickFilterAggressive(self)
  g_settings.setValue('Conditions', 'filterAggressive', self:isChecked())
  filterConditionButtons()
end

-- Sorting
function getSortType()
  return g_settings.getValue('Conditions', 'sortType', defaultValues.sortType)
end

function setSortType(state)
  g_settings.setValue('Conditions', 'sortType', state)
  sortMenuButton:setTooltip(tr('Sort by: %s (%s)', conditionSortStr[state] or '', conditionOrderStr[getSortOrder()] or ''))
  updateConditionList()
end

function getSortOrder()
  return g_settings.getValue('Conditions', 'sortOrder', defaultValues.sortOrder)
end

function setSortOrder(state)
  g_settings.setValue('Conditions', 'sortOrder', state)
  sortMenuButton:setTooltip(tr('Sort by: %s (%s)', conditionSortStr[getSortType()] or '', conditionOrderStr[state] or ''))
  updateConditionList()
end

function createSortMenu()
  local menu = g_ui.createWidget('PopupMenu')

  local sortOrder = getSortOrder()
  if sortOrder == CONDITION_ORDER_ASCENDING then
    menu:addOption(tr('%s Order', conditionOrderStr[CONDITION_ORDER_DESCENDING]), function() setSortOrder(CONDITION_ORDER_DESCENDING) end)
  elseif sortOrder == CONDITION_ORDER_DESCENDING then
    menu:addOption(tr('%s Order', conditionOrderStr[CONDITION_ORDER_ASCENDING]), function() setSortOrder(CONDITION_ORDER_ASCENDING) end)
  end

  menu:addSeparator()

  local sortType = getSortType()
  if sortType ~= CONDITION_SORT_APPEAR then
    menu:addOption(tr('Sort by %s', conditionSortStr[CONDITION_SORT_APPEAR]), function() setSortType(CONDITION_SORT_APPEAR) end)
  end
  if sortType ~= CONDITION_SORT_NAME then
    menu:addOption(tr('Sort by %s', conditionSortStr[CONDITION_SORT_NAME]), function() setSortType(CONDITION_SORT_NAME) end)
  end
  if sortType ~= CONDITION_SORT_PERCENTAGE then
    menu:addOption(tr('Sort by %s', conditionSortStr[CONDITION_SORT_PERCENTAGE]), function() setSortType(CONDITION_SORT_PERCENTAGE) end)
  end
  if sortType ~= CONDITION_SORT_REMAININGTIME then
    menu:addOption(tr('Sort by %s', conditionSortStr[CONDITION_SORT_REMAININGTIME]), function() setSortType(CONDITION_SORT_REMAININGTIME) end)
  end

  menu:display()
end

function sortConditions()
  local sortFunction
  local sortOrder = getSortOrder()
  local sortType  = getSortType()

  if sortOrder == CONDITION_ORDER_ASCENDING then
    if sortType == CONDITION_SORT_APPEAR then
      sortFunction = function(a,b) return a.startTime < b.startTime end
    elseif sortType == CONDITION_SORT_NAME then
      sortFunction = function(a,b) return a.name < b.name end
    elseif sortType == CONDITION_SORT_PERCENTAGE then
      sortFunction = function(a,b) return a.button.clock:getPercent() < b.button.clock:getPercent() end
    elseif sortType == CONDITION_SORT_REMAININGTIME then
      sortFunction = function(a,b) return a.button.clock:getRemainingTime() < b.button.clock:getRemainingTime() end
    end

  elseif sortOrder == CONDITION_ORDER_DESCENDING then
    if sortType == CONDITION_SORT_APPEAR then
      sortFunction = function(a,b) return a.startTime > b.startTime end
    elseif sortType == CONDITION_SORT_NAME then
      sortFunction = function(a,b) return a.name > b.name end
    elseif sortType == CONDITION_SORT_PERCENTAGE then
      sortFunction = function(a,b) return a.button.clock:getPercent() > b.button.clock:getPercent() end
    elseif sortType == CONDITION_SORT_REMAININGTIME then
      sortFunction = function(a,b) return a.button.clock:getRemainingTime() > b.button.clock:getRemainingTime() end
    end
  end

  if sortFunction then
    table.sort(conditionList, sortFunction)
  end
end

function updateConditionList()
  sortConditions()
  for i = 1, #conditionList do
    conditionPanel:moveChildToIndex(conditionList[i].button, i)
  end
  filterConditionButtons()
end

function clearListConditionPanel()
  conditionList = {}
  conditionPanel:destroyChildren()
end

function clearListDefaultConditionPanel()
  defaultConditionPanel:destroyChildren()
end

function clearList()
  clearListConditionPanel()
  clearListDefaultConditionPanel()
end

-- Default conditions

function loadIcon(bitChanged)
  local icon = g_ui.createWidget('ConditionWidget', content)
  icon:setId(Icons[bitChanged].id)
  icon:setImageSource(Icons[bitChanged].path)
  icon:setTooltip(Icons[bitChanged].tooltip)
  return icon
end

function toggleIcon(bitChanged)
  local content = conditionWindow:recursiveGetChildById('defaultConditionPanel')

  if Icons[bitChanged] then
    local icon = content:getChildById(Icons[bitChanged].id)
    if icon then
      icon:destroy()
    else
      icon = loadIcon(bitChanged)
      icon:setParent(content)
    end
  end
end

function onStatesChange(localPlayer, now, old)
  if now == old then return end

  local bitsChanged = bit32.bxor(now, old)
  for i = 1, 32 do
    local pow = math.pow(2, i-1)
    if pow > bitsChanged then break end
    local bitChanged = bit32.band(bitsChanged, pow)
    if bitChanged ~= 0 then
      toggleIcon(bitChanged)
    end
  end
end

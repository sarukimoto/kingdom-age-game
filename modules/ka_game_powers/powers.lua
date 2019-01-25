powersButton = nil
powersWindow = nil
sortMenuButton = nil
toggleFilterPanelButton = nil

filterPanel = nil
filterNonAggressiveButton = nil
filterAggressiveButton = nil
filterNonPremiumButton = nil
filterPremiumButton = nil

firstHorizontalSeparator = nil

powersPanel = nil

POWERS_SORT_NAME  = 1
POWERS_SORT_CLASS = 2
POWERS_SORT_LEVEL = 3

POWERS_ORDER_ASCENDING  = 1
POWERS_ORDER_DESCENDING = 2

local powersSortStr = {
  [POWERS_SORT_NAME]  = 'Name',
  [POWERS_SORT_CLASS] = 'Class',
  [POWERS_SORT_LEVEL] = 'Level'
}

local powersOrderStr = {
  [POWERS_ORDER_ASCENDING]  = 'Ascending',
  [POWERS_ORDER_DESCENDING] = 'Descending'
}

local defaultValues = {
  filterPanel = true,
  filterNonAggressive = true,
  filterAggressive = true,
  filterNonPremium = true,
  filterPremium = true,
  sortType = POWERS_SORT_LEVEL,
  sortOrder = POWERS_ORDER_ASCENDING
}

local POWER_CLASS_ALL       = 0
local POWER_CLASS_OFFENSIVE = 1
local POWER_CLASS_DEFENSIVE = 2
local POWER_CLASS_SUPPORT   = 3
local POWER_CLASS_SPECIAL   = 4

local power_flag_updateList             = -3
local power_flag_updateNonConstantPower = -4

function init()
  powersList = {}
  powerListByIndex = {}

  g_ui.importStyle('powersbutton')
  g_keyboard.bindKeyDown('Ctrl+Shift+P', toggle)

  powersButton = modules.client_topmenu.addRightGameToggleButton('powersButton', tr('Powers') .. ' (Ctrl+Shift+P)', 'powers', toggle)
  powersButton:setOn(true)

  powersWindow = g_ui.loadUI('powers', modules.game_interface.getRightPanel())
  powersWindow:setContentMinimumHeight(80)
  powersWindow:setup()

  -- This disables scrollbar auto hiding
  local scrollbar = powersWindow:getChildById('miniwindowScrollBar')
  scrollbar:mergeStyle({ ['$!on'] = {} })

  sortMenuButton = powersWindow:getChildById('sortMenuButton')
  setSortType(getSortType())
  setSortOrder(getSortOrder())

  toggleFilterPanelButton   = powersWindow:getChildById('toggleFilterPanelButton')
  filterPanel               = powersWindow:recursiveGetChildById('filterPanel')
  firstHorizontalSeparator  = powersWindow:recursiveGetChildById('firstHorizontalSeparator')
  onClickFilterPanelButton(toggleFilterPanelButton, g_settings.getValue('Powers', 'filterPanel', defaultValues.filterPanel))

  filterNonAggressiveButton = powersWindow:recursiveGetChildById('filterNonAggressive')
  filterAggressiveButton    = powersWindow:recursiveGetChildById('filterAggressive')
  filterNonPremiumButton    = powersWindow:recursiveGetChildById('filterNonPremium')
  filterPremiumButton       = powersWindow:recursiveGetChildById('filterPremium')
  filterNonAggressiveButton:setChecked(g_settings.getValue('Powers', 'filterNonAggressive', defaultValues.filterNonAggressive))
  filterAggressiveButton:setChecked(g_settings.getValue('Powers', 'filterAggressive', defaultValues.filterAggressive))
  filterNonPremiumButton:setChecked(g_settings.getValue('Powers', 'filterNonPremium', defaultValues.filterNonPremium))
  filterPremiumButton:setChecked(g_settings.getValue('Powers', 'filterPremium', defaultValues.filterPremium))
  onClickFilterNonAggressive(filterNonAggressiveButton)
  onClickFilterAggressive(filterAggressiveButton)
  onClickFilterNonPremium(filterNonPremiumButton)
  onClickFilterPremium(filterPremiumButton)

  powersPanel = powersWindow:recursiveGetChildById('powersPanel')

  connect(g_game, {
    onGameStart        = online,
    onGameEnd          = offline,
    onPlayerPowersList = onPlayerPowersList
  })
end

function terminate()
  powersList = {}
  powerListByIndex = {}

  disconnect(g_game, {
    onGameStart        = online,
    onGameEnd          = offline,
    onPlayerPowersList = onPlayerPowersList
  })

  powersButton:destroy()
  powersWindow:destroy()

  g_keyboard.unbindKeyDown('Ctrl+Shift+P')
end

function online()
  refreshList()
end

function offline()
  clearList()
end

-- Top menu button
function toggle()
  if powersButton:isOn() then
    powersWindow:close()
    powersButton:setOn(false)
  else
    powersWindow:open()
    powersButton:setOn(true)
  end
end

function onMiniWindowClose()
  if powersButton then
    powersButton:setOn(false)
  end
end

-- Filtering
function onClickFilterPanelButton(self, state) -- Needs 'state' because Button doesn't updates itself
  g_settings.setValue('Powers', 'filterPanel', state)
  toggleFilterPanelButton:setOn(state)
  filterPanel:setOn(state)
  firstHorizontalSeparator:setOn(state)
end

function powersButtonFilter(powerButton)
  local filterNonAggressive = not filterNonAggressiveButton:isChecked()
  local filterAggressive    = not filterAggressiveButton:isChecked()
  local filterNonPremium    = not filterNonPremiumButton:isChecked()
  local filterPremium       = not filterPremiumButton:isChecked()
  local power = powerButton.power
  return filterNonAggressive and not power.isOffensive or filterAggressive and power.isOffensive or filterNonPremium and not power.isPremium or filterPremium and power.isPremium or false
end

function filterPowersButtons()
  for i, powerButton in pairs(powersList) do
    powerButton:setOn(not powersButtonFilter(powerButton))
  end
end

function onClickFilterNonAggressive(self)
  g_settings.setValue('Powers', 'filterNonAggressive', self:isChecked())
  filterPowersButtons()
end

function onClickFilterAggressive(self)
  g_settings.setValue('Powers', 'filterAggressive', self:isChecked())
  filterPowersButtons()
end

function onClickFilterNonPremium(self)
  g_settings.setValue('Powers', 'filterNonPremium', self:isChecked())
  filterPowersButtons()
end

function onClickFilterPremium(self)
  g_settings.setValue('Powers', 'filterPremium', self:isChecked())
  filterPowersButtons()
end

-- Sorting
function getSortType()
  return g_settings.getValue('Powers', 'sortType', defaultValues.sortType)
end

function setSortType(state)
  g_settings.setValue('Powers', 'sortType', state)
  sortMenuButton:setTooltip(tr('Sort by: %s (%s)', powersSortStr[state] or '', powersOrderStr[getSortOrder()] or ''))
  updatePowersList()
end

function getSortOrder()
  return g_settings.getValue('Powers', 'sortOrder', defaultValues.sortOrder)
end

function setSortOrder(state)
  g_settings.setValue('Powers', 'sortOrder', state)
  sortMenuButton:setTooltip(tr('Sort by: %s (%s)', powersSortStr[getSortType()] or '', powersOrderStr[state] or ''))
  updatePowersList()
end

function createSortMenu()
  local menu = g_ui.createWidget('PopupMenu')

  local sortOrder = getSortOrder()
  if sortOrder == POWERS_ORDER_ASCENDING then
    menu:addOption(tr('%s Order', powersOrderStr[POWERS_ORDER_DESCENDING]), function() setSortOrder(POWERS_ORDER_DESCENDING) end)
  elseif sortOrder == POWERS_ORDER_DESCENDING then
    menu:addOption(tr('%s Order', powersOrderStr[POWERS_ORDER_ASCENDING]), function() setSortOrder(POWERS_ORDER_ASCENDING) end)
  end

  menu:addSeparator()

  local sortType = getSortType()
  if sortType ~= POWERS_SORT_NAME then
    menu:addOption(tr('Sort by %s', powersSortStr[POWERS_SORT_NAME]), function() setSortType(POWERS_SORT_NAME) end)
  end
  if sortType ~= POWERS_SORT_CLASS then
    menu:addOption(tr('Sort by %s', powersSortStr[POWERS_SORT_CLASS]), function() setSortType(POWERS_SORT_CLASS) end)
  end
  if sortType ~= POWERS_SORT_LEVEL then
    menu:addOption(tr('Sort by %s', powersSortStr[POWERS_SORT_LEVEL]), function() setSortType(POWERS_SORT_LEVEL) end)
  end

  menu:display()
end

function sortPowers()
  local sortFunction
  local sortOrder = getSortOrder()
  local sortType  = getSortType()

  if sortOrder == POWERS_ORDER_ASCENDING then
    if sortType == POWERS_SORT_NAME then
      sortFunction = function(a,b) return a.power.name < b.power.name end
    elseif sortType == POWERS_SORT_CLASS then
      sortFunction = function(a,b) return a.power.class < b.power.class end
    elseif sortType == POWERS_SORT_LEVEL then
      sortFunction = function(a,b) return a.power.level < b.power.level end
    end

  elseif sortOrder == POWERS_ORDER_DESCENDING then
    if sortType == POWERS_SORT_NAME then
      sortFunction = function(a,b) return a.power.name > b.power.name end
    elseif sortType == POWERS_SORT_CLASS then
      sortFunction = function(a,b) return a.power.class > b.power.class end
    elseif sortType == POWERS_SORT_LEVEL then
      sortFunction = function(a,b) return a.power.level > b.power.level end
    end

  end

  if sortFunction then
    table.sort(powerListByIndex, sortFunction)
  end
end

function updatePowersList()
  sortPowers()
  for i = 1, #powerListByIndex do
    powersPanel:moveChildToIndex(powerListByIndex[i], i)
    powerListByIndex[i].index = i
  end
  filterPowersButtons()
end

function clearList()
  powersList = {}
  powerListByIndex = {}
  powersPanel:destroyChildren()
end

function refreshList()
  if not g_game.isOnline() then return end

  clearList()

  local ignoreMessage = 1
  g_game.sendPowerProtocolData(string.format("%d:%d:%d:%d", power_flag_updateList, ignoreMessage, 0, 0))
end

function add(power, updateList)
  if update == nil then update = true end
  local powerButton = powersList[power.id]

  -- Update
  if powerButton then
    powerButton:updateData(power)
    return
  end

  -- Add
  powerButton = g_ui.createWidget('PowersListButton')
  powerButton:setup(power)

  -- powerButton.onMouseRelease = onPowerButtonMouseRelease

  powersList[power.id] = powerButton
  table.insert(powerListByIndex, powersList[power.id])

  powersPanel:addChild(powerButton)
  if updateList then
    updatePowersList()
  end
end

function remove(power)
  local index = nil
  if powersList[power.id] then
    index = powersList[power.id].index
    powersList[power.id]:destroy()
    powersList[power.id] = nil
    table.remove(powerListByIndex, index)
  end
end

function requestNonConstantPowerChanges(power)
  if not g_game.isOnline() then return end

  g_game.sendPowerProtocolData(string.format("%d:%d:%d:%d", power_flag_updateNonConstantPower, power.id or 0, 0, 0))
end

function onPlayerPowersList(powers, updateNonConstantPower)
  if not updateNonConstantPower then
    clearList()
  end

  for k, power in ipairs(powers) do
    local powerObj = {}

    powerObj.id                   = power[1]
    powerObj.name                 = power[2]
    powerObj.level                = power[3]
    powerObj.class                = power[4]
    powerObj.mana                 = power[5]
    powerObj.exhaustTime          = power[6]
    powerObj.vocations            = power[7]
    powerObj.isPremium            = power[8]
    powerObj.description          = power[9]
    powerObj.descriptionBoostNone = power[10]
    powerObj.descriptionBoostLow  = power[11]
    powerObj.descriptionBoostHigh = power[12]
    powerObj.isConstant           = power[13]
    powerObj.isOffensive          = powerObj.class == POWER_CLASS_OFFENSIVE

    powerObj.onTooltipHoverChange =
    function(widget, hovered)
      if hovered then
        local power = widget.power
        if power and not power.isConstant then
          requestNonConstantPowerChanges(power)
          return false -- Cancel old tooltip
        end
      end
      return true
    end

    add(powerObj, false)
  end

  if not updateNonConstantPower then
    updatePowersList() -- Update once after adding all powers
  end

  if updateNonConstantPower then
    local widget = g_game.getWidgetByPos()
    if g_tooltip and widget then
      g_tooltip.widgetHoverChange(widget, true) -- Automatically show updated power tooltip
    end
  end
end

function getPowerButton(id)
  return id and powersList[id] or nil
end

function getPower(id)
  local ret = getPowerButton(id)
  return ret and ret.power or nil
end

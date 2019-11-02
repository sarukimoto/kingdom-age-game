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

  refreshList()
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
  if not g_game.isOnline() then
    return
  end

  clearList()

  local ignoreMessage = 1
  g_game.sendPowerProtocolData(string.format("%d:%d:%d:%d", power_flag_updateList, ignoreMessage, 0, 0))
end

function add(power)
  local powerButton = powersList[power.id]
  if powerButton then
    return false -- Already added
  end

  -- Add
  powerButton = g_ui.createWidget('PowersListButton')
  powerButton:setup(power)

  -- powerButton.onMouseRelease = onPowerButtonMouseRelease

  powersList[power.id] = powerButton
  table.insert(powerListByIndex, powersList[power.id])

  powersPanel:addChild(powerButton)

  return true -- New added successfully
end

function update(power)
  local powerButton = powersList[power.id]
  if not powerButton then
    return false
  end

  powerButton:updateData(power)

  return true -- Updated successfully
end

function remove(powerId)
  if not powersList[powerId] then
    return false
  end

  powerListByIndex[powersList[powerId].index] = nil
  local widget = powersList[powerId]
  powersList[powerId] = nil
  widget:destroy()

  return true -- Removed successfully
end

function requestNonConstantPowerChanges(power)
  if not g_game.isOnline() then return end

  g_game.sendPowerProtocolData(string.format("%d:%d:%d:%d", power_flag_updateNonConstantPower, power.id or 0, 0, 0))
end

function onPlayerPowersList(powers, updateNonConstantPower, ignoreMessage)
  local hasAdded   = false
  local hasRemoved = false

  -- For add and update
  for _, powerData in ipairs(powers) do
    local power = {}

    power.id                   = powerData[1]
    power.name                 = powerData[2]
    power.level                = powerData[3]
    power.class                = powerData[4]
    power.mana                 = powerData[5]
    power.exhaustTime          = powerData[6]
    power.vocations            = powerData[7]
    power.isPremium            = powerData[8]
    power.description          = powerData[9]
    power.descriptionBoostNone = powerData[10]
    power.descriptionBoostLow  = powerData[11]
    power.descriptionBoostHigh = powerData[12]
    power.isConstant           = powerData[13]
    power.isOffensive          = power.class == POWER_CLASS_OFFENSIVE

    power.onTooltipHoverChange =
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

    local powerButton = powersList[power.id]
    if not powerButton then
      if not updateNonConstantPower then
        -- Add
        local ret = add(power)
        if not hasAdded then
          hasAdded = ret
        end
      end
    else
      -- Update
      update(power) -- No messages in this case, since is probably minor changes or nothing
    end
  end

  -- For remove
  -- for powerId, _ in pairs(powersList) do
  if not updateNonConstantPower then
    for i = #powersList, 1, -1 do
      local powerFound = false

      for _, powerData in ipairs(powers) do
        if powerId == powerData[1] then
          powerFound = true
          break
        end
      end

      if not powerFound then
        -- Remove
        local ret = remove(powerId)
        if not hasRemoved then
          hasRemoved = ret
        end
      end
    end
  end

  if not ignoreMessage and (hasAdded or hasRemoved) and modules.game_textmessage then
    modules.game_textmessage.displayGameMessage(tr('Your power list has been updated.'))
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

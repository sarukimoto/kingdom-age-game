local power_flag_updateList             = -3
local power_flag_updateNonConstantPower = -4

local POWER_CLASS_ALL       = 0
local POWER_CLASS_OFFENSIVE = 1
local POWER_CLASS_DEFENSIVE = 2
local POWER_CLASS_SUPPORT   = 3
local POWER_CLASS_SPECIAL   = 4

powersListTopButton = nil
powersListWindow = nil

mouseWidget = nil

ballButton = nil

filterSortPanel = nil
filterHiddenPanel = nil

sortTypeBox = nil
sortOrderBox = nil

hideNonOffensiveButton = nil
hideOffensiveButton = nil
hideNonPremiumButton = nil
hidePremiumButton = nil

horizontalSeparator = nil

powersListPanel = nil

lastPowerButtonSwitched = nil
powerButtonsByIdList    = {}

function init()
  g_ui.importStyle('powerslistbutton')

  powersListWindow = g_ui.loadUI('ka_powerslist', modules.game_interface.getRightPanel())
  powersListWindow:setContentMinimumHeight(94)
  powersListWindow:setup()
  powersListTopButton = modules.client_topmenu.addRightGameToggleButton('powersListTopButton', tr('Powers') .. ' (Ctrl+Shift+P)', 'ka_powerslist', toggle)
  powersListTopButton:setOn(true)
  g_keyboard.bindKeyDown('Ctrl+Shift+P', toggle)

  -- This disables scrollbar auto hiding
  local scrollbar = powersListWindow:getChildById('miniwindowScrollBar')
  scrollbar:mergeStyle({ ['$!on'] = {} })

  mouseWidget = g_ui.createWidget('UIButton')
  mouseWidget:setVisible(false)
  mouseWidget:setFocusable(false)
  mouseWidget.cancelNextRelease = false

  ballButton = powersListWindow:getChildById('ballButton')

  filterSortPanel   = powersListWindow:recursiveGetChildById('filterSortPanel')
  filterHiddenPanel = powersListWindow:recursiveGetChildById('filterHiddenPanel')
  if isHidingFilters() then
    hideFiltersPanel()
  end

  sortTypeBox  = powersListWindow:recursiveGetChildById('sortTypeBox')
  sortTypeBox:addOption('Name', 'name')
  sortTypeBox:addOption('Class', 'class')
  sortTypeBox:addOption('Level', 'level')
  sortTypeBox:setCurrentOptionByData(getSortType())
  sortTypeBox.onOptionChange = onChangeSortType

  sortOrderBox = powersListWindow:recursiveGetChildById('sortOrderBox')
  sortOrderBox:addOption('Asc.', 'asc')
  sortOrderBox:addOption('Desc.', 'desc')
  sortOrderBox:setCurrentOptionByData(getSortOrder())
  sortOrderBox.onOptionChange = onChangeSortOrder

  hideNonOffensiveButton = powersListWindow:recursiveGetChildById('hideNonOffensive')
  hideOffensiveButton    = powersListWindow:recursiveGetChildById('hideOffensive')
  hideNonPremiumButton   = powersListWindow:recursiveGetChildById('hideNonPremium')
  hidePremiumButton      = powersListWindow:recursiveGetChildById('hidePremium')

  horizontalSeparator = powersListWindow:recursiveGetChildById('horizontalSeparator')

  powersListPanel = powersListWindow:recursiveGetChildById('powersListPanel')

  connect(g_game, {
    onGameStart        = online,
    onGameEnd          = offline,
    onPlayerPowersList = onPlayerPowersList
  })

  checkPowers()
end

function terminate()
  powerButtonsByIdList = {}

  disconnect(g_game, {
    onGameStart        = online,
    onGameEnd          = offline,
    onPlayerPowersList = onPlayerPowersList
  })

  mouseWidget:destroy()
  powersListTopButton:destroy()
  powersListWindow:destroy()

  g_keyboard.unbindKeyDown('Ctrl+Shift+P')
end

function online()
  if filterSortPanel:isVisible() and filterHiddenPanel:isVisible() then
    ballButton:setTooltip('Hide options')
  else
    ballButton:setTooltip('Show options')
  end

  checkPowers()
end

function offline()
  removeAllPowers()
end

function onMiniWindowClose()
  if powersListTopButton then
    powersListTopButton:setOn(false)
  end
end

function onMiniWindowBallButton()
  toggleFilterPanel()
end

function toggle()
  if powersListTopButton:isOn() then
    powersListWindow:close()
    powersListTopButton:setOn(false)
  else
    powersListWindow:open()
    powersListTopButton:setOn(true)
  end
end



function hasPower(power)
  return powerButtonsByIdList[power.id] and true or false
end

function addPower(power)
  -- Add
  if not hasPower(power) then
    if not powerFitFilters(power) then return end

    local powerButton = g_ui.createWidget('PowersListButton')
    powerButton:setup(power)

    powerButton.onMouseRelease = onPowerButtonMouseRelease

    powerButtonsByIdList[power.id] = powerButton

    local inserted  = false
    local sortType  = getSortType()
    local sortOrder = getSortOrder()

    local childCount = powersListPanel:getChildCount()
    for i = 1, childCount do
      local equal = false
      local child = powersListPanel:getChildByIndex(i)

      if sortType == 'appear' then
        powersListPanel:insertChild(isSortAsc() and childCount + 1 or 1, powerButton)
        inserted = true
        break

      elseif sortType == 'class' or sortType == 'level' then
        if (power[sortType] < child.power[sortType] and isSortAsc()) or (power[sortType] > child.power[sortType] and isSortDesc()) then
          powersListPanel:insertChild(i, powerButton)
          inserted = true
          break
        elseif power[sortType] == child.power[sortType] then
          equal = true
        end
      end

      -- If any other sort type is selected and values are equal, sort it by name also
      if sortType == 'name' or equal then
        local nameLower = power.name:lower()
        local childName = child.power.name:lower()
        for j = 1, math.min(nameLower:len(), childName:len()) do
          if (nameLower:byte(j) < childName:byte(j) and isSortAsc()) or (nameLower:byte(j) > childName:byte(j) and isSortDesc()) then
            powersListPanel:insertChild(i, powerButton)
            inserted = true
            break
          elseif (nameLower:byte(j) > childName:byte(j) and isSortAsc()) or (nameLower:byte(j) < childName:byte(j) and isSortDesc()) then
            break
          elseif j == nameLower:len() and isSortAsc() then
            powersListPanel:insertChild(i, powerButton)
            inserted = true
          elseif j == childName:len() and isSortDesc() then
            powersListPanel:insertChild(i, powerButton)
            inserted = true
          end
        end
      end

      if inserted then
        break
      end
    end

    -- Insert at the end if no other place is found
    if not inserted then
      powersListPanel:insertChild(childCount + 1, powerButton)
    end

  -- Update
  else
    local powerButton = powerButtonsByIdList[power.id]
    powerButton:updateData(power)
  end
end

function removeAllPowers()
  for _, powerButton in pairs(powerButtonsByIdList) do
    removePower(powerButton.power)
  end
end

function removePower(power)
  if hasPower(power) then
    if lastPowerButtonSwitched == powerButtonsByIdList[power.id] then
      lastPowerButtonSwitched = nil
    end

    -- Remove power button
    powerButtonsByIdList[power.id]:destroy()
    powerButtonsByIdList[power.id] = nil
  end
end



-- Filters

function isHidingFilters()
  local settings = g_settings.getNode('PowersList')
  if settings and type(settings['hidingFilters']) == 'boolean' then
    return settings['hidingFilters']
  end
  return false
end

function setHidingFilters(state)
  local settings = {}
  settings['hidingFilters'] = state
  g_settings.mergeNode('PowersList', settings)
end

function hideFiltersPanel()
  -- Comboboxes to Sort
  filterSortPanel.originalHeight    = filterSortPanel:getHeight()
  filterSortPanel.originalMarginTop = filterSortPanel:getMarginTop()
  filterSortPanel:setHeight(0)
  filterSortPanel:setMarginTop(0)
  filterSortPanel:setVisible(false)

  -- Buttons to Hide
  filterHiddenPanel.originalHeight    = filterHiddenPanel:getHeight()
  filterHiddenPanel.originalMarginTop = filterHiddenPanel:getMarginTop()
  filterHiddenPanel:setHeight(0)
  filterHiddenPanel:setMarginTop(0)
  filterHiddenPanel:setVisible(false)

  -- Horizontal Separator
  horizontalSeparator.originalHeight    = horizontalSeparator:getHeight()
  horizontalSeparator.originalMarginTop = horizontalSeparator:getMarginTop()
  horizontalSeparator:setHeight(0)
  horizontalSeparator:setMarginTop(0)
  horizontalSeparator:setVisible(false)

  setHidingFilters(true)
  ballButton:setTooltip('Show options')
end

function showFiltersPanel()
  -- Comboboxes to Sort
  filterSortPanel:setHeight(filterSortPanel.originalHeight or 0)
  filterSortPanel:setMarginTop(filterSortPanel.originalMarginTop or 0)
  filterSortPanel:setVisible(true)

  -- Buttons to Hide
  filterHiddenPanel:setHeight(filterHiddenPanel.originalHeight or 0)
  filterHiddenPanel:setMarginTop(filterHiddenPanel.originalMarginTop or 0)
  filterHiddenPanel:setVisible(true)

  -- Horizontal Separator
  horizontalSeparator:setHeight(horizontalSeparator.originalHeight or 0)
  horizontalSeparator:setMarginTop(horizontalSeparator.originalMarginTop or 0)
  horizontalSeparator:setVisible(true)

  setHidingFilters(false)
  ballButton:setTooltip('Hide options')
end

function toggleFilterPanel()
  if filterSortPanel:isVisible() and filterHiddenPanel:isVisible() then
    hideFiltersPanel()
  else
    showFiltersPanel()
  end
end



-- Sort

function getSortType()
  local settings = g_settings.getNode('PowersList')
  return settings and settings['sortType'] or 'appear'
end

function setSortType(state)
  local settings = {}
  settings['sortType'] = state
  g_settings.mergeNode('PowersList', settings)
  checkPowers()
end

function getSortOrder()
  local settings = g_settings.getNode('PowersList')
  return settings and settings['sortOrder'] or 'desc'
end

function setSortOrder(state)
  local settings = {}
  settings['sortOrder'] = state
  g_settings.mergeNode('PowersList', settings)
  checkPowers()
end

function isSortAsc()
  return getSortOrder() == 'asc'
end

function isSortDesc()
  return getSortOrder() == 'desc'
end

function onChangeSortType(comboBox, option)
  setSortType(option:lower())
end

function onChangeSortOrder(comboBox, option)
  -- Replace dot in option name
  setSortOrder(option:lower():gsub('[.]', ''))
end



function powerFitFilters(power)
  if hideNonOffensiveButton:isChecked() and not power.isOffensive or hideOffensiveButton:isChecked() and power.isOffensive or hideNonPremiumButton:isChecked() and not power.isPremium or hidePremiumButton:isChecked() and power.isPremium then
    return false
  end
  return true
end

function checkPowers()
  removeAllPowers()

  if not g_game.isOnline() then
    return
  end

  g_game.sendPowerProtocolData(string.format("%d:%d:%d:%d", power_flag_updateList, 0, 0, 0))
end

function requestNonConstantPowerChanges(power)
  if not g_game.isOnline() then return end

  g_game.sendPowerProtocolData(string.format("%d:%d:%d:%d", power_flag_updateNonConstantPower, power.id or 0, 0, 0))
end



function onPowerButtonMouseRelease(self, mousePosition, mouseButton)
  if mouseWidget.cancelNextRelease then
    mouseWidget.cancelNextRelease = false
    return false
  end

  if mouseButton == MouseLeftButton then
    -- Do nothing, but returns true
    return true
  end
  return false
end

function onPlayerPowersList(powers, updateNonConstantPower)
  if not updateNonConstantPower then
    removeAllPowers()
  end

  for k, power in ipairs(powers) do
    local params = {}

    params.id                   = power[1]
    params.name                 = power[2]
    params.level                = power[3]
    params.class                = power[4]
    params.mana                 = power[5]
    params.exhaustTime          = power[6]
    params.vocations            = power[7]
    params.isPremium            = power[8]
    params.description          = power[9]
    params.descriptionBoostNone = power[10]
    params.descriptionBoostLow  = power[11]
    params.descriptionBoostHigh = power[12]
    params.isConstant           = power[13]
    params.isOffensive          = params.class == POWER_CLASS_OFFENSIVE

    params.onHover =
    function(widget, hovered)
      local power = widget.power
      if hovered and power and not power.isConstant then
        requestNonConstantPowerChanges(power)
        return false -- Cancel old tooltip
      end
      return true
    end

    addPower(params)
  end

  if updateNonConstantPower then
    local widget = g_game.getWidgetByPos()
    if widget then
      g_tooltip.widgetHoverChange(widget, true) -- Automatically show updated power tooltip
    end
  end
end

function getPower(id)
  return powerButtonsByIdList[id]
end

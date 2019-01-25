battleButton = nil
battleWindow = nil
sortMenuButton = nil
toggleFilterPanelButton = nil

filterPanel = nil
filterPlayersButton = nil
filterNPCsButton = nil
filterMonstersButton = nil
filterSkullsButton = nil
filterPartyButton = nil

firstHorizontalSeparator = nil

battlePanel = nil

mouseWidget = nil
lastBattleButtonSwitched = nil

-- Sorting
BATTLE_SORT_APPEAR   = 1
BATTLE_SORT_DISTANCE = 2
BATTLE_SORT_HEALTH   = 3
BATTLE_SORT_NAME     = 4

BATTLE_ORDER_ASCENDING  = 1
BATTLE_ORDER_DESCENDING = 2

local battleSortStr = {
  [BATTLE_SORT_APPEAR]   = 'Appear',
  [BATTLE_SORT_DISTANCE] = 'Distance',
  [BATTLE_SORT_HEALTH]   = 'Health',
  [BATTLE_SORT_NAME]     = 'Name',
}

local battleOrderStr = {
  [BATTLE_ORDER_ASCENDING]  = 'Ascending',
  [BATTLE_ORDER_DESCENDING] = 'Descending'
}

local defaultValues = {
  filterPanel = true,
  filterPlayers = true,
  filterNPCs = true,
  filterMonsters = true,
  filterSkulls = true,
  filterParty = true,
  sortType = BATTLE_SORT_APPEAR,
  sortOrder = BATTLE_ORDER_DESCENDING
}

-- position check
local lastPosCheck = g_clock.millis()
BATTLE_POS_UPDATE_DELAY = 1000

function init()
  battleList        = {}
  battleListByIndex = {}

  g_ui.importStyle('battlebutton')
  g_keyboard.bindKeyDown('Ctrl+B', toggle)

  battleButton = modules.client_topmenu.addRightGameToggleButton('battleButton', tr('Battle') .. ' (Ctrl+B)', '/images/topbuttons/battle', toggle)
  battleButton:setOn(true)

  battleWindow = g_ui.loadUI('battle', modules.game_interface.getRightPanel())
  battleWindow:setContentMinimumHeight(80)
  battleWindow:setup()

  -- This disables scrollbar auto hiding
  local scrollbar = battleWindow:getChildById('miniwindowScrollBar')
  scrollbar:mergeStyle({ ['$!on'] = {} })

  sortMenuButton = battleWindow:getChildById('sortMenuButton')
  setSortType(getSortType())
  setSortOrder(getSortOrder())

  toggleFilterPanelButton   = battleWindow:getChildById('toggleFilterPanelButton')
  filterPanel               = battleWindow:recursiveGetChildById('filterPanel')
  firstHorizontalSeparator  = battleWindow:recursiveGetChildById('firstHorizontalSeparator')
  onClickFilterPanelButton(toggleFilterPanelButton, g_settings.getValue('Battle', 'filterPanel', defaultValues.filterPanel))

  filterPlayersButton  = battleWindow:recursiveGetChildById('filterPlayers')
  filterNPCsButton     = battleWindow:recursiveGetChildById('filterNPCs')
  filterMonstersButton = battleWindow:recursiveGetChildById('filterMonsters')
  filterSkullsButton   = battleWindow:recursiveGetChildById('filterSkulls')
  filterPartyButton    = battleWindow:recursiveGetChildById('filterParty')
  filterPlayersButton:setChecked(g_settings.getValue('Battle', 'filterPlayers', defaultValues.filterPlayers))
  filterNPCsButton:setChecked(g_settings.getValue('Battle', 'filterNPCs', defaultValues.filterNPCs))
  filterMonstersButton:setChecked(g_settings.getValue('Battle', 'filterMonsters', defaultValues.filterMonsters))
  filterSkullsButton:setChecked(g_settings.getValue('Battle', 'filterSkulls', defaultValues.filterSkulls))
  filterPartyButton:setChecked(g_settings.getValue('Battle', 'filterParty', defaultValues.filterParty))
  onClickFilterPlayers(filterPlayersButton)
  onClickFilterNPCs(filterNPCsButton)
  onClickFilterMonsters(filterMonstersButton)
  onClickFilterSkulls(filterSkullsButton)
  onClickFilterParty(filterPartyButton)

  battlePanel = battleWindow:recursiveGetChildById('battlePanel')

  mouseWidget = g_ui.createWidget('UIButton')
  mouseWidget:setVisible(false)
  mouseWidget:setFocusable(false)
  mouseWidget.cancelNextRelease = false

  connect(Creature, {
    onAppear = onAppear,
    onDisappear = onDisappear,
    onPositionChange = onPositionChange,
    onSkullChange = onSkullChange,
    onEmblemChange = onEmblemChange,
    onSpecialIconChange = onSpecialIconChange,
    onHealthPercentChange = onHealthPercentChange,
    onNicknameChange = onNicknameChange
  })

  connect(LocalPlayer, {
    onPositionChange = onPositionChange
  })

  connect(g_game, {
    onAttackingCreatureChange = onAttackingCreatureChange,
    onFollowingCreatureChange = onFollowingCreatureChange,
    onGameEnd = offline
  })

  refreshList()
end

function terminate()
  battleList        = {}
  battleListByIndex = {}

  disconnect(g_game, {
    onAttackingCreatureChange = onAttackingCreatureChange,
    onFollowingCreatureChange = onFollowingCreatureChange,
    onGameEnd = offline
  })

  disconnect(LocalPlayer, {
    onPositionChange = onPositionChange
  })

  disconnect(Creature, {
    onAppear = onAppear,
    onDisappear = onDisappear,
    onPositionChange = onPositionChange,
    onSkullChange = onSkullChange,
    onEmblemChange = onEmblemChange,
    onSpecialIconChange = onSpecialIconChange,
    onHealthPercentChange = onHealthPercentChange,
    onNicknameChange = onNicknameChange
  })

  mouseWidget:destroy()

  battleButton:destroy()
  battleWindow:destroy()

  g_keyboard.unbindKeyDown('Ctrl+B')
end

function offline()
  clearList()
  if lastBattleButtonSwitched then
    lastBattleButtonSwitched = nil
  end
end

-- Top menu button
function toggle()
  if battleButton:isOn() then
    battleWindow:close()
    battleButton:setOn(false)
  else
    battleWindow:open()
    battleButton:setOn(true)
  end
end

function onMiniWindowClose()
  if battleButton then
    battleButton:setOn(false)
  end
end

-- Filtering
function onClickFilterPanelButton(self, state) -- Needs 'state' because Button doesn't updates itself
  g_settings.setValue('Battle', 'filterPanel', state)
  toggleFilterPanelButton:setOn(state)
  filterPanel:setOn(state)
  firstHorizontalSeparator:setOn(state)
end

function battleButtonFilter(battleButton)
  local filterPlayers  = not filterPlayersButton:isChecked()
  local filterNPCs     = not filterNPCsButton:isChecked()
  local filterMonsters = not filterMonstersButton:isChecked()
  local filterSkulls   = not filterSkullsButton:isChecked()
  local filterParty    = not filterPartyButton:isChecked()

  local creature = battleButton.creature
  local isPlayer = creature:isPlayer()
  return filterPlayers and isPlayer or filterNPCs and creature:isNpc() or filterMonsters and creature:isMonster() or filterSkulls and isPlayer and (creature:getSkull() == SkullNone or creature:getSkull() == SkullProtected) or filterParty and creature:getShield() > ShieldWhiteBlue or false
end

function filterBattleButtons()
  for _, battleButton in pairs(battleList) do
    local on = not battleButtonFilter(battleButton)
    local localPlayer = g_game.getLocalPlayer()
    if localPlayer and localPlayer:getPosition().z ~= battleButton.creature:getPosition().z then
      on = false
    end
    battleButton:setOn(on)
  end
end

function onClickFilterPlayers(self)
  g_settings.setValue('Battle', 'filterPlayers', self:isChecked())
  filterBattleButtons()
end

function onClickFilterNPCs(self)
  g_settings.setValue('Battle', 'filterNPCs', self:isChecked())
  filterBattleButtons()
end

function onClickFilterMonsters(self)
  g_settings.setValue('Battle', 'filterMonsters', self:isChecked())
  filterBattleButtons()
end

function onClickFilterSkulls(self)
  g_settings.setValue('Battle', 'filterSkulls', self:isChecked())
  filterBattleButtons()
end

function onClickFilterParty(self)
  g_settings.setValue('Battle', 'filterParty', self:isChecked())
  filterBattleButtons()
end

-- Sorting
function getSortType()
  return g_settings.getValue('Battle', 'sortType', defaultValues.sortType)
end

function setSortType(state)
  g_settings.setValue('Battle', 'sortType', state)
  sortMenuButton:setTooltip(tr('Sort by: %s (%s)', battleSortStr[state] or '', battleOrderStr[getSortOrder()] or ''))
  updateBattleList()
end

function getSortOrder()
  return g_settings.getValue('Battle', 'sortOrder', defaultValues.sortOrder)
end

function setSortOrder(state)
  g_settings.setValue('Battle', 'sortOrder', state)
  sortMenuButton:setTooltip(tr('Sort by: %s (%s)', battleSortStr[getSortType()] or '', battleOrderStr[state] or ''))
  updateBattleList()
end

function createSortMenu()
  local menu = g_ui.createWidget('PopupMenu')

  local sortOrder = getSortOrder()
  if sortOrder == BATTLE_ORDER_ASCENDING then
    menu:addOption(tr('%s Order', battleOrderStr[BATTLE_ORDER_DESCENDING]), function() setSortOrder(BATTLE_ORDER_DESCENDING) end)
  elseif sortOrder == BATTLE_ORDER_DESCENDING then
    menu:addOption(tr('%s Order', battleOrderStr[BATTLE_ORDER_ASCENDING]), function() setSortOrder(BATTLE_ORDER_ASCENDING) end)
  end

  menu:addSeparator()

  local sortType = getSortType()
  if sortType ~= BATTLE_SORT_APPEAR then
    menu:addOption(tr('Sort by %s', battleSortStr[BATTLE_SORT_APPEAR]), function() setSortType(BATTLE_SORT_APPEAR) end)
  end
  if sortType ~= BATTLE_SORT_DISTANCE then
    menu:addOption(tr('Sort by %s', battleSortStr[BATTLE_SORT_DISTANCE]), function() setSortType(BATTLE_SORT_DISTANCE) end)
  end
  if sortType ~= BATTLE_SORT_HEALTH then
    menu:addOption(tr('Sort by %s', battleSortStr[BATTLE_SORT_HEALTH]), function() setSortType(BATTLE_SORT_HEALTH) end)
  end
  if sortType ~= BATTLE_SORT_NAME then
    menu:addOption(tr('Sort by %s', battleSortStr[BATTLE_SORT_NAME]), function() setSortType(BATTLE_SORT_NAME) end)
  end

  menu:display()
end

function sortBattle()
  local sortFunction
  local sortOrder = getSortOrder()
  local sortType  = getSortType()

  if sortOrder == BATTLE_ORDER_ASCENDING then
    if sortType == BATTLE_SORT_APPEAR then
      sortFunction = function(a,b) return a.lastAppear < b.lastAppear end
    elseif sortType == BATTLE_SORT_DISTANCE then
      local localPlayer = g_game.getLocalPlayer()
      if localPlayer then
        local localPlayerPos = localPlayer:getPosition()
        sortFunction = function(a,b) return getDistanceTo(localPlayerPos, a.creature:getPosition()) < getDistanceTo(localPlayerPos, b.creature:getPosition()) end
      end
    elseif sortType == BATTLE_SORT_HEALTH then
      sortFunction = function(a,b) return a.creature:getHealthPercent() < b.creature:getHealthPercent() end
    elseif sortType == BATTLE_SORT_NAME then
      sortFunction = function(a,b) return a.creature:getName() < b.creature:getName() end
    end
  elseif sortOrder == BATTLE_ORDER_DESCENDING then
    if sortType == BATTLE_SORT_APPEAR then
      sortFunction = function(a,b) return a.lastAppear > b.lastAppear end
    elseif sortType == BATTLE_SORT_DISTANCE then
      local localPlayer = g_game.getLocalPlayer()
      if localPlayer then
        local localPlayerPos = localPlayer:getPosition()
        sortFunction = function(a,b) return getDistanceTo(localPlayerPos, a.creature:getPosition()) > getDistanceTo(localPlayerPos, b.creature:getPosition()) end
      end
    elseif sortType == BATTLE_SORT_HEALTH then
      sortFunction = function(a,b) return a.creature:getHealthPercent() > b.creature:getHealthPercent() end
    elseif sortType == BATTLE_SORT_NAME then
      sortFunction = function(a,b) return a.creature:getName() > b.creature:getName() end
    end
  end

  if sortFunction then
    table.sort(battleListByIndex, sortFunction)
  end
end

function updateBattleList()
  sortBattle()
  for i = 1, #battleListByIndex do
    battlePanel:moveChildToIndex(battleListByIndex[i], i)
  end
  filterBattleButtons()
end

function clearList()
  battleList        = {}
  battleListByIndex = {}
  battlePanel:destroyChildren()
end

function refreshList()
  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer then return end

  clearList()

  for _, creature in pairs(g_map.getSpectators(localPlayer:getPosition(), true)) do
    add(creature)
  end
end

function getBattleButtonIndex(cid)
  for k, battleButton in pairs(battleListByIndex) do
    if cid == battleButton.creature:getId() then
      return k
    end
  end
  return nil
end

function add(creature)
  local localPlayer = g_game.getLocalPlayer()
  if creature == localPlayer then return end

  local cid = creature:getId()
  local battleButton = battleList[cid]

  -- Register first time creature adding
  if not battleButton then
    battleButton = g_ui.createWidget('BattleButton')
    battleButton:setup(creature)

    battleButton.onHoverChange  = onBattleButtonHoverChange
    battleButton.onMouseRelease = onBattleButtonMouseRelease

    battleButton.lastAppear = os.time()

    battleList[cid] = battleButton
    table.insert(battleListByIndex, battleList[cid])

    if creature == g_game.getAttackingCreature() then
      onAttackingCreatureChange(creature)
    end
    if creature == g_game.getFollowingCreature() then
      onFollowingCreatureChange(creature)
    end

    battlePanel:addChild(battleButton)
    updateBattleList()
  end
end

function remove(creature)
  local cid   = creature:getId()
  local index = getBattleButtonIndex(cid)
  if index then
    if battleList[cid] then
      if battleList[cid] == lastBattleButtonSwitched then
        lastBattleButtonSwitched = nil
      end
      battleList[cid]:destroy()
      battleList[cid] = nil
    end
    table.remove(battleListByIndex, index)
  -- else
  --   print("Trying to remove invalid battleButton")
  end
end

function updateBattleButton(self)
  self:update()
  if self.isTarget or self.isFollowed then
    if lastBattleButtonSwitched and lastBattleButtonSwitched ~= self then
      lastBattleButtonSwitched.isTarget = false
      lastBattleButtonSwitched.isFollowed = false
      updateBattleButton(lastBattleButtonSwitched)
    end
    lastBattleButtonSwitched = self
  end
end

function updateBattleButtons()
  for _, battleButton in ipairs(battleListByIndex) do
    updateBattleButton(battleButton)
  end
end

function onBattleButtonHoverChange(self, hovered)
  if self.isBattleButton then
    self.isHovered = hovered
    updateBattleButton(self)
  end
end

function onBattleButtonMouseRelease(self, mousePosition, mouseButton)
  if mouseWidget.cancelNextRelease then
    mouseWidget.cancelNextRelease = false
    return false
  end
  if mouseButton == MouseLeftButton and g_keyboard.isCtrlPressed() and g_keyboard.isShiftPressed() then
    g_game.follow(self.creature)
  elseif g_mouse.isPressed(MouseLeftButton) and mouseButton == MouseRightButton or g_mouse.isPressed(MouseRightButton) and mouseButton == MouseLeftButton then
    mouseWidget.cancelNextRelease = true
    g_game.look(self.creature, true)
    return true
  elseif mouseButton == MouseLeftButton and g_keyboard.isShiftPressed() then
    g_game.look(self.creature, true)
    return true
  elseif mouseButton == MouseRightButton and not g_mouse.isPressed(MouseLeftButton) then
    modules.game_interface.createThingMenu(mousePosition, nil, nil, self.creature)
    return true
  elseif mouseButton == MouseLeftButton and not g_mouse.isPressed(MouseRightButton) then
    if self.isTarget then
      g_game.cancelAttack()
    else
      g_game.attack(self.creature)
    end
    return true
  end
  return false
end

function onAttackingCreatureChange(creature)
  local battleButton = creature and battleList[creature:getId()] or lastBattleButtonSwitched
  if battleButton then
    battleButton.isTarget = creature and true or false
    updateBattleButton(battleButton)
  end
end

function onFollowingCreatureChange(creature)
  local battleButton = creature and battleList[creature:getId()] or lastBattleButtonSwitched
  if battleButton then
    battleButton.isFollowed = creature and true or false
    updateBattleButton(battleButton)
  end
end

function updateStaticSquare()
  for _, battleButton in pairs(battleList) do
    if battleButton.isTarget then
      battleButton:update()
    end
  end
end

function onAppear(creature)
  if creature:isLocalPlayer() then
    addEvent(function()
      updateStaticSquare()
    end)
  end

  add(creature)
end

function onDisappear(creature)
  remove(creature)
end

function onPositionChange(creature, pos, oldPos)
  local posCheck = g_clock.millis()
  local diffTime = posCheck - lastPosCheck
  if getSortType() == BATTLE_SORT_DISTANCE and diffTime > BATTLE_POS_UPDATE_DELAY then
    updateBattleList()
    lastPosCheck = posCheck
  end
end

function onSkullChange(creature, skullId, oldSkull)
  local battleButton = battleList[creature:getId()]
  if battleButton then
    battleButton:updateSkull(skullId)
  end
end

function onEmblemChange(creature, emblemId)
  local battleButton = battleList[creature:getId()]
  if battleButton then
    battleButton:updateEmblem(emblemId)
  end
end

function onSpecialIconChange(creature, specialIconId)
  local battleButton = battleList[creature:getId()]
  if battleButton then
    battleButton:updateSpecialIcon(specialIconId)
  end
end

function onHealthPercentChange(creature, healthPercent)
  local battleButton = battleList[creature:getId()]
  if battleButton then
    battleButton:setLifeBarPercent(healthPercent)
  end
end

function onNicknameChange(creature, name)
  local battleButton = creature and battleList[creature:getId()] or lastBattleButtonSwitched
  if battleButton then
    remove(creature)
    addEvent(function()
      add(creature) -- Readd with the nickname or name
    end)
  end
end

outfitCreatureBox = nil





--healthInfoWindow = nil
healthBar = nil
manaBar = nil
experienceBar = nil
--soulLabel = nil
capLabel = nil





InventorySlotStyles = {
  [InventorySlotHead] = "HeadSlot",
  [InventorySlotNeck] = "NeckSlot",
  [InventorySlotBack] = "BackSlot",
  [InventorySlotBody] = "BodySlot",
  [InventorySlotRight] = "RightSlot",
  [InventorySlotLeft] = "LeftSlot",
  [InventorySlotLeg] = "LegSlot",
  [InventorySlotFeet] = "FeetSlot",
  [InventorySlotFinger] = "FingerSlot",
  [InventorySlotAmmo] = "AmmoSlot"
}

inventoryPanel = nil
inventoryButton = nil
inventoryWindow = nil
--purseButton = nil





-- Combat controls
--combatControlsButton = nil
--combatControlsWindow = nil
fightOffensiveBox = nil
fightBalancedBox = nil
fightDefensiveBox = nil
chaseModeButton = nil
safeFightButton = nil
mountButton = nil
-- whiteDoveBox = nil
-- whiteHandBox = nil
-- yellowHandBox = nil
-- redFistBox = nil
-- pvpModesPanel = nil
fightModeRadioGroup = nil
-- pvpModeRadioGroup = nil





function init()
  connect(LocalPlayer, {
    onChangeOutfit = onChangeOutfit,

    -- Health info
    onHealthChange = onHealthChange,
    onManaChange = onManaChange,
    onLevelChange = onLevelChange,
    --onSoulChange = onSoulChange,
    onFreeCapacityChange = onFreeCapacityChange,

    -- Inventory
    onInventoryChange = onInventoryChange,
    onBlessingsChange = onBlessingsChange,

    -- Combat controls
    onOutfitChange = onOutfitChange
  })

  connect(g_game, {
    -- Health info / Combat controls
    onGameEnd = offline,

    -- Inventory / Combat controls
    onGameStart = online,

    -- Combat controls
    onChaseModeChange = update,
    onSafeFightChange = update,
    onFightModeChange = update,
    -- onPVPModeChange   = update,
    onWalk = check,
    onAutoWalk = check
  })

  g_keyboard.bindKeyDown('Ctrl+I', toggle)

  inventoryButton = modules.client_topmenu.addRightGameToggleButton('inventoryButton', tr('Character') .. ' (Ctrl+I)', '/images/topbuttons/healthinfo', toggle)
  inventoryButton:setOn(true)

  inventoryWindow = g_ui.loadUI('character', modules.game_interface.getRightPanel())
  inventoryWindow:disableResize()

  if inventoryWindow:getSettings('minimized') then
    inventoryWindow:maximize(false)
  end
  showMoreInfo(true)
  inventoryWindow.onMinimize = function (self)
    local ballButton = inventoryWindow:recursiveGetChildById('ballButton')
    if ballButton then
      ballButton:setTooltip('Show more')
    end
  end
  inventoryWindow.onMaximize = function (self)
    local ballButton = inventoryWindow:recursiveGetChildById('ballButton')
    local headSlot = inventoryWindow:recursiveGetChildById('slot1')
    if ballButton and headSlot and headSlot:isVisible() then
      ballButton:setTooltip('Show less')
    end
  end

  outfitCreatureBox = inventoryWindow:recursiveGetChildById('outfitCreatureBox')

  -- Health info
  healthBar = inventoryWindow:recursiveGetChildById('healthBar')
  manaBar = inventoryWindow:recursiveGetChildById('manaBar')
  experienceBar = inventoryWindow:recursiveGetChildById('experienceBar')
  --soulLabel = inventoryWindow:recursiveGetChildById('soulLabel')
  capLabel = inventoryWindow:recursiveGetChildById('capLabel')
  inventoryPanel = inventoryWindow:getChildById('contentsPanel')

  -- Health info
  local localPlayer = g_game.getLocalPlayer()
  if localPlayer then
    onHealthChange(localPlayer, localPlayer:getHealth(), localPlayer:getMaxHealth())
    onManaChange(localPlayer, localPlayer:getMana(), localPlayer:getMaxMana())
    onLevelChange(localPlayer, localPlayer:getLevel(), localPlayer:getLevelPercent())
    --onSoulChange(localPlayer, localPlayer:getSoul())
    onFreeCapacityChange(localPlayer, localPlayer:getFreeCapacity())
  end

  -- Inventory
  -- purseButton = inventoryPanel:getChildById('purseButton')
  -- local function purseFunction()
  --   local purse = g_game.getLocalPlayer():getInventoryItem(InventorySlotPurse)
  --   if purse then
  --     g_game.use(purse)
  --   end
  -- end
  -- purseButton.onClick = purseFunction

  -- Combat controls
  fightOffensiveBox = inventoryWindow:recursiveGetChildById('fightOffensiveBox')
  fightBalancedBox = inventoryWindow:recursiveGetChildById('fightBalancedBox')
  fightDefensiveBox = inventoryWindow:recursiveGetChildById('fightDefensiveBox')

  -- Combat controls
  chaseModeButton = inventoryWindow:recursiveGetChildById('chaseModeBox')
  safeFightButton = inventoryWindow:recursiveGetChildById('safeFightBox')
  mountButton = inventoryWindow:recursiveGetChildById('mountButton')
  mountButton.onClick = onMountButtonClick

  -- Combat controls
  -- whiteDoveBox = inventoryWindow:recursiveGetChildById('whiteDoveBox')
  -- whiteHandBox = inventoryWindow:recursiveGetChildById('whiteHandBox')
  -- yellowHandBox = inventoryWindow:recursiveGetChildById('yellowHandBox')
  -- redFistBox = inventoryWindow:recursiveGetChildById('redFistBox')
  -- pvpModesPanel = inventoryWindow:recursiveGetChildById('pvpModesPanel')

  -- Combat controls
  fightModeRadioGroup = UIRadioGroup.create()
  fightModeRadioGroup:addWidget(fightOffensiveBox)
  fightModeRadioGroup:addWidget(fightBalancedBox)
  fightModeRadioGroup:addWidget(fightDefensiveBox)

  -- Combat controls
  -- pvpModeRadioGroup = UIRadioGroup.create()
  -- pvpModeRadioGroup:addWidget(whiteDoveBox)
  -- pvpModeRadioGroup:addWidget(whiteHandBox)
  -- pvpModeRadioGroup:addWidget(yellowHandBox)
  -- pvpModeRadioGroup:addWidget(redFistBox)

  -- Combat controls
  connect(chaseModeButton, { onCheckChange = onSetChaseMode })
  connect(safeFightButton, { onCheckChange = onSetSafeFight })
  connect(fightModeRadioGroup, { onSelectionChange = onSetFightMode })
  -- connect(pvpModeRadioGroup, { onSelectionChange = onSetPVPMode })

  online()
  if inventoryWindow then
    inventoryWindow:setup()
  end
end

function terminate()
  if g_game.isOnline() then
    offline() -- CHECK
  end

  -- Combat controls
  disconnect(chaseModeButton, { onCheckChange = onSetChaseMode })
  disconnect(safeFightButton, { onCheckChange = onSetSafeFight })
  disconnect(fightModeRadioGroup, { onSelectionChange = onSetFightMode })
  -- disconnect(pvpModeRadioGroup, { onSelectionChange = onSetPVPMode })

  disconnect(LocalPlayer, {
    -- Health info
    onHealthChange = onHealthChange,
    onManaChange = onManaChange,
    onLevelChange = onLevelChange,
    --onSoulChange = onSoulChange,
    onFreeCapacityChange = onFreeCapacityChange,

    -- Inventory
    onInventoryChange = onInventoryChange,
    onBlessingsChange = onBlessingsChange,

    -- Combat controls
    onOutfitChange = onOutfitChange
  })

  disconnect(g_game, {
    -- Health info / Combat controls
    onGameEnd = offline,

    -- Inventory / Combat controls
    onGameStart = online,

    -- Combat controls
    onChaseModeChange = update,
    onSafeFightChange = update,
    onFightModeChange = update,
    -- onPVPModeChange   = update,
    onWalk = check,
    onAutoWalk = check
  })

  g_keyboard.unbindKeyDown('Ctrl+I')

  -- Combat controls
  fightOffensiveBox:destroy()
  fightBalancedBox:destroy()
  fightDefensiveBox:destroy()
  chaseModeButton:destroy()
  safeFightButton:destroy()
  mountButton:destroy()
  fightModeRadioGroup:destroy()
  -- pvpModeRadioGroup:destroy()
  fightOffensiveBox = nil
  fightBalancedBox = nil
  fightDefensiveBox = nil
  chaseModeButton = nil
  safeFightButton = nil
  mountButton = nil
  fightModeRadioGroup = nil
  -- pvpModeRadioGroup = nil

  outfitCreatureBox:destroy()
  outfitCreatureBox = nil

  -- Health info
  healthBar:destroy()
  manaBar:destroy()
  experienceBar:destroy()
  --soulLabel:destroy()
  capLabel:destroy()
  healthBar = nil
  manaBar = nil
  experienceBar = nil
  --soulLabel = nil
  capLabel = nil

  inventoryPanel:destroy()
  inventoryPanel = nil
  inventoryButton:destroy()
  inventoryButton = nil
  inventoryWindow:destroy()
  inventoryWindow = nil

  -- Inventory
  -- purseButton = nil
end





-- Combat controls

function update()
  local chaseMode = g_game.getChaseMode()
  chaseModeButton:setChecked(chaseMode == ChaseOpponent)

  local safeFight = g_game.isSafeFight()
  safeFightButton:setChecked(not safeFight)

  local fightMode = g_game.getFightMode()
  if fightMode == FightOffensive then
    fightModeRadioGroup:selectWidget(fightOffensiveBox)
  elseif fightMode == FightBalanced then
    fightModeRadioGroup:selectWidget(fightBalancedBox)
  else
    fightModeRadioGroup:selectWidget(fightDefensiveBox)
  end

  -- if g_game.getFeature(GamePVPMode) then
  --   local pvpMode = g_game.getPVPMode()
  --   local pvpWidget = getPVPBoxByMode(pvpMode)
  --   if pvpWidget then
  --     pvpModeRadioGroup:selectWidget(pvpWidget)
  --   end
  -- end
end

function check()
  if modules.client_options.getOption('autoChaseOverride') then
    if g_game.isAttacking() and g_game.getChaseMode() == ChaseOpponent then
      g_game.setChaseMode(false, DontChase)
    end
  end
end

function onSetFightMode(self, selectedFightButton)
  if selectedFightButton == nil then return end
  local buttonId = selectedFightButton:getId()
  local fightMode
  if buttonId == 'fightOffensiveBox' then
    fightMode = FightOffensive
  elseif buttonId == 'fightBalancedBox' then
    fightMode = FightBalanced
  else
    fightMode = FightDefensive
  end
  g_game.setFightMode(false, fightMode)

  if g_game.isOnline() then
    scheduleEvent(function() if modules.game_battle then modules.game_battle.updateBattleButtons() end end, 1)
  end
end

function onSetChaseMode(self, checked)
  local chaseMode
  if checked then
    chaseMode = ChaseOpponent
  else
    chaseMode = DontChase
  end
  g_game.setChaseMode(false, chaseMode)
end

function onMountButtonClick(self, mousePos)
  local player = g_game.getLocalPlayer()
  if player then
    player:toggleMount()
  end
end

function onSetSafeFight(self, checked)
  g_game.setSafeFight(false, not checked)
end

function onSetPVPMode(self, selectedPVPButton)
  if selectedPVPButton == nil then
    return
  end

  local pvpMode = PVPWhiteDove
  -- local buttonId = selectedPVPButton:getId()
  -- if buttonId == 'whiteDoveBox' then
  --   pvpMode = PVPWhiteDove
  -- elseif buttonId == 'whiteHandBox' then
  --   pvpMode = PVPWhiteHand
  -- elseif buttonId == 'yellowHandBox' then
  --   pvpMode = PVPYellowHand
  -- elseif buttonId == 'redFistBox' then
  --   pvpMode = PVPRedFist
  -- end

  g_game.setPVPMode(false, pvpMode)
end

function onOutfitChange(localPlayer, outfit, oldOutfit)
  if outfit.mount == oldOutfit.mount then
    return
  end

  mountButton:setChecked(outfit.mount ~= nil and outfit.mount > 0)
end

-- function getPVPBoxByMode(mode)
--   local widget = nil
--   if mode == PVPWhiteDove then
--     widget = whiteDoveBox
--   elseif mode == PVPWhiteHand then
--     widget = whiteHandBox
--   elseif mode == PVPYellowHand then
--     widget = yellowHandBox
--   elseif mode == PVPRedFist then
--     widget = redFistBox
--   end
--   return widget
-- end





-- Inventory

function toggleAdventurerStyle(hasBlessing)
  for slot = InventorySlotFirst, InventorySlotLast do
    local itemWidget = inventoryPanel:getChildById('slot' .. slot)
    if itemWidget then
      itemWidget:setOn(hasBlessing)
    end
  end
end

function toggle()
  if inventoryButton:isOn() then
    inventoryWindow:close()
    inventoryButton:setOn(false)
  else
    inventoryWindow:open()
    inventoryButton:setOn(true)
  end
end

function onMiniWindowClose()
  inventoryButton:setOn(false)
end

-- hooked events
function onInventoryChange(player, slot, item, oldItem)
  if slot > InventorySlotAmmo then return end -- > InventorySlotPurse

  -- if slot == InventorySlotPurse then
  --   if g_game.getFeature(GamePurseSlot) then
  --     purseButton:setEnabled(item and true or false)
  --   end
  --   return
  -- end

  local itemWidget = inventoryPanel:getChildById('slot' .. slot)
  if item then
    itemWidget:setStyle('InventoryItem')
    itemWidget:setItem(item)
  else
    itemWidget:setStyle(InventorySlotStyles[slot])
    itemWidget:setItem(nil)
  end
end

function onBlessingsChange(player, blessings, oldBlessings)
  local hasAdventurerBlessing = Bit.hasBit(blessings, Blessings.Adventurer)
  if hasAdventurerBlessing ~= Bit.hasBit(oldBlessings, Blessings.Adventurer) then
    toggleAdventurerStyle(hasAdventurerBlessing)
  end
end





function updateOutfitCreatureBox(creature)
  outfitCreatureBox:setCreature(creature)
end

function onChangeOutfit(outfit)
  updateOutfitCreatureBox(g_game.getLocalPlayer())
end

function onHealthChange(localPlayer, health, maxHealth)
  healthBar:setValue(health, 0, maxHealth)
  healthBar:setText(health .. ' / ' .. maxHealth)
  healthBar:setTooltip(tr('Your character health is %d out of %d', health, maxHealth))
end

function onManaChange(localPlayer, mana, maxMana)
  manaBar:setValue(mana, 0, maxMana)
  manaBar:setText(mana .. ' / ' .. maxMana)
  manaBar:setTooltip(tr('Your character mana is %d out of %d', mana, maxMana))
end

function onLevelChange(localPlayer, value, percent)
  experienceBar:setPercent(percent)
  experienceBar:setText(percent .. '%')
  experienceBar:setTooltip(getExperienceTooltipText(localPlayer, value, percent))
end

function onSoulChange(localPlayer, soul)
  soulLabel:setText(tr('Soul') .. ': ' .. soul)
end

function onFreeCapacityChange(player, freeCapacity)
  capLabel:setText(string.format('%s: %.2f oz', tr('Cap'), freeCapacity))
end





function online()
  local player = g_game.getLocalPlayer()

  updateOutfitCreatureBox(player)



  -- Inventory

  for i = InventorySlotFirst, InventorySlotAmmo do -- , InventorySlotPurse
    if g_game.isOnline() then
      onInventoryChange(player, i, player:getInventoryItem(i))
    else
      onInventoryChange(player, i, nil)
    end
    toggleAdventurerStyle(player and Bit.hasBit(player:getBlessings(), Blessings.Adventurer) or false)
  end
  --purseButton:setVisible(g_game.getFeature(GamePurseSlot))



  -- Combat controls

  if player then
    local settings = modules.game_things.getPlayerSettings()
    local lastCombatControls = settings:getNode('lastCombatControls') or {}

    g_game.setChaseMode(true, lastCombatControls.chaseMode)
    g_game.setSafeFight(true, lastCombatControls.safeFight)
    g_game.setFightMode(true, lastCombatControls.fightMode)

    if lastCombatControls.pvpMode then
      g_game.setPVPMode(true, lastCombatControls.pvpMode)
    end

    if g_game.getFeature(GamePlayerMounts) then
      mountButton:setVisible(true)
      mountButton:setChecked(player:isMounted())
    else
      mountButton:setVisible(false)
    end

    -- if g_game.getFeature(GamePVPMode) then
    --   pvpModesPanel:setVisible(true)
    --   inventoryWindow:setHeight(inventoryWindow.extendedControlsHeight)
    -- else
    --   pvpModesPanel:setVisible(false)
    --   inventoryWindow:setHeight(inventoryWindow.simpleControlsHeight)
    -- end
  end
  update()
end

function offline()
  -- Combat controls

  local settings = modules.game_things.getPlayerSettings()
  local lastCombatControls = settings:getNode('lastCombatControls') or {}

  local player = g_game.getLocalPlayer()
  if player then
    lastCombatControls = {
      chaseMode = g_game.getChaseMode(),
      safeFight = g_game.isSafeFight(),
      fightMode = g_game.getFightMode()
    }

    if g_game.getFeature(GamePVPMode) then
      lastCombatControls.pvpMode = g_game.getPVPMode()
    end

    -- Save last combat control settings
    settings:setNode('lastCombatControls', lastCombatControls)
    settings:save()
  end
end

-- true = show more
-- false = show less
-- nil = default
function showMoreInfo(bool)
  if inventoryWindow:getSettings('minimized') then
    inventoryWindow:maximize(false)
    return
  end

  local headSlot = inventoryWindow:recursiveGetChildById('slot1')
  if not headSlot then return end

  local headSlot       = inventoryWindow:recursiveGetChildById('slot1')
  local bodySlot       = inventoryWindow:recursiveGetChildById('slot4')
  local legsSlot       = inventoryWindow:recursiveGetChildById('slot7')
  local feetSlot       = inventoryWindow:recursiveGetChildById('slot8')
  local neckSlot       = inventoryWindow:recursiveGetChildById('slot2')
  local leftSlot       = inventoryWindow:recursiveGetChildById('slot6')
  local fingerSlot     = inventoryWindow:recursiveGetChildById('slot9')
  local backSlot       = inventoryWindow:recursiveGetChildById('slot3')
  local rightSlot      = inventoryWindow:recursiveGetChildById('slot5')
  local ammoSlot       = inventoryWindow:recursiveGetChildById('slot10')
  local combatControls = inventoryWindow:recursiveGetChildById('combatControls')
  local ballButton     = inventoryWindow:recursiveGetChildById('ballButton')

  local hide = true
  if type(bool) == "boolean" then hide = bool else hide = not headSlot:isVisible() end

  if outfitCreatureBox then outfitCreatureBox:setVisible(hide) end
  if headSlot then          headSlot:setVisible(hide) end
  if bodySlot then          bodySlot:setVisible(hide) end
  if legsSlot then          legsSlot:setVisible(hide) end
  if feetSlot then          feetSlot:setVisible(hide) end
  if neckSlot then          neckSlot:setVisible(hide) end
  if leftSlot then          leftSlot:setVisible(hide) end
  if fingerSlot then        fingerSlot:setVisible(hide) end
  if backSlot then          backSlot:setVisible(hide) end
  if rightSlot then         rightSlot:setVisible(hide) end
  if ammoSlot then          ammoSlot:setVisible(hide) end
  if combatControls then    combatControls:setVisible(hide) end

  if hide then
    inventoryWindow:setHeight(264)
    if ballButton then ballButton:setTooltip('Show less') end
  else
    inventoryWindow:setHeight(94)
    if ballButton then ballButton:setTooltip('Show more') end
  end
end

function onMiniWindowBallButton()
  showMoreInfo()
end

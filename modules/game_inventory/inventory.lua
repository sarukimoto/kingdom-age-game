-- Health info

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

--healthInfoWindow = nil
healthBar = nil
manaBar = nil
experienceBar = nil
--soulLabel = nil
capLabel = nil
local healthTooltip = 'Your character health is %d out of %d.'
local manaTooltip = 'Your character mana is %d out of %d.'
local experienceTooltip = 'You have %d%% to advance to level %d.'





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
    -- Health info
    onHealthChange = onHealthChange,
    onManaChange = onManaChange,
    onLevelChange = onLevelChange,
    onStatesChange = onStatesChange,
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

  inventoryWindow = g_ui.loadUI('inventory', modules.game_interface.getRightPanel())
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

  -- Health info
  healthBar = inventoryWindow:recursiveGetChildById('healthBar')
  manaBar = inventoryWindow:recursiveGetChildById('manaBar')
  experienceBar = inventoryWindow:recursiveGetChildById('experienceBar')
  --soulLabel = inventoryWindow:recursiveGetChildById('soulLabel')
  capLabel = inventoryWindow:recursiveGetChildById('capLabel')
  inventoryPanel = inventoryWindow:getChildById('contentsPanel')

  -- Health info
  -- load condition icons
  for k,v in pairs(Icons) do
    g_textures.preload(v.path)
  end

  -- Health info
  if g_game.isOnline() then
    local localPlayer = g_game.getLocalPlayer()
    onHealthChange(localPlayer, localPlayer:getHealth(), localPlayer:getMaxHealth())
    onManaChange(localPlayer, localPlayer:getMana(), localPlayer:getMaxMana())
    onLevelChange(localPlayer, localPlayer:getLevel(), localPlayer:getLevelPercent())
    onStatesChange(localPlayer, localPlayer:getStates(), 0)
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
    onStatesChange = onStatesChange,
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
    scheduleEvent(function() modules.game_battle.checkCreatures() end, 1)
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





-- Health info

function toggleIcon(bitChanged)
  local content = inventoryWindow:recursiveGetChildById('conditionPanel')

  local icon = content:getChildById(Icons[bitChanged].id)
  if icon then
    icon:destroy()
  else
    icon = loadIcon(bitChanged)
    icon:setParent(content)
  end
end

function loadIcon(bitChanged)
  local icon = g_ui.createWidget('ConditionWidget', content)
  icon:setId(Icons[bitChanged].id)
  icon:setImageSource(Icons[bitChanged].path)
  icon:setTooltip(Icons[bitChanged].tooltip)
  return icon
end

function onHealthChange(localPlayer, health, maxHealth)
  healthBar:setText(health .. ' / ' .. maxHealth)
  healthBar:setTooltip(tr(healthTooltip, health, maxHealth))
  healthBar:setValue(health, 0, maxHealth)
end

function onManaChange(localPlayer, mana, maxMana)
  manaBar:setText(mana .. ' / ' .. maxMana)
  manaBar:setTooltip(tr(manaTooltip, mana, maxMana))
  manaBar:setValue(mana, 0, maxMana)
end

function onLevelChange(localPlayer, value, percent)
  experienceBar:setText(percent .. '%')
  experienceBar:setTooltip(tr(experienceTooltip, percent, value+1))
  experienceBar:setPercent(percent)
end

function onSoulChange(localPlayer, soul)
  soulLabel:setText(tr('Soul') .. ': ' .. soul)
end

function onFreeCapacityChange(player, freeCapacity)
  capLabel:setText(tr('Cap') .. ': ' .. freeCapacity)
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

function hideLabels() -- personalization function
  local removeHeight = math.max(capLabel:getMarginRect().height, soulLabel:getMarginRect().height)
  capLabel:setOn(false)
  soulLabel:setOn(false)
  inventoryWindow:setHeight(math.max(inventoryWindow.minimizedHeight, inventoryWindow:getHeight() - removeHeight))
end

function hideExperience() -- personalization function
  local removeHeight = experienceBar:getMarginRect().height
  experienceBar:setOn(false)
  inventoryWindow:setHeight(math.max(inventoryWindow.minimizedHeight, inventoryWindow:getHeight() - removeHeight))
end

function setHealthTooltip(tooltip)
  healthTooltip = tooltip

  local localPlayer = g_game.getLocalPlayer()
  if localPlayer then
    healthBar:setTooltip(tr(healthTooltip, localPlayer:getHealth(), localPlayer:getMaxHealth()))
  end
end

function setManaTooltip(tooltip)
  manaTooltip = tooltip

  local localPlayer = g_game.getLocalPlayer()
  if localPlayer then
    manaBar:setTooltip(tr(manaTooltip, localPlayer:getMana(), localPlayer:getMaxMana()))
  end
end

function setExperienceTooltip(tooltip)
  experienceTooltip = tooltip

  local localPlayer = g_game.getLocalPlayer()
  if localPlayer then
    experienceBar:setTooltip(tr(experienceTooltip, localPlayer:getLevelPercent(), localPlayer:getLevel()+1))
  end
end





function online()
  local player = g_game.getLocalPlayer()

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
    local char = g_game.getCharacterName()

    local lastCombatControls = g_settings.getNode('LastCombatControls')

    if not table.empty(lastCombatControls) then
      if lastCombatControls[char] then
        g_game.setChaseMode(true, lastCombatControls[char].chaseMode)
        g_game.setSafeFight(true, lastCombatControls[char].safeFight)
        g_game.setFightMode(true, lastCombatControls[char].fightMode)

        if lastCombatControls[char].pvpMode then
          g_game.setPVPMode(true, lastCombatControls[char].pvpMode)
        end
      end
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
  -- Health info

  inventoryWindow:recursiveGetChildById('conditionPanel'):destroyChildren()



  -- Combat controls

  local lastCombatControls = g_settings.getNode('LastCombatControls')
  if not lastCombatControls then
    lastCombatControls = {}
  end

  local player = g_game.getLocalPlayer()
  if player then
    local char = g_game.getCharacterName()
    lastCombatControls[char] = {
      chaseMode = g_game.getChaseMode(),
      safeFight = g_game.isSafeFight(),
      fightMode = g_game.getFightMode()
    }

    if g_game.getFeature(GamePVPMode) then
      lastCombatControls[char].pvpMode = g_game.getPVPMode()
    end

    -- save last combat control settings
    g_settings.setNode('LastCombatControls', lastCombatControls)
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
  local capLabel       = inventoryWindow:recursiveGetChildById('capLabel')
  local combatControls = inventoryWindow:recursiveGetChildById('combatControls')
  local ballButton     = inventoryWindow:recursiveGetChildById('ballButton')

  local hide = true
  if type(bool) == "boolean" then hide = bool else hide = not headSlot:isVisible() end

  if headSlot then       headSlot:setVisible(hide) end
  if bodySlot then       bodySlot:setVisible(hide) end
  if legsSlot then       legsSlot:setVisible(hide) end
  if feetSlot then       feetSlot:setVisible(hide) end
  if neckSlot then       neckSlot:setVisible(hide) end
  if leftSlot then       leftSlot:setVisible(hide) end
  if fingerSlot then     fingerSlot:setVisible(hide) end
  if backSlot then       backSlot:setVisible(hide) end
  if rightSlot then      rightSlot:setVisible(hide) end
  if ammoSlot then       ammoSlot:setVisible(hide) end
  if capLabel then       capLabel:setVisible(hide) end
  if combatControls then combatControls:setVisible(hide) end

  if hide then
    inventoryWindow:setHeight(261)
    if ballButton then ballButton:setTooltip('Show less') end
  else
    inventoryWindow:setHeight(100)
    if ballButton then ballButton:setTooltip('Show more') end
  end
end

function onMiniWindowBallButton()
  showMoreInfo()
end

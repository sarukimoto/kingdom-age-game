WALK_STEPS_RETRY = 10

gameRootPanel = nil
gameMapPanel = nil
gameRightPanel = nil
gameLeftPanel = nil
gameRightPanelBackground = nil
gameLeftPanelBackground = nil
gameBottomPanel = nil
logoutButton = nil
mouseGrabberWidget = nil
countWindow = nil
logoutWindow = nil
exitWindow = nil
bottomSplitter = nil
gameExpBar = nil
leftPanelButton = nil
rightPanelButton = nil
topMenuButton = nil
chatButton = nil
currentViewMode = 0
smartWalkDirs = {}
smartWalkDir = nil
walkFunction = nil
hookedMenuOptions = {}
lastDirTime = g_clock.millis()

function init()
  g_ui.importStyle('styles/countwindow')

  connect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd,
    onLoginAdvice = onLoginAdvice,
  }, true)

  -- Call load AFTER game window has been created and
  -- resized to a stable state, otherwise the saved
  -- settings can get overridden by false onGeometryChange
  -- events
  connect(g_app, {
    onRun = load,
    onExit = save
  })

  gameRootPanel = g_ui.displayUI('interface')
  gameRootPanel:hide()
  gameRootPanel:lower()
  gameRootPanel.onGeometryChange = updateStretchShrink
  gameRootPanel.onFocusChange = stopSmartWalk

  mouseGrabberWidget = gameRootPanel:getChildById('mouseGrabber')
  mouseGrabberWidget.onMouseRelease = onMouseGrabberRelease

  bottomSplitter = gameRootPanel:getChildById('bottomSplitter')
  gameExpBar = gameRootPanel:getChildById('gameExpBar')
  leftPanelButton = gameRootPanel:getChildById('leftPanelButton')
  rightPanelButton = gameRootPanel:getChildById('rightPanelButton')
  topMenuButton = gameRootPanel:getChildById('topMenuButton')
  chatButton = gameRootPanel:getChildById('chatButton')
  gameMapPanel = gameRootPanel:getChildById('gameMapPanel')
  gameRightPanel = gameRootPanel:getChildById('gameRightPanel')
  gameLeftPanel = gameRootPanel:getChildById('gameLeftPanel')
  gameRightPanelBackground = gameRootPanel:getChildById('gameRightPanelBackground')
  gameLeftPanelBackground = gameRootPanel:getChildById('gameLeftPanelBackground')
  gameBottomPanel = gameRootPanel:getChildById('gameBottomPanel')

  -- connect(gameLeftPanel, { onVisibilityChange = onLeftPanelVisibilityChange })

  logoutButton = modules.client_topmenu.addLeftButton('logoutButton', tr('Exit'),
    '/images/topbuttons/logout', tryLogout, true)

  setupViewMode(0)

  bindKeys()

  if g_game.isOnline() then
    show()
  end
end

function bindKeys()
  gameRootPanel:setAutoRepeatDelay(200)

  bindWalkKey('Up', North)
  bindWalkKey('Right', East)
  bindWalkKey('Down', South)
  bindWalkKey('Left', West)
  bindWalkKey('Numpad8', North)
  bindWalkKey('Numpad9', NorthEast)
  bindWalkKey('Numpad6', East)
  bindWalkKey('Numpad3', SouthEast)
  bindWalkKey('Numpad2', South)
  bindWalkKey('Numpad1', SouthWest)
  bindWalkKey('Numpad4', West)
  bindWalkKey('Numpad7', NorthWest)

  bindTurnKey('Ctrl+Up', North)
  bindTurnKey('Ctrl+Left', West)
  bindTurnKey('Ctrl+Down', South)
  bindTurnKey('Ctrl+Right', East)
  bindTurnKey('Ctrl+Numpad8', North)
  bindTurnKey('Ctrl+Numpad4', West)
  bindTurnKey('Ctrl+Numpad2', South)
  bindTurnKey('Ctrl+Numpad6', East)
  g_keyboard.bindKeyPress('Escape', function() g_game.cancelAttackAndFollow() end, gameRootPanel)
  g_keyboard.bindKeyPress('Ctrl+=', function() gameMapPanel:zoomIn() modules.client_options.setOption('gameScreenSize', gameMapPanel:getZoom(), false) end, gameRootPanel)
  g_keyboard.bindKeyPress('Ctrl+-', function() gameMapPanel:zoomOut() modules.client_options.setOption('gameScreenSize', gameMapPanel:getZoom(), false) end, gameRootPanel)
  g_keyboard.bindKeyDown('Ctrl+L', function() tryLogout(false) end, gameRootPanel)
  --g_keyboard.bindKeyDown('Ctrl+W', function() g_map.cleanTexts() local mod = modules.game_textmessage if not mod then return end mod.clearMessages() end, gameRootPanel)
  g_keyboard.bindKeyDown('Ctrl+.', nextViewMode, gameRootPanel)
end

function bindWalkKey(key, dir)
  g_keyboard.bindKeyDown(key, function() changeWalkDir(dir) end, gameRootPanel, true)
  g_keyboard.bindKeyUp(key, function() changeWalkDir(dir, true) end, gameRootPanel, true)
  g_keyboard.bindKeyPress(key, function() smartWalk(dir) end, gameRootPanel)
end

function unbindWalkKey(key)
  g_keyboard.unbindKeyDown(key, gameRootPanel)
  g_keyboard.unbindKeyUp(key, gameRootPanel)
  g_keyboard.unbindKeyPress(key, gameRootPanel)
end

function bindTurnKey(key, dir)
  local function callback(widget, code, repeatTicks)
    if g_clock.millis() - lastDirTime >= modules.client_options.getOption('turnDelay') then
      g_game.turn(dir)
      changeWalkDir(dir)
      lastDirTime = g_clock.millis()
    end
  end
  g_keyboard.bindKeyPress(key, callback, gameRootPanel)
end

function terminate()
  hide()

  hookedMenuOptions = {}

  stopSmartWalk()

  disconnect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd,
    onLoginAdvice = onLoginAdvice
  })

  -- disconnect(gameLeftPanel, { onVisibilityChange = onLeftPanelVisibilityChange })

  logoutButton:destroy()
  gameRootPanel:destroy()
end

function onGameStart()
  local localPlayer = g_game.getLocalPlayer()
  g_window.setTitle(g_app.getName() .. (localPlayer and " - " .. localPlayer:getName() or ""))

  show()

  -- Panels Stickers
  modules.client_options.updateStickers()

  -- open tibia has delay in auto walking
  if not g_game.isOfficialTibia() then
    g_game.enableFeature(GameForceFirstAutoWalkStep)
  else
    g_game.disableFeature(GameForceFirstAutoWalkStep)
  end
end

function onGameEnd()
  g_window.setTitle(g_app.getName())

  setupViewMode(0)
  hide()
end

function show()
  connect(g_app, { onClose = tryExit })
  modules.client_background.hide()
  gameRootPanel:show()
  gameRootPanel:focus()
  gameMapPanel:followCreature(g_game.getLocalPlayer())
  setupViewMode(0)
  updateStretchShrink()
  logoutButton:setTooltip(tr('Logout'))

  addEvent(function()
    gameMapPanel:setMaxZoomOut(19) -- Default: 11
    gameMapPanel:setLimitVisibleRange(true)
  end)
end

function hide()
  disconnect(g_app, { onClose = tryExit })
  logoutButton:setTooltip(tr('Exit'))

  if logoutWindow then
    logoutWindow:destroy()
    logoutWindow = nil
  end
  if exitWindow then
    exitWindow:destroy()
    exitWindow = nil
  end
  if countWindow then
    countWindow:destroy()
    countWindow = nil
  end
  gameRootPanel:hide()
  modules.client_background.show()
end

function save()
  local settings = {}
  settings.splitterMarginBottom = bottomSplitter:getMarginBottom()
  g_settings.setNode('game_interface', settings)
end

function load()
  local settings = g_settings.getNode('game_interface')
  if settings then
    if settings.splitterMarginBottom then
      bottomSplitter:setMarginBottom(settings.splitterMarginBottom)
    end
  end
end

function onLoginAdvice(message)
  displayInfoBox(tr("For Your Information"), message)
end

function forceExit()
  g_game.cancelLogin()
  scheduleEvent(exit, 10)
  return true
end

function tryExit()
  if exitWindow then
    return true
  end

  local exitFunc = function() g_game.safeLogout() forceExit() end
  local logoutFunc = function() g_game.safeLogout() exitWindow:destroy() exitWindow = nil end
  local cancelFunc = function() exitWindow:destroy() exitWindow = nil end

  exitWindow = displayGeneralBox(tr('Exit'), tr("If you shut down the program, your character might stay in the game.\nClick on 'Logout' to ensure that you character leaves the game properly.\nClick on 'Exit' if you want to exit the program without logging out your character."),
  { { text=tr('Force Exit'), callback=exitFunc },
    { text=tr('Logout'), callback=logoutFunc },
    { text=tr('Cancel'), callback=cancelFunc },
    anchor=AnchorHorizontalCenter }, logoutFunc, cancelFunc, 100)

  return true
end

function tryLogout(prompt)
  if type(prompt) ~= "boolean" then
    prompt = true
  end
  if not g_game.isOnline() then
    exit()
    return
  end

  if logoutWindow then
    return
  end

  local msg, yesCallback
  if not g_game.isConnectionOk() then
    msg = tr('Your connection is failing. If you logout now, your\ncharacter will be still online. Do you want to\nforce logout?')

    yesCallback = function()
      g_game.forceLogout()
      if logoutWindow then
        logoutWindow:destroy()
        logoutWindow=nil
        logoutButton:setOn(false)
      end
    end
  else
    msg = tr('Are you sure you want to logout?')

    yesCallback = function()
      g_game.safeLogout()
      if logoutWindow then
        logoutWindow:destroy()
        logoutWindow=nil
        logoutButton:setOn(false)
      end
    end
  end

  local noCallback = function()
    logoutWindow:destroy()
    logoutWindow=nil
    logoutButton:setOn(false)
  end

  if prompt then
    logoutWindow = displayGeneralBox(tr('Logout'), msg, {
      { text=tr('Yes'), callback=yesCallback },
      { text=tr('No'), callback=noCallback },
      anchor=AnchorHorizontalCenter}, yesCallback, noCallback)
    logoutButton:setOn(true)
  else
     yesCallback()
  end
end

function stopSmartWalk()
  smartWalkDirs = {}
  smartWalkDir = nil
end

function changeWalkDir(dir, pop)
  while table.removevalue(smartWalkDirs, dir) do end
  if pop then
    if #smartWalkDirs == 0 then
      stopSmartWalk()
      return
    end
  else
    table.insert(smartWalkDirs, 1, dir)
  end

  smartWalkDir = smartWalkDirs[1]
  if modules.client_options.getOption('smartWalk') and #smartWalkDirs > 1 then
    for _,d in pairs(smartWalkDirs) do
      if (smartWalkDir == North and d == West) or (smartWalkDir == West and d == North) then
        smartWalkDir = NorthWest
        break
      elseif (smartWalkDir == North and d == East) or (smartWalkDir == East and d == North) then
        smartWalkDir = NorthEast
        break
      elseif (smartWalkDir == South and d == West) or (smartWalkDir == West and d == South) then
        smartWalkDir = SouthWest
        break
      elseif (smartWalkDir == South and d == East) or (smartWalkDir == East and d == South) then
        smartWalkDir = SouthEast
        break
      end
    end
  end
end

function smartWalk(dir)
  if g_keyboard.getModifiers() == KeyboardNoModifier then
    local func = walkFunction
    if not func then
      local dire = smartWalkDir or dir
      if modules.client_options.getOption('smoothWalk') then
        local sensitivity = modules.client_options.getOption('walkingSensitivityScrollBar')
        g_game.smoothWalk(dire, sensitivity)
      else
        g_game.walk(dire)
      end
    end
    return true
  end
  return false
end

function setWalkingRepeatDelay(value)
   gameRootPanel:setAutoRepeatDelay(value)
end

function updateStretchShrink()
  if modules.client_options.getOption('dontStretchShrink') and not alternativeView then
    gameMapPanel:setVisibleDimension({ width = 15, height = 11 })

    -- Set gameMapPanel size to height = 11 * 32 + 2
    bottomSplitter:setMarginBottom(bottomSplitter:getMarginBottom() + (gameMapPanel:getHeight() - 32 * 11) - 10)
  end
end

function addToPanels(uiWidget)
  uiWidget.onRemoveFromContainer = function(widget)
    if gameLeftPanel:isOn() then
      if widget:getParent():getId() == 'gameRightPanel' then
        if gameLeftPanel:getEmptySpaceHeight() - widget:getHeight() >= 0 then
          widget:setParent(gameLeftPanel)
        end
      elseif widget:getParent():getId() == 'gameLeftPanel' then
        if gameRightPanel:getEmptySpaceHeight() - widget:getHeight() >= 0 then
          widget:setParent(gameRightPanel)
        end
      end
    end
  end
  if not gameLeftPanel:isOn() then uiWidget:setParent(gameRightPanel) return end
  if gameRightPanel:getEmptySpaceHeight() - uiWidget:getHeight() >= 0 then
    uiWidget:setParent(gameRightPanel)
  else
    uiWidget:setParent(gameLeftPanel)
  end
end

function onMouseGrabberRelease(self, mousePosition, mouseButton)
  if selectedThing == nil then return false end

  if mouseButton == MouseLeftButton then
    local clickedWidget = gameRootPanel:recursiveGetChildByPos(mousePosition, false)
    if clickedWidget then
      if selectedType == 'use' then
        onUseWith(clickedWidget, mousePosition)
      elseif selectedType == 'trade' then
        onTradeWith(clickedWidget, mousePosition)
      end
    end
  end

  selectedThing = nil
  g_mouse.popCursor('target')
  self:ungrabMouse()
  return true
end

function onUseWith(clickedWidget, mousePosition)
  if clickedWidget:getClassName() == 'UIGameMap' then
    local tile = clickedWidget:getTile(mousePosition)
    if tile then
      if selectedThing:isFluidContainer() or selectedThing:isMultiUse() then
        g_game.useWith(selectedThing, tile:getTopMultiUseThing())
      else
        g_game.useWith(selectedThing, tile:getTopUseThing())
      end
    end
  elseif clickedWidget:getClassName() == 'UIItem' and not clickedWidget:isVirtual() then
    g_game.useWith(selectedThing, clickedWidget:getItem())
  elseif clickedWidget:getClassName() == 'UICreatureButton' then
    local creature = clickedWidget:getCreature()
    if creature and not creature:isPlayer() then
      -- Make possible to use with on UICreatureButton (battle window)
      g_game.useWith(selectedThing, creature)
    end
  end
end

function onTradeWith(clickedWidget, mousePosition)
  if clickedWidget:getClassName() == 'UIGameMap' then
    local tile = clickedWidget:getTile(mousePosition)
    if tile then
      g_game.requestTrade(selectedThing, tile:getTopCreature())
    end
  elseif clickedWidget:getClassName() == 'UICreatureButton' then
    local creature = clickedWidget:getCreature()
    if creature then
      g_game.requestTrade(selectedThing, creature)
    end
  end
end

function startUseWith(thing)
  if not thing then return end
  if g_ui.isMouseGrabbed() then
    if selectedThing then
      selectedThing = thing
      selectedType = 'use'
    end
    return
  end
  selectedType = 'use'
  selectedThing = thing
  mouseGrabberWidget:grabMouse()
  g_mouse.pushCursor('target')
end

function startTradeWith(thing)
  if not thing then return end
  if g_ui.isMouseGrabbed() then
    if selectedThing then
      selectedThing = thing
      selectedType = 'trade'
    end
    return
  end
  selectedType = 'trade'
  selectedThing = thing
  mouseGrabberWidget:grabMouse()
  g_mouse.pushCursor('target')
end

function isMenuHookCategoryEmpty(category)
  if category then
    for _,opt in pairs(category) do
      if opt then return false end
    end
  end
  return true
end

function addMenuHook(category, name, callback, condition, shortcut)
  if not hookedMenuOptions[category] then
    hookedMenuOptions[category] = {}
  end
  hookedMenuOptions[category][name] = {
    callback = callback,
    condition = condition,
    shortcut = shortcut
  }
end

function removeMenuHook(category, name)
  if not name then
    hookedMenuOptions[category] = {}
  else
    hookedMenuOptions[category][name] = nil
  end
end

function createThingMenu(menuPosition, lookThing, useThing, creatureThing)
  if not g_game.isOnline() then return end

  local menu = g_ui.createWidget('PopupMenu')
  menu:setGameMenu(true)

  local classic = modules.client_options.getOption('classicControl')
  local shortcut = nil

  if not classic then shortcut = '(Shift)' else shortcut = nil end
  if lookThing then
    menu:addOption(tr('Look'), function() g_game.look(lookThing) end, shortcut)
  end

  if not classic then shortcut = '(Ctrl)' else shortcut = nil end
  if useThing then
    if useThing:isContainer() then
      if useThing:getParentContainer() then
        menu:addOption(tr('Open'), function() g_game.open(useThing, useThing:getParentContainer()) end, shortcut)
        menu:addOption(tr('Open in new window'), function() g_game.open(useThing) end)
      else
        menu:addOption(tr('Open'), function() g_game.open(useThing) end, shortcut)
      end
    else
      if useThing:isMultiUse() then
        menu:addOption(tr('Use with') .. ' ...', function() startUseWith(useThing) end, shortcut)
      else
        menu:addOption(tr('Use'), function() g_game.use(useThing) end, shortcut)
      end
    end

    if useThing:isRotateable() then
      menu:addOption(tr('Rotate'), function() g_game.rotate(useThing) end)
    end

    if g_game.getFeature(GameBrowseField) and useThing:getPosition().x ~= 0xffff then
      menu:addOption(tr('Browse field'), function() g_game.browseField(useThing:getPosition()) end)
    end
  end

  if lookThing and not lookThing:isCreature() and not lookThing:isNotMoveable() and lookThing:isPickupable() then
    menu:addSeparator()
    menu:addOption(tr('Trade with') .. ' ...', function() startTradeWith(lookThing) end)
  end

  if lookThing then
    local parentContainer = lookThing:getParentContainer()
    if parentContainer and parentContainer:hasParent() then
      menu:addOption(tr('Move up'), function() g_game.moveToParentContainer(lookThing, lookThing:getCount()) end)
    end
  end

  if creatureThing then
    local localPlayer = g_game.getLocalPlayer()
    local creatureName = creatureThing:getName()
    menu:addSeparator()

    if creatureThing:isLocalPlayer() then
      menu:addOption(tr('Set outfit'), function() g_game.requestOutfit() end)

      if g_game.getFeature(GamePlayerMounts) then
        if not localPlayer:isMounted() then
          menu:addOption(tr('Mount'), function() localPlayer:mount() end)
        else
          menu:addOption(tr('Dismount'), function() localPlayer:dismount() end)
        end
      end

      if creatureThing:isPartyMember() then
        if creatureThing:isPartyLeader() then
          if creatureThing:isPartySharedExperienceActive() then
            menu:addOption(tr('Disable shared XP'), function() g_game.partyShareExperience(false) end)
          else
            menu:addOption(tr('Enable shared XP'), function() g_game.partyShareExperience(true) end)
          end
        end
        menu:addOption(tr('Leave party'), function() g_game.partyLeave() end)
      end

      if g_game.getAccountType() >= ACCOUNT_TYPE_GAMEMASTER then
        menu:addSeparator()

        menu:addOption(tr('View rule violations'), function() local mod = modules.game_ruleviolation if not mod then return end mod.showViewWindow() end)
        menu:addOption(tr('View bugs'), function() local mod = modules.game_bugreport if not mod then return end mod.showViewWindow() end)
      end

    else
      local localPosition = localPlayer:getPosition()
      if creatureThing:getPosition().z == localPosition.z then
        if not classic then shortcut = '(Alt)' else shortcut = nil end
        if g_game.getAttackingCreature() ~= creatureThing then
          menu:addOption(tr('Attack'), function() g_game.attack(creatureThing) end, shortcut)
        else
          menu:addOption(tr('Stop attack'), function() g_game.cancelAttack() end, shortcut)
        end

        if not classic then shortcut = '(Ctrl+Shift)' else shortcut = nil end
        if g_game.getFollowingCreature() ~= creatureThing then
          menu:addOption(tr('Follow'), function() g_game.follow(creatureThing) end, shortcut)
        else
          menu:addOption(tr('Stop follow'), function() g_game.cancelFollow() end, shortcut)
        end
      end

      if creatureThing:isPlayer() then
        menu:addSeparator()

        menu:addOption(tr('Message to') .. ' ' .. creatureName, function() g_game.openPrivateChannel(creatureName) end)

        local mod = modules.game_console
        if mod then
          if mod.getOwnPrivateTab() then
            menu:addOption(tr('Invite to private chat'), function() g_game.inviteToOwnChannel(creatureName) end)
            menu:addOption(tr('Exclude from private chat'), function() g_game.excludeFromOwnChannel(creatureName) end) -- [TODO] must be removed after message's popup labels been implemented
          end
        end
        if not localPlayer:hasVip(creatureName) then
          menu:addOption(tr('Add to VIP list'), function() g_game.addVip(creatureName) end)
        end

        if mod then
          if mod.isIgnored(creatureName) then
            menu:addOption(tr('Unignore') .. ' ' .. creatureName, function() mod.removeIgnoredPlayer(creatureName) end)
          else
            menu:addOption(tr('Ignore') .. ' ' .. creatureName, function() mod.addIgnoredPlayer(creatureName) end)
          end
        end

        local localPlayerShield = localPlayer:getShield()
        local creatureShield = creatureThing:getShield()

        if localPlayerShield == ShieldNone or localPlayerShield == ShieldWhiteBlue then
          if creatureShield == ShieldWhiteYellow then
            menu:addOption(tr('Join %s\'s party', creatureThing:getName()), function() g_game.partyJoin(creatureThing:getId()) end)
          else
            menu:addOption(tr('Invite to party'), function() g_game.partyInvite(creatureThing:getId()) end)
          end
        elseif localPlayerShield == ShieldWhiteYellow then
          if creatureShield == ShieldWhiteBlue then
            menu:addOption(tr('Revoke %s\'s invitation', creatureThing:getName()), function() g_game.partyRevokeInvitation(creatureThing:getId()) end)
          end
        elseif localPlayerShield == ShieldYellow or localPlayerShield == ShieldYellowSharedExp or localPlayerShield == ShieldYellowNoSharedExpBlink or localPlayerShield == ShieldYellowNoSharedExp then
          if creatureShield == ShieldWhiteBlue then
            menu:addOption(tr('Revoke %s\'s invitation', creatureThing:getName()), function() g_game.partyRevokeInvitation(creatureThing:getId()) end)
          elseif creatureShield == ShieldBlue or creatureShield == ShieldBlueSharedExp or creatureShield == ShieldBlueNoSharedExpBlink or creatureShield == ShieldBlueNoSharedExp then
            menu:addOption(tr('Pass leadership to %s', creatureThing:getName()), function() g_game.partyPassLeadership(creatureThing:getId()) end)
          else
            menu:addOption(tr('Invite to party'), function() g_game.partyInvite(creatureThing:getId()) end)
          end
        end

        if localPlayer ~= creatureThing then
          menu:addSeparator()

          local mod = modules.game_ruleviolation
          if mod then
            if g_game.getAccountType() >= ACCOUNT_TYPE_GAMEMASTER then
              menu:addOption(tr('Add rule violation'), function() mod.showViewWindow(creatureName) end)
            end

            local REPORT_TYPE_NAME      = 0
            local REPORT_TYPE_VIOLATION = 2
            menu:addOption(tr('Report name'), function() mod.showRuleViolationReportWindow(REPORT_TYPE_NAME, creatureName) end)
            menu:addOption(tr('Report violation'), function() mod.showRuleViolationReportWindow(REPORT_TYPE_VIOLATION, creatureName) end)
          end
        end
      end
    end

    menu:addSeparator()

    menu:addOption(tr('Copy name'), function() g_window.setClipboardText(creatureName) end)
  end

  -- hooked menu options
  for _,category in pairs(hookedMenuOptions) do
    if not isMenuHookCategoryEmpty(category) then
      menu:addSeparator()
      for name,opt in pairs(category) do
        if opt and opt.condition(menuPosition, lookThing, useThing, creatureThing) then
          menu:addOption(name, function() opt.callback(menuPosition,
            lookThing, useThing, creatureThing) end, opt.shortcut)
        end
      end
    end
  end

  menu:display(menuPosition)
end

local function getDistanceBetween(p1, p2)
  return math.max(math.abs(p1.x - p2.x), math.abs(p1.y - p2.y))
end

function processMouseAction(menuPosition, mouseButton, autoWalkPos, lookThing, useThing, creatureThing, attackCreature)
  local player = g_game.getLocalPlayer()
  local keyboardModifiers = g_keyboard.getModifiers()
  local isMouseBothPressed = g_mouse.isPressed(MouseLeftButton) and mouseButton == MouseRightButton or g_mouse.isPressed(MouseRightButton) and mouseButton == MouseLeftButton

  if not modules.client_options.getOption('classicControl') then
    if keyboardModifiers == KeyboardNoModifier and mouseButton == MouseRightButton and not g_mouse.isPressed(MouseLeftButton) then
      createThingMenu(menuPosition, lookThing, useThing, creatureThing)
      return true
    elseif creatureThing and getDistanceBetween(creatureThing:getPosition(), player:getPosition()) >= 1 and (creatureThing:getPosition().z == autoWalkPos.z and g_keyboard.isCtrlPressed() and g_keyboard.isShiftPressed() and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) or not creatureThing:isMonster() and isMouseBothPressed) then
      g_game.follow(creatureThing)
      return true
    elseif attackCreature and getDistanceBetween(attackCreature:getPosition(), player:getPosition()) >= 1 and (g_keyboard.isAltPressed() and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) or attackCreature:isMonster() and isMouseBothPressed) then
      g_game.attack(attackCreature)
      return true
    elseif creatureThing and getDistanceBetween(creatureThing:getPosition(), player:getPosition()) >= 1 and (creatureThing:getPosition().z == autoWalkPos.z and g_keyboard.isAltPressed() and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) or creatureThing:isMonster() and isMouseBothPressed) then
      g_game.attack(creatureThing)
      return true
    elseif useThing and ((keyboardModifiers == KeyboardCtrlModifier or keyboardModifiers == KeyboardAltModifier) and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) or isMouseBothPressed) then
      if keyboardModifiers == KeyboardCtrlModifier or isMouseBothPressed then
        if useThing:isContainer() then
          g_game.open(useThing, useThing:getParentContainer() and not isMouseBothPressed and useThing:getParentContainer() or nil)
          return true
        elseif useThing:isMultiUse() then
          startUseWith(useThing)
          return true
        end
      end
      g_game.use(useThing)
      return true
    elseif lookThing and keyboardModifiers == KeyboardShiftModifier and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
      g_game.look(lookThing)
      return true
    end

  -- Classic control
  else
    if useThing and (keyboardModifiers == KeyboardNoModifier or keyboardModifiers == KeyboardAltModifier) and mouseButton == MouseRightButton and not g_mouse.isPressed(MouseLeftButton) then
      if keyboardModifiers == KeyboardNoModifier then
        if attackCreature and attackCreature ~= player then
          g_game.attack(attackCreature)
          return true
        elseif creatureThing and creatureThing ~= player and creatureThing:getPosition().z == autoWalkPos.z then
          g_game.attack(creatureThing)
          return true
        elseif useThing:isContainer() then
          g_game.open(useThing, useThing:getParentContainer() and useThing:getParentContainer() or nil)
          return true
        elseif useThing:isMultiUse() then
          startUseWith(useThing)
          return true
        end
      end
      g_game.use(useThing)
      return true
    elseif lookThing and keyboardModifiers == KeyboardShiftModifier and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
      g_game.look(lookThing)
      return true
    elseif lookThing and ((g_mouse.isPressed(MouseLeftButton) and mouseButton == MouseRightButton) or (g_mouse.isPressed(MouseRightButton) and mouseButton == MouseLeftButton)) then
      g_game.look(lookThing)
      return true
    elseif useThing and keyboardModifiers == KeyboardCtrlModifier and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
      createThingMenu(menuPosition, lookThing, useThing, creatureThing)
      return true
    elseif attackCreature and g_keyboard.isAltPressed() and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
      g_game.attack(attackCreature)
      return true
    elseif creatureThing and creatureThing:getPosition().z == autoWalkPos.z and g_keyboard.isAltPressed() and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
      g_game.attack(creatureThing)
      return true
    end
  end


  local player = g_game.getLocalPlayer()
  player:stopAutoWalk()

  if autoWalkPos and keyboardModifiers == KeyboardNoModifier and mouseButton == MouseLeftButton then
    player:autoWalk(autoWalkPos)
    return true
  end

  return false
end

function moveStackableItem(item, toPos)
  if countWindow then
    return
  end
  if g_keyboard.isCtrlPressed() then
    g_game.move(item, toPos, item:getCount())
    return
  elseif g_keyboard.isShiftPressed() then
    g_game.move(item, toPos, 1)
    return
  end
  local count = item:getCount()

  countWindow = g_ui.createWidget('CountWindow', rootWidget)
  local itembox = countWindow:getChildById('item')
  local scrollbar = countWindow:getChildById('countScrollBar')
  itembox:setItemId(item:getId())
  itembox:setItemCount(count)
  scrollbar:setMaximum(count)
  scrollbar:setMinimum(1)
  scrollbar:setValue(count)

  local spinbox = countWindow:getChildById('spinBox')
  spinbox:setMaximum(count)
  spinbox:setMinimum(0)
  spinbox:setValue(0)
  spinbox:hideButtons()
  spinbox:focus()
  spinbox.firstEdit = true

  local spinBoxValueChange = function(self, value)
    spinbox.firstEdit = false
    scrollbar:setValue(value)
  end
  spinbox.onValueChange = spinBoxValueChange

  local check = function()
    if spinbox.firstEdit then
      spinbox:setValue(spinbox:getMaximum())
      spinbox.firstEdit = false
    end
  end
  g_keyboard.bindKeyPress("Up", function() check() spinbox:up() end, spinbox)
  g_keyboard.bindKeyPress("Down", function() check() spinbox:down() end, spinbox)
  g_keyboard.bindKeyPress("Right", function() check() spinbox:up() end, spinbox)
  g_keyboard.bindKeyPress("Left", function() check() spinbox:down() end, spinbox)
  g_keyboard.bindKeyPress("PageUp", function() check() spinbox:setValue(spinbox:getValue()+10) end, spinbox)
  g_keyboard.bindKeyPress("PageDown", function() check() spinbox:setValue(spinbox:getValue()-10) end, spinbox)

  scrollbar.onValueChange = function(self, value)
    itembox:setItemCount(value)
    spinbox.onValueChange = nil
    spinbox:setValue(value)
    spinbox.onValueChange = spinBoxValueChange
  end

  scrollbar.onClick =
  function()
    local mousePos = g_window.getMousePosition()
    local slider = scrollbar:getChildById('sliderButton')
    check()
    if slider:getPosition().x > mousePos.x then
      spinbox:setValue(spinbox:getValue()-10)
    elseif slider:getPosition().x < mousePos.x then
      spinbox:setValue(spinbox:getValue()+10)
    end
  end

  local okButton = countWindow:getChildById('buttonOk')
  local moveFunc = function()
    g_game.move(item, toPos, itembox:getItemCount())
    okButton:getParent():destroy()
    countWindow = nil
  end
  local cancelButton = countWindow:getChildById('buttonCancel')
  local cancelFunc = function()
    cancelButton:getParent():destroy()
    countWindow = nil
  end

  countWindow.onEnter = moveFunc
  countWindow.onEscape = cancelFunc

  okButton.onClick = moveFunc
  cancelButton.onClick = cancelFunc
end

function getRootPanel()
  return gameRootPanel
end

function getMapPanel()
  return gameMapPanel
end

function getRightPanel()
  return gameRightPanel
end

function getLeftPanel()
  return gameLeftPanel
end

function gameRightPanelBackground()
  return gameRightPanelBackground
end

function gameLeftPanelBackground()
  return gameLeftPanelBackground
end

function getBottomPanel()
  return gameBottomPanel
end

function getSplitter()
  return bottomSplitter
end

function getGameExpBar()
  return gameExpBar
end

function getLeftPanelButton()
  return leftPanelButton
end

function getRightPanelButton()
  return rightPanelButton
end

function getTopMenuButton()
  return topMenuButton
end

function getChatButton()
  return chatButton
end

-- function onLeftPanelVisibilityChange(leftPanel, visible)
--   if not visible and g_game.isOnline() then
--     local children = leftPanel:getChildren()
--     for i=1,#children do
--       children[i]:setParent(gameRightPanel)
--     end
--   end
-- end

function nextViewMode()
  setupViewMode((currentViewMode + 1) % 3)
end

local visibleDimension = { width = 25, height = 19 }
function setupViewMode(mode)
  if mode == currentViewMode then return end

  local topMenu = modules.client_topmenu.getTopMenu()

  -- Previous mode as 2
  if currentViewMode == 2 then
    gameMapPanel:addAnchor(AnchorLeft, 'gameLeftPanel', AnchorRight)
    gameMapPanel:addAnchor(AnchorRight, 'gameRightPanel', AnchorLeft)
    gameMapPanel:addAnchor(AnchorBottom, 'gameBottomPanel', AnchorTop)
    gameRootPanel:addAnchor(AnchorTop, 'topMenu', AnchorBottom)
    gameLeftPanel:setOn(modules.client_options.getOption('showLeftPanel'))
    gameRightPanelBackground:setImageColor('white')
    gameLeftPanelBackground:setImageColor('white')
    gameLeftPanel:setMarginTop(0)
    gameRightPanel:setMarginTop(0)
    topMenuButton:setMarginTop(10)
    gameBottomPanel:setImageColor('white')
    topMenu:setImageColor('white')
  end

  g_game.changeMapAwareRange(18, 14)

  -- New mode
  local gameScreenSize = modules.client_options.getOption('gameScreenSize')
  if mode == 0 then
    gameMapPanel:setKeepAspectRatio(true)
    gameMapPanel:setLimitVisibleRange(false)
    gameMapPanel:setZoom(gameScreenSize)
    gameMapPanel:setVisibleDimension(visibleDimension)
  elseif mode == 1 then
    gameMapPanel:setKeepAspectRatio(false)
    gameMapPanel:setLimitVisibleRange(true)
    gameMapPanel:setZoom(gameScreenSize)
    gameMapPanel:setVisibleDimension(visibleDimension)
  elseif mode == 2 then
    gameMapPanel:setLimitVisibleRange(true)
    gameMapPanel:setZoom(gameScreenSize)
    gameMapPanel:setVisibleDimension(visibleDimension)
    gameMapPanel:fill('parent')
    gameRootPanel:fill('parent')
    gameRightPanelBackground:setImageColor('#ffffff88')
    gameLeftPanelBackground:setImageColor('#ffffff88')

    local isTopMenuVisible = topMenu and topMenu:getMarginTop() >= 0 or false
    gameLeftPanel:setMarginTop(isTopMenuVisible and topMenu:getHeight() - gameLeftPanel:getPaddingTop() or 0)
    gameRightPanel:setMarginTop(isTopMenuVisible and topMenu:getHeight() - gameRightPanel:getPaddingTop() or 0)
    topMenuButton:setMarginTop((isTopMenuVisible and topMenu:getHeight() - gameRightPanel:getPaddingTop() or 0) + 10)
    gameLeftPanel:setVisible(true)
    -- gameMapPanel:setOn(true)
    gameBottomPanel:setImageColor('#ffffff88')
    topMenu:setImageColor('#ffffff66')
  end

  gameMapPanel:changeViewMode(mode, currentViewMode)

  currentViewMode = mode
end

function getCurrentViewMode()
  return currentViewMode
end

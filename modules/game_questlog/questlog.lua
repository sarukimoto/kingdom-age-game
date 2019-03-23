questLogButton = nil
questLineWindow = nil

-- For avoid multiple teleport confirm windows
local questLogTeleportLock = false
function getTeleportLock()     return questLogTeleportLock end
function setTeleportLock(lock) questLogTeleportLock = lock end

function init()
  g_ui.importStyle('questlogwindow')
  g_ui.importStyle('questlinewindow')

  questLogButton = modules.client_topmenu.addRightGameToggleButton('questLogButton', tr('Quest Log') .. ' (Ctrl+Q)', '/images/topbuttons/questlog', toggle)

  connect(g_game, { onGameEnd = destroyWindows })
  ProtocolGame.registerExtendedOpcode(GameServerExtOpcodes.GameServerQuestLog, parseQuestLog)
  g_keyboard.bindKeyDown('Ctrl+Q', toggle)
end

function terminate()
  g_keyboard.unbindKeyDown('Ctrl+Q')
  ProtocolGame.unregisterExtendedOpcode(GameServerExtOpcodes.GameServerQuestLog)
  disconnect(g_game, { onGameEnd = destroyWindows })

  destroyWindows()
  questLogButton:destroy()
end

function destroyWindows()
  if questLogWindow then
    questLogWindow:destroy()
  end

  if questLineWindow then
    questLineWindow:destroy()
  end
end

function show()
  if not g_game.canPerformGameAction() then return end
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedOpcode(ClientExtOpcodes.ClientQuestLog, '')
    questLogButton:setOn(true)
  end
end

function hide()
  destroyWindows()
  questLogButton:setOn(false)
end

function toggle()
  if not questLogWindow or not questLogWindow:isVisible() then show() else hide() end
end

function sendTeleportRequest(questId, missionId)
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedOpcode(ClientExtOpcodes.ClientAction, string.format('%i:%i:%i', ClientActions.QuestTeleports, questId, missionId))
    return true
  end
  return false
end

function sendShowItemsRequest(questId, missionId)
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedOpcode(ClientExtOpcodes.ClientAction, string.format('%i:%i:%i', ClientActions.QuestItems, questId, missionId))
    return true
  end
  return false
end

function onRowUpdate(child)
  if child then
    if not child.isComplete and not child.canDo then
      child:setBackgroundColor('#ff000020')
    end
    child.mainDataLabel:setColor(child:isFocused() and '#ffffff' or '#333b43')
  end
end

function updateLayout(window, questId, missionId, row)
  if not window then
    return
  end
  local teleportButton             = window:getChildById('teleportButton')
  local rewardsLabel               = window:getChildById('rewardsLabel')
  local rewardExperienceLabel      = window:getChildById('rewardExperienceLabel')
  local rewardExperienceValueLabel = window:getChildById('rewardExperienceValueLabel')
  local rewardMoneyLabel           = window:getChildById('rewardMoneyLabel')
  local rewardMoneyValueLabel      = window:getChildById('rewardMoneyValueLabel')
  local itemsButton                = window:getChildById('itemsButton')
  local otherRewards               = window:getChildById('otherRewards')
  local otherRewardsScrollBar      = window:getChildById('otherRewardsScrollBar')
  local rowsList                   = row.parent

  if row.hasTeleport then
    teleportButton:setVisible(true)

    teleportButton.onClick = function()
      if not getTeleportLock() then
        displayCustomBox('Quest Teleport', 'Are you sure that you want to teleport?', {{ text = 'Yes', buttonCallback = function() sendTeleportRequest(questId, missionId) local mod = modules.game_questlog if not mod then return end mod.setTeleportLock(false) end }}, 1, 'No', function() local mod = modules.game_questlog if not mod then return end mod.setTeleportLock(false) end, nil)
        setTeleportLock(true)
      end
    end
  else
    teleportButton:setVisible(false)
  end

  if row.experience >= 1 then
    rewardExperienceLabel:setVisible(true)
    rewardExperienceValueLabel:setVisible(true)
    rewardExperienceValueLabel:setText(tr('%d XP', row.experience))
  else
    rewardExperienceLabel:setVisible(false)
    rewardExperienceValueLabel:setVisible(false)
  end

  if row.money >= 1 then
    rewardMoneyLabel:setVisible(true)
    rewardMoneyValueLabel:setVisible(true)
    rewardMoneyValueLabel:setText(tr('%d GPs', row.money))
  else
    rewardMoneyLabel:setVisible(false)
    rewardMoneyValueLabel:setVisible(false)
  end

  if row.showItems then
    itemsButton:setVisible(true)
    itemsButton.onClick = function()
      sendShowItemsRequest(questId, missionId)
    end
  else
    itemsButton:setVisible(false)
  end

  if row.otherRewards and row.otherRewards ~= "" then
    otherRewards:setVisible(true)
    otherRewards:setText(row.otherRewards)
    otherRewardsScrollBar:setVisible(true)
  else
    otherRewards:setVisible(false)
    otherRewardsScrollBar:setVisible(false)
  end

  rewardsLabel:setVisible(rewardExperienceValueLabel:isVisible() or rewardMoneyValueLabel:isVisible() or itemsButton:isVisible() or otherRewards:isVisible())

  if rowsList and rowsList:hasChildren() then
    local children = rowsList:getChildren()
    if #children >= 1 then
      for i = 1, #children do
        onRowUpdate(children[i])
      end
    end
  end
end

function parseQuestLog(protocol, opcode, buffer)
  local params = buffer:split(':::')
  local mode = tonumber(params[1])
  if not mode then return end

  if mode == 1 then -- Quest Log
    local quests = {}

    for _, _quest in ipairs(params[2] and params[2]:split(';;') or {}) do
      local quest = {}
      local data = _quest:split("::")
      quest.id = tonumber(data[1])
      if not quest.id then return end
      quest.isComplete   = tonumber(data[2]) == 1 and true or false
      quest.canDo        = tonumber(data[3]) == 1 and true or false
      quest.logName      = data[4]
      quest.categoryName = data[5]
      quest.minLevel     = tonumber(data[6]) or 1
      quest.hasTeleport  = tonumber(data[7]) == 1 and true or false
      quest.experience   = tonumber(data[8]) or 0
      quest.money        = tonumber(data[9]) or 0
      quest.showItems    = tonumber(data[10]) == 1 and true or false
      quest.otherRewards = data[11]
      quest.otherRewards = quest.otherRewards ~= '-' and quest.otherRewards or ''
      table.insert(quests, quest)
    end
    onGameQuestLog(quests)

  elseif mode == 2 then -- Quest Line
    local missions = {}
    local questId = tonumber(params[2])
    if not questId then return end

    for _, _mission in ipairs(params[3] and params[3]:split(';;') or {}) do
      local mission = {}
      local data = _mission:split('::')
      mission.id = tonumber(data[1])
      if mission.id then
        mission.isComplete   = tonumber(data[2]) == 1 and true or false
        mission.canDo        = tonumber(data[3]) == 1 and true or false
        mission.logName      = data[4]
        mission.minLevel     = tonumber(data[5]) or 1
        mission.description  = data[6]
        mission.hasTeleport  = tonumber(data[7]) == 1 and true or false
        mission.experience   = tonumber(data[8]) or 0
        mission.money        = tonumber(data[9]) or 0
        mission.showItems    = tonumber(data[10]) == 1 and true or false
        mission.otherRewards = data[11]
        mission.otherRewards = mission.otherRewards ~= '-' and mission.otherRewards or ''
        table.insert(missions, mission)
      end
    end
    onGameQuestLine(questId, missions)
  end
end

function onGameQuestLog(quests)
  destroyWindows()

  questLogWindow = g_ui.createWidget('QuestLogWindow', rootWidget)
  local questList = questLogWindow:getChildById('questList')

  connect(questList, { onChildFocusChange = function(self, focusedChild)
    if focusedChild == nil then return end
    updateLayout(questLogWindow, focusedChild.questId, 0, focusedChild)
  end })

  for _, quest in ipairs(quests) do
    local questLabel = g_ui.createWidget('QuestLabel', questList)
    questLabel.parent = questList
    questLabel.questId = quest.id
    questLabel.isComplete = quest.isComplete
    questLabel:setOn(quest.isComplete)
    questLabel.canDo = quest.canDo
    questLabel.logName = quest.logName
    questLabel.categoryName = quest.categoryName
    questLabel.minLevel = quest.minLevel
    questLabel:setText(quest.logName)
    questLabel.hasTeleport = quest.hasTeleport
    questLabel.experience = quest.experience
    questLabel.money = quest.money
    questLabel.showItems = quest.showItems
    questLabel.otherRewards = quest.otherRewards

    local questMainDataLabel = g_ui.createWidget('QuestDataLabel', questLabel)
    questMainDataLabel:addAnchor(AnchorRight, 'parent', AnchorRight)
    questMainDataLabel:setText('[' .. quest.categoryName .. ']'  .. (quest.minLevel > 1 and ' [Lv ' .. quest.minLevel .. ']' or ''))
    questLabel.mainDataLabel = questMainDataLabel

    onRowUpdate(questLabel)
    questLabel.onDoubleClick =
    function()
      if not g_game.canPerformGameAction() then return end
      local protocolGame = g_game.getProtocolGame()
      if protocolGame then
        questLogWindow:hide()
        protocolGame:sendExtendedOpcode(ClientExtOpcodes.ClientQuestLog, string.format('%d', quest.id))
      end
    end

  end

  questLogWindow.onDestroy = function()
    questLogWindow = nil
  end

  --questList:focusChild(questList:getFirstChild())
end

function onGameQuestLine(questId, missions)
  if questLogWindow then questLogWindow:hide() end
  if questLineWindow then questLineWindow:destroy() end

  questLineWindow = g_ui.createWidget('QuestLineWindow', rootWidget)
  local missionList = questLineWindow:getChildById('missionList')
  local missionDescription = questLineWindow:getChildById('missionDescription')

  connect(missionList, { onChildFocusChange = function(self, focusedChild)
    if focusedChild == nil then return end
    missionDescription:setText(focusedChild.description)
    updateLayout(questLineWindow, questId, focusedChild.missionId, focusedChild)
  end })

  for _, mission in pairs(missions) do
    local missionLabel = g_ui.createWidget('MissionLabel')
    missionLabel.parent = missionList
    missionLabel.missionId = mission.id
    missionLabel.isComplete = mission.isComplete
    missionLabel:setOn(mission.isComplete)
    missionLabel.canDo = mission.canDo
    missionLabel.logName = mission.logName
    missionLabel.minLevel = mission.minLevel
    missionLabel:setText(mission.logName)
    missionLabel.description = mission.description
    missionLabel.hasTeleport = mission.hasTeleport
    missionLabel.experience = mission.experience
    missionLabel.money = mission.money
    missionLabel.showItems = mission.showItems
    missionLabel.otherRewards = mission.otherRewards

    local missionMainDataLabel = g_ui.createWidget('MissionDataLabel', missionLabel)
    missionMainDataLabel:addAnchor(AnchorRight, 'parent', AnchorRight)
    missionMainDataLabel:setText((mission.minLevel > 1 and '[Lv ' .. mission.minLevel .. ']' or ''))
    missionLabel.mainDataLabel = missionMainDataLabel

    onRowUpdate(missionLabel)
    missionList:addChild(missionLabel)
  end

  questLineWindow.onDestroy =
  function()
    if questLogWindow then questLogWindow:show() end
    questLineWindow = nil
  end

  --missionList:focusChild(missionList:getFirstChild())
end

function questLogWindowFocus()
  if questLogWindow then
    questLogWindow:focus()
  end
end

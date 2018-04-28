local minimumCommentSize = 50
local textPattern        = "[^%w%s!?%+-*/=@%(%)%[%]%{%}.,]+" -- Find symbols that are NOT letters, numbers, spaces and !?+-*/=@()[]{}.,



local REPORT_MODE_NEWREPORT    = 0
local REPORT_MODE_UPDATESEARCH = 1
local REPORT_MODE_UPDATESTATE  = 2
local REPORT_MODE_REMOVEROW    = 3
local REPORT_MODE_ACTION       = 4

local REPORT_TYPE_ALL       = 255
local REPORT_TYPE_NAME      = 0
local REPORT_TYPE_STATEMENT = 1
local REPORT_TYPE_VIOLATION = 2
local REPORT_TYPE_NOTATIONS = 3

local function sendNewReport(_type, targetName, reasonId, comment, statement, translation)
  if not statement or statement == '' then statement = '-' end
  statement = statement:gsub(':', ';') -- Replace all ':' with ';' for avoid errors on opcodes
  if not translation or translation == '' then translation = '-' end
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedOpcode(ClientOpcodes.ClientRuleViolation, string.format("%d:%d:%s:%d:%s:%s:%s", REPORT_MODE_NEWREPORT, _type, targetName, reasonId, comment:trim(), statement:trim(), translation:trim()))
  end
end

local function sendUpdateSearch(_type, reasonId, page, rowsPerPage, state)
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedOpcode(ClientOpcodes.ClientRuleViolation, string.format("%d:%d:%d:%d:%d:%d", REPORT_MODE_UPDATESEARCH, _type, reasonId, page, rowsPerPage, state))
  end
end

local function sendUpdateState(row, state) -- (row[, state])
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedOpcode(ClientOpcodes.ClientRuleViolation, string.format("%d:%d:%d", REPORT_MODE_UPDATESTATE, state or row.state, row.id))
  end
end

local function sendRemoveRow(row)
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedOpcode(ClientOpcodes.ClientRuleViolation, string.format("%d:%d", REPORT_MODE_REMOVEROW, row.id))
  end
end

local function sendAddAction(_type, targetName, reasonId, comment, actionId, days, row)
  if comment == '' then comment = '-' end
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedOpcode(ClientOpcodes.ClientRuleViolation, string.format("%d:%d:%s:%d:%s:%d:%d:%d", REPORT_MODE_ACTION, _type, targetName, reasonId, comment:trim(), actionId, days, row and row.id or 0))
  end
end



rvWindow                 = nil
rvLabel                  = nil
targetTextEdit           = nil
statementTextEdit        = nil
translationTextEdit      = nil
typeComboBox             = nil
reasonMultilineTextEdit  = nil
commentMultilineTextEdit = nil
okButton                 = nil
cancelButton             = nil



local types =
{
  [REPORT_TYPE_ALL]       = 'All',
  [REPORT_TYPE_NAME]      = 'Name',
  [REPORT_TYPE_STATEMENT] = 'Statement',
  [REPORT_TYPE_VIOLATION] = 'Violation'
}

local typeId = REPORT_TYPE_NAME

local reasons = -- Titles should have until 255 characters.
{
  [REPORT_TYPE_NAME] =
  {
    [0]  = { title = "Offensive - Racism",                                       description = "Reflect prejudice, or hatred against people from other races or other countries.\n\nExamples:\n\nIllegal - You can report names like:\nJew hater, White Power, Niggerkiller, Stupid Polak\n\nLegal - Names like the following are legal and must not be reported:\nPolish Warrior, Tiago de Brasilia, Black Fighter" },
    [1]  = { title = "Offensive - Harassing",                                    description = "Made to harass other players or to threaten other players in real life.\n\nExamples:\n\nIllegal - You can report names like:\nIkillyou Reallife, Wheelchair Marcin\n\nLegal - Names like the following are legal and must not be reported:\nTomurka's friend, Bubble Two" },
    [2]  = { title = "Offensive - Insulting",                                    description = "Contain very rude and offensive vocabulary or created to insult other character names.\n\nExamples:\n\nIllegal - You can report names like:\nStupid Retard, Katie the Moron, Dickhead\n\nLegal - Names like the following are legal and must not be reported:\nNoob, Crazy Guy, Silly Gerta" },
    [3]  = { title = "Offensive - Drug related",                                 description = "Explicitly relate to drugs and other illegal substances or to well-known drug dealers.\nThe same is true for names that refer to alcoholism.\n\nExamples:\n\nIllegal - You can report names like:\nJunkie, Weedsmoker, Pablo Escobar, Alcoholic\n\nLegal - Names like the following are legal and must not be reported:\nWater pipe, Tobacco Man, Rum bottle, Drunk Dwarf" },
    [4]  = { title = "Offensive - Sexually related",                             description = "Refer to sex, a sexual orientation or intimate body parts.\nAlso, names of well-known prostitutes or porn stars may be reported.\n\nExamples:\n\nIllegal - You can report names like:\nSixty-nine, Hetero Guy, Nipple, Breastfeeder\n\nLegal - Names like the following are legal and must not be reported:\nSweet Kiss, Macho, Long Legs" },
    [5]  = { title = "Offensive - Religious or political view",                  description = "Refer to a specific religion or to a person or position that is connected to a certain religion.\nThe same is true for names that express political views or refer to contemporary and well-known politicians.\n\nExamples:\n\nIllegal - You can report names like:\nHindu Master, Jesus Christ, Pope Frank, Anarchist, Dilma\n\nLegal - Names like the following are legal and must not be reported:\nJesus Gonzales, Elfish Priest, God of War, Satan, Abraham Lincoln" },
    [6]  = { title = "Offensive - Generally objectionable",                      description = "Distasteful and likely to offend people.\n\nFor example, references to body fluids, excrements, serious diseases or organised crime.\nAlso, names of contemporary persons known for serious crimes or inhuman actions.\n\nExamples:\n\nIllegal - You can report names like:\nSnot, Moe the Mongolist, Mafia Hitman, Hitler\n\nLegal - Names like the following are legal and must not be reported:\nVial of Blood, Blind beggar, Genghis Khan" },
    [7]  = { title = "Offensive - Supporting rule violation",                    description = "Support a rule break, encourage others to break a Kingdom Age Rule.\n Or imply a violation of the Kingdom Age Rules.\nThe same is true for names that have been created to fake an official position.\n\nExamples:\n\nIllegal - You can report names like:\nSellacc, Spam Sponsor, Bothater, God Durin, System Admin, Senator Kate\n\nLegal - Names like the following are legal and must not be reported:\nEvil Thief, Bad Guy, Steve Johnson, God of War, Count Stephan" },
    [8]  = { title = "Advertising - Brand, product or service of a third party", description = "Contain advertising for worldwide known products, services or companies including titles of other online games.\n\nExamples:\n\nIllegal - You can report names like:\nNike Shoes, Siemens, Frank Google, World of Warcraft\n\nLegal - Names like the following are legal and must not be reported:\nJennifer Lopez, Real Madrid, Chrono, Zelda, Megaman" },
    [9]  = { title = "Advertising - Content which is not related to the game",   description = "Contain advertising for content which is not related to the game.\n\nExamples:\n\nIllegal - You can report names like:\nMobile Sale, Buy headset, Sell My Car\n\nLegal - Names like the following are legal and must not be reported:\nMerchant, Potionbuyer" },
    [10] = { title = "Other - Name violation",                                   description = "Other violation." },
  },

  [REPORT_TYPE_STATEMENT] =
  {
    [0]  = { title = "Spam - Public statements ignoring the default language",      description = "Consist of a bad usage of channel sending messages that is not in the default required.\n\nFor example, the help channel requires only english statements." },
    [1]  = { title = "Spam - Statements not related to the channel subject",        description = "Consist of a bad usage with no related statement to the channel within.\n\nFor example, do not post trade messages in the help channel." },
    [2]  = { title = "Spam - Using badly formatted or nonsensical text",            description = "Consist of nonsensical letter combinations.\n\nFor example, \"asdfsdfskhjkh...\" or \"-*-*-*-*I $eLl @rr0wzz*-*-*-*-...\"." },
    [3]  = { title = "Spam - Excessively repeating similar statements",             description = "Consist of annoying flood excessively repeating similar statements several times for a longer period of time." },
    [4]  = { title = "Offensive - Racism",                                          description = "Made to insult a certain country or its inhabitants, a certain nation or an ethnic group." },
    [5]  = { title = "Offensive - Harassing",                                       description = "Made to harass other players or to threaten other players in real life." },
    [6]  = { title = "Offensive - Insulting",                                       description = "Insulting or contain very offensive vocabulary.\nKeep in mind that harmless words like \"noob\" might annoy you, but are tolerated and should not be reported." },
    [7]  = { title = "Offensive - Drug related",                                    description = "Refer to drugs in any way." },
    [8]  = { title = "Offensive - Sexually related",                                description = "Contain references to sex, sexual related body parts or a sexual orientation." },
    [9]  = { title = "Offensive - Religious or political view",                     description = "Deal with controversial topics like religion and politics." },
    [10] = { title = "Offensive - Generally objectionable",                         description = "Grossly distasteful.\n\nFor example, cynical remarks about catastrophes." },
    [11] = { title = "Offensive - Supporting rule violation",                       description = "Support a rule break, encourage others to break a Kingdom Age Rule.\nOr imply a violation of the Kingdom Age Rules by the posting player." },
    [12] = { title = "Advertising - Brand, product or service of a third party",    description = "Made to advertise certain goods, services or brands of a third party.\n\nFor example, advertising other games, offering items from another game for Kingdom Age items.\nAlso, advertising other companies or their goods and services is illegal." },
    [13] = { title = "Advertising - Content which is not related to the game",      description = "Contain advertising for all kind of goods and services that are not related to Kingdom Age.\n\nFor example, \"sell my car\"." },
    [14] = { title = "Advertising - Disclosing personal data of other people",      description = "Contain personal data of other people.\n\nFor example, email address or phone number." },
    [15] = { title = "Team - False information to Vision Entertainment",            description = "Prove that a player has intentionally given wrong or misleading information,\nconcerning rule violation reports, complaints, bug reports or support requests to Vision Entertainment." },
    [16] = { title = "Team - Publishing wrong info about Vision Entertainment",     description = "Made to publish clearly wrong information about Vision Entertainment or its services." },
    [17] = { title = "Team - Boycott against Vision Entertainment or its services", description = "Made to ask other players to boycott Vision Entertainment or its services." },
    [18] = { title = "Team - Pretending to be Vision Entertainment",                description = "Made to make other players believe that a player is a Vision Entertainment member or has their powers or legitimation." },
    [19] = { title = "Other - Statement violation",                                 description = "Other violation." },
  },

  [REPORT_TYPE_VIOLATION] =
  {
    [0] = { title = "Abuse - Bug abuse on the game",                              description = "Abused an game bug." },
    [1] = { title = "Abuse - Error abuse on the Vision Entertainment's services", description = "Abused an any part of Vision Entertainment's service." },
    [2] = { title = "Hacking - Using unofficial software to play",                description = "Used unofficial software.\n\nFor example, a macro program or a so-called tasker or bot." },
    [3] = { title = "Hacking - Stealing other players' account or personal data", description = "Tried to steal another player's account data or to hack an account.\nOr tried to trick other players into downloading malicious software." },
    [4] = { title = "Hacking - Manipulating the official client program",         description = "Manipulating the client program to try gaining an advantage compared to other players." },
    [5] = { title = "Hacking - Attacking a Vision Entertainment service",         description = "Has or wants to attack, disrupt or damage the operation of Vision Entertainment servers,\nthe game or any other part of Vision Entertainment's service." },
    [6] = { title = "Law/Regulations - Violating the game Service Agreement",     description = "Violated the Kingdom Age Service Agreement or planned to be violated." },
    [7] = { title = "Law/Regulations - Violating a right of a third party",       description = "Violated the right of a third party or planned to be violated." },
    [8] = { title = "Law/Regulations - Violating applicable law",                 description = "Violated any applicable law or planned to be violated." },
    [9] = { title = "Other - Violation",                                          description = "Other violation." },
  }
}

local reasonId = 0



function init()
  ProtocolGame.registerExtendedOpcode(GameServerOpcodes.GameServerRuleViolation, parseRuleViolationsReports) -- View List
end

function terminate()
  ProtocolGame.unregisterExtendedOpcode(GameServerOpcodes.GameServerRuleViolation) -- View List

  destroyRuleViolationReportWindow()
  destroyRVViewWindow()
end

function showRuleViolationReportWindow(_type, targetName, statement)
  if not g_game.isOnline() then
    return
  end
  typeId = _type

  g_ui.importStyle('ruleviolation')
  rvWindow                 = g_ui.createWidget('RVWindow', rootWidget)
  rvLabel                  = rvWindow:getChildById('rvLabel')
  targetTextEdit           = rvWindow:getChildById('targetTextEdit')
  statementTextEdit        = rvWindow:getChildById('statementTextEdit')
  translationTextEdit      = rvWindow:getChildById('translationTextEdit')
  typeComboBox             = rvWindow:getChildById('typeComboBox')
  reasonMultilineTextEdit  = rvWindow:getChildById('reasonMultilineTextEdit')
  commentMultilineTextEdit = rvWindow:getChildById('commentMultilineTextEdit')
  okButton                 = rvWindow:getChildById('okButton')
  cancelButton             = rvWindow:getChildById('cancelButton')

  rvWindow:setText('Report ' .. types[typeId])

  if targetName then
    targetTextEdit:setText(targetName)
  end

  if statement then
    statementTextEdit:setText(statement)
  end

  typeComboBox.onOptionChange = onChangeReasonId
  if reasons[typeId] then
    for reasonId = 0, #reasons[typeId] do
      local reason = reasons[typeId][reasonId]
      typeComboBox:addOption(reason.title)
    end
  end

  -- Only REPORT_TYPE_STATEMENT has fields statement and translation
  if typeId ~= REPORT_TYPE_STATEMENT then
    local statementLabel   = rvWindow:getChildById('statementLabel')
    local translationLabel = rvWindow:getChildById('translationLabel')

    statementLabel:destroy()
    statementTextEdit:destroy()
    translationLabel:destroy()
    translationTextEdit:destroy()
    statementLabel      = nil
    statementTextEdit   = nil
    translationLabel    = nil
    translationTextEdit = nil
  end

  rvWindow:show()
  rvWindow:raise()
  if translationTextEdit then
    translationTextEdit:focus()
  else
    commentMultilineTextEdit:focus()
  end
end

function destroyRuleViolationReportWindow()
  if rvWindow then
    rvWindow:destroy()
  end

  rvWindow                 = nil
  rvLabel                  = nil
  targetTextEdit           = nil
  statementTextEdit        = nil
  translationTextEdit      = nil
  typeComboBox             = nil
  reasonMultilineTextEdit  = nil
  commentMultilineTextEdit = nil
  okButton                 = nil
  cancelButton             = nil
end



function onChangeReasonId(comboBox, option)
  if not reasons[typeId] then
    return
  end

  if option then
    for _reasonId = 0, #reasons[typeId] do
      local reason = reasons[typeId][_reasonId]
      if option == reason.title then
        reasonId = _reasonId
        break
      end
    end
  end

  reasonMultilineTextEdit:setText(typeId and reasonId >= 0 and reasons[typeId][reasonId] and reasons[typeId][reasonId].description or '')
end

function report()
  if not g_game.isOnline() then
    return
  end

  local targetName  = targetTextEdit:getText()
  local statement   = statementTextEdit and statementTextEdit:getText() or nil
  local translation = translationTextEdit and translationTextEdit:getText() or nil
  local comment     = commentMultilineTextEdit:getText()

  local err
  if typeId == REPORT_TYPE_STATEMENT and not statement then
    err = 'No statement selected. Contact a gamemaster.'
  elseif translation and translation:match(textPattern) then
    err = 'The \'Translation\' field should contains only letters, numbers, spaces and !?+-*/=@()[]{}.,.'
  elseif #comment < minimumCommentSize then
    err = 'You should write at least ' .. minimumCommentSize .. ' chars on \'Comment\' field.'
  elseif comment:match(textPattern) then
    err = 'The \'Comment\' field should contains only letters, numbers, spaces and !?+-*/=@()[]{}.,.'
  end
  if err then
    displayErrorBox('Error', err)
    return
  end

  sendNewReport(typeId, targetName, reasonId, comment, statement or '', translation or '')
  destroyRuleViolationReportWindow()
end










-- View window

local rvViewWindow                     = nil
local rvViewActionButton               = nil
local rvViewTypeActionComboBox         = nil
local rvViewActionComboBox             = nil
local rvViewActionReasonComboBox       = nil
local rvViewActionTargetNameLabel      = nil
local rvViewTargetNameTextEdit         = nil
local rvViewCommentMultilineTextEdit   = nil
local rvViewList                       = nil
local rvViewPage                       = nil
local rvViewRowsPerPageLabel           = nil
local rvViewRowsPerPageOptionScrollbar = nil
local rvViewStateComboBox              = nil
local rvViewTypeComboBox               = nil
local rvViewReasonComboBox             = nil



local REPORT_STATE_UNDONE  = 255
local REPORT_STATE_NEW     = 0
local REPORT_STATE_WORKING = 1
local REPORT_STATE_DONE    = 2

local states =
{
  [REPORT_STATE_UNDONE]  = 'Undone',
  [REPORT_STATE_NEW]     = 'New',
  [REPORT_STATE_WORKING] = 'Working',
  [REPORT_STATE_DONE]    = 'Done'
}



local VIOLATION_ACTIONTYPE_NOTATION  = 0
local VIOLATION_ACTIONTYPE_NAMELOCK  = 1
local VIOLATION_ACTIONTYPE_ACCOUNT   = 2
local VIOLATION_ACTIONTYPE_IPACCOUNT = 3

local ACTION_NOTATION             = { title = 'Notation', actionType = VIOLATION_ACTIONTYPE_NOTATION }
local ACTION_NAMELOCK             = { title = 'Name Lock', actionType = VIOLATION_ACTIONTYPE_NAMELOCK }
local ACTION_BANISHMENT_7_DAYS    = { title = 'Banishment of 7 Days', actionType = VIOLATION_ACTIONTYPE_ACCOUNT, days = 7 }
local ACTION_BANISHMENT_14_DAYS   = { title = 'Banishment of 14 Days', actionType = VIOLATION_ACTIONTYPE_ACCOUNT, days = 14 }
local ACTION_BANISHMENT_30_DAYS   = { title = 'Banishment of 30 Days', actionType = VIOLATION_ACTIONTYPE_ACCOUNT, days = 30 }
local ACTION_BANISHMENT_60_DAYS   = { title = 'Banishment of 60 Days', actionType = VIOLATION_ACTIONTYPE_ACCOUNT, days = 60 }
local ACTION_BANISHMENT_90_DAYS   = { title = 'Banishment of 90 Days', actionType = VIOLATION_ACTIONTYPE_ACCOUNT, days = 90 }
local ACTION_BANISHMENT_PERMANENT = { title = 'Permanent Banishment', actionType = VIOLATION_ACTIONTYPE_ACCOUNT, days = 0 }
local ACTION_IPBANISHMENT_7_DAYS  = { title = 'IP Banishment of 7 Days', actionType = VIOLATION_ACTIONTYPE_IPACCOUNT, days = 7 }
local ACTION_IPBANISHMENT_14_DAYS = { title = 'IP Banishment of 14 Days', actionType = VIOLATION_ACTIONTYPE_IPACCOUNT, days = 14 }
local ACTION_IPBANISHMENT_30_DAYS = { title = 'IP Banishment of 30 Days', actionType = VIOLATION_ACTIONTYPE_IPACCOUNT, days = 30 }
local ACTION_IPBANISHMENT_60_DAYS = { title = 'IP Banishment of 60 Days', actionType = VIOLATION_ACTIONTYPE_IPACCOUNT, days = 60 }
local ACTION_IPBANISHMENT_90_DAYS = { title = 'IP Banishment of 90 Days', actionType = VIOLATION_ACTIONTYPE_IPACCOUNT, days = 90 }

local actions =
{
  [REPORT_TYPE_NAME] =
  {
    ACTION_NAMELOCK
  },

  [REPORT_TYPE_STATEMENT] =
  {
    ACTION_NOTATION,
    ACTION_BANISHMENT_7_DAYS,
    ACTION_BANISHMENT_14_DAYS,
    ACTION_BANISHMENT_30_DAYS,
    ACTION_BANISHMENT_60_DAYS,
    ACTION_BANISHMENT_90_DAYS,
    ACTION_BANISHMENT_PERMANENT,
    ACTION_IPBANISHMENT_7_DAYS,
    ACTION_IPBANISHMENT_14_DAYS,
    ACTION_IPBANISHMENT_30_DAYS,
    ACTION_IPBANISHMENT_60_DAYS,
    ACTION_IPBANISHMENT_90_DAYS
  },

  [REPORT_TYPE_VIOLATION] =
  {
    ACTION_NOTATION,
    ACTION_BANISHMENT_7_DAYS,
    ACTION_BANISHMENT_14_DAYS,
    ACTION_BANISHMENT_30_DAYS,
    ACTION_BANISHMENT_60_DAYS,
    ACTION_BANISHMENT_90_DAYS,
    ACTION_BANISHMENT_PERMANENT,
    ACTION_IPBANISHMENT_7_DAYS,
    ACTION_IPBANISHMENT_14_DAYS,
    ACTION_IPBANISHMENT_30_DAYS,
    ACTION_IPBANISHMENT_60_DAYS,
    ACTION_IPBANISHMENT_90_DAYS
  }
}



local viewPage         = 1
local maxPages         = 1
local viewActionType   = REPORT_TYPE_NAME
local viewAction       = 1
local viewActionReason = 0
local viewTargetName   = ''
local viewComment      = ''
local viewState        = REPORT_STATE_UNDONE -- New + Working
local viewType         = REPORT_TYPE_ALL
local viewReason       = 0

local function hasViewAccess()
  return g_game.getAccountType() >= ACCOUNT_TYPE_GAMEMASTER
end

local function getWindowState()
  return g_game.isOnline() and rvViewWindow and hasViewAccess()
end



function listOnChildFocusChange(textList, focusedChild)
  if not textList then return end
  -- Update Report Rows Style
  local children = textList:getChildren()
  for i = 1, #children do
    if children[i].state == REPORT_STATE_WORKING then
      children[i]:setColor("#3264c8")
    elseif children[i].state == REPORT_STATE_DONE then
      children[i]:setOn(true)
    end
  end
  if not focusedChild then return end

  if rvViewTargetNameTextEdit then
    rvViewActionTargetNameLabel:destroy()
    rvViewTargetNameTextEdit:destroy()
    rvViewActionTargetNameLabel = nil
    rvViewTargetNameTextEdit    = nil

    rvViewWindow:getChildById('commentLabel'):addAnchor(AnchorTop, 'prev', AnchorBottom)
  end
end

function showViewWindow(_targetName, _comment)
  if not g_game.isOnline() or not hasViewAccess() then
    return
  end

  viewPage         = viewPage or 1
  maxPages         = maxPages or 1
  viewActionType   = viewActionType or REPORT_TYPE_NAME
  viewAction       = viewAction or 1
  viewActionReason = viewActionReason or 1
  viewTargetName   = _targetName or viewTargetName or ''
  viewComment      = _comment or viewComment or ''
  viewState        = viewState or REPORT_STATE_UNDONE
  viewType         = viewType or REPORT_TYPE_ALL
  viewReason       = viewReason or 0

  g_ui.importStyle('ruleviolationview')
  rvViewWindow = g_ui.createWidget('RVViewWindow', rootWidget)
  rvViewWindow:raise()
  rvViewWindow:lock()
  rvViewActionButton = rvViewWindow:getChildById('rvViewActionButton')
  rvViewTypeActionComboBox = rvViewWindow:getChildById('rvViewTypeActionComboBox')
  rvViewActionComboBox = rvViewWindow:getChildById('rvViewActionComboBox')
  rvViewActionReasonComboBox = rvViewWindow:getChildById('rvViewActionReasonComboBox')
  rvViewCommentMultilineTextEdit = rvViewWindow:getChildById('rvViewCommentMultilineTextEdit')
  rvViewList = rvViewWindow:getChildById('rvViewList')
  rvViewPage = rvViewWindow:getChildById('rvViewPage')
  rvViewRowsPerPageLabel = rvViewWindow:getChildById('rvViewRowsPerPageLabel')
  rvViewRowsPerPageOptionScrollbar = rvViewWindow:getChildById('rvViewRowsPerPageOptionScrollbar')
  rvViewStateComboBox = rvViewWindow:getChildById('rvViewStateComboBox')
  rvViewTypeComboBox = rvViewWindow:getChildById('rvViewTypeComboBox')
  rvViewReasonComboBox = rvViewWindow:getChildById('rvViewReasonComboBox')

  rvViewList.onChildFocusChange = listOnChildFocusChange
  updateRowsPerPageLabel(getRowsPerPage())

  -- Action Type ComboBox
  for _type = REPORT_TYPE_NAME, REPORT_TYPE_VIOLATION do
    rvViewTypeActionComboBox:addOption(types[_type])
  end
  rvViewTypeActionComboBox.onOptionChange = onViewChangeActionType
  rvViewTypeActionComboBox:setCurrentOption(types[viewActionType])
  onViewChangeActionType(rvViewTypeActionComboBox) -- Actions ComboBox
  rvViewDetachRow() -- Target Name Text Edit

  -- Action ComboBox
  rvViewActionComboBox.onOptionChange = onViewChangeAction
  rvViewActionComboBox:setCurrentOption(actions[viewActionType][viewAction].title)

  -- Action Reason ComboBox
  rvViewActionReasonComboBox.onOptionChange = onViewChangeActionReason
  rvViewActionReasonComboBox:setCurrentOption(reasons[viewActionType][viewActionReason].title)
  onViewChangeActionReason(rvViewActionReasonComboBox)

  -- Action Target Name MultilineTextEdit
  if rvViewTargetNameTextEdit then
    rvViewTargetNameTextEdit:setText(viewTargetName)
  end

  -- Action Comment MultilineTextEdit
  rvViewCommentMultilineTextEdit:setText(viewComment)

  -- State ComboBox
  rvViewStateComboBox:addOption(states[REPORT_STATE_UNDONE])
  for state = REPORT_STATE_NEW, REPORT_STATE_DONE do
    rvViewStateComboBox:addOption(states[state])
  end
  rvViewStateComboBox.onOptionChange = onViewChangeState
  rvViewStateComboBox:setCurrentOption(states[viewState])

  -- Type ComboBox
  rvViewTypeComboBox:addOption(types[REPORT_TYPE_ALL])
  for _type = REPORT_TYPE_NAME, REPORT_TYPE_VIOLATION do
    rvViewTypeComboBox:addOption(types[_type])
  end
  rvViewTypeComboBox.onOptionChange = onViewChangeType
  rvViewTypeComboBox:setCurrentOption(types[viewType])
  onViewChangeType(rvViewTypeComboBox)

  -- Reason ComboBox
  rvViewReasonComboBox.onOptionChange = onViewChangeReason
  if viewType ~= REPORT_TYPE_ALL then
    rvViewReasonComboBox:setCurrentOption(reasons[viewType][viewReason].title)
  end

  updatePage() -- Fill list
end

function destroyRVViewWindow()
  if rvViewWindow then
    rvViewWindow:destroy()
  end

  rvViewWindow                     = nil
  rvViewActionButton               = nil
  rvViewTypeActionComboBox         = nil
  rvViewActionComboBox             = nil
  rvViewActionReasonComboBox       = nil
  rvViewActionTargetNameLabel      = nil
  rvViewTargetNameTextEdit         = nil
  rvViewCommentMultilineTextEdit   = nil
  rvViewList                       = nil
  rvViewPage                       = nil
  rvViewRowsPerPageLabel           = nil
  rvViewRowsPerPageOptionScrollbar = nil
  rvViewStateComboBox              = nil
  rvViewTypeComboBox               = nil
  rvViewReasonComboBox             = nil
end

function clearViewWindow()
  viewPage         = 1
  maxPages         = 1
  viewActionType   = REPORT_TYPE_NAME
  viewAction       = 1
  viewActionReason = 0
  viewTargetName   = ''
  viewComment      = ''
  viewState        = REPORT_STATE_UNDONE -- New + Working
  viewType         = REPORT_TYPE_ALL
  viewReason       = 0

  rvViewPage:setText('1')
  updateRowsPerPageLabel(getRowsPerPage())

  rvViewTypeActionComboBox:setCurrentOption(types[viewActionType])
  rvViewActionComboBox:setCurrentOption(actions[viewActionType][viewAction].title)
  rvViewActionReasonComboBox:setCurrentOption(reasons[viewActionType][viewActionReason].title)
  if rvViewTargetNameTextEdit then
    rvViewTargetNameTextEdit:setText('')
  end
  rvViewCommentMultilineTextEdit:setText('')
  rvViewStateComboBox:setCurrentOption(states[viewState])
  rvViewTypeComboBox:setCurrentOption(types[viewType])
  if viewType ~= REPORT_TYPE_ALL then
    rvViewReasonComboBox:setCurrentOption(reasons[viewType][viewReason].title)
  end

  updatePage() -- Fill list
end

function openRow(row)
  if not g_game.isOnline() or not hasViewAccess() then
    return
  end

  if rvWindow and rvWindow:isVisible() then
    displayErrorBox('Error', 'You should close the \'Report Rule Violation\' window before do this.')
    return
  end

  showRuleViolationReportWindow(row.type, row.targetName, row.statement)
  if rvWindow then
    rvViewWindow:unlock()
    rvViewWindow:hide()

    rvWindow:lock()

    rvLabel:setText(string.format('%s\n- Time: %s\n- Player name: %s', row:getText(), os.date('%Y %b %d %H:%M:%S', row.time), row.playerName))

    typeComboBox:setCurrentOption(reasons[row.type][row.reasonId].title)
    typeComboBox:setEnabled(false)
    if statementTextEdit then
      local rvStatementVerticalScrollBar = g_ui.createWidget('HorizontalScrollBar', rvWindow)
      rvStatementVerticalScrollBar:setId('rvStatementVerticalScrollBar')
      rvStatementVerticalScrollBar:setStep(5)
      rvStatementVerticalScrollBar.pixelsScroll = true
      rvStatementVerticalScrollBar:addAnchor(AnchorTop, 'statementTextEdit', AnchorBottom)
      rvStatementVerticalScrollBar:addAnchor(AnchorLeft, 'statementTextEdit', AnchorLeft)
      rvStatementVerticalScrollBar:addAnchor(AnchorRight, 'statementTextEdit', AnchorRight)
      if translationTextEdit then
        rvWindow:getChildById('translationLabel'):addAnchor(AnchorTop, 'rvStatementVerticalScrollBar', AnchorBottom)
      else
        rvWindow:getChildById('reasonLabel'):addAnchor(AnchorTop, 'rvStatementVerticalScrollBar', AnchorBottom)
      end
      statementTextEdit:setHorizontalScrollBar(rvStatementVerticalScrollBar)
    end
    if translationTextEdit then
      translationTextEdit:setText(row.translation)
      translationTextEdit:setEditable(false)

      local rvTranslationVerticalScrollBar = g_ui.createWidget('HorizontalScrollBar', rvWindow)
      rvTranslationVerticalScrollBar:setId('rvTranslationVerticalScrollBar')
      rvTranslationVerticalScrollBar:setStep(5)
      rvTranslationVerticalScrollBar.pixelsScroll = true
      rvTranslationVerticalScrollBar:addAnchor(AnchorTop, 'translationTextEdit', AnchorBottom)
      rvTranslationVerticalScrollBar:addAnchor(AnchorLeft, 'translationTextEdit', AnchorLeft)
      rvTranslationVerticalScrollBar:addAnchor(AnchorRight, 'translationTextEdit', AnchorRight)
      rvWindow:getChildById('reasonLabel'):addAnchor(AnchorTop, 'rvTranslationVerticalScrollBar', AnchorBottom)
      translationTextEdit:setHorizontalScrollBar(rvTranslationVerticalScrollBar)
    end
    commentMultilineTextEdit:setText(row.comment)
    commentMultilineTextEdit:setEditable(false)

    okButton:hide()
    cancelButton.onClick = function() if rvViewTargetNameTextEdit then viewTargetName = rvViewTargetNameTextEdit:getText() end viewComment = rvViewCommentMultilineTextEdit:getText() rvWindow:unlock() destroyRuleViolationReportWindow() showViewWindow() rvViewWindow:lock() listOnChildFocusChange(rvViewList, rvViewList:getFocusedChild()) end
    rvWindow.onEscape = cancelButton.onClick
  end
end



function onRVViewPageChange(self)
  local text   = self:getText()
  local number = tonumber(text) or 0
  if text:match('[^0-9]+') or number > maxPages then -- Pattern: Cannot have non numbers (Correct: '7', '777' | Wrong: 'A7', '-7')
    return self:setText(maxPages)
  elseif text:match('^[0]+[1-9]*') then -- Pattern: Cannot start with 0, except 0 itself (Correct: '0', '70' | Wrong: '00', '07')
    return self:setText(1)
  end
end

function getRowsPerPage() return rvViewRowsPerPageOptionScrollbar and rvViewRowsPerPageOptionScrollbar:getValue() or 1 end
function updateRowsPerPageLabel(value) if not rvViewRowsPerPageLabel then return end rvViewRowsPerPageLabel:setText('Rows per page: ' .. value) end

function onViewChangeState(comboBox, option)
  if option then
    local newViewState = nil
    for k, v in pairs(states) do
      if v == option then newViewState = k break end
    end
    if not newViewState then return end
    viewState = newViewState
  end
end

function onViewChangeType(comboBox, option)
  if option then
    local newViewType = nil
    for k, v in pairs(types) do
      if v == option then newViewType = k break end
    end
    if not newViewType then return end
    viewType = newViewType
  end

  rvViewReasonComboBox:clearOptions()
  if viewType ~= REPORT_TYPE_ALL then
    for k = 0, #reasons[viewType] do
      rvViewReasonComboBox:addOption(reasons[viewType][k].title)
    end
  end
end

function onViewChangeReason(comboBox, option)
  if option then
    if viewType == REPORT_TYPE_ALL then return end

    local newViewReason = nil
    for k, v in pairs(reasons[viewType]) do
      if v.title == option then newViewReason = k break end
    end

    if not newViewReason then return end
    viewReason = newViewReason
  end
end

function rvViewUpdatePage()
  local page = tonumber(rvViewPage:getText()) or 1
  if page < 1 or page > maxPages then return end
  viewPage = page
  updatePage()
end

function rvViewPreviousPage()
  viewPage = math.max(1, viewPage - 1)
  rvViewPage:setText(viewPage)
  updatePage()
end

function rvViewNextPage()
  viewPage = math.min(viewPage + 1, maxPages)
  rvViewPage:setText(viewPage)
  updatePage()
end

function updatePage()
  if not getWindowState() then return end
  sendUpdateSearch(viewType, viewReason, viewPage, getRowsPerPage(), viewState)
end



local function updateReportRowTitle(row)
  row:setText(row.id .. '. [' .. states[row.state] .. ' | ' .. types[row.type] .. '] ' .. row.comment:sub(0, 35) .. (#row.comment > 35 and "..." or ""))
end

function parseRuleViolationsReports(protocol, opcode, buffer)
  if not getWindowState() then return end

  -- Clear list
  local children = rvViewList:getChildren()
  for i = 1, #children do
    rvViewList:removeChild(children[i])
    children[i]:destroy()
  end

  local _buffer = string.split(buffer, ':::')
  if #_buffer ~= 2 then return end

  maxPages = tonumber(_buffer[1]) or 1
  maxPages = math.ceil(maxPages / getRowsPerPage())

  local reports = string.split(_buffer[2], '::')
  for _, report in ipairs(reports) do
    local data = string.split(report, ':')
    local row = g_ui.createWidget('RVVRowLabel', rvViewList)
    row.id          = tonumber(data[1])
    row.state       = tonumber(data[2])
    row.time        = tonumber(data[3])
    row.type        = tonumber(data[4])
    row.playerId    = tonumber(data[5])
    row.targetName  = string.format('%s', data[6])
    row.statement   = string.format('%s', data[7])
    row.translation = string.format('%s', data[8])
    row.reasonId    = tonumber(data[9])
    row.comment     = string.format('%s', data[10])
    row.playerName  = string.format('%s', data[11])
    updateReportRowTitle(row)
    row.onDoubleClick = openRow
  end

  rvViewDetachRow()
  listOnChildFocusChange(rvViewList, rvViewList:getFocusedChild())
end



-- For avoid multiple confirm windows
local confirmWindowLock = false
function setConfirmWindowLock(lock) confirmWindowLock = lock end

function removeRow(rvViewList, row) -- After confirm button
  if not getWindowState() then return end

  sendRemoveRow(row)

  rvViewList:removeChild(row)
  row:destroy()

  rvViewDetachRow()
  listOnChildFocusChange(rvViewList, rvViewList:getFocusedChild())
end

function rvViewRemoveRow()
  if not getWindowState() then return end

  local row = rvViewList:getFocusedChild()
  if not row then
    displayErrorBox('Error', 'No row selected.')
    return
  end

  if not confirmWindowLock then
    displayCustomBox('Warning', 'Are you sure that you want to remove the row id ' .. row.id .. '?', {{ text = 'Yes', buttonCallback = function() modules.game_ruleviolation.removeRow(rvViewList, row) modules.game_ruleviolation.setConfirmWindowLock(false) end }}, 1, 'No', function() modules.game_ruleviolation.setConfirmWindowLock(false) end, nil)
    setConfirmWindowLock(true)
  end
end

function rvViewSetReportState()
  if not getWindowState() then return end

  local err
  local row = rvViewList:getFocusedChild()
  if not row then
    err = 'No row selected.'
  elseif viewState == 255 then
    err = 'Is not possible to set for this state.'
  end
  if err then
    displayErrorBox('Error', err)
    return
  end

  row.state = viewState
  sendUpdateState(row)
  updateReportRowTitle(row)

  rvViewDetachRow()
  listOnChildFocusChange(rvViewList, rvViewList:getFocusedChild())
end



function rvViewDetachRow()
  rvViewList:focusChild(nil)

  if not rvViewTargetNameTextEdit or not rvViewTargetNameTextEdit:isVisible() then
    rvViewActionTargetNameLabel = g_ui.createWidget('Label', rvViewWindow)
    rvViewActionTargetNameLabel:setId('rvViewActionTargetNameLabel')
    rvViewActionTargetNameLabel:setText('Target name:')
    rvViewActionTargetNameLabel:addAnchor(AnchorTop, 'rvViewActionReasonComboBox', AnchorBottom)
    rvViewActionTargetNameLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    rvViewActionTargetNameLabel:setMarginTop(5)

    rvViewTargetNameTextEdit = g_ui.createWidget('TextEdit', rvViewWindow)
    rvViewTargetNameTextEdit:setId('rvViewTargetNameTextEdit')
    rvViewTargetNameTextEdit:addAnchor(AnchorTop, 'rvViewActionReasonComboBox', AnchorBottom)
    rvViewTargetNameTextEdit:addAnchor(AnchorLeft, 'rvViewActionTargetNameLabel', AnchorRight)
    rvViewTargetNameTextEdit:addAnchor(AnchorRight, 'parent', AnchorRight)
    rvViewTargetNameTextEdit:setMarginTop(3)
    rvViewTargetNameTextEdit:setMarginLeft(5)

    rvViewWindow:getChildById('commentLabel'):addAnchor(AnchorTop, 'rvViewTargetNameTextEdit', AnchorBottom)
  end
end

function onViewChangeActionType(comboBox, option)
  if option then
    local newViewActionType = nil
    for k, v in pairs(types) do
      if v == option then newViewActionType = k break end
    end
    if not newViewActionType then return end
    viewActionType = newViewActionType
  end

  rvViewActionComboBox:clearOptions()
  for k = 1, #actions[viewActionType] do
    rvViewActionComboBox:addOption(actions[viewActionType][k].title)
  end

  rvViewActionReasonComboBox:clearOptions()
  for k = 0, #reasons[viewActionType] do
    rvViewActionReasonComboBox:addOption(reasons[viewActionType][k].title)
  end
end

function onViewChangeAction(comboBox, option)
  if option then
    local newViewAction = nil
    for k, v in pairs(actions[viewActionType]) do
      if v.title == option then newViewAction = k break end
    end

    if not newViewAction then return end
    viewAction = newViewAction
  end
end

function onViewChangeActionReason(comboBox, option)
  if option then
    local newViewActionReason = nil
    for k, v in pairs(reasons[viewActionType]) do
      if v.title == option then newViewActionReason = k break end
    end

    if not newViewActionReason then return end
    viewActionReason = newViewActionReason
  end

  rvViewActionReasonComboBox:setTooltip(viewActionType and viewActionReason >= 0 and reasons[viewActionType][viewActionReason] and reasons[viewActionType][viewActionReason].description or '')
end

local function checkActionFields(row, targetName)
  local err
  if row and (not row.targetName or row.targetName == '') then
    err = 'The selected row has no target.'
  elseif not row and (not targetName or targetName == '') then
    err = 'No row selected or field \'Target name\' is empty.'
  elseif rvViewCommentMultilineTextEdit:getText():match(textPattern) then
    err = 'The \'Action comment\' field should contains only letters, numbers, spaces and !?+-*/=@()[]{}.,.'
  end
  if err then
    displayErrorBox('Error', err)
    return false
  end
  return true
end

function action(row, targetName)
  if not getWindowState() or not checkActionFields(row, targetName) then return end

  local action = actions[viewActionType][viewAction].actionType
  local days   = actions[viewActionType][viewAction].days or 0
  sendAddAction(viewActionType, targetName, viewActionReason, rvViewCommentMultilineTextEdit:getText(), action, days, row)

  if row then
    sendUpdateState(row, REPORT_STATE_DONE)
    updateReportRowTitle(row)
  end

  updatePage()
end

function rvViewAction()
  if not getWindowState() then return end

  local row = rvViewList:getFocusedChild()
  local targetName = not row and rvViewTargetNameTextEdit and rvViewTargetNameTextEdit:getText() or row and row.targetName or ''
  if not checkActionFields(row, targetName) then return end

  local message = 'Are you sure that you want to add the action \'' .. actions[viewActionType][viewAction].title .. '\' to player \'' .. targetName .. '\'?'

  -- Notes
  local notes = ''
  if not row then
    notes = notes .. '\n' .. '- Is not recommended to make any action without a report attached.'
  end
  if row then
    if row.state == REPORT_STATE_DONE then
      notes = notes .. '\n' .. '- The selected row has already been marked as \'' .. states[REPORT_STATE_DONE] .. '\'.'
    end
    if viewActionType ~= row.type then
      notes = notes .. '\n' .. '- The setted action has a different type (' .. types[viewActionType] .. ') of the selected row (' .. types[row.type] .. ').'
    else
      if viewActionReason ~= row.reasonId then
        notes = notes .. '\n' .. '- The setted action has a different reason of the selected row.'
      end
    end
  end
  if notes ~= '' then
    message = message .. '\n\nIMPORTANT:\n' .. notes
  end

  if not confirmWindowLock then
    displayCustomBox('Warning', message, {{ text = 'Yes', buttonCallback = function() modules.game_ruleviolation.action(row, targetName) modules.game_ruleviolation.setConfirmWindowLock(false) end }}, 1, 'No', function() modules.game_ruleviolation.setConfirmWindowLock(false) end, nil)
    setConfirmWindowLock(true)
  end
end

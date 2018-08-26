local maximumXYValue     = 9999
local maximumZValue      = 15
local minimumCommentSize = 50
local textPattern     = "[^%w%s!?%+-*/=@%(%)%[%]%{%}.,]+" -- Find symbols that are NOT letters, numbers, spaces and !?+-*/=@()[]{}.,



local REPORT_MODE_NEWREPORT    = 0
local REPORT_MODE_UPDATESEARCH = 1
local REPORT_MODE_UPDATESTATE  = 2
local REPORT_MODE_REMOVEROW    = 3

local function sendNewReport(category, comment, position)
  position = position or { x = 0, y = 0, z = 0 }
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then return end
  protocolGame:sendExtendedOpcode(ClientExtOpcodes.ClientBugReport, string.format("%d;%d;%s;%d;%d;%d", REPORT_MODE_NEWREPORT, category, comment:trim(), position.x, position.y, position.z))
end

local function sendUpdateSearch(category, page, rowsPerPage, state)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then return end
  protocolGame:sendExtendedOpcode(ClientExtOpcodes.ClientBugReport, string.format("%d;%d;%d;%d;%d", REPORT_MODE_UPDATESEARCH, category, page, rowsPerPage, state))
end

local function sendUpdateState(row)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then return end
  protocolGame:sendExtendedOpcode(ClientExtOpcodes.ClientBugReport, string.format("%d;%d;%d", REPORT_MODE_UPDATESTATE, row.state, row.id))
end

local function sendRemoveRow(row)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then return end
  protocolGame:sendExtendedOpcode(ClientExtOpcodes.ClientBugReport, string.format("%d;%d", REPORT_MODE_REMOVEROW, row.id))
end



bugReportWindow             = nil
bugLabel                    = nil
bugReportButton             = nil
bugCommentMultilineTextEdit = nil
bugCategoryComboBox         = nil
bugPositionX                = nil
bugPositionY                = nil
bugPositionZ                = nil
bugOkButton                 = nil
bugCancelButton             = nil



local REPORT_CATEGORY_ALL       = 255
local REPORT_CATEGORY_MAP       = 0
local REPORT_CATEGORY_TYPO      = 1
local REPORT_CATEGORY_TECHNICAL = 2
local REPORT_CATEGORY_OTHER     = 3

local categories =
{
  [REPORT_CATEGORY_ALL]       = 'All',
  [REPORT_CATEGORY_MAP]       = 'Map',
  [REPORT_CATEGORY_TYPO]      = 'Typo',
  [REPORT_CATEGORY_TECHNICAL] = 'Technical',
  [REPORT_CATEGORY_OTHER]     = 'Other'
}



local bugCategory = REPORT_CATEGORY_MAP



function init()
  g_ui.importStyle('bugreport')

  bugReportButton = modules.client_topmenu.addLeftGameButton('bugReportButton', tr('Report Bug/Problem/Idea') .. ' (Ctrl+,)', '/images/topbuttons/bugreport', toggle)

  bugReportWindow = g_ui.createWidget('BugReportWindow', rootWidget)
  bugReportWindow:hide()
  bugLabel = bugReportWindow:getChildById('bugLabel')
  bugPositionX = bugReportWindow:getChildById('bugPositionX')
  bugPositionY = bugReportWindow:getChildById('bugPositionY')
  bugPositionZ = bugReportWindow:getChildById('bugPositionZ')
  bugOkButton = bugReportWindow:getChildById('bugOkButton')
  bugCancelButton = bugReportWindow:getChildById('bugCancelButton')
  bugCategoryComboBox = bugReportWindow:recursiveGetChildById('bugCategoryComboBox')
  bugCategoryComboBox:addOption('Map')
  bugCategoryComboBox:addOption('Typo')
  bugCategoryComboBox:addOption('Technical')
  bugCategoryComboBox:addOption('Other')
  bugCategoryComboBox.onOptionChange = onChangeCategory
  onChangeCategory(bugCategoryComboBox, 'map') -- For update the tooltip when init the window
  bugCommentMultilineTextEdit = bugReportWindow:getChildById('bugCommentMultilineTextEdit')

  g_keyboard.bindKeyDown('Ctrl+,', toggle)
  ProtocolGame.registerExtendedOpcode(GameServerExtOpcodes.GameServerBugReport, parseBugReports) -- View List
end

function terminate()
  ProtocolGame.unregisterExtendedOpcode(GameServerExtOpcodes.GameServerBugReport) -- View List
  g_keyboard.unbindKeyDown('Ctrl+,')

  destroyBugReportWindow()
  destroyBugReportViewWindow()
end

function destroyBugReportWindow()
  if bugReportWindow then
    bugReportWindow:destroy()
  end

  bugReportWindow             = nil
  bugLabel                    = nil
  bugReportButton             = nil
  bugCommentMultilineTextEdit = nil
  bugCategoryComboBox         = nil
  bugPositionX                = nil
  bugPositionY                = nil
  bugPositionZ                = nil
  bugOkButton                 = nil
  bugCancelButton             = nil
end

local function clearBugReportWindow()
  bugCategoryComboBox:setCurrentOption('Map')
  bugCategoryComboBox:setEnabled(true)
  bugPositionX:setText(0)
  bugPositionY:setText(0)
  bugPositionZ:setText(0)
  bugPositionX:setEnabled(true)
  bugPositionY:setEnabled(true)
  bugPositionZ:setEnabled(true)
  bugCommentMultilineTextEdit:setText('')
  bugCommentMultilineTextEdit:setEditable(true)
  bugLabel:setText('Use this dialog to only report bug or idea!\nONLY IN ENGLISH!\n\n[Bad Example] :(\nFound a fucking bug! msg me! fast!!!\n\n[Nice Example] :)\nGood morning!\nI found a map bug on my actual position.\nHere is the details: ...')
  bugOkButton:show()
  bugOkButton.onClick = doReport
  bugCancelButton:setText('Cancel')
  bugCancelButton.onClick = hideReportWindow
  bugReportWindow.onEscape = bugCancelButton.onClick
  bugCommentMultilineTextEdit:focus()
end

function showReportWindow()
  if not g_game.isOnline() then
    return
  end

  clearBugReportWindow()
  bugReportWindow:show()
  bugReportWindow:raise()
  bugReportWindow:focus()
  bugReportButton:setOn(true)
end

function hideReportWindow()
  clearBugReportWindow()
  bugReportWindow:hide()
  bugReportButton:setOn(false)
end

function toggle()
  if not bugReportWindow:isVisible() then showReportWindow() else hideReportWindow() end
end



function onChangeCategory(comboBox, option)
  local newCategory = nil
  for k, v in pairs(categories) do
    if v == option then newCategory = k break end
  end
  if not newCategory then return end
  bugCategory = newCategory

  local isMap = bugCategory == REPORT_CATEGORY_MAP
  if not isMap then
    bugPositionX:setText(0)
    bugPositionY:setText(0)
    bugPositionZ:setText(0)
  end
  bugOkButton:setTooltip(isMap and 'Do not enter your actual player position.\nLeave the default position in blank,\nif you are at the bug position.' or '')
  bugPositionX:setEnabled(isMap)
  bugPositionY:setEnabled(isMap)
  bugPositionZ:setEnabled(isMap)
end

local function onPositionTextChange(self, maxValue)
  local text = self:getText()
  if text:match("[^0-9]+") or (tonumber(text) or 0) > maxValue then
    self:setText(maxValue)
  end
end

function onPositionXTextChange(self)
  onPositionTextChange(self, maximumXYValue)
end

function onPositionYTextChange(self)
  onPositionTextChange(self, maximumXYValue)
end

function onPositionZTextChange(self)
  onPositionTextChange(self, maximumZValue)
end



function doReport()
  if not g_game.canPerformGameAction() then return end

  local position =
  {
    x = tonumber(bugPositionX:getText()) or 0,
    y = tonumber(bugPositionY:getText()) or 0,
    z = tonumber(bugPositionZ:getText()) or 0
  }

  local err
  local comment = bugCommentMultilineTextEdit:getText()
  if #comment < minimumCommentSize then
    err = 'You should write at least ' .. minimumCommentSize .. ' chars on \'Comment\' field.'
  elseif comment:match(textPattern) then
    err = 'The \'Comment\' field should contains only letters, numbers, spaces and !?+-*/=@()[]{}.,.'
  end
  if err then
    displayErrorBox('Error', err)
    return
  end

  sendNewReport(bugCategory, comment, position)
  hideReportWindow()
end










-- View window

local bugReportViewWindow               = nil
local bugViewList                       = nil
local bugViewPage                       = nil
local bugViewRowsPerPageLabel           = nil
local bugViewRowsPerPageOptionScrollbar = nil
local bugViewStateComboBox              = nil
local bugViewCategoryComboBox           = nil



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



local viewPage     = 1
local maxPages     = 1
local viewState    = REPORT_STATE_UNDONE -- New + Working
local viewCategory = REPORT_CATEGORY_ALL

local function hasViewAccess()
  return g_game.getAccountType() >= ACCOUNT_TYPE_GAMEMASTER
end

local function getWindowState()
  return g_game.isOnline() and bugReportViewWindow and hasViewAccess()
end



function listOnChildFocusChange(textList, focusedChild)
  if not textList then return end
  -- Update Report Rows Style
  local children = bugViewList:getChildren()
  for i = 1, #children do
    if children[i].state == REPORT_STATE_WORKING then
      children[i]:setColor("#3264c8")
    elseif children[i].state == REPORT_STATE_DONE then
      children[i]:setOn(true)
    end
  end
  if not focusedChild then return end
end

function showViewWindow()
  if not g_game.isOnline() or not hasViewAccess() then
    return
  end

  viewPage     = viewPage or 1
  maxPages     = maxPages or 1
  viewState    = viewState or REPORT_STATE_UNDONE
  viewCategory = viewCategory or REPORT_CATEGORY_ALL

  g_ui.importStyle('bugreportview')
  bugReportViewWindow = g_ui.createWidget('BugReportViewWindow', rootWidget)
  bugReportViewWindow:raise()
  bugReportViewWindow:lock()
  bugViewList = bugReportViewWindow:getChildById('bugViewList')
  bugViewPage = bugReportViewWindow:getChildById('bugViewPage')
  bugViewRowsPerPageLabel = bugReportViewWindow:getChildById('bugViewRowsPerPageLabel')
  bugViewRowsPerPageOptionScrollbar = bugReportViewWindow:getChildById('bugViewRowsPerPageOptionScrollbar')
  bugViewStateComboBox = bugReportViewWindow:getChildById('bugViewStateComboBox')
  bugViewCategoryComboBox = bugReportViewWindow:getChildById('bugViewCategoryComboBox')

  bugViewList.onChildFocusChange = listOnChildFocusChange
  updateRowsPerPageLabel(getRowsPerPage())

  bugViewStateComboBox:addOption(states[REPORT_STATE_UNDONE])
  for state = REPORT_STATE_NEW, REPORT_STATE_DONE do
    bugViewStateComboBox:addOption(states[state])
  end
  bugViewStateComboBox.onOptionChange = onViewChangeState

  bugViewCategoryComboBox:addOption(categories[REPORT_CATEGORY_ALL])
  for category = REPORT_CATEGORY_MAP, REPORT_CATEGORY_OTHER do
    bugViewCategoryComboBox:addOption(categories[category])
  end
  bugViewCategoryComboBox.onOptionChange = onViewChangeCategory

  updatePage() -- Fill list
end

function destroyBugReportViewWindow()
  if bugReportViewWindow then
    bugReportViewWindow:destroy()
  end

  bugReportViewWindow               = nil
  bugViewList                       = nil
  bugViewPage                       = nil
  bugViewRowsPerPageLabel           = nil
  bugViewRowsPerPageOptionScrollbar = nil
  bugViewStateComboBox              = nil
  bugViewCategoryComboBox           = nil
end

function clearViewWindow()
  viewPage     = 1
  maxPages     = 1
  viewState    = REPORT_STATE_UNDONE
  viewCategory = REPORT_CATEGORY_ALL

  bugViewPage:setText('1')
  updateRowsPerPageLabel(getRowsPerPage())

  bugViewStateComboBox:setCurrentOption(states[viewState])
  bugViewCategoryComboBox:setCurrentOption(categories[viewCategory])

  updatePage() -- Fill list
end

local function clearBugReportViewWindow(row)
  bugPositionX:setText(row.mapposx)
  bugPositionY:setText(row.mapposy)
  bugPositionZ:setText(row.mapposz)

  bugCategoryComboBox:setEnabled(false)
  bugPositionX:setEnabled(false)
  bugPositionY:setEnabled(false)
  bugPositionZ:setEnabled(false)
  bugCommentMultilineTextEdit:setText(row.comment)
  bugCommentMultilineTextEdit:setTextAlign(AlignTopLeft)
  bugCommentMultilineTextEdit:setEditable(false)
  bugOkButton:hide()
  bugCancelButton:setText('Close')
  bugCancelButton.onClick = function() bugReportWindow:unlock() hideReportWindow() bugReportViewWindow:show() bugReportViewWindow:lock() listOnChildFocusChange(bugViewList, bugViewList:getFocusedChild()) end
  bugReportWindow.onEscape = bugCancelButton.onClick
end

function openRow(row)
  if not g_game.isOnline() or not hasViewAccess() then
    return
  end

  if bugReportWindow and bugReportWindow:isVisible() then
    displayErrorBox('Error', 'You should close the \'Report Bug/Problem/Idea\' window before do this.')
    return
  end

  showReportWindow()
  if bugReportWindow then
    bugReportViewWindow:unlock()
    bugReportViewWindow:hide()

    bugReportWindow:lock()
    clearBugReportViewWindow(row)

    bugLabel:setText(string.format('%s\n- Time: %s\n- Player name: %s\n- Player pos: [ X: %d | Y: %d | Z: %d ]', row:getText(), os.date('%Y %b %d %H:%M:%S', row.time), row.playername, row.playerposx, row.playerposy, row.playerposz))

    if categories[row.category] then
      bugCategoryComboBox:setCurrentOption(categories[row.category])
    end
  end
end



function onBugViewPageChange(self)
  local text   = self:getText()
  local number = tonumber(text) or 0
  if text:match('[^0-9]+') or number > maxPages then -- Pattern: Cannot have non numbers (Correct: '7', '777' | Wrong: 'A7', '-7')
    return self:setText(maxPages)
  elseif text:match('^[0]+[1-9]*') then -- Pattern: Cannot start with 0, except 0 itself (Correct: '0', '70' | Wrong: '00', '07')
    return self:setText(1)
  end
end

function getRowsPerPage() return bugViewRowsPerPageOptionScrollbar and bugViewRowsPerPageOptionScrollbar:getValue() or 1 end
function updateRowsPerPageLabel(value) if not bugViewRowsPerPageLabel then return end bugViewRowsPerPageLabel:setText('Rows per page: ' .. value) end

function onViewChangeCategory(comboBox, option)
  local newViewCategory = nil
  for k, v in pairs(categories) do
    if v == option then newViewCategory = k break end
  end
  if not newViewCategory then return end
  viewCategory = newViewCategory
end

function onViewChangeState(comboBox, option)
  local newViewState = nil
  for k, v in pairs(states) do
    if v == option then newViewState = k break end
  end
  if not newViewState then return end
  viewState = newViewState
end

function bugViewUpdatePage()
  local page = tonumber(bugViewPage:getText()) or 1
  if page < 1 or page > maxPages then return end
  viewPage = page
  updatePage()
end

function bugViewPreviousPage()
  viewPage = math.max(1, viewPage - 1)
  bugViewPage:setText(viewPage)
  updatePage()
end

function bugViewNextPage()
  viewPage = math.min(viewPage + 1, maxPages)
  bugViewPage:setText(viewPage)
  updatePage()
end

function updatePage()
  if not g_game.canPerformGameAction() or not getWindowState() then return end
  sendUpdateSearch(viewCategory, viewPage, getRowsPerPage(), viewState)
end



local function updateReportRowTitle(row)
  row:setText(row.id .. '. [' .. states[row.state] .. ' | ' .. categories[row.category] .. '] ' .. row.comment:sub(0, 35) .. (#row.comment > 35 and "..." or ""))
end

function parseBugReports(protocol, opcode, buffer)
  if not getWindowState() then return end

  -- Clear list
  local children = bugViewList:getChildren()
  for i = 1, #children do
    bugViewList:removeChild(children[i])
    children[i]:destroy()
  end

  local _buffer = string.split(buffer, ';:')
  if #_buffer ~= 2 then return end

  maxPages = tonumber(_buffer[1]) or 1
  maxPages = math.ceil(maxPages / getRowsPerPage())

  local reports = string.split(_buffer[2], ';')
  for _, report in ipairs(reports) do
    local data = string.split(report, ':')
    local row = g_ui.createWidget('BRVRowLabel', bugViewList)
    row.id         = tonumber(data[1])
    row.state      = tonumber(data[2])
    row.time       = tonumber(data[3])
    row.playername = data[4]
    row.category   = tonumber(data[5])
    row.mapposx    = tonumber(data[6])
    row.mapposy    = tonumber(data[7])
    row.mapposz    = tonumber(data[8])
    row.playerposx = tonumber(data[9])
    row.playerposy = tonumber(data[10])
    row.playerposz = tonumber(data[11])
    row.comment    = string.format('%s', data[12])
    updateReportRowTitle(row)
    row.onDoubleClick = openRow
  end

  listOnChildFocusChange(bugViewList, bugViewList:getFocusedChild())
end



-- For avoid multiple remove row confirm windows
local removeConfirmWindowLock = false
function setRemoveConfirmWindowLock(lock) removeConfirmWindowLock = lock end

function removeRow(bugViewList, row) -- After confirm button
  if not g_game.canPerformGameAction() or not getWindowState() then return end

  -- Ignored fields
  local _bugCategory = 255
  local _position    = {}
  local _comment     = ''
  local _page        = 65535
  local _rowsPerPage = 65535
  local _state       = 255

  sendRemoveRow(row)
  bugViewList:removeChild(row)
  row:destroy()

  listOnChildFocusChange(bugViewList, bugViewList:getFocusedChild())
end

function bugViewRemoveRow()
  if not getWindowState() then return end

  local row = bugViewList:getFocusedChild()
  if not row then
    displayErrorBox('Error', 'No row selected.')
    return
  end

  if not removeConfirmWindowLock then
    displayCustomBox('Warning', 'Are you sure that you want to remove the row id ' .. row.id .. '?', {{ text = 'Yes', buttonCallback = function() local mod = modules.game_bugreport if not mod then return end mod.removeRow(bugViewList, row) mod.setRemoveConfirmWindowLock(false) end }}, 1, 'No', function() local mod = modules.game_bugreport if not mod then return end mod.setRemoveConfirmWindowLock(false) end, nil)
    setRemoveConfirmWindowLock(true)
  end
end

function bugViewSetReportState()
  if not g_game.canPerformGameAction() or not getWindowState() then return end

  local err
  local row = bugViewList:getFocusedChild()
  if not row then
    err = 'No row selected.'
  elseif viewState == 255 then
    err = 'Is not possible to set for this state.'
  end
  if err then
    displayErrorBox('Error', err)
    return
  end

  -- Ignored fields
  local _bugCategory = 255
  local _position    = {}
  local _comment     = ''
  local _page        = 65535
  local _rowsPerPage = 65535

  row.state = viewState
  sendUpdateState(row)

  updateReportRowTitle(row)
  listOnChildFocusChange(bugViewList, bugViewList:getFocusedChild())
end

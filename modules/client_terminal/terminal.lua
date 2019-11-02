-- configs
local LogColors = { [LogDebug] = 'pink',
                    [LogInfo] = 'white',
                    [LogWarning] = 'yellow',
                    [LogError] = 'red' }

local oldenv = getfenv(0)
setfenv(0, _G)
_G.commandEnv = runinsandbox('commands')
setfenv(0, oldenv)

-- private variables
local terminalWindow
--local terminalButton
local logLocked = false
local commandTextEdit
local terminalBuffer
local currentMessageIndex = 0
local poped = false
local oldPos
local oldSize
local firstShown = false
local flushEvent
local cachedLines = {}
local disabled = false
local allLines = {}

local terminalLogFile = nil
local terminalLog = {}
local MAX_LOGLINES = 500
local MAX_LINES = 128

-- private functions
local function navigateCommand(step)
  if commandTextEdit:isMultiline() then
    return
  end

  local numCommands = #terminalLog
  if numCommands > 0 then
    currentMessageIndex = math.min(math.max(currentMessageIndex + step, 0), numCommands)
    if currentMessageIndex > 0 then
      local command = terminalLog[numCommands - currentMessageIndex + 1]
      commandTextEdit:setText(command)
      commandTextEdit:setCursorPos(-1)
    else
      commandTextEdit:clearText()
    end
  end
end

local function completeCommand()
  local cursorPos = commandTextEdit:getCursorPos()
  if cursorPos == 0 then return end

  local commandBegin = commandTextEdit:getText():sub(1, cursorPos)
  local possibleCommands = {}

  -- create a list containing all globals
  local allVars = table.copy(_G)
  table.merge(allVars, commandEnv)

  -- match commands
  for k,v in pairs(allVars) do
    if k:sub(1, cursorPos) == commandBegin then
      table.insert(possibleCommands, k)
    end
  end

  -- complete command with one match
  if #possibleCommands == 1 then
    commandTextEdit:setText(possibleCommands[1])
    commandTextEdit:setCursorPos(-1)
  -- show command matches
  elseif #possibleCommands > 0 then
    print('>> ' .. commandBegin)

    -- expand command
    local expandedComplete = commandBegin
    local done = false
    while not done do
      cursorPos = #commandBegin+1
      if #possibleCommands[1] < cursorPos then
        break
      end
      expandedComplete = commandBegin .. possibleCommands[1]:sub(cursorPos, cursorPos)
      for i,v in ipairs(possibleCommands) do
        if v:sub(1, #expandedComplete) ~= expandedComplete then
          done = true
        end
      end
      if not done then
        commandBegin = expandedComplete
      end
    end
    commandTextEdit:setText(commandBegin)
      commandTextEdit:setCursorPos(-1)

    for i,v in ipairs(possibleCommands) do
      print(v)
    end
  end
end

local function doCommand(textWidget)
  local currentCommand = textWidget:getText()
  executeCommand(currentCommand)
  textWidget:clearText()
  return true
end

local function addNewline(textWidget)
  if not textWidget:isOn() then
    textWidget:setOn(true)
  end
  textWidget:appendText('\n')
end

local function onCommandChange(textWidget, newText, oldText)
  local _, newLineCount = string.gsub(newText, '\n', '\n')
  textWidget:setHeight((newLineCount + 1) * textWidget.baseHeight)

  if newLineCount == 0 and textWidget:isOn() then
    textWidget:setOn(false)
  end
end

local function onLog(level, message, time)
  if disabled then return end
  -- avoid logging while reporting logs (would cause a infinite loop)
  if logLocked then return end

  logLocked = true
  addLine(message, LogColors[level])
  logLocked = false
end

-- public functions
function init()
  terminalWindow = g_ui.displayUI('terminal')
  terminalWindow:setVisible(false)

  terminalWindow.onDoubleClick = popWindow

  -- terminalButton = modules.client_topmenu.addLeftButton('terminalButton', tr('Terminal') .. ' (Ctrl+Shift+T)', '/images/topbuttons/terminal', toggle)
  g_keyboard.bindKeyDown('Ctrl+Shift+T', toggle)

  commandTextEdit = terminalWindow:getChildById('commandTextEdit')
  commandTextEdit:setHeight(commandTextEdit.baseHeight)
  connect(commandTextEdit, {onTextChange = onCommandChange})
  g_keyboard.bindKeyPress('Up', function() navigateCommand(1) end, commandTextEdit)
  g_keyboard.bindKeyPress('Down', function() navigateCommand(-1) end, commandTextEdit)
  g_keyboard.bindKeyPress('Ctrl+C',
    function()
      if commandTextEdit:hasSelection() or not terminalSelectText:hasSelection() then return false end
      g_window.setClipboardText(terminalSelectText:getSelection())
    return true
    end, commandTextEdit)
  g_keyboard.bindKeyDown('Tab', completeCommand, commandTextEdit)
  g_keyboard.bindKeyPress('Shift+Enter', addNewline, commandTextEdit)
  g_keyboard.bindKeyDown('Enter', doCommand, commandTextEdit)
  g_keyboard.bindKeyDown('Escape', hide, terminalWindow)

  terminalBuffer = terminalWindow:getChildById('terminalBuffer')
  terminalSelectText = terminalWindow:getChildById('terminalSelectText')
  terminalSelectText.onDoubleClick = popWindow
  terminalSelectText.onMouseWheel = function(a,b,c) terminalBuffer:onMouseWheel(b,c) end
  terminalBuffer.onScrollChange = function(self, value) terminalSelectText:setTextVirtualOffset(value) end

  g_logger.setOnLog(onLog)

  if not g_app.isRunning() then
    g_logger.fireOldMessages()
  elseif _G.terminalLines then
    for _,line in pairs(_G.terminalLines) do
      addLine(line.text, line.color)
    end
  end

  -- Create or load terminal log file
  terminalLogFile = g_configs.create('/log.terminal.otml')

  -- Load kept terminal log after login
  terminalLog = terminalLogFile:getList('terminalLog') or {}
end

function terminate()
  -- Keep terminal log after logout
  terminalLogFile:setList('terminalLog', terminalLog)
  terminalLogFile:save()

  -- Clear terminal log file
  terminalLogFile = nil

  removeEvent(flushEvent)

  if poped then
    oldPos = terminalWindow:getPosition()
    oldSize = terminalWindow:getSize()
  end
  local settings = {
    size = oldSize,
    pos = oldPos,
    poped = poped
  }
  g_settings.setNode('terminal-window', settings)

  g_keyboard.unbindKeyDown('Ctrl+Shift+T')
  g_logger.setOnLog(nil)
  terminalWindow:destroy()
  --terminalButton:destroy()
  commandEnv = nil
  _G.terminalLines = allLines
end

--[[
function hideButton()
  terminalButton:hide()
end
]]

function popWindow()
  if poped then
    oldPos = terminalWindow:getPosition()
    oldSize = terminalWindow:getSize()
    terminalWindow:fill('parent')
    terminalWindow:setOn(false)
    terminalWindow:getChildById('bottomResizeBorder'):disable()
    terminalWindow:getChildById('rightResizeBorder'):disable()
    terminalWindow:getChildById('titleBar'):hide()
    terminalWindow:getChildById('terminalScroll'):setMarginTop(0)
    terminalWindow:getChildById('terminalScroll'):setMarginBottom(0)
    terminalWindow:getChildById('terminalScroll'):setMarginRight(0)
    poped = false
  else
    terminalWindow:breakAnchors()
    terminalWindow:setOn(true)
    local size = oldSize or { width = g_window.getWidth()/2.5, height = g_window.getHeight()/4 }
    terminalWindow:setSize(size)
    local pos = oldPos or { x = 0, y = g_window.getHeight() }
    terminalWindow:setPosition(pos)
    terminalWindow:getChildById('bottomResizeBorder'):enable()
    terminalWindow:getChildById('rightResizeBorder'):enable()
    terminalWindow:getChildById('titleBar'):show()
    terminalWindow:getChildById('terminalScroll'):setMarginTop(18)
    terminalWindow:getChildById('terminalScroll'):setMarginBottom(1)
    terminalWindow:getChildById('terminalScroll'):setMarginRight(1)
    terminalWindow:bindRectToParent()
    poped = true
  end
end

function toggle()
  if terminalWindow:isVisible() then
    hide()
  else
    if not firstShown then
      local settings = g_settings.getNode('terminal-window')
      if settings then
        if settings.size then oldSize = settings.size end
        if settings.pos then oldPos = settings.pos end
        if settings.poped then popWindow() end
      end
      firstShown = true
    end
    show()
  end
end

function show()
  if g_game.isOnline() and g_game.getAccountType() > ACCOUNT_TYPE_NORMAL then
    commandTextEdit:setEnabled(true)
  end
  terminalWindow:show()
  terminalWindow:raise()
  terminalWindow:focus()
  commandTextEdit:focus()
end

function hide()
  terminalWindow:hide()
end

function disable()
  --terminalButton:hide()
  g_keyboard.unbindKeyDown('Ctrl+Shift+T')
  disabled = true
end

function flushLines()
  local numLines = terminalBuffer:getChildCount() + #cachedLines
  local fulltext = terminalSelectText:getText()

  for _,line in pairs(cachedLines) do
    -- delete old lines if needed
    if numLines > MAX_LINES then
      local firstChild = terminalBuffer:getChildByIndex(1)
      if firstChild then
        local len = #firstChild:getText()
        firstChild:destroy()
        table.remove(allLines, 1)
        fulltext = string.sub(fulltext, len)
      end
    end

    local label = g_ui.createWidget('TerminalLabel', terminalBuffer)
    label:setId('terminalLabel' .. numLines)
    label:setText(line.text)
    label:setColor(line.color)

    table.insert(allLines, {text=line.text,color=line.color})

    fulltext = fulltext .. '\n' .. line.text
  end

  terminalSelectText:setText(fulltext)

  cachedLines = {}
  removeEvent(flushEvent)
  flushEvent = nil
end

function addLine(text, color)
  if not flushEvent then
    flushEvent = scheduleEvent(flushLines, 10)
  end

  text = string.gsub(text, '\t', '    ')
  table.insert(cachedLines, {text=text, color=color})
end

function executeCommand(command)
  if command == nil or #string.gsub(command, '\n', '') == 0 then return end

  -- add command line
  addLine("> " .. command, "#ffffff")

  -- Add new command to console log
  currentMessageIndex = 0
  if #terminalLog == 0 or terminalLog[#terminalLog] ~= command then
    table.insert(terminalLog, command)
    if #terminalLog > MAX_LOGLINES then
      table.remove(terminalLog, 1)
    end
  end

  -- detect and convert commands with simple syntax
  local realCommand
  if string.sub(command, 1, 1) == '=' then
    realCommand = 'print(' .. string.sub(command,2) .. ')'
  else
    realCommand = command
  end

  local func, err = loadstring(realCommand, "@")

  -- detect terminal commands
  if not func then
    local command_name = command:match('^([%w_]+)[%s]*.*')
    if command_name then
      local args = string.split(command:match('^[%w_]+[%s]*(.*)'), ' ')
      if commandEnv[command_name] and type(commandEnv[command_name]) == 'function' then
        func = function() modules.client_terminal.commandEnv[command_name](unpack(args)) end
      elseif command_name == command then
        addLine('ERROR: command not found', 'red')
        return
      end
    end
  end

  -- check for syntax errors
  if not func then
    addLine('ERROR: incorrect lua syntax: ' .. err:sub(5), 'red')
    return
  end

  -- setup func env to commandEnv
  setfenv(func, commandEnv)

  -- execute the command
  local ok, ret = pcall(func)
  if ok then
    -- if the command returned a value, print it
    if ret then addLine(ret, 'white') end
  else
    addLine('ERROR: command failed: ' .. ret, 'red')
  end
end

function clear()
  terminalBuffer:destroyChildren()
  terminalSelectText:setText('')
  cachedLines = {}
  allLines = {}
end

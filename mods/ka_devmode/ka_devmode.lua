local localIp  = '127.0.0.1'
local serverIp = 'kingdomageonline.com'

local devModeWindow
local devModeEnabled = 0
local function toggleWindow()
  if not devModeWindow then return end
  devModeEnabled = (devModeEnabled + 1) % 2
  if devModeEnabled == 1 then
    devModeWindow:show()
  else
    devModeWindow:hide()
  end
end

function init()
  devModeWindow = g_ui.displayUI('ka_devmode')
  devModeWindow:setOn(true)

  devModeWindow:move(200, 200)
  devModeWindow:breakAnchors()
  devModeWindow:hide()
  g_keyboard.bindKeyDown('Ctrl+Alt+D', toggleWindow)

  local localServerCheckBox = devModeWindow:getChildById('localServerCheckBox')
  if localServerCheckBox then
    localServerCheckBox.onClick = function (widget, pos) toggleOption(widget, function() EnterGame.setUniqueServer(localIp, 7171, 1099) end, function() EnterGame.setUniqueServer(serverIp, 7171, 1099) end) end
  end
end

function terminate()
  g_keyboard.unbindKeyDown('Ctrl+Alt+D')
  if devModeWindow then
    devModeWindow:destroy()
    devModeWindow = nil
  end

  EnterGame.setUniqueServer(serverIp, 7171, 1099)
end

function toggleOption(button, funcionEnable, functionDisable)
  functionDisable = functionDisable or funcionEnable
  button:setChecked(not button:isChecked())
  if button:isChecked() then
    funcionEnable()
  else
    functionDisable()
  end
end

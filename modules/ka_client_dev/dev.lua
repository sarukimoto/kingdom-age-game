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

local function checkServerConfig(localServerCheckBox, devServerCheckBox)
  if not localServerCheckBox or not devServerCheckBox then return end

  local enable = localServerCheckBox:isChecked() and devServerCheckBox:isChecked()
  localServerCheckBox:setOn(enable)
  devServerCheckBox:setOn(enable)
end

function init()
  devModeWindow = g_ui.displayUI('dev')
  devModeWindow:setOn(true)

  devModeWindow:move(200, 200)
  devModeWindow:breakAnchors()
  devModeWindow:hide()
  g_keyboard.bindKeyDown('Ctrl+Alt+D', toggleWindow)

  local localServerCheckBox = devModeWindow:getChildById('localServerCheckBox')
  local devServerCheckBox   = devModeWindow:getChildById('devServerCheckBox')

  if localServerCheckBox then
    localServerCheckBox.onClick =
    function (widget, pos)
      toggleOption(widget,
        function() EnterGame.setUniqueServer(localIp, g_settings.get('port'), 1099) checkServerConfig(localServerCheckBox, devServerCheckBox) end,
        function() EnterGame.setUniqueServer(serverIp, g_settings.get('port'), 1099) checkServerConfig(localServerCheckBox, devServerCheckBox) end)
    end
  end

  if devServerCheckBox then
    devServerCheckBox.onClick =
    function (widget, pos)
      toggleOption(widget,
        function() EnterGame.setUniqueServer(g_settings.get('host'), 7175, 1099) checkServerConfig(localServerCheckBox, devServerCheckBox) end,
        function() EnterGame.setUniqueServer(g_settings.get('host'), 7171, 1099) checkServerConfig(localServerCheckBox, devServerCheckBox) end)
    end
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

function toggleOption(button, functionEnable, functionDisable)
  functionDisable = functionDisable or functionEnable
  button:setChecked(not button:isChecked())
  if button:isChecked() then
    functionEnable()
  else
    functionDisable()
  end
end

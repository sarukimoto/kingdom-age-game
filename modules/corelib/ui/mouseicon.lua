g_mouseicon = {}

-- private variables
local fadeOutTime = 50
local defaultSize = { width = 32, height = 32 }
local defaultIconOpacity = 30 -- %
local defaultItemIconOpacity = 30 -- %
local mouseIcon

-- private functions
local function moveIcon(firstDisplay)
  local widget = g_game.getWidgetByPos()
  if not firstDisplay then
    if not mouseIcon:isVisible() then
      return
    end

    if not widget then -- No widget found (e.g., client background area)
      g_mouseicon.hide()
      return
    end
  end

  local pos        = g_window.getMousePosition()
  local windowSize = g_window.getSize()

  local width  = mouseIcon:getWidth()
  local xdif   = windowSize.width - (pos.x + width)
  local height = mouseIcon:getHeight()
  local ydif   = windowSize.height - (pos.y + height)
  pos.x        = xdif <= 10 and pos.x - width - 10 or pos.x + 11
  pos.y        = ydif <= 10 and pos.y - height or pos.y
  mouseIcon:setPosition(pos)
end

local function onWidgetMouseRelease(widget, mousePos, mouseButton)
  g_mouseicon.hide()
end

-- public functions
function g_mouseicon.init()
  connect(UIWidget, {
    onMouseRelease = onWidgetMouseRelease
  })

  addEvent(function()
    mouseIcon = g_ui.createWidget('UIItem', rootWidget)
    mouseIcon:setId('mouseIcon')
    mouseIcon:setPhantom(true)
    mouseIcon:hide()
    mouseIcon.onMouseMove = function() moveIcon() end

    -- For item only
    mouseIcon:setVirtual(true)
    mouseIcon:setFont('verdana-11px-rounded')
    mouseIcon:setBorderColor('white')
    mouseIcon:setColor('white')
  end)
end

function g_mouseicon.terminate()
  disconnect(UIWidget, {
    onMouseRelease = onWidgetMouseRelease
  })

  mouseIcon:destroy()
  mouseIcon = nil

  g_mouseicon = nil
end

function g_mouseicon.display(filePath, opacity, size, subType) -- (filePath[, opacity = defaultIconOpacity[, size = defaultSize[, subType = 1]]])
  if tonumber(filePath) then
    mouseIcon:setIcon('')
    mouseIcon:setItemId(filePath)
    mouseIcon:setItemSubType(subType or 1)
  else
    mouseIcon:setIcon(resolvepath(filePath))
    mouseIcon:clearItem()
  end
  mouseIcon:setSize(size or defaultSize)
  mouseIcon:setIconSize(size or defaultSize)
  mouseIcon:setOpacity(opacity or defaultIconOpacity / 100)

  mouseIcon:raise()
  mouseIcon:show()
  mouseIcon:enable()

  moveIcon(true)
end

function g_mouseicon.displayItem(item, opacity, size, subType) -- (item[, opacity = option or defaultItemIconOpacity[, size = defaultSize[, subType = 1]]])
  if modules.client_options and not modules.client_options.getOption('showMouseItemIcon') then
    return
  end
  g_mouseicon.display(item:getId(), opacity or (modules.client_options and modules.client_options.getOption('mouseItemIconOpacity') or defaultItemIconOpacity) / 100, size, subType or item:isStackable() and (g_keyboard and g_keyboard.isShiftPressed() and 1 or item:getCount()) or item:getSubType())
end

function g_mouseicon.hide()
  g_effects.cancelFade(mouseIcon) -- Because g_mouseicon.hide() can be called multiple times in a row
  g_effects.fadeOut(mouseIcon, fadeOutTime)
end

g_mouseicon.init()
connect(g_app, { onTerminate = g_mouseicon.terminate })

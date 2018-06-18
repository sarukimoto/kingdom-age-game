-- @docclass
g_tooltip = {}

-- private variables
local fadeInTime = 100
local fadeOutTime = 100
local toolTipLabel
local currentHoveredWidget
local toolTipAddonLabels = {}
local toolTipAddonBackgroundLabel

-- private functions
local function removeToolTipAddonLabels()
  for i = 1, #toolTipAddonLabels do
    if toolTipAddonLabels[i] then
      toolTipAddonLabels[i]:destroy()
    end
    toolTipAddonLabels[i] = nil
  end
  toolTipAddonLabels = {}
end

local function removeTooltip()
  g_effects.cancelFade(toolTipAddonBackgroundLabel)
  toolTipAddonBackgroundLabel:hide()
  for i = 1, #toolTipAddonLabels do
    if toolTipAddonLabels[i] then
      g_effects.cancelFade(toolTipAddonLabels[i])
    end
  end
  removeToolTipAddonLabels()
end

local function moveToolTip(firstDisplay)
  local widget = g_game.getWidgetByPos()
  if not firstDisplay then
    if not toolTipLabel:isVisible() or toolTipLabel:getOpacity() < 0.1 then
      return
    end

    if not widget then -- No widget found (e.g., client background area)
      removeTooltip()
      currentHoveredWidget = nil
      return
    end
  end

  local pos    = g_window.getMousePosition()
  local width  = toolTipLabel:getWidth()
  local height = toolTipLabel:getHeight()
  if widget.tooltipAddons then
    width  = toolTipAddonBackgroundLabel:getWidth()
    height = toolTipAddonBackgroundLabel:getHeight()
  end

  local ydif = g_window.getSize().height - (pos.y + height)
  pos.y = ydif <= 0 and pos.y - height - (widget.tooltipAddons and -6 or 0) or pos.y + (widget.tooltipAddons and 6 or 0)

  local xdif = g_window.getSize().width - (pos.x + width)
  pos.x = xdif <= 0 and pos.x - width - (widget.tooltipAddons and 6 or 10) or pos.x + (widget.tooltipAddons and 15 or 11)

  toolTipLabel:setPosition(pos)
end

local function onWidgetHoverChange(widget, hovered)
  if widget.onTooltipHoverChange then
    widget.onTooltipHoverChange(widget, hovered)
  end

  g_tooltip.widgetHoverChange(widget, hovered)
end

local function onWidgetStyleApply(widget, styleName, styleNode)
  if styleNode.tooltip then
    widget.tooltip = styleNode.tooltip
  end
end

-- public functions
function g_tooltip.init()
  connect(UIWidget, {
    onStyleApply = onWidgetStyleApply,
    onHoverChange = onWidgetHoverChange
  })

  addEvent(function()
    toolTipAddonBackgroundLabel = g_ui.createWidget('UILabel', rootWidget)
    toolTipAddonBackgroundLabel:setId('toolTipAddonBackground')

    toolTipLabel = g_ui.createWidget('UILabel', rootWidget)
    toolTipLabel:setId('toolTip')
    toolTipLabel:setTextAlign(AlignCenter)
    toolTipLabel:hide()
    toolTipLabel.onMouseMove = function() moveToolTip() end
  end)
end

function g_tooltip.terminate()
  disconnect(UIWidget, {
    onStyleApply = onWidgetStyleApply,
    onHoverChange = onWidgetHoverChange
  })

  currentHoveredWidget = nil

  toolTipLabel:destroy()
  toolTipLabel = nil

  toolTipAddonBackgroundLabel:destroy()
  toolTipAddonBackgroundLabel = nil

  removeToolTipAddonLabels()

  g_tooltip = nil
end

function g_tooltip.display(widget)
  if not widget.tooltip and not widget.tooltipAddons or not toolTipLabel then return end

  toolTipLabel:setBackgroundColor('#111111cc')
  toolTipLabel:setText(widget.tooltip or '')
  toolTipLabel:resizeToText()
  if not widget.tooltipAddons then
    toolTipLabel:resize(toolTipLabel:getWidth() + 8, toolTipLabel:getHeight() + 8)
  end
  if not widget.tooltip or widget.tooltip:len() == 0 then
    toolTipLabel:setHeight(0) -- For fix the heightSum
  end
  toolTipLabel:show()
  toolTipLabel:raise()
  toolTipLabel:enable()
  g_effects.fadeIn(toolTipLabel, fadeInTime)

  if widget.tooltipAddons then
    -- Force previous tooltip remove
    g_effects.cancelFade(toolTipAddonBackgroundLabel)
    for i = 1, #toolTipAddonLabels do
      if toolTipAddonLabels[i] then
        g_effects.cancelFade(toolTipAddonLabels[i])
      end
    end
    removeToolTipAddonLabels()

    local higherWidth = toolTipLabel:getWidth()
    local heightSum   = toolTipLabel:getHeight() + toolTipLabel:getMarginTop() + toolTipLabel:getMarginBottom()
    for i = 1, #widget.tooltipAddons do
      toolTipAddonLabels[i] = g_ui.createWidget('Label', rootWidget)
      toolTipAddonLabels[i]:setId(string.format('toolTipAddon_%d', i))
      if widget.tooltipAddons[i].backgroundColor then
        toolTipAddonLabels[i]:setBackgroundColor(widget.tooltipAddons[i].backgroundColor)
      end
      toolTipAddonLabels[i]:addAnchor(AnchorTop, i > 1 and string.format('toolTipAddon_%d', i - 1) or 'toolTip', AnchorBottom)
      toolTipAddonLabels[i]:addAnchor(AnchorHorizontalCenter, 'toolTip', AnchorHorizontalCenter)

      if widget.tooltipAddons[i].text then
        toolTipAddonLabels[i]:setText(widget.tooltipAddons[i].text)
        toolTipAddonLabels[i]:setColor(widget.tooltipAddons[i].color or 'white')
        toolTipAddonLabels[i]:resizeToText()
      elseif widget.tooltipAddons[i].icon then
        g_textures.preload(widget.tooltipAddons[i].icon)
        toolTipAddonLabels[i]:setIcon(widget.tooltipAddons[i].icon)
        if widget.tooltipAddons[i].size then
          toolTipAddonLabels[i]:setSize(widget.tooltipAddons[i].size)
          toolTipAddonLabels[i]:setIconSize(widget.tooltipAddons[i].size)
        end
      end

      toolTipAddonLabels[i]:show()
      toolTipAddonLabels[i]:raise()
      toolTipAddonLabels[i]:enable()

      higherWidth = higherWidth < toolTipAddonLabels[i]:getWidth() and toolTipAddonLabels[i]:getWidth() or higherWidth
      heightSum   = heightSum + toolTipAddonLabels[i]:getHeight() + toolTipAddonLabels[i]:getMarginTop() + toolTipAddonLabels[i]:getMarginBottom()
    end

    -- Background
    toolTipAddonBackgroundLabel:setBackgroundColor(widget.toolTipAddonBackground and widget.toolTipAddonBackground.backgroundColor or '#111111cc')
    toolTipAddonBackgroundLabel:setWidth(higherWidth + 8)
    toolTipAddonBackgroundLabel:setHeight(heightSum + 8)
    toolTipAddonBackgroundLabel:show()
    toolTipAddonBackgroundLabel:enable()
    toolTipAddonBackgroundLabel:addAnchor(AnchorTop, 'toolTip', AnchorTop)
    toolTipAddonBackgroundLabel:addAnchor(AnchorHorizontalCenter, 'toolTip', AnchorHorizontalCenter)
    toolTipAddonBackgroundLabel:setMarginTop(-6) -- Vertical position fix
    if widget.toolTipAddonBackground and widget.toolTipAddonBackground.onAddonBackground then
      widget.toolTipAddonBackground.onAddonBackground(toolTipAddonBackgroundLabel)
    end
    g_effects.fadeIn(toolTipAddonBackgroundLabel, fadeInTime)

    -- Fix size/alignment, and effect
    toolTipLabel:setWidth(higherWidth)
    for i = 1, #widget.tooltipAddons do
      if widget.tooltipAddons[i].text then
        toolTipAddonLabels[i]:setWidth(higherWidth)
        toolTipAddonLabels[i]:setTextAlign(widget.tooltipAddons[i].align or AlignCenter)
      elseif widget.tooltipAddons[i].icon then
        if widget.tooltipAddons[i].align == AlignLeft then
          toolTipAddonLabels[i]:removeAnchor(AnchorHorizontalCenter)
          toolTipAddonLabels[i]:addAnchor(AnchorLeft, 'toolTip', AnchorLeft)
        elseif widget.tooltipAddons[i].align == AlignRight then
          toolTipAddonLabels[i]:removeAnchor(AnchorHorizontalCenter)
          toolTipAddonLabels[i]:addAnchor(AnchorRight, 'toolTip', AnchorRight)
        end
      end

      if widget.tooltipAddons[i].onAddon then
        widget.tooltipAddons[i].onAddon(toolTipAddonLabels[i], i)
      end
      g_effects.fadeIn(toolTipAddonLabels[i], fadeInTime)
    end
  end

  moveToolTip(true)
end

function g_tooltip.hide(widget)
  if widget.tooltip then
    g_effects.fadeOut(toolTipLabel, fadeOutTime)
  end

  if widget.tooltipAddons then
    g_effects.fadeOut(toolTipAddonBackgroundLabel, fadeOutTime)
    for i = 1, #toolTipAddonLabels do
      if toolTipAddonLabels[i] then
        g_effects.fadeOut(toolTipAddonLabels[i], fadeOutTime)
      end
    end
  end
end

function g_tooltip.widgetHoverChange(widget, hovered)
  if hovered then
    if (widget.tooltip or widget.tooltipAddons) and not g_mouse.isPressed() then
      g_tooltip.display(widget)
      currentHoveredWidget = widget
    end
  else
    if widget == currentHoveredWidget then
      g_tooltip.hide(widget)
      currentHoveredWidget = nil
    end
  end
end


-- @docclass UIWidget @{

--[[
  Usage

  Simple:
    Lua:
      widget:setTooltip('Title message.')
    Otui:
      UIWidget
        !tooltip: 'Title message.'

  Custom:
    Lua:
      widget:setTooltip({ { text = 'Title message.' }, { icon = '/images/topbuttons/battle', size = { width = 20, height = 20 }, align = AlignRight, onAddon = function(widget, index) print_r(widget:getSize(), index) end }, { text = 'Left', backgroundColor = '#00ff0077', color = 'red', align = AlignLeft }, { text = 'Right', align = AlignRight } }, { backgroundColor = '#00007777', onAddonBackground = function (widget) print_r(widget:getSize()) end })
    Otui:
      UIWidget
        &tooltipAddons: { { text = 'Title message.' }, { icon = '/images/topbuttons/battle', size = { width = 20, height = 20 }, align = AlignRight, onAddon = function(widget, index) print_r(widget:getSize(), index) end }, { text = 'Left', backgroundColor = '#00ff0077', color = 'red', align = AlignLeft }, { text = 'Right', align = AlignRight } }
        &toolTipAddonBackground: { backgroundColor = '#00007777', onAddonBackground = function (widget) print_r(widget:getSize()) end }
]]

-- UIWidget extensions
function UIWidget:removeTooltip()
  self.tooltip = nil
  self.tooltipAddons = nil
end

function UIWidget:setTooltip(tooltip, toolTipAddonBackground)
  self:removeTooltip()
  if type(tooltip) == "string" then
    self.tooltip = tooltip
  elseif type(tooltip) == "table" then
    self.tooltipAddons = tooltip
    self.toolTipAddonBackground = toolTipAddonBackground
  end
end

function UIWidget:getTooltip()
  return self.tooltip
end

function UIWidget:getTooltipAddons()
  return self.tooltipAddons
end

-- @}

g_tooltip.init()
connect(g_app, { onTerminate = g_tooltip.terminate })

-- @docclass
g_tooltip = {}

-- private variables
local fadeInTime = 100
local fadeOutTime = 100
local toolTipLabel
local currentHoveredWidget
local toolTipAddonLabels = {}
local toolTipAddonGroupLabels = {} -- Rows background
local toolTipAddonsBackgroundLabel
local alignToAnchor = {
  [AlignLeft]   = AnchorLeft,
  [AlignRight]  = AnchorRight,
  [AlignCenter] = AnchorHorizontalCenter
}

-- private functions
local function removeToolTipAddonLabels()
  for i = 1, #toolTipAddonLabels do
    for j = 1, #toolTipAddonLabels[i] do
      toolTipAddonLabels[i][j]:destroy()
    end
    toolTipAddonGroupLabels[i]:destroy()
  end
  toolTipAddonLabels = {}
  toolTipAddonGroupLabels = {}
end

local function removeTooltip()
  g_effects.cancelFade(toolTipAddonsBackgroundLabel)
  toolTipAddonsBackgroundLabel:hide()
  for i = 1, #toolTipAddonLabels do
    for j = 1, #toolTipAddonLabels[i] do
      g_effects.cancelFade(toolTipAddonLabels[i][j])
    end
    g_effects.cancelFade(toolTipAddonGroupLabels[i])
  end
  removeToolTipAddonLabels()
end

local function moveToolTip(firstDisplay)
  if not firstDisplay and (not toolTipLabel:isVisible() or toolTipLabel:getOpacity() < 0.1) then
    return
  end

  local pos        = g_window.getMousePosition()
  local windowSize = g_window.getSize()
  local labelSize  = toolTipLabel:getSize()
  local hasAddons  = widget and widget.tooltipAddons or false

  if hasAddons then
    labelSize = toolTipAddonsBackgroundLabel:getSize()
  end

  pos.x = pos.x + 1
  pos.y = pos.y + 1

  if windowSize.width - (pos.x + labelSize.width) < 10 then
    if hasAddons then
      pos.x = pos.x - labelSize.width + 1
    else
      pos.x = pos.x - labelSize.width - 3
    end
  else
    if hasAddons then
      pos.x = pos.x + 14
    else
      pos.x = pos.x + 10
    end
  end

  if windowSize.height - (pos.y + labelSize.height) < 10 then
    if hasAddons then
      pos.y = pos.y - labelSize.height + 3
    else
      pos.y = pos.y - labelSize.height - 3
    end
  else
    if hasAddons then
      pos.y = pos.y + 16
    else
      pos.y = pos.y + 10
    end
  end

  toolTipLabel:setPosition(pos)
end

local function onWidgetStyleApply(widget, styleName, styleNode)
  if styleNode.tooltip then
    widget.tooltip = styleNode.tooltip
  end
end

local function onWidgetHoverChange(widget, hovered)
  if widget.onTooltipHoverChange and not widget.onTooltipHoverChange(widget, hovered) then
    return
  end

  g_tooltip.widgetHoverChange(widget, hovered)
end

-- public functions
function g_tooltip.init()
  connect(UIWidget, {
    onStyleApply = onWidgetStyleApply,
    onHoverChange = onWidgetHoverChange
  })

  addEvent(function()
    toolTipAddonsBackgroundLabel = g_ui.createWidget('UILabel', rootWidget)
    toolTipAddonsBackgroundLabel:setId('toolTipAddonsBackground')

    toolTipLabel = g_ui.createWidget('UILabel', rootWidget)
    toolTipLabel:setId('toolTip')
    toolTipLabel:setTextAlign(AlignCenter)
    toolTipLabel:hide()
  end)
end

function g_tooltip.terminate()
  disconnect(UIWidget, {
    onStyleApply = onWidgetStyleApply,
    onHoverChange = onWidgetHoverChange
  })

  removeTooltip()

  currentHoveredWidget = nil

  toolTipLabel:destroy()
  toolTipLabel = nil

  toolTipAddonsBackgroundLabel:destroy()
  toolTipAddonsBackgroundLabel = nil

  g_tooltip = nil
end

function g_tooltip.display(widget)
  if not widget.tooltip and not widget.tooltipAddons or not toolTipLabel then return end
  currentHoveredWidget = widget

  toolTipLabel:setBackgroundColor('#111111cc')
  toolTipLabel:setText(widget.tooltip or '')
  toolTipLabel:resizeToText()
  if not widget.tooltipAddons then
    toolTipLabel:resize(toolTipLabel:getWidth() + 8, toolTipLabel:getHeight() + 8)
  end
  if not widget.tooltip or widget.tooltip:len() == 0 then
    toolTipLabel:setHeight(0) -- For fix the heightTotalSum
  end
  toolTipLabel:raise()
  toolTipLabel:show()
  toolTipLabel:enable()
  g_effects.fadeIn(toolTipLabel, fadeInTime)

  if widget.tooltipAddons then
    -- Force previous tooltip remove
    g_effects.cancelFade(toolTipAddonsBackgroundLabel)
    for i = 1, #toolTipAddonLabels do
      for j = 1, #toolTipAddonLabels[i] do
        g_effects.cancelFade(toolTipAddonLabels[i][j])
      end
      g_effects.cancelFade(toolTipAddonGroupLabels[i])
    end
    removeToolTipAddonLabels()

    local higherWidth    = 0
    local heightTotalSum = 0

    toolTipAddonsBackgroundLabel:raise()

    -- Group
    --[[
      Options:
      - backgroundColor
    ]]
    for i = 1, #widget.tooltipAddons do
      local toolTipAddonGroupLabelId = string.format('toolTipAddonGroupLabels_%d', i)
      toolTipAddonGroupLabels[i] = g_ui.createWidget('UILabel', rootWidget)
      toolTipAddonGroupLabels[i]:setId(toolTipAddonGroupLabelId)
      toolTipAddonGroupLabels[i]:addAnchor(AnchorTop, i < 2 and 'toolTipAddonsBackground' or string.format('toolTipAddonGroupLabels_%d', i - 1), i < 2 and AnchorTop or AnchorBottom)
      if i == 1 then
        toolTipAddonGroupLabels[i]:setMarginTop(4)
      end
      toolTipAddonGroupLabels[i]:addAnchor(AnchorLeft, 'toolTipAddonsBackground', AnchorLeft)
      toolTipAddonGroupLabels[i]:setMarginLeft(4)
      toolTipAddonGroupLabels[i]:addAnchor(AnchorRight, 'toolTipAddonsBackground', AnchorRight)
      toolTipAddonGroupLabels[i]:setMarginRight(4)
      if i == #widget.tooltipAddons then
        toolTipAddonGroupLabels[i]:addAnchor(AnchorBottom, 'toolTipAddonsBackground', AnchorBottom)
        toolTipAddonGroupLabels[i]:setMarginBottom(4)
      end
      if widget.tooltipAddons[i].backgroundColor then
        toolTipAddonGroupLabels[i]:setBackgroundColor(widget.tooltipAddons[i].backgroundColor)
      end
      if widget.tooltipAddons[i].backgroundIcon then
        toolTipAddonGroupLabels[i]:setIcon(resolvepath(widget.tooltipAddons[i].backgroundIcon))
        if widget.tooltipAddons[i].backgroundIconSize then
          toolTipAddonGroupLabels[i]:setSize(widget.tooltipAddons[i].backgroundIconSize)
          toolTipAddonGroupLabels[i]:setIconSize(widget.tooltipAddons[i].backgroundIconSize)
        end
      elseif widget.tooltipAddons[i].backgroundImage then
        if not widget.tooltipAddons[i].backgroundImageSize then
          -- Make able to get height when change the image source
          toolTipAddonGroupLabels[i]:setWidth(0)
          toolTipAddonGroupLabels[i]:setHeight(0)
        end
        toolTipAddonGroupLabels[i]:setImageSource(resolvepath(widget.tooltipAddons[i].backgroundImage))
        if widget.tooltipAddons[i].backgroundImageSize then
          toolTipAddonGroupLabels[i]:setSize(widget.tooltipAddons[i].backgroundImageSize)
          toolTipAddonGroupLabels[i]:setImageSize(widget.tooltipAddons[i].backgroundImageSize)
        end
      end
      if widget.tooltipAddons[i].onGroupBackground then
        widget.tooltipAddons[i].onGroupBackground(toolTipAddonGroupLabels[i], i)
      end

      toolTipAddonGroupLabels[i]:raise()
      toolTipAddonGroupLabels[i]:show()
      toolTipAddonGroupLabels[i]:enable()

      -- Addons
      --[[
        Options:
        - backgroundColor
        - text
        - color
        - align (for text and icon)
        - icon
        - size (for icon)
        - onAddon(group, addon, i, j)
      ]]
      local addonsWidthSum = 0
      local higherHeight   = 0
      toolTipAddonLabels[i] = {}
      for j = 1, #widget.tooltipAddons[i] do
        toolTipAddonLabels[i][j] = g_ui.createWidget('UILabel', rootWidget)
        local addon = toolTipAddonLabels[i][j]
        addon:setId(string.format('toolTipAddon_%d_%d', i, j))

        addon:addAnchor(AnchorTop, toolTipAddonGroupLabelId, AnchorTop)
        addon:addAnchor(AnchorBottom, toolTipAddonGroupLabelId, AnchorBottom)
        addon:addAnchor(AnchorLeft, j < 2 and toolTipAddonGroupLabelId or string.format('toolTipAddon_%d_%d', i, j - 1), j < 2 and AnchorLeft or AnchorRight)
        if j == #widget.tooltipAddons[i] then addon:addAnchor(AnchorRight, toolTipAddonGroupLabelId, AnchorRight) end

        if widget.tooltipAddons[i][j].backgroundColor then
          addon:setBackgroundColor(widget.tooltipAddons[i][j].backgroundColor)
        end
        if widget.tooltipAddons[i][j].text then
          addon:setText(widget.tooltipAddons[i][j].text)
          addon:setColor(widget.tooltipAddons[i][j].color or 'white')
          addon:resizeToText()
          addon:setTextAlign(widget.tooltipAddons[i][j].align or AlignCenter)
        elseif widget.tooltipAddons[i][j].icon then
          addon:setIcon(resolvepath(widget.tooltipAddons[i][j].icon))
          if widget.tooltipAddons[i][j].size then
            addon:setSize(widget.tooltipAddons[i][j].size)
            addon:setIconSize(widget.tooltipAddons[i][j].size)
          end

          -- Icon align only if has the icon only on group
          if #widget.tooltipAddons[i] == 1 then
            addon:removeAnchor(AnchorLeft)
            addon:removeAnchor(AnchorRight)
            local align = alignToAnchor[widget.tooltipAddons[i][j].align or AlignCenter]
            addon:addAnchor(align, toolTipAddonGroupLabelId, align)
          end
        elseif widget.tooltipAddons[i][j].image then
          if not widget.tooltipAddons[i][j].size then
            -- Make able to get height when change the image source
            addon:setWidth(0)
            addon:setHeight(0)
          end
          addon:setImageSource(resolvepath(widget.tooltipAddons[i][j].image))
          if widget.tooltipAddons[i][j].size then
            addon:setSize(widget.tooltipAddons[i][j].size)
            addon:setImageSize(widget.tooltipAddons[i][j].size)
          end
        end

        addon:raise()
        addon:show()
        addon:enable()
        g_effects.fadeIn(addon, fadeInTime)

        addonsWidthSum = addonsWidthSum + addon:getWidth()
        local height   = (widget.tooltipAddons[i][j].icon and addon:getIconHeight() or addon:getHeight())
        higherHeight   = higherHeight > height and higherHeight or height
      end

      toolTipAddonGroupLabels[i]:resize(addonsWidthSum, higherHeight)

      higherWidth    = higherWidth > addonsWidthSum and higherWidth or addonsWidthSum
      heightTotalSum = heightTotalSum + higherHeight
    end

    toolTipLabel:setWidth(higherWidth)

    -- Background
    --[[
      Options:
      - backgroundColor
      - onAddonsBackground
    ]]
    toolTipAddonsBackgroundLabel:setBackgroundColor(widget.toolTipAddonsBackground and widget.toolTipAddonsBackground.backgroundColor or '#111111cc')
    toolTipAddonsBackgroundLabel:setWidth(higherWidth + 8)
    toolTipAddonsBackgroundLabel:setHeight(heightTotalSum + 8)
    toolTipAddonsBackgroundLabel:show()
    toolTipAddonsBackgroundLabel:enable()
    toolTipAddonsBackgroundLabel:addAnchor(AnchorTop, 'toolTip', AnchorTop)
    toolTipAddonsBackgroundLabel:addAnchor(AnchorHorizontalCenter, 'toolTip', AnchorHorizontalCenter)
    if widget.toolTipAddonsBackground and widget.toolTipAddonsBackground.onAddonsBackground then
      widget.toolTipAddonsBackground.onAddonsBackground(toolTipAddonsBackgroundLabel)
    end
    g_effects.fadeIn(toolTipAddonsBackgroundLabel, fadeInTime)

    for i = 1, #widget.tooltipAddons do
      for j = 1, #widget.tooltipAddons[i] do
        if widget.tooltipAddons[i][j].onAddon then
          widget.tooltipAddons[i][j].onAddon(toolTipAddonGroupLabels[i], toolTipAddonLabels[i][j], i, j)
        end
      end
    end
  end

  moveToolTip(true)

  connect(rootWidget, {
    onMouseMove = moveToolTip,
  })
end

function g_tooltip.hide(widget)
  currentHoveredWidget = nil

  g_effects.fadeOut(toolTipLabel, fadeOutTime)

  g_effects.fadeOut(toolTipAddonsBackgroundLabel, fadeOutTime)
  for i = 1, #toolTipAddonLabels do
    for j = 1, #toolTipAddonLabels[i] do
      g_effects.fadeOut(toolTipAddonLabels[i][j], fadeOutTime)
    end
    g_effects.fadeOut(toolTipAddonGroupLabels[i], fadeOutTime)
  end

  disconnect(rootWidget, {
    onMouseMove = moveToolTip,
  })
end

function g_tooltip.widgetHoverChange(widget, hovered)
  if hovered then
    if not g_mouse.isPressed() and widget:hasTooltip() and widget:isVisible() and widget:isEnabled() then
      g_tooltip.display(widget)
    end
  else
    -- if widget == currentHoveredWidget then
      g_tooltip.hide(widget)
    -- end
  end
end

function g_tooltip.widgetUpdateHover(widget, hovered)
  g_tooltip.hide(widget)
  addEvent(function()
    g_tooltip.widgetHoverChange(widget, hovered)
  end)
end

-- Widget callbacks

function g_tooltip.onWidgetMouseRelease(widget, mousePos, mouseButton)
  g_tooltip.widgetUpdateHover(widget, true)
end

function g_tooltip.onWidgetDestroy(widget)
  g_tooltip.hide(widget)
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
      widget:setTooltip({ {{ text = 'First message.\nSecond message.' }, backgroundColor = '#ffff0077', backgroundIcon = '/images/topbuttons/questlog', onGroupBackground = function(group, i) print_r(group:getSize(), i) end}, {{ icon = '/images/topbuttons/battle', size = { width = 20, height = 20 }, align = AlignCenter, onAddon = function(group, addon, i, j) print_r(group:getSize(), addon:getSize(), i, j) end }, { text = 'Duplicated!', color = 'green' }, backgroundColor = '#ff000077'}, {{ text = 'Left', backgroundColor = '#00ff0077', color = 'red', align = AlignLeft }}, {{ text = 'Right', align = AlignRight }} }, { backgroundColor = '#00007777', onAddonsBackground = function (widget) print_r(widget:getSize()) end })
    Otui:
      UIWidget
        &tooltipAddons: { {{ text = 'First message.\nSecond message.' }, backgroundColor = '#ffff0077', backgroundIcon = '/images/topbuttons/questlog', onGroupBackground = function(group, i) print_r(group:getSize(), i) end}, {{ icon = '/images/topbuttons/battle', size = { width = 20, height = 20 }, align = AlignCenter, onAddon = function(group, addon, i, j) print_r(group:getSize(), addon:getSize(), i, j) end }, { text = 'Duplicated!', color = 'green' }, backgroundColor = '#ff000077'}, {{ text = 'Left', backgroundColor = '#00ff0077', color = 'red', align = AlignLeft }}, {{ text = 'Right', align = AlignRight }} }
        &toolTipAddonsBackground: { backgroundColor = '#00007777', onAddonsBackground = function (widget) print_r(widget:getSize()) end }
]]

-- UIWidget extensions
function UIWidget:removeTooltip()
  self.tooltip = nil
  self.tooltipAddons = nil
  self.toolTipAddonsBackground = nil
end

function UIWidget:setTooltip(tooltip, toolTipAddonsBackground)
  self:removeTooltip()
  if type(tooltip) == "string" then
    self.tooltip = tooltip
  elseif type(tooltip) == "table" then
    self.tooltipAddons = tooltip
    self.toolTipAddonsBackground = toolTipAddonsBackground
  end
end

function UIWidget:getTooltip()
  return self.tooltip
end

function UIWidget:getTooltipAddons()
  return self.tooltipAddons
end

function UIWidget:getTooltipAddonsBackground()
  return self.toolTipAddonsBackground
end

function UIWidget:hasTooltip()
  return (self.tooltip or self.tooltipAddons) and true or false
end

-- @}

g_tooltip.init()
connect(g_app, { onTerminate = g_tooltip.terminate })

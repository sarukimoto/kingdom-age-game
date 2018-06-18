-- @docclass
UIProgressBar = extends(UIWidget, "UIProgressBar")

function UIProgressBar.create()
  local progressbar = UIProgressBar.internalCreate()
  progressbar:setFocusable(false)
  progressbar:setOn(true)
  progressbar.min = 0
  progressbar.max = 100
  progressbar.value = 0
  progressbar.bgBorderLeft = 0
  progressbar.bgBorderRight = 0
  progressbar.bgBorderTop = 0
  progressbar.bgBorderBottom = 0
  progressbar.phases = 0
  progressbar.phasesBorderWidth = 1
  progressbar.phasesBorderColor = '#ffffff77'
  return progressbar
end

function UIProgressBar:setMinimum(minimum)
  self.minimum = minimum
  if self.value < minimum then
    self:setValue(minimum)
  end
end

function UIProgressBar:setMaximum(maximum)
  self.maximum = maximum
  if self.value > maximum then
    self:setValue(maximum)
  end
end

function UIProgressBar:setValue(value, minimum, maximum)
  if minimum then
    self:setMinimum(minimum)
  end

  if maximum then
    self:setMaximum(maximum)
  end

  self.value = math.max(math.min(value, self.maximum), self.minimum)
  self:updateBackground()
end

function UIProgressBar:setPercent(percent)
  self:setValue(percent, 0, 100)
end

function UIProgressBar:setPhases(value)
  self.phases = value
  self:updateBackground()
end

function UIProgressBar:setPhasesBorderWidth(value)
  self.phasesBorderWidth = value
  self:updateBackground()
end

function UIProgressBar:setPhasesBorderColor(value)
  self.phasesBorderColor = value
  self:updateBackground()
end

function UIProgressBar:getPercent()
  return self.value
end

function UIProgressBar:getPercentPixels()
  return (self.maximum - self.minimum) / self:getWidth()
end

function UIProgressBar:getProgress()
  if self.minimum == self.maximum then return 1 end
  return (self.value - self.minimum) / (self.maximum - self.minimum)
end

function UIProgressBar:getPhases()
  return self.phases
end

function UIProgressBar:getPhasesBorderWidth()
  return self.phasesBorderWidth
end

function UIProgressBar:getPhasesBorderColor()
  return self.phasesBorderColor
end

function UIProgressBar:updatePhases()
  if self.phases < 2 or self.phasesBorderWidth < 1 then
    return
  end

  -- Remove old phases
  self:destroyChildren()

  local phaseWidth = math.floor((self:getWidth() - (self.bgBorderLeft + self.bgBorderRight)) / self.phases)
  local height = self:getHeight() - (self.bgBorderTop + self.bgBorderBottom)

  for i = 1, self.phases - 1 do
    local rect = { x = 0, y = 0, width = self.phasesBorderWidth, height = height }
    local widget = g_ui.createWidget('UIWidget', self)
    widget:addAnchor(AnchorTop, 'parent', AnchorTop)
    widget:addAnchor(AnchorLeft, 'parent', AnchorLeft)

    widget:setMarginLeft((i * phaseWidth) + self.bgBorderLeft)

    widget:setRect(rect)
    widget:setBackgroundColor(self.phasesBorderColor)
  end
end

function UIProgressBar:updateBackground()
  if self:isOn() then
    local width = math.round(math.max((self:getProgress() * (self:getWidth() - self.bgBorderLeft - self.bgBorderRight)), 1))
    local height = self:getHeight() - self.bgBorderTop - self.bgBorderBottom
    local rect = { x = self.bgBorderLeft, y = self.bgBorderTop, width = width, height = height }
    self:setBackgroundRect(rect)
    self:updatePhases()
  end
end

function UIProgressBar:onSetup()
  self:updateBackground()
end

function UIProgressBar:onStyleApply(name, node)
  for name,value in pairs(node) do
    if name == 'background-border-left' then
      self.bgBorderLeft = tonumber(value)
    elseif name == 'background-border-right' then
      self.bgBorderRight = tonumber(value)
    elseif name == 'background-border-top' then
      self.bgBorderTop = tonumber(value)
    elseif name == 'background-border-bottom' then
      self.bgBorderBottom = tonumber(value)
    elseif name == 'background-border' then
      self.bgBorderLeft = tonumber(value)
      self.bgBorderRight = tonumber(value)
      self.bgBorderTop = tonumber(value)
      self.bgBorderBottom = tonumber(value)
    end
  end
end

function UIProgressBar:onGeometryChange(oldRect, newRect)
  if not self:isOn() then
    self:setHeight(0)
  end
  self:updateBackground()
end

-- @docclass
UIConditionButton = extends(UIWidget, "UIConditionButton")

local barColors = {} -- Must be sorted by percentAbove
table.insert(barColors, { percentAbove = 92, color = '#00BC00' } )
table.insert(barColors, { percentAbove = 60, color = '#50A150' } )
table.insert(barColors, { percentAbove = 30, color = '#A1A100' } )
table.insert(barColors, { percentAbove =  8, color = '#BF0A0A' } )
table.insert(barColors, { percentAbove =  3, color = '#910F0F' } )
table.insert(barColors, { percentAbove = -1, color = '#850C0C' } )

local boostColors = {}
boostColors[0] = '#88888877' -- No boost
boostColors[1] = '#FF754977'
boostColors[2] = '#B770FF77'
boostColors[3] = '#70B8FF77'

function UIConditionButton.create()
  local button = UIConditionButton.internalCreate()
  button:setFocusable(false)
  return button
end

function UIConditionButton:setup(condition)
  self:setId(string.format('ConditionButton(%d,%d)', condition.id, condition.subId))

  local conditionBarWidget = self:getChildById('conditionBar')
  conditionBarWidget:setPhases(condition.turns or 0)
  conditionBarWidget:setPhasesBorderWidth(1)
  conditionBarWidget:setPhasesBorderColor('#00000077')

  if type(condition.remainingTime) == "number" and condition.remainingTime > 0 then
    local timer = {}
    self.clock = Timer.new(timer, condition.remainingTime)
    self.clock.updateTicks = 0.1
    self.clock.onUpdate = function() self:updateConditionClock() end
  end

  self.condition = condition
  self:updateData(condition)
end

function UIConditionButton:updateData(condition)
  -- Setup icon
  local conditionIconWidget = self:getChildById('conditionIcon')
  if condition.powerId then
    conditionIconWidget:setIcon(string.format('/images/game/powers/%d_off', condition.powerId))
    conditionIconWidget:setIconSize({ width = 16, height = 16 })
    conditionIconWidget:setIconOffset({ x = 2, y = 2})
    conditionIconWidget:setBackgroundColor(boostColors[condition.boost])
  else
  -- For debug
    -- conditionIconWidget:setText(string.format('%d,%d', condition.id, condition.subId))
  -- Else, remove the icon
    conditionIconWidget:setWidth(0) -- Comment this line if you want the debug above to work
  end

  if condition.name then
    local conditionAuxiliarWidget = self:getChildById('conditionAuxiliar')
    conditionAuxiliarWidget:setText(string.format('%s', condition.name))
  end

  -- Setup aggressive type
  local conditionTypeWidget = self:getChildById('conditionType')
  conditionTypeWidget:setImageSource(condition.isAggressive and '/images/game/conditions/type_aggressive' or '/images/game/conditions/type_nonaggressive')

  -- Setup clock
  local conditionClockWidget = self:getChildById('conditionClock')
  if condition.remainingTime then
    self.clock:start()
    conditionClockWidget:setText(self.clock:getString())
  end

  self:setTooltipText()
end

function UIConditionButton:updateConditionClock()
  local conditionClockWidget = self:getChildById('conditionClock')
  conditionClockWidget:setText(self.clock:getString())

  local conditionBarWidget = self:getChildById('conditionBar')
  local percent = self.clock:getPercent()
  conditionBarWidget:setPercent(percent)

  for _, v in pairs(barColors) do
    if percent > v.percentAbove then
      conditionBarWidget:setBackgroundColor(v.color)
      return
    end
  end
end

function UIConditionButton:onDestroy()
  self.clock:destroy()
end

function UIConditionButton:setTooltipText()
  local c = self.condition
  local blocks = {}

  local nameBlock = { { text = c.name }, backgroundColor = '#2C374C77' }
  local infoBlock = {
    { text = "Combat: ", align = AlignLeft },
    { icon = string.format('/images/game/conditions/type_%s', c.isAggressive and 'aggressive' or 'nonaggressive'), size = { width = 11, height = 11 }, align = AlignLeft },
    { text = string.format(' %s', c.isAggressive and "Aggressive" or "Non-Aggressive"), align = AlignLeft },
  }
  local attributeStr = ""
  if c.attribute then
    if tonumber(c.offset) > 0  then
      attributeStr = string.format('%s +%s', attributeStr, c.offset)
    end
    if tonumber(c.factor) ~= 1 then
      attributeStr = string.format('%s x%s', attributeStr, c.factor)
    end
  end

  local attributeBlock = { { text = string.format("Attribute: %s%s", ATTRIBUTE_NAMES[c.attribute], attributeStr), align = AlignLeft } }
  local durationBlock = { {  text = "Duration: " .. (self.clock and self.clock:getString()), align = AlignLeft } }
  local powerBlock = {
    { icon = c.powerId and string.format('/images/game/powers/%d_off', c.powerId), size = { width = 20, height = 20 } },
    { text = c.powerId and c.powerName or 'Unknown' },
    backgroundColor = boostColors[c.boost]
  }

  local originBlock = { { text = c.originName }, backgroundColor = '#647D9677' }

  if c.name then
    table.insert(blocks, nameBlock)
  end

  table.insert(blocks, infoBlock)

  if c.attribute then
    table.insert(blocks, attributeBlock)
  end

  if c.remainingTime then
    table.insert(blocks, durationBlock)
  end

  if c.powerId then
    table.insert(blocks, powerBlock)
  end

  if c.originId then
    table.insert(blocks, originBlock)
  end

  self:setTooltip(blocks)
end

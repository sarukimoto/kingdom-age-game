-- @docclass
UIPowerButton = extends(UIWidget, 'UIPowerButton')

-- See uicreaturebutton.lua

local extraLabelColors = {}
extraLabelColors[0] = '#888888' -- No boost
extraLabelColors[1] = '#FF7549'
extraLabelColors[2] = '#B770FF'
extraLabelColors[3] = '#70B8FF'

local POWER_CLASS_ALL       = 0
local POWER_CLASS_OFFENSIVE = 1
local POWER_CLASS_DEFENSIVE = 2
local POWER_CLASS_SUPPORT   = 3
local POWER_CLASS_SPECIAL   = 4
local POWER_CLASS_STRING =
{
  [POWER_CLASS_ALL]       = 'All',
  [POWER_CLASS_OFFENSIVE] = 'Offensive',
  [POWER_CLASS_DEFENSIVE] = 'Defensive',
  [POWER_CLASS_SUPPORT]   = 'Support',
  [POWER_CLASS_SPECIAL]   = 'Special'
}

local VOCATION_LEARNER  = 0
local VOCATION_KNIGHT   = 1
local VOCATION_PALADIN  = 2
local VOCATION_ARCHER   = 3
local VOCATION_ASSASSIN = 4
local VOCATION_WIZARD   = 5
local VOCATION_BARD     = 6
local VOCATION_STRING =
{
  [VOCATION_LEARNER]  = 'Learner',
  [VOCATION_KNIGHT]   = 'Knight',
  [VOCATION_PALADIN]  = 'Paladin',
  [VOCATION_ARCHER]   = 'Archer',
  [VOCATION_ASSASSIN] = 'Assassin',
  [VOCATION_WIZARD]   = 'Wizard',
  [VOCATION_BARD]     = 'Bard',
}

--[[
  Power Object:
  - (number)  id
  - (string)  name
  - (string)  class
  - (array)   mana
  - (array)   vocations
  - (number)  level
  - (boolean) isConstant
  - (boolean) isOffensive
  - (boolean) isPremium
  - (string)  description
  - (string)  descriptionBoostNone
  - (string)  descriptionBoostLow
  - (string)  descriptionBoostHigh
]]
function UIPowerButton.create()
  local button = UIPowerButton.internalCreate()
  button:setFocusable(false)
  button.power = nil
  return button
end

function UIPowerButton:setup(power)
  self:setId(string.format('PowerButton_id%d', power.id))
  self:updateData(power)
end

function UIPowerButton:onDragEnter(mousePos)
  g_mouse.pushCursor('target')
  return true
end

function UIPowerButton:onDragMove(mouseMove, mouseMoved)
  g_mouseicon.display(string.format('/images/game/powers/%d_off', self.power.id))
  return true
end

function UIPowerButton:onDragLeave(droppedWidget, mousePos)
  g_mouseicon.hide()
  g_mouse.popCursor('target')
  return true
end

function UIPowerButton:updateData(power)
  if power then
    self.power = power
  end

  self:setIcon()
  self:setLabel()
  self:setTooltipText()
  self:updateOffensiveIcon()
end

function UIPowerButton:setIcon(id)
  if id then
    local powerWidget = self:getChildById('power')
    powerWidget:setIcon(string.format('/images/game/powers/%d_off', id))
    powerWidget:setIconSize({ width = 34, height = 34 })
    return
  end

  local power = self.power
  self:setIcon(power.id)
end

function UIPowerButton:setLabel(text)
  local labelWidget = self:getChildById('label')
  if text then
    labelWidget:setText(text)
    return
  end

  local power = self.power
  if power.name then
    labelWidget:setText(power.name)
  end
end

function UIPowerButton:setTooltipText(text)
  if text then
    self:setTooltip(text)
    return
  end

  local power  = self.power
  local blocks = {}

  local exhaustTime = power.exhaustTime / 1000

  local isOffensiveBlock          = {{ icon = power.isOffensive and '/images/game/powers/type_aggressive' or '/images/game/powers/type_nonaggressive', size = { width = 11, height = 11 } }}
  local mainInfoBlock             = {{ text = string.format('Name: %s\nClass: %s\nVocations: %s\nLevel: %d\nMana Cost: [%s]\nExhaust Time: %s second%s\nPremium: %s', power.name or 'Unknown', POWER_CLASS_STRING[power.class or 0], self:getVocations(), power.level, self:getMana(), exhaustTime, exhaustTime > 1 and 's' or '', power.isPremium and 'Yes' or 'No'), align = AlignLeft }}
  local descriptionBlock          = power.description and power.description ~= '' and {{ text = string.format('\n%s%s', power.description, power.descriptionBoostNone and power.descriptionBoostNone ~= '' and '\n' or ''), color = '#E6DB74' }} or nil
  local descriptionBoostNoneBlock = power.descriptionBoostNone and power.descriptionBoostNone ~= '' and {{ text = power.descriptionBoostNone, backgroundColor = '#FF754977' }} or nil
  local descriptionBoostLowBlock  = power.descriptionBoostLow and power.descriptionBoostLow ~= '' and {{ text = power.descriptionBoostLow, backgroundColor = '#B770FF77' }} or nil
  local descriptionBoostHighBlock = power.descriptionBoostHigh and power.descriptionBoostHigh ~= '' and {{ text = power.descriptionBoostHigh, backgroundColor = '#70B8FF77' }} or nil

  table.insert(blocks, isOffensiveBlock)
  table.insert(blocks, mainInfoBlock)
  if descriptionBlock then
    table.insert(blocks, descriptionBlock)
  end
  if descriptionBoostNoneBlock then
    table.insert(blocks, descriptionBoostNoneBlock)
  end
  if descriptionBoostLowBlock then
    table.insert(blocks, descriptionBoostLowBlock)
  end
  if descriptionBoostHighBlock then
    table.insert(blocks, descriptionBoostHighBlock)
  end

  self.onTooltipHoverChange = power.onTooltipHoverChange

  self:setTooltip(blocks)
end

function UIPowerButton:updateOffensiveIcon()
  local offensiveWidget = self:getChildById('offensive')
  local labelWidget     = self:getChildById('label')

  local power = self.power
  offensiveWidget:setImageSource(power.isOffensive and '/images/game/powers/type_aggressive' or '/images/game/powers/type_nonaggressive')
end



function UIPowerButton:getMana()
  local power = self.power
  if not power.mana then return '0' end

  return table.concat(power.mana, ' / ')
end

function UIPowerButton:getVocations()
  local power = self.power
  if not power.vocations then return 'Unknown' end

  if #power.vocations == table.size(VOCATION_STRING) then
    return 'All'
  end

  local vocations = {}
  for _, vocationId in ipairs(power.vocations) do
    if VOCATION_STRING[vocationId] then
      table.insert(vocations, VOCATION_STRING[vocationId])
    end
  end
  return table.concat(vocations, ', ')
end

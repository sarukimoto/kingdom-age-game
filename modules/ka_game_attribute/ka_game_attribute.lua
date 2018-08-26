attributeWindow = nil
attributeButton = nil

attackAttributeAddButton    = nil
defenseAttributeAddButton   = nil
willPowerAttributeAddButton = nil
healthAttributeAddButton    = nil
manaAttributeAddButton      = nil
agilityAttributeAddButton   = nil
dodgeAttributeAddButton     = nil
walkingAttributeAddButton   = nil
luckAttributeAddButton      = nil

attackAttributeActLabel    = nil
defenseAttributeActLabel   = nil
willPowerAttributeActLabel = nil
healthAttributeActLabel    = nil
manaAttributeActLabel      = nil
agilityAttributeActLabel   = nil
dodgeAttributeActLabel     = nil
walkingAttributeActLabel   = nil
luckAttributeActLabel      = nil

availablePointsLabel = nil
pointsCostLabel      = nil

ATTRIBUTE_NONE      = 0
ATTRIBUTE_ATTACK    = 1
ATTRIBUTE_DEFENSE   = 2
ATTRIBUTE_WILLPOWER = 3
ATTRIBUTE_HEALTH    = 4
ATTRIBUTE_MANA      = 5
ATTRIBUTE_AGILITY   = 6 -- Limited to 100 points
ATTRIBUTE_DODGE     = 7 -- Limited to 100 points
ATTRIBUTE_WALKING   = 8 -- Limited to 100 points
ATTRIBUTE_LUCK      = 9 -- Limited to 100 points
ATTRIBUTE_FIRST     = ATTRIBUTE_ATTACK
ATTRIBUTE_LAST      = ATTRIBUTE_LUCK

attributeLabel = nil

local attribute_flag_updateList = -1

local _availablePoints = 0

-- Attribute
Attribute = {}

function init()
  g_keyboard.bindKeyDown('Ctrl+Shift+U', toggle)

  attributeButton = modules.client_topmenu.addRightGameToggleButton('attributeButton', tr('Attributes') .. ' (Ctrl+Shift+U)', 'ka_game_attribute', toggle)
  attributeButton:setOn(true)

  attributeWindow = g_ui.loadUI('ka_game_attribute', modules.game_interface.getRightPanel())
  attributeWindow:disableResize()
  attributeWindow:setup()

  attackAttributeAddButton    = attributeWindow:recursiveGetChildById('attackAttributeAddButton')
  defenseAttributeAddButton   = attributeWindow:recursiveGetChildById('defenseAttributeAddButton')
  willPowerAttributeAddButton = attributeWindow:recursiveGetChildById('willPowerAttributeAddButton')
  healthAttributeAddButton    = attributeWindow:recursiveGetChildById('healthAttributeAddButton')
  manaAttributeAddButton      = attributeWindow:recursiveGetChildById('manaAttributeAddButton')
  agilityAttributeAddButton   = attributeWindow:recursiveGetChildById('agilityAttributeAddButton')
  dodgeAttributeAddButton     = attributeWindow:recursiveGetChildById('dodgeAttributeAddButton')
  walkingAttributeAddButton   = attributeWindow:recursiveGetChildById('walkingAttributeAddButton')
  luckAttributeAddButton      = attributeWindow:recursiveGetChildById('luckAttributeAddButton')

  attackAttributeActLabel    = attributeWindow:recursiveGetChildById('attackAttributeActLabel')
  defenseAttributeActLabel   = attributeWindow:recursiveGetChildById('defenseAttributeActLabel')
  willPowerAttributeActLabel = attributeWindow:recursiveGetChildById('willPowerAttributeActLabel')
  healthAttributeActLabel    = attributeWindow:recursiveGetChildById('healthAttributeActLabel')
  manaAttributeActLabel      = attributeWindow:recursiveGetChildById('manaAttributeActLabel')
  agilityAttributeActLabel   = attributeWindow:recursiveGetChildById('agilityAttributeActLabel')
  dodgeAttributeActLabel     = attributeWindow:recursiveGetChildById('dodgeAttributeActLabel')
  walkingAttributeActLabel   = attributeWindow:recursiveGetChildById('walkingAttributeActLabel')
  luckAttributeActLabel      = attributeWindow:recursiveGetChildById('luckAttributeActLabel')

  availablePointsLabel = attributeWindow:recursiveGetChildById('availablePointsLabel')
  pointsCostLabel      = attributeWindow:recursiveGetChildById('pointsCostLabel')

  attributeLabel =
  {
    [ATTRIBUTE_ATTACK]    = attackAttributeActLabel,
    [ATTRIBUTE_DEFENSE]   = defenseAttributeActLabel,
    [ATTRIBUTE_WILLPOWER] = willPowerAttributeActLabel,
    [ATTRIBUTE_HEALTH]    = healthAttributeActLabel,
    [ATTRIBUTE_MANA]      = manaAttributeActLabel,
    [ATTRIBUTE_AGILITY]   = agilityAttributeActLabel,
    [ATTRIBUTE_DODGE]     = dodgeAttributeActLabel,
    [ATTRIBUTE_WALKING]   = walkingAttributeActLabel,
    [ATTRIBUTE_LUCK]      = luckAttributeActLabel,
  }

  attackAttributeAddButton.attributeId    = ATTRIBUTE_ATTACK
  defenseAttributeAddButton.attributeId   = ATTRIBUTE_DEFENSE
  willPowerAttributeAddButton.attributeId = ATTRIBUTE_WILLPOWER
  healthAttributeAddButton.attributeId    = ATTRIBUTE_HEALTH
  manaAttributeAddButton.attributeId      = ATTRIBUTE_MANA
  agilityAttributeAddButton.attributeId   = ATTRIBUTE_AGILITY
  dodgeAttributeAddButton.attributeId     = ATTRIBUTE_DODGE
  walkingAttributeAddButton.attributeId   = ATTRIBUTE_WALKING
  luckAttributeAddButton.attributeId      = ATTRIBUTE_LUCK

  attackAttributeAddButton.onClick    = onClickAddButton
  defenseAttributeAddButton.onClick   = onClickAddButton
  willPowerAttributeAddButton.onClick = onClickAddButton
  healthAttributeAddButton.onClick    = onClickAddButton
  manaAttributeAddButton.onClick      = onClickAddButton
  agilityAttributeAddButton.onClick   = onClickAddButton
  dodgeAttributeAddButton.onClick     = onClickAddButton
  walkingAttributeAddButton.onClick   = onClickAddButton
  luckAttributeAddButton.onClick      = onClickAddButton

  if g_game.isOnline() then
    online()
  end

  connect(g_game, { onGameStart        = online,
                    onPlayerAttributes = onPlayerAttributes })
end

function terminate()
  disconnect(g_game, { onGameStart        = online,
                       onPlayerAttributes = onPlayerAttributes })

  attributeButton:destroy()
  attributeWindow:destroy()

  attributeButton = nil
  attributeWindow = nil

  attackAttributeAddButton    = nil
  defenseAttributeAddButton   = nil
  willPowerAttributeAddButton = nil
  healthAttributeAddButton    = nil
  manaAttributeAddButton      = nil
  agilityAttributeAddButton   = nil
  dodgeAttributeAddButton     = nil
  walkingAttributeAddButton   = nil
  luckAttributeAddButton      = nil

  attackAttributeActLabel    = nil
  defenseAttributeActLabel   = nil
  willPowerAttributeActLabel = nil
  healthAttributeActLabel    = nil
  manaAttributeActLabel      = nil
  agilityAttributeActLabel   = nil
  dodgeAttributeActLabel     = nil
  walkingAttributeActLabel   = nil
  luckAttributeActLabel      = nil

  availablePointsLabel = nil
  pointsCostLabel      = nil

  g_keyboard.unbindKeyDown('Ctrl+Shift+U')
end

function toggle()
  if attributeButton:isOn() then
    attributeWindow:close()
    attributeButton:setOn(false)
  else
    attributeWindow:open()
    attributeButton:setOn(true)
  end
end

function online()
  clearWindow()

  local protocol = g_game.getProtocolGame()
  if protocol then
    protocol:sendExtendedOpcode(ClientExtOpcodes.ClientAttribute, string.format("%d", attribute_flag_updateList))
  end
end

function onMiniWindowClose()
  if attributeButton then
    attributeButton:setOn(false)
  end
end

function clearWindow()
  attackAttributeActLabel:setText(string.format('%.2f', 0))
  defenseAttributeActLabel:setText(string.format('%.2f', 0))
  willPowerAttributeActLabel:setText(string.format('%.2f', 0))
  healthAttributeActLabel:setText(string.format('%.2f', 0))
  manaAttributeActLabel:setText(string.format('%.2f', 0))
  agilityAttributeActLabel:setText(string.format('%.2f', 0))
  dodgeAttributeActLabel:setText(string.format('%.2f', 0))
  walkingAttributeActLabel:setText(string.format('%.2f', 0))
  luckAttributeActLabel:setText(string.format('%.2f', 0))

  availablePointsLabel:setText(string.format('Available Pts: %d', 0))
  pointsCostLabel:setText(string.format('Cost: %d', 0))

  attackAttributeActLabel:setTooltip('')
  defenseAttributeActLabel:setTooltip('')
  willPowerAttributeActLabel:setTooltip('')
  healthAttributeActLabel:setTooltip('')
  manaAttributeActLabel:setTooltip('')
  agilityAttributeActLabel:setTooltip('')
  dodgeAttributeActLabel:setTooltip('')
  walkingAttributeActLabel:setTooltip('')
  luckAttributeActLabel:setTooltip('')

  availablePointsLabel:setTooltip(string.format('Used Pts with cost: %d\nUsed Pts without cost: %d', 0, 0))
  pointsCostLabel:setTooltip(string.format('Pts to increase cost: %d', 0))

  attackAttributeActLabel:setColor('white')
  defenseAttributeActLabel:setColor('white')
  willPowerAttributeActLabel:setColor('white')
  healthAttributeActLabel:setColor('white')
  manaAttributeActLabel:setColor('white')
  agilityAttributeActLabel:setColor('white')
  dodgeAttributeActLabel:setColor('white')
  walkingAttributeActLabel:setColor('white')
  luckAttributeActLabel:setColor('white')
end

function onPlayerAttributes(attributes, availablePoints, usedPoints, distributionPoints, pointsCost, pointsToCostIncrease)
  if attributeLabel then
    for k, attribute in ipairs(attributes) do
      local id                 = attribute[1]
      local distributionPoints = attribute[2]
      local alignmentPoints    = attribute[3]
      local alignmentMaxPoints = attribute[4]
      local buffPoints         = attribute[5]
      local total              = attribute[6]

      if attributeLabel[id] then
        local distributionPointsText = distributionPoints ~= 0 and string.format('Distribution: %d\n', distributionPoints)                         or ''
        local alignmentPointsText    = alignmentPoints    ~= 0 and string.format('Alignment: %.2f of %.2f\n', alignmentPoints, alignmentMaxPoints) or ''
        local buffPointsText         = buffPoints         ~= 0 and string.format('(De)Buff: %s%.2f\n', buffPoints > 0 and '+' or '', buffPoints)   or ''

        local moreThanMaximum        = (distributionPoints + alignmentPoints + buffPoints) > total
        local totalPointsText        = total ~= 0 and string.format('Total: %.2f%s', total, moreThanMaximum and '\n(exceed the maximum value)' or '') or ''

        attributeLabel[id]:setText(string.format('%0.02f', total))
        attributeLabel[id]:setTooltip(string.format('%s%s%s%s', distributionPointsText, alignmentPointsText, buffPointsText, totalPointsText))
        attributeLabel[id]:setColor(buffPoints > 0 and 'green' or buffPoints < 0 and 'red' or 'white')
      end
    end
  end

  _availablePoints = availablePoints
  availablePointsLabel:setText(string.format('Available Pts: %d', availablePoints))
  availablePointsLabel:setTooltip(string.format('Used Pts with cost: %d\nUsed Pts without cost: %d', usedPoints, distributionPoints))
  pointsCostLabel:setText(string.format('Cost: %d', pointsCost))
  pointsCostLabel:setTooltip(string.format('Pts to increase cost: %d', pointsToCostIncrease))
end

function Attribute:sendAdd(attributeId)
  local protocol = g_game.getProtocolGame()
  if not protocol then return end

  protocol:sendExtendedOpcode(ClientExtOpcodes.ClientAttribute, string.format("%d", attributeId))
end

function onClickAddButton(widget)
  if not widget.attributeId then return end

  Attribute:sendAdd(widget.attributeId)
end

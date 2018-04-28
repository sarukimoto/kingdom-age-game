-- @docclass
UICreatureButton = extends(UIWidget, "UICreatureButton")

local aa = 'AA' -- alpha
local CreatureButtonColors = {
  onIdle = {notHovered = '#888888'..aa, hovered = '#FFFFFF'..aa },
  onTargetedOffensive = {notHovered = '#FF0000'..aa, hovered = '#FF8888'..aa },
  onTargetedBalanced  = {notHovered = '#FFFF00'..aa, hovered = '#FFFF88'..aa },
  onTargetedDefensive = {notHovered = '#00FFFF'..aa, hovered = '#88FFFF'..aa },
  onFollowed = {notHovered = '#00FF00'..aa, hovered = '#88FF88'..aa }
}

local LifeBarColor = '#FF4444'
-- local LifeBarColors = {} -- Must be sorted by percentAbove
-- table.insert(LifeBarColors, {percentAbove = 92, color = '#00BC00' } )
-- table.insert(LifeBarColors, {percentAbove = 60, color = '#50A150' } )
-- table.insert(LifeBarColors, {percentAbove = 30, color = '#A1A100' } )
-- table.insert(LifeBarColors, {percentAbove = 8, color = '#BF0A0A' } )
-- table.insert(LifeBarColors, {percentAbove = 3, color = '#910F0F' } )
-- table.insert(LifeBarColors, {percentAbove = -1, color = '#850C0C' } )
-- table.insert(LifeBarColors, {percentAbove = -1, color = '#FF4444' } )

function UICreatureButton.create()
  local button = UICreatureButton.internalCreate()
  button:setFocusable(false)
  button.creature = nil
  button.isHovered = false
  button.isTarget = false
  button.isFollowed = false
  return button
end

function UICreatureButton:setCreature(creature)
    self.creature = creature
end

function UICreatureButton:getCreature()
  return self.creature
end

function UICreatureButton:getCreatureId()
    return self.creature:getId()
end

function UICreatureButton:setup(creature)
  self.creature = creature

  local creatureWidget = self:getChildById('creature')
  local labelWidget = self:getChildById('label')
  local lifeBarWidget = self:getChildById('lifeBar')

  labelWidget:setText(creature:getName())
  creatureWidget:setCreature(creature)

  self:setId('CreatureButton_' .. creature:getName():gsub('%s','_'))
  self:setLifeBarPercent(creature:getHealthPercent())

  self:updateSkull(creature:getSkull())
  self:updateEmblem(creature:getEmblem())
  self:updateSpecialIcon(creature:getSpecialIcon())
end

function UICreatureButton:update()
  local color = CreatureButtonColors.onIdle
  if self.isTarget then
    color = CreatureButtonColors.onTargetedOffensive

    local fightMode = g_game.getFightMode()
    if fightMode == FightOffensive then
      color = CreatureButtonColors.onTargetedOffensive
    elseif fightMode == FightBalanced then
      color = CreatureButtonColors.onTargetedBalanced
    elseif fightMode == FightDefensive then
      color = CreatureButtonColors.onTargetedDefensive
    end
  elseif self.isFollowed then
    color = CreatureButtonColors.onFollowed
  end
  color = self.isHovered and color.hovered or color.notHovered

  if self.isHovered or self.isTarget or self.isFollowed then
    self.creature:showStaticSquare(color)
    self:getChildById('creature'):setBorderWidth(1)
    self:getChildById('creature'):setBorderColor(color)
    self:getChildById('label'):setColor(color)
  else
    self.creature:hideStaticSquare()
    self:getChildById('creature'):setBorderWidth(0)
    self:getChildById('label'):setColor(color)
  end
end

function UICreatureButton:updateSkull(skullId)
  if not self.creature then
    return
  end
  local skullId = skullId or self.creature:getSkull()
  local skullWidget = self:getChildById('skull')
  local labelWidget = self:getChildById('label')

  if skullId ~= SkullNone then
    skullWidget:setWidth(skullWidget:getHeight())
    local imagePath = getSkullImagePath(skullId)
    skullWidget:setImageSource(imagePath)
    labelWidget:setMarginLeft(5)
  else
    skullWidget:setWidth(0)
    if self.creature:getEmblem() == EmblemNone and self.creature:getSpecialIcon() == SpecialIconNone then
      labelWidget:setMarginLeft(2)
    end
  end
end

function UICreatureButton:updateEmblem(emblemId)
  if not self.creature then
    return
  end
  local emblemId = emblemId or self.creature:getEmblem()
  local emblemWidget = self:getChildById('emblem')
  local labelWidget = self:getChildById('label')

  if emblemId ~= EmblemNone then
    emblemWidget:setWidth(emblemWidget:getHeight())
    local imagePath = getEmblemImagePath(emblemId)
    emblemWidget:setImageSource(imagePath)
    emblemWidget:setMarginLeft(5)
    labelWidget:setMarginLeft(5)
  else
    emblemWidget:setWidth(0)
    emblemWidget:setMarginLeft(0)
    if self.creature:getSkull() == SkullNone and self.creature:getSpecialIcon() == SpecialIconNone then
      labelWidget:setMarginLeft(2)
    end
  end
end

function UICreatureButton:updateSpecialIcon(specialIconId)
  if not self.creature then
    return
  end
  local specialIconId = specialIconId or self.creature:getSpecialIcon()
  local specialIconWidget = self:getChildById('specialIcon')
  local labelWidget = self:getChildById('label')

  if specialIconId ~= SpecialIconNone then
    specialIconWidget:setWidth(specialIconWidget:getHeight())
    local imagePath = getSpecialIconPath(specialIconId)
    specialIconWidget:setImageSource(imagePath)
    specialIconWidget:setMarginLeft(5)
    labelWidget:setMarginLeft(5)
  else
    specialIconWidget:setWidth(0)
    specialIconWidget:setMarginLeft(0)
    if self.creature:getSkull() == SkullNone and self.creature:getEmblem() == EmblemNone then
      labelWidget:setMarginLeft(2)
    end
  end
end

function UICreatureButton:setLifeBarPercent(percent)
  local lifeBarWidget = self:getChildById('lifeBar')
  lifeBarWidget:setPercent(percent)

  local color
  -- for i, v in pairs(LifeBarColors) do
  --   if percent > v.percentAbove then
  --     color = v.color
  --     break
  --   end
  -- end

  -- lifeBarWidget:setBackgroundColor(color)
  lifeBarWidget:setBackgroundColor(LifeBarColor)
end

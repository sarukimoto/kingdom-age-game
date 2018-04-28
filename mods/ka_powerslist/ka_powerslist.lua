local minimumWindowSize = 290

powersListWindow = nil
powersListButton = nil

powersList       = nil
labelName        = nil
labelLevel       = nil
labelClass       = nil
labelVocation    = nil
labelPremium     = nil
labelDescription = nil

local txtName     = "Name"
local txtLevel    = "Level"
local txtClass    = "Class"
local txtVocation = "Vocs"
local txtPremium  = "Premium"

local POWER_CLASS_ALL       = 0
local POWER_CLASS_OFFENSIVE = 1
local POWER_CLASS_DEFENSIVE = 2
local POWER_CLASS_SUPPORT   = 3
local POWER_CLASS_SPECIAL   = 4

local POWER_CLASS_STRING =
{
  [POWER_CLASS_ALL]       = "All",
  [POWER_CLASS_OFFENSIVE] = "Offensive",
  [POWER_CLASS_DEFENSIVE] = "Defensive",
  [POWER_CLASS_SUPPORT]   = "Support",
  [POWER_CLASS_SPECIAL]   = "Special"
}

local VOCATION_LEARNER  = 0
local VOCATION_KNIGHT   = 1
local VOCATION_PALADIN  = 2
local VOCATION_ARCHER   = 3
local VOCATION_ASSASSIN = 4
local VOCATION_WIZARD   = 5
local VOCATION_BARD     = 6
local vocationName =
{
  [VOCATION_LEARNER]  = "Learner",
  [VOCATION_KNIGHT]   = "Knight",
  [VOCATION_PALADIN]  = "Paladin",
  [VOCATION_ARCHER]   = "Archer",
  [VOCATION_ASSASSIN] = "Assassin",
  [VOCATION_WIZARD]   = "Wizard",
  [VOCATION_BARD]     = "Bard",
}

function init()
  powersListWindow = g_ui.loadUI('ka_powerslist', modules.game_interface.getRightPanel())
  powersListWindow:hide()
  powersListWindow:setContentMinimumHeight(minimumWindowSize)
  powersListWindow:setup()

  powersListButton = modules.client_topmenu.addRightGameToggleButton('powersListButton', tr('Powers List') .. ' (Ctrl+Shift+P)', 'ka_powerslist', toggle)

  powersList       = powersListWindow:recursiveGetChildById('powersList')
  labelName        = powersListWindow:recursiveGetChildById('labelName')
  labelLevel       = powersListWindow:recursiveGetChildById('labelLevel')
  labelClass       = powersListWindow:recursiveGetChildById('labelClass')
  labelVocation    = powersListWindow:recursiveGetChildById('labelVocation')
  labelPremium     = powersListWindow:recursiveGetChildById('labelPremium')
  labelDescription = powersListWindow:recursiveGetChildById('labelDescription')

  if g_game.isOnline() then
    online()
  end

  connect(g_game, { onGameStart        = online,
                    onPlayerPowersList = onPlayerPowersList })

  g_keyboard.bindKeyDown('Ctrl+Shift+P', toggle)
end

function terminate()
  g_keyboard.unbindKeyDown('Ctrl+Shift+P')

  disconnect(g_game, { onGameStart        = online,
                       onPlayerPowersList = onPlayerPowersList })

  disconnect(powersList, { onChildFocusChange = function(self, focusedChild)
                             if focusedChild == nil then return end
                             onClickPowersListLabel(focusedChild)
                           end })

  powersListWindow:destroy()

  powersListWindow = nil
  powersListButton = nil

  powersList       = nil
  labelName        = nil
  labelLevel       = nil
  labelClass       = nil
  labelVocation    = nil
  labelPremium     = nil
  labelDescription = nil
end

function open()
  powersListButton:setOn(true)
  powersListWindow:show()
  powersListWindow:raise()
  powersListWindow:focus()
end

function close()
  powersListButton:setOn(false)
  powersListWindow:hide()
end

function toggle()
  if powersListButton:isOn() then close() else open() end
end

function online()
  clearWindow()
  powersListButton:show()
  powersListButton:setOn(false)
end

function clearWindow()
  labelName:setText(string.format('%s:', tr(txtName)))
  labelLevel:setText(string.format('%s:', tr(txtLevel)))
  labelClass:setText(string.format('%s:', tr(txtClass)))
  labelVocation:setText(string.format('%s:', tr(txtVocation)))
  labelPremium:setText(string.format('%s:', tr(txtPremium)))
  labelDescription:setText('')

  clearPowersList()
end

function onClickPowersListLabel(widget)
  labelName:setText(string.format("%s: %s", tr(txtName), widget.name))
  labelLevel:setText(string.format("%s: %d", tr(txtLevel), widget.level))
  labelClass:setText(string.format("%s: %s", tr(txtClass), POWER_CLASS_STRING[widget.class]))

  local vocations = {}
  if #widget.vocations == table.size(vocationName) then
    labelVocation:setText(string.format("%s: %s", tr(txtVocation), tr('All')))
  else
    for _, vocationId in ipairs(widget.vocations) do
      if vocationName[vocationId] then
        table.insert(vocations, vocationName[vocationId])
      end
    end
    labelVocation:setText(string.format("%s: %s", tr(txtVocation), table.concat(vocations, ', ')))
  end

  labelPremium:setText(string.format("%s: %s", tr(txtPremium), widget.premium and tr('Yes') or tr('No')))
  labelDescription:setText(string.format("\n%s", widget.description))
end

function clearPowersList()
  local children = powersList:getChildren()
  for i = 1, #children do
    powersList:removeChild(children[i])
    children[i]:destroy()
  end
end

function onPlayerPowersList(powers)
  clearWindow()

  for k, power in ipairs(powers) do
    local id          = power[1]
    local name        = power[2]
    local level       = power[3]
    local class       = power[4]
    local vocations   = power[5]
    local premium     = power[6]
    local description = power[7]

    local label = g_ui.createWidget('PowersListLabel', powersList)

    label:setId(string.format("power_%d", id))
    label:setText(string.format("%d. %s", k, name))

    local icon = label:getChildById('powerIcon')
    icon:setIcon('/images/game/powers/' .. id .. '_off')

    label.id          = id
    label.name        = name
    label.level       = level
    label.class       = class
    label.vocations   = vocations
    label.premium     = premium
    label.description = description

    label.onClick = onClickPowersListLabel
  end

  connect(powersList, { onChildFocusChange = function(self, focusedChild)
                          if focusedChild == nil then return end
                          onClickPowersListLabel(focusedChild)
                        end })

  modules.ka_hotkeybars.updateLook()
end

function getPower(id)
  local children = powersList:getChildren()
  for i = 1, #children do
    if id == children[i].id then
      return children[i]
    end
  end
  return nil
end

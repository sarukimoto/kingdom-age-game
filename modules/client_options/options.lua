local optionsShortcut = 'Ctrl+Alt+O'
local audioShortcut = 'Ctrl+Alt+A'
local leftPanelShortcut = 'Ctrl+Shift+A'
local rightPanelShortcut = 'Ctrl+Shift+S'

local defaultOptions = {
  vsync = false,
  showFps = false,
  showPing = false,
  fullscreen = false,
  classicControl = false,
  smartWalk = false,
  dashWalk = false,
  autoChaseOverride = true,
  showStatusMessagesInConsole = true,
  showEventMessagesInConsole = true,
  showInfoMessagesInConsole = true,
  showTimestampsInConsole = true,
  showLevelsInConsole = true,
  showPrivateMessagesInConsole = true,
  showPrivateMessagesOnScreen = true,
  showLeftPanel = false,
  showRightPanel = true,
  showTopMenu = true,
  showChat = true,
  gameScreenSize = 11,
  foregroundFrameRate = 61,
  backgroundFrameRate = 201,
  painterEngine = 0,
  enableAudio = true,
  enableMusic = true,
  enableSoundAmbient = true,
  enableSoundEffect = true,
  musicVolume = 100,
  soundAmbientVolume = 100,
  soundEffectVolume = 100,
  displayNames = true,
  displayLevel = true,
  displayIcons = true,
  displayHealth = true,
  displayMana = true,
  displayExpBar = true,
  displayText = true,
  displayHotkeybars = true,
  showNpcDialogWindows = true,
  dontStretchShrink = false,
  leftSticker = tr("None"),
  rightSticker = tr("None"),
  leftStickerOpacityScrollbar = 100,
  rightStickerOpacityScrollbar = 100,
  smoothWalk = true,
  walkingSensitivityScrollBar = 100,
  walkingRepeatDelayScrollBar = 200,
  bouncingKeys = true,
  bouncingKeysDelayScrollBar = 1000,
  turnDelay = 50,
  hotkeyDelay = 50,
}



-- Panels

function setLeftPanel(value)
  local mod = modules.game_interface
  if not mod then return end

  mod.getLeftPanel():setOn(value)
  updateStickers()
end

function setRightPanel(value)
  local mod = modules.game_interface
  if not mod then return end

  mod.getRightPanel():setOn(value)
  updateStickers()
end

local noneStickerDefaultPath = "/images/ui/stickers/sticker_0.png"
local stickers = {
  [1] = {opt = tr("None"),            path = noneStickerDefaultPath},
  [2] = {opt = tr("Sticker") .. " 1", path = "/images/ui/stickers/sticker_1.png"},
  [3] = {opt = tr("Sticker") .. " 2", path = "/images/ui/stickers/sticker_2.png"},
  [4] = {opt = tr("Sticker") .. " 3", path = "/images/ui/stickers/sticker_3.png"},
  [5] = {opt = tr("Sticker") .. " 4", path = "/images/ui/stickers/sticker_4.png"},
  [6] = {opt = tr("Sticker") .. " 5", path = "/images/ui/stickers/sticker_5.png"}
}

local mt = {__index = function (self, index)
  for i, v in ipairs(self) do
    if v.opt == index then
      return v.path
    end
  end
  return noneStickerDefaultPath
end
}
setmetatable(stickers, mt)





local optionsWindow
local optionsButton
local optionsTabBar
local options = {}
local generalPanel
local consolePanel
local graphicsPanel
local soundPanel
local audioButton
local leftStickerComboBox
local rightStickerComboBox
local keyboardPanel

local function setupGraphicsEngines()
  local enginesRadioGroup = UIRadioGroup.create()
  local ogl1 = graphicsPanel:getChildById('opengl1')
  local ogl2 = graphicsPanel:getChildById('opengl2')
  local dx9 = graphicsPanel:getChildById('directx9')
  enginesRadioGroup:addWidget(ogl1)
  enginesRadioGroup:addWidget(ogl2)
  enginesRadioGroup:addWidget(dx9)

  if g_window.getPlatformType() == 'WIN32-EGL' then
    enginesRadioGroup:selectWidget(dx9)
    ogl1:setEnabled(false)
    ogl2:setEnabled(false)
    dx9:setEnabled(true)
  else
    ogl1:setEnabled(g_graphics.isPainterEngineAvailable(1))
    ogl2:setEnabled(g_graphics.isPainterEngineAvailable(2))
    dx9:setEnabled(false)
    if g_graphics.getPainterEngine() == 2 then
      enginesRadioGroup:selectWidget(ogl2)
    else
      enginesRadioGroup:selectWidget(ogl1)
    end

    if g_app.getOs() ~= 'windows' then
      dx9:hide()
    end
  end

  enginesRadioGroup.onSelectionChange = function(self, selected)
    if selected == ogl1 then
      setOption('painterEngine', 1)
    elseif selected == ogl2 then
      setOption('painterEngine', 2)
    end
  end

  if not g_graphics.canCacheBackbuffer() then
    graphicsPanel:getChildById('foregroundFrameRate'):disable()
    graphicsPanel:getChildById('foregroundFrameRateLabel'):disable()
  end
end

function init()
  for k,v in pairs(defaultOptions) do
    g_settings.setDefault(k, v)
    options[k] = v
  end

  optionsWindow = g_ui.displayUI('options')
  optionsWindow:hide()

  optionsTabBar = optionsWindow:getChildById('optionsTabBar')
  optionsTabBar:setContentWidget(optionsWindow:getChildById('optionsTabContent'))

  g_keyboard.bindKeyDown('Ctrl+Shift+F', function() toggleOption('fullscreen') end)

  generalPanel = g_ui.loadUI('game')
  optionsTabBar:addTab(tr('Game'), generalPanel, '/images/optionstab/game')

  -- Panels Stickers
  leftStickerComboBox = generalPanel:getChildById('leftStickerComboBox')
  rightStickerComboBox = generalPanel:getChildById('rightStickerComboBox')
  if leftStickerComboBox and rightStickerComboBox then
    for _, sticker in ipairs(stickers) do
      leftStickerComboBox:addOption(sticker.opt)
      rightStickerComboBox:addOption(sticker.opt)
    end
    leftStickerComboBox.onOptionChange = setSticker
    rightStickerComboBox.onOptionChange = setSticker

    addEvent(updateStickers, 500)
  end

  consolePanel = g_ui.loadUI('console')
  optionsTabBar:addTab(tr('Console'), consolePanel, '/images/optionstab/console')

  graphicsPanel = g_ui.loadUI('graphics')
  optionsTabBar:addTab(tr('Graphics'), graphicsPanel, '/images/optionstab/graphics')

  audioPanel = g_ui.loadUI('audio')
  optionsTabBar:addTab(tr('Audio'), audioPanel, '/images/optionstab/audio')

  keyboardPanel = g_ui.loadUI('keyboard')
  optionsTabBar:addTab(tr('Keyboard'), keyboardPanel, '/images/optionstab/keyboard')

  optionsButton = modules.client_topmenu.addLeftButton('optionsButton', tr('Options') .. string.format(' (%s)', optionsShortcut), '/images/topbuttons/options', toggle)
  g_keyboard.bindKeyDown(optionsShortcut, toggle)
  audioButton = modules.client_topmenu.addLeftButton('audioButton', tr('Audio') .. string.format(' (%s)', audioShortcut), '/images/topbuttons/audio', function() toggleOption('enableAudio') end)
  g_keyboard.bindKeyDown(audioShortcut, function() toggleOption('enableAudio') end)

  addEvent(function() setup() end)
end

function terminate()
  g_keyboard.unbindKeyDown(optionsShortcut)
  g_keyboard.unbindKeyDown(audioShortcut)
  g_keyboard.unbindKeyDown('Ctrl+Shift+F')
  optionsWindow:destroy()
  optionsButton:destroy()
  audioButton:destroy()
end

function setup()
  setupGraphicsEngines()

  -- load options
  for k,v in pairs(defaultOptions) do
    if type(v) == 'boolean' then
      setOption(k, g_settings.getBoolean(k), true)
    elseif type(v) == 'number' then
      setOption(k, g_settings.getNumber(k), true)
    elseif k == "rightStickerComboBox" or k == "leftStickerComboBox" then
      setOption(k, g_settings.get(k), true)
    end
  end
end

function toggle()
  if optionsWindow:isVisible() then
    hide()
  else
    show()
  end
end

function show()
  optionsWindow:show()
  optionsWindow:raise()
  optionsWindow:focus()
  optionsButton:setOn(true)
end

function hide()
  optionsWindow:hide()
  optionsButton:setOn(false)
end

function toggleOption(key)
  setOption(key, not getOption(key))
end

function setOption(key, value, force)
  if not force and options[key] == value then return end
  local mod = modules.game_interface
  if not mod then return end

  local gameMapPanel = mod.getMapPanel()
  local rootPanel    = mod.getRootPanel()
  if key == 'vsync' then
    g_window.setVerticalSync(value)
  elseif key == 'showFps' then
    modules.client_topmenu.setFpsVisible(value)
  elseif key == 'showPing' then
    modules.client_topmenu.setPingVisible(value)
  elseif key == 'fullscreen' then
    g_window.setFullscreen(value)

  elseif key == 'enableAudio' then
    g_sounds.setEnabled(value)
    g_sounds.getChannel(AudioChannels.Music):setEnabled(value and getOption('enableMusic'))
    g_sounds.getChannel(AudioChannels.Ambient):setEnabled(value and getOption('enableSoundAmbient'))
    g_sounds.getChannel(AudioChannels.Effect):setEnabled(value and getOption('enableSoundEffect'))
    if value then
      audioButton:setIcon('/images/topbuttons/audio')
      audioButton:setOn(true)
    else
      audioButton:setIcon('/images/topbuttons/audio_mute')
      audioButton:setOn(false)
    end

  elseif key == 'enableMusic' then
    g_sounds.getChannel(AudioChannels.Music):setEnabled(getOption('enableAudio') and value)

  elseif key == 'musicVolume' then
    local mod = modules.ka_client_audio
    if mod then
      mod.setMusicVolume(value / 100)
      audioPanel:getChildById('musicVolumeLabel'):setText(tr('Music volume') .. ': ' .. (value < 100 and string.format('%d%%', value) or 'max'))
    end

  elseif key == 'enableSoundAmbient' then
    g_sounds.getChannel(AudioChannels.Ambient):setEnabled(getOption('enableAudio') and value)

  elseif key == 'soundAmbientVolume' then
    local mod = modules.ka_client_audio
    if mod then
      mod.setAmbientVolume(value / 100)
      audioPanel:getChildById('soundAmbientVolumeLabel'):setText(tr('Ambient sounds volume') .. ': ' .. (value < 100 and string.format('%d%%', value) or 'max'))
    end

  elseif key == 'enableSoundEffect' then
    g_sounds.getChannel(AudioChannels.Effect):setEnabled(getOption('enableAudio') and value)

  elseif key == 'soundEffectVolume' then
    local mod = modules.ka_client_audio
    if mod then
      mod.setEffectVolume(value / 100)
      audioPanel:getChildById('soundEffectVolumeLabel'):setText(tr('Effect sounds volume') .. ': ' .. (value < 100 and string.format('%d%%', value) or 'max'))
    end

  elseif key == 'showLeftPanel' then
    setLeftPanel(value)
    mod.getLeftPanelButton():setOn(value)

  elseif key == 'showRightPanel' then
    setRightPanel(value)
    mod.getRightPanelButton():setOn(value)

  elseif key == 'showTopMenu' then
    local topMenu       = modules.client_topmenu.getTopMenu()
    local topMenuButton = mod.getTopMenuButton()
    local leftPanel     = mod.getLeftPanel()
    local rightPanel    = mod.getRightPanel()

    local margin = 0
    if value then
      margin = 0
      topMenu:setMarginTop(-topMenu:getHeight())
      topMenuButton:setOn(false)
    else
      margin = topMenu:getHeight() - leftPanel:getPaddingTop()
      topMenu:setMarginTop(0)
      topMenuButton:setOn(true)
    end

    local viewMode = mod.getCurrentViewMode()
    if value or viewMode == 2 then
      -- See more of these margins at setupViewMode() on game_interface/interface.lua
      leftPanel:setMarginTop(margin)
      rightPanel:setMarginTop(margin)
      topMenuButton:setMarginTop(margin + 10)
    end

    if viewMode == 2 then
      mod = modules.ka_game_hotkeybars
      if mod then
        mod.updateHotkeybarPositions()
      end
    end

  elseif key == 'showChat' then
    local splitter   = mod.getSplitter()
    local chatButton = mod.getChatButton()

    if value then
      splitter:setMarginBottom(162)
      chatButton:setOn(true)
    else
      splitter:setMarginBottom(-splitter:getHeight())
      chatButton:setOn(false)
    end

  elseif key == 'gameScreenSize' then
    local zoom = value % 2 == 0 and value + 1 or value
    local text, v = zoom, value
    if value < 11 or value >= 18 then text = 'max' v = 0 end
    graphicsPanel:getChildById('gameScreenSizeLabel'):setText(tr('Game screen size') .. ': ' .. text .. ' SQMs')
    gameMapPanel:setZoom(zoom)
  elseif key == 'backgroundFrameRate' then
    local text, v = value, value
    if value <= 0 or value >= 201 then text = 'max' v = 0 end
    graphicsPanel:getChildById('backgroundFrameRateLabel'):setText(tr('Game framerate limit') .. ': ' .. text)
    g_app.setBackgroundPaneMaxFps(v)
  elseif key == 'foregroundFrameRate' then
    local text, v = value, value
    if value <= 0 or value >= 61 then  text = 'max' v = 0 end
    graphicsPanel:getChildById('foregroundFrameRateLabel'):setText(tr('Interface framerate limit') .. ': ' .. text)
    g_app.setForegroundPaneMaxFps(v)
  elseif key == 'painterEngine' then
    g_graphics.selectPainterEngine(value)
  elseif key == 'displayNames' then
    gameMapPanel:setDrawNames(value)
  elseif key == 'displayLevel' then
    gameMapPanel:setDrawLevels(value)
  elseif key == 'displayIcons' then
    gameMapPanel:setDrawIcons(value)
  elseif key == 'displayHealth' then
    gameMapPanel:setDrawHealthBars(value)
  elseif key == 'displayMana' then
    gameMapPanel:setDrawManaBar(value)
  elseif key == 'displayExpBar' then
    if modules.ka_game_ui then
      modules.ka_game_ui.setExpBar(value)
    end
  elseif key == 'displayText' then
    gameMapPanel:setDrawTexts(value)
  elseif key == 'displayHotkeybars' then
    local mod = modules.ka_game_hotkeybars
    if mod then
      mod.onDisplay(value)
    end
  elseif key == 'showNpcDialogWindows' then
    g_game.setNpcDialogWindows(value)
  elseif key == 'dontStretchShrink' then
    addEvent(function()
      mod.updateStretchShrink()
    end)
  elseif key == 'leftStickerOpacityScrollbar' then
    local op = generalPanel:getChildById('leftSticketOpacityLabel')
    op:setText(string.format(op.baseText, math.ceil(100 * value / 255)))
    local leftStickerWidget = rootPanel:getChildById('gameLeftPanelSticker')
    if leftStickerWidget then
      local alpha = string.format("%s%x", value < 16 and "0" or "", value)
      leftStickerWidget:setImageColor(tocolor("#FFFFFF" .. alpha))
    end
  elseif key == 'rightStickerOpacityScrollbar' then
    local op = generalPanel:getChildById('rightSticketOpacityLabel')
    op:setText(string.format(op.baseText, math.ceil(100 * value / 255)))
    local rightStickerWidget = rootPanel:getChildById('gameRightPanelSticker')
    if rightStickerWidget then
      local alpha = string.format("%s%x", value < 16 and "0" or "", value)
      rightStickerWidget:setImageColor(tocolor("#FFFFFF" .. alpha))
    end
  elseif key == "leftStickerComboBox" then
    leftStickerComboBox:setCurrentOption(value)
  elseif key == "rightStickerComboBox" then
    rightStickerComboBox:setCurrentOption(value)
  elseif key == 'walkingSensitivityScrollBar' then
    keyboardPanel:getChildById('walkingSensitivityLabel'):setText(tr('Walking keys sensitivity: %s', value < 100 and string.format('%d%%', value) or 'max'))
  elseif key == 'walkingRepeatDelayScrollBar' then
    keyboardPanel:getChildById('walkingRepeatDelayLabel'):setText(tr('Walking keys auto-repeat delay: %s', value < 200 and string.format('%d ms', value) or 'max'))
    local scrollBar = keyboardPanel:getChildById('walkingRepeatDelayScrollBar')
    mod.setWalkingRepeatDelay(value)
  elseif key == 'bouncingKeysDelayScrollBar' then
    keyboardPanel:getChildById('bouncingKeysDelayLabel'):setText(tr('Auto bouncing keys interval: %s', value < 1000 and string.format('%d ms', value) or 'max'))
  elseif key == 'smoothWalk' then
    keyboardPanel:getChildById('walkingSensitivityScrollBar'):setEnabled(value)
    keyboardPanel:getChildById('walkingSensitivityLabel'):setEnabled(value)
    keyboardPanel:getChildById('walkingRepeatDelayLabel'):setEnabled(value)
    keyboardPanel:getChildById('walkingRepeatDelayScrollBar'):setEnabled(value)
  elseif key == 'bouncingKeys' then
    keyboardPanel:getChildById('bouncingKeysDelayScrollBar'):setEnabled(value)
    keyboardPanel:getChildById('bouncingKeysDelayLabel'):setEnabled(value)
  elseif key == 'turnDelay' then
    keyboardPanel:getChildById('turnDelayLabel'):setText(tr('Turn delay: %sms', value))
  elseif key == 'hotkeyDelay' then
    keyboardPanel:getChildById('hotkeyDelayLabel'):setText(tr('Hotkey delay: %sms', value))
  end

  -- change value for keybind updates
  for _,panel in pairs(optionsTabBar:getTabsPanel()) do
    local widget = panel:recursiveGetChildById(key)
    if widget then
      if widget:getStyle().__class == 'UICheckBox' then
        widget:setChecked(value)
      elseif widget:getStyle().__class == 'UIScrollBar' then
        widget:setValue(value)
      end
      break
    end
  end

  g_settings.set(key, value)
  options[key] = value
end

function getOption(key)
  return options[key]
end

function addTab(name, panel, icon)
  optionsTabBar:addTab(name, panel, icon)
end

function addButton(name, func, icon)
  optionsTabBar:addButton(name, func, icon)
end



-- Panels Stickers

function updateStickers()
  local mod = modules.game_interface
  if not mod then return end
  local rootPanel = mod.getRootPanel()
  if not rootPanel then return end

  -- Left panel
  local leftStickerWidget = rootPanel:getChildById('gameLeftPanelSticker')
  if leftStickerWidget then
    local value = g_settings.get(leftStickerComboBox:getId())
    value = type(value) == "string" and value ~= "" and value or defaultOptions.leftSticker

    leftStickerComboBox:setCurrentOption(value) -- Make sure combobox has same as value at g_settings
    leftStickerWidget:setHeight(0) -- Will make able to get height when change the image source
    leftStickerWidget:setImageSource(stickers[value])
  end

  -- Right panel
  local rightStickerWidget = rootPanel:getChildById('gameRightPanelSticker')
  if rightStickerWidget then
    local value = g_settings.get(rightStickerComboBox:getId())
    value = type(value) == "string" and value ~= "" and value or defaultOptions.rightSticker

    rightStickerComboBox:setCurrentOption(value) -- Make sure combobox has same as value at g_settings
    rightStickerWidget:setHeight(0) -- Will make able to get height when change the image source
    rightStickerWidget:setImageSource(stickers[value])
  end
end

function setSticker(comboBox, opt)
  g_settings.set(comboBox:getId(), opt)
  options[comboBox:getId()] = opt
  updateStickers()
end

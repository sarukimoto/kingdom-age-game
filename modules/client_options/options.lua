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
  showNames = true,
  showLevel = true,
  showIcons = true,
  showHealth = true,
  showMana = true,
  showExpBar = true,
  showText = true,
  showHotkeybars = true,
  showNpcDialogWindows = true,
  showMouseItemIcon = true,
  mouseItemIconOpacity = 30,
  dontStretchShrink = false,
  shaderFilter = ShaderFilter,
  viewMode = ViewModes[3].name,
  leftSticker = 'None',
  rightSticker = 'None',
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
  if not modules.game_interface then return end

  modules.game_interface.getLeftPanel():setOn(value)
  updateStickers()
end

function setRightPanel(value)
  if not modules.game_interface then return end

  modules.game_interface.getRightPanel():setOn(value)
  updateStickers()
end





local optionsWindow
local optionsButton
local optionsTabBar
local options = {}
local generalPanel
local controlPanel
local audioPanel
local graphicPanel
local displayPanel
local consolePanel
local audioButton
local leftStickerComboBox
local rightStickerComboBox
local shaderFilterComboBox
local viewModeComboBox

local function setupGraphicsEngines()
  local enginesRadioGroup = UIRadioGroup.create()
  local ogl1 = graphicPanel:getChildById('opengl1')
  local ogl2 = graphicPanel:getChildById('opengl2')
  local dx9 = graphicPanel:getChildById('directx9')
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
    graphicPanel:getChildById('foregroundFrameRate'):disable()
    graphicPanel:getChildById('foregroundFrameRateLabel'):disable()
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
  controlPanel = g_ui.loadUI('control')
  audioPanel = g_ui.loadUI('audio')
  graphicPanel = g_ui.loadUI('graphic')
  displayPanel = g_ui.loadUI('display')
  consolePanel = g_ui.loadUI('console')
  optionsTabBar:addTab(tr('Game'), generalPanel, '/images/optionstab/game')
  optionsTabBar:addTab(tr('Control'), controlPanel, '/images/optionstab/control')
  optionsTabBar:addTab(tr('Audio'), audioPanel, '/images/optionstab/audio')
  optionsTabBar:addTab(tr('Graphic'), graphicPanel, '/images/optionstab/graphic')
  optionsTabBar:addTab(tr('Display'), displayPanel, '/images/optionstab/display')
  optionsTabBar:addTab(tr('Console'), consolePanel, '/images/optionstab/console')

  -- Shader filters
  shaderFilterComboBox = graphicPanel:getChildById('shaderFilterComboBox')
  if shaderFilterComboBox then
    for _, shaderFilter in ipairs(MapShaders) do
      if shaderFilter.isFilter then
        shaderFilterComboBox:addOption(shaderFilter.name)
      end
    end
    shaderFilterComboBox.onOptionChange = setShaderFilter

    -- Select default shader
    local shaderFilter = g_settings.get(shaderFilterComboBox:getId(), defaultOptions.shaderFilter)
    shaderFilterComboBox:setOption(shaderFilter)
  end

  -- View mode combobox
  viewModeComboBox = graphicPanel:getChildById('viewModeComboBox')
  if viewModeComboBox then
    for k = 0, #ViewModes do
      viewModeComboBox:addOption(ViewModes[k].name)
    end
    viewModeComboBox.onOptionChange = setViewMode

    -- Select default view mode
    local viewMode = g_settings.get(viewModeComboBox:getId(), defaultOptions.viewMode)
    viewModeComboBox:setOption(viewMode)
  end

  -- Mouse item icon example
  local showMouseItemIcon = displayPanel:getChildById('showMouseItemIcon')
  showMouseItemIcon.onHoverChange = function (self, hovered)
    if hovered then
      g_mouseicon.display(3585, getOption('mouseItemIconOpacity') / 100, nil, 7)
    else
      g_mouseicon.hide()
    end
  end
  local mouseItemIconOpacity = displayPanel:getChildById('mouseItemIconOpacity')
  mouseItemIconOpacity.onHoverChange = showMouseItemIcon.onHoverChange

  -- Sticker combobox
  leftStickerComboBox = displayPanel:getChildById('leftStickerComboBox')
  rightStickerComboBox = displayPanel:getChildById('rightStickerComboBox')
  if leftStickerComboBox and rightStickerComboBox then
    for _, sticker in ipairs(PanelStickers) do
      leftStickerComboBox:addOption(sticker.opt)
      rightStickerComboBox:addOption(sticker.opt)
    end
    leftStickerComboBox.onOptionChange = setSticker
    rightStickerComboBox.onOptionChange = setSticker

    addEvent(updateStickers, 500)
  end

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
    elseif type(v) == 'string' then
      setOption(k, g_settings.getString(k), true)
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
  if not modules.game_interface then return end

  local gameMapPanel = modules.game_interface.getMapPanel()
  local rootPanel    = modules.game_interface.getRootPanel()
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
    if modules.ka_client_audio then
      modules.ka_client_audio.setMusicVolume(value / 100)
      audioPanel:getChildById('musicVolumeLabel'):setText(tr('Music volume') .. ': ' .. (value < 100 and string.format('%d%%', value) or 'max'))
    end

  elseif key == 'enableSoundAmbient' then
    g_sounds.getChannel(AudioChannels.Ambient):setEnabled(getOption('enableAudio') and value)

  elseif key == 'soundAmbientVolume' then
    if modules.ka_client_audio then
      modules.ka_client_audio.setAmbientVolume(value / 100)
      audioPanel:getChildById('soundAmbientVolumeLabel'):setText(tr('Ambient sounds volume') .. ': ' .. (value < 100 and string.format('%d%%', value) or 'max'))
    end

  elseif key == 'enableSoundEffect' then
    g_sounds.getChannel(AudioChannels.Effect):setEnabled(getOption('enableAudio') and value)

  elseif key == 'soundEffectVolume' then
    if modules.ka_client_audio then
      modules.ka_client_audio.setEffectVolume(value / 100)
      audioPanel:getChildById('soundEffectVolumeLabel'):setText(tr('Effect sounds volume') .. ': ' .. (value < 100 and string.format('%d%%', value) or 'max'))
    end

  elseif key == 'showLeftPanel' then
    setLeftPanel(value)
    modules.game_interface.getLeftPanelButton():setOn(value)

    -- Force onGeometryChange calling
    -- Without it, onGeometryChange is not executed on execute the button showLeftPanel
    if ViewModes[modules.game_interface.getCurrentViewMode()].isFull then
      signalcall(gameMapPanel.onGeometryChange, gameMapPanel)
      signalcall(rootPanel.onGeometryChange, rootPanel)
    end

  elseif key == 'showRightPanel' then
    setRightPanel(value)
    modules.game_interface.getRightPanelButton():setOn(value)

    -- Force onGeometryChange calling
    -- Without it, onGeometryChange is not executed on execute the button showRightPanel
    if ViewModes[modules.game_interface.getCurrentViewMode()].isFull then
      signalcall(gameMapPanel.onGeometryChange, gameMapPanel)
      signalcall(rootPanel.onGeometryChange, rootPanel)
    end

  elseif key == 'showTopMenu' then
    local topMenu       = modules.client_topmenu.getTopMenu()
    local topMenuButton = modules.game_interface.getTopMenuButton()
    local leftPanel     = modules.game_interface.getLeftPanel()
    local rightPanel    = modules.game_interface.getRightPanel()

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

    local isFullViewMode = ViewModes[modules.game_interface.getCurrentViewMode()].isFull

    if value or isFullViewMode then
      -- See more of these margins at setupViewMode() on game_interface/interface.lua
      leftPanel:setMarginTop(margin)
      rightPanel:setMarginTop(margin)
      topMenuButton:setMarginTop(margin + 10)
    end

    -- Force onGeometryChange calling
    -- Without it, onGeometryChange is not executed on execute the button showTopMenu
    if ViewModes[modules.game_interface.getCurrentViewMode()].isFull then
      signalcall(gameMapPanel.onGeometryChange, gameMapPanel)
      signalcall(rootPanel.onGeometryChange, rootPanel)
    end

  elseif key == 'showChat' then
    local splitter   = modules.game_interface.getSplitter()
    local chatButton = modules.game_interface.getChatButton()

    if value then
      splitter:setMarginBottom(162)
      chatButton:setOn(true)
    else
      splitter:setMarginBottom(-splitter:getHeight())
      chatButton:setOn(false)
    end

    -- Force onGeometryChange calling
    -- Without it, onGeometryChange is not executed on execute the button showChat
    if ViewModes[modules.game_interface.getCurrentViewMode()].isFull then
      signalcall(gameMapPanel.onGeometryChange, gameMapPanel)
      signalcall(rootPanel.onGeometryChange, rootPanel)
    end

  elseif key == 'gameScreenSize' then
    local zoom = value % 2 == 0 and value + 1 or value
    local text, v = zoom, value
    if value < 11 or value >= 18 then text = 'max' v = 0 end
    graphicPanel:getChildById('gameScreenSizeLabel'):setText(tr('Game screen size') .. ': ' .. text .. ' SQMs')
    gameMapPanel:setZoom(zoom)
  elseif key == 'backgroundFrameRate' then
    local text, v = value, value
    if value <= 0 or value >= 201 then text = 'max' v = 0 end
    graphicPanel:getChildById('backgroundFrameRateLabel'):setText(tr('Game framerate limit') .. ': ' .. text)
    g_app.setBackgroundPaneMaxFps(v)
  elseif key == 'foregroundFrameRate' then
    local text, v = value, value
    if value <= 0 or value >= 61 then  text = 'max' v = 0 end
    graphicPanel:getChildById('foregroundFrameRateLabel'):setText(tr('Interface framerate limit') .. ': ' .. text)
    g_app.setForegroundPaneMaxFps(v)
  elseif key == 'painterEngine' then
    g_graphics.selectPainterEngine(value)
  elseif key == 'showNames' then
    gameMapPanel:setDrawNames(value)
  elseif key == 'showLevel' then
    gameMapPanel:setDrawLevels(value)
  elseif key == 'showIcons' then
    gameMapPanel:setDrawIcons(value)
  elseif key == 'showHealth' then
    gameMapPanel:setDrawHealthBars(value)
  elseif key == 'showMana' then
    gameMapPanel:setDrawManaBar(value)
  elseif key == 'showExpBar' then
    if modules.ka_game_ui then
      modules.ka_game_ui.setExpBar(value)
    end
  elseif key == 'showText' then
    gameMapPanel:setDrawTexts(value)
  elseif key == 'showHotkeybars' then
    if modules.ka_game_hotkeybars then
      modules.ka_game_hotkeybars.onDisplay(value)
    end
  elseif key == 'showNpcDialogWindows' then
    g_game.setNpcDialogWindows(value)
  elseif key == 'mouseItemIconOpacity' then
    local op = displayPanel:getChildById('mouseItemIconOpacityLabel')
    op:setText(string.format(op.baseText, value))
  elseif key == 'dontStretchShrink' then
    addEvent(function()
      modules.game_interface.updateStretchShrink()
    end)
  elseif key == 'leftStickerOpacityScrollbar' then
    local op = displayPanel:getChildById('leftSticketOpacityLabel')
    op:setText(string.format(op.baseText, math.ceil(100 * value / 255)))
    local leftStickerWidget = rootPanel:getChildById('gameLeftPanelSticker')
    if leftStickerWidget then
      local alpha = string.format("%s%x", value < 16 and "0" or "", value)
      leftStickerWidget:setImageColor(tocolor("#FFFFFF" .. alpha))
    end
  elseif key == 'rightStickerOpacityScrollbar' then
    local op = displayPanel:getChildById('rightSticketOpacityLabel')
    op:setText(string.format(op.baseText, math.ceil(100 * value / 255)))
    local rightStickerWidget = rootPanel:getChildById('gameRightPanelSticker')
    if rightStickerWidget then
      local alpha = string.format("%s%x", value < 16 and "0" or "", value)
      rightStickerWidget:setImageColor(tocolor("#FFFFFF" .. alpha))
    end
  elseif key == "shaderFilterComboBox" then
    shaderFilterComboBox:setOption(value)
  elseif key == "viewModeComboBox" then
    viewModeComboBox:setOption(value)
  elseif key == "leftStickerComboBox" then
    leftStickerComboBox:setOption(value)
  elseif key == "rightStickerComboBox" then
    rightStickerComboBox:setOption(value)
  elseif key == 'walkingSensitivityScrollBar' then
    controlPanel:getChildById('walkingSensitivityLabel'):setText(tr('Walking keys sensitivity: %s', value < 100 and string.format('%d%%', value) or 'max'))
  elseif key == 'walkingRepeatDelayScrollBar' then
    controlPanel:getChildById('walkingRepeatDelayLabel'):setText(tr('Walking keys auto-repeat delay: %s', value < 200 and string.format('%d ms', value) or 'max'))
    local scrollBar = controlPanel:getChildById('walkingRepeatDelayScrollBar')
    modules.game_interface.setWalkingRepeatDelay(value)
  elseif key == 'bouncingKeysDelayScrollBar' then
    controlPanel:getChildById('bouncingKeysDelayLabel'):setText(tr('Auto bouncing keys interval: %s', value < 1000 and string.format('%d ms', value) or 'max'))
  elseif key == 'smoothWalk' then
    controlPanel:getChildById('walkingSensitivityScrollBar'):setEnabled(value)
    controlPanel:getChildById('walkingSensitivityLabel'):setEnabled(value)
    controlPanel:getChildById('walkingRepeatDelayLabel'):setEnabled(value)
    controlPanel:getChildById('walkingRepeatDelayScrollBar'):setEnabled(value)
  elseif key == 'bouncingKeys' then
    controlPanel:getChildById('bouncingKeysDelayScrollBar'):setEnabled(value)
    controlPanel:getChildById('bouncingKeysDelayLabel'):setEnabled(value)
  elseif key == 'turnDelay' then
    controlPanel:getChildById('turnDelayLabel'):setText(tr('Turn delay: %sms', value))
  elseif key == 'hotkeyDelay' then
    controlPanel:getChildById('hotkeyDelayLabel'):setText(tr('Hotkey delay: %sms', value))
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



-- Panel Stickers

function updateStickers()
  if not modules.game_interface then return end

  local rootPanel = modules.game_interface.getRootPanel()
  if not rootPanel then return end

  -- Left panel
  local leftStickerWidget = rootPanel:getChildById('gameLeftPanelSticker')
  if leftStickerWidget then
    local value = g_settings.get(leftStickerComboBox:getId())
    value = type(value) == "string" and value ~= "" and value or defaultOptions.leftSticker

    leftStickerComboBox:setOption(value) -- Make sure combobox has same as value at g_settings
    leftStickerComboBox.tooltipAddons = value ~= defaultOptions.leftSticker and { {{ image = PanelStickers[value], align = AlignCenter }} } or nil

    -- Will make able to get height when change the image source
    leftStickerWidget:setWidth(0)
    leftStickerWidget:setHeight(0)
    leftStickerWidget:setImageSource(PanelStickers[value])
  end

  -- Right panel
  local rightStickerWidget = rootPanel:getChildById('gameRightPanelSticker')
  if rightStickerWidget then
    local value = g_settings.get(rightStickerComboBox:getId())
    value = type(value) == "string" and value ~= "" and value or defaultOptions.rightSticker

    rightStickerComboBox:setOption(value) -- Make sure combobox has same as value at g_settings
    rightStickerComboBox.tooltipAddons = value ~= defaultOptions.leftSticker and { {{ image = PanelStickers[value], align = AlignCenter }} } or nil

    -- Will make able to get height when change the image source
    rightStickerWidget:setWidth(0)
    rightStickerWidget:setHeight(0)
    rightStickerWidget:setImageSource(PanelStickers[value])
  end
end

function setSticker(comboBox, opt)
  g_settings.set(comboBox:getId(), opt)
  options[comboBox:getId()] = opt
  updateStickers()
end



-- Shader Filter

function setShaderFilter(comboBox, opt)
  g_settings.set(comboBox:getId(), opt)
  options[comboBox:getId()] = opt
  setMapShader(opt)
end

-- View Mode

function setViewMode(comboBox, opt)
  g_settings.set(comboBox:getId(), opt)
  options[comboBox:getId()] = opt
  if modules.game_interface then
    local viewModeId = 0
    for k = 0, #ViewModes do
      if opt == ViewModes[k].name then
        viewModeId = k
        break
      end
    end
    modules.game_interface.setupViewMode(viewModeId)
  end
end

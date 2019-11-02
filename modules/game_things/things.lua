filename = 'Kingdom Age'
loaded = false



playerSettingsPath = ""

function getPlayerSettings(fileName) -- ([fileName])
  if g_game.isOnline() then
    playerSettingsPath = string.format('/%s/%s', G.host:gsub("[%W]", "_"):lower(), g_game.getCharacterName():gsub("[%W]", "_"))
  end
  if not g_resources.makeDir(playerSettingsPath) then
    g_logger.error(string.format('Failed to load path \'%s\'', playerSettingsPath))
  end

  local playerSettingsFilePath = string.format('%s/%s.otml', playerSettingsPath, fileName or 'config')

  -- Create or load player settings file
  local file = g_configs.create(playerSettingsFilePath)
  if not file then
    g_logger.error(string.format('Failed to load file at \'%s\'', playerSettingsFilePath))
  end

  return file
end



function init()
  connect(g_game, {
    onClientVersionChange = load,
    onGameStart = online,
    onGameEnd = offline
  })
end

function terminate()
  disconnect(g_game, {
    onClientVersionChange = load,
    onGameStart = online,
    onGameEnd = offline
  })
end

function setFileName(name)
  filename = name
end

function isLoaded()
  return loaded
end

function load()
  local version = g_game.getClientVersion()

  -- New limit of sprites
  -- g_game.enableFeature(GameSpritesU32) -- Automatically activated on 960+ protocol
  -- Alpha channel on sprites
  g_game.enableFeature(GameSpritesAlphaChannel)
  -- New limit of effects
  g_game.enableFeature(GameMagicEffectU16)


  local datPath, sprPath
  if filename then
    datPath = resolvepath('/things/' .. filename)
    sprPath = resolvepath('/things/' .. filename)
  else
    datPath = resolvepath('/things/' .. version .. '/Kingdom Age')
    sprPath = resolvepath('/things/' .. version .. '/Kingdom Age')
  end

  local errorMessage = ''
  if not g_things.loadDat(datPath) then
    errorMessage = errorMessage .. tr("Unable to load dat file, place a valid dat in '%s'", datPath) .. '\n'
  end
  if not g_sprites.loadSpr(sprPath) then
    errorMessage = errorMessage .. tr("Unable to load spr file, place a valid spr in '%s'", sprPath)
  end

  loaded = (errorMessage:len() == 0)

  if errorMessage:len() > 0 then
    local messageBox = displayErrorBox(tr('Error'), errorMessage)
    addEvent(function() messageBox:raise() messageBox:focus() end)

    disconnect(g_game, { onClientVersionChange = load })
    g_game.setClientVersion(0)
    g_game.setProtocolVersion(0)
    connect(g_game, { onClientVersionChange = load })
  end
end

function online()
  -- Ensure player settings file existence
  getPlayerSettings()
end

function offline()
  -- On last save of playerSettingsFile when player get offline
  scheduleEvent(function()
    local file = getPlayerSettings()
    -- Keep player settings after terminate
    file:save()
  end)
end

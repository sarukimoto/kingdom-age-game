local musicFilename = "/audios/startup"
local musicChannel = g_sounds.getChannel(AudioChannels.Music)

function reloadScripts()
  g_textures.clearCache()
  g_modules.reloadModules()

  local script = '/' .. g_app.getCompactName() .. 'rc.lua'
  if g_resources.fileExists(script) then
    dofile(script)
  end

  local message = tr('All modules and scripts were reloaded.')

  if modules.game_textmessage then
    modules.game_textmessage.displayGameMessage(message)
  end

  print(message)
end

function onGameStart()
  if modules.ka_client_audio then
    modules.ka_client_audio.clearAudios()
  end
end

function onGameEnd()
  if modules.ka_client_audio then
    modules.ka_client_audio.clearAudios()
  end
  musicChannel:play(musicFilename, 1.0, -1, 7) -- Startup music
end

function startup()
  musicChannel:play(musicFilename, 1.0, -1, 7) -- Startup music

  connect(g_game, { onGameStart = onGameStart })
  connect(g_game, { onGameEnd = onGameEnd })

  -- Check for startup errors
  local errtitle = nil
  local errmsg = nil

  if g_graphics.getRenderer():lower():match('gdi generic') then
    errtitle = tr('Graphics card driver not detected')
    errmsg = tr('No graphics card detected. Everything will be drawn using the CPU,\nthus the performance will be really bad.\nUpdate your graphics driver to have a better performance.')
  end

  -- Show entergame
  if errmsg or errtitle then
    local msgbox = displayErrorBox(errtitle, errmsg)
    msgbox.onOk = function() EnterGame.firstShow() end
  else
    EnterGame.firstShow()
  end
end

function init()
  connect(g_app, { onRun = startup,
                   onExit = exit })

  g_window.setMinimumSize({ width = 600, height = 480 })
  -- g_sounds.preload(musicFilename)

  -- initialize in fullscreen mode on mobile devices
  if g_window.getPlatformType() == "X11-EGL" then
    g_window.setFullscreen(true)
  else
    -- window size
    local size = { width = 800, height = 600 }
    size = g_settings.getSize('window-size', size)
    g_window.resize(size)

    -- window position, default is the screen center
    local displaySize = g_window.getDisplaySize()
    local defaultPos = { x = (displaySize.width - size.width)/2,
                         y = (displaySize.height - size.height)/2 }
    local pos = g_settings.getPoint('window-pos', defaultPos)
    pos.x = math.max(pos.x, 0)
    pos.y = math.max(pos.y, 0)
    g_window.move(pos)

    -- window maximized?
    local maximized = g_settings.getBoolean('window-maximized', false)
    if maximized then g_window.maximize() end
  end

  g_window.setTitle(g_app.getName())
  g_window.setIcon('/images/clienticon')

  -- poll resize events
  g_window.poll()

  --g_keyboard.bindKeyDown('Ctrl+Shift+R', reloadScripts)

  -- generate machine uuid, this is a security measure for storing passwords
  if not g_crypt.setMachineUUID(g_settings.get('uuid')) then
    g_settings.set('uuid', g_crypt.getMachineUUID())
    g_settings.save()
  end
end

function terminate()
  disconnect(g_app, { onRun = startup,
                      onExit = exit })
  -- save window configs
  g_settings.set('window-size', g_window.getUnmaximizedSize())
  g_settings.set('window-pos', g_window.getUnmaximizedPos())
  g_settings.set('window-maximized', g_window.isMaximized())
end

function exit()
  g_logger.info("Exiting application...")
end

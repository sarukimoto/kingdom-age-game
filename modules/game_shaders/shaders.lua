-- HOTKEY = 'Ctrl+X'

-- shadersPanel = nil

function init()
  g_ui.importStyle('shaders.otui')

  -- g_keyboard.bindKeyDown(HOTKEY, toggle)

  -- shadersPanel = g_ui.createWidget('ShadersPanel', modules.game_interface.getMapPanel())
  -- shadersPanel:hide()

  -- Combobox
  -- local mapComboBox = shadersPanel:getChildById('mapComboBox')
  -- mapComboBox.onOptionChange = function(combobox, option)
  --   -- Update shader
  --   setMapShader(option)
  -- end

  if not g_graphics.canUseShaders() then return end

  for _, opts in pairs(MapShaders) do
    local shader = g_shaders.createFragmentShader(opts.name, opts.frag)

    if opts.tex1 then
      shader:addMultiTexture(opts.tex1)
    end
    if opts.tex2 then
      shader:addMultiTexture(opts.tex2)
    end

    -- mapComboBox:addOption(opts.name)
  end

  -- mapComboBox:setOption(ShaderFilter) -- Select default shader

  connect(g_game, {
    onGameStart = online,
  })
end

function terminate()
  disconnect(g_game, {
    onGameStart = online,
  })

  -- g_keyboard.unbindKeyDown(HOTKEY)
  -- shadersPanel:destroy()
end

-- function toggle()
--   shadersPanel:setVisible(not shadersPanel:isVisible())
-- end

function online()
  setMapShader(ShaderFilter) -- Set to default shader
end

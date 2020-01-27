local shadersMetatable = {
  __index =
  function (self, index)
    for i, v in ipairs(self) do
      if index == v.name then
        return v
      end
    end
    return nil
  end
}

MapShaders = {
  -- Filters
  { isFilter = true, name = 'Anti-Aliasing', frag = 'shaders/filters/default.frag' },
  { isFilter = true, name = 'No Anti-Aliasing', frag = 'shaders/filters/default.frag', ignoreAntiAliasing = true },
  { isFilter = true, name = '2xSal', frag ='shaders/filters/2xsal.frag', ignoreAntiAliasing = true }, -- 2xsal
  { isFilter = true, name = '2xSal Level 2', frag ='shaders/filters/2xsal-level2.frag', ignoreAntiAliasing = true }, -- 2xsal-level2


  -- Shaders (isFilter = false) -- Now isFilter is true just for players have fun for a while
  { isFilter = true, name = 'Heat', frag ='shaders/heat.frag' },
  { isFilter = true, name = 'Noise', frag ='shaders/noise.frag' },
  { isFilter = true, name = 'Night', frag ='shaders/night.frag' }, -- linearize
  { isFilter = true, name = 'Water', frag ='shaders/water.frag' },
  { isFilter = true, name = 'Painting', frag ='shaders/painting.frag', ignoreAntiAliasing = true },
  { isFilter = true, name = 'Sepia', frag ='shaders/sepia.frag' },
  { isFilter = true, name = 'Grayscale', frag ='shaders/grayscale.frag' },
  { isFilter = true, name = 'Negative Grayscale', frag ='shaders/negative-grayscale.frag' },
  { isFilter = true, name = 'Negative', frag ='shaders/negative.frag' },
  { isFilter = true, name = 'PAL', frag ='shaders/pal.frag' }, -- pal-singlepass (Phase Alternating Line)
  { isFilter = true, name = 'Old TV', frag = 'shaders/old-tv.frag' },
  { isFilter = true, name = 'Party', frag = 'shaders/party.frag' },
  { isFilter = true, name = 'Bloom', frag = 'shaders/bloom.frag' },
  { isFilter = true, name = 'Radial Blur', frag ='shaders/radial-blur.frag' },
  { isFilter = true, name = 'Zomg', frag ='shaders/zomg.frag' },

  -- { name = 'Fog', frag = 'shaders/fog.frag', tex1 = 'images/clouds.png' }, -- Not that cool on local player walking
  -- { name = 'Pulse', frag = 'shaders/pulse.frag' }, -- Not that cool on local player walking
}
setmetatable(MapShaders, shadersMetatable)
ShaderFilter = '2xSal Level 2'

ItemShaders = {
  { name = 'Fake 3D', vert = 'shaders/fake3d.vert' }
}
setmetatable(ItemShaders, shadersMetatable)

function setMapShader(option)
  local shaderConfig = MapShaders[option]
  if not shaderConfig then return end

  if shaderConfig.isFilter then
    ShaderFilter = option
  end

  if modules.game_interface then
    local map = modules.game_interface.getMapPanel()
    map:setTextureSmooth(not shaderConfig.ignoreAntiAliasing)
    map:setMapShader(g_shaders.getShader(option))
  end
end

function setItemShader(option)
  local shaderConfig = ItemShaders[option]
  if not shaderConfig then return end

  -- TODO
end

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

  -- Shaders
  { name = 'Bloom', frag = 'shaders/bloom.frag' },
  { name = 'Sepia', frag ='shaders/sepia.frag' },
  { name = 'Grayscale', frag ='shaders/grayscale.frag' },
  { name = 'Negative Grayscale', frag ='shaders/negative-grayscale.frag' },
  { name = 'Old TV', frag = 'shaders/old-tv.frag' },
  { name = 'Party', frag = 'shaders/party.frag' },
  { name = 'Radial Blur', frag ='shaders/radial-blur.frag' },
  { name = 'Zomg', frag ='shaders/zomg.frag' },
  { name = 'Heat', frag ='shaders/heat.frag' },
  { name = 'Noise', frag ='shaders/noise.frag' },
  { name = 'PAL', frag ='shaders/pal.frag' }, -- pal-singlepass (Phase Alternating Line)
  { name = 'Night', frag ='shaders/night.frag' }, -- linearize
  { name = 'Water', frag ='shaders/water.frag' },
  { name = 'Negative', frag ='shaders/negative.frag' },
  { name = 'Painting', frag ='shaders/painting.frag', ignoreAntiAliasing = true },
  -- { name = 'Pulse', frag = 'shaders/pulse.frag' }, -- Not that cool on local player walking
  -- { name = 'Fog', frag = 'shaders/fog.frag', tex1 = 'images/clouds.png' }, -- Not that cool on local player walking
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

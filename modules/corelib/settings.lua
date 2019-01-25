g_settings = makesingleton(g_configs.getSettings())

function g_settings.getValue(nodeKey, key, defaultValue) -- (nodeKey, key[, defaultValue])
  local nodeSettings = g_settings.getNode(nodeKey) or {}
  local value
  if defaultValue ~= nil then
    value = defaultValue
  end
  if nodeSettings[key] ~= nil then
    value = nodeSettings[key]
  end
  return value
end

function g_settings.setValue(nodeKey, key, value) -- (nodeKey, key, value)
  local nodeSettings = {}
  nodeSettings[key] = value
  g_settings.mergeNode(nodeKey, nodeSettings)
end

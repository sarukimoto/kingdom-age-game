local blinkTime = 250
local events    = {}

local function removeBlink(id)
  local creature = g_map.getCreatureById(id)
  if creature and creature:getBlinkHitEffect() then
    creature:setBlinkHitEffect(false)
  end

  removeEvent(events[id])
  events[id] = nil
end

Blink = {}

Blink.remove =
function (id, instantly)
  if instantly then
    removeBlink(id)
    return
  end

  removeEvent(events[id])
  events[id] = scheduleEvent(function() removeBlink(id) end, blinkTime)
end

Blink.removeAll =
function (instantly)
  for id, _ in ipairs(events) do
    Blink.remove(id, instantly)
  end
  if instantly then
    events = {}
  end
end

Blink.add =
function (id)
  local creature = g_map.getCreatureById(id)
  if not creature then return end

  -- Will keep enabled if another event is added before the last finishes
  if creature:getBlinkHitEffect() and events[id] then
    removeEvent(events[id])
  end
  creature:setBlinkHitEffect(true)

  Blink.remove(id)
end

function init()
  Blink.removeAll(true)
  ProtocolGame.registerExtendedOpcode(GameServerOpcodes.GameServerBlinkHit, onBlinkHit)
end

function terminate()
  Blink.removeAll(true)
  ProtocolGame.unregisterExtendedOpcode(GameServerOpcodes.GameServerBlinkHit)
end

function onBlinkHit(protocol, opcode, buffer)
  local params = string.split(buffer, ':')

  local id = tonumber(params[1])
  if not id then return end

  Blink.add(id)
end

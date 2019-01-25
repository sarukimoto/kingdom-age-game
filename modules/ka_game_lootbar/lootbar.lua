lootWidget = nil

local queue = {}
local config =
{
  maxItems = 10,
  shrinkTime = 1800,
  shrinkInterval = 50,
  showingTime = 5000
}

function initLootWidget()
  if lootWidget then
    return
  end

  lootWidget = g_ui.createWidget('LootPanel', modules.game_interface.getMapPanel())
  g_ui.createWidget('ItemBoxLeft', lootWidget)
  g_ui.createWidget('ItemBoxRight', lootWidget)
  lootWidget:setVisible(false)
  lootWidget:setWidth(48)
  adjustPosition(modules.game_interface.getMapPanel())
end

function adjustPosition(widget)
  if not lootWidget then
    return
  end

  addEvent(function()
    local mod = modules.ka_game_hotkeybars
    if mod and modules.game_interface.getCurrentViewMode() == 2 and mod.getHotkeyBars()[AnchorTop] then
      lootWidget:setMarginTop(modules.client_topmenu.getTopMenu():getHeight() + (mod.getHotkeyBars()[AnchorTop]:isVisible() and mod.getHotkeyBars()[AnchorTop]:getHeight() or 0) + math.floor((widget:getHeight() - widget:getMapHeight()) / 2) + 8)
    else
      lootWidget:setMarginTop(8)
    end
  end)
end

function updateLootWidget()
  local width = 0
  for i = 1, lootWidget:getChildCount() do
    local child = lootWidget:getChildByIndex(i)
    width = width + child:getWidth()
  end
  lootWidget:setWidth(width)
end

function onRemoveChild()
  if #queue > 0 then
    local item = queue[1]
    table.remove(queue, 1)
    addItem(item.item, item.count, item.name, item.pos)
  end

  if lootWidget:getChildCount() <= 2 then
    lootWidget:setVisible(false)
  end
end

function removeWidget(widget)
  if lootWidget:hasChild(widget) then
    lootWidget:removeChild(widget)
    onRemoveChild()
  end
end

function shrinkOut(widget, time)
  local opacity = time / config.shrinkTime
  local width = math.floor(widget.realWidth * math.min((time / config.shrinkTime) * 1.5, 1))
  if opacity <= 0 or width <= 0 then
    removeWidget(widget)
    return
  end

  local item = widget:getChildById('item')
  if item then
    item:setOpacity(opacity)
  end

  widget:setWidth(width)
  updateLootWidget()
  scheduleEvent(function() shrinkOut(widget, time - config.shrinkInterval) end, config.shrinkInterval)
end

function onHoverChange(widget, hovered)
  if hovered and os.time() > widget.lastHover then
    g_game.sendMagicEffect(widget.pos, 32)    -- stun / stars
    g_game.sendMagicEffect(widget.pos, 57)    -- orange square
    g_game.sendDistanceEffect(widget.pos, 41) -- red thing
    widget.lastHover = os.time()
  end
end

function addItem(id, count, name, pos)
  count = count or 1
  if lootWidget:getChildCount() - 2 >= config.maxItems then
    table.insert(queue, {item = id, count = count, name = name, pos = pos})
    return
  end

  local widget = g_ui.createWidget('ItemBoxContainer', lootWidget)
  widget:setTooltip((count > 1 and  count .. 'x 'or '') .. name)
  widget.realWidth = widget:getWidth()
  widget.pos = pos
  widget.lastHover = 0
  connect(widget, {onHoverChange = onHoverChange})

  lootWidget:moveChildToIndex(widget, lootWidget:getChildCount() - 1)
  lootWidget:setVisible(true)

  local item = widget:getChildById('item')
  item:setItemId(id)
  item:setItemCount(count)

  scheduleEvent(function() shrinkOut(widget, config.shrinkTime) end, config.showingTime)

  updateLootWidget()
end

function onLoot(protocol, opcode, buffer)
  local params = buffer:split(':')
  local pos = { x = tonumber(params[1]), y = tonumber(params[2]), z = tonumber(params[3]) }
  if not pos.x or not pos.y or not pos.z then
    pos = g_game.getLocalPlayer():getPosition()
  end

  for i = 4, #params do
    local _params = params[i]:split(';')
    for j = 1, 3 do
      -- Params 1 to 2 are numeric
      if j >= 1 and j <= 2 then
        _params[j] = tonumber(_params[j])
      end
      if not _params[j] then return end
    end
    addItem(_params[1], _params[2], _params[3], pos)
  end
end

function init()
  g_ui.importStyle('lootbar')

  ProtocolGame.registerExtendedOpcode(GameServerExtOpcodes.GameServerLootWindow, onLoot)
  connect(modules.game_interface.getMapPanel(), {
    onGeometryChange = adjustPosition
  })

  initLootWidget()
end

function terminate()
  if lootWidget then
    lootWidget:destroy()
  end

  ProtocolGame.unregisterExtendedOpcode(GameServerExtOpcodes.GameServerLootWindow)
  disconnect(modules.game_interface.getMapPanel(), {
    onGeometryChange = adjustPosition
  })
end

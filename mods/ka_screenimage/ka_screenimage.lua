screenImages = {}

local SCREENPOS_CENTER = 1
local SCREENPOS_TOP = 2
local SCREENPOS_TOPRIGHT = 3
local SCREENPOS_RIGHT = 4
local SCREENPOS_BOTTOMRIGHT = 5
local SCREENPOS_BOTTOM = 6
local SCREENPOS_BOTTOMLEFT = 7
local SCREENPOS_LEFT = 8
local SCREENPOS_TOPLEFT = 9

function init()
  ProtocolGame.registerExtendedOpcode(GameServerExtOpcodes.GameServerScreenImage, parseScreenImage)

  g_ui.importStyle('ka_screenimage.otui')

  connect(g_game, {
    onGameStart = clearImages,
    onGameEnd   = clearImages
  })

  connect(modules.game_interface.getMapPanel(), {
    onGeometryChange = adjustPositions,
    onViewModeChange = onViewModeChange
  })
end

function terminate()
  ProtocolGame.unregisterExtendedOpcode(GameServerExtOpcodes.GameServerScreenImage)

  clearImages()

  disconnect(g_game, {
    onGameStart = clearImages,
    onGameEnd   = clearImages
  })

  disconnect(modules.game_interface.getMapPanel(), {
    onGeometryChange = adjustPositions,
    onViewModeChange = onViewModeChange
  })
end

function onViewModeChange(mapWidget, newMode, oldMode)
  adjustPositions()
end

function adjustPosition(image)
  local mapWidget = modules.game_interface.getMapPanel()

  addEvent(function()
    local marginVertical = math.floor((mapWidget:getHeight() - mapWidget:getPaddingTop() - mapWidget:getPaddingBottom() - mapWidget:getMapHeight()) / 2)
    local marginHorizontal = math.floor((mapWidget:getWidth() - mapWidget:getPaddingLeft() - mapWidget:getPaddingRight() - mapWidget:getMapWidth()) / 2)

    if image.stretchHorizontal then
      image:setMarginLeft(marginHorizontal)
      image:setMarginRight(marginHorizontal)
    else
      if image.position == SCREENPOS_TOPLEFT or image.position == SCREENPOS_LEFT or image.position == SCREENPOS_BOTTOMLEFT then
        image:setMarginLeft(marginHorizontal)
      end
      if image.position == SCREENPOS_TOPRIGHT or image.position == SCREENPOS_RIGHT or image.position == SCREENPOS_BOTTOMRIGHT then
        image:setMarginRight(marginHorizontal)
      end
      if image.position == SCREENPOS_CENTER and image.stretchVertical then
        image:setMarginLeft(marginHorizontal)
      end
      if image.baseSizeOnGameScreen then
        image:setWidth(mapWidget:getMapWidth() * image.screenResizeX)
      end
    end

    if image.stretchVertical then
      image:setMarginTop(marginVertical)
      image:setMarginBottom(marginVertical)
    else
      if image.position == SCREENPOS_TOPLEFT or image.position == SCREENPOS_TOP or image.position == SCREENPOS_TOPRIGHT then
        image:setMarginTop(marginVertical)
      end
      if image.position == SCREENPOS_BOTTOMLEFT or image.position == SCREENPOS_BOTTOM or image.position == SCREENPOS_BOTTOMRIGHT then
        image:setMarginBottom(marginVertical)
      end
      if image.position == SCREENPOS_CENTER and image.stretchHorizontal then
        image:setMarginTop(marginVertical)
      end
      if image.baseSizeOnGameScreen then
        image:setHeight(mapWidget:getMapHeight() * image.screenResizeY)
      end
    end
  end)
end

function adjustPositions()
  for i = 1, #screenImages do
    adjustPosition(screenImages[i])
  end
end

function clearImages()
  for i = 1, #screenImages do
    local tmpImage = screenImages[i]

    if tmpImage then
      if tmpImage.fadeEvent then
        g_effects.cancelFade(tmpImage)
      end
      if tmpImage.destroyEvent then
        removeEvent(tmpImage.destroyEvent)
      end

      tmpImage:destroy()
    end
  end
  screenImages = {}
end

function getRootPath()
  return '/screenimages/'
end

function addImage(path, fadeIn, position, resizeX, resizeY, screenBased)
  if not path or not fadeIn or not position or not resizeX or not resizeY or not screenBased then return end

  local mapWidget = modules.game_interface.getMapPanel()
  local image = g_ui.createWidget('ScreenImage', mapWidget)
  image:setImageSource(string.format('%s%s', getRootPath(), path))

  if fadeIn ~= 0 then
    g_effects.fadeIn(image, fadeIn)
  end

  image.path                 = path
  image.position             = position
  image.stretchHorizontal    = resizeX == 0
  image.stretchVertical      = resizeY == 0
  image.baseSizeOnGameScreen = screenBased == 1
  image.screenResizeX        = resizeX
  image.screenResizeY        = resizeY

  if image.stretchHorizontal then
    image:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    image:addAnchor(AnchorRight, 'parent', AnchorRight)
  else
    if image.position == SCREENPOS_TOPLEFT or image.position == SCREENPOS_LEFT or image.position == SCREENPOS_BOTTOMLEFT then
      image:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    end
    if image.position == SCREENPOS_TOPRIGHT or image.position == SCREENPOS_RIGHT or image.position == SCREENPOS_BOTTOMRIGHT then
      image:addAnchor(AnchorRight, 'parent', AnchorRight)
    end
    if (image.position == SCREENPOS_CENTER or image.position == SCREENPOS_LEFT or image.position == SCREENPOS_RIGHT) and not image.stretchVertical then
      image:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
    elseif image.position == SCREENPOS_CENTER then
      image:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    end
    image:setWidth((image.baseSizeOnGameScreen and mapWidget:getMapWidth() or image:getWidth()) * resizeX)
  end

  if image.stretchVertical then
    image:addAnchor(AnchorTop, 'parent', AnchorTop)
    image:addAnchor(AnchorBottom, 'parent', AnchorBottom)
  else
    if image.position == SCREENPOS_TOPLEFT or image.position == SCREENPOS_TOP or image.position == SCREENPOS_TOPRIGHT then
      image:addAnchor(AnchorTop, 'parent', AnchorTop)
    end
    if image.position == SCREENPOS_BOTTOMLEFT or image.position == SCREENPOS_BOTTOM or image.position == SCREENPOS_BOTTOMRIGHT then
      image:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    end
    if (image.position == SCREENPOS_CENTER or image.position == SCREENPOS_TOP or image.position == SCREENPOS_BOTTOM) and not image.stretchHorizontal then
      image:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
    elseif image.position == SCREENPOS_CENTER then
      image:addAnchor(AnchorTop, 'parent', AnchorTop)
    end
    image:setHeight((image.baseSizeOnGameScreen and mapWidget:getMapHeight() or image:getHeight()) * resizeY)
  end

  table.insert(screenImages, image)
  adjustPosition(image)
end

local function removeSingleImage(index, fadeOut)
  local image = screenImages[index]
  if image --[[and image.path == path]] and not image.destroyEvent then
    if image.fadeEvent then
      g_effects.cancelFade(image)
    end

    if fadeOut == 0 then
      image:destroy()
      table.remove(screenImages, index)
    else
      g_effects.fadeOut(image, fadeOut)
      image.destroyEvent = scheduleEvent(function()
        if image.fadeEvent then
          g_effects.cancelFade(image)
        end
        for i = 1, #screenImages do
          if image == screenImages[i] then
            table.remove(screenImages, i)
          end
        end
        image:destroy()
      end, fadeOut)
    end
  end
end

function removeImage(path, fadeOut, mode)
  if not path or not fadeOut or not mode then return end

  if #screenImages < 1 then
    return
  end

  -- Remove last added of path
  if mode == 1 then
    local found = nil
    for i = #screenImages, 1, -1 do
      if screenImages[i] and screenImages[i].path == path then
        found = i
        break
      end
    end
    if found then
      removeSingleImage(found, fadeOut)
    end

  -- Remove first added of path
  elseif mode == -1 then
    local found = nil
    for i = 1, #screenImages do
      if screenImages[i] and screenImages[i].path == path then
        found = i
        break
      end
    end
    if found then
      removeSingleImage(found, fadeOut)
    end

  -- Remove all of path
  else
    for i = 1, #screenImages do
      if screenImages[i] and screenImages[i].path == path then
        removeSingleImage(i, fadeOut)
      end
    end
  end
end

function parseScreenImage(protocol, opcode, buffer)
  local params = string.split(buffer, ':')
  local state = tonumber(params[1])
  if not state then
    return
  end
  state = state == 1

  -- Add
  if state then
    for i = 2, 7 do
      -- Params 3 to 7 are numeric
      if i >= 3 and i <= 7 then
        params[i] = tonumber(params[i])
      end
      if not params[i] then return end
    end
    addImage(params[2], params[3], params[4], params[5], params[6], params[7]) -- (path, fadeIn, position, resizeX, resizeY, screenBased)

  -- Remove
  else
    for i = 2, 4 do
      -- Params 3 to 4 are numeric
      if i >= 3 and i <= 4 then
        params[i] = tonumber(params[i])
      end
      if not params[i] then return end
    end
    removeImage(params[2], params[3], params[4]) -- (path, fadeOut, mode)
  end
end

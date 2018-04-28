local backpackSize  = 20
local backpackPrice = 20

BUY = 1
SELL = 2
CURRENCY = 'GPs'
CURRENCY_DECIMAL = false
CURRENCY_VIP = 'KAps'
CURRENCY_ISVIP = false
WEIGHT_UNIT = 'oz'
LAST_INVENTORY = 10

npcWindow = nil
itemsPanel = nil
radioTabs = nil
radioItems = nil
searchText = nil
setupPanel = nil
quantity = nil
quantityScroll = nil
nameLabel = nil
priceLabel = nil
moneyLabel = nil
weightDesc = nil
weightLabel = nil
capacityDesc = nil
capacityLabel = nil
tradeButton = nil
buyTab = nil
sellTab = nil
initialized = false

showWeight = true
buyWithBackpack = nil
ignoreCapacity = nil
ignoreEquipped = nil
showAllItems = nil
sellAllButton = nil

playerFreeCapacity = 0
playerMoney = 0
tradeItems = {}
playerItems = {}
selectedItem = nil

cancelNextRelease = nil

function init()
  npcWindow = g_ui.displayUI('npctrade')
  npcWindow:setVisible(false)

  itemsPanel = npcWindow:recursiveGetChildById('itemsPanel')
  searchText = npcWindow:recursiveGetChildById('searchText')

  setupPanel = npcWindow:recursiveGetChildById('setupPanel')
  quantityScroll = setupPanel:getChildById('quantityScroll')
  nameLabel = setupPanel:getChildById('name')
  priceLabel = setupPanel:getChildById('price')
  moneyLabel = setupPanel:getChildById('money')
  weightDesc = setupPanel:getChildById('weightDesc')
  weightLabel = setupPanel:getChildById('weight')
  capacityDesc = setupPanel:getChildById('capacityDesc')
  capacityLabel = setupPanel:getChildById('capacity')
  tradeButton = npcWindow:recursiveGetChildById('tradeButton')

  buyWithBackpack = npcWindow:recursiveGetChildById('buyWithBackpack')
  ignoreCapacity = npcWindow:recursiveGetChildById('ignoreCapacity')
  ignoreEquipped = npcWindow:recursiveGetChildById('ignoreEquipped')
  showAllItems = npcWindow:recursiveGetChildById('showAllItems')
  sellAllButton = npcWindow:recursiveGetChildById('sellAllButton')

  buyTab = npcWindow:getChildById('buyTab')
  sellTab = npcWindow:getChildById('sellTab')

  radioTabs = UIRadioGroup.create()
  radioTabs:addWidget(buyTab)
  radioTabs:addWidget(sellTab)
  radioTabs:selectWidget(buyTab)
  radioTabs.onSelectionChange = onTradeTypeChange

  cancelNextRelease = false

  if g_game.isOnline() then
    playerFreeCapacity = g_game.getLocalPlayer():getFreeCapacity()
  end

  connect(g_game, { onGameEnd = hide,
                    onOpenNpcTrade = onOpenNpcTrade,
                    onCloseNpcTrade = onCloseNpcTrade,
                    onPlayerGoods = onPlayerGoods } )

  connect(LocalPlayer, { onFreeCapacityChange = onFreeCapacityChange,
                         onInventoryChange = onInventoryChange } )

  initialized = true
end

function terminate()
  initialized = false
  npcWindow:destroy()

  disconnect(g_game, {  onGameEnd = hide,
                        onOpenNpcTrade = onOpenNpcTrade,
                        onCloseNpcTrade = onCloseNpcTrade,
                        onPlayerGoods = onPlayerGoods } )

  disconnect(LocalPlayer, { onFreeCapacityChange = onFreeCapacityChange,
                            onInventoryChange = onInventoryChange } )
end

function show()
  if g_game.isOnline() then
    if #tradeItems[BUY] > 0 then
      radioTabs:selectWidget(buyTab)
    else
      radioTabs:selectWidget(sellTab)
    end

    npcWindow:show()
    npcWindow:raise()
    npcWindow:focus()
  end
end

function hide()
  npcWindow:hide()
end

function onItemBoxChecked(widget)
  if widget:isChecked() then
    local item = widget.item
    selectedItem = item
    refreshItem(item)
    tradeButton:enable()

    if getCurrentTradeType() == SELL then
      quantityScroll:setValue(quantityScroll:getMaximum())
    end
  end
end

function onQuantityValueChange(quantity)
  if selectedItem then
    local items, backpacks, price = getBuyAmount(selectedItem, quantity)
    priceLabel:setText(formatCurrency(price))
    weightLabel:setText(string.format('%.2f', quantity * selectedItem.weight) .. ' ' .. WEIGHT_UNIT)
  end
end

function onTradeTypeChange(radioTabs, selected, deselected)
  tradeButton:setText(selected:getText())
  selected:setOn(true)
  deselected:setOn(false)

  local currentTradeType = getCurrentTradeType()
  buyWithBackpack:setVisible(currentTradeType == BUY)
  ignoreCapacity:setVisible(currentTradeType == BUY)
  ignoreEquipped:setVisible(currentTradeType == SELL)
  showAllItems:setVisible(currentTradeType == SELL)
  sellAllButton:setVisible(currentTradeType == SELL)

  refreshTradeItems()
  refreshPlayerGoods()
end

function onTradeClick()
  if getCurrentTradeType() == BUY then
    g_game.buyItem(selectedItem.ptr, selectedItem.maskptr, quantityScroll:getValue(), ignoreCapacity:isChecked(), buyWithBackpack:isChecked())
  else
    g_game.sellItem(selectedItem.ptr, selectedItem.maskptr, quantityScroll:getValue(), ignoreEquipped:isChecked())
  end
end

function onSearchTextChange()
  refreshPlayerGoods()
end

function itemPopup(self, mousePosition, mouseButton)
  if cancelNextRelease then
    cancelNextRelease = false
    return false
  end

  local onLook = function() return g_game.inspectNpcTrade(self:getItem()) end
  if ((g_mouse.isPressed(MouseLeftButton) and mouseButton == MouseRightButton)
    or (g_mouse.isPressed(MouseRightButton) and mouseButton == MouseLeftButton)) then
    cancelNextRelease = true
    onLook()
    return true
  elseif mouseButton == MouseRightButton then
    local menu = g_ui.createWidget('PopupMenu')
    menu:setGameMenu(true)
    menu:addOption(tr('Look'), onLook, '(Shift)')
    menu:display(mousePosition)
    return true
  elseif mouseButton == MouseLeftButton and g_keyboard.isShiftPressed() then
    onLook()
    return true
  end
  return false
end

function onBuyWithBackpackChange()
  if selectedItem then
    refreshItem(selectedItem)
  end
end

function onIgnoreCapacityChange()
  refreshPlayerGoods()
end

function onIgnoreEquippedChange()
  refreshPlayerGoods()
end

function onShowAllItemsChange()
  refreshPlayerGoods()
end

function setCurrency(currency, decimal, isVip)
  CURRENCY = currency
  CURRENCY_DECIMAL = decimal
  CURRENCY_ISVIP = isVip
end

function setShowWeight(state)
  showWeight = state
  weightDesc:setVisible(state)
  weightLabel:setVisible(state)
end

function setShowYourCapacity(state)
  capacityDesc:setVisible(state)
  capacityLabel:setVisible(state)
  ignoreCapacity:setVisible(state)
end

function clearSelectedItem()
  nameLabel:clearText()
  weightLabel:clearText()
  priceLabel:clearText()
  tradeButton:disable()
  quantityScroll:setMinimum(0)
  quantityScroll:setMaximum(0)
  if selectedItem then
    radioItems:selectWidget(nil)
    selectedItem = nil
  end
end

function getCurrentTradeType()
  if tradeButton:getText() == tr('Buy') then
    return BUY
  else
    return SELL
  end
end

function getSellQuantity(item)
  if not item or not playerItems[item:getId()] then return 0 end
  local removeAmount = 0
  if ignoreEquipped:isChecked() then
    local localPlayer = g_game.getLocalPlayer()
    for i=1,LAST_INVENTORY do
      local inventoryItem = localPlayer:getInventoryItem(i)
      if inventoryItem and inventoryItem:getId() == item:getId() then
        removeAmount = removeAmount + inventoryItem:getCount()
      end
    end
  end
  return playerItems[item:getId()] - removeAmount
end

function canTradeItem(item)
  if getCurrentTradeType() == BUY then
    local items, backpacks, price = getBuyAmount(item, 1)
    return (ignoreCapacity:isChecked() or (not ignoreCapacity:isChecked() and playerFreeCapacity >= item.weight)) and playerMoney >= price and price ~= 0
  else
    local items, price = getSellAmount(item)
    return items >= 1 and price ~= 0
  end
end

function refreshItem(item)
  local quantity = quantityScroll:getValue()
  local items, backpacks, price = 0, 0, 0
  local _items, _backpacks, _price = 0, 0, 0
  if getCurrentTradeType() == BUY then
    items, backpacks, price = getBuyAmount(item)
    _items, _backpacks, _price = getBuyAmount(item, quantity)
  else
    items, price = getSellAmount(item)
  end

  nameLabel:setText(item.name)
  priceLabel:setText(formatCurrency(getCurrentTradeType() == BUY and _price ~= 0 and _price or quantity * item.price))
  weightLabel:setText(string.format('%.2f', quantity * item.weight) .. ' ' .. WEIGHT_UNIT)
  quantityScroll:setMinimum(items ~= 0 and 1 or 0)
  quantityScroll:setMaximum(items)

  setupPanel:enable()
end

function refreshTradeItems()
  local layout = itemsPanel:getLayout()
  layout:disableUpdates()

  clearSelectedItem()

  searchText:clearText()
  setupPanel:disable()
  itemsPanel:destroyChildren()

  if radioItems then
    radioItems:destroy()
  end
  radioItems = UIRadioGroup.create()

  local currentTradeItems = tradeItems[getCurrentTradeType()]
  for _,item in pairs(currentTradeItems) do
    local itemBox = g_ui.createWidget('NPCItemBox', itemsPanel)
    itemBox.item = item

    local text = ''
    local name = item.name
    text = text .. name
    if showWeight then
      local weight = string.format('%.2f', item.weight) .. ' ' .. WEIGHT_UNIT
      text = text .. '\n' .. weight
    end
    local price = formatCurrency(item.price)
    text = text .. '\n' .. price
    itemBox:setText(text)

    local itemWidget = itemBox:getChildById('item')
    itemWidget:setItem(item.maskptr or item.ptr)
    itemWidget.onMouseRelease = itemPopup

    radioItems:addWidget(itemBox)
  end

  layout:enableUpdates()
  layout:update()
end

function refreshPlayerGoods()
  if not initialized then return end

  checkSellAllTooltip()

  moneyLabel:setText(formatCurrency(playerMoney))
  tradeButton:setTooltip(CURRENCY_ISVIP and getCurrentTradeType() == BUY and 'Your VIP money may not be displayed correctly\nif points are added through the website\nwhile keeping the trade opened.' or '')
  capacityLabel:setText(string.format('%.2f', playerFreeCapacity) .. ' ' .. WEIGHT_UNIT)

  local currentTradeType = getCurrentTradeType()
  local searchFilter = searchText:getText():lower()
  local foundSelectedItem = false

  local items = itemsPanel:getChildCount()
  for i=1,items do
    local itemWidget = itemsPanel:getChildByIndex(i)
    local item = itemWidget.item

    local canTrade = canTradeItem(item)
    itemWidget:setOn(canTrade)
    itemWidget:setEnabled(canTrade)

    local searchCondition = (searchFilter == '') or (searchFilter ~= '' and string.find(item.name:lower(), searchFilter) ~= nil)
    local showAllItemsCondition = (currentTradeType == BUY) or (showAllItems:isChecked()) or (currentTradeType == SELL and not showAllItems:isChecked() and canTrade)
    itemWidget:setVisible(searchCondition and showAllItemsCondition)

    if selectedItem == item and itemWidget:isEnabled() and itemWidget:isVisible() then
      foundSelectedItem = true
    end
  end

  if not foundSelectedItem then
    clearSelectedItem()
  end

  if selectedItem then
    refreshItem(selectedItem)
  end
end

function onOpenNpcTrade(items, isVip)
  tradeItems[BUY] = {}
  tradeItems[SELL] = {}

  for _,item in pairs(items) do
    if item[5] > 0 then
      local newItem =
      {
        ptr     = item[1],
        maskptr = item[2],
        name    = item[3],
        weight  = item[4] / 100,
        price   = item[5]
      }
      table.insert(tradeItems[BUY], newItem)
    end

    if item[6] > 0 then
      local newItem =
      {
        ptr     = item[1],
        maskptr = item[2],
        name    = item[3],
        weight  = item[4] / 100,
        price   = item[6]
      }
      table.insert(tradeItems[SELL], newItem)
    end
  end

  CURRENCY_ISVIP = isVip

  refreshTradeItems()
  addEvent(show) -- player goods has not been parsed yet
end

function closeNpcTrade()
  g_game.closeNpcTrade()
  hide()
end

function onCloseNpcTrade()
  hide()
end

function onPlayerGoods(money, kaps, items)
  playerMoney = CURRENCY_ISVIP and kaps or money

  playerItems = {}
  for _,item in pairs(items) do
    local id = item[1]:getId()
    if not playerItems[id] then
      playerItems[id] = item[2]
    else
      playerItems[id] = playerItems[id] + item[2]
    end
  end

  refreshPlayerGoods()
end

function onFreeCapacityChange(localPlayer, freeCapacity, oldFreeCapacity)
  playerFreeCapacity = freeCapacity

  if npcWindow:isVisible() then
    refreshPlayerGoods()
  end
end

function onInventoryChange(inventory, item, oldItem)
  refreshPlayerGoods()
end

function getTradeItemData(id, type)
  if table.empty(tradeItems[type]) then
    return false
  end

  if type then
    for _,item in pairs(tradeItems[type]) do
      if item.ptr and item.ptr:getId() == id then
        return item
      end
    end
  else
    for _,items in pairs(tradeItems) do
      for _,item in pairs(items) do
        if item.ptr and item.ptr:getId() == id then
          return item
        end
      end
    end
  end
  return false
end

function checkSellAllTooltip()
  sellAllButton:setEnabled(true)
  sellAllButton:removeTooltip()

  local total = 0
  local info = ''
  local first = true

  for key, _ in pairs(playerItems) do
    local item = getTradeItemData(key, SELL)
    if item then
      local items, price = getSellAmount(item)
      if items > 0 then
        info = string.format("%s%s%d %s (%d %s)", info, (not first and "\n" or ""), items, item.name, price, tr(CURRENCY))
        total = total + price
        if first then first = false end
      end
    end
  end
  if info ~= '' then
    info = string.format("%s\nTotal: %d %s", info, total, tr(CURRENCY))
    sellAllButton:setTooltip(info)
  else
    sellAllButton:setEnabled(false)
  end
end

function formatCurrency(amount)
  if CURRENCY_DECIMAL then
    return string.format("%.02f", amount/100.0) .. ' ' .. (CURRENCY_ISVIP and CURRENCY_VIP or CURRENCY)
  else
    return amount .. ' ' .. (CURRENCY_ISVIP and CURRENCY_VIP or CURRENCY)
  end
end

function getMaxAmount()
  if getCurrentTradeType() == SELL and g_game.getFeature(GameDoubleShopSellAmount) then
    return 10000
  end
  return 100
end

function sellAll()
  for itemid,_ in pairs(playerItems) do
    local item = getTradeItemData(itemid, SELL)
    if item then
      local quantity = getSellQuantity(item.ptr)
      if quantity > 0 then
        g_game.sellItem(item.ptr, item.maskptr, quantity, ignoreEquipped:isChecked())
      end
    end
  end
end

function getBuyAmount(item, count) -- (item[, count])
  local items = 0
  local buyWithBackpacks = buyWithBackpack:isChecked()

  if item.ptr:isStackable() or not buyWithBackpacks then
    local _playerMoney = math.max(0, playerMoney - (buyWithBackpacks and backpackPrice or 0))
    items = math.floor(_playerMoney / item.price)
  else

    -- Non stackable and buyWithBackpack
    local _playerMoney = playerMoney
    local minimumCost  = item.price + backpackPrice
    -- Should be possible to buy at least 1 item + 1 backpack and have bought less than 100 items to next loop
    while _playerMoney >= minimumCost and items < getMaxAmount() do -- Buying each backpack of items until 100 items (it will loop until 5 times, since 100 is the limit)
      local amount = math.min(math.floor(_playerMoney / item.price), backpackSize)
      _playerMoney = _playerMoney - backpackPrice - amount * item.price
      items = items + amount
    end
  end

  local capacityMaxCount = not ignoreCapacity:isChecked() and math.floor(playerFreeCapacity / item.weight) or 65535
  items = math.max(0, math.min(count or items, getMaxAmount(), capacityMaxCount))
  local backpacks = buyWithBackpacks and (not item.ptr:isStackable() and math.ceil(items / backpackSize) or items >= 1 and 1 or 0) or 0
  local price     = items * item.price + backpacks * backpackPrice

  if count and count > items then
    return 0, 0, 0
  end
  return items, backpacks, price
end

function getSellAmount(item, count) -- (item[, count])
  local items = getSellQuantity(item.ptr)
  local buyWithBackpacks = buyWithBackpack:isChecked()
  items       = math.max(0, math.min(count or items, getMaxAmount()))
  local price = items * item.price

  if count and count > items then
    return 0, 0, 0
  end
  return items, price
end

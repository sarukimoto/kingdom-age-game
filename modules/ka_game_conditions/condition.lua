CONDITION_ATTR_REMAININGTIME = 1
CONDITION_ATTR_TURNS         = 2
CONDITION_ATTR_POWER         = 3
CONDITION_ATTR_DESCRIPTION   = 4
CONDITION_ATTR_ORIGINID      = 5
CONDITION_ATTR_ORIGINNAME    = 6
CONDITION_ATTR_ATTRIBUTE     = 7
CONDITION_ATTR_ENDLIST       = 255

CONDITION_ACTION_UPDATE = 1
CONDITION_ACTION_REMOVE = 2

conditionList = {}

--[[
  Condition Object:
  - (number)  id
  - (number)  subId
  - (string)  name
  - (boolean) isAgressive

  - (number)  remainingTime (optional)
  - (number)  turns (optional)
  - (number)  powerId (optional)
  - (number)  boost (optional)

]]

function parseConditions(protocol, msg)
  local action = msg:getU8()

  local condition = {}
  condition.id    = msg:getU8()
  condition.subId = msg:getU8()

  -- Insert / Update
  if action == CONDITION_ACTION_UPDATE then
    condition.name = msg:getString()
    condition.aggressive = msg:getU8()

    local nextByte = msg:getU8()
    while nextByte ~= CONDITION_ATTR_ENDLIST do
      if nextByte == CONDITION_ATTR_REMAININGTIME then
        condition.remainingTime = msg:getU32()
      elseif nextByte == CONDITION_ATTR_TURNS then
        condition.turns = msg:getU32()
      elseif nextByte == CONDITION_ATTR_POWER then
        condition.powerId = msg:getU8()
        condition.powerName = msg:getString()
        condition.boost = msg:getU8()
      elseif nextByte == CONDITION_ATTR_DESCRIPTION then
        condition.description = msg:getString()
      elseif nextByte == CONDITION_ATTR_ORIGINID then
        condition.originId = msg:getU32()
      elseif nextByte == CONDITION_ATTR_ORIGINNAME then
        condition.originName = msg:getString()
      elseif nextByte == CONDITION_ATTR_ATTRIBUTE then
        condition.attribute = msg:getU8()
        condition.offset = msg:getString()
        condition.factor = msg:getString()
      else
        print("Unknown byte: " .. nextByte)
      end
      nextByte = msg:getU8()
    end
    addCondition(condition)

  -- Remove
  elseif action == CONDITION_ACTION_REMOVE then
    removeCondition(condition)
  end
end

function getConditionIndex(id, subId)
  for i, condition in pairs(conditionList) do
    if condition.id == id and condition.subId == subId then
      return i
    end
  end
  return nil
end

function addCondition(condition)
  condition.startTime = os.time()
  condition.button = g_ui.createWidget('ConditionButton')
  condition.button:setup(condition)
  table.insert(conditionList, condition)
  conditionPanel:addChild(condition.button)
  updateConditionList()
end

function removeCondition(condition)
  local index = getConditionIndex(condition.id, condition.subId)
  if index then
    if conditionList[index] then
      conditionList[index].button:destroy()
    end
    table.remove(conditionList, index)
    updateConditionList()
  -- else
  --   print("Trying to remove invalid condition")
  end
end

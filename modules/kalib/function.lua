function getDistanceTo(fromPos, toPos)
  local xDif, yDif = math.abs(fromPos.x - toPos.x), math.abs(fromPos.y - toPos.y)
  local dif = math.max(xDif, yDif)
  return fromPos.z == toPos.z and dif or dif + 15
end

function expForLevel(level)
  return math.floor((50*level*level*level)/3 - 100*level*level + (850*level)/3 - 200)
end

function expToAdvance(currentLevel, currentExp)
  return expForLevel(currentLevel+1) - currentExp
end

function getExperienceTooltipText(localPlayer, value, percent)
  local ret = tr('Remaining %d%% (%d XP) to advance to level %d', string.format("%.2f", 100 - percent), expToAdvance(localPlayer:getLevel(), localPlayer:getExperience()), value + 1)
  if type(localPlayer.expSpeed) == "number" then
     local xpPerHour = math.floor(localPlayer.expSpeed * 3600)
     if xpPerHour > 0 then
        local xpNextLevel = expForLevel(localPlayer:getLevel() + 1)
        local hoursLeft   = (xpNextLevel - localPlayer:getExperience()) / xpPerHour
        local minutesLeft = math.floor((hoursLeft - math.floor(hoursLeft)) * 60)
        ret = string.format('%s\n%s\n%s', ret, tr('%d XP per hour', xpPerHour), tr('Next level in %d hours and %d minutes', math.floor(hoursLeft), minutesLeft))
     end
  end
  return ret
end

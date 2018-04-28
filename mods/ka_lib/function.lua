function getDistanceTo(fromPos, toPos)
  local xDif, yDif = math.abs(fromPos.x - toPos.x), math.abs(fromPos.y - toPos.y)
  local dif = math.max(xDif, yDif)
  return fromPos.z == toPos.z and dif or dif + 15
end

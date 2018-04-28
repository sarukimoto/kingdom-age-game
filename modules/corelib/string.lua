-- @docclass string

function string:split(delim)
  local start = 1
  local results = {}
  while true do
    local pos = string.find(self, delim, start, true)
    if not pos then
      break
    end
    table.insert(results, string.sub(self, start, pos-1))
    start = pos + string.len(delim)
  end
  table.insert(results, string.sub(self, start))
  table.removevalue(results, '', true)
  return results
end

function string:starts(start)
  return string.sub(self, 1, #start) == start
end

function string:ends(test)
   return test =='' or string.sub(self,-string.len(test)) == test
end

function string:trim()
  return string.match(self, '^%s*(.*%S)') or ''
end

function string:explode(sep, limit)
  if type(sep) ~= 'string' or tostring(self):len() == 0 or sep:len() == 0 then
    return {}
  end

  local i, pos, tmp, t = 0, 1, "", {}
  for s, e in function() return string.find(self, sep, pos) end do
    tmp = self:sub(pos, s - 1):trim()
    table.insert(t, tmp)
    pos = e + 1

    i = i + 1
    if limit ~= nil and i == limit then
      break
    end
  end

  tmp = self:sub(pos):trim()
  table.insert(t, tmp)
  return t
end

function string:contains(...)
  for _, keyword in ipairs({ ... }) do
    if (" " .. self .. " "):find("%s+" .. keyword .. "[%s%p]+") then
      return true
    end
  end
  -- return message:find(keyword) and not message:find('(%w+)' .. keyword)
  return false
end

-- :+ to : and ;+ to ;
function string:asOpcodeString()
  return self:gsub(":+", ":"):gsub(";+", ";")
end

local function getFatorial(n)
  return n == 0 and 1 or n * getFatorial(n - 1)
end

local function randomizeTable(_table, begin, final) -- (_table[, begin[, final]])
  -- math.randomseed(os.time()) -- do not use
  if not _table or type(_table) ~= "table" or table.empty(_table) then
    return nil
  end
  if begin == -1 or final == -1 then
    return _table
  end

  local sequence, ret = {}, {}
  -- Randomize Table Positions
  local size = begin and final and final-begin+1 or #_table
  while #sequence ~= size do
    local random = begin and final and math.random(begin, final) or math.random(#_table)
    if not table.contains(sequence, random) then
      table.insert(sequence, random)
    end
  end

  -- Copy table
  local cache = {}
  for i=1, #_table do
    cache[i] = _table[i]
  end

  for k1,v1 in pairs(_table) do
    for k2,v2 in pairs(sequence) do
      if k1 == k2+(begin and begin-1 or 0) then
        _table[k1] = cache[v2]
      end
    end
  end
  return _table
end

function string:getCombinations(begin, final, size, result) -- ([begin[, final[, size[, result]])
  result = result or 1
  local letters, combinations = {}, {}

  local string_length = self:len()
  for i = 1, string_length do
    table.insert(letters, string.sub(self, i, i))
  end

  local _result = 0
  while true do
    local str = table.concat(randomizeTable(letters, begin, final) or {}, "")

    -- Cut
    if size and type(size) == "number" and size >= 1 and size < #str then
      str = str:sub(1, size)
    end

    -- Combine
    if not table.contains(combinations, str) then
      table.insert(combinations, str)
    end
    if #combinations == getFatorial(string_length) then
      break
    end

    _result = _result + 1
    if _result >= result then
      break
    end
  end
  table.sort(combinations)
  --print(table.concat(combinations, "\n"))
  return combinations
end

function string:mix(lockBorders, decrease)
  local words = string.explode(self, " ")
  local ret = ""
  for k,v in pairs(words) do
    local begin  = lockBorders and (#v >= 4 and 2 or -1) or 1
    local final  = lockBorders and (#v >= 4 and #v-1 or -1) or #v
    ret = ret .. v:getCombinations(begin, final, decrease and math.random(#v) or #v)[1] .. (k ~= #words and " " or "")
  end
  return ret
end

function string:removeBorders(begin, final) -- ([begin], [final])
  return self:match((begin or "") .. "(.+)" .. (final or ""))
end

function string:getCompactPath() -- path/file.ext to path/file
  return self:match("(.+)%..-$")
end

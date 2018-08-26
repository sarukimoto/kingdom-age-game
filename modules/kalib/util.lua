function dumpvar(data)
  local tablecache = {}
  local buffer = ''
  local padder = '    '

  local function _dumpvar(d, depth)
    local t = type(d)
    local str = tostring(d)
    if t == 'table' then
      if tablecache[str] then
        -- Table already dumped before, so we dont
        -- Dump it again, just mention it
        buffer = buffer .. '<' .. str .. '>\n'
      else
        tablecache[str] = (tablecache[str] or 0) + 1
        buffer = buffer .. '\n' .. string.rep(padder, depth) .. '(' .. str .. ')\n' .. string.rep(padder, depth) .. '{\n'
        for k, v in pairs(d) do
          buffer = buffer .. string.rep(padder, depth + 1) .. '[' .. (type(k) == 'string' and '\"' .. k .. '\"' or k) .. '] = '
          _dumpvar(v, depth + 1)
        end
        buffer = buffer .. string.rep(padder, depth) .. '}\n'
      end
    elseif t == 'number' then
      buffer = buffer .. '(' .. t .. ') ' .. str .. '\n'
    elseif t == 'nil' then
      buffer = buffer .. '(' .. t .. ') ' .. 'nil' .. '\n'
    else
      buffer = buffer .. '(' .. t .. ') \"' .. str .. '\"\n'
    end
  end

  _dumpvar(data, 0)
  return buffer
end

-- Is NOT possible to print a nil value inside a table
-- If you want to know if a value is nil, use it as the first param
function print_r(...)
  if ... == nil then
    print(dumpvar())
    return true
  end

  local args = {...}
  if type(args) ~= "table" or table.empty(args) then
    return false
  end
  for _,arg in pairs(args) do
    g_logger.info(dumpvar(arg))
  end
  return true
end

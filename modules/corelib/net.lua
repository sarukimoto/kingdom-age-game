function translateNetworkError(errcode, connecting, errdesc)
  local text
  if errcode == 111 then
    text = tr('Connection refused, the server might be offline or restarting.\nTry again later.')
  elseif errcode == 110 then
    text = tr('Connection timed out. Either your network is failing or the server is offline.')
  elseif errcode == 1 then
    text = tr('Connection failed, the server address does not exist.')
  elseif connecting then
    text = tr('Connection failed.')
  else
    text = tr('Connection timed out. Either your network is failing or the server is offline.')
  end
  text = text .. ' ' .. tr('ERROR') .. ': ' .. errcode
  return text
end

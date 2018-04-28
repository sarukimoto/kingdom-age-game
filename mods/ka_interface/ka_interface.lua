function init()
	connect(g_game, { onGameStart = onGameStart })

	ProtocolGame.registerExtendedOpcode(GameServerOpcodes.GameServerCustomBox, parseDisplayCustomBox)
end

function terminate()
	disconnect(g_game, { onGameStart = onGameStart })

	ProtocolGame.unregisterExtendedOpcode(GameServerOpcodes.GameServerCustomBox)
end


function onGameStart()
	-- Nothing yet
end





function parseDisplayCustomBox(protocol, opcode, buffer)
  local params                     = string.split(buffer, ':')
  local windowId                   = tonumber(params[1])
  local title                      = params[2] ~= '-' and params[2] or nil
  local message                    = params[3] ~= '-' and params[3] or nil
  local buttonIndexOnEnterCallback = tonumber(params[4])
  local cancelText                 = params[5] ~= '-' and params[5] or nil
  local buttonWidth                = tonumber(params[6])
  local buttons                    = {}
  for i = 7, #params do
    table.insert(buttons, {text = params[i]})
  end
  displayServerCustomBox(windowId, title, message, buttons, buttonIndexOnEnterCallback, cancelText, buttonWidth)
end

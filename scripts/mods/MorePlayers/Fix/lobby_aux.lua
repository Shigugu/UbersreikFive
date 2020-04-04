--[[
	Patch server name
]]--

local mod = get_mod("MorePlayers")

mod:hook(LobbyAux, "get_unique_server_name", function(func)
	return "[MorePlayers] " .. func()
end)
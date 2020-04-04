local mod = get_mod("MorePlayers")

local MOREPLAYER_CHANNEL = 8

mod.network = {}

--[[
	Load custom network_config file
]]--
mod:hook(Network, "init_steam_client", function(func, config)
	--config = "content/MorePlayers/global"
	
	mod:debug(string.format("Network.init_steam_client(%s)", config))
	
	return func(config)
end)

--[[
mod:command("network_modded", "", function(...)
	LobbyInternal.client = Network.init_steam_client("global")
end)

mod:command("network_global", "", function(...)
	LobbyInternal.client = Network.init_steam_client("content/MorePlayers/global")
end)
]]--

mod:hook(Network, "config_hash", function(func, config_resource)
	local hash = func(config_resource)
	
	mod:debug(string.format("Network.config_hash(%s) = %s(%s)", config_resource, hash, type(hash)))
	
	return hash
end)

mod.send_rpc = function (rpc_name, peer_id, ...)
	local network_manager = Managers.state.network
	
	if network_manager then
		local data = cjson.encode({...})
		
		network_manager.network_transmit:send_rpc(
			"rpc_chat_message", peer_id, MOREPLAYER_CHANNEL, Network.peer_id(), 0, rpc_name, {data}, false, false, false, true, false
		)
	end
end

mod.send_rpc_server = function (rpc_name, ...)
	local network_manager = Managers.state.network
	
	if network_manager then
		local data = cjson.encode({...})
		
		network_manager.network_transmit:send_rpc_server(
			"rpc_chat_message", MOREPLAYER_CHANNEL, Network.peer_id(), 0, rpc_name, {data}, false, false, false, true, false
		)
	end
end

mod.send_rpc_clients = function (rpc_name, ...)
	local network_manager = Managers.state.network
	
	if network_manager then
		local data = cjson.encode({...})
		
		network_manager.network_transmit:send_rpc_clients(
			"rpc_chat_message", MOREPLAYER_CHANNEL, Network.peer_id(), 0, rpc_name, {data}, false, false, false, true, false
		)
	end
end

mod.send_rpc_clients_except = function (rpc_name, except, ...)
	local network_manager = Managers.state.network
	
	if network_manager then
		local data = cjson.encode({...})
		
		network_manager.network_transmit:send_rpc_clients_except(
			"rpc_chat_message", except, MOREPLAYER_CHANNEL, Network.peer_id(), 0, rpc_name, {data}, false, false, false, true, false
		)
	end
end

mod.send_rpc_all = function (rpc_name, ...)
	local network_manager = Managers.state.network
	
	if network_manager then
		local data = cjson.encode({...})
		
		network_manager.network_transmit:send_rpc_all(
			"rpc_chat_message", MOREPLAYER_CHANNEL, Network.peer_id(), 0, rpc_name, {data}, false, false, false, true, false
		)
	end
end

mod.send_rpc_all_except = function (rpc_name, except, ...)
	local network_manager = Managers.state.network
	
	if network_manager then
		local data = cjson.encode({...})
		
		network_manager.network_transmit:send_rpc_all_except(
			"rpc_chat_message", except, MOREPLAYER_CHANNEL, Network.peer_id(), 0, rpc_name, {data}, false, false, false, true, false
		)
	end
end

mod:hook("ChatManager", "rpc_chat_message", function(func, self, sender, channel_id, message_sender, arg1, rpc_name, data, ...)
	if channel_id == MOREPLAYER_CHANNEL then
		mod:debug("custom rpc " .. tostring(rpc_name))
		
		local rpc_manager = mod.network[rpc_name]
		if rpc_manager then
			local rpc_func = rpc_manager[rpc_name]	
			if rpc_func then
				local data = cjson.decode(data[1])
			
				rpc_func(rpc_manager, sender, unpack(data))
			end
		end
	else
		return func(self, sender, channel_id, message_sender, arg1, rpc_name, data, ...)
	end
end)

--[[
	Patched profile data rpc calls. They have a restriction that this data can not have a bigger array then 6 elements
	
	Fix:
		I json encode and decode the variables in the host_cookie variable. This is a string variable.
		I place the host_cookie, peer_ids and player_indices inside it.
		Added pcall to detect server has MorePlayers mod, if not it switch to the old rpc protocol
]]--
local mod = get_mod("MorePlayers")

mod:hook(MatchmakingManager, "init", function(func, self, ...)
	mod.network["rpc_matchmaking_request_profiles_data_reply"] = self
	mod.network["rpc_matchmaking_update_profiles_data"] = self
	
	return func(self, ...)
end)

mod:hook(MatchmakingManager, "rpc_matchmaking_request_profiles_data", function(func, self, sender, client_cookie, host_cookie)
	if not self.handshaker_host:validate_cookies(sender, client_cookie, host_cookie) then
		return
	end

	local peer_ids, player_indices = self.slot_allocator:pack_for_transmission()
	
	--self.network_transmit:send_rpc("rpc_matchmaking_request_profiles_data_reply", sender, client_cookie, host_cookie, peer_ids, player_indices)
	mod.send_rpc("rpc_matchmaking_request_profiles_data_reply", sender, client_cookie, host_cookie, peer_ids, player_indices)
end)

mod:hook(MatchmakingHandshakerHost, "send_rpc_to_clients", function(func, self, rpc_name, ...)
	local rpc = RPC[rpc_name]

	for peer_id, client_cookie in pairs(self.clients) do
		if rpc_name == "rpc_matchmaking_update_profiles_data" then
			mod.send_rpc(peer_id, client_cookie, self.cookie, ...)
		else
			rpc(peer_id, client_cookie, self.cookie, ...)
		end
	end
end)

--[[
	██████╗ ███████╗██████╗ ██╗   ██╗ ██████╗ 
	██╔══██╗██╔════╝██╔══██╗██║   ██║██╔════╝ 
	██║  ██║█████╗  ██████╔╝██║   ██║██║  ███╗
	██║  ██║██╔══╝  ██╔══██╗██║   ██║██║   ██║
	██████╔╝███████╗██████╔╝╚██████╔╝╚██████╔╝
	╚═════╝ ╚══════╝╚═════╝  ╚═════╝  ╚═════╝ 
]]--
mod:hook(MatchmakingManager, "rpc_matchmaking_request_profiles_data_reply", function(func, self, sender, client_cookie, host_cookie, profile_array, player_id_array)
	mod:debug(string.format("MatchmakingManager.rpc_matchmaking_request_profiles_data_reply(%s)", sender))
	
	return func(self, sender, client_cookie, host_cookie, profile_array, player_id_array)
end)

mod:hook(MatchmakingManager, "rpc_matchmaking_update_profiles_data", function(func, self, sender, client_cookie, host_cookie, profile_array, player_id_array)
	mod:debug(string.format("MatchmakingManager.rpc_matchmaking_update_profiles_data(%s)", sender))
	
	return func(self, sender, client_cookie, host_cookie, profile_array, player_id_array)
end)

mod:hook(MatchmakingManager, "rpc_matchmaking_request_profile", function(func, self, sender, client_cookie, host_cookie, profile_index)
	mod:debug(string.format("MatchmakingManager.rpc_matchmaking_request_profile(%s, %s)", sender, profile_index))
	
	local player_slot_available = self.slot_allocator:is_free(profile_index)
	
	mod:debug("MatchmakingManager.rpc_matchmaking_request_profile(" .. tostring(profile_index) .. ")")
	mod:debug("player_slot_available = " .. tostring(player_slot_available))
	
	return func(self, sender, client_cookie, host_cookie, profile_index)
end)
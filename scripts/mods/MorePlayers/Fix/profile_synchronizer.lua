--[[
	The ProfileSynchronizer had a local NUM_PLAYERS that was 5,
	also "rpc_server_mark_profile_used" had a restriction that it only could have max 7 as profile_index
	
	Fix:
		1e: Redeclair the functions that use this local variable and let it run by my mod variable NUM_PLAYERS
		2e: Made a custom rpc_server_mark_profile_used to have no parameter restrictions
		3e: When the server leave it reinitialize the profiles and by unknown causes it also sends to
		his clients that has been connected before. Because of this i check before "rpc_server_mark_profile_used"
		can be executed. (console log: rpc_server_mark_profile_used.log)
]]--
local mod = get_mod("MorePlayers")
local DebugMenu = get_mod("DebugMenu")

local NO_CLIENT_SYNC_ID = 0
local REQUEST_RESULTS = {
	"success",
	"failure",
	success = 1,
	failure = 2
}
local NO_PEER = "0"
local EMPTY_TABLE = {}
local NO_LOCAL_PLAYER_ID = 0
local IS_LOCAL_CALL = "is_local_call"

mod:hook(ProfileSynchronizer, "init", function(func, self, is_server, lobby_host, network_server)
	mod:debug("ProfileSynchronizer.init")
	
	mod:dofile("scripts/mods/MorePlayers/Fix/chat_manager")
	
	-- When you start your own server or connect to a new server reset to start
	mod.SPProfiles:reset()
	mod.ProfilePriority:reset()
	
	-- Register that this rpc call must be send without limitations
	mod.network["rpc_server_mark_profile_used"] = self
	mod.network["rpc_client_request_mark_profile"] = self
	
	local profile_owners = {}
	
	for i = 1, mod.NUM_PROFILES, 1 do
		profile_owners[i] = StrictNil
	end

	profile_owners[0] = StrictNil
	self._profile_owners = MakeTableStrict(profile_owners)

	if is_server then
		self._lobby_host = lobby_host
		self._is_server = is_server
		self._inventory_package_synchronizer_server = InventoryPackageSynchronizer:new()
		self._network_server = network_server
		self._slot_allocator = self._network_server.slot_allocator
	end

	self._inventory_package_synchronizer = InventoryPackageSynchronizerClient:new(is_server)
	self._peer_id = Network.peer_id()
	self._inventory_sync_id = 0
	self._client_sync_id = 0
	self._client_sync_id_map = {}
	self._loaded_peers = {}
	self._request_result = nil
	self._request_local_player_id = nil
	self._all_synced = false
	self._player_manager = Managers.player
	self._reserved_profiles = {}
	self._hot_join_synced_peers = {}
end)

mod:hook(ProfileSynchronizer, "_send_rpc_lobby_clients", function(func, self, rpc, ...)
	fassert(self._is_server, "Trying to send rpc to lobby clients without being lobby host.")

	local members = self._lobby_host:members()

	if not members or members:get_members() == nil then
		return
	end

	for _, peer_id in ipairs(members:get_members()) do
		if peer_id ~= Network.peer_id() and self._hot_join_synced_peers[peer_id] then
			if rpc == "rpc_server_mark_profile_used" then
				--DebugMenu.app.list:setList({...})
				--mod:debug("DebugMenu")
				
				local arg = {...}
				local arg_peer_id = arg[1]
				local arg_local_player_id = arg[2]
				local arg_previous_profile_index = arg[3]
				local arg_profile_index = arg[4]
				local character_id = mod.SPProfiles:get_character_id(arg_profile_index)
				
				mod.send_rpc("rpc_server_mark_profile_used", peer_id, arg_peer_id, arg_local_player_id, arg_previous_profile_index, arg_profile_index, character_id)
			else
				RPC[rpc](peer_id, ...)
			end
		end
	end
end)

mod:hook(ProfileSynchronizer, "hot_join_sync", function(func, self, peer_id, local_ids)
	local profile_owners = self._profile_owners
	local network_transmit = self._network_transmit
	local player_manager = self._player_manager
	local self_peer_id = Network.peer_id()

	for i = 1, mod.NUM_PROFILES, 1 do
		local owner_table = profile_owners[i]

		if owner_table then
			local owner_peer_id = owner_table.peer_id
			local owner_local_player_id = owner_table.local_player_id

			if owner_peer_id ~= peer_id then
				if self_peer_id == peer_id then
					self:rpc_server_mark_profile_used(IS_LOCAL_CALL, owner_peer_id, owner_local_player_id, 0, i)
				else
					--network_transmit:send_rpc("rpc_server_mark_profile_used", peer_id, owner_peer_id, owner_local_player_id, 0, i)
					
					local character_id = mod.SPProfiles:get_character_id(i)
					mod.send_rpc("rpc_server_mark_profile_used", peer_id, owner_peer_id, owner_local_player_id, 0, i, character_id)
				end
			end
		elseif self_peer_id == peer_id then
			self:rpc_server_mark_profile_used(IS_LOCAL_CALL, NO_PEER, NO_LOCAL_PLAYER_ID, 0, i)
		else
			--network_transmit:send_rpc("rpc_server_mark_profile_used", peer_id, NO_PEER, NO_LOCAL_PLAYER_ID, 0, i)
			
			local character_id = mod.SPProfiles:get_character_id(i)
			mod.send_rpc("rpc_server_mark_profile_used", peer_id, NO_PEER, NO_LOCAL_PLAYER_ID, 0, i, character_id)
		end
	end

	self._all_synced = false
	local peer_table = self._loaded_peers[peer_id] or {}

	for _, local_player_id in pairs(local_ids) do
		peer_table[local_player_id] = false
	end

	self._loaded_peers[peer_id] = peer_table
end)

mod:hook(ProfileSynchronizer, "get_first_free_profile", function (func, self)
	local ProfilePriority = ProfilePriority

	for i = 1, mod.NUM_PROFILES, 1 do
		local prioritized_profile_id = ProfilePriority[i]

		if not self._profile_owners[prioritized_profile_id] then
			return prioritized_profile_id
		end
	end

	table.dump(self._profile_owners, "profile owners", 2)
	fassert(false, "Trying to get free profile when there are no free profiles.")
end)

mod:hook(ProfileSynchronizer, "rpc_server_mark_profile_used", function (func, self, sender, peer_id, local_player_id, previous_profile_index, profile_index, character_id)
	mod:debug("ProfileSynchronizer.rpc_server_mark_profile_used(%s, %s, %s, %s, %s, %s)", sender, peer_id, local_player_id, previous_profile_index, profile_index, character_id)
	
	if character_id then
		mod.SPProfiles:set(profile_index, character_id)
	end
	
	return func(self, sender, peer_id, local_player_id, previous_profile_index, profile_index)
end)

--[[
	Send the character_id it wants to be
]]--
mod:hook(ProfileSynchronizer, "request_select_profile", function (func, self, profile_index, local_player_id)
	assert(not self._has_pending_request)

	local network_manager = Managers.state.network
	local game_session = network_manager:game()

	if game_session then
		self._has_pending_request = true
		
		local character_id = mod.SPProfiles:get_character_id(profile_index)
		
		mod.send_rpc_server("rpc_client_request_mark_profile", profile_index, local_player_id, character_id)
	end
end)

--[[
	If client is accepted to use this profile spot then it also need to patch the moddified SPProfiles list
]]--
mod:hook(ProfileSynchronizer, "rpc_client_request_mark_profile", function (func, self, sender, profile_index, local_player_id, character_id)
	mod:debug(string.format("ProfileSynchronizer.rpc_client_request_mark_profile(%s, %s, %s, %s)", sender, profile_index, local_player_id, character_id))
	
	local profile_owner = self._profile_owners[profile_index]
	local owned_by_another = profile_owner and profile_owner.peer_id ~= sender

	if owned_by_another then
		local result = REQUEST_RESULTS.failure

		self._network_transmit:send_rpc("rpc_server_request_mark_profile_result", sender, profile_index, result, local_player_id)
	else
		local result = REQUEST_RESULTS.success

		self._network_transmit:send_rpc("rpc_server_request_mark_profile_result", sender, profile_index, result, local_player_id)

		self._reserved_profiles[profile_index] = nil
		
		mod.SPProfiles:set(profile_index, character_id)
		
		self:set_profile_peer_id(profile_index, sender, local_player_id)
	end
end)

mod:hook(ProfileSynchronizer, "set_profile_peer_id", function (func, self, profile_index, peer_id, local_player_id)
	mod:debug(string.format("ProfileSynchronizer.set_profile_peer_id(%s, %s, %s)", profile_index, peer_id, local_player_id))
	
	assert(self._is_server)
	assert(profile_index)
	assert((peer_id and local_player_id) or (not peer_id and not local_player_id), "Missing local_player_id despite assigning to peer.")

	local new_profile_index, previous_profile_index = nil

	if peer_id then
		new_profile_index = profile_index
		previous_profile_index = self:profile_by_peer(peer_id, local_player_id)

		--profile_printf("[ProfileSynchronizer] set_profile_peer_id from profile %s to %s for peer id %s:%i", tostring(previous_profile_index), tostring(new_profile_index), peer_id, local_player_id)
	else
		new_profile_index = nil
		previous_profile_index = profile_index
		local previous_owner = self._profile_owners[previous_profile_index]
		
		-- If client connects in a active level the previous_owner is missing
		if previous_owner then
			local peer_table = self._loaded_peers[previous_owner.peer_id]

			if peer_table then
				peer_table[previous_owner.local_player_id] = nil

				if table.is_empty(peer_table) then
					self._loaded_peers[previous_owner.peer_id] = nil
				end

				--profile_printf("[ProfileSynchronizer] set_profile_peer_id %s is no longer owned by %s:%i", tostring(previous_profile_index), (previous_owner and previous_owner.peer_id) or "<none>", (previous_owner and previous_owner.local_player_id) or 0)
			end
		end
	end

	if previous_profile_index then
		local sender = nil

		self:_profile_select_inventory(previous_profile_index, EMPTY_TABLE, EMPTY_TABLE, sender, local_player_id, NO_CLIENT_SYNC_ID)
	end

	local transmit_peer_id = peer_id or NO_PEER
	local transmit_local_player_id = local_player_id or NO_LOCAL_PLAYER_ID

	self:rpc_server_mark_profile_used(IS_LOCAL_CALL, transmit_peer_id, transmit_local_player_id, previous_profile_index or 0, new_profile_index or 0)
	self:_send_rpc_lobby_clients("rpc_server_mark_profile_used", transmit_peer_id, transmit_local_player_id, previous_profile_index or 0, new_profile_index or 0)

	if peer_id then
		local peer_table = self._loaded_peers[peer_id] or {}
		peer_table[local_player_id] = false
		self._loaded_peers[peer_id] = peer_table
	end

	self._all_synced = false
end)

--[[
	██████╗ ███████╗██████╗ ██╗   ██╗ ██████╗ 
	██╔══██╗██╔════╝██╔══██╗██║   ██║██╔════╝ 
	██║  ██║█████╗  ██████╔╝██║   ██║██║  ███╗
	██║  ██║██╔══╝  ██╔══██╗██║   ██║██║   ██║
	██████╔╝███████╗██████╔╝╚██████╔╝╚██████╔╝
	╚═════╝ ╚══════╝╚═════╝  ╚═════╝  ╚═════╝ 
]]--
mod:hook(ProfileSynchronizer, "rpc_server_request_mark_profile_result", function (func, self, sender, profile_index, result, local_player_id)
	mod:debug(string.format("ProfileSynchronizer.rpc_server_request_mark_profile_result(%s, %s, %s, %s)", sender, profile_index, result, local_player_id))
	
	return func(self, sender, profile_index, result, local_player_id)
end)

mod:hook(ProfileSynchronizer, "rpc_client_select_inventory", function (func, self, sender, local_player_id, network_inventory_list, network_inventory_list_first_person, client_sync_id)
	mod:debug(string.format("ProfileSynchronizer.rpc_client_select_inventory(%s, %s, %s, %s, %s)", sender, local_player_id, network_inventory_list, network_inventory_list_first_person, client_sync_id))
	
	return func(self, sender, local_player_id, network_inventory_list, network_inventory_list_first_person, client_sync_id)
end)

mod:hook(ProfileSynchronizer, "profile_request_result", function (func, self)
	local request_result, request_local_player_id = func(self)

	mod:debug(string.format("request_result = %s", request_result))
	mod:debug(string.format("request_local_player_id = %s", request_local_player_id))
	
	return request_result, request_local_player_id
end)

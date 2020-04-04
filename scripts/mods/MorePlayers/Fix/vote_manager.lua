--[[
	Console log:
		vote_deed.log
		vote_lookup.log
		voters_list.log
]]--
local mod = get_mod("MorePlayers")

mod:hook(VoteManager, "init", function (func, self, ...)
	mod:debug("VoteManager.init()")
	
	mod.network["rpc_client_start_vote_lookup"] = self
	mod.network["rpc_client_start_vote_deed"] = self
	mod.network["rpc_update_voters_list"] = self
	
	return func(self, ...)
end)

mod:hook(VoteManager, "request_vote", function(func, self, name, vote_data, voter_peer_id)
	local vote_template = VoteTemplates[name]

	fassert(vote_template, "Could not find voting template by name: %q", name)
	fassert(voter_peer_id ~= nil, "No voter peer id sent")

	local vote_type_id = NetworkLookup.voting_types[name]
	vote_data = vote_data or {}
	vote_data.voter_peer_id = voter_peer_id

	if self.is_server then
		local start_new_voting = self:can_start_vote(name, vote_data)

		if start_new_voting then
			self:_server_abort_active_vote()
			self:_server_start_vote(name, nil, vote_data)

			local sync_data = vote_template.pack_sync_data(vote_data)
			local server_start_vote_rpc = vote_template.server_start_vote_rpc
			local voters = self.active_voting.voters
			
			if server_start_vote_rpc == "rpc_client_start_vote_lookup" or server_start_vote_rpc == "rpc_client_start_vote_deed"  then
				mod.send_rpc_clients(server_start_vote_rpc, vote_type_id, sync_data, voters)
			else
				Managers.state.network.network_transmit:send_rpc_clients(server_start_vote_rpc, vote_type_id, sync_data, voters)
			end
			
			if vote_template.initial_vote_func then
				local votes = vote_template.initial_vote_func(vote_data)

				for peer_id, vote in pairs(votes) do
					self:rpc_vote(peer_id, vote)
				end
			end

			return true
		end
	elseif Managers.state.network:game() then
		local client_start_vote_rpc = vote_template.client_start_vote_rpc
		local sync_data = vote_template.pack_sync_data(vote_data)

		Managers.state.network.network_transmit:send_rpc_server(client_start_vote_rpc, vote_type_id, sync_data)
	end
end)

mod:hook(VoteManager, "hot_join_sync", function (func, self, peer_id)
	if self.active_voting then
		local active_voting = self.active_voting
		local template = active_voting.template
		local name_id = NetworkLookup.voting_types[template.name]
		local sync_data = template.pack_sync_data(active_voting.data)
		local server_start_vote_rpc = template.server_start_vote_rpc
		local voters = active_voting.voters
		
		if server_start_vote_rpc == "rpc_client_start_vote_lookup" or server_start_vote_rpc == "rpc_client_start_vote_deed"  then
			mod.send_rpc(server_start_vote_rpc, peer_id, name_id, sync_data, voters)
		else
			RPC[server_start_vote_rpc](peer_id, name_id, sync_data, voters)
		end
		
		local votes = active_voting.votes

		for voter_peer_id, vote_option in pairs(votes) do
			RPC.rpc_client_add_vote(peer_id, voter_peer_id, vote_option)
		end
	end

	RPC.rpc_client_vote_kick_enabled(peer_id, self._vote_kick_enabled)
end)

mod:hook(VoteManager, "_server_update", function (func, self, dt, t)
	local active_voting = self.active_voting

	if not active_voting then
		return
	end

	if not Managers.state.network:game() then
		return
	end

	local active_peers = self:_active_peers()
	local changed = self:_update_voter_list_by_active_peers(active_peers, active_voting.voters, active_voting.votes)

	if changed then
		--Managers.state.network.network_transmit:send_rpc_clients("rpc_update_voters_list", active_voting.voters)
		mod.send_rpc_clients("rpc_update_voters_list", active_voting.voters)
	end

	local vote_time_ended = self:_time_ended(t)

	if vote_time_ended then
		self:_handle_undecided_votes(active_voting)
	end

	local vote_result = self:_vote_result(vote_time_ended)

	if vote_result ~= nil then
		local result_data = active_voting.template.on_complete(vote_result, self.ingame_context, active_voting.data)

		Managers.state.network.network_transmit:send_rpc_all("rpc_client_complete_vote", vote_result)
	elseif vote_time_ended then
		local result_data = active_voting.template.on_complete(0, self.ingame_context, active_voting.data)

		Managers.state.network.network_transmit:send_rpc_all("rpc_client_complete_vote", 0)
	end
end)

mod:hook(VoteManager, "rpc_client_start_vote_lookup", function (func, ...)
	mod:debug("original rpc_client_start_vote_lookup")
	
	return func(...)
end)

mod:hook(VoteManager, "rpc_client_start_vote_deed", function (func, ...)
	mod:debug("original rpc_client_start_vote_deed")
	
	return func(...)
end)

mod:hook(VoteManager, "rpc_update_voters_list", function (func, ...)
	mod:debug("original rpc_update_voters_list")
	
	return func(...)
end)
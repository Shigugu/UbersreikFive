--[[
	
]]--
local mod = get_mod("MorePlayers")

local function networkified_path(path)
	local networkified_path = {}

	for id, name in ipairs(path) do
		networkified_path[id] = NetworkLookup.statistics_path_names[name]
	end

	return networkified_path
end

local function cap_sync_value(value)
	local max_size = 65535

	if value > max_size then
		Application.warning(string.format("Trying to sync value exceeding maximum size %d > %d", value, max_size))
		print(Script.callstack())

		value = max_size
	end

	return value
end

local function sync_stat(peer_id, stat_peer_id, stat_local_player_id, path, path_step, stat)
	if stat.value then
		if stat.sync_on_hot_join then
			fassert(type(stat.value) == "number", "Not supporting hot join syncing of value %q", type(stat.value))
			fassert(path_step <= NetworkConstants.statistics_path_max_size, "statistics path is longer than max size, increase in global.networks_config")

			local default_value = stat.default_value

			if stat.value ~= default_value or (stat.persistent_value and stat.persistent_value ~= default_value) then
				local networkified_path = networkified_path(path)

				--RPC.rpc_sync_statistics_number(peer_id, stat_peer_id, stat_local_player_id, networkified_path, cap_sync_value(stat.value), cap_sync_value(stat.persistent_value or 0))
				mod.send_rpc("rpc_sync_statistics_number", peer_id, stat_peer_id, stat_local_player_id, networkified_path, cap_sync_value(stat.value), cap_sync_value(stat.persistent_value or 0))
			end
		end
	else
		for stat_name, stat_definition in pairs(stat) do
			path[path_step] = stat_name

			sync_stat(peer_id, stat_peer_id, stat_local_player_id, path, path_step + 1, stat_definition)
		end
	end

	path[path_step] = nil
end

mod:hook(StatisticsDatabase, "init", function(func, self, ...)
	mod.network["rpc_sync_statistics_number"] = self
		
	return func(self, ...)
end)

mod:hook(StatisticsDatabase, "rpc_sync_statistics_number", function(func, ...)
	local arg = {...}
	
	local succes = mod:pcall(function()
		func(unpack(arg))
	end)
	
	if succes == false then
		mod:debug("original rpc_sync_statistics_number")
	end
end)

mod:hook(StatisticsDatabase, "hot_join_sync", function(func, self, peer_id)
	for stat_id, category in pairs(self.categories) do
		if category == "player" then
			local player = Managers.player:player_from_stats_id(stat_id)
			local stats = self.statistics[stat_id]

			sync_stat(peer_id, player:network_id(), player:local_player_id(), {}, 1, stats)
		elseif category == "session" then
		end
	end
end)
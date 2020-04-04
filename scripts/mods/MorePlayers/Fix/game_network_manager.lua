--[[
	
]]--
local mod = get_mod("MorePlayers")

mod:hook(GameNetworkManager, "init", function(func, self, ...)
	mod.network["rpc_assist"] = self
	
	return func(self, ...)
end)

mod:hook(GameNetworkManager, "rpc_assist", function(func, ...)
	mod:debug("original rpc_assist")
	
	return func(...)
end)

mod:hook(StatisticsUtil, "check_save", function(func, savior_unit, enemy_unit)
	local blackboard = BLACKBOARDS[enemy_unit]
	local saved_unit = blackboard.target_unit
	local player_manager = Managers.player

	if not savior_unit or not saved_unit then
		return
	end

	local savior_is_player = player_manager:is_player_unit(savior_unit)
	local saved_is_player = player_manager:is_player_unit(saved_unit)

	if not savior_is_player or not saved_is_player then
		return
	end

	local savior_player = player_manager:owner(savior_unit)
	local saved_player = player_manager:owner(saved_unit)

	if savior_player == saved_player then
		return
	end

	local saved_unit_dir = nil
	local network_manager = Managers.state.network
	local game = network_manager:game()
	local game_object_id = game and network_manager:unit_game_object_id(saved_unit)

	if game_object_id then
		saved_unit_dir = Vector3.normalize(Vector3.flat(GameSession.game_object_field(game, game_object_id, "aim_direction")))
	else
		saved_unit_dir = Quaternion.forward(Unit.local_rotation(saved_unit, 0))
	end

	local enemy_unit_dir = Quaternion.forward(Unit.local_rotation(enemy_unit, 0))
	local saved_unit_pos = POSITION_LOOKUP[saved_unit]
	local enemy_unit_pos = POSITION_LOOKUP[enemy_unit]
	local attack_dir = saved_unit_pos - enemy_unit_pos
	local is_behind = Vector3.distance(saved_unit_pos, enemy_unit_pos) < 3 and Vector3.dot(attack_dir, saved_unit_dir) > 0 and Vector3.dot(attack_dir, enemy_unit_dir) > 0
	local status_ext = ScriptUnit.extension(saved_unit, "status_system")
	local grabber_unit = status_ext:get_pouncer_unit() or status_ext:get_pack_master_grabber()
	local is_disabled = status_ext:is_disabled()
	local predicate = nil
	local statistics_db = player_manager:statistics_db()
	local savior_player_stats_id = savior_player:stats_id()

	if enemy_unit == grabber_unit then
		predicate = "save"

		statistics_db:increment_stat(savior_player_stats_id, "saves")
	elseif is_behind or is_disabled then
		predicate = "aid"

		statistics_db:increment_stat(savior_player_stats_id, "aidings")
	end

	if predicate then
		local local_human = not savior_player.remote and not savior_player.bot_player

		Managers.state.event:trigger("add_coop_feedback", savior_player_stats_id .. saved_player:stats_id(), local_human, predicate, savior_player, saved_player)

		local buff_extension = ScriptUnit.extension(saved_unit, "buff_system")

		buff_extension:trigger_procs("on_assisted", savior_unit, enemy_unit)

		local savior_buff_extension = ScriptUnit.extension(savior_unit, "buff_system")

		savior_buff_extension:trigger_procs("on_assisted_ally", saved_unit, enemy_unit)

		local network_transmit = Managers.state.network.network_transmit
		local savior_player_id = savior_player:network_id()
		local savior_local_player_id = savior_player:local_player_id()
		local saved_player_id = saved_player:network_id()
		local saved_local_player_id = saved_player:local_player_id()
		local predicate_id = NetworkLookup.coop_feedback[predicate]
		local enemy_unit_id = network_manager:unit_game_object_id(enemy_unit)

		--network_transmit:send_rpc_clients("rpc_assist", savior_player_id, savior_local_player_id, saved_player_id, saved_local_player_id, predicate_id, enemy_unit_id)
		mod.send_rpc_clients("rpc_assist", savior_player_id, savior_local_player_id, saved_player_id, saved_local_player_id, predicate_id, enemy_unit_id)
	end
end)
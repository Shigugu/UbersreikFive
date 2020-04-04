--[[
	The SpawnManager had a local NUM_PLAYERS that was 5
	
	Fix:
		Redeclair the functions that use this local variable and let it run by my mod variable NUM_PLAYERS
	
	Also there are some unknown changes made by Zaphio
]]--
local mod = get_mod("MorePlayers")

local CONSUMABLE_SLOTS = { "slot_healthkit", "slot_potion", "slot_grenade", }
local NUM_CONSUMABLE_SLOTS = #CONSUMABLE_SLOTS
local CONSUMABLES_TEMP = {}

local function netpack_consumables(consumables, temp_table)
    for i = 1, NUM_CONSUMABLE_SLOTS do
        local slot_name = CONSUMABLE_SLOTS[i]
        temp_table[i] = NetworkLookup.item_names[consumables[slot_name] or "n/a"]
    end
end

mod:hook(SpawnManager, "init", function(func, self, ...)
    -- Register that this rpc call must be send without limitations
	mod.network["rpc_to_client_respawn_player"] = self
	
	return func(self, ...)
end)

mod:hook(SpawnManager, "_force_update_spawn_positions", function(func, self, safe_position, safe_rotation)
    local statuses = self._player_statuses

    for i = 1, mod.NUM_PLAYERS do
        local status = statuses[i]

        status.position:store(safe_position)
        status.rotation:store(safe_rotation)
    end
end)

mod:hook(SpawnManager, "_default_player_statuses", function(func, self)
    local settings = Managers.state.difficulty:get_difficulty_settings()
    local gamemode_settings = Managers.state.game_mode:settings()
    local statuses = {}

    for i = 1, mod.NUM_PLAYERS do
        local status = {
            temporary_health_percentage = 0,
            spawn_state = "not_spawned",
            health_percentage = 1,
            health_state = "alive",
            last_update = -math.huge,
            consumables = {},
            ammo = {
                slot_ranged = 1,
                slot_melee = 1,
            }
        }

        if not gamemode_settings.disable_difficulty_spawning_items then
            local consumables = status.consumables

            for i = 1, NUM_CONSUMABLE_SLOTS, 1 do
                local slot_name = CONSUMABLE_SLOTS[i]
                consumables[slot_name] = settings[slot_name]
            end
        end

        statuses[i] = status
    end

    return statuses
end)

mod:hook(SpawnManager, "flow_callback_add_spawn_point", function(func, self, unit)
    local pos = Unit.local_position(unit, 0)
    local rot = Unit.local_rotation(unit, 0)
    local spawn_point = {
        pos = Vector3Box(pos),
        rot = QuaternionBox(rot),
    }
    self.spawn_points[#self.spawn_points + 1] = spawn_point
    local statuses = self._player_statuses

    for i = 1, mod.NUM_PLAYERS, 1 do
        local status = statuses[i]

        if not status.position then
            status.position = Vector3Box(pos)
            status.rotation = QuaternionBox(rot)

            --break
        end
    end
end)

mod:hook(SpawnManager, "_update_respawns", function(func, self, dt, t)
    local statuses = self._player_statuses
    local player_manager = Managers.player
    local network_manager = Managers.state.network
    local network_transmit = network_manager.network_transmit

    if self._network_server:has_all_peers_loaded_packages() then
        for i = 1, mod.NUM_PLAYERS, 1 do
            local status = statuses[i]

            if status.health_state == "dead" and status.ready_for_respawn and status.peer_id then
                local respawn_unit = status.respawn_unit or self.respawn_handler:get_respawn_unit()

                if respawn_unit then
                    local respawn_unit_id = network_manager:level_object_id(respawn_unit)

                    netpack_consumables(status.consumables, CONSUMABLES_TEMP)
                    --network_transmit:send_rpc("rpc_to_client_respawn_player", status.peer_id, status.local_player_id, status.profile_index, respawn_unit_id, unpack(CONSUMABLES_TEMP))
					mod.send_rpc("rpc_to_client_respawn_player", status.peer_id, status.local_player_id, status.profile_index, respawn_unit_id, unpack(CONSUMABLES_TEMP))
                    table.clear(CONSUMABLES_TEMP)

                    status.health_state = "respawning"
                    status.respawn_unit = respawn_unit
                    status.health_percentage = Managers.state.difficulty:get_difficulty_settings().respawn.health_percentage
                    status.temporary_health_percentage = Managers.state.difficulty:get_difficulty_settings().respawn.temporary_health_percentage
                end
            end
        end
    end
end)

mod:hook(SpawnManager, "rpc_respawn_confirmed", function(func, self, sender, local_player_id)
    local statuses = self._player_statuses

    for i = 1, mod.NUM_PLAYERS, 1 do
        local status = statuses[i]

        if status.peer_id == sender and status.local_player_id == local_player_id then
            status.ready_for_respawn = false

            return
        end
    end
end)

mod:hook(SpawnManager, "_update_player_status", function(func, self, dt, t)
    local player_manager = Managers.player
    local statuses = self._player_statuses
    local ScriptUnit_extension = ScriptUnit.extension

    for i = 1, mod.NUM_PLAYERS, 1 do
        local status = statuses[i]
        local peer_id = status.peer_id
        local local_player_id = status.local_player_id
        local print_unit = nil

        if peer_id or local_player_id then
            local player = player_manager:player(peer_id, local_player_id)

            if player then
                local player_unit = player.player_unit
                print_unit = player_unit

                if player_unit then
                    status.spawn_state = "spawned"
                    local safe_position = ScriptUnit_extension(player_unit, "locomotion_system"):last_position_on_navmesh()

                    status.position:store(safe_position)
                    status.rotation:store(Unit.local_rotation(player_unit, 0))

                    local status_extension = ScriptUnit_extension(player_unit, "status_system")
                    local old_state = status.health_state
                    local is_dead = status_extension:is_dead()

                    if is_dead then
                        if status.health_state ~= "respawning" then
                            status.health_state = "dead"
                        end
                    elseif status_extension:is_ready_for_assisted_respawn() then
                        status.health_state = "respawn"
                    elseif status_extension:is_knocked_down() then
                        status.health_state = "knocked_down"
                    elseif status_extension:is_disabled() and not status_extension:is_in_vortex() and not status_extension:is_grabbed_by_corruptor() and not status_extension:is_grabbed_by_chaos_spawn() and not status_extension:is_overpowered() then
                        status.health_state = "disabled"
                    else
                        status.health_state = "alive"
                        local respawn_unit = status.respawn_unit

                        if respawn_unit then
                            self.respawn_handler:set_respawn_unit_available(respawn_unit)

                            status.respawn_unit = nil
                        end
                    end

                    local health_ext = ScriptUnit_extension(player_unit, "health_system")

                    if not is_dead or status.health_state ~= "respawning" then
                        status.health_percentage = health_ext:current_permanent_health_percent()
                        status.temporary_health_percentage = health_ext:current_temporary_health_percent()
                    end

                    status.last_update = t
                    local inventory = ScriptUnit_extension(player_unit, "inventory_system")
                    local consumables = status.consumables

                    for i = 1, NUM_CONSUMABLE_SLOTS, 1 do
                        local slot_name = CONSUMABLE_SLOTS[i]
                        local slot_data = inventory:get_slot_data(slot_name)
                        local item_key = slot_data and slot_data.item_data.key

                        if item_key ~= nil or consumables[slot_name] ~= nil then
                            consumables[slot_name] = item_key
                        end
                    end
                end
            else
                self:_free_status_slot(i)
            end
        end
    end
end)

mod:hook(SpawnManager, "_update_bot_spawns", function(func, self, dt, t)
    local player_manager = Managers.player
    local profile_synchronizer = self._profile_synchronizer
    local available_profile_order = self._available_profile_order
    local available_profiles = self._available_profiles
    local profile_release_list = self._bot_profile_release_list
    local delta, humans, bots = self:_update_available_profiles(profile_synchronizer, available_profile_order, available_profiles)

    for local_player_id, bot_player in pairs(self._bot_players) do
        local profile_index = bot_player:profile_index()

        if not available_profiles[profile_index] then
            local peer_id = bot_player:network_id()
            local local_player_id = bot_player:local_player_id()
            profile_release_list[profile_index] = true
            local bot_unit = bot_player.player_unit

            if bot_unit then
                bot_player:despawn()
            end

            local status_slot_index = bot_player.status_slot_index

            self:_free_status_slot(status_slot_index)
            player_manager:remove_player(peer_id, local_player_id)

            self._bot_players[local_player_id] = nil
        end
    end

    local allowed_bots = math.min(mod.NUM_PLAYERS - humans, (script_data.ai_bots_disabled and 0) or script_data.cap_num_bots or mod.NUM_PLAYERS)
    local bot_delta = allowed_bots - bots
    local local_peer_id = Network.peer_id()

    if bot_delta > 0 then
        local i = 1
        local bots_spawned = 0

        while bot_delta > bots_spawned do
            local profile_index = available_profile_order[i] or i
            local profile = SPProfiles[profile_index]

            if not profile.tutorial_profile then
                fassert(profile_index, "Tried to add more bots than there are profiles available")

                local owner_type = profile_synchronizer:owner_type(profile_index)

                if owner_type == "available" then
                    local local_player_id = player_manager:next_available_local_player_id(local_peer_id)
                    local bot_player = player_manager:add_bot_player(profile.display_name, local_peer_id, "default", profile_index, local_player_id)
                    local is_initial_spawn, status_slot_index = self:_assign_status_slot(local_peer_id, local_player_id, profile_index)
                    bot_player.status_slot_index = status_slot_index

                    profile_synchronizer:set_profile_peer_id(profile_index, local_peer_id, local_player_id)
                    bot_player:create_game_object()

                    self._bot_players[local_player_id] = bot_player
                    self._spawn_list[#self._spawn_list + 1] = bot_player
                    bots_spawned = bots_spawned + 1
                    self._forced_bot_profile_index = nil
                end
            end

            i = i + 1
        end
    elseif bot_delta < 0 then
        local bots_despawned = 0
        local i = 1

        while bots_despawned < -bot_delta do
            local profile_index = available_profile_order[i]

            fassert(profile_index, "Tried to remove more bots than there are profiles belonging to bots")

            local owner_type = profile_synchronizer:owner_type(profile_index)

            if owner_type == "bot" then
                local bot_player, bot_local_player_id = nil

                for local_player_id, player in pairs(self._bot_players) do
                    if player:profile_index() == profile_index then
                        bot_player = player
                        bot_local_player_id = local_player_id

                        break
                    end
                end

                fassert(bot_player, "Did not find bot player with profile_index profile_index %i", profile_index)

                profile_release_list[profile_index] = true
                local bot_unit = bot_player.player_unit

                if bot_unit then
                    bot_player:despawn()
                end

                local status_slot_index = bot_player.status_slot_index

                self:_free_status_slot(status_slot_index)
                player_manager:remove_player(local_peer_id, bot_local_player_id)

                self._bot_players[bot_local_player_id] = nil
                bots_despawned = bots_despawned + 1
            end

            i = i + 1
        end
    end

    if self._network_server:has_all_peers_loaded_packages() then
        local statuses = self._player_statuses
        local spawn_list = self._spawn_list
        local num_to_spawn = #spawn_list

        for i = 1, num_to_spawn, 1 do
            local bot_player = spawn_list[i]
            local bot_local_player_id = bot_player:local_player_id()
            local bot_peer_id = bot_player:network_id()

            if player_manager:player(bot_peer_id, bot_local_player_id) == bot_player then
                local status_slot_index = bot_player.status_slot_index
                local status = statuses[status_slot_index]
                local position = status.position:unbox()
                local rotation = status.rotation:unbox()
                local is_initial_spawn = false

                if status.health_state ~= "dead" and status.health_state ~= "respawn" and status.health_state ~= "respawning" then
                    local consumables = status.consumables
                    local ammo = status.ammo

                    bot_player:spawn(position, rotation, is_initial_spawn, ammo.slot_melee, ammo.slot_ranged, consumables[CONSUMABLE_SLOTS[1]], consumables[CONSUMABLE_SLOTS[2]], consumables[CONSUMABLE_SLOTS[3]])
                end

                status.spawn_state = "spawned"
            end
        end

        table.clear(spawn_list)
    end
end)

mod:hook(SpawnManager, "all_humans_dead", function(func, self)
    local statuses = self._player_statuses
    local player_manager = Managers.player

    for i = 1, mod.NUM_PLAYERS, 1 do
        local status = statuses[i]
        local health_state = status.health_state
        local peer_id = status.peer_id
        local local_player_id = status.local_player_id
        local player = peer_id and player_manager:player(peer_id, local_player_id)
        local is_bot = player and player.bot_player

        if health_state ~= "dead" and health_state ~= "respawn" and health_state ~= "respawning" and not is_bot then
            return false
        end
    end

    return true
end)

mod:hook(SpawnManager, "all_players_disabled", function(func, self)
    local statuses = self._player_statuses

    for i = 1, mod.NUM_PLAYERS, 1 do
        local status = statuses[i]
        local health_state = status.health_state

        if health_state == "alive" then
            return false
        end
    end

    return true
end)

mod:hook(SpawnManager, "get_status", function(func, self, _player)
    local statuses = self._player_statuses
    local player_manager = Managers.player

    for i = 1, mod.NUM_PLAYERS, 1 do
        local status = statuses[i]
        local peer_id = status.peer_id
        local local_player_id = status.local_player_id

        if peer_id or local_player_id then
            local player = player_manager:player(peer_id, local_player_id)

            if player == _player then
                return status.health_state, status.health_percentage, status.temporary_health_percentage, status.ammo.slot_melee, status.ammo.slot_ranged
            end
        end
    end

    return nil
end)

mod:hook(SpawnManager, "teleport_despawned_players", function(func, self, position)
    local statuses = self._player_statuses
    local player_manager = Managers.player

    for i = 1, mod.NUM_PLAYERS, 1 do
        local status = statuses[i]
        local peer_id = status.peer_id
        local local_player_id = status.local_player_id
        local player = peer_id and local_player_id and player_manager:player(peer_id, local_player_id)

        if not player or not player.player_unit then
            status.position:store(position)
        end
    end
end)

mod:hook(SpawnManager, "_assign_status_slot", function(func, self, peer_id, local_player_id, profile_index)
    local latest_slot = nil
    local latest_time = -math.huge
    local first_empty, slot_index = nil
    local found_slot = false

    for i = 1, mod.NUM_PLAYERS, 1 do
        local status = self._player_statuses[i]

        if status.peer_id == peer_id and status.local_player_id == local_player_id then
            status.profile_index = profile_index
            found_slot = true
            slot_index = i

            break
        end
    end

    if not found_slot then
        for i = 1, mod.NUM_PLAYERS, 1 do
            local status = self._player_statuses[i]
            local last_update = status.last_update

            if status.profile_index == profile_index then
                fassert(not status.peer_id, "Trying to take slot for profile already in use. old player: %q:%q, new player: %q:%q", status.peer_id, status.local_player_id, peer_id, local_player_id)
                self:_take_status_slot(i, peer_id, local_player_id, profile_index)

                slot_index = i
                found_slot = true

                break
            elseif not first_empty and not status.profile_index then
                first_empty = i
            end

            if not status.peer_id and latest_time < last_update then
                latest_time = last_update
                latest_slot = i
            end
        end
    end

    if not found_slot then
        if latest_slot then
            self:_take_status_slot(latest_slot, peer_id, local_player_id, profile_index)

            slot_index = latest_slot
        elseif first_empty then
            self:_take_status_slot(first_empty, peer_id, local_player_id, profile_index)

            slot_index = first_empty
        end
    end

    if not slot_index then
        table.dump(self._player_statuses, "", 3)
    end

    assert(slot_index, "Did not find status slot index.")

    local ingame_time = Managers.time:time("client_ingame")
    local first_spawn = ingame_time == nil or ingame_time < 10

    return first_spawn, slot_index
end)

mod:hook(SpawnManager, "_update_spawning", function(func, self, dt, t)
    if self._spawning then
        local statuses = self._player_statuses

        for i = 1, mod.NUM_PLAYERS, 1 do
            local status = statuses[i]
            local spawn_state = status.spawn_state

            if spawn_state == "is_initial_spawn" or spawn_state == "spawn" then
                self:_spawn_player(status)
            end
        end
    end
end)

mod:hook(SpawnManager, "_update_available_profiles", function(func, self, profile_synchronizer, available_profile_order, available_profiles)
	local delta = 0
	local bots = 0
	local humans = 0
	local order_changed = false

	for profile_index = 1, mod.NUM_PROFILES, 1 do
		local owner_type = profile_synchronizer:owner_type(profile_index)

		if owner_type == "human" then
			humans = humans + 1

			if available_profiles[profile_index] then
				local index = table.find(available_profile_order, profile_index)

				table.remove(available_profile_order, index)

				available_profiles[profile_index] = false
				delta = delta - 1
				order_changed = true
			end
		elseif owner_type == "available" or owner_type == "bot" then
			if owner_type == "bot" then
				bots = bots + 1
			end

			if not available_profiles[profile_index] then
				table.insert(available_profile_order, 1, profile_index)

				available_profiles[profile_index] = true
				delta = delta + 1
				order_changed = true
			end
		end
	end

	if order_changed then
		local bot_profile_id_to_priority_id = self._bot_profile_id_to_priority_id

		table.sort(available_profile_order, function (a, b)
			return (bot_profile_id_to_priority_id[a] or math.huge) < (bot_profile_id_to_priority_id[b] or math.huge)
		end)
	end

	if self._forced_bot_profile_index then
		local forced_bot_profile_index = self._forced_bot_profile_index
		local index = table.find(available_profile_order, forced_bot_profile_index)
		local available = (index and profile_synchronizer:owner_type(forced_bot_profile_index) == "available") or false

		fassert(available, "Bot profile (%s) is not available!", SPProfilesAbbreviation[forced_bot_profile_index])

		if index ~= 1 then
			available_profile_order[index] = available_profile_order[1]
			available_profile_order[1] = available_profile_order[index]
		end
	end

	return delta, humans, bots
end)

mod:hook(SpawnManager, "rpc_to_client_respawn_player", function (func, ...)
	mod:debug("original rpc_to_client_respawn_player")
	
	return func(...)
end)
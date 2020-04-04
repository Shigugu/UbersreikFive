--[[
	This is a test to have 8 players and switch profile id
]]--
local mod = get_mod("MorePlayers")

mod.hero_selection = false
mod.profile_id = nil

-- If the profile_index isn't changed and you respawn the player it wont get respawned
-- With this variable we can do this by force :D Prepare your anus xD
mod.respawn = false

-- Dead to the tutorial profile xD
TUTORIAL_PROFILE_INDEX = 1337

--[[
	███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
	██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
	█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
	██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
	██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
	╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝
]]--
mod.current_profile_index = function()
	local profile_synchronizer = Managers.state.network.profile_synchronizer
	local player = Managers.player:local_player()

	if profile_synchronizer and player then
		local network_id = player:network_id()
		local local_player_id = player:local_player_id()
		local profile_index = profile_synchronizer:profile_by_peer(network_id, local_player_id)
		
		return profile_index
	end
	
	return nil
end

--[[
	Prevent the game to save the profile index, this prevent crashes in official game
]]--
mod.func_fix_profile_index = function(func, self, profile_index)
	profile_index = 1
	
	return func(self, profile_index)
end

--[[
	 ██████╗ ██████╗ ███╗   ███╗███╗   ███╗ █████╗ ███╗   ██╗██████╗ ███████╗
	██╔════╝██╔═══██╗████╗ ████║████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝
	██║     ██║   ██║██╔████╔██║██╔████╔██║███████║██╔██╗ ██║██║  ██║███████╗
	██║     ██║   ██║██║╚██╔╝██║██║╚██╔╝██║██╔══██║██║╚██╗██║██║  ██║╚════██║
	╚██████╗╚██████╔╝██║ ╚═╝ ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║██████╔╝███████║
	 ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚══════╝
]]--
mod:command("set_profile", "<profile_id>", function(...)
	if mod.hero_selection == false then
		return mod:echo("Go to 'Hero selection' before you execute this command!")
	end
	
	local arg = {...}
	if #arg == 1 then
		local profile_id = tonumber(arg[1])
		
		if profile_id >= 1 and profile_id <= mod.NUM_PLAYERS then
			mod.profile_id = profile_id
			
			if profile_id == mod.current_profile_index() then
				mod.respawn = true
			end
		else
			mod:echo(string.format("Profile id must be between 1 and %s", mod.NUM_PLAYERS))
		end
	end
end)

--[[
	██╗  ██╗ ██████╗  ██████╗ ██╗  ██╗███████╗
	██║  ██║██╔═══██╗██╔═══██╗██║ ██╔╝██╔════╝
	███████║██║   ██║██║   ██║█████╔╝ ███████╗
	██╔══██║██║   ██║██║   ██║██╔═██╗ ╚════██║
	██║  ██║╚██████╔╝╚██████╔╝██║  ██╗███████║
	╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝
]]--


--[[
	██████╗ ███████╗██╗   ██╗███████╗██╗      ██████╗ ██████╗ ███╗   ███╗███████╗███╗   ██╗████████╗
	██╔══██╗██╔════╝██║   ██║██╔════╝██║     ██╔═══██╗██╔══██╗████╗ ████║██╔════╝████╗  ██║╚══██╔══╝
	██║  ██║█████╗  ██║   ██║█████╗  ██║     ██║   ██║██████╔╝██╔████╔██║█████╗  ██╔██╗ ██║   ██║   
	██║  ██║██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║     ██║   ██║██╔═══╝ ██║╚██╔╝██║██╔══╝  ██║╚██╗██║   ██║   
	██████╔╝███████╗ ╚████╔╝ ███████╗███████╗╚██████╔╝██║     ██║ ╚═╝ ██║███████╗██║ ╚████║   ██║   
	╚═════╝ ╚══════╝  ╚═══╝  ╚══════╝╚══════╝ ╚═════╝ ╚═╝     ╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝ 
]]--
--[[
mod:command("mutators", "", function(...)
	local mutator_handler = Managers.state.game_mode._mutator_handler
	
	if mutator_handler then
		local active_mutators = mutator_handler._active_mutators
		
		if active_mutators and active_mutators.player_dot then
			for key, value in pairs(active_mutators.player_dot.player_units) do
				mod:echo(string.format("%s '%s' %s", type(key), key, value))
			end
		end
	end
end)
]]--

--[[
mod.network_reload = false
mod:command("network_reload", "", function(...)
	local arg = {...}
	
	mod.network_reload = true
end)

mod.network_spawn = false
mod:command("network_spawn", "", function(...)
	local arg = {...}
	
	mod.network_spawn = true
end)

mod:hook(ProfileSynchronizer, "update", function (func, self, ...)
	if mod.network_reload == true then
		mod:echo("network reload")
		
		self._network_transmit:send_rpc_server("rpc_reload_level")
		mod.network_reload = false
	end
	
	if mod.network_spawn then
		mod:echo("network spawn")
		
		self._network_transmit:send_rpc_server(
			"rpc_spawn_pickup_with_physics",
			NetworkLookup.pickup_names["training_dummy"],
			Vector3(0, 0, 6),
			Quaternion.identity(),
			NetworkLookup.pickup_spawn_types['dropped']
		)
		mod.network_spawn = false
	end
	
		--self._network_transmit:send_rpc_server("rpc_start_game_countdown_finished")
	
	return func(self, ...)
end)
]]--
local mod = get_mod("MorePlayers")

local any_char = get_mod("any_char")
if any_char then
	return mod:error("Disable 'Duplicated Characters' mod. This project is outdated and is been migrated into the MorePlayers mod.")
end

mod.NUM_PLAYERS = 5
mod.NUM_PROFILES = 5

script_data.cap_num_bots = 7

PlayerManager.MAX_PLAYERS = mod.NUM_PLAYERS
MatchmakingSettings.MAX_NUMBER_OF_PLAYERS = mod.NUM_PLAYERS
GameSettingsDevelopment.lobby_max_members = mod.NUM_PLAYERS

mod:dofile("scripts/mods/MorePlayers/Module/sp_profiles")
mod:dofile("scripts/mods/MorePlayers/Module/network")
mod:dofile("scripts/mods/MorePlayers/Module/8player")

mod:dofile("scripts/mods/MorePlayers/Fix/ai_slot_system")
mod:dofile("scripts/mods/MorePlayers/Fix/backend_interface_hero_attributes_playfab")
mod:dofile("scripts/mods/MorePlayers/Fix/character_selection_state_character")
mod:dofile("scripts/mods/MorePlayers/Fix/conflict_director")
mod:dofile("scripts/mods/MorePlayers/Fix/conflict_utils")
mod:dofile("scripts/mods/MorePlayers/Fix/death_reactions")
mod:dofile("scripts/mods/MorePlayers/Fix/end_view_state_score")
mod:dofile("scripts/mods/MorePlayers/Fix/game_network_manager")
mod:dofile("scripts/mods/MorePlayers/Fix/GameSession")
mod:dofile("scripts/mods/MorePlayers/Fix/hero_spawner_handler")
mod:dofile("scripts/mods/MorePlayers/Fix/ingame_player_list_ui")
mod:dofile("scripts/mods/MorePlayers/Fix/linker_transportation_extension")
mod:dofile("scripts/mods/MorePlayers/Fix/lobby_aux")
mod:dofile("scripts/mods/MorePlayers/Fix/matchmaking_manager")
mod:dofile("scripts/mods/MorePlayers/Fix/matchmaking_ui")
mod:dofile("scripts/mods/MorePlayers/Fix/matchmaking_state_join_game")
mod:dofile("scripts/mods/MorePlayers/Fix/popup_join_lobby_handler")
mod:dofile("scripts/mods/MorePlayers/Fix/profile_synchronizer")
mod:dofile("scripts/mods/MorePlayers/Fix/save_manager")
mod:dofile("scripts/mods/MorePlayers/Fix/slot_allocator")
mod:dofile("scripts/mods/MorePlayers/Fix/spawn_manager")
mod:dofile("scripts/mods/MorePlayers/Fix/start_game_window_lobby_browser")
mod:dofile("scripts/mods/MorePlayers/Fix/state_loading")
mod:dofile("scripts/mods/MorePlayers/Fix/state_title_screen_init_network")
mod:dofile("scripts/mods/MorePlayers/Fix/statistics_database")
mod:dofile("scripts/mods/MorePlayers/Fix/twitch_vote_ui")
mod:dofile("scripts/mods/MorePlayers/Fix/unit_frames")
mod:dofile("scripts/mods/MorePlayers/Fix/vote_manager")

mod.update = function(dt)
	
end

mod.on_unload = function(exit_game)
	SPProfiles = mod.SPProfiles.start
	ProfilePriority = mod.ProfilePriority.start
end

mod.on_game_state_changed = function(status, state)
	
end

mod.on_setting_changed = function(setting_name)
	
end

mod.on_all_mods_loaded = function()

end

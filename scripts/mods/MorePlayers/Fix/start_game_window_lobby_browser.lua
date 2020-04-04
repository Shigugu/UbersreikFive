--[[
	Lobby browser crashes because it draws to much characters
]]--
local mod = get_mod("MorePlayers")

mod:hook(StartGameWindowLobbyBrowser, "_assign_hero_portraits", mod.func_original_profile)
mod:hook(StartGameWindowLobbyBrowser, "_setup_lobby_info_box", mod.func_original_profile)
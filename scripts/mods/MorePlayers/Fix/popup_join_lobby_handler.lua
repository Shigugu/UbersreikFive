--[[
	Character selection it draws to much characters
]]--
local mod = get_mod("MorePlayers")

mod:hook(PopupJoinLobbyHandler, "_setup_hero_selection_widgets", mod.func_original_profile)
mod:hook(PopupJoinLobbyHandler, "_update_occupied_profiles", mod.func_original_profile)

mod:hook(PopupJoinLobbyHandler, "set_unavailable_heroes", function(func, self, occupied_heroes)
	return func(self, {})
end)
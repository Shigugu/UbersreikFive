--[[
	Because some mods try to request a career information with this function it crashes because they input a nil hero
	The problem is in a profile_index > 5 this request cant be processed
]]--
local mod = get_mod("MorePlayers")

mod:hook(BackendInterfaceHeroAttributesPlayFab, "get", function(func, self, hero, attribute)
	if self._dirty then
		self:_refresh()
	end
	
	if hero then
		local key = hero .. "_" .. attribute

		return self._attributes[key]
	end
	
	return nil
end)
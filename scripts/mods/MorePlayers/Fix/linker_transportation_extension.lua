--[[
	When you have more then 4 bots and you activate the elivator  it try to get positions
	on the elivator by index. If you ask index > 5 it crash
	
	Fix:
		filter the index before execution this function
]]--
local mod = get_mod("MorePlayers")

mod:hook(LinkerTransportationExtension, "_get_position_from_index", function(func, self, index)
	if index >= 5 then
		index = 1
	end
	
	return func(self, index)
end)

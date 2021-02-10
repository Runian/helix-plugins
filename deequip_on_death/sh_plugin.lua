PLUGIN.name = "Unequip on Death"; -- Technically misleading name; should be 'Unequip after Death, but before Death'.
PLUGIN.author = "Rune Knight";
PLUGIN.description = "Automatically de-equips items during a period after death and before (fully) respawning.";
PLUGIN.license = [[Copyright 2021 Rune Knight

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.]];

--[[
	STEAM: https://steamcommunity.com/profiles/76561198028996329/
	DISCORD: Rune Knight#5972
]]

-- PlayerDeath doesn't work because ix.item.PerformInventoryAction requires the player to alive.
-- PlayerSpawn and PlayerLoadout is fine, so either works.
-- PostPlayerLoadout is too late because the character's health stop beings nil.
function PLUGIN:PlayerSpawn( client )
	local character = client:GetCharacter();
	if( !character or !character:GetInventory() ) then return end;
	if( character:GetData( "health" ) ) then return end; -- On death, the character's health becomes nil. This is our way to differentiate "dying then respawning" and "swapping characters then respawning".
	for _, v in pairs( character:GetInventory():GetItems() ) do
		if( v:GetData( "equip" ) == true ) then
			local ret = ix.item.PerformInventoryAction( client, "EquipUn", v:GetID(), v.invID, {} );
			continue;
		end
	end
end
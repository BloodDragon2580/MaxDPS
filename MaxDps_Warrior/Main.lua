﻿local addonName, addonTable = ...;
_G[addonName] = addonTable;

--- @type MaxDps
if not MaxDps then return end

local Warrior = MaxDps:NewModule('Warrior', 'AceEvent-3.0');
addonTable.Warrior = Warrior;

local MaxDps = MaxDps;

Warrior.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
}

function Warrior:Enable()
	MaxDps:Print(MaxDps.Colors.Info .. 'Warrior [Arms, Fury, Protection]');

	if MaxDps.Spec == 1 then
		MaxDps.NextSpell = Warrior.Arms;
	elseif MaxDps.Spec == 2 then
		MaxDps.NextSpell = Warrior.Fury;
	elseif MaxDps.Spec == 3 then
		MaxDps.NextSpell = Warrior.Protection;
	end

	Warrior.playerLevel = UnitLevel('player');
	return true;
end

function Warrior:Disable()
	self:UnregisterAllEvents();
end

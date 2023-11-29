local _, addonTable = ...;

-- @type MaxDps;
if not MaxDps then return end;
local Mage = addonTable.Mage;
local MaxDps = MaxDps;

local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;

local itemID = GetInventoryItemID('player', INVSLOT_MAINHAND);

local mainHandSubClassID = itemID and  select(13, GetItemInfo(itemID));

local TwoHanderWepCheck = mainHandSubClassID and (mainHandSubClassID == 1 or mainHandSubClassID == 5 or mainHandSubClassID == 8 or mainHandSubClassID == 10);

local FT = {
	ArcaneIntellect = 1459,
	Blizzard = 190356,
	Frostbolt = 116,
	Counterspell = 2139,
	Tier302pc = 393657,
	IceCaller = 236662,
	ConeOfCold = 120,
	ColdestSnap = 417493,
	CometStorm = 153595,
	FrozenOrb = 84714,
	GlacialSpike = 199786,
	Freeze = 33395,
	Snowstorm = 381706,
	IceNova = 157997,
	FrostNova = 122,
	ShiftingPower = 382440,
	Flurry = 44614,
	BrainFreeze = 190447,
	FingersOfFrost = 112965,
	IceLance = 30455,
	DragonsBreath = 31661,
	ArcaneExplosion = 1449,
	TimeWarp = 80353,
	IcyVeins = 12472,
	IceFloes = 108839,
	FireBlast = 319836,
	RayOfFrost = 205021,
	FreezingRain = 270233,
	SplinteringCold = 379049,
};
local A = {
};
function Mage:Frost()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;

	-- call_action_list,name=cds;
	local result = Mage:FrostCds();
	if result then
		return result;
	end

	-- run_action_list,name=aoe,if=active_enemies>=7&!set_bonus.tier30_2pc|active_enemies>=3&talent.ice_caller;
	if targets >= 7 and not MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2) or targets >= 3 and talents[FT.IceCaller] then
		return Mage:FrostAoe();
	end

	-- run_action_list,name=st;
	return Mage:FrostSt();
end
function Mage:FrostAoe()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local spellHistory = fd.spellHistory;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local gcd = fd.gcd;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- cone_of_cold,if=talent.coldest_snap&(prev_gcd.1.comet_storm|prev_gcd.1.frozen_orb&!talent.comet_storm);
	if cooldown[FT.ConeOfCold].ready and mana >= 2000 and (talents[FT.ColdestSnap] and ( spellHistory[1] == FT.CometStorm or spellHistory[1] == FT.FrozenOrb and not talents[FT.CometStorm] )) then
		return FT.ConeOfCold;
	end

	-- frozen_orb,if=!prev_gcd.1.glacial_spike|!freezable;
	if talents[FT.FrozenOrb] and cooldown[FT.FrozenOrb].ready and mana >= 500 and (not spellHistory[1] == FT.GlacialSpike ) then
		return FT.FrozenOrb;
	end

	-- blizzard,if=!prev_gcd.1.glacial_spike|!freezable;
	if cooldown[FT.Blizzard].ready and mana >= 1250 and currentSpell ~= FT.Blizzard and (not spellHistory[1] == FT.GlacialSpike ) then
		return FT.Blizzard;
	end

	-- comet_storm,if=!prev_gcd.1.glacial_spike&(!talent.coldest_snap|cooldown.cone_of_cold.ready&cooldown.frozen_orb.remains>25|cooldown.cone_of_cold.remains>20);
	if talents[FT.CometStorm] and cooldown[FT.CometStorm].ready and mana >= 500 and (not spellHistory[1] == FT.GlacialSpike and ( not talents[FT.ColdestSnap] or cooldown[FT.ConeOfCold].ready and cooldown[FT.FrozenOrb].remains > 25 or cooldown[FT.ConeOfCold].remains > 20 )) then
		return FT.CometStorm;
	end

	-- freeze,if=freezable&debuff.frozen.down&(!talent.glacial_spike&!talent.snowstorm|prev_gcd.1.glacial_spike|cooldown.cone_of_cold.ready&buff.snowstorm.stack=buff.snowstorm.max_stack);
	if not debuff[FT.Frozen].up and ( not talents[FT.GlacialSpike] and not talents[FT.Snowstorm] or spellHistory[1] == FT.GlacialSpike or cooldown[FT.ConeOfCold].ready and buff[FT.Snowstorm].count == buff[FT.Snowstorm].maxStacks ) then
		return FT.Freeze;
	end

	-- ice_nova,if=freezable&!prev_off_gcd.freeze&(prev_gcd.1.glacial_spike|cooldown.cone_of_cold.ready&buff.snowstorm.stack=buff.snowstorm.max_stack&gcd.max<1);
	if talents[FT.IceNova] and cooldown[FT.IceNova].ready and (not spellHistory[1] == FT.Freeze and ( spellHistory[1] == FT.GlacialSpike or cooldown[FT.ConeOfCold].ready and buff[FT.Snowstorm].count == buff[FT.Snowstorm].maxStacks and gcd < 1 )) then
		return FT.IceNova;
	end

	-- frost_nova,if=freezable&!prev_off_gcd.freeze&(prev_gcd.1.glacial_spike&!remaining_winters_chill|cooldown.cone_of_cold.ready&buff.snowstorm.stack=buff.snowstorm.max_stack&gcd.max<1);
	if cooldown[FT.FrostNova].ready and mana >= 1000 and (not spellHistory[1] == FT.Freeze and ( spellHistory[1] == FT.GlacialSpike and not cooldown[FT.ConeOfCold].ready and buff[FT.Snowstorm].count == buff[FT.Snowstorm].maxStacks and gcd < 1 )) then
		return FT.FrostNova;
	end

	-- cone_of_cold,if=buff.snowstorm.stack=buff.snowstorm.max_stack;
	if cooldown[FT.ConeOfCold].ready and mana >= 2000 and (buff[FT.Snowstorm].count == buff[FT.Snowstorm].maxStacks) then
		return FT.ConeOfCold;
	end

	-- shifting_power;
	if talents[FT.ShiftingPower] and cooldown[FT.ShiftingPower].ready and mana >= 2500 then
		return FT.ShiftingPower;
	end

	-- glacial_spike,if=buff.icicles.react=5&cooldown.blizzard.remains>gcd.max;
	if talents[FT.GlacialSpike] and mana >= 500 and currentSpell ~= FT.GlacialSpike and (buff[FT.Icicles].count == 5 and cooldown[FT.Blizzard].remains > gcd) then
		return FT.GlacialSpike;
	end

	-- flurry,if=!freezable&cooldown_react&!debuff.winters_chill.remains&(prev_gcd.1.glacial_spike|charges_fractional>1.8);
	if talents[FT.Flurry] and cooldown[FT.Flurry].ready and mana >= 500 and (not cooldownReact and not debuff[FT.WintersChill].remains and ( spellHistory[1] == FT.GlacialSpike or cooldown[FT.Flurry].charges > 1.8 )) then
		return FT.Flurry;
	end

	-- flurry,if=cooldown_react&!debuff.winters_chill.remains&(buff.brain_freeze.react|!buff.fingers_of_frost.react);
	if talents[FT.Flurry] and cooldown[FT.Flurry].ready and mana >= 500 and (cooldownReact and not debuff[FT.WintersChill].remains and ( buff[FT.BrainFreeze].count or not buff[FT.FingersOfFrost].count )) then
		return FT.Flurry;
	end

	-- ice_lance,if=buff.fingers_of_frost.react|debuff.frozen.remains>travel_time|remaining_winters_chill;
	if talents[FT.IceLance] and mana >= 500 and (buff[FT.FingersOfFrost].count or debuff[FT.Frozen].remains) then
		return FT.IceLance;
	end

	-- ice_nova,if=active_enemies>=4&(!talent.snowstorm&!talent.glacial_spike|!freezable);
	if talents[FT.IceNova] and cooldown[FT.IceNova].ready and (targets >= 4 and ( not talents[FT.Snowstorm] and not talents[FT.GlacialSpike] )) then
		return FT.IceNova;
	end

	-- dragons_breath,if=active_enemies>=7;
	if talents[FT.DragonsBreath] and cooldown[FT.DragonsBreath].ready and mana >= 2000 and (targets >= 7) then
		return FT.DragonsBreath;
	end

	-- arcane_explosion,if=mana.pct>30&active_enemies>=7;
	if mana >= 5000 and (manaPct > 30 and targets >= 7) then
		return FT.ArcaneExplosion;
	end

	-- frostbolt;
	if mana >= 1000 and currentSpell ~= FT.Frostbolt then
		return FT.Frostbolt;
	end

	-- call_action_list,name=movement;
	local result = Mage:FrostMovement();
	if result then
		return result;
	end
end

function Mage:FrostCds()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local spellHistory = fd.spellHistory;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- time_warp,if=buff.bloodlust.down&prev_off_gcd.icy_veins;
	if cooldown[FT.TimeWarp].ready and mana >= 2000 and (not buff[FT.Bloodlust].up and spellHistory[1] == FT.IcyVeins) then
		return FT.TimeWarp;
	end

	-- flurry,if=time=0&active_enemies<=2;
	if talents[FT.Flurry] and cooldown[FT.Flurry].ready and mana >= 500 and (GetTime() == 0 and targets <= 2) then
		return FT.Flurry;
	end

	-- icy_veins;
	if talents[FT.IcyVeins] and cooldown[FT.IcyVeins].ready then
		return FT.IcyVeins;
	end
end

function Mage:FrostMovement()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- any_blink,if=movement.distance>10;
	if 10 then
		return FT.AnyBlink;
	end

	-- ice_floes,if=buff.ice_floes.down;
	if talents[FT.IceFloes] and cooldown[FT.IceFloes].ready and (not buff[FT.IceFloes].up) then
		return FT.IceFloes;
	end

	-- ice_nova;
	if talents[FT.IceNova] and cooldown[FT.IceNova].ready then
		return FT.IceNova;
	end

	-- arcane_explosion,if=mana.pct>30&active_enemies>=2;
	if mana >= 5000 and (manaPct > 30 and targets >= 2) then
		return FT.ArcaneExplosion;
	end

	-- fire_blast;
	if cooldown[FT.FireBlast].ready and mana >= 500 then
		return FT.FireBlast;
	end

	-- ice_lance;
	if talents[FT.IceLance] and mana >= 500 then
		return FT.IceLance;
	end
end

function Mage:FrostSt()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local spellHistory = fd.spellHistory;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- comet_storm,if=prev_gcd.1.flurry|prev_gcd.1.cone_of_cold;
	if talents[FT.CometStorm] and cooldown[FT.CometStorm].ready and mana >= 500 and (spellHistory[1] == FT.Flurry or spellHistory[1] == FT.ConeOfCold) then
		return FT.CometStorm;
	end

	-- flurry,if=cooldown_react&remaining_winters_chill=0&debuff.winters_chill.down&(prev_gcd.1.frostbolt|prev_gcd.1.glacial_spike|talent.glacial_spike&buff.icicles.react=4&!buff.fingers_of_frost.react);
	if talents[FT.Flurry] and cooldown[FT.Flurry].ready and mana >= 500 and (cooldownReact and not debuff[FT.WintersChill].up and ( spellHistory[1] == FT.Frostbolt or spellHistory[1] == FT.GlacialSpike or talents[FT.GlacialSpike] and buff[FT.Icicles].count == 4 and not buff[FT.FingersOfFrost].count )) then
		return FT.Flurry;
	end

	-- ice_lance,if=talent.glacial_spike&debuff.winters_chill.down&buff.icicles.react=4&buff.fingers_of_frost.react;
	if talents[FT.IceLance] and mana >= 500 and (talents[FT.GlacialSpike] and not debuff[FT.WintersChill].up and buff[FT.Icicles].count == 4 and buff[FT.FingersOfFrost].count) then
		return FT.IceLance;
	end

	-- ray_of_frost,if=remaining_winters_chill=1;
	if talents[FT.RayOfFrost] and cooldown[FT.RayOfFrost].ready and mana >= 1000 then
		return FT.RayOfFrost;
	end

	-- glacial_spike,if=buff.icicles.react=5&(action.flurry.cooldown_react|remaining_winters_chill);
	if talents[FT.GlacialSpike] and mana >= 500 and currentSpell ~= FT.GlacialSpike and (buff[FT.Icicles].count == 5 ) then
		return FT.GlacialSpike;
	end

	-- frozen_orb,if=buff.fingers_of_frost.react<2&(!talent.ray_of_frost|cooldown.ray_of_frost.remains);
	if talents[FT.FrozenOrb] and cooldown[FT.FrozenOrb].ready and mana >= 500 and (buff[FT.FingersOfFrost].count < 2 and ( not talents[FT.RayOfFrost] or cooldown[FT.RayOfFrost].remains )) then
		return FT.FrozenOrb;
	end

	-- cone_of_cold,if=talent.coldest_snap&cooldown.comet_storm.remains>10&cooldown.frozen_orb.remains>10&remaining_winters_chill=0&active_enemies>=3;
	if cooldown[FT.ConeOfCold].ready and mana >= 2000 and (talents[FT.ColdestSnap] and cooldown[FT.CometStorm].remains > 10 and cooldown[FT.FrozenOrb].remains > 10 and targets >= 3) then
		return FT.ConeOfCold;
	end

	-- blizzard,if=active_enemies>=2&talent.ice_caller&talent.freezing_rain&(!talent.splintering_cold&!talent.ray_of_frost|buff.freezing_rain.up|active_enemies>=3);
	if cooldown[FT.Blizzard].ready and mana >= 1250 and currentSpell ~= FT.Blizzard and (targets >= 2 and talents[FT.IceCaller] and talents[FT.FreezingRain] and ( not talents[FT.SplinteringCold] and not talents[FT.RayOfFrost] or buff[FT.FreezingRain].up or targets >= 3 )) then
		return FT.Blizzard;
	end

	-- shifting_power,if=cooldown.frozen_orb.remains>10&(!talent.comet_storm|cooldown.comet_storm.remains>10)&(!talent.ray_of_frost|cooldown.ray_of_frost.remains>10)|cooldown.icy_veins.remains<20;
	if talents[FT.ShiftingPower] and cooldown[FT.ShiftingPower].ready and mana >= 2500 and (cooldown[FT.FrozenOrb].remains > 10 and ( not talents[FT.CometStorm] or cooldown[FT.CometStorm].remains > 10 ) and ( not talents[FT.RayOfFrost] or cooldown[FT.RayOfFrost].remains > 10 ) or cooldown[FT.IcyVeins].remains < 20) then
		return FT.ShiftingPower;
	end

	-- ice_lance,if=buff.fingers_of_frost.react&!prev_gcd.1.glacial_spike|remaining_winters_chill;
	if talents[FT.IceLance] and mana >= 500 and (buff[FT.FingersOfFrost].count and not spellHistory[1] == FT.GlacialSpike ) then
		return FT.IceLance;
	end

	-- ice_nova,if=active_enemies>=4;
	if talents[FT.IceNova] and cooldown[FT.IceNova].ready and (targets >= 4) then
		return FT.IceNova;
	end

	-- glacial_spike,if=buff.icicles.react=5&buff.icy_veins.up;
	if talents[FT.GlacialSpike] and mana >= 500 and currentSpell ~= FT.GlacialSpike and (buff[FT.Icicles].count == 5 and buff[FT.IcyVeins].up) then
		return FT.GlacialSpike;
	end

	-- frostbolt;
	if mana >= 1000 and currentSpell ~= FT.Frostbolt then
		return FT.Frostbolt;
	end

	-- call_action_list,name=movement;
	local result = Mage:FrostMovement();
	if result then
		return result;
	end
end


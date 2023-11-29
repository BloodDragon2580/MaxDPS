local _, addonTable = ...;

-- @type MaxDps;
if not MaxDps then return end;
local Warrior = addonTable.Warrior;
local MaxDps = MaxDps;

local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;

local itemID = GetInventoryItemID('player', INVSLOT_MAINHAND);

local mainHandSubClassID = itemID and  select(13, GetItemInfo(itemID));

local TwoHanderWepCheck = mainHandSubClassID and (mainHandSubClassID == 1 or mainHandSubClassID == 5 or mainHandSubClassID == 8 or mainHandSubClassID == 10);

local FR = {
	BerserkerStance = 386196,
	Avatar = 107574,
	TitansTorment = 390135,
	Recklessness = 1719,
	RecklessAbandon = 396749,
	Charge = 100,
	HeroicLeap = 6544,
	Pummel = 6552,
	Ravager = 228920,
	Enrage = 184361,
	BerserkersTorment = 390123,
	Annihilator = 383916,
	SpearOfBastion = 376079,
	OdynsFury = 385059,
	TitanicRage = 394329,
	MeatCleaver = 280392,
	Whirlwind = 190411,
	ImprovedWhirlwind = 12950,
	Massacre = 206315,
	SuddenDeathAura = 280776,
	Execute = 280735,
	AshenJuggernaut = 392536,
	ThunderousRoar = 384318,
	Bloodbath = 335096,
	Tier304pc = 409983,
	Bloodthirst = 23881,
	CrushingBlow = 335097,
	WrathAndFury = 392936,
	Rampage = 184367,
	OverwhelmingRage = 382767,
	Onslaught = 315720,
	Tenderize = 388933,
	RagingBlow = 85288,
	Slam = 1464,
	DancingBlades = 391683,
	AngerManagement = 152278,
	WreckingThrow = 384110,
	StormBolt = 107570,
};
local A = {
};
function Warrior:Fury()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local timeToDie = fd.timeToDie;
	local canExecute = ((talents[FR.Massacre] and targetHp < 35) or targetHp < 20) or buff[FR.SuddenDeathAura].up;

	-- ravager,if=cooldown.recklessness.remains<3|buff.recklessness.up;
	if talents[FR.Ravager] and cooldown[FR.Ravager].ready and (cooldown[FR.Recklessness].remains < 3 or buff[FR.Recklessness].up) then
		return FR.Ravager;
	end

	-- avatar,if=talent.titans_torment&buff.enrage.up&raid_event.adds.in>15|talent.berserkers_torment&buff.enrage.up&!buff.avatar.up&raid_event.adds.in>15|!talent.titans_torment&!talent.berserkers_torment&(buff.recklessness.up|target.time_to_die<20);
	if talents[FR.Avatar] and cooldown[FR.Avatar].ready and (talents[FR.TitansTorment] and buff[FR.Enrage].up or talents[FR.BerserkersTorment] and buff[FR.Enrage].up and not buff[FR.Avatar].up or not talents[FR.TitansTorment] and not talents[FR.BerserkersTorment] and ( buff[FR.Recklessness].up or timeToDie < 20 )) then
		return FR.Avatar;
	end

	-- recklessness,if=!raid_event.adds.exists&(talent.annihilator&cooldown.avatar.remains<1|cooldown.avatar.remains>40|!talent.avatar|target.time_to_die<12);
	if talents[FR.Recklessness] and cooldown[FR.Recklessness].ready and (targets <= 1 and ( talents[FR.Annihilator] and cooldown[FR.Avatar].remains < 1 or cooldown[FR.Avatar].remains > 40 or not talents[FR.Avatar] or timeToDie < 12 )) then
		return FR.Recklessness;
	end

	-- recklessness,if=!raid_event.adds.exists&!talent.annihilator|target.time_to_die<12;
	if talents[FR.Recklessness] and cooldown[FR.Recklessness].ready and (targets <= 1 and not talents[FR.Annihilator] or timeToDie < 12) then
		return FR.Recklessness;
	end

	-- spear_of_bastion,if=buff.enrage.up&(buff.recklessness.up|buff.avatar.up|target.time_to_die<20|active_enemies>1)&raid_event.adds.in>15;
	if talents[FR.SpearOfBastion] and cooldown[FR.SpearOfBastion].ready and (buff[FR.Enrage].up and ( buff[FR.Recklessness].up or buff[FR.Avatar].up or timeToDie < 20 or targets > 1 ) ) then
		return FR.SpearOfBastion;
	end

	-- call_action_list,name=multi_target,if=raid_event.adds.exists|active_enemies>2;
	if targets > 1 or targets > 2 then
		local result = Warrior:FuryMultiTarget();
		if result then
			return result;
		end
	end

	-- call_action_list,name=single_target,if=!raid_event.adds.exists;
	if targets <= 1 then
		local result = Warrior:FurySingleTarget();
		if result then
			return result;
		end
	end
end
function Warrior:FuryMultiTarget()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local gcd = fd.gcd;
	local timeToDie = fd.timeToDie;
	local rage = UnitPower('player', Enum.PowerType.Rage);
	local rageMax = UnitPowerMax('player', Enum.PowerType.Rage);
	local ragePct = UnitPower('player')/UnitPowerMax('player') * 100;
	local rageRegen = select(2,GetPowerRegen());
	local rageRegenCombined = rageRegen + rage;
	local rageDeficit = UnitPowerMax('player', Enum.PowerType.Rage) - rage;
	local rageTimeToMax = rageMax - rage / rageRegen;
	local canExecute = ((talents[FR.Massacre] and targetHp < 35) or targetHp < 20) or buff[FR.SuddenDeathAura].up;

	-- recklessness,if=raid_event.adds.in>15|active_enemies>1|target.time_to_die<12;
	if talents[FR.Recklessness] and cooldown[FR.Recklessness].ready and (targets > 1 or timeToDie < 12) then
		return FR.Recklessness;
	end

	-- odyns_fury,if=active_enemies>1&talent.titanic_rage&(!buff.meat_cleaver.up|buff.avatar.up|buff.recklessness.up);
	if talents[FR.OdynsFury] and cooldown[FR.OdynsFury].ready and (targets > 1 and talents[FR.TitanicRage] and ( not buff[FR.MeatCleaver].up or buff[FR.Avatar].up or buff[FR.Recklessness].up )) then
		return FR.OdynsFury;
	end

	-- whirlwind,if=spell_targets.whirlwind>1&talent.improved_whirlwind&!buff.meat_cleaver.up|raid_event.adds.in<2&talent.improved_whirlwind&!buff.meat_cleaver.up;
	if targets > 1 and talents[FR.ImprovedWhirlwind] and not buff[FR.MeatCleaver].up or talents[FR.ImprovedWhirlwind] and not buff[FR.MeatCleaver].up then
		return FR.Whirlwind;
	end

	-- execute,if=buff.ashen_juggernaut.up&buff.ashen_juggernaut.remains<gcd;
	if canExecute and cooldown[FR.Execute].ready and rage >= 20 and (buff[FR.AshenJuggernaut].up and buff[FR.AshenJuggernaut].remains < gcd) then
		return FR.Execute;
	end

	-- thunderous_roar,if=buff.enrage.up&(spell_targets.whirlwind>1|raid_event.adds.in>15);
	if talents[FR.ThunderousRoar] and cooldown[FR.ThunderousRoar].ready and (buff[FR.Enrage].up and ( targets > 1 )) then
		return FR.ThunderousRoar;
	end

	-- odyns_fury,if=active_enemies>1&buff.enrage.up&raid_event.adds.in>15;
	if talents[FR.OdynsFury] and cooldown[FR.OdynsFury].ready and (targets > 1 and buff[FR.Enrage].up) then
		return FR.OdynsFury;
	end

	-- bloodbath,if=set_bonus.tier30_4pc&action.bloodthirst.crit_pct_current>=95;
	if MaxDps:FindSpell(FR.Bloodbath) and (MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 4) and buff[FR.Tier304pc].count >= 9) then
		return FR.Bloodbath;
	end

	-- bloodthirst,if=set_bonus.tier30_4pc&action.bloodthirst.crit_pct_current>=95;
	if talents[FR.Bloodthirst] and cooldown[FR.Bloodthirst].ready and (MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 4) and buff[FR.Tier304pc].count >= 9) then
		return FR.Bloodthirst;
	end

	-- crushing_blow,if=talent.wrath_and_fury&buff.enrage.up;
	if MaxDps:FindSpell(FR.CrushingBlow) and (talents[FR.WrathAndFury] and buff[FR.Enrage].up) then
		return FR.CrushingBlow;
	end

	-- execute,if=buff.enrage.up;
	if canExecute and cooldown[FR.Execute].ready and rage >= 20 and (buff[FR.Enrage].up) then
		return FR.Execute;
	end

	-- odyns_fury,if=buff.enrage.up&raid_event.adds.in>15;
	if talents[FR.OdynsFury] and cooldown[FR.OdynsFury].ready and (buff[FR.Enrage].up) then
		return FR.OdynsFury;
	end

	-- rampage,if=buff.recklessness.up|buff.enrage.remains<gcd|(rage>110&talent.overwhelming_rage)|(rage>80&!talent.overwhelming_rage);
	if talents[FR.Rampage] and rage >= 80 and (buff[FR.Recklessness].up or buff[FR.Enrage].remains < gcd or ( rage > 110 and talents[FR.OverwhelmingRage] ) or ( rage > 80 and not talents[FR.OverwhelmingRage] )) then
		return FR.Rampage;
	end

	-- execute;
	if canExecute and cooldown[FR.Execute].ready and rage >= 20 then
		return FR.Execute;
	end

	-- bloodbath,if=buff.enrage.up&talent.reckless_abandon&!talent.wrath_and_fury;
	if MaxDps:FindSpell(FR.Bloodbath) and (buff[FR.Enrage].up and talents[FR.RecklessAbandon] and not talents[FR.WrathAndFury]) then
		return FR.Bloodbath;
	end

	-- bloodthirst,if=buff.enrage.down|(talent.annihilator&!buff.recklessness.up);
	if talents[FR.Bloodthirst] and cooldown[FR.Bloodthirst].ready and (not buff[FR.Enrage].up or ( talents[FR.Annihilator] and not buff[FR.Recklessness].up )) then
		return FR.Bloodthirst;
	end

	-- onslaught,if=!talent.annihilator&buff.enrage.up|talent.tenderize;
	if talents[FR.Onslaught] and cooldown[FR.Onslaught].ready and (not talents[FR.Annihilator] and buff[FR.Enrage].up or talents[FR.Tenderize]) then
		return FR.Onslaught;
	end

	-- raging_blow,if=charges>1&talent.wrath_and_fury;
	if talents[FR.RagingBlow] and cooldown[FR.RagingBlow].ready and (cooldown[FR.RagingBlow].charges > 1 and talents[FR.WrathAndFury]) then
		return FR.RagingBlow;
	end

	-- crushing_blow,if=charges>1&talent.wrath_and_fury;
	if MaxDps:FindSpell(FR.CrushingBlow) and (cooldown[FR.CrushingBlow].charges > 1 and talents[FR.WrathAndFury]) then
		return FR.CrushingBlow;
	end

	-- bloodbath,if=buff.enrage.down|!talent.wrath_and_fury;
	if MaxDps:FindSpell(FR.Bloodbath) and (not buff[FR.Enrage].up or not talents[FR.WrathAndFury]) then
		return FR.Bloodbath;
	end

	-- crushing_blow,if=buff.enrage.up&talent.reckless_abandon;
	if MaxDps:FindSpell(FR.CrushingBlow) and (buff[FR.Enrage].up and talents[FR.RecklessAbandon]) then
		return FR.CrushingBlow;
	end

	-- bloodthirst,if=!talent.wrath_and_fury;
	if talents[FR.Bloodthirst] and cooldown[FR.Bloodthirst].ready and (not talents[FR.WrathAndFury]) then
		return FR.Bloodthirst;
	end

	-- raging_blow,if=charges>=1;
	if talents[FR.RagingBlow] and cooldown[FR.RagingBlow].ready and (cooldown[FR.RagingBlow].charges >= 1) then
		return FR.RagingBlow;
	end

	-- rampage;
	if talents[FR.Rampage] and rage >= 80 then
		return FR.Rampage;
	end

	-- slam,if=talent.annihilator;
	if rage >= 20 and (talents[FR.Annihilator]) then
		return FR.Slam;
	end

	-- bloodbath;
	if MaxDps:FindSpell(FR.Bloodbath) then
		return FR.Bloodbath;
	end

	-- raging_blow;
	if talents[FR.RagingBlow] and cooldown[FR.RagingBlow].ready then
		return FR.RagingBlow;
	end

	-- crushing_blow;
	if MaxDps:FindSpell(FR.CrushingBlow) then
		return FR.CrushingBlow;
	end

	-- whirlwind;
	-- FR.Whirlwind;
end

function Warrior:FurySingleTarget()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local gcd = fd.gcd;
	local rage = UnitPower('player', Enum.PowerType.Rage);
	local rageMax = UnitPowerMax('player', Enum.PowerType.Rage);
	local ragePct = UnitPower('player')/UnitPowerMax('player') * 100;
	local rageRegen = select(2,GetPowerRegen());
	local rageRegenCombined = rageRegen + rage;
	local rageDeficit = UnitPowerMax('player', Enum.PowerType.Rage) - rage;
	local rageTimeToMax = rageMax - rage / rageRegen;
	local canExecute = ((talents[FR.Massacre] and targetHp < 35) or targetHp < 20) or buff[FR.SuddenDeathAura].up;

	-- whirlwind,if=spell_targets.whirlwind>1&talent.improved_whirlwind&!buff.meat_cleaver.up|raid_event.adds.in<2&talent.improved_whirlwind&!buff.meat_cleaver.up;
	if targets > 1 and talents[FR.ImprovedWhirlwind] and not buff[FR.MeatCleaver].up or talents[FR.ImprovedWhirlwind] and not buff[FR.MeatCleaver].up then
		return FR.Whirlwind;
	end

	-- execute,if=buff.ashen_juggernaut.up&buff.ashen_juggernaut.remains<gcd;
	if canExecute and cooldown[FR.Execute].ready and rage >= 20 and (buff[FR.AshenJuggernaut].up and buff[FR.AshenJuggernaut].remains < gcd) then
		return FR.Execute;
	end

	-- thunderous_roar,if=buff.enrage.up&(spell_targets.whirlwind>1|raid_event.adds.in>15);
	if talents[FR.ThunderousRoar] and cooldown[FR.ThunderousRoar].ready and (buff[FR.Enrage].up and ( targets > 1 )) then
		return FR.ThunderousRoar;
	end

	-- odyns_fury,if=buff.enrage.up&(spell_targets.whirlwind>1|raid_event.adds.in>15)&(talent.dancing_blades&buff.dancing_blades.remains<5|!talent.dancing_blades);
	if talents[FR.OdynsFury] and cooldown[FR.OdynsFury].ready and (buff[FR.Enrage].up and ( targets > 1 ) and ( talents[FR.DancingBlades] and buff[FR.DancingBlades].remains < 5 or not talents[FR.DancingBlades] )) then
		return FR.OdynsFury;
	end

	-- rampage,if=talent.anger_management&(buff.recklessness.up|buff.enrage.remains<gcd|rage.pct>85);
	if talents[FR.Rampage] and rage >= 80 and (talents[FR.AngerManagement] and ( buff[FR.Recklessness].up or buff[FR.Enrage].remains < gcd or ragePct > 85 )) then
		return FR.Rampage;
	end

	-- bloodbath,if=set_bonus.tier30_4pc&action.bloodthirst.crit_pct_current>=95;
	if MaxDps:FindSpell(FR.Bloodbath) and (MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 4) and buff[FR.Tier304pc].count >= 9) then
		return FR.Bloodbath;
	end

	-- bloodthirst,if=set_bonus.tier30_4pc&action.bloodthirst.crit_pct_current>=95;
	if talents[FR.Bloodthirst] and cooldown[FR.Bloodthirst].ready and (MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 4) and buff[FR.Tier304pc].count >= 9) then
		return FR.Bloodthirst;
	end

	-- execute,if=buff.enrage.up;
	if canExecute and cooldown[FR.Execute].ready and rage >= 20 and (buff[FR.Enrage].up) then
		return FR.Execute;
	end

	-- onslaught,if=buff.enrage.up|talent.tenderize;
	if talents[FR.Onslaught] and cooldown[FR.Onslaught].ready and (buff[FR.Enrage].up or talents[FR.Tenderize]) then
		return FR.Onslaught;
	end

	-- crushing_blow,if=talent.wrath_and_fury&buff.enrage.up;
	if MaxDps:FindSpell(FR.CrushingBlow) and (talents[FR.WrathAndFury] and buff[FR.Enrage].up) then
		return FR.CrushingBlow;
	end

	-- rampage,if=talent.reckless_abandon&(buff.recklessness.up|buff.enrage.remains<gcd|rage.pct>85);
	if talents[FR.Rampage] and rage >= 80 and (talents[FR.RecklessAbandon] and ( buff[FR.Recklessness].up or buff[FR.Enrage].remains < gcd or ragePct > 85 )) then
		return FR.Rampage;
	end

	-- rampage,if=talent.anger_management;
	if talents[FR.Rampage] and rage >= 80 and (talents[FR.AngerManagement]) then
		return FR.Rampage;
	end

	-- execute;
	if canExecute and cooldown[FR.Execute].ready and rage >= 20 then
		return FR.Execute;
	end

	-- bloodbath,if=buff.enrage.up&talent.reckless_abandon&!talent.wrath_and_fury;
	if MaxDps:FindSpell(FR.Bloodbath) and (buff[FR.Enrage].up and talents[FR.RecklessAbandon] and not talents[FR.WrathAndFury]) then
		return FR.Bloodbath;
	end

	-- bloodthirst,if=buff.enrage.down|(talent.annihilator&!buff.recklessness.up);
	if talents[FR.Bloodthirst] and cooldown[FR.Bloodthirst].ready and (not buff[FR.Enrage].up or ( talents[FR.Annihilator] and not buff[FR.Recklessness].up )) then
		return FR.Bloodthirst;
	end

	-- raging_blow,if=charges>1&talent.wrath_and_fury;
	if talents[FR.RagingBlow] and cooldown[FR.RagingBlow].ready and (cooldown[FR.RagingBlow].charges > 1 and talents[FR.WrathAndFury]) then
		return FR.RagingBlow;
	end

	-- crushing_blow,if=charges>1&talent.wrath_and_fury;
	if MaxDps:FindSpell(FR.CrushingBlow) and (cooldown[FR.CrushingBlow].charges > 1 and talents[FR.WrathAndFury]) then
		return FR.CrushingBlow;
	end

	-- bloodbath,if=buff.enrage.down|!talent.wrath_and_fury;
	if MaxDps:FindSpell(FR.Bloodbath) and (not buff[FR.Enrage].up or not talents[FR.WrathAndFury]) then
		return FR.Bloodbath;
	end

	-- crushing_blow,if=buff.enrage.up&talent.reckless_abandon;
	if MaxDps:FindSpell(FR.CrushingBlow) and (buff[FR.Enrage].up and talents[FR.RecklessAbandon]) then
		return FR.CrushingBlow;
	end

	-- bloodthirst,if=!talent.wrath_and_fury;
	if talents[FR.Bloodthirst] and cooldown[FR.Bloodthirst].ready and (not talents[FR.WrathAndFury]) then
		return FR.Bloodthirst;
	end

	-- raging_blow,if=charges>1;
	if talents[FR.RagingBlow] and cooldown[FR.RagingBlow].ready and (cooldown[FR.RagingBlow].charges > 1) then
		return FR.RagingBlow;
	end

	-- rampage;
	if talents[FR.Rampage] and rage >= 80 then
		return FR.Rampage;
	end

	-- slam,if=talent.annihilator;
	if rage >= 20 and (talents[FR.Annihilator]) then
		return FR.Slam;
	end

	-- bloodbath;
	if MaxDps:FindSpell(FR.Bloodbath) then
		return FR.Bloodbath;
	end

	-- raging_blow;
	if talents[FR.RagingBlow] and cooldown[FR.RagingBlow].ready then
		return FR.RagingBlow;
	end

	-- crushing_blow;
	if MaxDps:FindSpell(FR.CrushingBlow) then
		return FR.CrushingBlow;
	end

	-- bloodthirst;
	if talents[FR.Bloodthirst] and cooldown[FR.Bloodthirst].ready then
		return FR.Bloodthirst;
	end

	-- whirlwind;
	-- FR.Whirlwind;

	-- wrecking_throw;
	if talents[FR.WreckingThrow] and cooldown[FR.WreckingThrow].ready then
		return FR.WreckingThrow;
	end

	-- storm_bolt;
	if talents[FR.StormBolt] and cooldown[FR.StormBolt].ready then
		return FR.StormBolt;
	end
end


local _, addonTable = ...;

-- @type MaxDps;
if not MaxDps then return end;
local Paladin = addonTable.Paladin;
local MaxDps = MaxDps;

local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;

local itemID = GetInventoryItemID('player', INVSLOT_MAINHAND);

local mainHandSubClassID = itemID and  select(13, GetItemInfo(itemID));

local TwoHanderWepCheck = mainHandSubClassID and (mainHandSubClassID == 1 or mainHandSubClassID == 5 or mainHandSubClassID == 8 or mainHandSubClassID == 10);

local RT = {
	ShieldOfVengeance = 184662,
	Crusade = 231895,
	AvengingWrath = 31884,
	Rebuke = 96231,
	ExecutionSentence = 343527,
	DivineAuxiliary = 406158,
	ExecutionersWill = 406940,
	FinalReckoning = 343721,
	DivineArbiter = 404306,
	EmpyreanPower = 326732,
	EmpyreanLegacy = 387170,
	DivineStorm = 53385,
	JusticarsVengeance = 215661,
	TemplarsVerdict = 85256,
	Judgment = 20271,
	DivineResonance = 384027,
	WakeOfAshes = 255937,
	DivineToll = 375576,
	TemplarSlash = 406647,
	TemplarStrikes = 406646,
	BladeOfJustice = 184575,
	HolyBlade = 383342,
	CrusadingStrikes = 404542,
	HammerOfWrath = 24275,
	BlessedChampion = 403010,
	Tier304pc = 393677,
	VanguardsMomentum = 383314,
	BoundlessJudgment = 405278,
	Consecration = 26573,
	DivineHammer = 198034,
	CrusaderStrike = 35395,
	TemplarStrike = 407480,
};
local A = {
};
function Paladin:Retribution()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;

	-- call_action_list,name=cooldowns;
	local result = Paladin:RetributionCooldowns();
	if result then
		return result;
	end

	-- call_action_list,name=generators;
	local result = Paladin:RetributionGenerators();
	if result then
		return result;
	end
end
function Paladin:RetributionCooldowns()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local timeToDie = fd.timeToDie;
	local holyPower = UnitPower('player', Enum.PowerType.HolyPower);
	local holyPowerMax = UnitPowerMax('player', Enum.PowerType.HolyPower);
	local holyPowerPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local holyPowerRegen = select(2,GetPowerRegen());
	local holyPowerRegenCombined = holyPowerRegen + holyPower;
	local holyPowerDeficit = UnitPowerMax('player', Enum.PowerType.HolyPower) - holyPower;
	local holyPowerTimeToMax = holyPowerMax - holyPower / holyPowerRegen;

	-- shield_of_vengeance,if=fight_remains>15&(!talent.execution_sentence|!debuff.execution_sentence.up);
	if talents[RT.ShieldOfVengeance] and cooldown[RT.ShieldOfVengeance].ready and (timeToDie > 15 and ( not talents[RT.ExecutionSentence] or not debuff[RT.ExecutionSentence].up )) then
		return RT.ShieldOfVengeance;
	end

	-- execution_sentence,if=(!buff.crusade.up&cooldown.crusade.remains>15|buff.crusade.stack=10|cooldown.avenging_wrath.remains<0.75|cooldown.avenging_wrath.remains>15)&(holy_power>=3|holy_power>=2&talent.divine_auxiliary)&(target.time_to_die>8|target.time_to_die>12&talent.executioners_will);
	if talents[RT.ExecutionSentence] and cooldown[RT.ExecutionSentence].ready and (( not buff[RT.Crusade].up and cooldown[RT.Crusade].remains > 15 or buff[RT.Crusade].count == 10 or cooldown[RT.AvengingWrath].remains < 0.75 or cooldown[RT.AvengingWrath].remains > 15 ) and ( holyPower >= 3 or holyPower >= 2 and talents[RT.DivineAuxiliary] ) and ( timeToDie > 8 or timeToDie > 12 and talents[RT.ExecutionersWill] )) then
		return RT.ExecutionSentence;
	end

	-- avenging_wrath,if=holy_power>=4&time<5|holy_power>=3&time>5|holy_power>=2&talent.divine_auxiliary&(cooldown.execution_sentence.remains=0|cooldown.final_reckoning.remains=0);
	if talents[RT.AvengingWrath] and cooldown[RT.AvengingWrath].ready and (holyPower >= 4 and GetTime() < 5 or holyPower >= 3 and GetTime() > 5 or holyPower >= 2 and talents[RT.DivineAuxiliary] and ( cooldown[RT.ExecutionSentence].remains == 0 or cooldown[RT.FinalReckoning].remains == 0 )) then
		return RT.AvengingWrath;
	end

	-- crusade,if=holy_power>=5&time<5|holy_power>=3&time>5;
	if talents[RT.Crusade] and cooldown[RT.Crusade].ready and (holyPower >= 5 and GetTime() < 5 or holyPower >= 3 and GetTime() > 5) then
		return RT.Crusade;
	end

	-- final_reckoning,if=(holy_power>=4&time<8|holy_power>=3&time>=8|holy_power>=2&talent.divine_auxiliary)&(cooldown.avenging_wrath.remains>10|cooldown.crusade.remains&(!buff.crusade.up|buff.crusade.stack>=10))&(time_to_hpg>0|holy_power=5|holy_power>=2&talent.divine_auxiliary)&(!raid_event.adds.exists|raid_event.adds.up|raid_event.adds.in>40);
	if talents[RT.FinalReckoning] and cooldown[RT.FinalReckoning].ready and (( holyPower >= 4 and GetTime() < 8 or holyPower >= 3 and GetTime() >= 8 or holyPower >= 2 and talents[RT.DivineAuxiliary] ) and ( cooldown[RT.AvengingWrath].remains > 10 or cooldown[RT.Crusade].remains and ( not buff[RT.Crusade].up or buff[RT.Crusade].count >= 10 ) ) and ( 0 or holyPower == 5 or holyPower >= 2 and talents[RT.DivineAuxiliary] ) and ( not targets > 1 )) then
		return RT.FinalReckoning;
	end
end

function Paladin:RetributionFinishers()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local gcd = fd.gcd;
	local holyPower = UnitPower('player', Enum.PowerType.HolyPower);
	local holyPowerMax = UnitPowerMax('player', Enum.PowerType.HolyPower);
	local holyPowerPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local holyPowerRegen = select(2,GetPowerRegen());
	local holyPowerRegenCombined = holyPowerRegen + holyPower;
	local holyPowerDeficit = UnitPowerMax('player', Enum.PowerType.HolyPower) - holyPower;
	local holyPowerTimeToMax = holyPowerMax - holyPower / holyPowerRegen;

	-- variable,name=ds_castable,value=(spell_targets.divine_storm>=3|spell_targets.divine_storm>=2&!talent.divine_arbiter|buff.empyrean_power.up)&!buff.empyrean_legacy.up&!(buff.divine_arbiter.up&buff.divine_arbiter.stack>24);
	local dsCastable = ( targets >= 3 or targets >= 2 and not talents[RT.DivineArbiter] or buff[RT.EmpyreanPower].up ) and not buff[RT.EmpyreanLegacy].up and not ( buff[RT.DivineArbiter].up and buff[RT.DivineArbiter].count > 24 );

	-- divine_storm,if=variable.ds_castable&(!talent.crusade|cooldown.crusade.remains>gcd*3|buff.crusade.up&buff.crusade.stack<10);
	if talents[RT.DivineStorm] and holyPower >= 4 and (dsCastable and ( not talents[RT.Crusade] or cooldown[RT.Crusade].remains > gcd * 3 or buff[RT.Crusade].up and buff[RT.Crusade].count < 10 )) then
		return RT.DivineStorm;
	end

	-- justicars_vengeance,if=!talent.crusade|cooldown.crusade.remains>gcd*3|buff.crusade.up&buff.crusade.stack<10;
	if talents[RT.JusticarsVengeance] and holyPower >= 4 and (not talents[RT.Crusade] or cooldown[RT.Crusade].remains > gcd * 3 or buff[RT.Crusade].up and buff[RT.Crusade].count < 10) then
		return RT.JusticarsVengeance;
	end

	-- templars_verdict,if=!talent.crusade|cooldown.crusade.remains>gcd*3|buff.crusade.up&buff.crusade.stack<10;
	if holyPower >= 3 and (not talents[RT.Crusade] or cooldown[RT.Crusade].remains > gcd * 3 or buff[RT.Crusade].up and buff[RT.Crusade].count < 10) then
		return RT.TemplarsVerdict;
	end
end

function Paladin:RetributionGenerators()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local gcd = fd.gcd;
	local timeToDie = fd.timeToDie;
	local holyPower = UnitPower('player', Enum.PowerType.HolyPower);
	local holyPowerMax = UnitPowerMax('player', Enum.PowerType.HolyPower);
	local holyPowerPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local holyPowerRegen = select(2,GetPowerRegen());
	local holyPowerRegenCombined = holyPowerRegen + holyPower;
	local holyPowerDeficit = UnitPowerMax('player', Enum.PowerType.HolyPower) - holyPower;
	local holyPowerTimeToMax = holyPowerMax - holyPower / holyPowerRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- call_action_list,name=finishers,if=holy_power=5|(debuff.judgment.up|holy_power=4)&buff.divine_resonance.up;
	if holyPower == 5 or ( debuff[RT.Judgment].up or holyPower == 4 ) and buff[RT.DivineResonance].up then
		local result = Paladin:RetributionFinishers();
		if result then
			return result;
		end
	end

	-- wake_of_ashes,if=holy_power<=2&(cooldown.avenging_wrath.remains|cooldown.crusade.remains)&(!talent.execution_sentence|cooldown.execution_sentence.remains>4|target.time_to_die<8)&(!raid_event.adds.exists|raid_event.adds.in>20|raid_event.adds.up);
	if talents[RT.WakeOfAshes] and cooldown[RT.WakeOfAshes].ready and (holyPower <= 2 and ( cooldown[RT.AvengingWrath].remains or cooldown[RT.Crusade].remains ) and ( not talents[RT.ExecutionSentence] or cooldown[RT.ExecutionSentence].remains > 4 or timeToDie < 8 ) and ( not targets > 1 )) then
		return RT.WakeOfAshes;
	end

	-- divine_toll,if=holy_power<=2&!debuff.judgment.up&(!raid_event.adds.exists|raid_event.adds.in>30|raid_event.adds.up)&(cooldown.avenging_wrath.remains>15|cooldown.crusade.remains>15|fight_remains<8);
	if talents[RT.DivineToll] and cooldown[RT.DivineToll].ready and mana >= 7500 and (holyPower <= 2 and not debuff[RT.Judgment].up and ( not targets > 1  ) and ( cooldown[RT.AvengingWrath].remains > 15 or cooldown[RT.Crusade].remains > 15 or timeToDie < 8 )) then
		return RT.DivineToll;
	end

	-- call_action_list,name=finishers,if=holy_power>=3&buff.crusade.up&buff.crusade.stack<10;
	if holyPower >= 3 and buff[RT.Crusade].up and buff[RT.Crusade].count < 10 then
		local result = Paladin:RetributionFinishers();
		if result then
			return result;
		end
	end

	-- templar_slash,if=buff.templar_strikes.remains<gcd&spell_targets.divine_storm>=2;
	if MaxDps.Spells[RT.TemplarSlash] and (buff[RT.TemplarStrikes].remains < gcd and targets >= 2) then
		return RT.TemplarSlash;
	end

	-- blade_of_justice,if=(holy_power<=3|!talent.holy_blade)&(spell_targets.divine_storm>=2&!talent.crusading_strikes|spell_targets.divine_storm>=4);
	if talents[RT.BladeOfJustice] and cooldown[RT.BladeOfJustice].ready and (( holyPower <= 3 or not talents[RT.HolyBlade] ) and ( targets >= 2 and not talents[RT.CrusadingStrikes] or targets >= 4 )) then
		return RT.BladeOfJustice;
	end

	-- hammer_of_wrath,if=(spell_targets.divine_storm<2|!talent.blessed_champion|set_bonus.tier30_4pc)&(holy_power<=3|target.health.pct>20|!talent.vanguards_momentum);
	if talents[RT.HammerOfWrath] and cooldown[RT.HammerOfWrath].ready and mana >= 0 and (( targets < 2 or not talents[RT.BlessedChampion] or MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 4) ) and ( holyPower <= 3 or targetHp > 20 or not talents[RT.VanguardsMomentum] )) then
		return RT.HammerOfWrath;
	end

	-- templar_slash,if=buff.templar_strikes.remains<gcd;
	if MaxDps.Spells[RT.TemplarSlash] and (buff[RT.TemplarStrikes].remains < gcd) then
		return RT.TemplarSlash;
	end

	-- judgment,if=!buff.avenging_wrath.up&(holy_power<=3|!talent.boundless_judgment)&talent.crusading_strikes;
	if cooldown[RT.Judgment].ready and mana >= 1500 and (not buff[RT.AvengingWrath].up and ( holyPower <= 3 or not talents[RT.BoundlessJudgment] ) and talents[RT.CrusadingStrikes]) then
		return RT.Judgment;
	end

	-- blade_of_justice,if=holy_power<=3|!talent.holy_blade;
	if talents[RT.BladeOfJustice] and cooldown[RT.BladeOfJustice].ready and (holyPower <= 3 or not talents[RT.HolyBlade]) then
		return RT.BladeOfJustice;
	end

	-- judgment,if=!debuff.judgment.up&(holy_power<=3|!talent.boundless_judgment);
	if cooldown[RT.Judgment].ready and mana >= 1500 and (not debuff[RT.Judgment].up and ( holyPower <= 3 or not talents[RT.BoundlessJudgment] )) then
		return RT.Judgment;
	end

	-- call_action_list,name=finishers,if=(target.health.pct<=20|buff.avenging_wrath.up|buff.crusade.up|buff.empyrean_power.up);
	if ( targetHp <= 20 or buff[RT.AvengingWrath].up or buff[RT.Crusade].up or buff[RT.EmpyreanPower].up ) then
		local result = Paladin:RetributionFinishers();
		if result then
			return result;
		end
	end

	-- consecration,if=!consecration.up&spell_targets.divine_storm>=2;
	if cooldown[RT.Consecration].ready and (not consecrationUp and targets >= 2) then
		return RT.Consecration;
	end

	-- divine_hammer,if=spell_targets.divine_storm>=2;
	if talents[RT.DivineHammer] and cooldown[RT.DivineHammer].ready and (targets >= 2) then
		return RT.DivineHammer;
	end

	-- crusader_strike,if=cooldown.crusader_strike.charges_fractional>=1.75&(holy_power<=2|holy_power<=3&cooldown.blade_of_justice.remains>gcd*2|holy_power=4&cooldown.blade_of_justice.remains>gcd*2&cooldown.judgment.remains>gcd*2);
	if cooldown[RT.CrusaderStrike].charges >= 1.75 and ( holyPower <= 2 or holyPower <= 3 and cooldown[RT.BladeOfJustice].remains > gcd * 2 or holyPower == 4 and cooldown[RT.BladeOfJustice].remains > gcd * 2 and cooldown[RT.Judgment].remains > gcd * 2 ) then
		return RT.CrusaderStrike;
	end

	-- call_action_list,name=finishers;
	local result = Paladin:RetributionFinishers();
	if result then
		return result;
	end

	-- templar_slash;
	if MaxDps.Spells[RT.TemplarSlash] then
		return RT.TemplarSlash;
	end

	-- templar_strike;
	if cooldown[RT.TemplarStrike].ready and mana >= 1000 then
		return RT.TemplarStrike;
	end

	-- judgment,if=holy_power<=3|!talent.boundless_judgment;
	if cooldown[RT.Judgment].ready and mana >= 1500 and (holyPower <= 3 or not talents[RT.BoundlessJudgment]) then
		return RT.Judgment;
	end

	-- hammer_of_wrath,if=holy_power<=3|target.health.pct>20|!talent.vanguards_momentum;
	if talents[RT.HammerOfWrath] and cooldown[RT.HammerOfWrath].ready and mana >= 0 and (holyPower <= 3 or targetHp > 20 or not talents[RT.VanguardsMomentum]) then
		return RT.HammerOfWrath;
	end

	-- crusader_strike;
	-- RT.CrusaderStrike;

	-- consecration;
	if cooldown[RT.Consecration].ready then
		return RT.Consecration;
	end

	-- divine_hammer;
	if talents[RT.DivineHammer] and cooldown[RT.DivineHammer].ready then
		return RT.DivineHammer;
	end
end


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

local PR = {
	Consecration = 26573,
	AvengersShield = 31935,
	Tier292pc = 393673,
	AvengingWrath = 31884,
	MomentOfGlory = 327193,
	Judgment = 275779,
	HammerOfWrath = 24275,
	DivineToll = 375576,
	EyeOfTyr = 387174,
	InmostLight = 405757,
	BastionOfLight = 378974,
	ShieldOfTheRighteous = 53600,
	RighteousProtector = 204074,
	DivinePurpose = 223817,
	BulwarkOfRighteousFury = 386653,
	CrusadersJudgment = 204023,
	BlessedHammer = 204019,
	HammerOfTheRighteous = 53595,
	CrusaderStrike = 35395,
	WordOfGlory = 85673,
};
local A = {
};
function Paladin:Protection()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;

	-- call_action_list,name=cooldowns;
	local result = Paladin:ProtectionCooldowns();
	if result then
		return result;
	end

	-- call_action_list,name=trinkets;

	-- call_action_list,name=standard;
	local result = Paladin:ProtectionStandard();
	if result then
		return result;
	end
end
function Paladin:ProtectionCooldowns()
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

	-- avengers_shield,if=time=0&set_bonus.tier29_2pc;
	if talents[PR.AvengersShield] and cooldown[PR.AvengersShield].ready and (GetTime() == 0 and MaxDps.tier[29] and MaxDps.tier[29].count and (MaxDps.tier[29].count == 2)) then
		return PR.AvengersShield;
	end

	-- avenging_wrath;
	if talents[PR.AvengingWrath] and cooldown[PR.AvengingWrath].ready then
		return PR.AvengingWrath;
	end

	-- moment_of_glory,if=(buff.avenging_wrath.remains<15|(time>10|(cooldown.avenging_wrath.remains>15))&(cooldown.avengers_shield.remains&cooldown.judgment.remains&cooldown.hammer_of_wrath.remains));
	if talents[PR.MomentOfGlory] and cooldown[PR.MomentOfGlory].ready and (( buff[PR.AvengingWrath].remains < 15 or ( GetTime() > 10 or ( cooldown[PR.AvengingWrath].remains > 15 ) ) and ( cooldown[PR.AvengersShield].remains and cooldown[PR.Judgment].remains and cooldown[PR.HammerOfWrath].remains ) )) then
		return PR.MomentOfGlory;
	end

	-- divine_toll,if=spell_targets.shield_of_the_righteous>=3;
	if talents[PR.DivineToll] and cooldown[PR.DivineToll].ready and mana >= 7500 and (targets >= 3) then
		return PR.DivineToll;
	end

	-- eye_of_tyr,if=talent.inmost_light.enabled&spell_targets.shield_of_the_righteous>=3;
	if talents[PR.EyeOfTyr] and cooldown[PR.EyeOfTyr].ready and (talents[PR.InmostLight] and targets >= 3) then
		return PR.EyeOfTyr;
	end

	-- bastion_of_light,if=buff.avenging_wrath.up;
	if talents[PR.BastionOfLight] and cooldown[PR.BastionOfLight].ready and (buff[PR.AvengingWrath].up) then
		return PR.BastionOfLight;
	end
end

function Paladin:ProtectionStandard()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
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

	-- shield_of_the_righteous,if=((!talent.righteous_protector.enabled|cooldown.righteous_protector_icd.remains=0)&holy_power>2)|buff.bastion_of_light.up|buff.divine_purpose.up;
	if cooldown[PR.ShieldOfTheRighteous].ready and holyPower >= 3 and (( ( not talents[PR.RighteousProtector] or cooldown[PR.RighteousProtectorIcd].remains == 0 ) and holyPower > 2 ) or buff[PR.BastionOfLight].up or buff[PR.DivinePurpose].up) then
		return PR.ShieldOfTheRighteous;
	end

	-- judgment,target_if=min:debuff.judgment.remains,if=spell_targets.shield_of_the_righteous>3&buff.bulwark_of_righteous_fury.stack>=3&holy_power<3;
	if cooldown[PR.Judgment].ready and mana >= 1500 and (targets > 3 and buff[PR.BulwarkOfRighteousFury].count >= 3 and holyPower < 3) then
		return PR.Judgment;
	end

	-- avengers_shield,if=spell_targets.avengers_shield>2;
	if talents[PR.AvengersShield] and cooldown[PR.AvengersShield].ready and (targets > 2) then
		return PR.AvengersShield;
	end

	-- hammer_of_wrath,if=buff.avenging_wrath.up;
	if talents[PR.HammerOfWrath] and cooldown[PR.HammerOfWrath].ready and mana >= 0 and (buff[PR.AvengingWrath].up) then
		return PR.HammerOfWrath;
	end

	-- judgment,target_if=min:debuff.judgment.remains,if=talent.crusaders_judgment.enabled&(charges=2|cooldown.judgment.remains<4)|!talent.crusaders_judgment.enabled;
	if cooldown[PR.Judgment].ready and mana >= 1500 and (talents[PR.CrusadersJudgment] and ( cooldown[PR.Judgment].charges == 2 or cooldown[PR.Judgment].remains < 4 ) or not talents[PR.CrusadersJudgment]) then
		return PR.Judgment;
	end

	-- divine_toll,if=(time>20&(!raid_event.adds.exists|raid_event.adds.in>10))|((buff.avenging_wrath.up|!talent.avenging_wrath.enabled)&(buff.moment_of_glory.up|!talent.moment_of_glory.enabled));
	if talents[PR.DivineToll] and cooldown[PR.DivineToll].ready and mana >= 7500 and (( GetTime() > 20 and ( not targets > 1  ) ) or ( ( buff[PR.AvengingWrath].up or not talents[PR.AvengingWrath] ) and ( buff[PR.MomentOfGlory].up or not talents[PR.MomentOfGlory] ) )) then
		return PR.DivineToll;
	end

	-- avengers_shield;
	if talents[PR.AvengersShield] and cooldown[PR.AvengersShield].ready then
		return PR.AvengersShield;
	end

	-- hammer_of_wrath;
	if talents[PR.HammerOfWrath] and cooldown[PR.HammerOfWrath].ready and mana >= 0 then
		return PR.HammerOfWrath;
	end

	-- judgment,target_if=min:debuff.judgment.remains;
	if cooldown[PR.Judgment].ready and mana >= 1500 then
		return PR.Judgment;
	end

	-- consecration,if=!consecration.up;
	if cooldown[PR.Consecration].ready and (not consecrationUp) then
		return PR.Consecration;
	end

	-- eye_of_tyr,if=talent.inmost_light.enabled&raid_event.adds.in>=45;
	if talents[PR.EyeOfTyr] and cooldown[PR.EyeOfTyr].ready and (talents[PR.InmostLight]) then
		return PR.EyeOfTyr;
	end

	-- blessed_hammer;
	if talents[PR.BlessedHammer] and cooldown[PR.BlessedHammer].ready and mana >= 800 then
		return PR.BlessedHammer;
	end

	-- hammer_of_the_righteous;
	if talents[PR.HammerOfTheRighteous] and cooldown[PR.HammerOfTheRighteous].ready and mana >= 800 then
		return PR.HammerOfTheRighteous;
	end

	-- crusader_strike;
	-- PR.CrusaderStrike;

	-- eye_of_tyr,if=!talent.inmost_light.enabled&raid_event.adds.in>=60;
	if talents[PR.EyeOfTyr] and cooldown[PR.EyeOfTyr].ready and (not talents[PR.InmostLight]) then
		return PR.EyeOfTyr;
	end

	-- word_of_glory,if=buff.shining_light_free.up;
	if holyPower >= 3 and mana >= 0 and (buff[PR.ShiningLightFree].up) then
		return PR.WordOfGlory;
	end

	-- consecration;
	if cooldown[PR.Consecration].ready then
		return PR.Consecration;
	end
end

function Paladin:ProtectionTrinkets()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
end


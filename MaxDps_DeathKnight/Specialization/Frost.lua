local _, addonTable = ...;

-- @type MaxDps;
if not MaxDps then return end;
local DeathKnight = addonTable.DeathKnight;
local MaxDps = MaxDps;

local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;

local itemID = GetInventoryItemID('player', INVSLOT_MAINHAND);

local mainHandSubClassID = itemID and  select(13, GetItemInfo(itemID));

local TwoHanderWepCheck = mainHandSubClassID and (mainHandSubClassID == 1 or mainHandSubClassID == 5 or mainHandSubClassID == 8 or mainHandSubClassID == 10);


local stPlanning
local addsRemain
local rimeBuffs
local rpBuffs
local cooldownCheck
local frostscythePriority
local oblitPoolingTime
local breathPoolingTime
local poolingRunes
local poolingRunicPower

local FR = {
	PillarOfFrost = 51271,
	BreathOfSindragosa = 152279,
	GatheringStorm = 194912,
	Everfrost = 376938,
	ColdHeart = 281208,
	KillingMachine = 51128,
	Razorice = 51714,
	GlacialAdvance = 194913,
	Avalanche = 207142,
	Obliteration = 281238,
	RemorselessWinter = 196770,
	HowlingBlast = 49184,
	Rime = 59057,
	FrostFever = 55095,
	Obliterate = 49020,
	CleavingStrikes = 316916,
	DeathAndDecay = 43265,
	Frostscythe = 207230,
	FrostStrike = 49143,
	HornOfWinter = 57330,
	RageOfTheFrozenChampion = 377076,
	ChainsOfIce = 45524,
	FrostwyrmsFury = 279302,
	UnholyStrength = 53365,
	ChaosBane = 359437,
	EmpowerRuneWeapon = 47568,
	AbominationLimb = 383269,
	ChillStreak = 305392,
	Icecap = 207126,
	AbsoluteZero = 377047,
	RaiseDead = 46585,
	SoulReaper = 343294,
	SacrificialPact = 327574,
	MindFreeze = 47528,
	AntimagicShell = 48707,
	AntimagicZone = 51052,
	Assimilation = 374383,
	Tier302pc = 393623,
	ShatteringBlade = 207057,
	Icebreaker = 392950,
	UnleashedFrenzy = 376905,
	IcyTalons = 194878,
	ImprovedObliterate = 317198,
	FrigidExecutioner = 377073,
	Frostreaper = 317214,
	MightOfTheFrozenWastes = 81333,
};
local A = {
};
function DeathKnight:Frost()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local gcd = fd.gcd;
	local timeToDie = fd.timeToDie;
	local runeforge = fd.runeforge;

	-- call_action_list,name=variables;
	local result = DeathKnight:FrostVariables();
	if result then
		return result;
	end

	-- call_action_list,name=high_prio_actions;
	local result = DeathKnight:FrostHighPrioActions();
	if result then
		return result;
	end

	-- call_action_list,name=trinkets;

	-- call_action_list,name=cooldowns;
	local result = DeathKnight:FrostCooldowns();
	if result then
		return result;
	end

	-- call_action_list,name=racials;

	-- call_action_list,name=cold_heart,if=talent.cold_heart&(!buff.killing_machine.up|talent.breath_of_sindragosa)&((debuff.razorice.stack=5|!death_knight.runeforge.razorice&!talent.glacial_advance&!talent.avalanche)|fight_remains<=gcd);
	if talents[FR.ColdHeart] and ( not buff[FR.KillingMachine].up or talents[FR.BreathOfSindragosa] ) and ( ( debuff[FR.Razorice].count == 5 or not runeforge[FR.Razorice] and not talents[FR.GlacialAdvance] and not talents[FR.Avalanche] ) or timeToDie <= gcd ) then
		local result = DeathKnight:FrostColdHeart();
		if result then
			return result;
		end
	end

	-- run_action_list,name=breath_oblit,if=buff.breath_of_sindragosa.up&talent.obliteration&buff.pillar_of_frost.up;
	if buff[FR.BreathOfSindragosa].up and talents[FR.Obliteration] and buff[FR.PillarOfFrost].up then
		return DeathKnight:FrostBreathOblit();
	end

	-- run_action_list,name=breath,if=buff.breath_of_sindragosa.up&(!talent.obliteration|talent.obliteration&!buff.pillar_of_frost.up);
	if buff[FR.BreathOfSindragosa].up and ( not talents[FR.Obliteration] or talents[FR.Obliteration] and not buff[FR.PillarOfFrost].up ) then
		return DeathKnight:FrostBreath();
	end

	-- run_action_list,name=obliteration,if=talent.obliteration&buff.pillar_of_frost.up&!buff.breath_of_sindragosa.up;
	if talents[FR.Obliteration] and buff[FR.PillarOfFrost].up and not buff[FR.BreathOfSindragosa].up then
		return DeathKnight:FrostObliteration();
	end

	-- call_action_list,name=aoe,if=active_enemies>=2;
	if targets >= 2 then
		local result = DeathKnight:FrostAoe();
		if result then
			return result;
		end
	end

	-- call_action_list,name=single_target,if=active_enemies=1;
	if targets == 1 then
		local result = DeathKnight:FrostSingleTarget();
		if result then
			return result;
		end
	end
end
function DeathKnight:FrostAoe()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local runes = UnitPower('player', Enum.PowerType.Runes);
	local runesduration = select(2,GetRuneCooldown(1));
	local runesRegen = runesduration and math.floor(runesduration*100)/100;
	local runesTimeTo2 = DeathKnight:TimeToRunes(2);
	local runesTimeTo3 = DeathKnight:TimeToRunes(3);
	local runesTimeTo4 = DeathKnight:TimeToRunes(4);
	local runicPower = UnitPower('player', Enum.PowerType.RunicPower);
	local runicPowerMax = UnitPowerMax('player', Enum.PowerType.RunicPower);
	local runicPowerPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local runicPowerRegen = select(2,GetPowerRegen());
	local runicPowerRegenCombined = runicPowerRegen + runicPower;
	local runicPowerDeficit = UnitPowerMax('player', Enum.PowerType.RunicPower) - runicPower;
	local runicPowerTimeToMax = runicPowerMax - runicPower / runicPowerRegen;
	local runeforge = fd.runeforge;

	-- remorseless_winter;
	if cooldown[FR.RemorselessWinter].ready and runes >= 1 and runicPower >= 10 then
		return FR.RemorselessWinter;
	end

	-- howling_blast,if=buff.rime.react|!dot.frost_fever.ticking;
	if talents[FR.HowlingBlast] and runes >= 1 and runicPower >= 10 and (buff[FR.Rime].count or not debuff[FR.FrostFever].up) then
		return FR.HowlingBlast;
	end

	-- glacial_advance,if=!variable.pooling_runic_power&variable.rp_buffs;
	if talents[FR.GlacialAdvance] and runicPower >= 30 and (not poolingRunicPower and rpBuffs) then
		return FR.GlacialAdvance;
	end

	-- obliterate,if=buff.killing_machine.react&talent.cleaving_strikes&death_and_decay.ticking&!variable.frostscythe_priority;
	if talents[FR.Obliterate] and runes >= 2 and (buff[FR.KillingMachine].count and talents[FR.CleavingStrikes] and debuff[FR.DeathAndDecay].up and not frostscythePriority) then
		return FR.Obliterate;
	end

	-- glacial_advance,if=!variable.pooling_runic_power;
	if talents[FR.GlacialAdvance] and runicPower >= 30 and (not poolingRunicPower) then
		return FR.GlacialAdvance;
	end

	-- frostscythe,if=variable.frostscythe_priority;
	if talents[FR.Frostscythe] and runes >= 1 and (frostscythePriority) then
		return FR.Frostscythe;
	end

	-- obliterate,if=!variable.frostscythe_priority;
	if talents[FR.Obliterate] and runes >= 2 and (not frostscythePriority) then
		return FR.Obliterate;
	end

	-- frost_strike,if=!variable.pooling_runic_power&!talent.glacial_advance;
	if talents[FR.FrostStrike] and runicPower >= 30 and (not poolingRunicPower and not talents[FR.GlacialAdvance]) then
		return FR.FrostStrike;
	end

	-- horn_of_winter,if=rune<2&runic_power.deficit>25;
	if talents[FR.HornOfWinter] and cooldown[FR.HornOfWinter].ready and (runes < 2 and runicPowerDeficit > 25) then
		return FR.HornOfWinter;
	end
end

function DeathKnight:FrostBreath()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local runes = UnitPower('player', Enum.PowerType.Runes);
	local runesduration = select(2,GetRuneCooldown(1));
	local runesRegen = runesduration and math.floor(runesduration*100)/100;
	local runesTimeTo2 = DeathKnight:TimeToRunes(2);
	local runesTimeTo3 = DeathKnight:TimeToRunes(3);
	local runesTimeTo4 = DeathKnight:TimeToRunes(4);
	local runicPower = UnitPower('player', Enum.PowerType.RunicPower);
	local runicPowerMax = UnitPowerMax('player', Enum.PowerType.RunicPower);
	local runicPowerPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local runicPowerRegen = select(2,GetPowerRegen());
	local runicPowerRegenCombined = runicPowerRegen + runicPower;
	local runicPowerDeficit = UnitPowerMax('player', Enum.PowerType.RunicPower) - runicPower;
	local runicPowerTimeToMax = runicPowerMax - runicPower / runicPowerRegen;
	local runeforge = fd.runeforge;

	-- remorseless_winter,if=variable.rw_buffs|variable.adds_remain;
	if cooldown[FR.RemorselessWinter].ready and runes >= 1 and runicPower >= 10 and (rwBuffs or addsRemain) then
		return FR.RemorselessWinter;
	end

	-- howling_blast,if=variable.rime_buffs&runic_power>(45-talent.rage_of_the_frozen_champion*8);
	if talents[FR.HowlingBlast] and runes >= 1 and runicPower >= 10 and (rimeBuffs and runicPower > ( 45 - (talents[FR.RageOfTheFrozenChampion] and 1 or 0) * 8 )) then
		return FR.HowlingBlast;
	end

	-- horn_of_winter,if=rune<2&runic_power.deficit>25;
	if talents[FR.HornOfWinter] and cooldown[FR.HornOfWinter].ready and (runes < 2 and runicPowerDeficit > 25) then
		return FR.HornOfWinter;
	end

	-- obliterate,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice,if=buff.killing_machine.react&!variable.frostscythe_priority;
	if talents[FR.Obliterate] and runes >= 2 and (buff[FR.KillingMachine].count and not frostscythePriority) then
		return FR.Obliterate;
	end

	-- frostscythe,if=buff.killing_machine.react&variable.frostscythe_priority;
	if talents[FR.Frostscythe] and runes >= 1 and (buff[FR.KillingMachine].count and frostscythePriority) then
		return FR.Frostscythe;
	end

	-- frostscythe,if=variable.frostscythe_priority&runic_power>45;
	if talents[FR.Frostscythe] and runes >= 1 and (frostscythePriority and runicPower > 45) then
		return FR.Frostscythe;
	end

	-- obliterate,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice,if=runic_power.deficit>40|buff.pillar_of_frost.up&runic_power.deficit>17;
	if talents[FR.Obliterate] and runes >= 2 and (runicPowerDeficit > 40 or buff[FR.PillarOfFrost].up and runicPowerDeficit > 17) then
		return FR.Obliterate;
	end

	-- death_and_decay,if=runic_power<36&rune.time_to_2>runic_power%18;
	if cooldown[FR.DeathAndDecay].ready and runes >= 1 and runicPower >= 10 and (runicPower < 36 and runesTimeTo2 > runicPower / 18) then
		return FR.DeathAndDecay;
	end

	-- remorseless_winter,if=runic_power<36&rune.time_to_2>runic_power%18;
	if cooldown[FR.RemorselessWinter].ready and runes >= 1 and runicPower >= 10 and (runicPower < 36 and runesTimeTo2 > runicPower / 18) then
		return FR.RemorselessWinter;
	end

	-- howling_blast,if=runic_power<36&rune.time_to_2>runic_power%18;
	if talents[FR.HowlingBlast] and runes >= 1 and runicPower >= 10 and (runicPower < 36 and runesTimeTo2 > runicPower / 18) then
		return FR.HowlingBlast;
	end

	-- obliterate,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice,if=runic_power.deficit>25;
	if talents[FR.Obliterate] and runes >= 2 and (runicPowerDeficit > 25) then
		return FR.Obliterate;
	end

	-- howling_blast,if=buff.rime.react;
	if talents[FR.HowlingBlast] and runes >= 1 and runicPower >= 10 and (buff[FR.Rime].count) then
		return FR.HowlingBlast;
	end
end

function DeathKnight:FrostBreathOblit()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local runes = UnitPower('player', Enum.PowerType.Runes);
	local runesduration = select(2,GetRuneCooldown(1));
	local runesRegen = runesduration and math.floor(runesduration*100)/100;
	local runesTimeTo2 = DeathKnight:TimeToRunes(2);
	local runesTimeTo3 = DeathKnight:TimeToRunes(3);
	local runesTimeTo4 = DeathKnight:TimeToRunes(4);
	local runicPower = UnitPower('player', Enum.PowerType.RunicPower);
	local runicPowerMax = UnitPowerMax('player', Enum.PowerType.RunicPower);
	local runicPowerPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local runicPowerRegen = select(2,GetPowerRegen());
	local runicPowerRegenCombined = runicPowerRegen + runicPower;
	local runicPowerDeficit = UnitPowerMax('player', Enum.PowerType.RunicPower) - runicPower;
	local runicPowerTimeToMax = runicPowerMax - runicPower / runicPowerRegen;
	local runeforge = fd.runeforge;

	-- frostscythe,if=buff.killing_machine.up&variable.frostscythe_priority;
	if talents[FR.Frostscythe] and runes >= 1 and (buff[FR.KillingMachine].up and frostscythePriority) then
		return FR.Frostscythe;
	end

	-- obliterate,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice,if=buff.killing_machine.up;
	if talents[FR.Obliterate] and runes >= 2 and (buff[FR.KillingMachine].up) then
		return FR.Obliterate;
	end

	-- howling_blast,if=buff.rime.react;
	if talents[FR.HowlingBlast] and runes >= 1 and runicPower >= 10 and (buff[FR.Rime].count) then
		return FR.HowlingBlast;
	end

	-- howling_blast,if=!buff.killing_machine.up;
	if talents[FR.HowlingBlast] and runes >= 1 and runicPower >= 10 and (not buff[FR.KillingMachine].up) then
		return FR.HowlingBlast;
	end

	-- horn_of_winter,if=runic_power.deficit>25;
	if talents[FR.HornOfWinter] and cooldown[FR.HornOfWinter].ready and (runicPowerDeficit > 25) then
		return FR.HornOfWinter;
	end
end

function DeathKnight:FrostColdHeart()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local gcd = fd.gcd;
	local timeToDie = fd.timeToDie;
	local runes = UnitPower('player', Enum.PowerType.Runes);
	local runesduration = select(2,GetRuneCooldown(1));
	local runesRegen = runesduration and math.floor(runesduration*100)/100;
	local runesTimeTo2 = DeathKnight:TimeToRunes(2);
	local runesTimeTo3 = DeathKnight:TimeToRunes(3);
	local runesTimeTo4 = DeathKnight:TimeToRunes(4);
	local runicPower = UnitPower('player', Enum.PowerType.RunicPower);
	local runicPowerMax = UnitPowerMax('player', Enum.PowerType.RunicPower);
	local runicPowerPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local runicPowerRegen = select(2,GetPowerRegen());
	local runicPowerRegenCombined = runicPowerRegen + runicPower;
	local runicPowerDeficit = UnitPowerMax('player', Enum.PowerType.RunicPower) - runicPower;
	local runicPowerTimeToMax = runicPowerMax - runicPower / runicPowerRegen;
	local runeforge = fd.runeforge;

	-- chains_of_ice,if=fight_remains<gcd&(rune<2|!buff.killing_machine.up&(!variable.2h_check&buff.cold_heart.stack>=4|variable.2h_check&buff.cold_heart.stack>8)|buff.killing_machine.up&(!variable.2h_check&buff.cold_heart.stack>8|variable.2h_check&buff.cold_heart.stack>10));
	if talents[FR.ChainsOfIce] and runes >= 1 and runicPower >= 10 and (timeToDie < gcd and ( runes < 2 or not buff[FR.KillingMachine].up and ( not TwoHanderWepCheck and buff[FR.ColdHeart].count >= 4 or TwoHanderWepCheck and buff[FR.ColdHeart].count > 8 ) or buff[FR.KillingMachine].up and ( not TwoHanderWepCheck and buff[FR.ColdHeart].count > 8 or TwoHanderWepCheck and buff[FR.ColdHeart].count > 10 ) )) then
		return FR.ChainsOfIce;
	end

	-- chains_of_ice,if=!talent.obliteration&buff.pillar_of_frost.up&buff.cold_heart.stack>=10&(buff.pillar_of_frost.remains<gcd*(1+(talent.frostwyrms_fury&cooldown.frostwyrms_fury.ready))|buff.unholy_strength.up&buff.unholy_strength.remains<gcd);
	if talents[FR.ChainsOfIce] and runes >= 1 and runicPower >= 10 and (not talents[FR.Obliteration] and buff[FR.PillarOfFrost].up and buff[FR.ColdHeart].count >= 10 and ( buff[FR.PillarOfFrost].remains < gcd * ( 1 + ( talents[FR.FrostwyrmsFury] and cooldown[FR.FrostwyrmsFury].ready ) ) or buff[FR.UnholyStrength].up and buff[FR.UnholyStrength].remains < gcd )) then
		return FR.ChainsOfIce;
	end

	-- chains_of_ice,if=!talent.obliteration&death_knight.runeforge.fallen_crusader&!buff.pillar_of_frost.up&cooldown.pillar_of_frost.remains_expected>15&(buff.cold_heart.stack>=10&buff.unholy_strength.up|buff.cold_heart.stack>=13);
	if talents[FR.ChainsOfIce] and runes >= 1 and runicPower >= 10 and (not talents[FR.Obliteration] and runeforge[FR.FallenCrusader] and not buff[FR.PillarOfFrost].up and cooldown[FR.PillarOfFrost].remains > 15 and ( buff[FR.ColdHeart].count >= 10 and buff[FR.UnholyStrength].up or buff[FR.ColdHeart].count >= 13 )) then
		return FR.ChainsOfIce;
	end

	-- chains_of_ice,if=!talent.obliteration&!death_knight.runeforge.fallen_crusader&buff.cold_heart.stack>=10&!buff.pillar_of_frost.up&cooldown.pillar_of_frost.remains_expected>20;
	if talents[FR.ChainsOfIce] and runes >= 1 and runicPower >= 10 and (not talents[FR.Obliteration] and not runeforge[FR.FallenCrusader] and buff[FR.ColdHeart].count >= 10 and not buff[FR.PillarOfFrost].up and cooldown[FR.PillarOfFrost].remains > 20) then
		return FR.ChainsOfIce;
	end

	-- chains_of_ice,if=talent.obliteration&!buff.pillar_of_frost.up&(buff.cold_heart.stack>=14&(buff.unholy_strength.up|buff.chaos_bane.up)|buff.cold_heart.stack>=19|cooldown.pillar_of_frost.remains_expected<3&buff.cold_heart.stack>=14);
	if talents[FR.ChainsOfIce] and runes >= 1 and runicPower >= 10 and (talents[FR.Obliteration] and not buff[FR.PillarOfFrost].up and ( buff[FR.ColdHeart].count >= 14 and ( buff[FR.UnholyStrength].up or buff[FR.ChaosBane].up ) or buff[FR.ColdHeart].count >= 19 or cooldown[FR.PillarOfFrost].remains < 3 and buff[FR.ColdHeart].count >= 14 )) then
		return FR.ChainsOfIce;
	end
end

function DeathKnight:FrostCooldowns()
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
	local runes = UnitPower('player', Enum.PowerType.Runes);
	local runesduration = select(2,GetRuneCooldown(1));
	local runesRegen = runesduration and math.floor(runesduration*100)/100;
	local runesTimeTo2 = DeathKnight:TimeToRunes(2);
	local runesTimeTo3 = DeathKnight:TimeToRunes(3);
	local runesTimeTo4 = DeathKnight:TimeToRunes(4);
	local runicPower = UnitPower('player', Enum.PowerType.RunicPower);
	local runicPowerMax = UnitPowerMax('player', Enum.PowerType.RunicPower);
	local runicPowerPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local runicPowerRegen = select(2,GetPowerRegen());
	local runicPowerRegenCombined = runicPowerRegen + runicPower;
	local runicPowerDeficit = UnitPowerMax('player', Enum.PowerType.RunicPower) - runicPower;
	local runicPowerTimeToMax = runicPowerMax - runicPower / runicPowerRegen;
	local runeforge = fd.runeforge;

	-- empower_rune_weapon,if=talent.obliteration&!buff.empower_rune_weapon.up&rune<6&(cooldown.pillar_of_frost.remains_expected<7&(variable.adds_remain|variable.st_planning)|buff.pillar_of_frost.up)|fight_remains<20;
	if talents[FR.EmpowerRuneWeapon] and cooldown[FR.EmpowerRuneWeapon].ready and (talents[FR.Obliteration] and not buff[FR.EmpowerRuneWeapon].up and runes < 6 and ( cooldown[FR.PillarOfFrost].remains < 7 and ( addsRemain or stPlanning ) or buff[FR.PillarOfFrost].up ) or timeToDie < 20) then
		return FR.EmpowerRuneWeapon;
	end

	-- empower_rune_weapon,use_off_gcd=1,if=buff.breath_of_sindragosa.up&talent.breath_of_sindragosa&!buff.empower_rune_weapon.up&(runic_power<70&rune<3|time<10);
	if talents[FR.EmpowerRuneWeapon] and cooldown[FR.EmpowerRuneWeapon].ready and (buff[FR.BreathOfSindragosa].up and talents[FR.BreathOfSindragosa] and not buff[FR.EmpowerRuneWeapon].up and ( runicPower < 70 and runes < 3 or GetTime() < 10 )) then
		return FR.EmpowerRuneWeapon;
	end

	-- empower_rune_weapon,use_off_gcd=1,if=!talent.breath_of_sindragosa&!talent.obliteration&!buff.empower_rune_weapon.up&rune<5&(cooldown.pillar_of_frost.remains_expected<7|buff.pillar_of_frost.up|!talent.pillar_of_frost);
	if talents[FR.EmpowerRuneWeapon] and cooldown[FR.EmpowerRuneWeapon].ready and (not talents[FR.BreathOfSindragosa] and not talents[FR.Obliteration] and not buff[FR.EmpowerRuneWeapon].up and runes < 5 and ( cooldown[FR.PillarOfFrost].remains < 7 or buff[FR.PillarOfFrost].up or not talents[FR.PillarOfFrost] )) then
		return FR.EmpowerRuneWeapon;
	end

	-- abomination_limb,if=talent.obliteration&!buff.pillar_of_frost.up&cooldown.pillar_of_frost.remains<3&(variable.adds_remain|variable.st_planning)|fight_remains<12;
	if talents[FR.AbominationLimb] and cooldown[FR.AbominationLimb].ready and (talents[FR.Obliteration] and not buff[FR.PillarOfFrost].up and cooldown[FR.PillarOfFrost].remains < 3 and ( addsRemain or stPlanning ) or timeToDie < 12) then
		return FR.AbominationLimb;
	end

	-- abomination_limb,if=talent.breath_of_sindragosa&(variable.adds_remain|variable.st_planning);
	if talents[FR.AbominationLimb] and cooldown[FR.AbominationLimb].ready and (talents[FR.BreathOfSindragosa] and ( addsRemain or stPlanning )) then
		return FR.AbominationLimb;
	end

	-- abomination_limb,if=!talent.breath_of_sindragosa&!talent.obliteration&(variable.adds_remain|variable.st_planning);
	if talents[FR.AbominationLimb] and cooldown[FR.AbominationLimb].ready and (not talents[FR.BreathOfSindragosa] and not talents[FR.Obliteration] and ( addsRemain or stPlanning )) then
		return FR.AbominationLimb;
	end

	-- chill_streak,if=active_enemies>=2&(!death_and_decay.ticking&talent.cleaving_strikes|!talent.cleaving_strikes|active_enemies<=5);
	if talents[FR.ChillStreak] and cooldown[FR.ChillStreak].ready and runes >= 1 and runicPower >= 10 and (targets >= 2 and ( not debuff[FR.DeathAndDecay].up and talents[FR.CleavingStrikes] or not talents[FR.CleavingStrikes] or targets <= 5 )) then
		return FR.ChillStreak;
	end

	-- pillar_of_frost,if=talent.obliteration&(variable.adds_remain|variable.st_planning)&(buff.empower_rune_weapon.up|cooldown.empower_rune_weapon.remains)|fight_remains<12;
	if talents[FR.PillarOfFrost] and cooldown[FR.PillarOfFrost].ready and (talents[FR.Obliteration] and ( addsRemain or stPlanning ) and ( buff[FR.EmpowerRuneWeapon].up or cooldown[FR.EmpowerRuneWeapon].remains ) or timeToDie < 12) then
		return FR.PillarOfFrost;
	end

	-- pillar_of_frost,if=talent.breath_of_sindragosa&(variable.adds_remain|variable.st_planning)&(!talent.icecap&(runic_power>70|cooldown.breath_of_sindragosa.remains>40)|talent.icecap&(cooldown.breath_of_sindragosa.remains>10|buff.breath_of_sindragosa.up));
	if talents[FR.PillarOfFrost] and cooldown[FR.PillarOfFrost].ready and (talents[FR.BreathOfSindragosa] and ( addsRemain or stPlanning ) and ( not talents[FR.Icecap] and ( runicPower > 70 or cooldown[FR.BreathOfSindragosa].remains > 40 ) or talents[FR.Icecap] and ( cooldown[FR.BreathOfSindragosa].remains > 10 or buff[FR.BreathOfSindragosa].up ) )) then
		return FR.PillarOfFrost;
	end

	-- pillar_of_frost,if=talent.icecap&!talent.obliteration&!talent.breath_of_sindragosa&(variable.adds_remain|variable.st_planning);
	if talents[FR.PillarOfFrost] and cooldown[FR.PillarOfFrost].ready and (talents[FR.Icecap] and not talents[FR.Obliteration] and not talents[FR.BreathOfSindragosa] and ( addsRemain or stPlanning )) then
		return FR.PillarOfFrost;
	end

	-- breath_of_sindragosa,if=!buff.breath_of_sindragosa.up&runic_power>60&(variable.adds_remain|variable.st_planning)|fight_remains<30;
	if talents[FR.BreathOfSindragosa] and cooldown[FR.BreathOfSindragosa].ready and runicPower >= 0 and (not buff[FR.BreathOfSindragosa].up and runicPower > 60 and ( addsRemain or stPlanning ) or timeToDie < 30) then
		return FR.BreathOfSindragosa;
	end

	-- frostwyrms_fury,if=active_enemies=1&(talent.pillar_of_frost&buff.pillar_of_frost.remains<gcd*2&buff.pillar_of_frost.up&!talent.obliteration|!talent.pillar_of_frost)&(!raid_event.adds.exists|(raid_event.adds.in>15+raid_event.adds.duration|talent.absolute_zero&raid_event.adds.in>15+raid_event.adds.duration))|fight_remains<3;
	if talents[FR.FrostwyrmsFury] and cooldown[FR.FrostwyrmsFury].ready and (targets == 1 and ( talents[FR.PillarOfFrost] and buff[FR.PillarOfFrost].remains < gcd * 2 and buff[FR.PillarOfFrost].up and not talents[FR.Obliteration] or not talents[FR.PillarOfFrost] ) and ( not targets > 1  ) or timeToDie < 3) then
		return FR.FrostwyrmsFury;
	end

	-- frostwyrms_fury,if=active_enemies>=2&(talent.pillar_of_frost&buff.pillar_of_frost.up|raid_event.adds.exists&raid_event.adds.up&raid_event.adds.in>cooldown.pillar_of_frost.remains_expected-raid_event.adds.in-raid_event.adds.duration)&(buff.pillar_of_frost.remains<gcd*2|raid_event.adds.exists&raid_event.adds.remains<gcd*2);
	if talents[FR.FrostwyrmsFury] and cooldown[FR.FrostwyrmsFury].ready and (targets >= 2 and ( talents[FR.PillarOfFrost] and buff[FR.PillarOfFrost].up or targets > 1 ) and ( buff[FR.PillarOfFrost].remains < gcd * 2 or targets > 1 )) then
		return FR.FrostwyrmsFury;
	end

	-- frostwyrms_fury,if=talent.obliteration&(talent.pillar_of_frost&buff.pillar_of_frost.up&!variable.2h_check|!buff.pillar_of_frost.up&variable.2h_check&cooldown.pillar_of_frost.remains|!talent.pillar_of_frost)&((buff.pillar_of_frost.remains<gcd|buff.unholy_strength.up&buff.unholy_strength.remains<gcd)&(debuff.razorice.stack=5|!death_knight.runeforge.razorice&!talent.glacial_advance));
	if talents[FR.FrostwyrmsFury] and cooldown[FR.FrostwyrmsFury].ready and (talents[FR.Obliteration] and ( talents[FR.PillarOfFrost] and buff[FR.PillarOfFrost].up and not TwoHanderWepCheck or not buff[FR.PillarOfFrost].up and TwoHanderWepCheck and cooldown[FR.PillarOfFrost].remains or not talents[FR.PillarOfFrost] ) and ( ( buff[FR.PillarOfFrost].remains < gcd or buff[FR.UnholyStrength].up and buff[FR.UnholyStrength].remains < gcd ) and ( debuff[FR.Razorice].count == 5 or not runeforge[FR.Razorice] and not talents[FR.GlacialAdvance] ) )) then
		return FR.FrostwyrmsFury;
	end

	-- raise_dead;
	if talents[FR.RaiseDead] and cooldown[FR.RaiseDead].ready then
		return FR.RaiseDead;
	end

	-- soul_reaper,if=fight_remains>5&target.time_to_pct_35<5&active_enemies<=2&(talent.obliteration&(buff.pillar_of_frost.up&!buff.killing_machine.react|!buff.pillar_of_frost.up)|talent.breath_of_sindragosa&(buff.breath_of_sindragosa.up&runic_power>40|!buff.breath_of_sindragosa.up)|!talent.breath_of_sindragosa&!talent.obliteration);
	if talents[FR.SoulReaper] and cooldown[FR.SoulReaper].ready and runes >= 1 and runicPower >= 10 and (timeToDie > 5 and timeTo35 < 5 and targets <= 2 and ( talents[FR.Obliteration] and ( buff[FR.PillarOfFrost].up and not buff[FR.KillingMachine].count or not buff[FR.PillarOfFrost].up ) or talents[FR.BreathOfSindragosa] and ( buff[FR.BreathOfSindragosa].up and runicPower > 40 or not buff[FR.BreathOfSindragosa].up ) or not talents[FR.BreathOfSindragosa] and not talents[FR.Obliteration] )) then
		return FR.SoulReaper;
	end

	-- sacrificial_pact,if=!talent.glacial_advance&!buff.breath_of_sindragosa.up&pet.ghoul.remains<gcd*2&active_enemies>3;
	if talents[FR.SacrificialPact] and cooldown[FR.SacrificialPact].ready and runicPower >= 20 and (not talents[FR.GlacialAdvance] and not buff[FR.BreathOfSindragosa].up and ghoulRemains < gcd * 2 and targets > 3) then
		return FR.SacrificialPact;
	end

	-- any_dnd,if=!death_and_decay.ticking&variable.adds_remain&(buff.pillar_of_frost.up&buff.pillar_of_frost.remains>5&buff.pillar_of_frost.remains<11|!buff.pillar_of_frost.up&cooldown.pillar_of_frost.remains>10|fight_remains<11)&(active_enemies>5|talent.cleaving_strikes&active_enemies>=2);
	if not debuff[FR.DeathAndDecay].up and addsRemain and ( buff[FR.PillarOfFrost].up and buff[FR.PillarOfFrost].remains > 5 and buff[FR.PillarOfFrost].remains < 11 or not buff[FR.PillarOfFrost].up and cooldown[FR.PillarOfFrost].remains > 10 or timeToDie < 11 ) and ( targets > 5 or talents[FR.CleavingStrikes] and targets >= 2 ) then
		return FR.AnyDnd;
	end
end

function DeathKnight:FrostHighPrioActions()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local runicPower = UnitPower('player', Enum.PowerType.RunicPower);
	local runicPowerMax = UnitPowerMax('player', Enum.PowerType.RunicPower);
	local runicPowerPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local runicPowerRegen = select(2,GetPowerRegen());
	local runicPowerRegenCombined = runicPowerRegen + runicPower;
	local runicPowerDeficit = UnitPowerMax('player', Enum.PowerType.RunicPower) - runicPower;
	local runicPowerTimeToMax = runicPowerMax - runicPower / runicPowerRegen;
	local runes = UnitPower('player', Enum.PowerType.Runes);
	local runesduration = select(2,GetRuneCooldown(1));
	local runesRegen = runesduration and math.floor(runesduration*100)/100;
	local runesTimeTo2 = DeathKnight:TimeToRunes(2);
	local runesTimeTo3 = DeathKnight:TimeToRunes(3);
	local runesTimeTo4 = DeathKnight:TimeToRunes(4);
	local runeforge = fd.runeforge;

	-- antimagic_shell,if=runic_power.deficit>40;
	if talents[FR.AntimagicShell] and cooldown[FR.AntimagicShell].ready and (runicPowerDeficit > 40) then
		return FR.AntimagicShell;
	end

	-- antimagic_zone,if=death_knight.amz_absorb_percent>0&runic_power.deficit>70&talent.assimilation&(buff.breath_of_sindragosa.up&cooldown.empower_rune_weapon.charges<2|!talent.breath_of_sindragosa&!buff.pillar_of_frost.up);
	if talents[FR.AntimagicZone] and cooldown[FR.AntimagicZone].ready and (amzAbsorbPercent > 0 and runicPowerDeficit > 70 and talents[FR.Assimilation] and ( buff[FR.BreathOfSindragosa].up and cooldown[FR.EmpowerRuneWeapon].charges < 2 or not talents[FR.BreathOfSindragosa] and not buff[FR.PillarOfFrost].up )) then
		return FR.AntimagicZone;
	end

	-- howling_blast,if=!dot.frost_fever.ticking&active_enemies>=2&(!talent.obliteration|talent.obliteration&(!cooldown.pillar_of_frost.ready|buff.pillar_of_frost.up&!buff.killing_machine.react));
	if talents[FR.HowlingBlast] and runes >= 1 and runicPower >= 10 and (not debuff[FR.FrostFever].up and targets >= 2 and ( not talents[FR.Obliteration] or talents[FR.Obliteration] and ( not cooldown[FR.PillarOfFrost].ready or buff[FR.PillarOfFrost].up and not buff[FR.KillingMachine].count ) )) then
		return FR.HowlingBlast;
	end

	-- glacial_advance,if=active_enemies>=2&variable.rp_buffs&talent.obliteration&talent.breath_of_sindragosa&!buff.pillar_of_frost.up&!buff.breath_of_sindragosa.up&cooldown.breath_of_sindragosa.remains>variable.breath_pooling_time;
	if talents[FR.GlacialAdvance] and runicPower >= 30 and (targets >= 2 and rpBuffs and talents[FR.Obliteration] and talents[FR.BreathOfSindragosa] and not buff[FR.PillarOfFrost].up and not buff[FR.BreathOfSindragosa].up and cooldown[FR.BreathOfSindragosa].remains > breathPoolingTime) then
		return FR.GlacialAdvance;
	end

	-- glacial_advance,if=active_enemies>=2&variable.rp_buffs&talent.breath_of_sindragosa&!buff.breath_of_sindragosa.up&cooldown.breath_of_sindragosa.remains>variable.breath_pooling_time;
	if talents[FR.GlacialAdvance] and runicPower >= 30 and (targets >= 2 and rpBuffs and talents[FR.BreathOfSindragosa] and not buff[FR.BreathOfSindragosa].up and cooldown[FR.BreathOfSindragosa].remains > breathPoolingTime) then
		return FR.GlacialAdvance;
	end

	-- glacial_advance,if=active_enemies>=2&variable.rp_buffs&!talent.breath_of_sindragosa&talent.obliteration&!buff.pillar_of_frost.up;
	if talents[FR.GlacialAdvance] and runicPower >= 30 and (targets >= 2 and rpBuffs and not talents[FR.BreathOfSindragosa] and talents[FR.Obliteration] and not buff[FR.PillarOfFrost].up) then
		return FR.GlacialAdvance;
	end

	-- frost_strike,if=active_enemies=1&variable.rp_buffs&talent.obliteration&talent.breath_of_sindragosa&!buff.pillar_of_frost.up&!buff.breath_of_sindragosa.up&cooldown.breath_of_sindragosa.remains>variable.breath_pooling_time;
	if talents[FR.FrostStrike] and runicPower >= 30 and (targets == 1 and rpBuffs and talents[FR.Obliteration] and talents[FR.BreathOfSindragosa] and not buff[FR.PillarOfFrost].up and not buff[FR.BreathOfSindragosa].up and cooldown[FR.BreathOfSindragosa].remains > breathPoolingTime) then
		return FR.FrostStrike;
	end

	-- frost_strike,if=active_enemies=1&variable.rp_buffs&talent.breath_of_sindragosa&!buff.breath_of_sindragosa.up&cooldown.breath_of_sindragosa.remains>variable.breath_pooling_time;
	if talents[FR.FrostStrike] and runicPower >= 30 and (targets == 1 and rpBuffs and talents[FR.BreathOfSindragosa] and not buff[FR.BreathOfSindragosa].up and cooldown[FR.BreathOfSindragosa].remains > breathPoolingTime) then
		return FR.FrostStrike;
	end

	-- frost_strike,if=active_enemies=1&variable.rp_buffs&!talent.breath_of_sindragosa&talent.obliteration&!buff.pillar_of_frost.up;
	if talents[FR.FrostStrike] and runicPower >= 30 and (targets == 1 and rpBuffs and not talents[FR.BreathOfSindragosa] and talents[FR.Obliteration] and not buff[FR.PillarOfFrost].up) then
		return FR.FrostStrike;
	end

	-- remorseless_winter,if=!talent.breath_of_sindragosa&!talent.obliteration&variable.rw_buffs;
	if cooldown[FR.RemorselessWinter].ready and runes >= 1 and runicPower >= 10 and (not talents[FR.BreathOfSindragosa] and not talents[FR.Obliteration] and rwBuffs) then
		return FR.RemorselessWinter;
	end

	-- remorseless_winter,if=talent.obliteration&active_enemies>=3&variable.adds_remain;
	if cooldown[FR.RemorselessWinter].ready and runes >= 1 and runicPower >= 10 and (talents[FR.Obliteration] and targets >= 3 and addsRemain) then
		return FR.RemorselessWinter;
	end
end

function DeathKnight:FrostObliteration()
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
	local runes = UnitPower('player', Enum.PowerType.Runes);
	local runesduration = select(2,GetRuneCooldown(1));
	local runesRegen = runesduration and math.floor(runesduration*100)/100;
	local runesTimeTo2 = DeathKnight:TimeToRunes(2);
	local runesTimeTo3 = DeathKnight:TimeToRunes(3);
	local runesTimeTo4 = DeathKnight:TimeToRunes(4);
	local runicPower = UnitPower('player', Enum.PowerType.RunicPower);
	local runicPowerMax = UnitPowerMax('player', Enum.PowerType.RunicPower);
	local runicPowerPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local runicPowerRegen = select(2,GetPowerRegen());
	local runicPowerRegenCombined = runicPowerRegen + runicPower;
	local runicPowerDeficit = UnitPowerMax('player', Enum.PowerType.RunicPower) - runicPower;
	local runicPowerTimeToMax = runicPowerMax - runicPower / runicPowerRegen;
	local runeforge = fd.runeforge;

	-- remorseless_winter,if=active_enemies>3;
	if cooldown[FR.RemorselessWinter].ready and runes >= 1 and runicPower >= 10 and (targets > 3) then
		return FR.RemorselessWinter;
	end

	-- howling_blast,if=buff.killing_machine.stack<2&buff.pillar_of_frost.remains<gcd&buff.rime.react;
	if talents[FR.HowlingBlast] and runes >= 1 and runicPower >= 10 and (buff[FR.KillingMachine].count < 2 and buff[FR.PillarOfFrost].remains < gcd and buff[FR.Rime].count) then
		return FR.HowlingBlast;
	end

	-- frost_strike,if=buff.killing_machine.stack<2&buff.pillar_of_frost.remains<gcd&!death_and_decay.ticking;
	if talents[FR.FrostStrike] and runicPower >= 30 and (buff[FR.KillingMachine].count < 2 and buff[FR.PillarOfFrost].remains < gcd and not debuff[FR.DeathAndDecay].up) then
		return FR.FrostStrike;
	end

	-- glacial_advance,if=buff.killing_machine.stack<2&buff.pillar_of_frost.remains<gcd&!death_and_decay.ticking;
	if talents[FR.GlacialAdvance] and runicPower >= 30 and (buff[FR.KillingMachine].count < 2 and buff[FR.PillarOfFrost].remains < gcd and not debuff[FR.DeathAndDecay].up) then
		return FR.GlacialAdvance;
	end

	-- obliterate,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice,if=buff.killing_machine.react&!variable.frostscythe_priority;
	if talents[FR.Obliterate] and runes >= 2 and (buff[FR.KillingMachine].count and not frostscythePriority) then
		return FR.Obliterate;
	end

	-- frostscythe,if=buff.killing_machine.react&variable.frostscythe_priority;
	if talents[FR.Frostscythe] and runes >= 1 and (buff[FR.KillingMachine].count and frostscythePriority) then
		return FR.Frostscythe;
	end

	-- howling_blast,if=!buff.killing_machine.react&(!dot.frost_fever.ticking|buff.rime.react&set_bonus.tier30_2pc&!variable.rp_buffs);
	if talents[FR.HowlingBlast] and runes >= 1 and runicPower >= 10 and (not buff[FR.KillingMachine].count and ( not debuff[FR.FrostFever].up or buff[FR.Rime].count and MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2) and not rpBuffs )) then
		return FR.HowlingBlast;
	end

	-- glacial_advance,if=!buff.killing_machine.react&(!death_knight.runeforge.razorice&(!talent.avalanche|debuff.razorice.stack<5|debuff.razorice.remains<gcd*3)|(variable.rp_buffs&active_enemies>1));
	if talents[FR.GlacialAdvance] and runicPower >= 30 and (not buff[FR.KillingMachine].count and ( not runeforge[FR.Razorice] and ( not talents[FR.Avalanche] or debuff[FR.Razorice].count < 5 or debuff[FR.Razorice].remains < gcd * 3 ) or ( rpBuffs and targets > 1 ) )) then
		return FR.GlacialAdvance;
	end

	-- frost_strike,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice,if=!buff.killing_machine.react&(rune<2|variable.rp_buffs|debuff.razorice.stack=5&talent.shattering_blade)&!variable.pooling_runic_power&(!talent.glacial_advance|active_enemies=1);
	if talents[FR.FrostStrike] and runicPower >= 30 and (not buff[FR.KillingMachine].count and ( runes < 2 or rpBuffs or debuff[FR.Razorice].count == 5 and talents[FR.ShatteringBlade] ) and not poolingRunicPower and ( not talents[FR.GlacialAdvance] or targets == 1 )) then
		return FR.FrostStrike;
	end

	-- howling_blast,if=buff.rime.react&!buff.killing_machine.react;
	if talents[FR.HowlingBlast] and runes >= 1 and runicPower >= 10 and (buff[FR.Rime].count and not buff[FR.KillingMachine].count) then
		return FR.HowlingBlast;
	end

	-- glacial_advance,if=!variable.pooling_runic_power&variable.rp_buffs&!buff.killing_machine.react&active_enemies>=2;
	if talents[FR.GlacialAdvance] and runicPower >= 30 and (not poolingRunicPower and rpBuffs and not buff[FR.KillingMachine].count and targets >= 2) then
		return FR.GlacialAdvance;
	end

	-- frost_strike,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice,if=!buff.killing_machine.react&!variable.pooling_runic_power&(!talent.glacial_advance|active_enemies=1);
	if talents[FR.FrostStrike] and runicPower >= 30 and (not buff[FR.KillingMachine].count and not poolingRunicPower and ( not talents[FR.GlacialAdvance] or targets == 1 )) then
		return FR.FrostStrike;
	end

	-- howling_blast,if=!buff.killing_machine.react&runic_power<25;
	if talents[FR.HowlingBlast] and runes >= 1 and runicPower >= 10 and (not buff[FR.KillingMachine].count and runicPower < 25) then
		return FR.HowlingBlast;
	end

	-- glacial_advance,if=!variable.pooling_runic_power&active_enemies>=2;
	if talents[FR.GlacialAdvance] and runicPower >= 30 and (not poolingRunicPower and targets >= 2) then
		return FR.GlacialAdvance;
	end

	-- frost_strike,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice,if=!variable.pooling_runic_power&(!talent.glacial_advance|active_enemies=1);
	if talents[FR.FrostStrike] and runicPower >= 30 and (not poolingRunicPower and ( not talents[FR.GlacialAdvance] or targets == 1 )) then
		return FR.FrostStrike;
	end

	-- howling_blast,if=buff.rime.react;
	if talents[FR.HowlingBlast] and runes >= 1 and runicPower >= 10 and (buff[FR.Rime].count) then
		return FR.HowlingBlast;
	end

	-- obliterate,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice;
	if talents[FR.Obliterate] and runes >= 2 then
		return FR.Obliterate;
	end
end

function DeathKnight:FrostRacials()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local runeforge = fd.runeforge;
end

function DeathKnight:FrostSingleTarget()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local gcd = fd.gcd;
	local runes = UnitPower('player', Enum.PowerType.Runes);
	local runesduration = select(2,GetRuneCooldown(1));
	local runesRegen = runesduration and math.floor(runesduration*100)/100;
	local runesTimeTo2 = DeathKnight:TimeToRunes(2);
	local runesTimeTo3 = DeathKnight:TimeToRunes(3);
	local runesTimeTo4 = DeathKnight:TimeToRunes(4);
	local runicPower = UnitPower('player', Enum.PowerType.RunicPower);
	local runicPowerMax = UnitPowerMax('player', Enum.PowerType.RunicPower);
	local runicPowerPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local runicPowerRegen = select(2,GetPowerRegen());
	local runicPowerRegenCombined = runicPowerRegen + runicPower;
	local runicPowerDeficit = UnitPowerMax('player', Enum.PowerType.RunicPower) - runicPower;
	local runicPowerTimeToMax = runicPowerMax - runicPower / runicPowerRegen;
	local runeforge = fd.runeforge;

	-- remorseless_winter,if=variable.rw_buffs|variable.adds_remain;
	if cooldown[FR.RemorselessWinter].ready and runes >= 1 and runicPower >= 10 and (rwBuffs or addsRemain) then
		return FR.RemorselessWinter;
	end

	-- frost_strike,if=buff.killing_machine.stack<2&runic_power.deficit<20&!variable.2h_check;
	if talents[FR.FrostStrike] and runicPower >= 30 and (buff[FR.KillingMachine].count < 2 and runicPowerDeficit < 20 and not TwoHanderWepCheck) then
		return FR.FrostStrike;
	end

	-- howling_blast,if=buff.rime.react&set_bonus.tier30_2pc&buff.killing_machine.stack<2;
	if talents[FR.HowlingBlast] and runes >= 1 and runicPower >= 10 and (buff[FR.Rime].count and MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2) and buff[FR.KillingMachine].count < 2) then
		return FR.HowlingBlast;
	end

	-- frostscythe,if=buff.killing_machine.react&variable.frostscythe_priority;
	if talents[FR.Frostscythe] and runes >= 1 and (buff[FR.KillingMachine].count and frostscythePriority) then
		return FR.Frostscythe;
	end

	-- obliterate,if=buff.killing_machine.react;
	if talents[FR.Obliterate] and runes >= 2 and (buff[FR.KillingMachine].count) then
		return FR.Obliterate;
	end

	-- howling_blast,if=buff.rime.react&talent.icebreaker.rank=2;
	if talents[FR.HowlingBlast] and runes >= 1 and runicPower >= 10 and (buff[FR.Rime].count and talents[FR.Icebreaker] == 2) then
		return FR.HowlingBlast;
	end

	-- horn_of_winter,if=rune<4&runic_power.deficit>25&talent.obliteration&talent.breath_of_sindragosa;
	if talents[FR.HornOfWinter] and cooldown[FR.HornOfWinter].ready and (runes < 4 and runicPowerDeficit > 25 and talents[FR.Obliteration] and talents[FR.BreathOfSindragosa]) then
		return FR.HornOfWinter;
	end

	-- frost_strike,if=!variable.pooling_runic_power&(variable.rp_buffs|runic_power.deficit<25|debuff.razorice.stack=5&talent.shattering_blade);
	if talents[FR.FrostStrike] and runicPower >= 30 and (not poolingRunicPower and ( rpBuffs or runicPowerDeficit < 25 or debuff[FR.Razorice].count == 5 and talents[FR.ShatteringBlade] )) then
		return FR.FrostStrike;
	end

	-- howling_blast,if=variable.rime_buffs;
	if talents[FR.HowlingBlast] and runes >= 1 and runicPower >= 10 and (rimeBuffs) then
		return FR.HowlingBlast;
	end

	-- glacial_advance,if=!variable.pooling_runic_power&!death_knight.runeforge.razorice&(debuff.razorice.stack<5|debuff.razorice.remains<gcd*3);
	if talents[FR.GlacialAdvance] and runicPower >= 30 and (not poolingRunicPower and not runeforge[FR.Razorice] and ( debuff[FR.Razorice].count < 5 or debuff[FR.Razorice].remains < gcd * 3 )) then
		return FR.GlacialAdvance;
	end

	-- obliterate,if=!variable.pooling_runes;
	if talents[FR.Obliterate] and runes >= 2 and (not poolingRunes) then
		return FR.Obliterate;
	end

	-- horn_of_winter,if=rune<4&runic_power.deficit>25&(!talent.breath_of_sindragosa|cooldown.breath_of_sindragosa.remains>cooldown.horn_of_winter.duration);
	if talents[FR.HornOfWinter] and cooldown[FR.HornOfWinter].ready and (runes < 4 and runicPowerDeficit > 25 and ( not talents[FR.BreathOfSindragosa] or cooldown[FR.BreathOfSindragosa].remains > cooldown[FR.HornOfWinter].duration )) then
		return FR.HornOfWinter;
	end

	-- frost_strike,if=!variable.pooling_runic_power;
	if talents[FR.FrostStrike] and runicPower >= 30 and (not poolingRunicPower) then
		return FR.FrostStrike;
	end
end

function DeathKnight:FrostTrinkets()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local runeforge = fd.runeforge;
end

function DeathKnight:FrostVariables()
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
	local runes = UnitPower('player', Enum.PowerType.Runes);
	local runesduration = select(2,GetRuneCooldown(1));
	local runesRegen = runesduration and math.floor(runesduration*100)/100;
	local runesTimeTo2 = DeathKnight:TimeToRunes(2);
	local runesTimeTo3 = DeathKnight:TimeToRunes(3);
	local runesTimeTo4 = DeathKnight:TimeToRunes(4);
	local runicPower = UnitPower('player', Enum.PowerType.RunicPower);
	local runicPowerMax = UnitPowerMax('player', Enum.PowerType.RunicPower);
	local runicPowerPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local runicPowerRegen = select(2,GetPowerRegen());
	local runicPowerRegenCombined = runicPowerRegen + runicPower;
	local runicPowerDeficit = UnitPowerMax('player', Enum.PowerType.RunicPower) - runicPower;
	local runicPowerTimeToMax = runicPowerMax - runicPower / runicPowerRegen;
	local runeforge = fd.runeforge;

	-- variable,name=st_planning,value=active_enemies=1&(raid_event.adds.in>15|!raid_event.adds.exists);
	stPlanning = (targets == 1);

	-- variable,name=adds_remain,value=active_enemies>=2&(!raid_event.adds.exists|raid_event.adds.exists&raid_event.adds.remains>5);
	addsRemain = targets >= 2 and ( not targets > 1 or targets > 1 );

	-- variable,name=rime_buffs,value=buff.rime.react&(talent.rage_of_the_frozen_champion|talent.avalanche|talent.icebreaker);
	rimeBuffs = buff[FR.Rime].count and ( talents[FR.RageOfTheFrozenChampion] or talents[FR.Avalanche] or talents[FR.Icebreaker] );

	-- variable,name=rp_buffs,value=talent.unleashed_frenzy&(buff.unleashed_frenzy.remains<gcd.max*3|buff.unleashed_frenzy.stack<3)|talent.icy_talons&(buff.icy_talons.remains<gcd.max*3|buff.icy_talons.stack<3);
	rpBuffs = talents[FR.UnleashedFrenzy] and ( buff[FR.UnleashedFrenzy].remains < gcd * 3 or buff[FR.UnleashedFrenzy].count < 3 ) or talents[FR.IcyTalons] and ( buff[FR.IcyTalons].remains < gcd * 3 or buff[FR.IcyTalons].count < 3 );

	-- variable,name=cooldown_check,value=talent.pillar_of_frost&buff.pillar_of_frost.up&(talent.obliteration&buff.pillar_of_frost.remains<6|!talent.obliteration)|!talent.pillar_of_frost&buff.empower_rune_weapon.up|!talent.pillar_of_frost&!talent.empower_rune_weapon|active_enemies>=2&buff.pillar_of_frost.up;
	cooldownCheck = talents[FR.PillarOfFrost] and buff[FR.PillarOfFrost].up and ( talents[FR.Obliteration] and buff[FR.PillarOfFrost].remains < 6 or not talents[FR.Obliteration] ) or not talents[FR.PillarOfFrost] and buff[FR.EmpowerRuneWeapon].up or not talents[FR.PillarOfFrost] and not talents[FR.EmpowerRuneWeapon] or targets >= 2 and buff[FR.PillarOfFrost].up;

	-- variable,name=frostscythe_priority,value=talent.frostscythe&(buff.killing_machine.react|active_enemies>=3)&(!talent.improved_obliterate&!talent.frigid_executioner&!talent.frostreaper&!talent.might_of_the_frozen_wastes|!talent.cleaving_strikes|talent.cleaving_strikes&(active_enemies>6|!death_and_decay.ticking&active_enemies>3));
	frostscythePriority = talents[FR.Frostscythe] and ( buff[FR.KillingMachine].count or targets >= 3 ) and ( not talents[FR.ImprovedObliterate] and not talents[FR.FrigidExecutioner] and not talents[FR.Frostreaper] and not talents[FR.MightOfTheFrozenWastes] or not talents[FR.CleavingStrikes] or talents[FR.CleavingStrikes] and ( targets > 6 or not debuff[FR.DeathAndDecay].up and targets > 3 ) );

	-- variable,name=oblit_pooling_time,op=setif,value=((cooldown.pillar_of_frost.remains_expected+1)%gcd.max)%((rune+3)*(runic_power+5))*100,value_else=3,condition=runic_power<35&rune<2&cooldown.pillar_of_frost.remains_expected<10;
	if runicPower < 35 and runes < 2 and cooldown[FR.PillarOfFrost].remains < 10 then
		oblitPoolingTime = ( ( cooldown[FR.PillarOfFrost].remains + 1 ) / gcd ) / ( ( runes + 3 ) * ( runicPower + 5 ) ) * 100;
	else
		oblitPoolingTime = 3;
	end

	-- variable,name=breath_pooling_time,op=setif,value=((cooldown.breath_of_sindragosa.remains+1)%gcd.max)%((rune+1)*(runic_power+20))*100,value_else=3,condition=runic_power.deficit>10&cooldown.breath_of_sindragosa.remains<10;
	if runicPowerDeficit > 10 and cooldown[FR.BreathOfSindragosa].remains < 10 then
		breathPoolingTime = ( ( cooldown[FR.BreathOfSindragosa].remains + 1 ) / gcd ) / ( ( runes + 1 ) * ( runicPower + 20 ) ) * 100;
	else
		breathPoolingTime = 3;
	end

	-- variable,name=pooling_runes,value=rune<4&talent.obliteration&cooldown.pillar_of_frost.remains_expected<variable.oblit_pooling_time;
	poolingRunes = runes < 4 and talents[FR.Obliteration] and cooldown[FR.PillarOfFrost].remains < oblitPoolingTime;

	-- variable,name=pooling_runic_power,value=talent.breath_of_sindragosa&cooldown.breath_of_sindragosa.remains<variable.breath_pooling_time|talent.obliteration&runic_power<35&cooldown.pillar_of_frost.remains_expected<variable.oblit_pooling_time;
	poolingRunicPower = talents[FR.BreathOfSindragosa] and cooldown[FR.BreathOfSindragosa].remains < breathPoolingTime or talents[FR.Obliteration] and runicPower < 35 and cooldown[FR.PillarOfFrost].remains < oblitPoolingTime;
end


local _, addonTable = ...;

-- @type MaxDps;
if not MaxDps then return end;
local Druid = addonTable.Druid;
local MaxDps = MaxDps;

local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;

local itemID = GetInventoryItemID('player', INVSLOT_MAINHAND);

local mainHandSubClassID = itemID and  select(13, GetItemInfo(itemID));

local TwoHanderWepCheck = mainHandSubClassID and (mainHandSubClassID == 1 or mainHandSubClassID == 5 or mainHandSubClassID == 8 or mainHandSubClassID == 10);

local BL = {
	CelestialAlignment = 194223,
	MoonkinForm = 24858,
	Wrath = 190984,
	StellarFlare = 202347,
	Starfire = 194153,
	AetherialKindling = 327541,
	Starweaver = 393940,
	Starfall = 191034,
	NaturesBalance = 202430,
	OrbitBreaker = 383197,
	Moonfire = 8921,
	Solstice = 343647,
	NaturesVigil = 124974,
	Sunfire = 93402,
	UmbralIntensity = 383195,
	AstralSmolder = 394058,
	OrbitalStrike = 390378,
	TouchTheCosmos = 394414,
	EclipseLunar = 48518,
	EclipseSolar = 48517,
	Incarnation = 102560,
	WarriorOfElune = 202425,
	WildMushroom = 88747,
	FungalGrowth = 392999,
	WaningTwilight = 393956,
	FuryOfElune = 202770,
	PrimordialArcanicPulsar = 393960,
	StarweaversWarp = 393942,
	Starlord = 202345,
	FullMoon = 274283,
	Starsurge = 78674,
	StarweaversWeft = 393944,
	AstralCommunion = 400636,
	ConvokeTheSpirits = 391528,
	ElunesGuidance = 393991,
	NewMoon = 274281,
	HalfMoon = 274282,
	ForceOfNature = 205636,
	RattleTheStars = 393954,
	RattledStars = 393955,
};
local A = {
};
function Druid:Balance()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local spellHaste = fd.spellHaste;

	-- variable,name=is_aoe,value=spell_targets.starfall>(1+(!talent.aetherial_kindling&!talent.starweaver))&talent.starfall;
	local isAoe = targets > ( 1 + ( not talents[BL.AetherialKindling] and not talents[BL.Starweaver] ) ) and talents[BL.Starfall];

	-- variable,name=passive_asp,value=6%spell_haste+talent.natures_balance+talent.orbit_breaker*dot.moonfire.ticking*(buff.orbit_breaker.stack>(27-2*buff.solstice.up))*40;
	local passiveAsp = 6 / spellHaste + (talents[BL.NaturesBalance] and 1 or 0) + (talents[BL.OrbitBreaker] and 1 or 0) * debuff[BL.Moonfire].up * ( buff[BL.OrbitBreaker].count > ( 27 - 2 * buff[BL.Solstice].up ) ) * 40;

	-- natures_vigil;
	if talents[BL.NaturesVigil] and cooldown[BL.NaturesVigil].ready then
		return BL.NaturesVigil;
	end

	-- run_action_list,name=aoe,if=variable.is_aoe;
	if isAoe then
		return Druid:BalanceAoe();
	end

	-- run_action_list,name=st;
	return Druid:BalanceSt();
end
function Druid:BalanceAoe()
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
	local timeShift = fd.timeShift;
	local targets = fd.targets and fd.targets or 1;
	local timeToDie = fd.timeToDie;
	local lunarPower = UnitPower('player', Enum.PowerType.LunarPower);
	local lunarPowerMax = UnitPowerMax('player', Enum.PowerType.LunarPower);
	local lunarPowerPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local lunarPowerRegen = select(2,GetPowerRegen());
	local lunarPowerRegenCombined = lunarPowerRegen + lunarPower;
	local lunarPowerDeficit = UnitPowerMax('player', Enum.PowerType.LunarPower) - lunarPower;
	local lunarPowerTimeToMax = lunarPowerMax - lunarPower / lunarPowerRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- moonfire,target_if=refreshable&(target.time_to_die-remains)>6&astral_power.deficit>variable.passive_asp+3,if=fight_style.dungeonroute;
	if mana >= 0 then
		return BL.Moonfire;
	end

	-- sunfire,target_if=refreshable&(target.time_to_die-remains)>6-(spell_targets%2)&astral_power.deficit>variable.passive_asp+3;
	if talents[BL.Sunfire] and mana >= 0 then
		return BL.Sunfire;
	end

	-- moonfire,target_if=refreshable&(target.time_to_die-remains)>6&astral_power.deficit>variable.passive_asp+3,if=!fight_style.dungeonroute;
	if mana >= 0 then
		return BL.Moonfire;
	end

	-- variable,name=cd_condition_aoe,value=!druid.no_cds&(cooldown.ca_inc.remains<5&!buff.ca_inc.up&(target.time_to_die>10|fight_remains<25+10*talent.incarnation_chosen_of_elune));
	local cdConditionAoe = not druidNoCds and ( cooldown[BL.CaInc].remains < 5 and not buff[BL.CaInc].up and ( timeToDie > 10 or timeToDie < 25 + 10 * (talents[BL.IncarnationChosenOfElune] and 1 or 0) ) );

	-- stellar_flare,target_if=refreshable&(target.time_to_die-remains-spell_targets.starfire)>8+spell_targets.starfire,if=astral_power.deficit>variable.passive_asp+8&spell_targets.starfire<(11-talent.umbral_intensity.rank-talent.astral_smolder.rank)&variable.cd_condition_aoe;
	if talents[BL.StellarFlare] and currentSpell ~= BL.StellarFlare and (lunarPowerDeficit > passiveAsp + 8 and targets < ( 11 - (talents[BL.UmbralIntensity] and 1 or 0) - (talents[BL.AstralSmolder] and 1 or 0) ) and cdConditionAoe) then
		return BL.StellarFlare;
	end

	-- variable,name=starfall_condition1,value=variable.cd_condition_aoe&(talent.orbital_strike&astral_power.deficit<variable.passive_asp+8*spell_targets|buff.touch_the_cosmos.up)|astral_power.deficit<(variable.passive_asp+8+12*(buff.eclipse_lunar.remains<4|buff.eclipse_solar.remains<4));
	local starfallCondition1 = cdConditionAoe and ( talents[BL.OrbitalStrike] and lunarPowerDeficit < passiveAsp + 8 * targets or buff[BL.TouchTheCosmos].up ) or lunarPowerDeficit < ( passiveAsp + 8 + 12 * ( buff[BL.EclipseLunar].remains < 4 or buff[BL.EclipseSolar].remains < 4 ) );

	-- starfall,if=variable.starfall_condition1;
	if talents[BL.Starfall] and lunarPower >= 50 and (starfallCondition1) then
		return BL.Starfall;
	end

	-- celestial_alignment,if=variable.cd_condition_aoe;
	if talents[BL.CelestialAlignment] and cooldown[BL.CelestialAlignment].ready and (cdConditionAoe) then
		return BL.CelestialAlignment;
	end

	-- incarnation,if=variable.cd_condition_aoe;
	if cdConditionAoe then
		return BL.Incarnation;
	end

	-- warrior_of_elune;
	if talents[BL.WarriorOfElune] and cooldown[BL.WarriorOfElune].ready then
		return BL.WarriorOfElune;
	end

	-- variable,name=enter_solar,value=spell_targets.starfire<3;
	local enterSolar = targets < 3;

	-- starfire,if=variable.enter_solar&(eclipse.any_next|buff.eclipse_solar.remains<action.starfire.cast_time);
	if talents[BL.Starfire] and currentSpell ~= BL.Starfire and (enterSolar and ( eclipseAnyNext or buff[BL.EclipseSolar].remains < timeShift )) then
		return BL.Starfire;
	end

	-- wrath,if=!variable.enter_solar&(eclipse.any_next|buff.eclipse_lunar.remains<action.wrath.cast_time);
	if currentSpell ~= BL.Wrath and (not enterSolar and ( eclipseAnyNext or buff[BL.EclipseLunar].remains < timeShift )) then
		return BL.Wrath;
	end

	-- wild_mushroom,if=astral_power.deficit>variable.passive_asp+20&(!talent.fungal_growth|!talent.waning_twilight|dot.fungal_growth.remains<2&target.time_to_die>7&!prev_gcd.1.wild_mushroom);
	if talents[BL.WildMushroom] and cooldown[BL.WildMushroom].ready and (lunarPowerDeficit > passiveAsp + 20 and ( not talents[BL.FungalGrowth] or not talents[BL.WaningTwilight] or debuff[BL.FungalGrowth].remains < 2 and timeToDie > 7 and not spellHistory[1] == BL.WildMushroom )) then
		return BL.WildMushroom;
	end

	-- fury_of_elune,if=target.time_to_die>2&(buff.ca_inc.remains>3|cooldown.ca_inc.remains>30&buff.primordial_arcanic_pulsar.value<=280|buff.primordial_arcanic_pulsar.value>=560&astral_power>50)|fight_remains<10;
	if talents[BL.FuryOfElune] and cooldown[BL.FuryOfElune].ready and (timeToDie > 2 and ( buff[BL.CaInc].remains > 3 or cooldown[BL.CaInc].remains > 30 and buff[BL.PrimordialArcanicPulsar].value <= 280 or buff[BL.PrimordialArcanicPulsar].value >= 560 and lunarPower > 50 ) or timeToDie < 10) then
		return BL.FuryOfElune;
	end

	-- variable,name=starfall_condition2,value=target.time_to_die>4&(buff.starweavers_warp.up|talent.starlord&buff.starlord.stack<3);
	local starfallCondition2 = timeToDie > 4 and ( buff[BL.StarweaversWarp].up or talents[BL.Starlord] and buff[BL.Starlord].count < 3 );

	-- starfall,if=variable.starfall_condition2;
	if talents[BL.Starfall] and lunarPower >= 50 and (starfallCondition2) then
		return BL.Starfall;
	end

	-- full_moon,if=astral_power.deficit>variable.passive_asp+40&(buff.eclipse_lunar.remains>execute_time|buff.eclipse_solar.remains>execute_time)&(buff.ca_inc.up|charges_fractional>2.5&buff.primordial_arcanic_pulsar.value<=520&cooldown.ca_inc.remains>10|fight_remains<10);
	if lunarPowerDeficit > passiveAsp + 40 and ( buff[BL.EclipseLunar].remains > timeShift or buff[BL.EclipseSolar].remains > timeShift ) and ( buff[BL.CaInc].up or cooldown[BL.FullMoon].charges > 2.5 and buff[BL.PrimordialArcanicPulsar].value <= 520 and cooldown[BL.CaInc].remains > 10 or timeToDie < 10 ) then
		return BL.FullMoon;
	end

	-- starsurge,if=buff.starweavers_weft.up&spell_targets.starfire<3;
	if talents[BL.Starsurge] and lunarPower >= 40 and (buff[BL.StarweaversWeft].up and targets < 3) then
		return BL.Starsurge;
	end

	-- stellar_flare,target_if=refreshable&(target.time_to_die-remains-spell_targets.starfire)>8+spell_targets.starfire,if=astral_power.deficit>variable.passive_asp+8&spell_targets.starfire<(11-talent.umbral_intensity.rank-talent.astral_smolder.rank);
	if talents[BL.StellarFlare] and currentSpell ~= BL.StellarFlare and (lunarPowerDeficit > passiveAsp + 8 and targets < ( 11 - (talents[BL.UmbralIntensity] and 1 or 0) - (talents[BL.AstralSmolder] and 1 or 0) )) then
		return BL.StellarFlare;
	end

	-- astral_communion,if=astral_power.deficit>variable.passive_asp+50;
	if talents[BL.AstralCommunion] and (lunarPowerDeficit > passiveAsp + 50) then
		return BL.AstralCommunion;
	end

	-- convoke_the_spirits,if=astral_power<50&spell_targets.starfall<3+talent.elunes_guidance&(buff.eclipse_lunar.remains>4|buff.eclipse_solar.remains>4);
	if talents[BL.ConvokeTheSpirits] and cooldown[BL.ConvokeTheSpirits].ready and (lunarPower < 50 and targets < 3 + (talents[BL.ElunesGuidance] and 1 or 0) and ( buff[BL.EclipseLunar].remains > 4 or buff[BL.EclipseSolar].remains > 4 )) then
		return BL.ConvokeTheSpirits;
	end

	-- new_moon,if=astral_power.deficit>variable.passive_asp+10;
	if talents[BL.NewMoon] and cooldown[BL.NewMoon].ready and currentSpell ~= BL.NewMoon and (lunarPowerDeficit > passiveAsp + 10) then
		return BL.NewMoon;
	end

	-- half_moon,if=astral_power.deficit>variable.passive_asp+20&(buff.eclipse_lunar.remains>execute_time|buff.eclipse_solar.remains>execute_time);
	if lunarPowerDeficit > passiveAsp + 20 and ( buff[BL.EclipseLunar].remains > timeShift or buff[BL.EclipseSolar].remains > timeShift ) then
		return BL.HalfMoon;
	end

	-- force_of_nature,if=astral_power.deficit>variable.passive_asp+20;
	if talents[BL.ForceOfNature] and cooldown[BL.ForceOfNature].ready and (lunarPowerDeficit > passiveAsp + 20) then
		return BL.ForceOfNature;
	end

	-- starsurge,if=buff.starweavers_weft.up&spell_targets.starfire<17;
	if talents[BL.Starsurge] and lunarPower >= 40 and (buff[BL.StarweaversWeft].up and targets < 17) then
		return BL.Starsurge;
	end

	-- starfire,if=spell_targets>3&buff.eclipse_lunar.up|eclipse.in_lunar;
	if talents[BL.Starfire] and currentSpell ~= BL.Starfire and (targets > 3 and buff[BL.EclipseLunar].up or eclipseInLunar) then
		return BL.Starfire;
	end

	-- wrath;
	if currentSpell ~= BL.Wrath then
		return BL.Wrath;
	end

	-- run_action_list,name=fallthru;
	return Druid:BalanceFallthru();
end

function Druid:BalanceFallthru()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local lunarPower = UnitPower('player', Enum.PowerType.LunarPower);
	local lunarPowerMax = UnitPowerMax('player', Enum.PowerType.LunarPower);
	local lunarPowerPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local lunarPowerRegen = select(2,GetPowerRegen());
	local lunarPowerRegenCombined = lunarPowerRegen + lunarPower;
	local lunarPowerDeficit = UnitPowerMax('player', Enum.PowerType.LunarPower) - lunarPower;
	local lunarPowerTimeToMax = lunarPowerMax - lunarPower / lunarPowerRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- starfall,if=variable.is_aoe;
	if talents[BL.Starfall] and lunarPower >= 50 and (isAoe) then
		return BL.Starfall;
	end

	-- starsurge;
	if talents[BL.Starsurge] and lunarPower >= 40 then
		return BL.Starsurge;
	end

	-- sunfire,target_if=dot.moonfire.remains>remains*22%18;
	if talents[BL.Sunfire] and mana >= 0 then
		return BL.Sunfire;
	end

	-- moonfire;
	if mana >= 0 then
		return BL.Moonfire;
	end
end

function Druid:BalanceSt()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local timeShift = fd.timeShift;
	local targets = fd.targets and fd.targets or 1;
	local gcd = fd.gcd;
	local timeToDie = fd.timeToDie;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;
	local lunarPower = UnitPower('player', Enum.PowerType.LunarPower);
	local lunarPowerMax = UnitPowerMax('player', Enum.PowerType.LunarPower);
	local lunarPowerPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local lunarPowerRegen = select(2,GetPowerRegen());
	local lunarPowerRegenCombined = lunarPowerRegen + lunarPower;
	local lunarPowerDeficit = UnitPowerMax('player', Enum.PowerType.LunarPower) - lunarPower;
	local lunarPowerTimeToMax = lunarPowerMax - lunarPower / lunarPowerRegen;

	-- sunfire,target_if=refreshable&remains<2&(target.time_to_die-remains)>6;
	if talents[BL.Sunfire] and mana >= 0 then
		return BL.Sunfire;
	end

	-- moonfire,target_if=refreshable&remains<2&(target.time_to_die-remains)>6;
	if mana >= 0 then
		return BL.Moonfire;
	end

	-- stellar_flare,target_if=refreshable&astral_power.deficit>variable.passive_asp+8&remains<2&(target.time_to_die-remains)>8;
	if talents[BL.StellarFlare] and currentSpell ~= BL.StellarFlare then
		return BL.StellarFlare;
	end

	-- variable,name=cd_condition_st,value=!druid.no_cds&(cooldown.ca_inc.remains<15&!buff.ca_inc.up&(target.time_to_die>15|fight_remains<25+10*talent.incarnation_chosen_of_elune));
	local cdConditionSt = not druidNoCds and ( cooldown[BL.CaInc].remains < 15 and not buff[BL.CaInc].up and ( timeToDie > 15 or timeToDie < 25 + 10 * (talents[BL.IncarnationChosenOfElune] and 1 or 0) ) );

	-- starfall,if=buff.primordial_arcanic_pulsar.value>=550&!buff.ca_inc.up&buff.starweavers_warp.up;
	if talents[BL.Starfall] and lunarPower >= 50 and (buff[BL.PrimordialArcanicPulsar].value >= 550 and not buff[BL.CaInc].up and buff[BL.StarweaversWarp].up) then
		return BL.Starfall;
	end

	-- starsurge,if=buff.primordial_arcanic_pulsar.value>=560&buff.starweavers_weft.up;
	if talents[BL.Starsurge] and lunarPower >= 40 and (buff[BL.PrimordialArcanicPulsar].value >= 560 and buff[BL.StarweaversWeft].up) then
		return BL.Starsurge;
	end

	-- celestial_alignment,if=variable.cd_condition_st;
	if talents[BL.CelestialAlignment] and cooldown[BL.CelestialAlignment].ready and (cdConditionSt) then
		return BL.CelestialAlignment;
	end

	-- incarnation,if=variable.cd_condition_st;
	if cdConditionSt then
		return BL.Incarnation;
	end

	-- variable,name=solar_eclipse_st,value=buff.primordial_arcanic_pulsar.value<520&cooldown.ca_inc.remains>5&spell_targets.starfire<3;
	local solarEclipseSt = buff[BL.PrimordialArcanicPulsar].value < 520 and cooldown[BL.CaInc].remains > 5 and targets < 3;

	-- variable,name=enter_eclipse,value=eclipse.any_next|variable.solar_eclipse_st&buff.eclipse_solar.up&(buff.eclipse_solar.remains<action.starfire.cast_time)|!variable.solar_eclipse_st&buff.eclipse_lunar.up&(buff.eclipse_lunar.remains<action.wrath.cast_time);
	local enterEclipse = eclipseAnyNext or solarEclipseSt and buff[BL.EclipseSolar].up and ( buff[BL.EclipseSolar].remains < timeShift ) or not solarEclipseSt and buff[BL.EclipseLunar].up and ( buff[BL.EclipseLunar].remains < timeShift );

	-- warrior_of_elune,if=variable.solar_eclipse_st&(variable.enter_eclipse|buff.eclipse_solar.remains<7&buff.primordial_arcanic_pulsar.value<280);
	if talents[BL.WarriorOfElune] and cooldown[BL.WarriorOfElune].ready and (solarEclipseSt and ( enterEclipse or buff[BL.EclipseSolar].remains < 7 and buff[BL.PrimordialArcanicPulsar].value < 280 )) then
		return BL.WarriorOfElune;
	end

	-- starfire,if=variable.enter_eclipse&variable.solar_eclipse_st;
	if talents[BL.Starfire] and currentSpell ~= BL.Starfire and (enterEclipse and solarEclipseSt) then
		return BL.Starfire;
	end

	-- wrath,if=variable.enter_eclipse;
	if currentSpell ~= BL.Wrath and (enterEclipse) then
		return BL.Wrath;
	end

	-- variable,name=convoke_condition,value=buff.ca_inc.remains>4|(cooldown.ca_inc.remains>30|variable.no_cd_talent)&(buff.eclipse_lunar.remains>4|buff.eclipse_solar.remains>4);
	local convokeCondition = buff[BL.CaInc].remains > 4 or ( cooldown[BL.CaInc].remains > 30 or noCdTalent ) and ( buff[BL.EclipseLunar].remains > 4 or buff[BL.EclipseSolar].remains > 4 );

	-- starsurge,if=talent.convoke_the_spirits&cooldown.convoke_the_spirits.ready&variable.convoke_condition;
	if talents[BL.Starsurge] and lunarPower >= 40 and (talents[BL.ConvokeTheSpirits] and cooldown[BL.ConvokeTheSpirits].ready and convokeCondition) then
		return BL.Starsurge;
	end

	-- convoke_the_spirits,if=variable.convoke_condition;
	if talents[BL.ConvokeTheSpirits] and cooldown[BL.ConvokeTheSpirits].ready and (convokeCondition) then
		return BL.ConvokeTheSpirits;
	end

	-- astral_communion,if=astral_power.deficit>variable.passive_asp+55;
	if talents[BL.AstralCommunion] and (lunarPowerDeficit > passiveAsp + 55) then
		return BL.AstralCommunion;
	end

	-- force_of_nature,if=astral_power.deficit>variable.passive_asp+20;
	if talents[BL.ForceOfNature] and cooldown[BL.ForceOfNature].ready and (lunarPowerDeficit > passiveAsp + 20) then
		return BL.ForceOfNature;
	end

	-- fury_of_elune,if=target.time_to_die>2&(buff.ca_inc.remains>3|cooldown.ca_inc.remains>30&buff.primordial_arcanic_pulsar.value<=280|buff.primordial_arcanic_pulsar.value>=560&astral_power>50)|fight_remains<10;
	if talents[BL.FuryOfElune] and cooldown[BL.FuryOfElune].ready and (timeToDie > 2 and ( buff[BL.CaInc].remains > 3 or cooldown[BL.CaInc].remains > 30 and buff[BL.PrimordialArcanicPulsar].value <= 280 or buff[BL.PrimordialArcanicPulsar].value >= 560 and lunarPower > 50 ) or timeToDie < 10) then
		return BL.FuryOfElune;
	end

	-- starfall,if=buff.starweavers_warp.up;
	if talents[BL.Starfall] and lunarPower >= 50 and (buff[BL.StarweaversWarp].up) then
		return BL.Starfall;
	end

	-- variable,name=starsurge_condition1,value=talent.starlord&buff.starlord.stack<3|talent.rattle_the_stars&buff.rattled_stars.up&buff.rattled_stars.remains<gcd.max;
	local starsurgeCondition1 = talents[BL.Starlord] and buff[BL.Starlord].count < 3 or talents[BL.RattleTheStars] and buff[BL.RattledStars].up and buff[BL.RattledStars].remains < gcd;

	-- starsurge,if=variable.starsurge_condition1;
	if talents[BL.Starsurge] and lunarPower >= 40 and (starsurgeCondition1) then
		return BL.Starsurge;
	end

	-- sunfire,target_if=refreshable&astral_power.deficit>variable.passive_asp+3;
	if talents[BL.Sunfire] and mana >= 0 then
		return BL.Sunfire;
	end

	-- moonfire,target_if=refreshable&astral_power.deficit>variable.passive_asp+3;
	if mana >= 0 then
		return BL.Moonfire;
	end

	-- stellar_flare,target_if=refreshable&astral_power.deficit>variable.passive_asp+8;
	if talents[BL.StellarFlare] and currentSpell ~= BL.StellarFlare then
		return BL.StellarFlare;
	end

	-- new_moon,if=astral_power.deficit>variable.passive_asp+10&(buff.ca_inc.up|charges_fractional>2.5&buff.primordial_arcanic_pulsar.value<=520&cooldown.ca_inc.remains>10|fight_remains<10);
	if talents[BL.NewMoon] and cooldown[BL.NewMoon].ready and currentSpell ~= BL.NewMoon and (lunarPowerDeficit > passiveAsp + 10 and ( buff[BL.CaInc].up or cooldown[BL.NewMoon].charges > 2.5 and buff[BL.PrimordialArcanicPulsar].value <= 520 and cooldown[BL.CaInc].remains > 10 or timeToDie < 10 )) then
		return BL.NewMoon;
	end

	-- half_moon,if=astral_power.deficit>variable.passive_asp+20&(buff.eclipse_lunar.remains>execute_time|buff.eclipse_solar.remains>execute_time)&(buff.ca_inc.up|charges_fractional>2.5&buff.primordial_arcanic_pulsar.value<=520&cooldown.ca_inc.remains>10|fight_remains<10);
	if lunarPowerDeficit > passiveAsp + 20 and ( buff[BL.EclipseLunar].remains > timeShift or buff[BL.EclipseSolar].remains > timeShift ) and ( buff[BL.CaInc].up or cooldown[BL.HalfMoon].charges > 2.5 and buff[BL.PrimordialArcanicPulsar].value <= 520 and cooldown[BL.CaInc].remains > 10 or timeToDie < 10 ) then
		return BL.HalfMoon;
	end

	-- full_moon,if=astral_power.deficit>variable.passive_asp+40&(buff.eclipse_lunar.remains>execute_time|buff.eclipse_solar.remains>execute_time)&(buff.ca_inc.up|charges_fractional>2.5&buff.primordial_arcanic_pulsar.value<=520&cooldown.ca_inc.remains>10|fight_remains<10);
	if lunarPowerDeficit > passiveAsp + 40 and ( buff[BL.EclipseLunar].remains > timeShift or buff[BL.EclipseSolar].remains > timeShift ) and ( buff[BL.CaInc].up or cooldown[BL.FullMoon].charges > 2.5 and buff[BL.PrimordialArcanicPulsar].value <= 520 and cooldown[BL.CaInc].remains > 10 or timeToDie < 10 ) then
		return BL.FullMoon;
	end

	-- variable,name=starsurge_condition2,value=buff.starweavers_weft.up|astral_power.deficit<variable.passive_asp+action.wrath.energize_amount+(action.starfire.energize_amount+variable.passive_asp)*(buff.eclipse_solar.remains<(gcd.max*3))|talent.astral_communion&cooldown.astral_communion.remains<3|fight_remains<5;
	local starsurgeCondition2 = buff[BL.StarweaversWeft].up or lunarPowerDeficit < passiveAsp + ( passiveAsp ) * ( buff[BL.EclipseSolar].remains < ( gcd * 3 ) ) or talents[BL.AstralCommunion] and cooldown[BL.AstralCommunion].remains < 3 or timeToDie < 5;

	-- starsurge,if=variable.starsurge_condition2;
	if talents[BL.Starsurge] and lunarPower >= 40 and (starsurgeCondition2) then
		return BL.Starsurge;
	end

	-- wild_mushroom,if=talent.fungal_growth&(!fight_style.dungeonroute|target.time_to_die>(full_recharge_time-7)|fight_remains<10);
	if talents[BL.WildMushroom] and cooldown[BL.WildMushroom].ready and (talents[BL.FungalGrowth] and ( not timeToDie > ( cooldown[BL.WildMushroom].fullRecharge - 7 ) or timeToDie < 10 )) then
		return BL.WildMushroom;
	end

	-- wrath;
	if currentSpell ~= BL.Wrath then
		return BL.Wrath;
	end

	-- run_action_list,name=fallthru;
	return Druid:BalanceFallthru();
end


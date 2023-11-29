local _, addonTable = ...;

-- @type MaxDps;
if not MaxDps then return end;
local Monk = addonTable.Monk;
local MaxDps = MaxDps;

local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;

local itemID = GetInventoryItemID('player', INVSLOT_MAINHAND);

local mainHandSubClassID = itemID and  select(13, GetItemInfo(itemID));

local TwoHanderWepCheck = mainHandSubClassID and (mainHandSubClassID == 1 or mainHandSubClassID == 5 or mainHandSubClassID == 8 or mainHandSubClassID == 10);

local WW = {
	SummonWhiteTigerStatue = 388686,
	ExpelHarm = 322101,
	ChiBurst = 123986,
	FaelineStomp = 388193,
	ChiWave = 115098,
	Roll = 109132,
	ChiTorpedo = 115008,
	FlyingSerpentKick = 101545,
	SpearHandStrike = 116705,
	InvokeXuenTheWhiteTiger = 123904,
	Serenity = 152173,
	StormEarthAndFire = 137639,
	FaeExposureDamage = 356773,
	FaelineHarmony = 391412,
	TigerPalm = 100780,
	MarkOfTheCrane = 220357,
	SkyreachExhaustion = 393050,
	TeachingsOfTheMonastery = 116645,
	PowerStrikes = 121817,
	Skyreach = 392991,
	Skytouch = 405044,
	SpinningCraneKick = 101546,
	DanceOfChiji = 325201,
	StrikeOfTheWindlord = 392983,
	Thunderfist = 392985,
	FistsOfFury = 113656,
	RisingSunKick = 107428,
	BonedustBrew = 386276,
	PressurePoint = 337482,
	Tier302pc = 405543,
	BlackoutKick = 100784,
	WhirlingDragonPunch = 152175,
	RushingJadeWind = 116847,
	TouchOfDeath = 322109,
	HiddenMastersForbiddenTouch = 213112,
	TouchOfKarma = 122470,
	CracklingJadeLightning = 117952,
	TheEmperorsCapacitor = 235054,
	KicksOfFlowingMomentum = 394944,
	InvokersDelight = 388661,
	CraneVortex = 388848,
	ShdaowboxingTreads = 392982,
	--JadeIgnition = ,
	XuensBattlegear = 392993,
};
local A = {
};
function Monk:Windwalker()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local timeToDie = fd.timeToDie;
	local chi = UnitPower('player', Enum.PowerType.Chi);
	local chiMax = UnitPowerMax('player', Enum.PowerType.Chi);
	local chiPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local chiRegen = select(2,GetPowerRegen());
	local chiRegenCombined = chiRegen + chi;
	local chiDeficit = UnitPowerMax('player', Enum.PowerType.Chi) - chi;
	local chiTimeToMax = chiMax - chi / chiRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;

	-- variable,name=hold_xuen,op=set,value=!talent.invoke_xuen_the_white_tiger|cooldown.invoke_xuen_the_white_tiger.remains>fight_remains|fight_remains-cooldown.invoke_xuen_the_white_tiger.remains<120&((talent.serenity&fight_remains>cooldown.serenity.remains&cooldown.serenity.remains>10)|(cooldown.storm_earth_and_fire.full_recharge_time<fight_remains&cooldown.storm_earth_and_fire.full_recharge_time>15)|(cooldown.storm_earth_and_fire.charges=0&cooldown.storm_earth_and_fire.remains<fight_remains));
	local holdXuen = not talents[WW.InvokeXuenTheWhiteTiger] or cooldown[WW.InvokeXuenTheWhiteTiger].remains > timeToDie or timeToDie - cooldown[WW.InvokeXuenTheWhiteTiger].remains < 120 and ( ( talents[WW.Serenity] and timeToDie > cooldown[WW.Serenity].remains and cooldown[WW.Serenity].remains > 10 ) or ( cooldown[WW.StormEarthAndFire].fullRecharge < timeToDie and cooldown[WW.StormEarthAndFire].fullRecharge > 15 ) or ( cooldown[WW.StormEarthAndFire].charges == 0 and cooldown[WW.StormEarthAndFire].remains < timeToDie ) );

	-- call_action_list,name=opener,if=time<4&chi<5&!pet.xuen_the_white_tiger.active&!talent.serenity;
	if GetTime() < 4 and chi < 5 and not petXuen and not talents[WW.Serenity] then
		local result = Monk:WindwalkerOpener();
		if result then
			return result;
		end
	end

	-- call_action_list,name=trinkets;

	-- faeline_stomp,target_if=min:debuff.fae_exposure_damage.remains,if=combo_strike&talent.faeline_harmony&debuff.fae_exposure_damage.remains<1;
	if talents[WW.FaelineStomp] and cooldown[WW.FaelineStomp].ready and mana >= 0 and (comboStrike and talents[WW.FaelineHarmony] and debuff[WW.FaeExposureDamage].remains < 1) then
		return WW.FaelineStomp;
	end

	-- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains+(debuff.skyreach_exhaustion.up*20),if=!buff.serenity.up&buff.teachings_of_the_monastery.stack<3&combo_strike&chi.max-chi>=(2+buff.power_strikes.up)&(!talent.invoke_xuen_the_white_tiger&!talent.serenity|((!talent.skyreach&!talent.skytouch)|time>5|pet.xuen_the_white_tiger.active));
	if energy >= 50 and (not buff[WW.Serenity].up and buff[WW.TeachingsOfTheMonastery].count < 3 and comboStrike and chiMax - chi >= ( 2 + buff[WW.PowerStrikes].up ) and ( not talents[WW.InvokeXuenTheWhiteTiger] and not talents[WW.Serenity] or ( ( not talents[WW.Skyreach] and not talents[WW.Skytouch] ) or GetTime() > 5 or petXuen ) )) then
		return WW.TigerPalm;
	end

	-- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=active_enemies=1&buff.serenity.up&pet.xuen_the_white_tiger.active&!debuff.skyreach_exhaustion.up*20&combo_strike;
	if energy >= 50 and (targets == 1 and buff[WW.Serenity].up and petXuen and not debuff[WW.SkyreachExhaustion].up * 20 and comboStrike) then
		return WW.TigerPalm;
	end

	-- chi_burst,if=talent.faeline_stomp&cooldown.faeline_stomp.remains&(chi.max-chi>=1&active_enemies=1|chi.max-chi>=2&active_enemies>=2)&!talent.faeline_harmony;
	if talents[WW.ChiBurst] and cooldown[WW.ChiBurst].ready and currentSpell ~= WW.ChiBurst and (talents[WW.FaelineStomp] and cooldown[WW.FaelineStomp].remains and ( chiMax - chi >= 1 and targets == 1 or chiMax - chi >= 2 and targets >= 2 ) and not talents[WW.FaelineHarmony]) then
		return WW.ChiBurst;
	end

	-- call_action_list,name=cd_sef,if=!talent.serenity;
	if not talents[WW.Serenity] then
		local result = Monk:WindwalkerCdSef();
		if result then
			return result;
		end
	end

	-- call_action_list,name=cd_serenity,if=talent.serenity;
	if talents[WW.Serenity] then
		local result = Monk:WindwalkerCdSerenity();
		if result then
			return result;
		end
	end

	-- call_action_list,name=serenity,if=buff.serenity.up;
	if buff[WW.Serenity].up then
		local result = Monk:WindwalkerSerenity();
		if result then
			return result;
		end
	end

	-- call_action_list,name=heavy_aoe,if=active_enemies>4;
	if targets > 4 then
		local result = Monk:WindwalkerHeavyAoe();
		if result then
			return result;
		end
	end

	-- call_action_list,name=aoe,if=active_enemies=4;
	if targets == 4 then
		local result = Monk:WindwalkerAoe();
		if result then
			return result;
		end
	end

	-- call_action_list,name=cleave,if=active_enemies=3;
	if targets == 3 then
		local result = Monk:WindwalkerCleave();
		if result then
			return result;
		end
	end

	-- call_action_list,name=st_cleave,if=active_enemies=2;
	if targets == 2 then
		local result = Monk:WindwalkerStCleave();
		if result then
			return result;
		end
	end

	-- call_action_list,name=st,if=active_enemies=1;
	if targets == 1 then
		local result = Monk:WindwalkerSt();
		if result then
			return result;
		end
	end

	-- call_action_list,name=fallthru;
	local result = Monk:WindwalkerFallthru();
	if result then
		return result;
	end
end
function Monk:WindwalkerAoe()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local chi = UnitPower('player', Enum.PowerType.Chi);
	local chiMax = UnitPowerMax('player', Enum.PowerType.Chi);
	local chiPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local chiRegen = select(2,GetPowerRegen());
	local chiRegenCombined = chiRegen + chi;
	local chiDeficit = UnitPowerMax('player', Enum.PowerType.Chi) - chi;
	local chiTimeToMax = chiMax - chi / chiRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;

	-- spinning_crane_kick,if=combo_strike&buff.dance_of_chiji.up&spinning_crane_kick.max;
	if chi >= 2 and mana >= 0 and energy >= 0 and (comboStrike and buff[WW.DanceOfChiji].up ) then
		return WW.SpinningCraneKick;
	end

	-- strike_of_the_windlord,if=talent.thunderfist;
	if talents[WW.StrikeOfTheWindlord] and cooldown[WW.StrikeOfTheWindlord].ready and chi >= 2 and (talents[WW.Thunderfist]) then
		return WW.StrikeOfTheWindlord;
	end

	-- fists_of_fury;
	if talents[WW.FistsOfFury] and cooldown[WW.FistsOfFury].ready and chi >= 3 then
		return WW.FistsOfFury;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.bonedust_brew.up&buff.pressure_point.up&set_bonus.tier30_2pc;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (buff[WW.BonedustBrew].up and buff[WW.PressurePoint].up and MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2)) then
		return WW.RisingSunKick;
	end

	-- spinning_crane_kick,if=buff.bonedust_brew.up&combo_strike&spinning_crane_kick.max;
	if chi >= 2 and mana >= 0 and energy >= 0 and (buff[WW.BonedustBrew].up and comboStrike ) then
		return WW.SpinningCraneKick;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!buff.bonedust_brew.up&buff.pressure_point.up&cooldown.fists_of_fury.remains>5;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (not buff[WW.BonedustBrew].up and buff[WW.PressurePoint].up and cooldown[WW.FistsOfFury].remains > 5) then
		return WW.RisingSunKick;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.stack=3&talent.shadowboxing_treads;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (buff[WW.TeachingsOfTheMonastery].count == 3 and talents[WW.ShadowboxingTreads]) then
		return WW.BlackoutKick;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=set_bonus.tier30_2pc;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2)) then
		return WW.RisingSunKick;
	end

	-- spinning_crane_kick,if=combo_strike&cooldown.fists_of_fury.remains>3&buff.chi_energy.stack>10;
	if chi >= 2 and mana >= 0 and energy >= 0 and (comboStrike and cooldown[WW.FistsOfFury].remains > 3 and buff[WW.ChiEnergy].count > 10) then
		return WW.SpinningCraneKick;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&set_bonus.tier30_2pc;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (comboStrike and MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2)) then
		return WW.BlackoutKick;
	end

	-- spinning_crane_kick,if=combo_strike&(cooldown.fists_of_fury.remains>3|chi>4)&spinning_crane_kick.max;
	if chi >= 2 and mana >= 0 and energy >= 0 and (comboStrike and ( cooldown[WW.FistsOfFury].remains > 3 or chi > 4 ) ) then
		return WW.SpinningCraneKick;
	end

	-- whirling_dragon_punch;
	if talents[WW.WhirlingDragonPunch] and cooldown[WW.WhirlingDragonPunch].ready then
		return WW.WhirlingDragonPunch;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.stack=3;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (buff[WW.TeachingsOfTheMonastery].count == 3) then
		return WW.BlackoutKick;
	end

	-- rushing_jade_wind,if=!buff.rushing_jade_wind.up;
	if talents[WW.RushingJadeWind] and cooldown[WW.RushingJadeWind].ready and chi >= 1 and (not buff[WW.RushingJadeWind].up) then
		return WW.RushingJadeWind;
	end

	-- strike_of_the_windlord;
	if talents[WW.StrikeOfTheWindlord] and cooldown[WW.StrikeOfTheWindlord].ready and chi >= 2 then
		return WW.StrikeOfTheWindlord;
	end

	-- spinning_crane_kick,if=combo_strike&(cooldown.fists_of_fury.remains>3|chi>4);
	if chi >= 2 and mana >= 0 and energy >= 0 and (comboStrike and ( cooldown[WW.FistsOfFury].remains > 3 or chi > 4 )) then
		return WW.SpinningCraneKick;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (comboStrike) then
		return WW.BlackoutKick;
	end
end

function Monk:WindwalkerBdbSetup()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local chi = UnitPower('player', Enum.PowerType.Chi);
	local chiMax = UnitPowerMax('player', Enum.PowerType.Chi);
	local chiPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local chiRegen = select(2,GetPowerRegen());
	local chiRegenCombined = chiRegen + chi;
	local chiDeficit = UnitPowerMax('player', Enum.PowerType.Chi) - chi;
	local chiTimeToMax = chiMax - chi / chiRegen;
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- strike_of_the_windlord,if=talent.thunderfist&active_enemies>3;
	if talents[WW.StrikeOfTheWindlord] and cooldown[WW.StrikeOfTheWindlord].ready and chi >= 2 and (talents[WW.Thunderfist] and targets > 3) then
		return WW.StrikeOfTheWindlord;
	end

	-- bonedust_brew,if=spinning_crane_kick.max&chi>=4;
	if talents[WW.BonedustBrew] and cooldown[WW.BonedustBrew].ready and (chi >= 4) then
		return WW.BonedustBrew;
	end

	-- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains+(debuff.skyreach_exhaustion.up*20),if=combo_strike&chi.max-chi>=2&buff.storm_earth_and_fire.up;
	if energy >= 50 and (comboStrike and chiMax - chi >= 2 and buff[WW.StormEarthAndFire].up) then
		return WW.TigerPalm;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&!talent.whirling_dragon_punch&!spinning_crane_kick.max;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (comboStrike and not talents[WW.WhirlingDragonPunch] ) then
		return WW.BlackoutKick;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&chi>=5&talent.whirling_dragon_punch;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (comboStrike and chi >= 5 and talents[WW.WhirlingDragonPunch]) then
		return WW.RisingSunKick;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&active_enemies>=2&talent.whirling_dragon_punch;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (comboStrike and targets >= 2 and talents[WW.WhirlingDragonPunch]) then
		return WW.RisingSunKick;
	end
end

function Monk:WindwalkerCdSef()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local timeToDie = fd.timeToDie;
	local chi = UnitPower('player', Enum.PowerType.Chi);
	local chiMax = UnitPowerMax('player', Enum.PowerType.Chi);
	local chiPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local chiRegen = select(2,GetPowerRegen());
	local chiRegenCombined = chiRegen + chi;
	local chiDeficit = UnitPowerMax('player', Enum.PowerType.Chi) - chi;
	local chiTimeToMax = chiMax - chi / chiRegen;

	-- summon_white_tiger_statue,if=!cooldown.invoke_xuen_the_white_tiger.remains|active_enemies>4|cooldown.invoke_xuen_the_white_tiger.remains>50|fight_remains<=30;
	if talents[WW.SummonWhiteTigerStatue] and cooldown[WW.SummonWhiteTigerStatue].ready and (not cooldown[WW.InvokeXuenTheWhiteTiger].remains or targets > 4 or cooldown[WW.InvokeXuenTheWhiteTiger].remains > 50 or timeToDie <= 30) then
		return WW.SummonWhiteTigerStatue;
	end

	-- invoke_xuen_the_white_tiger,if=!variable.hold_xuen&target.time_to_die>25&talent.bonedust_brew&cooldown.bonedust_brew.remains<=5&(active_enemies<3&chi>=3|active_enemies>=3&chi>=2)|fight_remains<25;
	if talents[WW.InvokeXuenTheWhiteTiger] and cooldown[WW.InvokeXuenTheWhiteTiger].ready and (not holdXuen and timeToDie > 25 and talents[WW.BonedustBrew] and cooldown[WW.BonedustBrew].remains <= 5 and ( targets < 3 and chi >= 3 or targets >= 3 and chi >= 2 ) or timeToDie < 25) then
		return WW.InvokeXuenTheWhiteTiger;
	end

	-- invoke_xuen_the_white_tiger,if=!variable.hold_xuen&target.time_to_die>25&!talent.bonedust_brew&(cooldown.rising_sun_kick.remains<2)&chi>=3;
	if talents[WW.InvokeXuenTheWhiteTiger] and cooldown[WW.InvokeXuenTheWhiteTiger].ready and (not holdXuen and timeToDie > 25 and not talents[WW.BonedustBrew] and ( cooldown[WW.RisingSunKick].remains < 2 ) and chi >= 3) then
		return WW.InvokeXuenTheWhiteTiger;
	end

	-- storm_earth_and_fire,if=talent.bonedust_brew&(fight_remains<30&cooldown.bonedust_brew.remains<4&chi>=4|buff.bonedust_brew.up|!spinning_crane_kick.max&active_enemies>=3&cooldown.bonedust_brew.remains<=2&chi>=2)&(pet.xuen_the_white_tiger.active|cooldown.invoke_xuen_the_white_tiger.remains>cooldown.storm_earth_and_fire.full_recharge_time);
	if talents[WW.StormEarthAndFire] and cooldown[WW.StormEarthAndFire].ready and (talents[WW.BonedustBrew] and ( timeToDie < 30 and cooldown[WW.BonedustBrew].remains < 4 and chi >= 4 or buff[WW.BonedustBrew].up or not targets >= 3 and cooldown[WW.BonedustBrew].remains <= 2 and chi >= 2 ) and ( petXuen or cooldown[WW.InvokeXuenTheWhiteTiger].remains > cooldown[WW.StormEarthAndFire].fullRecharge )) then
		return WW.StormEarthAndFire;
	end

	-- storm_earth_and_fire,if=!talent.bonedust_brew&(pet.xuen_the_white_tiger.active|target.time_to_die>15&cooldown.storm_earth_and_fire.full_recharge_time<cooldown.invoke_xuen_the_white_tiger.remains);
	if talents[WW.StormEarthAndFire] and cooldown[WW.StormEarthAndFire].ready and (not talents[WW.BonedustBrew] and ( petXuen or timeToDie > 15 and cooldown[WW.StormEarthAndFire].fullRecharge < cooldown[WW.InvokeXuenTheWhiteTiger].remains )) then
		return WW.StormEarthAndFire;
	end

	-- bonedust_brew,if=(!buff.bonedust_brew.up&buff.storm_earth_and_fire.up&buff.storm_earth_and_fire.remains<11&spinning_crane_kick.max)|(!buff.bonedust_brew.up&fight_remains<30&fight_remains>10&spinning_crane_kick.max&chi>=4)|fight_remains<10|(!debuff.skyreach_exhaustion.up&active_enemies>=4&spinning_crane_kick.modifier>=2)|(pet.xuen_the_white_tiger.active&spinning_crane_kick.max&active_enemies>=4);
	if talents[WW.BonedustBrew] and cooldown[WW.BonedustBrew].ready and (( not buff[WW.BonedustBrew].up and buff[WW.StormEarthAndFire].up and buff[WW.StormEarthAndFire].remains < 11 ) or ( not buff[WW.BonedustBrew].up and timeToDie < 30 and timeToDie > 10 and chi >= 4 ) or timeToDie < 10 or ( not debuff[WW.SkyreachExhaustion].up and targets >= 4 and 2 ) or ( petXuen and targets >= 4 )) then
		return WW.BonedustBrew;
	end

	-- call_action_list,name=bdb_setup,if=!buff.bonedust_brew.up&talent.bonedust_brew&cooldown.bonedust_brew.remains<=2&(fight_remains>60&(cooldown.storm_earth_and_fire.charges>0|cooldown.storm_earth_and_fire.remains>10)&(pet.xuen_the_white_tiger.active|cooldown.invoke_xuen_the_white_tiger.remains>10|variable.hold_xuen)|((pet.xuen_the_white_tiger.active|cooldown.invoke_xuen_the_white_tiger.remains>13)&(cooldown.storm_earth_and_fire.charges>0|cooldown.storm_earth_and_fire.remains>13|buff.storm_earth_and_fire.up)));
	if not buff[WW.BonedustBrew].up and talents[WW.BonedustBrew] and cooldown[WW.BonedustBrew].remains <= 2 and ( timeToDie > 60 and ( cooldown[WW.StormEarthAndFire].charges > 0 or cooldown[WW.StormEarthAndFire].remains > 10 ) and ( petXuen or cooldown[WW.InvokeXuenTheWhiteTiger].remains > 10 or holdXuen ) or ( ( petXuen or cooldown[WW.InvokeXuenTheWhiteTiger].remains > 13 ) and ( cooldown[WW.StormEarthAndFire].charges > 0 or cooldown[WW.StormEarthAndFire].remains > 13 or buff[WW.StormEarthAndFire].up ) ) ) then
		local result = Monk:WindwalkerBdbSetup();
		if result then
			return result;
		end
	end

	-- storm_earth_and_fire,if=fight_remains<20|(cooldown.storm_earth_and_fire.charges=2&cooldown.invoke_xuen_the_white_tiger.remains>cooldown.storm_earth_and_fire.full_recharge_time)&cooldown.fists_of_fury.remains<=9&chi>=2&cooldown.whirling_dragon_punch.remains<=12;
	if talents[WW.StormEarthAndFire] and cooldown[WW.StormEarthAndFire].ready and (timeToDie < 20 or ( cooldown[WW.StormEarthAndFire].charges == 2 and cooldown[WW.InvokeXuenTheWhiteTiger].remains > cooldown[WW.StormEarthAndFire].fullRecharge ) and cooldown[WW.FistsOfFury].remains <= 9 and chi >= 2 and cooldown[WW.WhirlingDragonPunch].remains <= 12) then
		return WW.StormEarthAndFire;
	end

	-- touch_of_death,target_if=max:target.health,if=fight_style.dungeonroute&!buff.serenity.up&(combo_strike&target.health<health)|(buff.hidden_masters_forbidden_touch.remains<2)|(buff.hidden_masters_forbidden_touch.remains>target.time_to_die);
	if cooldown[WW.TouchOfDeath].ready and (not buff[WW.Serenity].up and ( comboStrike and targetHp < health ) or ( buff[WW.HiddenMastersForbiddenTouch].remains < 2 ) or ( buff[WW.HiddenMastersForbiddenTouch].remains > timeToDie )) then
		return WW.TouchOfDeath;
	end

	-- touch_of_death,cycle_targets=1,if=fight_style.dungeonroute&combo_strike&(target.time_to_die>60|debuff.bonedust_brew_debuff.up|fight_remains<10);
	if cooldown[WW.TouchOfDeath].ready and (comboStrike and ( timeToDie > 60 or debuff[WW.BonedustBrewDebuff].up or timeToDie < 10 )) then
		return WW.TouchOfDeath;
	end

	-- touch_of_death,cycle_targets=1,if=!fight_style.dungeonroute&combo_strike;
	if cooldown[WW.TouchOfDeath].ready and (not comboStrike) then
		return WW.TouchOfDeath;
	end

	-- touch_of_karma,target_if=max:target.time_to_die,if=fight_remains>90|pet.xuen_the_white_tiger.active|variable.hold_xuen|fight_remains<16;
	if talents[WW.TouchOfKarma] and cooldown[WW.TouchOfKarma].ready and (timeToDie > 90 or petXuen or holdXuen or timeToDie < 16) then
		return WW.TouchOfKarma;
	end
end

function Monk:WindwalkerCdSerenity()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local timeToDie = fd.timeToDie;

	-- summon_white_tiger_statue,if=!cooldown.invoke_xuen_the_white_tiger.remains|active_enemies>4|cooldown.invoke_xuen_the_white_tiger.remains>50|fight_remains<=30;
	if talents[WW.SummonWhiteTigerStatue] and cooldown[WW.SummonWhiteTigerStatue].ready and (not cooldown[WW.InvokeXuenTheWhiteTiger].remains or targets > 4 or cooldown[WW.InvokeXuenTheWhiteTiger].remains > 50 or timeToDie <= 30) then
		return WW.SummonWhiteTigerStatue;
	end

	-- invoke_xuen_the_white_tiger,if=!variable.hold_xuen&talent.bonedust_brew&cooldown.bonedust_brew.remains<=5&target.time_to_die>25|fight_remains<25;
	if talents[WW.InvokeXuenTheWhiteTiger] and cooldown[WW.InvokeXuenTheWhiteTiger].ready and (not holdXuen and talents[WW.BonedustBrew] and cooldown[WW.BonedustBrew].remains <= 5 and timeToDie > 25 or timeToDie < 25) then
		return WW.InvokeXuenTheWhiteTiger;
	end

	-- invoke_xuen_the_white_tiger,if=!variable.hold_xuen&!talent.bonedust_brew&(cooldown.rising_sun_kick.remains<2)&target.time_to_die>25|fight_remains<25;
	if talents[WW.InvokeXuenTheWhiteTiger] and cooldown[WW.InvokeXuenTheWhiteTiger].ready and (not holdXuen and not talents[WW.BonedustBrew] and ( cooldown[WW.RisingSunKick].remains < 2 ) and timeToDie > 25 or timeToDie < 25) then
		return WW.InvokeXuenTheWhiteTiger;
	end

	-- bonedust_brew,if=!buff.bonedust_brew.up&(cooldown.serenity.up|cooldown.serenity.remains>15|fight_remains<30&fight_remains>10)|fight_remains<10;
	if talents[WW.BonedustBrew] and cooldown[WW.BonedustBrew].ready and (not buff[WW.BonedustBrew].up and ( cooldown[WW.Serenity].up or cooldown[WW.Serenity].remains > 15 or timeToDie < 30 and timeToDie > 10 ) or timeToDie < 10) then
		return WW.BonedustBrew;
	end

	-- serenity,if=pet.xuen_the_white_tiger.active|!talent.invoke_xuen_the_white_tiger|fight_remains<15;
	if talents[WW.Serenity] and cooldown[WW.Serenity].ready and (petXuen or not talents[WW.InvokeXuenTheWhiteTiger] or timeToDie < 15) then
		return WW.Serenity;
	end

	-- touch_of_death,target_if=max:target.health,if=fight_style.dungeonroute&!buff.serenity.up&(combo_strike&target.health<health)|(buff.hidden_masters_forbidden_touch.remains<2)|(buff.hidden_masters_forbidden_touch.remains>target.time_to_die);
	if cooldown[WW.TouchOfDeath].ready and (not buff[WW.Serenity].up and ( comboStrike and targetHp < health ) or ( buff[WW.HiddenMastersForbiddenTouch].remains < 2 ) or ( buff[WW.HiddenMastersForbiddenTouch].remains > timeToDie )) then
		return WW.TouchOfDeath;
	end

	-- touch_of_death,cycle_targets=1,if=fight_style.dungeonroute&combo_strike&(target.time_to_die>60|debuff.bonedust_brew_debuff.up|fight_remains<10)&!buff.serenity.up;
	if cooldown[WW.TouchOfDeath].ready and (comboStrike and ( timeToDie > 60 or debuff[WW.BonedustBrewDebuff].up or timeToDie < 10 ) and not buff[WW.Serenity].up) then
		return WW.TouchOfDeath;
	end

	-- touch_of_death,cycle_targets=1,if=!fight_style.dungeonroute&combo_strike&!buff.serenity.up;
	if cooldown[WW.TouchOfDeath].ready and (not comboStrike and not buff[WW.Serenity].up) then
		return WW.TouchOfDeath;
	end

	-- touch_of_karma,if=fight_remains>90|fight_remains<10;
	if talents[WW.TouchOfKarma] and cooldown[WW.TouchOfKarma].ready and (timeToDie > 90 or timeToDie < 10) then
		return WW.TouchOfKarma;
	end
end

function Monk:WindwalkerCleave()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local chi = UnitPower('player', Enum.PowerType.Chi);
	local chiMax = UnitPowerMax('player', Enum.PowerType.Chi);
	local chiPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local chiRegen = select(2,GetPowerRegen());
	local chiRegenCombined = chiRegen + chi;
	local chiDeficit = UnitPowerMax('player', Enum.PowerType.Chi) - chi;
	local chiTimeToMax = chiMax - chi / chiRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.stack=3&talent.shadowboxing_treads;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (buff[WW.TeachingsOfTheMonastery].count == 3 and talents[WW.ShadowboxingTreads]) then
		return WW.BlackoutKick;
	end

	-- spinning_crane_kick,if=combo_strike&buff.dance_of_chiji.up;
	if chi >= 2 and mana >= 0 and energy >= 0 and (comboStrike and buff[WW.DanceOfChiji].up) then
		return WW.SpinningCraneKick;
	end

	-- strike_of_the_windlord,if=talent.thunderfist;
	if talents[WW.StrikeOfTheWindlord] and cooldown[WW.StrikeOfTheWindlord].ready and chi >= 2 and (talents[WW.Thunderfist]) then
		return WW.StrikeOfTheWindlord;
	end

	-- fists_of_fury;
	if talents[WW.FistsOfFury] and cooldown[WW.FistsOfFury].ready and chi >= 3 then
		return WW.FistsOfFury;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.bonedust_brew.up&buff.pressure_point.up&set_bonus.tier30_2pc;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (buff[WW.BonedustBrew].up and buff[WW.PressurePoint].up and MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2)) then
		return WW.RisingSunKick;
	end

	-- spinning_crane_kick,if=buff.bonedust_brew.up&combo_strike;
	if chi >= 2 and mana >= 0 and energy >= 0 and (buff[WW.BonedustBrew].up and comboStrike) then
		return WW.SpinningCraneKick;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!buff.bonedust_brew.up&buff.pressure_point.up;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (not buff[WW.BonedustBrew].up and buff[WW.PressurePoint].up) then
		return WW.RisingSunKick;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=set_bonus.tier30_2pc;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2)) then
		return WW.RisingSunKick;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.stack=2;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (buff[WW.TeachingsOfTheMonastery].count == 2) then
		return WW.BlackoutKick;
	end

	-- strike_of_the_windlord;
	if talents[WW.StrikeOfTheWindlord] and cooldown[WW.StrikeOfTheWindlord].ready and chi >= 2 then
		return WW.StrikeOfTheWindlord;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.up&(talent.shadowboxing_treads|cooldown.rising_sun_kick.remains>1);
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (buff[WW.TeachingsOfTheMonastery].up and ( talents[WW.ShadowboxingTreads] or cooldown[WW.RisingSunKick].remains > 1 )) then
		return WW.BlackoutKick;
	end

	-- whirling_dragon_punch;
	if talents[WW.WhirlingDragonPunch] and cooldown[WW.WhirlingDragonPunch].ready then
		return WW.WhirlingDragonPunch;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.stack=3;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (buff[WW.TeachingsOfTheMonastery].count == 3) then
		return WW.BlackoutKick;
	end

	-- spinning_crane_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&cooldown.fists_of_fury.remains<3&buff.chi_energy.stack>15;
	if chi >= 2 and mana >= 0 and energy >= 0 and (comboStrike and cooldown[WW.FistsOfFury].remains < 3 and buff[WW.ChiEnergy].count > 15) then
		return WW.SpinningCraneKick;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=cooldown.fists_of_fury.remains>4&chi>3;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (cooldown[WW.FistsOfFury].remains > 4 and chi > 3) then
		return WW.RisingSunKick;
	end

	-- spinning_crane_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&cooldown.rising_sun_kick.remains&cooldown.fists_of_fury.remains&chi>4&((talent.storm_earth_and_fire&!talent.bonedust_brew)|(talent.serenity));
	if chi >= 2 and mana >= 0 and energy >= 0 and (comboStrike and cooldown[WW.RisingSunKick].remains and cooldown[WW.FistsOfFury].remains and chi > 4 and ( ( talents[WW.StormEarthAndFire] and not talents[WW.BonedustBrew] ) or ( talents[WW.Serenity] ) )) then
		return WW.SpinningCraneKick;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&cooldown.fists_of_fury.remains;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (comboStrike and cooldown[WW.FistsOfFury].remains) then
		return WW.BlackoutKick;
	end

	-- rushing_jade_wind,if=!buff.rushing_jade_wind.up;
	if talents[WW.RushingJadeWind] and cooldown[WW.RushingJadeWind].ready and chi >= 1 and (not buff[WW.RushingJadeWind].up) then
		return WW.RushingJadeWind;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&talent.shadowboxing_treads&!spinning_crane_kick.max;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (comboStrike and talents[WW.ShadowboxingTreads] ) then
		return WW.BlackoutKick;
	end

	-- spinning_crane_kick,target_if=min:debuff.mark_of_the_crane.remains,if=(combo_strike&chi>5&talent.storm_earth_and_fire|combo_strike&chi>4&talent.serenity);
	if chi >= 2 and mana >= 0 and energy >= 0 and (( comboStrike and chi > 5 and talents[WW.StormEarthAndFire] or comboStrike and chi > 4 and talents[WW.Serenity] )) then
		return WW.SpinningCraneKick;
	end
end

function Monk:WindwalkerFallthru()
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
	local timeToDie = fd.timeToDie;
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;
	local chi = UnitPower('player', Enum.PowerType.Chi);
	local chiMax = UnitPowerMax('player', Enum.PowerType.Chi);
	local chiPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local chiRegen = select(2,GetPowerRegen());
	local chiRegenCombined = chiRegen + chi;
	local chiDeficit = UnitPowerMax('player', Enum.PowerType.Chi) - chi;
	local chiTimeToMax = chiMax - chi / chiRegen;

	-- crackling_jade_lightning,if=buff.the_emperors_capacitor.stack>19&energy.time_to_max>execute_time-1&cooldown.rising_sun_kick.remains>execute_time|buff.the_emperors_capacitor.stack>14&(cooldown.serenity.remains<5&talent.serenity|fight_remains<5);
	if energy >= 0 and (buff[WW.TheEmperorsCapacitor].count > 19 and energyTimeToMax > timeShift - 1 and cooldown[WW.RisingSunKick].remains > timeShift or buff[WW.TheEmperorsCapacitor].count > 14 and ( cooldown[WW.Serenity].remains < 5 and talents[WW.Serenity] or timeToDie < 5 )) then
		return WW.CracklingJadeLightning;
	end

	-- faeline_stomp,if=combo_strike;
	if talents[WW.FaelineStomp] and cooldown[WW.FaelineStomp].ready and mana >= 0 and (comboStrike) then
		return WW.FaelineStomp;
	end

	-- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains+(debuff.skyreach_exhaustion.up*20),if=combo_strike&chi.max-chi>=(2+buff.power_strikes.up);
	if energy >= 50 and (comboStrike and chiMax - chi >= ( 2 + buff[WW.PowerStrikes].up )) then
		return WW.TigerPalm;
	end

	-- expel_harm,if=chi.max-chi>=1&active_enemies>2;
	if cooldown[WW.ExpelHarm].ready and energy >= 0 and mana >= 0 and (chiMax - chi >= 1 and targets > 2) then
		return WW.ExpelHarm;
	end

	-- chi_burst,if=chi.max-chi>=1&active_enemies=1&raid_event.adds.in>20|chi.max-chi>=2&active_enemies>=2;
	if talents[WW.ChiBurst] and cooldown[WW.ChiBurst].ready and currentSpell ~= WW.ChiBurst and (chiMax - chi >= 1 and targets == 1 or chiMax - chi >= 2 and targets >= 2) then
		return WW.ChiBurst;
	end

	-- chi_wave;
	if talents[WW.ChiWave] and cooldown[WW.ChiWave].ready then
		return WW.ChiWave;
	end

	-- expel_harm,if=chi.max-chi>=1;
	if cooldown[WW.ExpelHarm].ready and energy >= 0 and mana >= 0 and (chiMax - chi >= 1) then
		return WW.ExpelHarm;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&active_enemies>=5;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (comboStrike and targets >= 5) then
		return WW.BlackoutKick;
	end

	-- spinning_crane_kick,if=combo_strike&buff.chi_energy.stack>30-5*active_enemies&buff.storm_earth_and_fire.down&(cooldown.rising_sun_kick.remains>2&cooldown.fists_of_fury.remains>2|cooldown.rising_sun_kick.remains<3&cooldown.fists_of_fury.remains>3&chi>3|cooldown.rising_sun_kick.remains>3&cooldown.fists_of_fury.remains<3&chi>4|chi.max-chi<=1&energy.time_to_max<2)|buff.chi_energy.stack>10&fight_remains<7;
	if chi >= 2 and mana >= 0 and energy >= 0 and (comboStrike and buff[WW.ChiEnergy].count > 30 - 5 * targets and not buff[WW.StormEarthAndFire].up and ( cooldown[WW.RisingSunKick].remains > 2 and cooldown[WW.FistsOfFury].remains > 2 or cooldown[WW.RisingSunKick].remains < 3 and cooldown[WW.FistsOfFury].remains > 3 and chi > 3 or cooldown[WW.RisingSunKick].remains > 3 and cooldown[WW.FistsOfFury].remains < 3 and chi > 4 or chiMax - chi <= 1 and energyTimeToMax < 2 ) or buff[WW.ChiEnergy].count > 10 and timeToDie < 7) then
		return WW.SpinningCraneKick;
	end

	-- tiger_palm;
	if energy >= 50 then
		return WW.TigerPalm;
	end
end

function Monk:WindwalkerHeavyAoe()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local chi = UnitPower('player', Enum.PowerType.Chi);
	local chiMax = UnitPowerMax('player', Enum.PowerType.Chi);
	local chiPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local chiRegen = select(2,GetPowerRegen());
	local chiRegenCombined = chiRegen + chi;
	local chiDeficit = UnitPowerMax('player', Enum.PowerType.Chi) - chi;
	local chiTimeToMax = chiMax - chi / chiRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;

	-- spinning_crane_kick,if=combo_strike&buff.dance_of_chiji.up&spinning_crane_kick.max;
	if chi >= 2 and mana >= 0 and energy >= 0 and (comboStrike and buff[WW.DanceOfChiji].up ) then
		return WW.SpinningCraneKick;
	end

	-- strike_of_the_windlord,if=talent.thunderfist;
	if talents[WW.StrikeOfTheWindlord] and cooldown[WW.StrikeOfTheWindlord].ready and chi >= 2 and (talents[WW.Thunderfist]) then
		return WW.StrikeOfTheWindlord;
	end

	-- whirling_dragon_punch,if=active_enemies>8;
	if talents[WW.WhirlingDragonPunch] and cooldown[WW.WhirlingDragonPunch].ready and (targets > 8) then
		return WW.WhirlingDragonPunch;
	end

	-- fists_of_fury;
	if talents[WW.FistsOfFury] and cooldown[WW.FistsOfFury].ready and chi >= 3 then
		return WW.FistsOfFury;
	end

	-- spinning_crane_kick,if=buff.bonedust_brew.up&combo_strike&spinning_crane_kick.max;
	if chi >= 2 and mana >= 0 and energy >= 0 and (buff[WW.BonedustBrew].up and comboStrike ) then
		return WW.SpinningCraneKick;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.bonedust_brew.up&buff.pressure_point.up&set_bonus.tier30_2pc;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (buff[WW.BonedustBrew].up and buff[WW.PressurePoint].up and MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2)) then
		return WW.RisingSunKick;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.stack=3&talent.shadowboxing_treads;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (buff[WW.TeachingsOfTheMonastery].count == 3 and talents[WW.ShadowboxingTreads]) then
		return WW.BlackoutKick;
	end

	-- whirling_dragon_punch,if=active_enemies>=5;
	if talents[WW.WhirlingDragonPunch] and cooldown[WW.WhirlingDragonPunch].ready and (targets >= 5) then
		return WW.WhirlingDragonPunch;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.pressure_point.up&set_bonus.tier30_2pc;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (buff[WW.PressurePoint].up and MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2)) then
		return WW.RisingSunKick;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=set_bonus.tier30_2pc;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2)) then
		return WW.RisingSunKick;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=talent.whirling_dragon_punch&cooldown.whirling_dragon_punch.remains<3&cooldown.fists_of_fury.remains>3&!buff.kicks_of_flowing_momentum.up;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (talents[WW.WhirlingDragonPunch] and cooldown[WW.WhirlingDragonPunch].remains < 3 and cooldown[WW.FistsOfFury].remains > 3 and not buff[WW.KicksOfFlowingMomentum].up) then
		return WW.RisingSunKick;
	end

	-- spinning_crane_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&cooldown.fists_of_fury.remains<5&buff.chi_energy.stack>10;
	if chi >= 2 and mana >= 0 and energy >= 0 and (comboStrike and cooldown[WW.FistsOfFury].remains < 5 and buff[WW.ChiEnergy].count > 10) then
		return WW.SpinningCraneKick;
	end

	-- spinning_crane_kick,if=combo_strike&(cooldown.fists_of_fury.remains>3|chi>2)&spinning_crane_kick.max&buff.bloodlust.up;
	if chi >= 2 and mana >= 0 and energy >= 0 and (comboStrike and ( cooldown[WW.FistsOfFury].remains > 3 or chi > 2 ) and buff[WW.Bloodlust].up) then
		return WW.SpinningCraneKick;
	end

	-- spinning_crane_kick,if=combo_strike&(cooldown.fists_of_fury.remains>3|chi>2)&spinning_crane_kick.max&buff.invokers_delight.up;
	if chi >= 2 and mana >= 0 and energy >= 0 and (comboStrike and ( cooldown[WW.FistsOfFury].remains > 3 or chi > 2 ) and buff[WW.InvokersDelight].up) then
		return WW.SpinningCraneKick;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=talent.shadowboxing_treads&combo_strike&set_bonus.tier30_2pc&!buff.bonedust_brew.up&active_enemies<15&!talent.crane_vortex;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (talents[WW.ShadowboxingTreads] and comboStrike and MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2) and not buff[WW.BonedustBrew].up and targets < 15 and not talents[WW.CraneVortex]) then
		return WW.BlackoutKick;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=talent.shadowboxing_treads&combo_strike&set_bonus.tier30_2pc&!buff.bonedust_brew.up&active_enemies<8;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (talents[WW.ShadowboxingTreads] and comboStrike and MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2) and not buff[WW.BonedustBrew].up and targets < 8) then
		return WW.BlackoutKick;
	end

	-- spinning_crane_kick,if=combo_strike&(cooldown.fists_of_fury.remains>3|chi>4)&spinning_crane_kick.max;
	if chi >= 2 and mana >= 0 and energy >= 0 and (comboStrike and ( cooldown[WW.FistsOfFury].remains > 3 or chi > 4 ) ) then
		return WW.SpinningCraneKick;
	end

	-- rushing_jade_wind,if=!buff.rushing_jade_wind.up;
	if talents[WW.RushingJadeWind] and cooldown[WW.RushingJadeWind].ready and chi >= 1 and (not buff[WW.RushingJadeWind].up) then
		return WW.RushingJadeWind;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.stack=3;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (buff[WW.TeachingsOfTheMonastery].count == 3) then
		return WW.BlackoutKick;
	end

	-- strike_of_the_windlord;
	if talents[WW.StrikeOfTheWindlord] and cooldown[WW.StrikeOfTheWindlord].ready and chi >= 2 then
		return WW.StrikeOfTheWindlord;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=talent.shadowboxing_treads&combo_strike&!spinning_crane_kick.max;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (talents[WW.ShadowboxingTreads] and comboStrike ) then
		return WW.BlackoutKick;
	end

	-- chi_burst,if=chi.max-chi>=1&active_enemies=1&raid_event.adds.in>20|chi.max-chi>=2;
	if talents[WW.ChiBurst] and cooldown[WW.ChiBurst].ready and currentSpell ~= WW.ChiBurst and (chiMax - chi >= 1 and targets == 1 or chiMax - chi >= 2) then
		return WW.ChiBurst;
	end
end

function Monk:WindwalkerOpener()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local chi = UnitPower('player', Enum.PowerType.Chi);
	local chiMax = UnitPowerMax('player', Enum.PowerType.Chi);
	local chiPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local chiRegen = select(2,GetPowerRegen());
	local chiRegenCombined = chiRegen + chi;
	local chiDeficit = UnitPowerMax('player', Enum.PowerType.Chi) - chi;
	local chiTimeToMax = chiMax - chi / chiRegen;
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- summon_white_tiger_statue;
	if talents[WW.SummonWhiteTigerStatue] and cooldown[WW.SummonWhiteTigerStatue].ready then
		return WW.SummonWhiteTigerStatue;
	end

	-- expel_harm,if=talent.chi_burst.enabled&chi.max-chi>=3;
	if cooldown[WW.ExpelHarm].ready and energy >= 0 and mana >= 0 and (talents[WW.ChiBurst] and chiMax - chi >= 3) then
		return WW.ExpelHarm;
	end

	-- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains+(debuff.skyreach_exhaustion.up*20),if=combo_strike&chi.max-chi>=(2+buff.power_strikes.up);
	if energy >= 50 and (comboStrike and chiMax - chi >= ( 2 + buff[WW.PowerStrikes].up )) then
		return WW.TigerPalm;
	end

	-- expel_harm,if=talent.chi_burst.enabled&chi=3;
	if cooldown[WW.ExpelHarm].ready and energy >= 0 and mana >= 0 and (talents[WW.ChiBurst] and chi == 3) then
		return WW.ExpelHarm;
	end

	-- chi_wave,if=chi.max-chi=2;
	if talents[WW.ChiWave] and cooldown[WW.ChiWave].ready and (chiMax - chi == 2) then
		return WW.ChiWave;
	end

	-- expel_harm;
	if cooldown[WW.ExpelHarm].ready and energy >= 0 and mana >= 0 then
		return WW.ExpelHarm;
	end

	-- chi_burst,if=chi>1&chi.max-chi>=2;
	if talents[WW.ChiBurst] and cooldown[WW.ChiBurst].ready and currentSpell ~= WW.ChiBurst and (chi > 1 and chiMax - chi >= 2) then
		return WW.ChiBurst;
	end
end

function Monk:WindwalkerSerenity()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local timeToDie = fd.timeToDie;
	local chi = UnitPower('player', Enum.PowerType.Chi);
	local chiMax = UnitPowerMax('player', Enum.PowerType.Chi);
	local chiPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local chiRegen = select(2,GetPowerRegen());
	local chiRegenCombined = chiRegen + chi;
	local chiDeficit = UnitPowerMax('player', Enum.PowerType.Chi) - chi;
	local chiTimeToMax = chiMax - chi / chiRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;

	-- fists_of_fury,if=buff.serenity.remains<1;
	if talents[WW.FistsOfFury] and cooldown[WW.FistsOfFury].ready and chi >= 3 and (buff[WW.Serenity].remains < 1) then
		return WW.FistsOfFury;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&!spinning_crane_kick.max&active_enemies>4&talent.shdaowboxing_treads;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (comboStrike and not targets > 4 and talents[WW.ShdaowboxingTreads]) then
		return WW.BlackoutKick;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&buff.teachings_of_the_monastery.stack=3&buff.teachings_of_the_monastery.remains<1;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (comboStrike and buff[WW.TeachingsOfTheMonastery].count == 3 and buff[WW.TeachingsOfTheMonastery].remains < 1) then
		return WW.BlackoutKick;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=active_enemies=4&buff.pressure_point.up&!talent.bonedust_brew;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (targets == 4 and buff[WW.PressurePoint].up and not talents[WW.BonedustBrew]) then
		return WW.RisingSunKick;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=active_enemies=1;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (targets == 1) then
		return WW.RisingSunKick;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=active_enemies<=3&buff.pressure_point.up;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (targets <= 3 and buff[WW.PressurePoint].up) then
		return WW.RisingSunKick;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.pressure_point.up&set_bonus.tier30_2pc;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (buff[WW.PressurePoint].up and MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2)) then
		return WW.RisingSunKick;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=set_bonus.tier30_2pc;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2)) then
		return WW.RisingSunKick;
	end

	-- fists_of_fury,if=buff.invokers_delight.up&active_enemies<3&talent.Jade_Ignition,interrupt=1;
	if talents[WW.FistsOfFury] and cooldown[WW.FistsOfFury].ready and chi >= 3 and (buff[WW.InvokersDelight].up and targets < 3 and talents[WW.JadeIgnition]) then
		return WW.FistsOfFury;
	end

	-- fists_of_fury,if=buff.bloodlust.up,interrupt=1;
	if talents[WW.FistsOfFury] and cooldown[WW.FistsOfFury].ready and chi >= 3 and (buff[WW.Bloodlust].up) then
		return WW.FistsOfFury;
	end

	-- fists_of_fury,if=buff.invokers_delight.up&active_enemies>4,interrupt=1;
	if talents[WW.FistsOfFury] and cooldown[WW.FistsOfFury].ready and chi >= 3 and (buff[WW.InvokersDelight].up and targets > 4) then
		return WW.FistsOfFury;
	end

	-- fists_of_fury,if=active_enemies=2,interrupt=1;
	if talents[WW.FistsOfFury] and cooldown[WW.FistsOfFury].ready and chi >= 3 and (targets == 2) then
		return WW.FistsOfFury;
	end

	-- fists_of_fury_cancel,target_if=max:target.time_to_die;
	--return WW.FistsOfFuryCancel;

	-- strike_of_the_windlord,if=talent.thunderfist;
	if talents[WW.StrikeOfTheWindlord] and cooldown[WW.StrikeOfTheWindlord].ready and chi >= 2 and (talents[WW.Thunderfist]) then
		return WW.StrikeOfTheWindlord;
	end

	-- spinning_crane_kick,if=combo_strike&buff.dance_of_chiji.up&active_enemies>=2;
	if chi >= 2 and mana >= 0 and energy >= 0 and (comboStrike and buff[WW.DanceOfChiji].up and targets >= 2) then
		return WW.SpinningCraneKick;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=active_enemies=4&buff.pressure_point.up;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (targets == 4 and buff[WW.PressurePoint].up) then
		return WW.RisingSunKick;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=active_enemies<6&combo_strike&set_bonus.tier30_2pc;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (targets < 6 and comboStrike and MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2)) then
		return WW.BlackoutKick;
	end

	-- spinning_crane_kick,if=combo_strike&active_enemies>=3&spinning_crane_kick.max;
	if chi >= 2 and mana >= 0 and energy >= 0 and (comboStrike and targets >= 3 ) then
		return WW.SpinningCraneKick;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&active_enemies>1&active_enemies<4&buff.teachings_of_the_monastery.stack=2;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (comboStrike and targets > 1 and targets < 4 and buff[WW.TeachingsOfTheMonastery].count == 2) then
		return WW.BlackoutKick;
	end

	-- rushing_jade_wind,if=!buff.rushing_jade_wind.up&active_enemies>=5;
	if talents[WW.RushingJadeWind] and cooldown[WW.RushingJadeWind].ready and chi >= 1 and (not buff[WW.RushingJadeWind].up and targets >= 5) then
		return WW.RushingJadeWind;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=talent.shadowboxing_treads&active_enemies>=3&combo_strike;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (talents[WW.ShadowboxingTreads] and targets >= 3 and comboStrike) then
		return WW.BlackoutKick;
	end

	-- spinning_crane_kick,if=combo_strike&(active_enemies>3|active_enemies>2&spinning_crane_kick.modifier>=2.3);
	if chi >= 2 and mana >= 0 and energy >= 0 and (comboStrike and ( targets > 3 or targets > 2 and 2.3 )) then
		return WW.SpinningCraneKick;
	end

	-- strike_of_the_windlord,if=active_enemies>=3;
	if talents[WW.StrikeOfTheWindlord] and cooldown[WW.StrikeOfTheWindlord].ready and chi >= 2 and (targets >= 3) then
		return WW.StrikeOfTheWindlord;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=active_enemies=2&cooldown.fists_of_fury.remains>5;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (targets == 2 and cooldown[WW.FistsOfFury].remains > 5) then
		return WW.RisingSunKick;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=active_enemies=2&cooldown.fists_of_fury.remains>5&talent.shadowboxing_treads&buff.teachings_of_the_monastery.stack=1&combo_strike;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (targets == 2 and cooldown[WW.FistsOfFury].remains > 5 and talents[WW.ShadowboxingTreads] and buff[WW.TeachingsOfTheMonastery].count == 1 and comboStrike) then
		return WW.BlackoutKick;
	end

	-- spinning_crane_kick,if=combo_strike&active_enemies>1;
	if chi >= 2 and mana >= 0 and energy >= 0 and (comboStrike and targets > 1) then
		return WW.SpinningCraneKick;
	end

	-- whirling_dragon_punch,if=active_enemies>1;
	if talents[WW.WhirlingDragonPunch] and cooldown[WW.WhirlingDragonPunch].ready and (targets > 1) then
		return WW.WhirlingDragonPunch;
	end

	-- rushing_jade_wind,if=!buff.rushing_jade_wind.up&active_enemies>=3;
	if talents[WW.RushingJadeWind] and cooldown[WW.RushingJadeWind].ready and chi >= 1 and (not buff[WW.RushingJadeWind].up and targets >= 3) then
		return WW.RushingJadeWind;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 then
		return WW.RisingSunKick;
	end

	-- spinning_crane_kick,if=combo_strike&buff.dance_of_chiji.up;
	if chi >= 2 and mana >= 0 and energy >= 0 and (comboStrike and buff[WW.DanceOfChiji].up) then
		return WW.SpinningCraneKick;
	end

	-- blackout_kick,if=combo_strike;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (comboStrike) then
		return WW.BlackoutKick;
	end

	-- whirling_dragon_punch;
	if talents[WW.WhirlingDragonPunch] and cooldown[WW.WhirlingDragonPunch].ready then
		return WW.WhirlingDragonPunch;
	end

	-- tiger_palm,target_if=min:debuff.mark_of_the_crane.remains,if=talent.teachings_of_the_monastery&buff.teachings_of_the_monastery.stack<3;
	if energy >= 50 and (talents[WW.TeachingsOfTheMonastery] and buff[WW.TeachingsOfTheMonastery].count < 3) then
		return WW.TigerPalm;
	end
end

function Monk:WindwalkerSt()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local timeToDie = fd.timeToDie;
	local chi = UnitPower('player', Enum.PowerType.Chi);
	local chiMax = UnitPowerMax('player', Enum.PowerType.Chi);
	local chiPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local chiRegen = select(2,GetPowerRegen());
	local chiRegenCombined = chiRegen + chi;
	local chiDeficit = UnitPowerMax('player', Enum.PowerType.Chi) - chi;
	local chiTimeToMax = chiMax - chi / chiRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;

	-- fists_of_fury,if=!buff.pressure_point.up&!cooldown.rising_sun_kick.remains;
	if talents[WW.FistsOfFury] and cooldown[WW.FistsOfFury].ready and chi >= 3 and (not buff[WW.PressurePoint].up and not cooldown[WW.RisingSunKick].remains) then
		return WW.FistsOfFury;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.pressure_point.up;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (buff[WW.PressurePoint].up) then
		return WW.RisingSunKick;
	end

	-- strike_of_the_windlord,if=talent.thunderfist&(cooldown.invoke_xuen_the_white_tiger.remains>10|fight_remains<5);
	if talents[WW.StrikeOfTheWindlord] and cooldown[WW.StrikeOfTheWindlord].ready and chi >= 2 and (talents[WW.Thunderfist] and ( cooldown[WW.InvokeXuenTheWhiteTiger].remains > 10 or timeToDie < 5 )) then
		return WW.StrikeOfTheWindlord;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.kicks_of_flowing_momentum.up|buff.pressure_point.up;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (buff[WW.KicksOfFlowingMomentum].up or buff[WW.PressurePoint].up) then
		return WW.RisingSunKick;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.stack=3;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (buff[WW.TeachingsOfTheMonastery].count == 3) then
		return WW.BlackoutKick;
	end

	-- fists_of_fury;
	if talents[WW.FistsOfFury] and cooldown[WW.FistsOfFury].ready and chi >= 3 then
		return WW.FistsOfFury;
	end

	-- rising_sun_kick;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 then
		return WW.RisingSunKick;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.stack=2;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (buff[WW.TeachingsOfTheMonastery].count == 2) then
		return WW.BlackoutKick;
	end

	-- strike_of_the_windlord,if=debuff.skyreach_exhaustion.remains>30|fight_remains<5;
	if talents[WW.StrikeOfTheWindlord] and cooldown[WW.StrikeOfTheWindlord].ready and chi >= 2 and (debuff[WW.SkyreachExhaustion].remains > 30 or timeToDie < 5) then
		return WW.StrikeOfTheWindlord;
	end

	-- spinning_crane_kick,if=combo_strike&buff.dance_of_chiji.up;
	if chi >= 2 and mana >= 0 and energy >= 0 and (comboStrike and buff[WW.DanceOfChiji].up) then
		return WW.SpinningCraneKick;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.up&cooldown.rising_sun_kick.remains>1;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (buff[WW.TeachingsOfTheMonastery].up and cooldown[WW.RisingSunKick].remains > 1) then
		return WW.BlackoutKick;
	end

	-- spinning_crane_kick,if=buff.bonedust_brew.up&combo_strike&spinning_crane_kick.modifier>=2.7;
	if chi >= 2 and mana >= 0 and energy >= 0 and (buff[WW.BonedustBrew].up and comboStrike and 2.7) then
		return WW.SpinningCraneKick;
	end

	-- whirling_dragon_punch;
	if talents[WW.WhirlingDragonPunch] and cooldown[WW.WhirlingDragonPunch].ready then
		return WW.WhirlingDragonPunch;
	end

	-- rushing_jade_wind,if=!buff.rushing_jade_wind.up;
	if talents[WW.RushingJadeWind] and cooldown[WW.RushingJadeWind].ready and chi >= 1 and (not buff[WW.RushingJadeWind].up) then
		return WW.RushingJadeWind;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (comboStrike) then
		return WW.BlackoutKick;
	end
end

function Monk:WindwalkerStCleave()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local chi = UnitPower('player', Enum.PowerType.Chi);
	local chiMax = UnitPowerMax('player', Enum.PowerType.Chi);
	local chiPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local chiRegen = select(2,GetPowerRegen());
	local chiRegenCombined = chiRegen + chi;
	local chiDeficit = UnitPowerMax('player', Enum.PowerType.Chi) - chi;
	local chiTimeToMax = chiMax - chi / chiRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.stack=3&talent.shadowboxing_treads;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (buff[WW.TeachingsOfTheMonastery].count == 3 and talents[WW.ShadowboxingTreads]) then
		return WW.BlackoutKick;
	end

	-- strike_of_the_windlord,if=talent.thunderfist;
	if talents[WW.StrikeOfTheWindlord] and cooldown[WW.StrikeOfTheWindlord].ready and chi >= 2 and (talents[WW.Thunderfist]) then
		return WW.StrikeOfTheWindlord;
	end

	-- fists_of_fury;
	if talents[WW.FistsOfFury] and cooldown[WW.FistsOfFury].ready and chi >= 3 then
		return WW.FistsOfFury;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=set_bonus.tier30_2pc;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2)) then
		return WW.RisingSunKick;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.kicks_of_flowing_momentum.up|buff.pressure_point.up;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (buff[WW.KicksOfFlowingMomentum].up or buff[WW.PressurePoint].up) then
		return WW.RisingSunKick;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.stack=2;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (buff[WW.TeachingsOfTheMonastery].count == 2) then
		return WW.BlackoutKick;
	end

	-- spinning_crane_kick,if=combo_strike&buff.dance_of_chiji.up;
	if chi >= 2 and mana >= 0 and energy >= 0 and (comboStrike and buff[WW.DanceOfChiji].up) then
		return WW.SpinningCraneKick;
	end

	-- strike_of_the_windlord;
	if talents[WW.StrikeOfTheWindlord] and cooldown[WW.StrikeOfTheWindlord].ready and chi >= 2 then
		return WW.StrikeOfTheWindlord;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.up&(talent.shadowboxing_treads|cooldown.rising_sun_kick.remains>1);
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (buff[WW.TeachingsOfTheMonastery].up and ( talents[WW.ShadowboxingTreads] or cooldown[WW.RisingSunKick].remains > 1 )) then
		return WW.BlackoutKick;
	end

	-- whirling_dragon_punch;
	if talents[WW.WhirlingDragonPunch] and cooldown[WW.WhirlingDragonPunch].ready then
		return WW.WhirlingDragonPunch;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=buff.teachings_of_the_monastery.stack=3;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (buff[WW.TeachingsOfTheMonastery].count == 3) then
		return WW.BlackoutKick;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains,if=!talent.shadowboxing_treads&cooldown.fists_of_fury.remains>4&talent.xuens_battlegear;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 and (not talents[WW.ShadowboxingTreads] and cooldown[WW.FistsOfFury].remains > 4 and talents[WW.XuensBattlegear]) then
		return WW.RisingSunKick;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike&cooldown.rising_sun_kick.remains&cooldown.fists_of_fury.remains&(!buff.bonedust_brew.up|spinning_crane_kick.modifier<1.5);
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (comboStrike and cooldown[WW.RisingSunKick].remains and cooldown[WW.FistsOfFury].remains and ( not buff[WW.BonedustBrew].up or 1.5 )) then
		return WW.BlackoutKick;
	end

	-- rushing_jade_wind,if=!buff.rushing_jade_wind.up;
	if talents[WW.RushingJadeWind] and cooldown[WW.RushingJadeWind].ready and chi >= 1 and (not buff[WW.RushingJadeWind].up) then
		return WW.RushingJadeWind;
	end

	-- spinning_crane_kick,if=buff.bonedust_brew.up&combo_strike&spinning_crane_kick.modifier>=2.7;
	if chi >= 2 and mana >= 0 and energy >= 0 and (buff[WW.BonedustBrew].up and comboStrike and 2.7) then
		return WW.SpinningCraneKick;
	end

	-- rising_sun_kick,target_if=min:debuff.mark_of_the_crane.remains;
	if talents[WW.RisingSunKick] and cooldown[WW.RisingSunKick].ready and chi >= 2 and mana >= 0 then
		return WW.RisingSunKick;
	end

	-- blackout_kick,target_if=min:debuff.mark_of_the_crane.remains,if=combo_strike;
	if cooldown[WW.BlackoutKick].ready and chi >= 1 and (comboStrike) then
		return WW.BlackoutKick;
	end

	-- spinning_crane_kick,target_if=min:debuff.mark_of_the_crane.remains,if=(combo_strike&chi>5&talent.storm_earth_and_fire|combo_strike&chi>4&talent.serenity);
	if chi >= 2 and mana >= 0 and energy >= 0 and (( comboStrike and chi > 5 and talents[WW.StormEarthAndFire] or comboStrike and chi > 4 and talents[WW.Serenity] )) then
		return WW.SpinningCraneKick;
	end
end

function Monk:WindwalkerTrinkets()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
end


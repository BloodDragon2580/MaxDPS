local _, addonTable = ...;

-- @type MaxDps;
if not MaxDps then return end;
local Deathknight = addonTable.Deathknight;
local MaxDps = MaxDps;

local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;

local itemID = GetInventoryItemID('player', INVSLOT_MAINHAND);

local mainHandSubClassID = itemID and  select(13, GetItemInfo(itemID));

local TwoHanderWepCheck = mainHandSubClassID and (mainHandSubClassID == 1 or mainHandSubClassID == 5 or mainHandSubClassID == 8 or mainHandSubClassID == 10);

local epidemicPriority
local gargSetup
local apocTiming
local festermightTracker
local popWounds
local poolingRunicPower
local stPlanning
local addsRemain

local UH = {
	RaiseDead = 46584,
	ArmyOfTheDead = 42650,
	DeathAndDecay = 43265,
	Epidemic = 207317,
	FesteringWound = 194310,
	FesteringStrike = 85948,
	DeathCoil = 47541,
	BurstingSores = 207264,
	Festermight = 377590,
	VileContagion = 390279,
	SummonGargoyle = 49206,
	AbominationLimb = 383269,
	Apocalypse = 275699,
	UnholyAssault = 207289,
	DarkTransformation = 63560,
	InfectedClaws = 207272,
	EmpowerRuneWeapon = 47568,
	SacrificialPact = 327574,
	CommanderOfTheDead = 390259,
	ArmyOfTheDamned = 276837,
	SoulReaper = 343294,
	MindFreeze = 47528,
	AntimagicShell = 48707,
	AntimagicZone = 51052,
	Assimilation = 374383,
	DeathRot = 377537,
	Plaguebringer = 390175,
	Superstrain = 390283,
	UnholyBlight = 115989,
	Morbidity = 377592,
	Outbreak = 77575,
	VirulentPlague = 191587,
	EbonFever = 207269,
	SuddenDoom = 49530,
	UnholyGround = 374265,
	ImprovedDeathCoil = 377580,
	CoilOfDevastation = 390270,
	RottenTouch = 390275,
};
local A = {
};
function DeathKnight:Unholy()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local debuff = fd.debuff;
	local targets = fd.targets and fd.targets or 1;
	local runeforge = fd.runeforge;

	-- call_action_list,name=variables;
	local result = DeathKnight:UnholyVariables();
	if result then
		return result;
	end

	-- call_action_list,name=high_prio_actions;
	local result = DeathKnight:UnholyHighPrioActions();
	if result then
		return result;
	end

	-- call_action_list,name=trinkets;

	-- run_action_list,name=garg_setup,if=variable.garg_setup=0;
	if gargSetup == 0 then
		return DeathKnight:UnholyGargSetup();
	end

	-- call_action_list,name=cooldowns,if=variable.st_planning;
	if stPlanning then
		local result = DeathKnight:UnholyCooldowns();
		if result then
			return result;
		end
	end

	-- call_action_list,name=aoe_cooldowns,if=variable.adds_remain;
	if addsRemain then
		local result = DeathKnight:UnholyAoeCooldowns();
		if result then
			return result;
		end
	end

	-- call_action_list,name=racials;

	-- call_action_list,name=aoe_setup,if=variable.adds_remain&cooldown.any_dnd.remains<10&!death_and_decay.ticking;
	if addsRemain and cooldown[UH.AnyDnd].remains < 10 and not debuff[UH.DeathAndDecay].up then
		local result = DeathKnight:UnholyAoeSetup();
		if result then
			return result;
		end
	end

	-- call_action_list,name=aoe_burst,if=active_enemies>=4&death_and_decay.ticking;
	if targets >= 4 and debuff[UH.DeathAndDecay].up then
		local result = DeathKnight:UnholyAoeBurst();
		if result then
			return result;
		end
	end

	-- call_action_list,name=aoe,if=active_enemies>=4&(cooldown.any_dnd.remains>10&!death_and_decay.ticking|!variable.adds_remain);
	if targets >= 4 and ( cooldown[UH.AnyDnd].remains > 10 and not debuff[UH.DeathAndDecay].up or not addsRemain ) then
		local result = DeathKnight:UnholyAoe();
		if result then
			return result;
		end
	end

	-- call_action_list,name=st,if=active_enemies<=3;
	if targets <= 3 then
		local result = DeathKnight:UnholySt();
		if result then
			return result;
		end
	end
end
function DeathKnight:UnholyAoe()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local timeToDie = fd.timeToDie;
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

	-- epidemic,if=!variable.pooling_runic_power|fight_remains<10;
	if talents[UH.Epidemic] and runicPower >= 30 and (not poolingRunicPower or timeToDie < 10) then
		return UH.Epidemic;
	end

	-- wound_spender,target_if=max:debuff.festering_wound.stack,if=variable.pop_wounds;
	if popWounds then
		return UH.WoundSpender;
	end

	-- festering_strike,target_if=max:debuff.festering_wound.stack,if=!variable.pop_wounds;
	if talents[UH.FesteringStrike] and runes >= 2 and runicPower >= 20 and (not popWounds) then
		return UH.FesteringStrike;
	end

	-- death_coil,if=!variable.pooling_runic_power&!talent.epidemic;
	if runicPower >= 30 and (not poolingRunicPower and not talents[UH.Epidemic]) then
		return UH.DeathCoil;
	end
end

function DeathKnight:UnholyAoeBurst()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
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

	-- epidemic,if=(!talent.bursting_sores|rune<1|talent.bursting_sores&debuff.festering_wound.stack=0)&!variable.pooling_runic_power&(active_enemies>=6|runic_power.deficit<30|buff.festermight.stack=20);
	if talents[UH.Epidemic] and runicPower >= 30 and (( not talents[UH.BurstingSores] or runes < 1 or talents[UH.BurstingSores] and debuff[UH.FesteringWound].count == 0 ) and not poolingRunicPower and ( targets >= 6 or runicPowerDeficit < 30 or buff[UH.Festermight].count == 20 )) then
		return UH.Epidemic;
	end

	-- wound_spender,target_if=max:debuff.festering_wound.stack,if=debuff.festering_wound.stack>=1;
	if debuff[UH.FesteringWound].count >= 1 then
		return UH.WoundSpender;
	end

	-- epidemic,if=!variable.pooling_runic_power|fight_remains<10;
	if talents[UH.Epidemic] and runicPower >= 30 and (not poolingRunicPower or timeToDie < 10) then
		return UH.Epidemic;
	end

	-- death_coil,if=!variable.pooling_runic_power&!talent.epidemic;
	if runicPower >= 30 and (not poolingRunicPower and not talents[UH.Epidemic]) then
		return UH.DeathCoil;
	end

	-- wound_spender;
	-- UH.WoundSpender;
end

function DeathKnight:UnholyAoeCooldowns()
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

	-- vile_contagion,target_if=max:debuff.festering_wound.stack,if=debuff.festering_wound.stack>=4&cooldown.any_dnd.remains<3;
	if talents[UH.VileContagion] and cooldown[UH.VileContagion].ready and runicPower >= 30 and (debuff[UH.FesteringWound].count >= 4 and cooldown[UH.AnyDnd].remains < 3) then
		return UH.VileContagion;
	end

	-- summon_gargoyle;
	if talents[UH.SummonGargoyle] and cooldown[UH.SummonGargoyle].ready then
		return UH.SummonGargoyle;
	end

	-- abomination_limb,if=rune<2|buff.festermight.stack>10|!talent.festermight|buff.festermight.up&buff.festermight.remains<12;
	if talents[UH.AbominationLimb] and cooldown[UH.AbominationLimb].ready and (runes < 2 or buff[UH.Festermight].count > 10 or not talents[UH.Festermight] or buff[UH.Festermight].up and buff[UH.Festermight].remains < 12) then
		return UH.AbominationLimb;
	end

	-- apocalypse,target_if=min:debuff.festering_wound.stack,if=talent.bursting_sores&debuff.festering_wound.up&(!death_and_decay.ticking&cooldown.death_and_decay.remains&rune<3|death_and_decay.ticking&rune=0)|!talent.bursting_sores&debuff.festering_wound.stack>=4;
	if talents[UH.Apocalypse] and cooldown[UH.Apocalypse].ready and (talents[UH.BurstingSores] and debuff[UH.FesteringWound].up and ( not debuff[UH.DeathAndDecay].up and cooldown[UH.DeathAndDecay].remains and runes < 3 or debuff[UH.DeathAndDecay].up and runes == 0 ) or not talents[UH.BurstingSores] and debuff[UH.FesteringWound].count >= 4) then
		return UH.Apocalypse;
	end

	-- unholy_assault,target_if=min:debuff.festering_wound.stack,if=debuff.festering_wound.stack<=2|buff.dark_transformation.up;
	if talents[UH.UnholyAssault] and cooldown[UH.UnholyAssault].ready and (debuff[UH.FesteringWound].count <= 2 or buff[UH.DarkTransformation].up) then
		return UH.UnholyAssault;
	end

	-- raise_dead,if=!pet.ghoul.active;
	if talents[UH.RaiseDead] and cooldown[UH.RaiseDead].ready and (not ghoulActive) then
		return UH.RaiseDead;
	end

	-- dark_transformation,if=(cooldown.any_dnd.remains<10&talent.infected_claws&((cooldown.vile_contagion.remains|raid_event.adds.exists&raid_event.adds.in>10)&death_knight.fwounded_targets<active_enemies|!talent.vile_contagion)&(raid_event.adds.remains>5|!raid_event.adds.exists)|!talent.infected_claws);
	if talents[UH.DarkTransformation] and cooldown[UH.DarkTransformation].ready and (( cooldown[UH.AnyDnd].remains < 10 and talents[UH.InfectedClaws] and ( ( cooldown[UH.VileContagion].remains or targets > 1 ) and fwoundedTargets < targets or not talents[UH.VileContagion] ) and ( raid_event.adds.remains > 5 or not targets > 1 ) or not talents[UH.InfectedClaws] )) then
		return UH.DarkTransformation;
	end

	-- empower_rune_weapon,if=buff.dark_transformation.up;
	if talents[UH.EmpowerRuneWeapon] and (buff[UH.DarkTransformation].up) then
		return UH.EmpowerRuneWeapon;
	end

	-- sacrificial_pact,if=!buff.dark_transformation.up&cooldown.dark_transformation.remains>6|fight_remains<gcd;
	if talents[UH.SacrificialPact] and cooldown[UH.SacrificialPact].ready and runicPower >= 20 and (not buff[UH.DarkTransformation].up and cooldown[UH.DarkTransformation].remains > 6 or timeToDie < gcd) then
		return UH.SacrificialPact;
	end
end

function DeathKnight:UnholyAoeSetup()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
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

	-- any_dnd,if=(!talent.bursting_sores|death_knight.fwounded_targets=active_enemies|death_knight.fwounded_targets>=8|raid_event.adds.exists&raid_event.adds.remains<=11&raid_event.adds.remains>5);
	if ( not talents[UH.BurstingSores] or fwoundedTargets == targets or fwoundedTargets >= 8 or targets > 1 and raid_event.adds.remains <= 11 and raid_event.adds.remains > 5 ) then
		return UH.AnyDnd;
	end

	-- festering_strike,target_if=min:debuff.festering_wound.stack,if=death_knight.fwounded_targets<active_enemies&talent.bursting_sores;
	if talents[UH.FesteringStrike] and runes >= 2 and runicPower >= 20 and (fwoundedTargets < targets and talents[UH.BurstingSores]) then
		return UH.FesteringStrike;
	end

	-- epidemic,if=!variable.pooling_runic_power|fight_remains<10;
	if talents[UH.Epidemic] and runicPower >= 30 and (not poolingRunicPower or timeToDie < 10) then
		return UH.Epidemic;
	end

	-- festering_strike,target_if=min:debuff.festering_wound.stack,if=death_knight.fwounded_targets<active_enemies;
	if talents[UH.FesteringStrike] and runes >= 2 and runicPower >= 20 and (fwoundedTargets < targets) then
		return UH.FesteringStrike;
	end

	-- festering_strike,target_if=max:debuff.festering_wound.stack,if=cooldown.apocalypse.remains<variable.apoc_timing&debuff.festering_wound.stack<4;
	if talents[UH.FesteringStrike] and runes >= 2 and runicPower >= 20 and (cooldown[UH.Apocalypse].remains < apocTiming and debuff[UH.FesteringWound].count < 4) then
		return UH.FesteringStrike;
	end

	-- death_coil,if=!variable.pooling_runic_power&!talent.epidemic;
	if runicPower >= 30 and (not poolingRunicPower and not talents[UH.Epidemic]) then
		return UH.DeathCoil;
	end
end

function DeathKnight:UnholyCooldowns()
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

	-- summon_gargoyle,if=buff.commander_of_the_dead.up|!talent.commander_of_the_dead;
	if talents[UH.SummonGargoyle] and cooldown[UH.SummonGargoyle].ready and (buff[UH.CommanderOfTheDead].up or not talents[UH.CommanderOfTheDead]) then
		return UH.SummonGargoyle;
	end

	-- raise_dead,if=!pet.ghoul.active;
	if talents[UH.RaiseDead] and cooldown[UH.RaiseDead].ready and (not ghoulActive) then
		return UH.RaiseDead;
	end

	-- dark_transformation,if=cooldown.apocalypse.remains<5;
	if talents[UH.DarkTransformation] and cooldown[UH.DarkTransformation].ready and (cooldown[UH.Apocalypse].remains < 5) then
		return UH.DarkTransformation;
	end

	-- apocalypse,target_if=max:debuff.festering_wound.stack,if=variable.st_planning&debuff.festering_wound.stack>=4;
	if talents[UH.Apocalypse] and cooldown[UH.Apocalypse].ready and (stPlanning and debuff[UH.FesteringWound].count >= 4) then
		return UH.Apocalypse;
	end

	-- empower_rune_weapon,if=variable.st_planning&(pet.gargoyle.active&pet.gargoyle.remains<=23|!talent.summon_gargoyle&talent.army_of_the_damned&pet.army_ghoul.active&pet.apoc_ghoul.active|!talent.summon_gargoyle&!talent.army_of_the_damned&buff.dark_transformation.up|!talent.summon_gargoyle&!talent.summon_gargoyle&buff.dark_transformation.up)|fight_remains<=21;
	if talents[UH.EmpowerRuneWeapon] and (stPlanning and ( petGargoyle and petGargoyle <= 23 or not talents[UH.SummonGargoyle] and talents[UH.ArmyOfTheDamned] and armyGhoulActive and apocGhoulActive or not talents[UH.SummonGargoyle] and not talents[UH.ArmyOfTheDamned] and buff[UH.DarkTransformation].up or not talents[UH.SummonGargoyle] and not talents[UH.SummonGargoyle] and buff[UH.DarkTransformation].up ) or timeToDie <= 21) then
		return UH.EmpowerRuneWeapon;
	end

	-- abomination_limb,if=rune<3&variable.st_planning;
	if talents[UH.AbominationLimb] and cooldown[UH.AbominationLimb].ready and (runes < 3 and stPlanning) then
		return UH.AbominationLimb;
	end

	-- unholy_assault,target_if=min:debuff.festering_wound.stack,if=variable.st_planning;
	if talents[UH.UnholyAssault] and cooldown[UH.UnholyAssault].ready and (stPlanning) then
		return UH.UnholyAssault;
	end

	-- soul_reaper,if=active_enemies=1&target.time_to_pct_35<5&target.time_to_die>5;
	if talents[UH.SoulReaper] and cooldown[UH.SoulReaper].ready and runes >= 1 and runicPower >= 10 and (targets == 1 and timeTo35 < 5 and timeToDie > 5) then
		return UH.SoulReaper;
	end

	-- soul_reaper,target_if=min:dot.soul_reaper.remains,if=target.time_to_pct_35<5&active_enemies>=2&target.time_to_die>(dot.soul_reaper.remains+5);
	if talents[UH.SoulReaper] and cooldown[UH.SoulReaper].ready and runes >= 1 and runicPower >= 10 and (timeTo35 < 5 and targets >= 2 and timeToDie > ( debuff[UH.SoulReaper].remains + 5 )) then
		return UH.SoulReaper;
	end
end

function DeathKnight:UnholyGargSetup()
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

	-- apocalypse,if=debuff.festering_wound.stack>=4&(buff.commander_of_the_dead.up&pet.gargoyle.remains<23|!talent.commander_of_the_dead);
	if talents[UH.Apocalypse] and cooldown[UH.Apocalypse].ready and (debuff[UH.FesteringWound].count >= 4 and ( buff[UH.CommanderOfTheDead].up and petGargoyle < 23 or not talents[UH.CommanderOfTheDead] )) then
		return UH.Apocalypse;
	end

	-- army_of_the_dead,if=talent.commander_of_the_dead&(cooldown.dark_transformation.remains<3|buff.commander_of_the_dead.up)|!talent.commander_of_the_dead&talent.unholy_assault&cooldown.unholy_assault.remains<10|!talent.unholy_assault&!talent.commander_of_the_dead;
	if talents[UH.ArmyOfTheDead] and cooldown[UH.ArmyOfTheDead].ready and runes >= 1 and runicPower >= 10 and (talents[UH.CommanderOfTheDead] and ( cooldown[UH.DarkTransformation].remains < 3 or buff[UH.CommanderOfTheDead].up ) or not talents[UH.CommanderOfTheDead] and talents[UH.UnholyAssault] and cooldown[UH.UnholyAssault].remains < 10 or not talents[UH.UnholyAssault] and not talents[UH.CommanderOfTheDead]) then
		return UH.ArmyOfTheDead;
	end

	-- soul_reaper,if=active_enemies=1&target.time_to_pct_35<5&target.time_to_die>5;
	if talents[UH.SoulReaper] and cooldown[UH.SoulReaper].ready and runes >= 1 and runicPower >= 10 and (targets == 1 and timeTo35 < 5 and timeToDie > 5) then
		return UH.SoulReaper;
	end

	-- summon_gargoyle,use_off_gcd=1,if=buff.commander_of_the_dead.up|!talent.commander_of_the_dead&runic_power>=40;
	if talents[UH.SummonGargoyle] and cooldown[UH.SummonGargoyle].ready and (buff[UH.CommanderOfTheDead].up or not talents[UH.CommanderOfTheDead] and runicPower >= 40) then
		return UH.SummonGargoyle;
	end

	-- empower_rune_weapon,if=pet.gargoyle.active&pet.gargoyle.remains<=23;
	if talents[UH.EmpowerRuneWeapon] and (petGargoyle and petGargoyle <= 23) then
		return UH.EmpowerRuneWeapon;
	end

	-- unholy_assault,if=pet.gargoyle.active&pet.gargoyle.remains<=23;
	if talents[UH.UnholyAssault] and cooldown[UH.UnholyAssault].ready and (petGargoyle and petGargoyle <= 23) then
		return UH.UnholyAssault;
	end

	-- dark_transformation,if=talent.commander_of_the_dead&runic_power>40|!talent.commander_of_the_dead;
	if talents[UH.DarkTransformation] and cooldown[UH.DarkTransformation].ready and (talents[UH.CommanderOfTheDead] and runicPower > 40 or not talents[UH.CommanderOfTheDead]) then
		return UH.DarkTransformation;
	end

	-- any_dnd,if=!death_and_decay.ticking&debuff.festering_wound.stack>0;
	if not debuff[UH.DeathAndDecay].up and debuff[UH.FesteringWound].count > 0 then
		return UH.AnyDnd;
	end

	-- festering_strike,if=debuff.festering_wound.stack=0|!talent.apocalypse|runic_power<40&!pet.gargoyle.active;
	if talents[UH.FesteringStrike] and runes >= 2 and runicPower >= 20 and (debuff[UH.FesteringWound].count == 0 or not talents[UH.Apocalypse] or runicPower < 40 and not petGargoyle) then
		return UH.FesteringStrike;
	end

	-- death_coil,if=rune<=1;
	if runicPower >= 30 and (runes <= 1) then
		return UH.DeathCoil;
	end
end

function DeathKnight:UnholyHighPrioActions()
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

	-- antimagic_shell,if=runic_power.deficit>40&(pet.gargoyle.active|!talent.summon_gargoyle|cooldown.summon_gargoyle.remains>cooldown.antimagic_shell.duration);
	if talents[UH.AntimagicShell] and cooldown[UH.AntimagicShell].ready and (runicPowerDeficit > 40 and ( petGargoyle or not talents[UH.SummonGargoyle] or cooldown[UH.SummonGargoyle].remains > cooldown[UH.AntimagicShell].duration )) then
		return UH.AntimagicShell;
	end

	-- antimagic_zone,if=death_knight.amz_absorb_percent>0&runic_power.deficit>70&talent.assimilation&(pet.gargoyle.active|!talent.summon_gargoyle);
	if talents[UH.AntimagicZone] and cooldown[UH.AntimagicZone].ready and (amzAbsorbPercent > 0 and runicPowerDeficit > 70 and talents[UH.Assimilation] and ( petGargoyle or not talents[UH.SummonGargoyle] )) then
		return UH.AntimagicZone;
	end

	-- army_of_the_dead,if=talent.summon_gargoyle&cooldown.summon_gargoyle.remains<2|!talent.summon_gargoyle|fight_remains<35;
	if talents[UH.ArmyOfTheDead] and cooldown[UH.ArmyOfTheDead].ready and runes >= 1 and runicPower >= 10 and (talents[UH.SummonGargoyle] and cooldown[UH.SummonGargoyle].remains < 2 or not talents[UH.SummonGargoyle] or timeToDie < 35) then
		return UH.ArmyOfTheDead;
	end

	-- death_coil,if=(active_enemies<=3|!talent.epidemic)&(pet.gargoyle.active&talent.commander_of_the_dead&buff.commander_of_the_dead.up&cooldown.apocalypse.remains<5&buff.commander_of_the_dead.remains>27|debuff.death_rot.up&debuff.death_rot.remains<gcd);
	if runicPower >= 30 and (( targets <= 3 or not talents[UH.Epidemic] ) and ( petGargoyle and talents[UH.CommanderOfTheDead] and buff[UH.CommanderOfTheDead].up and cooldown[UH.Apocalypse].remains < 5 and buff[UH.CommanderOfTheDead].remains > 27 or debuff[UH.DeathRot].up and debuff[UH.DeathRot].remains < gcd )) then
		return UH.DeathCoil;
	end

	-- epidemic,if=active_enemies>=4&(talent.commander_of_the_dead&buff.commander_of_the_dead.up&cooldown.apocalypse.remains<5|debuff.death_rot.up&debuff.death_rot.remains<gcd);
	if talents[UH.Epidemic] and runicPower >= 30 and (targets >= 4 and ( talents[UH.CommanderOfTheDead] and buff[UH.CommanderOfTheDead].up and cooldown[UH.Apocalypse].remains < 5 or debuff[UH.DeathRot].up and debuff[UH.DeathRot].remains < gcd )) then
		return UH.Epidemic;
	end

	-- wound_spender,if=(cooldown.apocalypse.remains>variable.apoc_timing+3|active_enemies>=3)&talent.plaguebringer&(talent.superstrain|talent.unholy_blight)&buff.plaguebringer.remains<gcd;
	if ( cooldown[UH.Apocalypse].remains > apocTiming + 3 or targets >= 3 ) and talents[UH.Plaguebringer] and ( talents[UH.Superstrain] or talents[UH.UnholyBlight] ) and buff[UH.Plaguebringer].remains < gcd then
		return UH.WoundSpender;
	end

	-- unholy_blight,if=variable.st_planning&((!talent.apocalypse|cooldown.apocalypse.remains)&talent.morbidity|!talent.morbidity)|variable.adds_remain|fight_remains<21;
	if talents[UH.UnholyBlight] and cooldown[UH.UnholyBlight].ready and runes >= 1 and runicPower >= 10 and (stPlanning and ( ( not talents[UH.Apocalypse] or cooldown[UH.Apocalypse].remains ) and talents[UH.Morbidity] or not talents[UH.Morbidity] ) or addsRemain or timeToDie < 21) then
		return UH.UnholyBlight;
	end

	-- outbreak,target_if=target.time_to_die>dot.virulent_plague.remains&(dot.virulent_plague.refreshable|talent.superstrain&(dot.frost_fever_superstrain.refreshable|dot.blood_plague_superstrain.refreshable))&(!talent.unholy_blight|talent.unholy_blight&cooldown.unholy_blight.remains>15%((talent.superstrain*3)+(talent.plaguebringer*2)+(talent.ebon_fever*2)));
	if talents[UH.Outbreak] and runes >= 1 and runicPower >= 10 then
		return UH.Outbreak;
	end
end

function DeathKnight:UnholyRacials()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local runeforge = fd.runeforge;
end

function DeathKnight:UnholySt()
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

	-- death_coil,if=!variable.epidemic_priority&(!variable.pooling_runic_power&(rune<3|pet.gargoyle.active|buff.sudden_doom.react|cooldown.apocalypse.remains<10&debuff.festering_wound.stack>3|!variable.pop_wounds&debuff.festering_wound.stack>=4)|fight_remains<10);
	if runicPower >= 30 and (not epidemicPriority and ( not poolingRunicPower and ( runes < 3 or petGargoyle or buff[UH.SuddenDoom].count or cooldown[UH.Apocalypse].remains < 10 and debuff[UH.FesteringWound].count > 3 or not popWounds and debuff[UH.FesteringWound].count >= 4 ) or timeToDie < 10 )) then
		return UH.DeathCoil;
	end

	-- epidemic,if=variable.epidemic_priority&(!variable.pooling_runic_power&(rune<3|pet.gargoyle.active|buff.sudden_doom.react|cooldown.apocalypse.remains<10&debuff.festering_wound.stack>3|!variable.pop_wounds&debuff.festering_wound.stack>=4)|fight_remains<10);
	if talents[UH.Epidemic] and runicPower >= 30 and (epidemicPriority and ( not poolingRunicPower and ( runes < 3 or petGargoyle or buff[UH.SuddenDoom].count or cooldown[UH.Apocalypse].remains < 10 and debuff[UH.FesteringWound].count > 3 or not popWounds and debuff[UH.FesteringWound].count >= 4 ) or timeToDie < 10 )) then
		return UH.Epidemic;
	end

	-- any_dnd,if=!death_and_decay.ticking&(active_enemies>=2|talent.unholy_ground&(pet.apoc_ghoul.active&pet.apoc_ghoul.remains>=13|pet.gargoyle.active&pet.gargoyle.remains>8|pet.army_ghoul.active&pet.army_ghoul.remains>8|!variable.pop_wounds&debuff.festering_wound.stack>=4))&(death_knight.fwounded_targets=active_enemies|active_enemies=1);
	if not debuff[UH.DeathAndDecay].up and ( targets >= 2 or talents[UH.UnholyGround] and ( apocGhoulActive and apocGhoulRemains >= 13 or petGargoyle and petGargoyle > 8 or armyGhoulActive and armyGhoulRemains > 8 or not popWounds and debuff[UH.FesteringWound].count >= 4 ) ) and ( fwoundedTargets == targets or targets == 1 ) then
		return UH.AnyDnd;
	end

	-- wound_spender,target_if=max:debuff.festering_wound.stack,if=variable.pop_wounds|active_enemies>=2&death_and_decay.ticking;
	if popWounds or targets >= 2 and debuff[UH.DeathAndDecay].up then
		return UH.WoundSpender;
	end

	-- festering_strike,target_if=min:debuff.festering_wound.stack,if=!variable.pop_wounds&debuff.festering_wound.stack<4;
	if talents[UH.FesteringStrike] and runes >= 2 and runicPower >= 20 and (not popWounds and debuff[UH.FesteringWound].count < 4) then
		return UH.FesteringStrike;
	end

	-- death_coil;
	if runicPower >= 30 then
		return UH.DeathCoil;
	end

	-- wound_spender,target_if=max:debuff.festering_wound.stack,if=!variable.pop_wounds&debuff.festering_wound.stack>=4;
	if not popWounds and debuff[UH.FesteringWound].count >= 4 then
		return UH.WoundSpender;
	end
end

function DeathKnight:UnholyTrinkets()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local runeforge = fd.runeforge;
end

function DeathKnight:UnholyVariables()
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
	local runicPower = UnitPower('player', Enum.PowerType.RunicPower);
	local runicPowerMax = UnitPowerMax('player', Enum.PowerType.RunicPower);
	local runicPowerPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local runicPowerRegen = select(2,GetPowerRegen());
	local runicPowerRegenCombined = runicPowerRegen + runicPower;
	local runicPowerDeficit = UnitPowerMax('player', Enum.PowerType.RunicPower) - runicPower;
	local runicPowerTimeToMax = runicPowerMax - runicPower / runicPowerRegen;
	local runeforge = fd.runeforge;

	-- variable,name=epidemic_priority,op=setif,value=1,value_else=0,condition=talent.improved_death_coil&!talent.coil_of_devastation&active_enemies>=3|talent.coil_of_devastation&active_enemies>=4|!talent.improved_death_coil&active_enemies>=2;
	if talents[UH.ImprovedDeathCoil] and not talents[UH.CoilOfDevastation] and targets >= 3 or talents[UH.CoilOfDevastation] and targets >= 4 or not talents[UH.ImprovedDeathCoil] and targets >= 2 then
		epidemicPriority = 1;
	else
		epidemicPriority = 0;
	end

	-- variable,name=garg_setup,op=setif,value=1,value_else=0,condition=active_enemies>=3|cooldown.summon_gargoyle.remains>1&cooldown.apocalypse.remains>1|!talent.apocalypse&cooldown.summon_gargoyle.remains>1|!talent.summon_gargoyle|time>20;
	if targets >= 3 or cooldown[UH.SummonGargoyle].remains > 1 and cooldown[UH.Apocalypse].remains > 1 or not talents[UH.Apocalypse] and cooldown[UH.SummonGargoyle].remains > 1 or not talents[UH.SummonGargoyle] or GetTime() > 20 then
		gargSetup = 1;
	else
		gargSetup = 0;
	end

	-- variable,name=apoc_timing,op=setif,value=7,value_else=2,condition=cooldown.apocalypse.remains<10&debuff.festering_wound.stack<=4&cooldown.unholy_assault.remains>10;
	if cooldown[UH.Apocalypse].remains < 10 and debuff[UH.FesteringWound].count <= 4 and cooldown[UH.UnholyAssault].remains > 10 then
		apocTiming = 7;
	else
		apocTiming = 2;
	end

	-- variable,name=festermight_tracker,op=setif,value=debuff.festering_wound.stack>=1,value_else=debuff.festering_wound.stack>=(3-talent.infected_claws),condition=!pet.gargoyle.active&talent.festermight&buff.festermight.up&(buff.festermight.remains%(5*gcd.max))>=1;
	if not petGargoyle and talents[UH.Festermight] and buff[UH.Festermight].up and ( buff[UH.Festermight].remains / ( 5 * gcd ) ) >= 1 then
		festermightTracker = debuff[UH.FesteringWound].count >= 1;
	else
		festermightTracker = debuff[UH.FesteringWound].count >= ( 3 - (talents[UH.InfectedClaws] and 1 or 0) );
	end

	-- variable,name=pop_wounds,op=setif,value=1,value_else=0,condition=(cooldown.apocalypse.remains>variable.apoc_timing|!talent.apocalypse)&(variable.festermight_tracker|debuff.festering_wound.stack>=1&!talent.apocalypse|debuff.festering_wound.stack>=1&cooldown.unholy_assault.remains<20&talent.unholy_assault&variable.st_planning|debuff.rotten_touch.up&debuff.festering_wound.stack>=1|debuff.festering_wound.stack>4)|fight_remains<5&debuff.festering_wound.stack>=1;
	if ( cooldown[UH.Apocalypse].remains > apocTiming or not talents[UH.Apocalypse] ) and ( festermightTracker or debuff[UH.FesteringWound].count >= 1 and not talents[UH.Apocalypse] or debuff[UH.FesteringWound].count >= 1 and cooldown[UH.UnholyAssault].remains < 20 and talents[UH.UnholyAssault] and stPlanning or debuff[UH.RottenTouch].up and debuff[UH.FesteringWound].count >= 1 or debuff[UH.FesteringWound].count > 4 ) or timeToDie < 5 and debuff[UH.FesteringWound].count >= 1 then
		popWounds = 1;
	else
		popWounds = 0;
	end

	-- variable,name=pooling_runic_power,op=setif,value=1,value_else=0,condition=talent.vile_contagion&cooldown.vile_contagion.remains<3&runic_power<60&!variable.st_planning;
	if talents[UH.VileContagion] and cooldown[UH.VileContagion].remains < 3 and runicPower < 60 and not stPlanning then
		poolingRunicPower = 1;
	else
		poolingRunicPower = 0;
	end

	-- variable,name=st_planning,op=setif,value=1,value_else=0,condition=active_enemies=1&(!raid_event.adds.exists|raid_event.adds.in>15);
	if targets == 1 and ( not targets > 1 ) then
		stPlanning = 1;
	else
		stPlanning = 0;
	end

	-- variable,name=adds_remain,op=setif,value=1,value_else=0,condition=active_enemies>=2&(!raid_event.adds.exists|raid_event.adds.exists&raid_event.adds.remains>6);
	if targets >= 2 and ( not targets > 1 or targets > 1) then
		addsRemain = 1;
	else
		addsRemain = 0;
	end
end


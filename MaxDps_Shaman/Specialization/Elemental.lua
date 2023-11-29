local _, addonTable = ...;

-- @type MaxDps;
if not MaxDps then return end;
local Shaman = addonTable.Shaman;
local MaxDps = MaxDps;

local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;

local itemID = GetInventoryItemID('player', INVSLOT_MAINHAND);

local mainHandSubClassID = itemID and  select(13, GetItemInfo(itemID));

local TwoHanderWepCheck = mainHandSubClassID and (mainHandSubClassID == 1 or mainHandSubClassID == 5 or mainHandSubClassID == 8 or mainHandSubClassID == 10);

local EL = {
	FlametongueWeapon = 318038,
	ImprovedFlametongueWeapon = 382027,
	Stormkeeper = 191634,
	Icefury = 210714,
	SpiritwalkersGrace = 79206,
	WindShear = 57994,
	NaturesSwiftness = 378081,
	FireElemental = 198067,
	StormElemental = 192249,
	TotemicRecall = 108285,
	LiquidMagmaTotem = 192222,
	PrimordialWave = 375982,
	FlameShock = 188389,
	SurgeOfPower = 262303,
	SplinteredElements = 382042,
	DeeplyRootedElements = 378270,
	MasterOfTheElements = 16166,
	LightningRod = 210689,
	WindspeakersLavaResurgence = 378268,
	SkybreakersFieryDemise = 378310,
	Ascendance = 114050,
	LavaBurst = 51505,
	LavaSurge = 77756,
	EyeOfTheStorm = 381708,
	FlowOfPower = 385923,
	EchoesOfGreatSundering = 384087,
	UnrelentingCalamity = 382685,
	Earthquake = 61882,
	ElementalBlast = 117014,
	EarthShock = 8042,
	ElectrifiedShocks = 382086,
	FrostShock = 196840,
	Tier302pc = 393688,
	LavaBeam = 114074,
	ChainLightning = 188443,
	PowerOfTheMaelstrom = 191861,
	SearingFlames = 381782,
	MagmaChamber = 381932,
	SwellingMaelstrom = 381707,
	EchoOfTheElements = 333919,
	PrimordialSurge = 386474,
	LightningBolt = 188196,
	FluxMelting = 381776,
};
local A = {
};
function Shaman:Elemental()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- spiritwalkers_grace,moving=1,if=movement.distance>6;
	if talents[EL.SpiritwalkersGrace] and cooldown[EL.SpiritwalkersGrace].ready and mana >= 7050 and (6) then
		return EL.SpiritwalkersGrace;
	end

	-- natures_swiftness;
	if talents[EL.NaturesSwiftness] and cooldown[EL.NaturesSwiftness].ready then
		return EL.NaturesSwiftness;
	end

	-- run_action_list,name=aoe,if=active_enemies>2&(spell_targets.chain_lightning>2|spell_targets.lava_beam>2);
	if targets > 2 and ( targets > 2 or targets > 2 ) then
		return Shaman:ElementalAoe();
	end

	-- run_action_list,name=single_target;
	return Shaman:ElementalSingleTarget();
end
function Shaman:ElementalAoe()
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
	local maelstrom = UnitPower('player', Enum.PowerType.Maelstrom);
	local maelstromMax = UnitPowerMax('player', Enum.PowerType.Maelstrom);
	local maelstromPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local maelstromRegen = select(2,GetPowerRegen());
	local maelstromRegenCombined = maelstromRegen + maelstrom;
	local maelstromDeficit = UnitPowerMax('player', Enum.PowerType.Maelstrom) - maelstrom;
	local maelstromTimeToMax = maelstromMax - maelstrom / maelstromRegen;

	-- fire_elemental;
	if talents[EL.FireElemental] and cooldown[EL.FireElemental].ready and mana >= 2500 then
		return EL.FireElemental;
	end

	-- storm_elemental;
	if talents[EL.StormElemental] and cooldown[EL.StormElemental].ready and mana >= 2500 then
		return EL.StormElemental;
	end

	-- stormkeeper,if=!buff.stormkeeper.up;
	if talents[EL.Stormkeeper] and cooldown[EL.Stormkeeper].ready and currentSpell ~= EL.Stormkeeper and (not buff[EL.Stormkeeper].up) then
		return EL.Stormkeeper;
	end

	-- totemic_recall,if=cooldown.liquid_magma_totem.remains>45;
	if talents[EL.TotemicRecall] and cooldown[EL.TotemicRecall].ready and (cooldown[EL.LiquidMagmaTotem].remains > 45) then
		return EL.TotemicRecall;
	end

	-- liquid_magma_totem;
	if talents[EL.LiquidMagmaTotem] and cooldown[EL.LiquidMagmaTotem].ready and mana >= 1750 then
		return EL.LiquidMagmaTotem;
	end

	-- primordial_wave,target_if=min:dot.flame_shock.remains,if=!buff.primordial_wave.up&buff.surge_of_power.up&!buff.splintered_elements.up;
	if talents[EL.PrimordialWave] and cooldown[EL.PrimordialWave].ready and mana >= 1500 and (not buff[EL.PrimordialWave].up and buff[EL.SurgeOfPower].up and not buff[EL.SplinteredElements].up) then
		return EL.PrimordialWave;
	end

	-- primordial_wave,target_if=min:dot.flame_shock.remains,if=!buff.primordial_wave.up&talent.deeply_rooted_elements.enabled&!talent.surge_of_power.enabled&!buff.splintered_elements.up;
	if talents[EL.PrimordialWave] and cooldown[EL.PrimordialWave].ready and mana >= 1500 and (not buff[EL.PrimordialWave].up and talents[EL.DeeplyRootedElements] and not talents[EL.SurgeOfPower] and not buff[EL.SplinteredElements].up) then
		return EL.PrimordialWave;
	end

	-- primordial_wave,target_if=min:dot.flame_shock.remains,if=!buff.primordial_wave.up&talent.master_of_the_elements.enabled&!talent.lightning_rod.enabled;
	if talents[EL.PrimordialWave] and cooldown[EL.PrimordialWave].ready and mana >= 1500 and (not buff[EL.PrimordialWave].up and talents[EL.MasterOfTheElements] and not talents[EL.LightningRod]) then
		return EL.PrimordialWave;
	end

	-- flame_shock,target_if=refreshable,if=buff.surge_of_power.up&talent.lightning_rod.enabled&talent.windspeakers_lava_resurgence.enabled&dot.flame_shock.remains<target.time_to_die-16&active_enemies<5;
	if cooldown[EL.FlameShock].ready and mana >= 750 and (buff[EL.SurgeOfPower].up and talents[EL.LightningRod] and talents[EL.WindspeakersLavaResurgence] and debuff[EL.FlameShock].remains < timeToDie - 16 and targets < 5) then
		return EL.FlameShock;
	end

	-- flame_shock,target_if=refreshable,if=buff.surge_of_power.up&(!talent.lightning_rod.enabled|talent.skybreakers_fiery_demise.enabled)&dot.flame_shock.remains<target.time_to_die-5&active_dot.flame_shock<6;
	if cooldown[EL.FlameShock].ready and mana >= 750 and (buff[EL.SurgeOfPower].up and ( not talents[EL.LightningRod] or talents[EL.SkybreakersFieryDemise] ) and debuff[EL.FlameShock].remains < timeToDie - 5 and activeDot[EL.FlameShock] < 6) then
		return EL.FlameShock;
	end

	-- flame_shock,target_if=refreshable,if=talent.master_of_the_elements.enabled&!talent.lightning_rod.enabled&dot.flame_shock.remains<target.time_to_die-5&active_dot.flame_shock<6;
	if cooldown[EL.FlameShock].ready and mana >= 750 and (talents[EL.MasterOfTheElements] and not talents[EL.LightningRod] and debuff[EL.FlameShock].remains < timeToDie - 5 and activeDot[EL.FlameShock] < 6) then
		return EL.FlameShock;
	end

	-- flame_shock,target_if=refreshable,if=talent.deeply_rooted_elements.enabled&!talent.surge_of_power.enabled&dot.flame_shock.remains<target.time_to_die-5&active_dot.flame_shock<6;
	if cooldown[EL.FlameShock].ready and mana >= 750 and (talents[EL.DeeplyRootedElements] and not talents[EL.SurgeOfPower] and debuff[EL.FlameShock].remains < timeToDie - 5 and activeDot[EL.FlameShock] < 6) then
		return EL.FlameShock;
	end

	-- flame_shock,target_if=refreshable,if=buff.surge_of_power.up&(!talent.lightning_rod.enabled|talent.skybreakers_fiery_demise.enabled)&dot.flame_shock.remains<target.time_to_die-5&dot.flame_shock.remains>0;
	if cooldown[EL.FlameShock].ready and mana >= 750 and (buff[EL.SurgeOfPower].up and ( not talents[EL.LightningRod] or talents[EL.SkybreakersFieryDemise] ) and debuff[EL.FlameShock].remains < timeToDie - 5 and debuff[EL.FlameShock].remains > 0) then
		return EL.FlameShock;
	end

	-- flame_shock,target_if=refreshable,if=talent.master_of_the_elements.enabled&!talent.lightning_rod.enabled&dot.flame_shock.remains<target.time_to_die-5&dot.flame_shock.remains>0;
	if cooldown[EL.FlameShock].ready and mana >= 750 and (talents[EL.MasterOfTheElements] and not talents[EL.LightningRod] and debuff[EL.FlameShock].remains < timeToDie - 5 and debuff[EL.FlameShock].remains > 0) then
		return EL.FlameShock;
	end

	-- flame_shock,target_if=refreshable,if=talent.deeply_rooted_elements.enabled&!talent.surge_of_power.enabled&dot.flame_shock.remains<target.time_to_die-5&dot.flame_shock.remains>0;
	if cooldown[EL.FlameShock].ready and mana >= 750 and (talents[EL.DeeplyRootedElements] and not talents[EL.SurgeOfPower] and debuff[EL.FlameShock].remains < timeToDie - 5 and debuff[EL.FlameShock].remains > 0) then
		return EL.FlameShock;
	end

	-- ascendance;
	if talents[EL.Ascendance] and cooldown[EL.Ascendance].ready then
		return EL.Ascendance;
	end

	-- lava_burst,target_if=dot.flame_shock.remains,if=cooldown_react&buff.lava_surge.up&talent.master_of_the_elements.enabled&!buff.master_of_the_elements.up&(maelstrom>=60-5*talent.eye_of_the_storm.rank-2*talent.flow_of_power.enabled)&(!talent.echoes_of_great_sundering.enabled&!talent.lightning_rod.enabled|buff.echoes_of_great_sundering.up)&(!buff.ascendance.up&active_enemies>3&talent.unrelenting_calamity.enabled|active_enemies>3&!talent.unrelenting_calamity.enabled|active_enemies=3);
	if talents[EL.LavaBurst] and cooldown[EL.LavaBurst].ready and mana >= 1250 and currentSpell ~= EL.LavaBurst and (cooldownReact and buff[EL.LavaSurge].up and talents[EL.MasterOfTheElements] and not buff[EL.MasterOfTheElements].up and ( maelstrom >= 60 - 5 * (talents[EL.EyeOfTheStorm] and 1 or 0) - 2 * (talents[EL.FlowOfPower] and 1 or 0) ) and ( not talents[EL.EchoesOfGreatSundering] and not talents[EL.LightningRod] or buff[EL.EchoesOfGreatSundering].up ) and ( not buff[EL.Ascendance].up and targets > 3 and talents[EL.UnrelentingCalamity] or targets > 3 and not talents[EL.UnrelentingCalamity] or targets == 3 )) then
		return EL.LavaBurst;
	end

	-- earthquake,if=!talent.echoes_of_great_sundering.enabled&active_enemies>3&(spell_targets.chain_lightning>3|spell_targets.lava_beam>3);
	if talents[EL.Earthquake] and maelstrom >= 50 and (not talents[EL.EchoesOfGreatSundering] and targets > 3 and ( targets > 3 or targets > 3 )) then
		return EL.Earthquake;
	end

	-- earthquake,if=!talent.echoes_of_great_sundering.enabled&!talent.elemental_blast.enabled&active_enemies=3&(spell_targets.chain_lightning=3|spell_targets.lava_beam=3);
	if talents[EL.Earthquake] and maelstrom >= 50 and (not talents[EL.EchoesOfGreatSundering] and not talents[EL.ElementalBlast] and targets == 3 and ( targets == 3 or targets == 3 )) then
		return EL.Earthquake;
	end

	-- earthquake,if=buff.echoes_of_great_sundering.up;
	if talents[EL.Earthquake] and maelstrom >= 50 and (buff[EL.EchoesOfGreatSundering].up) then
		return EL.Earthquake;
	end

	-- elemental_blast,target_if=min:debuff.lightning_rod.remains,if=talent.echoes_of_great_sundering.enabled;
	if talents[EL.ElementalBlast] and mana >= 0 and maelstrom >= 75 and currentSpell ~= EL.ElementalBlast and (talents[EL.EchoesOfGreatSundering]) then
		return EL.ElementalBlast;
	end

	-- elemental_blast,if=talent.echoes_of_great_sundering.enabled;
	if talents[EL.ElementalBlast] and mana >= 0 and maelstrom >= 75 and currentSpell ~= EL.ElementalBlast and (talents[EL.EchoesOfGreatSundering]) then
		return EL.ElementalBlast;
	end

	-- elemental_blast,if=enemies=3&!talent.echoes_of_great_sundering.enabled;
	if talents[EL.ElementalBlast] and mana >= 0 and maelstrom >= 75 and currentSpell ~= EL.ElementalBlast and (not talents[EL.EchoesOfGreatSundering]) then
		return EL.ElementalBlast;
	end

	-- earth_shock,target_if=min:debuff.lightning_rod.remains,if=talent.echoes_of_great_sundering.enabled;
	if talents[EL.EarthShock] and maelstrom >= 50 and (talents[EL.EchoesOfGreatSundering]) then
		return EL.EarthShock;
	end

	-- earth_shock,if=talent.echoes_of_great_sundering.enabled;
	if talents[EL.EarthShock] and maelstrom >= 50 and (talents[EL.EchoesOfGreatSundering]) then
		return EL.EarthShock;
	end

	-- icefury,if=!buff.ascendance.up&talent.electrified_shocks.enabled&(talent.lightning_rod.enabled&active_enemies<5&!buff.master_of_the_elements.up|talent.deeply_rooted_elements.enabled&active_enemies=3);
	if talents[EL.Icefury] and cooldown[EL.Icefury].ready and mana >= 1500 and currentSpell ~= EL.Icefury and (not buff[EL.Ascendance].up and talents[EL.ElectrifiedShocks] and ( talents[EL.LightningRod] and targets < 5 and not buff[EL.MasterOfTheElements].up or talents[EL.DeeplyRootedElements] and targets == 3 )) then
		return EL.Icefury;
	end

	-- frost_shock,if=!buff.ascendance.up&buff.icefury.up&talent.electrified_shocks.enabled&(!debuff.electrified_shocks.up|buff.icefury.remains<gcd)&(talent.lightning_rod.enabled&active_enemies<5&!buff.master_of_the_elements.up|talent.deeply_rooted_elements.enabled&active_enemies=3);
	if talents[EL.FrostShock] and mana >= 500 and (not buff[EL.Ascendance].up and buff[EL.Icefury].up and talents[EL.ElectrifiedShocks] and ( not debuff[EL.ElectrifiedShocks].up or buff[EL.Icefury].remains < gcd ) and ( talents[EL.LightningRod] and targets < 5 and not buff[EL.MasterOfTheElements].up or talents[EL.DeeplyRootedElements] and targets == 3 )) then
		return EL.FrostShock;
	end

	-- lava_burst,target_if=dot.flame_shock.remains,if=talent.master_of_the_elements.enabled&!buff.master_of_the_elements.up&(buff.stormkeeper.up|t30_2pc_timer.next_tick<3&set_bonus.tier30_2pc)&(maelstrom<60-5*talent.eye_of_the_storm.rank-2*talent.flow_of_power.enabled-10)&active_enemies<5;
	if talents[EL.LavaBurst] and cooldown[EL.LavaBurst].ready and mana >= 1250 and currentSpell ~= EL.LavaBurst and (talents[EL.MasterOfTheElements] and not buff[EL.MasterOfTheElements].up and ( buff[EL.Stormkeeper].up or 3 and MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2) ) and ( maelstrom < 60 - 5 * (talents[EL.EyeOfTheStorm] and 1 or 0) - 2 * (talents[EL.FlowOfPower] and 1 or 0) - 10 ) and targets < 5) then
		return EL.LavaBurst;
	end

	-- lava_beam,if=buff.stormkeeper.up;
	if buff[EL.Stormkeeper].up then
		return EL.LavaBeam;
	end

	-- chain_lightning,if=buff.stormkeeper.up;
	if talents[EL.ChainLightning] and mana >= 500 and currentSpell ~= EL.ChainLightning and (buff[EL.Stormkeeper].up) then
		return EL.ChainLightning;
	end

	-- lava_beam,if=buff.power_of_the_maelstrom.up&buff.ascendance.remains>cast_time;
	if buff[EL.PowerOfTheMaelstrom].up and buff[EL.Ascendance].remains > timeShift then
		return EL.LavaBeam;
	end

	-- chain_lightning,if=buff.power_of_the_maelstrom.up;
	if talents[EL.ChainLightning] and mana >= 500 and currentSpell ~= EL.ChainLightning and (buff[EL.PowerOfTheMaelstrom].up) then
		return EL.ChainLightning;
	end

	-- lava_beam,if=active_enemies>=6&buff.surge_of_power.up&buff.ascendance.remains>cast_time;
	if targets >= 6 and buff[EL.SurgeOfPower].up and buff[EL.Ascendance].remains > timeShift then
		return EL.LavaBeam;
	end

	-- chain_lightning,if=active_enemies>=6&buff.surge_of_power.up;
	if talents[EL.ChainLightning] and mana >= 500 and currentSpell ~= EL.ChainLightning and (targets >= 6 and buff[EL.SurgeOfPower].up) then
		return EL.ChainLightning;
	end

	-- lava_burst,target_if=dot.flame_shock.remains,if=buff.lava_surge.up&talent.deeply_rooted_elements.enabled&buff.windspeakers_lava_resurgence.up;
	if talents[EL.LavaBurst] and cooldown[EL.LavaBurst].ready and mana >= 1250 and currentSpell ~= EL.LavaBurst and (buff[EL.LavaSurge].up and talents[EL.DeeplyRootedElements] and buff[EL.WindspeakersLavaResurgence].up) then
		return EL.LavaBurst;
	end

	-- lava_beam,if=buff.master_of_the_elements.up&buff.ascendance.remains>cast_time;
	if buff[EL.MasterOfTheElements].up and buff[EL.Ascendance].remains > timeShift then
		return EL.LavaBeam;
	end

	-- lava_burst,target_if=dot.flame_shock.remains,if=enemies=3&talent.master_of_the_elements.enabled;
	if talents[EL.LavaBurst] and cooldown[EL.LavaBurst].ready and mana >= 1250 and currentSpell ~= EL.LavaBurst and (talents[EL.MasterOfTheElements]) then
		return EL.LavaBurst;
	end

	-- lava_burst,target_if=dot.flame_shock.remains,if=buff.lava_surge.up&talent.deeply_rooted_elements.enabled;
	if talents[EL.LavaBurst] and cooldown[EL.LavaBurst].ready and mana >= 1250 and currentSpell ~= EL.LavaBurst and (buff[EL.LavaSurge].up and talents[EL.DeeplyRootedElements]) then
		return EL.LavaBurst;
	end

	-- icefury,if=talent.electrified_shocks.enabled&active_enemies<5;
	if talents[EL.Icefury] and cooldown[EL.Icefury].ready and mana >= 1500 and currentSpell ~= EL.Icefury and (talents[EL.ElectrifiedShocks] and targets < 5) then
		return EL.Icefury;
	end

	-- frost_shock,if=buff.icefury.up&talent.electrified_shocks.enabled&!debuff.electrified_shocks.up&active_enemies<5;
	if talents[EL.FrostShock] and mana >= 500 and (buff[EL.Icefury].up and talents[EL.ElectrifiedShocks] and not debuff[EL.ElectrifiedShocks].up and targets < 5) then
		return EL.FrostShock;
	end

	-- lava_beam,if=buff.ascendance.remains>cast_time;
	if buff[EL.Ascendance].remains > timeShift then
		return EL.LavaBeam;
	end

	-- chain_lightning;
	if talents[EL.ChainLightning] and mana >= 500 and currentSpell ~= EL.ChainLightning then
		return EL.ChainLightning;
	end

	-- flame_shock,moving=1,target_if=refreshable;
	if cooldown[EL.FlameShock].ready and mana >= 750 then
		return EL.FlameShock;
	end

	-- frost_shock,moving=1;
	if talents[EL.FrostShock] and mana >= 500 then
		return EL.FrostShock;
	end
end

function Shaman:ElementalSingleTarget()
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
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;
	local maelstrom = UnitPower('player', Enum.PowerType.Maelstrom);
	local maelstromMax = UnitPowerMax('player', Enum.PowerType.Maelstrom);
	local maelstromPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local maelstromRegen = select(2,GetPowerRegen());
	local maelstromRegenCombined = maelstromRegen + maelstrom;
	local maelstromDeficit = UnitPowerMax('player', Enum.PowerType.Maelstrom) - maelstrom;
	local maelstromTimeToMax = maelstromMax - maelstrom / maelstromRegen;

	-- fire_elemental;
	if talents[EL.FireElemental] and cooldown[EL.FireElemental].ready and mana >= 2500 then
		return EL.FireElemental;
	end

	-- storm_elemental;
	if talents[EL.StormElemental] and cooldown[EL.StormElemental].ready and mana >= 2500 then
		return EL.StormElemental;
	end

	-- totemic_recall,if=cooldown.liquid_magma_totem.remains>45&(talent.lava_surge.enabled&talent.splintered_elements.enabled|active_enemies>1&(spell_targets.chain_lightning>1|spell_targets.lava_beam>1));
	if talents[EL.TotemicRecall] and cooldown[EL.TotemicRecall].ready and (cooldown[EL.LiquidMagmaTotem].remains > 45 and ( talents[EL.LavaSurge] and talents[EL.SplinteredElements] or targets > 1 and ( targets > 1 or targets > 1 ) )) then
		return EL.TotemicRecall;
	end

	-- liquid_magma_totem,if=talent.lava_surge.enabled&talent.splintered_elements.enabled|active_dot.flame_shock=0|dot.flame_shock.remains<6|active_enemies>1&(spell_targets.chain_lightning>1|spell_targets.lava_beam>1);
	if talents[EL.LiquidMagmaTotem] and cooldown[EL.LiquidMagmaTotem].ready and mana >= 1750 and (talents[EL.LavaSurge] and talents[EL.SplinteredElements] or activeDot[EL.FlameShock] == 0 or debuff[EL.FlameShock].remains < 6 or targets > 1 and ( targets > 1 or targets > 1 )) then
		return EL.LiquidMagmaTotem;
	end

	-- primordial_wave,target_if=min:dot.flame_shock.remains,if=!buff.primordial_wave.up&!buff.splintered_elements.up;
	if talents[EL.PrimordialWave] and cooldown[EL.PrimordialWave].ready and mana >= 1500 and (not buff[EL.PrimordialWave].up and not buff[EL.SplinteredElements].up) then
		return EL.PrimordialWave;
	end

	-- flame_shock,target_if=min:dot.flame_shock.remains,if=active_enemies=1&refreshable&!buff.surge_of_power.up&(!buff.master_of_the_elements.up|(!buff.stormkeeper.up&(talent.elemental_blast.enabled&maelstrom<90-8*talent.eye_of_the_storm.rank|maelstrom<60-5*talent.eye_of_the_storm.rank)));
	if cooldown[EL.FlameShock].ready and mana >= 750 and (targets == 1 and debuff[EL.FlameShock].refreshable and not buff[EL.SurgeOfPower].up and ( not buff[EL.MasterOfTheElements].up or ( not buff[EL.Stormkeeper].up and ( talents[EL.ElementalBlast] and maelstrom < 90 - 8 * (talents[EL.EyeOfTheStorm] and 1 or 0) or maelstrom < 60 - 5 * (talents[EL.EyeOfTheStorm] and 1 or 0) ) ) )) then
		return EL.FlameShock;
	end

	-- flame_shock,target_if=min:dot.flame_shock.remains,if=active_dot.flame_shock=0&active_enemies>1&(spell_targets.chain_lightning>1|spell_targets.lava_beam>1)&(talent.deeply_rooted_elements.enabled|talent.ascendance.enabled|talent.primordial_wave.enabled|talent.searing_flames.enabled|talent.magma_chamber.enabled)&(!buff.master_of_the_elements.up&(buff.stormkeeper.up|cooldown.stormkeeper.remains=0)|!talent.surge_of_power.enabled);
	if cooldown[EL.FlameShock].ready and mana >= 750 and (activeDot[EL.FlameShock] == 0 and targets > 1 and ( targets > 1 or targets > 1 ) and ( talents[EL.DeeplyRootedElements] or talents[EL.Ascendance] or talents[EL.PrimordialWave] or talents[EL.SearingFlames] or talents[EL.MagmaChamber] ) and ( not buff[EL.MasterOfTheElements].up and ( buff[EL.Stormkeeper].up or cooldown[EL.Stormkeeper].remains == 0 ) or not talents[EL.SurgeOfPower] )) then
		return EL.FlameShock;
	end

	-- flame_shock,target_if=min:dot.flame_shock.remains,if=active_enemies>1&(spell_targets.chain_lightning>1|spell_targets.lava_beam>1)&refreshable&(talent.deeply_rooted_elements.enabled|talent.ascendance.enabled|talent.primordial_wave.enabled|talent.searing_flames.enabled|talent.magma_chamber.enabled)&(buff.surge_of_power.up&!buff.stormkeeper.up&!cooldown.stormkeeper.remains=0|!talent.surge_of_power.enabled),cycle_targets=1;
	if cooldown[EL.FlameShock].ready and mana >= 750 and (targets > 1 and ( targets > 1 or targets > 1 ) and debuff[EL.FlameShock].refreshable and ( talents[EL.DeeplyRootedElements] or talents[EL.Ascendance] or talents[EL.PrimordialWave] or talents[EL.SearingFlames] or talents[EL.MagmaChamber] ) and ( buff[EL.SurgeOfPower].up and not buff[EL.Stormkeeper].up and not cooldown[EL.Stormkeeper].remains == 0 or not talents[EL.SurgeOfPower] )) then
		return EL.FlameShock;
	end

	-- stormkeeper,if=!buff.ascendance.up&!buff.stormkeeper.up&maelstrom>=116&talent.elemental_blast.enabled&talent.surge_of_power.enabled&talent.swelling_maelstrom.enabled&!talent.lava_surge.enabled&!talent.echo_of_the_elements.enabled&!talent.primordial_surge.enabled;
	if talents[EL.Stormkeeper] and cooldown[EL.Stormkeeper].ready and currentSpell ~= EL.Stormkeeper and (not buff[EL.Ascendance].up and not buff[EL.Stormkeeper].up and maelstrom >= 116 and talents[EL.ElementalBlast] and talents[EL.SurgeOfPower] and talents[EL.SwellingMaelstrom] and not talents[EL.LavaSurge] and not talents[EL.EchoOfTheElements] and not talents[EL.PrimordialSurge]) then
		return EL.Stormkeeper;
	end

	-- stormkeeper,if=!buff.ascendance.up&!buff.stormkeeper.up&buff.surge_of_power.up&!talent.lava_surge.enabled&!talent.echo_of_the_elements.enabled&!talent.primordial_surge.enabled;
	if talents[EL.Stormkeeper] and cooldown[EL.Stormkeeper].ready and currentSpell ~= EL.Stormkeeper and (not buff[EL.Ascendance].up and not buff[EL.Stormkeeper].up and buff[EL.SurgeOfPower].up and not talents[EL.LavaSurge] and not talents[EL.EchoOfTheElements] and not talents[EL.PrimordialSurge]) then
		return EL.Stormkeeper;
	end

	-- stormkeeper,if=!buff.ascendance.up&!buff.stormkeeper.up&(!talent.surge_of_power.enabled|!talent.elemental_blast.enabled|talent.lava_surge.enabled|talent.echo_of_the_elements.enabled|talent.primordial_surge.enabled);
	if talents[EL.Stormkeeper] and cooldown[EL.Stormkeeper].ready and currentSpell ~= EL.Stormkeeper and (not buff[EL.Ascendance].up and not buff[EL.Stormkeeper].up and ( not talents[EL.SurgeOfPower] or not talents[EL.ElementalBlast] or talents[EL.LavaSurge] or talents[EL.EchoOfTheElements] or talents[EL.PrimordialSurge] )) then
		return EL.Stormkeeper;
	end

	-- ascendance,if=!buff.stormkeeper.up;
	if talents[EL.Ascendance] and cooldown[EL.Ascendance].ready and (not buff[EL.Stormkeeper].up) then
		return EL.Ascendance;
	end

	-- lightning_bolt,if=buff.stormkeeper.up&buff.surge_of_power.up;
	if buff[EL.Stormkeeper].up and buff[EL.SurgeOfPower].up then
		return EL.LightningBolt;
	end

	-- lava_beam,if=active_enemies>1&(spell_targets.chain_lightning>1|spell_targets.lava_beam>1)&buff.stormkeeper.up&!talent.surge_of_power.enabled;
	if targets > 1 and ( targets > 1 or targets > 1 ) and buff[EL.Stormkeeper].up and not talents[EL.SurgeOfPower] then
		return EL.LavaBeam;
	end

	-- chain_lightning,if=active_enemies>1&(spell_targets.chain_lightning>1|spell_targets.lava_beam>1)&buff.stormkeeper.up&!talent.surge_of_power.enabled;
	if talents[EL.ChainLightning] and mana >= 500 and currentSpell ~= EL.ChainLightning and (targets > 1 and ( targets > 1 or targets > 1 ) and buff[EL.Stormkeeper].up and not talents[EL.SurgeOfPower]) then
		return EL.ChainLightning;
	end

	-- lava_burst,if=buff.stormkeeper.up&!buff.master_of_the_elements.up&!talent.surge_of_power.enabled&talent.master_of_the_elements.enabled;
	if talents[EL.LavaBurst] and cooldown[EL.LavaBurst].ready and mana >= 1250 and currentSpell ~= EL.LavaBurst and (buff[EL.Stormkeeper].up and not buff[EL.MasterOfTheElements].up and not talents[EL.SurgeOfPower] and talents[EL.MasterOfTheElements]) then
		return EL.LavaBurst;
	end

	-- lightning_bolt,if=buff.stormkeeper.up&!talent.surge_of_power.enabled&buff.master_of_the_elements.up;
	if buff[EL.Stormkeeper].up and not talents[EL.SurgeOfPower] and buff[EL.MasterOfTheElements].up then
		return EL.LightningBolt;
	end

	-- lightning_bolt,if=buff.stormkeeper.up&!talent.surge_of_power.enabled&!talent.master_of_the_elements.enabled;
	if buff[EL.Stormkeeper].up and not talents[EL.SurgeOfPower] and not talents[EL.MasterOfTheElements] then
		return EL.LightningBolt;
	end

	-- lightning_bolt,if=buff.surge_of_power.up;
	if buff[EL.SurgeOfPower].up then
		return EL.LightningBolt;
	end

	-- icefury,if=talent.electrified_shocks.enabled;
	if talents[EL.Icefury] and cooldown[EL.Icefury].ready and mana >= 1500 and currentSpell ~= EL.Icefury and (talents[EL.ElectrifiedShocks]) then
		return EL.Icefury;
	end

	-- frost_shock,if=buff.icefury.up&talent.electrified_shocks.enabled&(debuff.electrified_shocks.remains<2|buff.icefury.remains<=gcd);
	if talents[EL.FrostShock] and mana >= 500 and (buff[EL.Icefury].up and talents[EL.ElectrifiedShocks] and ( debuff[EL.ElectrifiedShocks].remains < 2 or buff[EL.Icefury].remains <= gcd )) then
		return EL.FrostShock;
	end

	-- frost_shock,if=buff.icefury.up&talent.electrified_shocks.enabled&maelstrom>=50&debuff.electrified_shocks.remains<2*gcd&buff.stormkeeper.up;
	if talents[EL.FrostShock] and mana >= 500 and (buff[EL.Icefury].up and talents[EL.ElectrifiedShocks] and maelstrom >= 50 and debuff[EL.ElectrifiedShocks].remains < 2 * gcd and buff[EL.Stormkeeper].up) then
		return EL.FrostShock;
	end

	-- lava_beam,if=active_enemies>1&(spell_targets.chain_lightning>1|spell_targets.lava_beam>1)&buff.power_of_the_maelstrom.up&buff.ascendance.remains>cast_time;
	if targets > 1 and ( targets > 1 or targets > 1 ) and buff[EL.PowerOfTheMaelstrom].up and buff[EL.Ascendance].remains > timeShift then
		return EL.LavaBeam;
	end

	-- frost_shock,if=buff.icefury.up&buff.stormkeeper.up&!talent.lava_surge.enabled&!talent.echo_of_the_elements.enabled&!talent.primordial_surge.enabled&talent.elemental_blast.enabled&(maelstrom>=61&maelstrom<75&cooldown.lava_burst.remains>gcd|maelstrom>=49&maelstrom<63&cooldown.lava_burst.ready);
	if talents[EL.FrostShock] and mana >= 500 and (buff[EL.Icefury].up and buff[EL.Stormkeeper].up and not talents[EL.LavaSurge] and not talents[EL.EchoOfTheElements] and not talents[EL.PrimordialSurge] and talents[EL.ElementalBlast] and ( maelstrom >= 61 and maelstrom < 75 and cooldown[EL.LavaBurst].remains > gcd or maelstrom >= 49 and maelstrom < 63 and cooldown[EL.LavaBurst].ready )) then
		return EL.FrostShock;
	end

	-- frost_shock,if=buff.icefury.up&buff.stormkeeper.up&!talent.lava_surge.enabled&!talent.echo_of_the_elements.enabled&!talent.elemental_blast.enabled&(maelstrom>=36&maelstrom<50&cooldown.lava_burst.remains>gcd|maelstrom>=24&maelstrom<38&cooldown.lava_burst.ready);
	if talents[EL.FrostShock] and mana >= 500 and (buff[EL.Icefury].up and buff[EL.Stormkeeper].up and not talents[EL.LavaSurge] and not talents[EL.EchoOfTheElements] and not talents[EL.ElementalBlast] and ( maelstrom >= 36 and maelstrom < 50 and cooldown[EL.LavaBurst].remains > gcd or maelstrom >= 24 and maelstrom < 38 and cooldown[EL.LavaBurst].ready )) then
		return EL.FrostShock;
	end

	-- lava_burst,if=buff.windspeakers_lava_resurgence.up&(talent.echo_of_the_elements.enabled|talent.lava_surge.enabled|talent.primordial_surge.enabled|maelstrom>=63&talent.master_of_the_elements.enabled|maelstrom>=38&buff.echoes_of_great_sundering.up&active_enemies>1&(spell_targets.chain_lightning>1|spell_targets.lava_beam>1)|!talent.elemental_blast.enabled);
	if talents[EL.LavaBurst] and cooldown[EL.LavaBurst].ready and mana >= 1250 and currentSpell ~= EL.LavaBurst and (buff[EL.WindspeakersLavaResurgence].up and ( talents[EL.EchoOfTheElements] or talents[EL.LavaSurge] or talents[EL.PrimordialSurge] or maelstrom >= 63 and talents[EL.MasterOfTheElements] or maelstrom >= 38 and buff[EL.EchoesOfGreatSundering].up and targets > 1 and ( targets > 1 or targets > 1 ) or not talents[EL.ElementalBlast] )) then
		return EL.LavaBurst;
	end

	-- lava_burst,if=cooldown_react&buff.lava_surge.up&(talent.echo_of_the_elements.enabled|talent.lava_surge.enabled|talent.primordial_surge.enabled|!talent.master_of_the_elements.enabled|!talent.elemental_blast.enabled);
	if talents[EL.LavaBurst] and cooldown[EL.LavaBurst].ready and mana >= 1250 and currentSpell ~= EL.LavaBurst and (cooldownReact and buff[EL.LavaSurge].up and ( talents[EL.EchoOfTheElements] or talents[EL.LavaSurge] or talents[EL.PrimordialSurge] or not talents[EL.MasterOfTheElements] or not talents[EL.ElementalBlast] )) then
		return EL.LavaBurst;
	end

	-- lava_burst,if=talent.master_of_the_elements.enabled&!buff.master_of_the_elements.up&maelstrom>=50&!talent.swelling_maelstrom.enabled&maelstrom<=80;
	if talents[EL.LavaBurst] and cooldown[EL.LavaBurst].ready and mana >= 1250 and currentSpell ~= EL.LavaBurst and (talents[EL.MasterOfTheElements] and not buff[EL.MasterOfTheElements].up and maelstrom >= 50 and not talents[EL.SwellingMaelstrom] and maelstrom <= 80) then
		return EL.LavaBurst;
	end

	-- lava_burst,if=talent.master_of_the_elements.enabled&!buff.master_of_the_elements.up&(maelstrom>=75|maelstrom>=50&!talent.elemental_blast.enabled)&talent.swelling_maelstrom.enabled&maelstrom<=130;
	if talents[EL.LavaBurst] and cooldown[EL.LavaBurst].ready and mana >= 1250 and currentSpell ~= EL.LavaBurst and (talents[EL.MasterOfTheElements] and not buff[EL.MasterOfTheElements].up and ( maelstrom >= 75 or maelstrom >= 50 and not talents[EL.ElementalBlast] ) and talents[EL.SwellingMaelstrom] and maelstrom <= 130) then
		return EL.LavaBurst;
	end

	-- earthquake,if=buff.echoes_of_great_sundering.up&(!talent.elemental_blast.enabled&active_enemies<2|active_enemies>1);
	if talents[EL.Earthquake] and maelstrom >= 50 and (buff[EL.EchoesOfGreatSundering].up and ( not talents[EL.ElementalBlast] and targets < 2 or targets > 1 )) then
		return EL.Earthquake;
	end

	-- earthquake,if=active_enemies>1&(spell_targets.chain_lightning>1|spell_targets.lava_beam>1)&!talent.echoes_of_great_sundering.enabled&!talent.elemental_blast.enabled;
	if talents[EL.Earthquake] and maelstrom >= 50 and (targets > 1 and ( targets > 1 or targets > 1 ) and not talents[EL.EchoesOfGreatSundering] and not talents[EL.ElementalBlast]) then
		return EL.Earthquake;
	end

	-- elemental_blast;
	if talents[EL.ElementalBlast] and mana >= 0 and maelstrom >= 75 and currentSpell ~= EL.ElementalBlast then
		return EL.ElementalBlast;
	end

	-- earth_shock;
	if talents[EL.EarthShock] and maelstrom >= 50 then
		return EL.EarthShock;
	end

	-- lava_burst,target_if=dot.flame_shock.remains>2,if=buff.flux_melting.up&active_enemies>1;
	if talents[EL.LavaBurst] and cooldown[EL.LavaBurst].ready and mana >= 1250 and currentSpell ~= EL.LavaBurst and (buff[EL.FluxMelting].up and targets > 1) then
		return EL.LavaBurst;
	end

	-- lava_burst,target_if=dot.flame_shock.remains>2,if=enemies=1&talent.deeply_rooted_elements.enabled;
	if talents[EL.LavaBurst] and cooldown[EL.LavaBurst].ready and mana >= 1250 and currentSpell ~= EL.LavaBurst and (talents[EL.DeeplyRootedElements]) then
		return EL.LavaBurst;
	end

	-- frost_shock,if=buff.icefury.up&talent.flux_melting.enabled&!buff.flux_melting.up;
	if talents[EL.FrostShock] and mana >= 500 and (buff[EL.Icefury].up and talents[EL.FluxMelting] and not buff[EL.FluxMelting].up) then
		return EL.FrostShock;
	end

	-- frost_shock,if=buff.icefury.up&(talent.electrified_shocks.enabled&debuff.electrified_shocks.remains<2|buff.icefury.remains<6);
	if talents[EL.FrostShock] and mana >= 500 and (buff[EL.Icefury].up and ( talents[EL.ElectrifiedShocks] and debuff[EL.ElectrifiedShocks].remains < 2 or buff[EL.Icefury].remains < 6 )) then
		return EL.FrostShock;
	end

	-- lava_burst,target_if=dot.flame_shock.remains>2,if=talent.echo_of_the_elements.enabled|talent.lava_surge.enabled|talent.primordial_surge.enabled|!talent.elemental_blast.enabled|!talent.master_of_the_elements.enabled|buff.stormkeeper.up;
	if talents[EL.LavaBurst] and cooldown[EL.LavaBurst].ready and mana >= 1250 and currentSpell ~= EL.LavaBurst and (talents[EL.EchoOfTheElements] or talents[EL.LavaSurge] or talents[EL.PrimordialSurge] or not talents[EL.ElementalBlast] or not talents[EL.MasterOfTheElements] or buff[EL.Stormkeeper].up) then
		return EL.LavaBurst;
	end

	-- chain_lightning,if=buff.power_of_the_maelstrom.up&talent.unrelenting_calamity.enabled&active_enemies>1&(spell_targets.chain_lightning>1|spell_targets.lava_beam>1);
	if talents[EL.ChainLightning] and mana >= 500 and currentSpell ~= EL.ChainLightning and (buff[EL.PowerOfTheMaelstrom].up and talents[EL.UnrelentingCalamity] and targets > 1 and ( targets > 1 or targets > 1 )) then
		return EL.ChainLightning;
	end

	-- lightning_bolt,if=buff.power_of_the_maelstrom.up&talent.unrelenting_calamity.enabled;
	if buff[EL.PowerOfTheMaelstrom].up and talents[EL.UnrelentingCalamity] then
		return EL.LightningBolt;
	end

	-- icefury;
	if talents[EL.Icefury] and cooldown[EL.Icefury].ready and mana >= 1500 and currentSpell ~= EL.Icefury then
		return EL.Icefury;
	end

	-- chain_lightning,if=pet.storm_elemental.active&debuff.lightning_rod.up&(debuff.electrified_shocks.up|buff.power_of_the_maelstrom.up)&active_enemies>1&(spell_targets.chain_lightning>1|spell_targets.lava_beam>1);
	if talents[EL.ChainLightning] and mana >= 500 and currentSpell ~= EL.ChainLightning and (stormElementalActive and debuff[EL.LightningRod].up and ( debuff[EL.ElectrifiedShocks].up or buff[EL.PowerOfTheMaelstrom].up ) and targets > 1 and ( targets > 1 or targets > 1 )) then
		return EL.ChainLightning;
	end

	-- lightning_bolt,if=pet.storm_elemental.active&debuff.lightning_rod.up&(debuff.electrified_shocks.up|buff.power_of_the_maelstrom.up);
	if stormElementalActive and debuff[EL.LightningRod].up and ( debuff[EL.ElectrifiedShocks].up or buff[EL.PowerOfTheMaelstrom].up ) then
		return EL.LightningBolt;
	end

	-- frost_shock,if=buff.icefury.up&buff.master_of_the_elements.up&!buff.lava_surge.up&!talent.electrified_shocks.enabled&!talent.flux_melting.enabled&cooldown.lava_burst.charges_fractional<1.0&talent.echo_of_the_elements.enabled;
	if talents[EL.FrostShock] and mana >= 500 and (buff[EL.Icefury].up and buff[EL.MasterOfTheElements].up and not buff[EL.LavaSurge].up and not talents[EL.ElectrifiedShocks] and not talents[EL.FluxMelting] and cooldown[EL.LavaBurst].charges < 1.0 and talents[EL.EchoOfTheElements]) then
		return EL.FrostShock;
	end

	-- frost_shock,if=buff.icefury.up&talent.flux_melting.enabled;
	if talents[EL.FrostShock] and mana >= 500 and (buff[EL.Icefury].up and talents[EL.FluxMelting]) then
		return EL.FrostShock;
	end

	-- chain_lightning,if=buff.master_of_the_elements.up&!buff.lava_surge.up&(cooldown.lava_burst.charges_fractional<1.0&talent.echo_of_the_elements.enabled)&active_enemies>1&(spell_targets.chain_lightning>1|spell_targets.lava_beam>1);
	if talents[EL.ChainLightning] and mana >= 500 and currentSpell ~= EL.ChainLightning and (buff[EL.MasterOfTheElements].up and not buff[EL.LavaSurge].up and ( cooldown[EL.LavaBurst].charges < 1.0 and talents[EL.EchoOfTheElements] ) and targets > 1 and ( targets > 1 or targets > 1 )) then
		return EL.ChainLightning;
	end

	-- lightning_bolt,if=buff.master_of_the_elements.up&!buff.lava_surge.up&(cooldown.lava_burst.charges_fractional<1.0&talent.echo_of_the_elements.enabled);
	if buff[EL.MasterOfTheElements].up and not buff[EL.LavaSurge].up and ( cooldown[EL.LavaBurst].charges < 1.0 and talents[EL.EchoOfTheElements] ) then
		return EL.LightningBolt;
	end

	-- frost_shock,if=buff.icefury.up&!talent.electrified_shocks.enabled&!talent.flux_melting.enabled;
	if talents[EL.FrostShock] and mana >= 500 and (buff[EL.Icefury].up and not talents[EL.ElectrifiedShocks] and not talents[EL.FluxMelting]) then
		return EL.FrostShock;
	end

	-- chain_lightning,if=active_enemies>1&(spell_targets.chain_lightning>1|spell_targets.lava_beam>1);
	if talents[EL.ChainLightning] and mana >= 500 and currentSpell ~= EL.ChainLightning and (targets > 1 and ( targets > 1 or targets > 1 )) then
		return EL.ChainLightning;
	end

	-- lightning_bolt;
	-- EL.LightningBolt;

	-- flame_shock,moving=1,target_if=refreshable;
	if cooldown[EL.FlameShock].ready and mana >= 750 then
		return EL.FlameShock;
	end

	-- flame_shock,moving=1,if=movement.distance>6;
	if cooldown[EL.FlameShock].ready and mana >= 750 then
		return EL.FlameShock;
	end

	-- frost_shock,moving=1;
	if talents[EL.FrostShock] and mana >= 500 then
		return EL.FrostShock;
	end
end


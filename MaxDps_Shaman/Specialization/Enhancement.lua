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

local EH = {
	WindfuryWeapon = 33757,
	FlametongueWeapon = 318038,
	LightningShield = 192106,
	WindfuryTotem = 8512,
	FeralSpirit = 51533,
	WitchDoctorsAncestry = 384447,
	DoomWinds = 384352,
	Ascendance = 114051,
	Bloodlust = 2825,
	FlameShock = 188389,
	CrashingStorms = 334308,
	UnrulyWinds = 390288,
	LightningBolt = 188196,
	PrimordialWave = 375982,
	MaelstromWeapon = 187880,
	SplinteredElements = 382042,
	LavaLash = 60103,
	MoltenAssault = 334033,
	FireNova = 333974,
	ElementalBlast = 117014,
	ElementalSpirits = 262624,
	Windstrike = 115356,
	ThorimsInvocation = 384444,
	ChainLightning = 188443,
	AlphaWolf = 198434,
	Sundering = 197214,
	Tier302pc = 405567,
	LashingFlames = 334046,
	AshenCatalyst = 390370,
	IceStrike = 342240,
	Hailstorm = 334195,
	FrostShock = 196840,
	Stormstrike = 17364,
	DeeplyRootedElements = 378270,
	ConvergingStorms = 384363,
	ClCrashLightning = 187874,
	CracklingThunder = 409834,
	Stormblast = 319930,
	Stormbringer = 201845,
	ElementalAssault = 210853,
	Stormflurry = 344357,
	HotHand = 201900,
	LavaBurst = 51505,
	StaticAccumulation = 384411,
	SwirlingMaelstrom = 384359,
	EarthElemental = 198103,
};
local A = {
};
function Shaman:Enhancement()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;

	-- feral_spirit;
	if talents[EH.FeralSpirit] and cooldown[EH.FeralSpirit].ready then
		return EH.FeralSpirit;
	end

	-- ascendance,if=dot.flame_shock.ticking&((ti_lightning_bolt&active_enemies=1&raid_event.adds.in>=90)|(ti_chain_lightning&active_enemies>1));
	if talents[EH.Ascendance] and cooldown[EH.Ascendance].ready and (debuff[EH.FlameShock].up and ( ( targets == 1 ) or ( targets > 1 ) )) then
		return EH.Ascendance;
	end

	-- doom_winds,if=raid_event.adds.in>=90|active_enemies>1;
	if talents[EH.DoomWinds] and cooldown[EH.DoomWinds].ready and ( targets > 1) then
		return EH.DoomWinds;
	end

	-- call_action_list,name=single,if=active_enemies=1;
	if targets == 1 then
		local result = Shaman:EnhancementSingle();
		if result then
			return result;
		end
	end

	-- call_action_list,name=aoe,if=active_enemies>1;
	if targets > 1 then
		local result = Shaman:EnhancementAoe();
		if result then
			return result;
		end
	end
end
function Shaman:EnhancementAoe()
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

	-- crash_lightning,if=talent.crashing_storms.enabled&((talent.unruly_winds.enabled&active_enemies>=10)|active_enemies>=15);
	if talents[EH.CrashingStorms] and ( ( talents[EH.UnrulyWinds] and targets >= 10 ) or targets >= 15 ) then
		return EH.CrashLightning;
	end

	-- lightning_bolt,if=(active_dot.flame_shock=active_enemies|active_dot.flame_shock=6)&buff.primordial_wave.up&buff.maelstrom_weapon.stack=buff.maelstrom_weapon.max_stack&(!buff.splintered_elements.up|fight_remains<=12|raid_event.adds.remains<=gcd);
	if mana >= 500 and currentSpell ~= EH.LightningBolt and (( activeDot[EH.FlameShock] == targets or activeDot[EH.FlameShock] == 6 ) and buff[EH.PrimordialWave].up and buff[EH.MaelstromWeapon].count == buff[EH.MaelstromWeapon].maxStacks and ( not buff[EH.SplinteredElements].up or timeToDie <= 12 or raid_event.adds.remains <= gcd )) then
		return EH.LightningBolt;
	end

	-- lava_lash,if=talent.molten_assault.enabled&(talent.primordial_wave.enabled|talent.fire_nova.enabled)&dot.flame_shock.ticking&(active_dot.flame_shock<active_enemies)&active_dot.flame_shock<6;
	if talents[EH.LavaLash] and cooldown[EH.LavaLash].ready and mana >= 400 and (talents[EH.MoltenAssault] and ( talents[EH.PrimordialWave] or talents[EH.FireNova] ) and debuff[EH.FlameShock].up and ( activeDot[EH.FlameShock] < targets ) and activeDot[EH.FlameShock] < 6) then
		return EH.LavaLash;
	end

	-- primordial_wave,target_if=min:dot.flame_shock.remains,cycle_targets=1,if=!buff.primordial_wave.up;
	if talents[EH.PrimordialWave] and cooldown[EH.PrimordialWave].ready and mana >= 1500 and (not buff[EH.PrimordialWave].up) then
		return EH.PrimordialWave;
	end

	-- elemental_blast,if=(!talent.elemental_spirits.enabled|(talent.elemental_spirits.enabled&(charges=max_charges|buff.feral_spirit.up)))&buff.maelstrom_weapon.stack=buff.maelstrom_weapon.max_stack&(!talent.crashing_storms.enabled|active_enemies<=3);
	if talents[EH.ElementalBlast] and cooldown[EH.ElementalBlast].ready and mana >= 1375 and maelstrom >= 0 and currentSpell ~= EH.ElementalBlast and (( not talents[EH.ElementalSpirits] or ( talents[EH.ElementalSpirits] and ( cooldown[EH.ElementalBlast].charges == cooldown[EH.ElementalBlast].maxCharges or buff[EH.FeralSpirit].up ) ) ) and buff[EH.MaelstromWeapon].count == buff[EH.MaelstromWeapon].maxStacks and ( not talents[EH.CrashingStorms] or targets <= 3 )) then
		return EH.ElementalBlast;
	end

	-- windstrike,if=talent.thorims_invocation.enabled&ti_chain_lightning&buff.maelstrom_weapon.stack>1;
	if cooldown[EH.Windstrike].ready and (talents[EH.ThorimsInvocation] and buff[EH.MaelstromWeapon].count > 1) then
		return EH.Windstrike;
	end

	-- chain_lightning,if=buff.maelstrom_weapon.stack=buff.maelstrom_weapon.max_stack;
	if talents[EH.ChainLightning] and mana >= 500 and currentSpell ~= EH.ChainLightning and (buff[EH.MaelstromWeapon].count == buff[EH.MaelstromWeapon].maxStacks) then
		return EH.ChainLightning;
	end

	-- crash_lightning,if=buff.doom_winds.up|!buff.crash_lightning.up|(talent.alpha_wolf.enabled&feral_spirit.active&alpha_wolf_min_remains=0);
	if buff[EH.DoomWinds].up or not buff[EH.CrashLightning].up or ( talents[EH.AlphaWolf] and feralSpiritActive ) then
		return EH.CrashLightning;
	end

	-- sundering,if=buff.doom_winds.up|set_bonus.tier30_2pc;
	if talents[EH.Sundering] and cooldown[EH.Sundering].ready and mana >= 3000 and (buff[EH.DoomWinds].up or MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2)) then
		return EH.Sundering;
	end

	-- fire_nova,if=active_dot.flame_shock=6|(active_dot.flame_shock>=4&active_dot.flame_shock=active_enemies);
	if talents[EH.FireNova] and cooldown[EH.FireNova].ready and mana >= 500 and (activeDot[EH.FlameShock] == 6 or ( activeDot[EH.FlameShock] >= 4 and activeDot[EH.FlameShock] == targets )) then
		return EH.FireNova;
	end

	-- lava_lash,target_if=min:debuff.lashing_flames.remains,cycle_targets=1,if=talent.lashing_flames.enabled;
	if talents[EH.LavaLash] and cooldown[EH.LavaLash].ready and mana >= 400 and (talents[EH.LashingFlames]) then
		return EH.LavaLash;
	end

	-- lava_lash,if=(talent.molten_assault.enabled&dot.flame_shock.ticking&(active_dot.flame_shock<active_enemies)&active_dot.flame_shock<6)|(talent.ashen_catalyst.enabled&buff.ashen_catalyst.stack=buff.ashen_catalyst.max_stack);
	if talents[EH.LavaLash] and cooldown[EH.LavaLash].ready and mana >= 400 and (( talents[EH.MoltenAssault] and debuff[EH.FlameShock].up and ( activeDot[EH.FlameShock] < targets ) and activeDot[EH.FlameShock] < 6 ) or ( talents[EH.AshenCatalyst] and buff[EH.AshenCatalyst].count == buff[EH.AshenCatalyst].maxStacks )) then
		return EH.LavaLash;
	end

	-- ice_strike,if=talent.hailstorm.enabled&!buff.ice_strike.up;
	if talents[EH.IceStrike] and cooldown[EH.IceStrike].ready and mana >= 1650 and (talents[EH.Hailstorm] and not buff[EH.IceStrike].up) then
		return EH.IceStrike;
	end

	-- frost_shock,if=talent.hailstorm.enabled&buff.hailstorm.up;
	if talents[EH.FrostShock] and mana >= 500 and (talents[EH.Hailstorm] and buff[EH.Hailstorm].up) then
		return EH.FrostShock;
	end

	-- sundering;
	if talents[EH.Sundering] and cooldown[EH.Sundering].ready and mana >= 3000 then
		return EH.Sundering;
	end

	-- flame_shock,if=talent.molten_assault.enabled&!ticking;
	if cooldown[EH.FlameShock].ready and mana >= 750 and (talents[EH.MoltenAssault] and not debuff[EH.FlameShock].up) then
		return EH.FlameShock;
	end

	-- flame_shock,target_if=min:dot.flame_shock.remains,cycle_targets=1,if=(talent.fire_nova.enabled|talent.primordial_wave.enabled)&(active_dot.flame_shock<active_enemies)&active_dot.flame_shock<6;
	if cooldown[EH.FlameShock].ready and mana >= 750 and (( talents[EH.FireNova] or talents[EH.PrimordialWave] ) and ( activeDot[EH.FlameShock] < targets ) and activeDot[EH.FlameShock] < 6) then
		return EH.FlameShock;
	end

	-- fire_nova,if=active_dot.flame_shock>=3;
	if talents[EH.FireNova] and cooldown[EH.FireNova].ready and mana >= 500 and (activeDot[EH.FlameShock] >= 3) then
		return EH.FireNova;
	end

	-- stormstrike,if=buff.crash_lightning.up&(talent.deeply_rooted_elements.enabled|buff.converging_storms.stack=6);
	if talents[EH.Stormstrike] and cooldown[EH.Stormstrike].ready and mana >= 1000 and (buff[EH.CrashLightning].up and ( talents[EH.DeeplyRootedElements] or buff[EH.ConvergingStorms].count == 6 )) then
		return EH.Stormstrike;
	end

	-- crash_lightning,if=talent.crashing_storms.enabled&buff.cl_crash_lightning.up&active_enemies>=4;
	if talents[EH.CrashingStorms] and buff[EH.ClCrashLightning].up and targets >= 4 then
		return EH.CrashLightning;
	end

	-- windstrike;
	if cooldown[EH.Windstrike].ready then
		return EH.Windstrike;
	end

	-- stormstrike;
	if talents[EH.Stormstrike] and cooldown[EH.Stormstrike].ready and mana >= 1000 then
		return EH.Stormstrike;
	end

	-- ice_strike;
	if talents[EH.IceStrike] and cooldown[EH.IceStrike].ready and mana >= 1650 then
		return EH.IceStrike;
	end

	-- lava_lash;
	if talents[EH.LavaLash] and cooldown[EH.LavaLash].ready and mana >= 400 then
		return EH.LavaLash;
	end

	-- crash_lightning;
	-- EH.CrashLightning;

	-- fire_nova,if=active_dot.flame_shock>=2;
	if talents[EH.FireNova] and cooldown[EH.FireNova].ready and mana >= 500 and (activeDot[EH.FlameShock] >= 2) then
		return EH.FireNova;
	end

	-- elemental_blast,if=(!talent.elemental_spirits.enabled|(talent.elemental_spirits.enabled&(charges=max_charges|buff.feral_spirit.up)))&buff.maelstrom_weapon.stack>=5&(!talent.crashing_storms.enabled|active_enemies<=3);
	if talents[EH.ElementalBlast] and cooldown[EH.ElementalBlast].ready and mana >= 1375 and maelstrom >= 0 and currentSpell ~= EH.ElementalBlast and (( not talents[EH.ElementalSpirits] or ( talents[EH.ElementalSpirits] and ( cooldown[EH.ElementalBlast].charges == cooldown[EH.ElementalBlast].maxCharges or buff[EH.FeralSpirit].up ) ) ) and buff[EH.MaelstromWeapon].count >= 5 and ( not talents[EH.CrashingStorms] or targets <= 3 )) then
		return EH.ElementalBlast;
	end

	-- chain_lightning,if=buff.maelstrom_weapon.stack>=5;
	if talents[EH.ChainLightning] and mana >= 500 and currentSpell ~= EH.ChainLightning and (buff[EH.MaelstromWeapon].count >= 5) then
		return EH.ChainLightning;
	end

	-- windfury_totem,if=buff.windfury_totem.remains<30;
	if talents[EH.WindfuryTotem] and mana >= 750 and (buff[EH.WindfuryTotem].remains < 30) then
		return EH.WindfuryTotem;
	end

	-- flame_shock,if=!ticking;
	if cooldown[EH.FlameShock].ready and mana >= 750 and (not debuff[EH.FlameShock].up) then
		return EH.FlameShock;
	end

	-- frost_shock,if=!talent.hailstorm.enabled;
	if talents[EH.FrostShock] and mana >= 500 and (not talents[EH.Hailstorm]) then
		return EH.FrostShock;
	end
end

function Shaman:EnhancementSingle()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
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

	-- primordial_wave,if=!dot.flame_shock.ticking&talent.lashing_flames.enabled&(raid_event.adds.in>42|raid_event.adds.in<6);
	if talents[EH.PrimordialWave] and cooldown[EH.PrimordialWave].ready and mana >= 1500 and (not debuff[EH.FlameShock].up and talents[EH.LashingFlames] ) then
		return EH.PrimordialWave;
	end

	-- flame_shock,if=!ticking&talent.lashing_flames.enabled;
	if cooldown[EH.FlameShock].ready and mana >= 750 and (not debuff[EH.FlameShock].up and talents[EH.LashingFlames]) then
		return EH.FlameShock;
	end

	-- elemental_blast,if=buff.maelstrom_weapon.stack>=5&talent.elemental_spirits.enabled&feral_spirit.active>=4;
	if talents[EH.ElementalBlast] and cooldown[EH.ElementalBlast].ready and mana >= 1375 and maelstrom >= 0 and currentSpell ~= EH.ElementalBlast and (buff[EH.MaelstromWeapon].count >= 5 and talents[EH.ElementalSpirits] and feralSpiritActive >= 4) then
		return EH.ElementalBlast;
	end

	-- sundering,if=set_bonus.tier30_2pc&raid_event.adds.in>=40;
	if talents[EH.Sundering] and cooldown[EH.Sundering].ready and mana >= 3000 and (MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2) ) then
		return EH.Sundering;
	end

	-- lightning_bolt,if=buff.maelstrom_weapon.stack>=5&buff.crackling_thunder.down&buff.ascendance.up&ti_chain_lightning&(buff.ascendance.remains>(cooldown.strike.remains+gcd));
	if mana >= 500 and currentSpell ~= EH.LightningBolt and (buff[EH.MaelstromWeapon].count >= 5 and not buff[EH.CracklingThunder].up and buff[EH.Ascendance].up and ( buff[EH.Ascendance].remains > ( cooldown[EH.Strike].remains + gcd ) )) then
		return EH.LightningBolt;
	end

	-- windstrike,if=talent.thorims_invocation.enabled&buff.maelstrom_weapon.stack>=1&(talent.deeply_rooted_elements.enabled|(talent.stormblast.enabled&buff.stormbringer.up)|(talent.elemental_assault.enabled&talent.stormflurry.enabled)|ti_lightning_bolt);
	if cooldown[EH.Windstrike].ready and (talents[EH.ThorimsInvocation] and buff[EH.MaelstromWeapon].count >= 1 and ( talents[EH.DeeplyRootedElements] or ( talents[EH.Stormblast] and buff[EH.Stormbringer].up ) or ( talents[EH.ElementalAssault] and talents[EH.Stormflurry] ) )) then
		return EH.Windstrike;
	end

	-- stormstrike,if=buff.doom_winds.up|talent.deeply_rooted_elements.enabled|(talent.stormblast.enabled&buff.stormbringer.up)|((talent.elemental_assault.enabled&talent.stormflurry.enabled)&buff.maelstrom_weapon.stack<buff.maelstrom_weapon.max_stack);
	if talents[EH.Stormstrike] and cooldown[EH.Stormstrike].ready and mana >= 1000 and (buff[EH.DoomWinds].up or talents[EH.DeeplyRootedElements] or ( talents[EH.Stormblast] and buff[EH.Stormbringer].up ) or ( ( talents[EH.ElementalAssault] and talents[EH.Stormflurry] ) and buff[EH.MaelstromWeapon].count < buff[EH.MaelstromWeapon].maxStacks )) then
		return EH.Stormstrike;
	end

	-- lava_lash,if=buff.hot_hand.up;
	if talents[EH.LavaLash] and cooldown[EH.LavaLash].ready and mana >= 400 and (buff[EH.HotHand].up) then
		return EH.LavaLash;
	end

	-- windfury_totem,if=!buff.windfury_totem.up;
	if talents[EH.WindfuryTotem] and mana >= 750 and (not buff[EH.WindfuryTotem].up) then
		return EH.WindfuryTotem;
	end

	-- elemental_blast,if=buff.maelstrom_weapon.stack>=5&charges=max_charges;
	if talents[EH.ElementalBlast] and cooldown[EH.ElementalBlast].ready and mana >= 1375 and maelstrom >= 0 and currentSpell ~= EH.ElementalBlast and (buff[EH.MaelstromWeapon].count >= 5 and cooldown[EH.ElementalBlast].charges == cooldown[EH.ElementalBlast].maxCharges) then
		return EH.ElementalBlast;
	end

	-- lightning_bolt,if=buff.maelstrom_weapon.stack>=5&buff.primordial_wave.up&raid_event.adds.in>buff.primordial_wave.remains&(!buff.splintered_elements.up|fight_remains<=12);
	if mana >= 500 and currentSpell ~= EH.LightningBolt and (buff[EH.MaelstromWeapon].count >= 5 and buff[EH.PrimordialWave].up and ( not buff[EH.SplinteredElements].up or timeToDie <= 12 )) then
		return EH.LightningBolt;
	end

	-- chain_lightning,if=buff.maelstrom_weapon.stack>=5&buff.crackling_thunder.up&talent.elemental_spirits.enabled;
	if talents[EH.ChainLightning] and mana >= 500 and currentSpell ~= EH.ChainLightning and (buff[EH.MaelstromWeapon].count >= 5 and buff[EH.CracklingThunder].up and talents[EH.ElementalSpirits]) then
		return EH.ChainLightning;
	end

	-- elemental_blast,if=buff.maelstrom_weapon.stack>=5&(buff.feral_spirit.up|!talent.elemental_spirits.enabled);
	if talents[EH.ElementalBlast] and cooldown[EH.ElementalBlast].ready and mana >= 1375 and maelstrom >= 0 and currentSpell ~= EH.ElementalBlast and (buff[EH.MaelstromWeapon].count >= 5 and ( buff[EH.FeralSpirit].up or not talents[EH.ElementalSpirits] )) then
		return EH.ElementalBlast;
	end

	-- lava_burst,if=!talent.thorims_invocation.enabled&buff.maelstrom_weapon.stack>=5;
	if talents[EH.LavaBurst] and cooldown[EH.LavaBurst].ready and mana >= 1250 and currentSpell ~= EH.LavaBurst and (not talents[EH.ThorimsInvocation] and buff[EH.MaelstromWeapon].count >= 5) then
		return EH.LavaBurst;
	end

	-- lightning_bolt,if=((buff.maelstrom_weapon.stack=buff.maelstrom_weapon.max_stack)|(talent.static_accumulation.enabled&buff.maelstrom_weapon.stack>=5))&buff.primordial_wave.down;
	if mana >= 500 and currentSpell ~= EH.LightningBolt and (( ( buff[EH.MaelstromWeapon].count == buff[EH.MaelstromWeapon].maxStacks ) or ( talents[EH.StaticAccumulation] and buff[EH.MaelstromWeapon].count >= 5 ) ) and not buff[EH.PrimordialWave].up) then
		return EH.LightningBolt;
	end

	-- ice_strike,if=buff.doom_winds.up;
	if talents[EH.IceStrike] and cooldown[EH.IceStrike].ready and mana >= 1650 and (buff[EH.DoomWinds].up) then
		return EH.IceStrike;
	end

	-- sundering,if=buff.doom_winds.up&raid_event.adds.in>=40;
	if talents[EH.Sundering] and cooldown[EH.Sundering].ready and mana >= 3000 and (buff[EH.DoomWinds].up) then
		return EH.Sundering;
	end

	-- crash_lightning,if=buff.doom_winds.up|(talent.alpha_wolf.enabled&feral_spirit.active&alpha_wolf_min_remains=0);
	if buff[EH.DoomWinds].up or ( talents[EH.AlphaWolf] and feralSpiritActive ) then
		return EH.CrashLightning;
	end

	-- primordial_wave,if=raid_event.adds.in>42|raid_event.adds.in<6;
	if talents[EH.PrimordialWave] and cooldown[EH.PrimordialWave].ready and mana >= 1500 then
		return EH.PrimordialWave;
	end

	-- flame_shock,if=!ticking;
	if cooldown[EH.FlameShock].ready and mana >= 750 and (not debuff[EH.FlameShock].up) then
		return EH.FlameShock;
	end

	-- lava_lash,if=talent.molten_assault.enabled&dot.flame_shock.refreshable;
	if talents[EH.LavaLash] and cooldown[EH.LavaLash].ready and mana >= 400 and (talents[EH.MoltenAssault] and debuff[EH.FlameShock].refreshable) then
		return EH.LavaLash;
	end

	-- ice_strike,if=!buff.ice_strike.up;
	if talents[EH.IceStrike] and cooldown[EH.IceStrike].ready and mana >= 1650 and (not buff[EH.IceStrike].up) then
		return EH.IceStrike;
	end

	-- frost_shock,if=buff.hailstorm.up;
	if talents[EH.FrostShock] and mana >= 500 and (buff[EH.Hailstorm].up) then
		return EH.FrostShock;
	end

	-- lava_lash;
	if talents[EH.LavaLash] and cooldown[EH.LavaLash].ready and mana >= 400 then
		return EH.LavaLash;
	end

	-- ice_strike;
	if talents[EH.IceStrike] and cooldown[EH.IceStrike].ready and mana >= 1650 then
		return EH.IceStrike;
	end

	-- windstrike;
	if cooldown[EH.Windstrike].ready then
		return EH.Windstrike;
	end

	-- stormstrike;
	if talents[EH.Stormstrike] and cooldown[EH.Stormstrike].ready and mana >= 1000 then
		return EH.Stormstrike;
	end

	-- sundering,if=raid_event.adds.in>=40;
	if talents[EH.Sundering] and cooldown[EH.Sundering].ready and mana >= 3000 then
		return EH.Sundering;
	end

	-- fire_nova,if=talent.swirling_maelstrom.enabled&active_dot.flame_shock&buff.maelstrom_weapon.stack<buff.maelstrom_weapon.max_stack;
	if talents[EH.FireNova] and cooldown[EH.FireNova].ready and mana >= 500 and (talents[EH.SwirlingMaelstrom] and activeDot[EH.FlameShock] and buff[EH.MaelstromWeapon].count < buff[EH.MaelstromWeapon].maxStacks) then
		return EH.FireNova;
	end

	-- lightning_bolt,if=talent.hailstorm.enabled&buff.maelstrom_weapon.stack>=5&buff.primordial_wave.down;
	if mana >= 500 and currentSpell ~= EH.LightningBolt and (talents[EH.Hailstorm] and buff[EH.MaelstromWeapon].count >= 5 and not buff[EH.PrimordialWave].up) then
		return EH.LightningBolt;
	end

	-- frost_shock;
	if talents[EH.FrostShock] and mana >= 500 then
		return EH.FrostShock;
	end

	-- crash_lightning;
	-- EH.CrashLightning;

	-- fire_nova,if=active_dot.flame_shock;
	if talents[EH.FireNova] and cooldown[EH.FireNova].ready and mana >= 500 and (activeDot[EH.FlameShock]) then
		return EH.FireNova;
	end

	-- earth_elemental;
	if talents[EH.EarthElemental] and cooldown[EH.EarthElemental].ready then
		return EH.EarthElemental;
	end

	-- flame_shock;
	if cooldown[EH.FlameShock].ready and mana >= 750 then
		return EH.FlameShock;
	end

	-- lightning_bolt,if=buff.maelstrom_weapon.stack>=5&buff.primordial_wave.down;
	if mana >= 500 and currentSpell ~= EH.LightningBolt and (buff[EH.MaelstromWeapon].count >= 5 and not buff[EH.PrimordialWave].up) then
		return EH.LightningBolt;
	end

	-- windfury_totem,if=buff.windfury_totem.remains<30;
	if talents[EH.WindfuryTotem] and mana >= 750 and (buff[EH.WindfuryTotem].remains < 30) then
		return EH.WindfuryTotem;
	end
end


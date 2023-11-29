local _, addonTable = ...;

-- @type MaxDps;
if not MaxDps then return end;
local Warlock = addonTable.Warlock;
local MaxDps = MaxDps;

local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;

local itemID = GetInventoryItemID('player', INVSLOT_MAINHAND);

local mainHandSubClassID = itemID and  select(13, GetItemInfo(itemID));

local TwoHanderWepCheck = mainHandSubClassID and (mainHandSubClassID == 1 or mainHandSubClassID == 5 or mainHandSubClassID == 8 or mainHandSubClassID == 10);

local AF = {
	GrimoireOfSacrifice = 108503,
	SeedOfCorruption = 27243,
	Haunt = 48181,
	UnstableAffliction = 316099,
	SoulSwap = 386951,
	ShadowBolt = 394238,
	MaleficRapture = 324536,
	DreadTouch = 389775,
	Agony = 980,
	Corruption = 172,
	SiphonLife = 63106,
	PhantomSingularity = 205179,
	VileTaint = 278350,
	SoulRot = 386997,
	DrainSoul = 198590,
	ShadowEmbrace = 32388,
	SouleatersGluttony = 389630,
	SummonDarkglare = 205180,
	TormentedCrescendo = 387075,
	Nightfall = 108558,
	DrainLife = 234153,
	InevitableDemise = 334319,
	DoomBlossom = 416621,
	SowTheSeeds = 196226,
	SummonSoulkeeper = 386256,
	TormentedSoul = 386309,
	AbsoluteCorruption = 196103,
	VileTaintDot = 386931,
};
local A = {
};
function Warlock:Affliction()
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
	local soulShards = UnitPower('player', Enum.PowerType.SoulShards);
	local soulShardsMax = UnitPowerMax('player', Enum.PowerType.SoulShards);
	local soulShardsPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local soulShardsRegen = select(2,GetPowerRegen());
	local soulShardsRegenCombined = soulShardsRegen + soulShards;
	local soulShardsDeficit = UnitPowerMax('player', Enum.PowerType.SoulShards) - soulShards;
	local soulShardsTimeToMax = soulShardsMax - soulShards / soulShardsRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- call_action_list,name=variables;
	local result = Warlock:AfflictionVariables();
	if result then
		return result;
	end

	-- call_action_list,name=cleave,if=active_enemies!=1&active_enemies<4|variable.cleave_apl;
	if not targets == 1 and targets < 4 or cleaveApl then
		local result = Warlock:AfflictionCleave();
		if result then
			return result;
		end
	end

	-- call_action_list,name=aoe,if=active_enemies>3;
	if targets > 3 then
		local result = Warlock:AfflictionAoe();
		if result then
			return result;
		end
	end

	-- call_action_list,name=ogcd;
	local result = Warlock:AfflictionOgcd();
	if result then
		return result;
	end

	-- call_action_list,name=items;
	local result = Warlock:AfflictionItems();
	if result then
		return result;
	end

	-- malefic_rapture,if=talent.dread_touch&debuff.dread_touch.remains<2&(dot.agony.ticking&dot.corruption.ticking&(!talent.siphon_life|dot.siphon_life.ticking))&(!talent.phantom_singularity|!cooldown.phantom_singularity.ready)&(!talent.vile_taint|!cooldown.vile_taint.ready)&(!talent.soul_rot|!cooldown.soul_rot.ready);
	if talents[AF.MaleficRapture] and soulShards >= 1 and currentSpell ~= AF.MaleficRapture and (talents[AF.DreadTouch] and debuff[AF.DreadTouch].remains < 2 and ( debuff[AF.Agony].up and debuff[AF.Corruption].up and ( not talents[AF.SiphonLife] or debuff[AF.SiphonLife].up ) ) and ( not talents[AF.PhantomSingularity] or not cooldown[AF.PhantomSingularity].ready ) and ( not talents[AF.VileTaint] or not cooldown[AF.VileTaint].ready ) and ( not talents[AF.SoulRot] or not cooldown[AF.SoulRot].ready )) then
		return AF.MaleficRapture;
	end

	-- unstable_affliction,if=remains<5;
	if talents[AF.UnstableAffliction] and mana >= 500 and currentSpell ~= AF.UnstableAffliction and (debuff[AF.UnstableAffliction].remains < 5) then
		return AF.UnstableAffliction;
	end

	-- agony,if=remains<5;
	if mana >= 500 and (debuff[AF.Agony].remains < 5) then
		return AF.Agony;
	end

	-- corruption,if=remains<5;
	if mana >= 500 and (debuff[AF.Corruption].remains < 5) then
		return AF.Corruption;
	end

	-- siphon_life,if=remains<5;
	if talents[AF.SiphonLife] and mana >= 500 and (debuff[AF.SiphonLife].remains < 5) then
		return AF.SiphonLife;
	end

	-- haunt;
	if talents[AF.Haunt] and cooldown[AF.Haunt].ready and mana >= 1000 and currentSpell ~= AF.Haunt then
		return AF.Haunt;
	end

	-- drain_soul,if=talent.shadow_embrace&(debuff.shadow_embrace.stack<3|debuff.shadow_embrace.remains<3);
	if talents[AF.DrainSoul] and mana >= 0 and (talents[AF.ShadowEmbrace] and ( debuff[AF.ShadowEmbrace].count < 3 or debuff[AF.ShadowEmbrace].remains < 3 )) then
		return AF.DrainSoul;
	end

	-- shadow_bolt,if=talent.shadow_embrace&(debuff.shadow_embrace.stack<3|debuff.shadow_embrace.remains<3);
	if talents[AF.ShadowEmbrace] and ( debuff[AF.ShadowEmbrace].count < 3 or debuff[AF.ShadowEmbrace].remains < 3 ) then
		return AF.ShadowBolt;
	end

	-- phantom_singularity,if=!talent.soul_rot|cooldown.soul_rot.remains<=execute_time|cooldown.soul_rot.remains>=25;
	if talents[AF.PhantomSingularity] and cooldown[AF.PhantomSingularity].ready and mana >= 500 and (not talents[AF.SoulRot] or cooldown[AF.SoulRot].remains <= timeShift or cooldown[AF.SoulRot].remains >= 25) then
		return AF.PhantomSingularity;
	end

	-- vile_taint,if=!talent.soul_rot|cooldown.soul_rot.remains<=execute_time|talent.souleaters_gluttony.rank<2&cooldown.soul_rot.remains>=12;
	if talents[AF.VileTaint] and cooldown[AF.VileTaint].ready and soulShards >= 1 and currentSpell ~= AF.VileTaint and (not talents[AF.SoulRot] or cooldown[AF.SoulRot].remains <= timeShift or talents[AF.SouleatersGluttony] < 2 and cooldown[AF.SoulRot].remains >= 12) then
		return AF.VileTaint;
	end

	-- soul_rot,if=variable.vt_up&variable.ps_up;
	if talents[AF.SoulRot] and cooldown[AF.SoulRot].ready and mana >= 250 and currentSpell ~= AF.SoulRot and (vtUp and psUp) then
		return AF.SoulRot;
	end

	-- summon_darkglare,if=variable.ps_up&variable.vt_up&variable.sr_up|cooldown.invoke_power_infusion_0.duration>0&cooldown.invoke_power_infusion_0.up&!talent.soul_rot;
	if talents[AF.SummonDarkglare] and cooldown[AF.SummonDarkglare].ready and mana >= 1000 and (psUp and vtUp and srUp or cooldown[AF.InvokePowerInfusion0].duration > 0 and cooldown[AF.InvokePowerInfusion0].up and not talents[AF.SoulRot]) then
		return AF.SummonDarkglare;
	end

	-- malefic_rapture,if=soul_shard>4|(talent.tormented_crescendo&buff.tormented_crescendo.stack=1&soul_shard>3);
	if talents[AF.MaleficRapture] and soulShards >= 1 and currentSpell ~= AF.MaleficRapture and (soulShards > 4 or ( talents[AF.TormentedCrescendo] and buff[AF.TormentedCrescendo].count == 1 and soulShards > 3 )) then
		return AF.MaleficRapture;
	end

	-- malefic_rapture,if=talent.tormented_crescendo&buff.tormented_crescendo.react&!debuff.dread_touch.react;
	if talents[AF.MaleficRapture] and soulShards >= 1 and currentSpell ~= AF.MaleficRapture and (talents[AF.TormentedCrescendo] and buff[AF.TormentedCrescendo].count and not debuff[AF.DreadTouch].count) then
		return AF.MaleficRapture;
	end

	-- malefic_rapture,if=talent.tormented_crescendo&buff.tormented_crescendo.stack=2;
	if talents[AF.MaleficRapture] and soulShards >= 1 and currentSpell ~= AF.MaleficRapture and (talents[AF.TormentedCrescendo] and buff[AF.TormentedCrescendo].count == 2) then
		return AF.MaleficRapture;
	end

	-- malefic_rapture,if=variable.cd_dots_up|variable.vt_up&soul_shard>1;
	if talents[AF.MaleficRapture] and soulShards >= 1 and currentSpell ~= AF.MaleficRapture and (cdDotsUp or vtUp and soulShards > 1) then
		return AF.MaleficRapture;
	end

	-- malefic_rapture,if=talent.tormented_crescendo&talent.nightfall&buff.tormented_crescendo.react&buff.nightfall.react;
	if talents[AF.MaleficRapture] and soulShards >= 1 and currentSpell ~= AF.MaleficRapture and (talents[AF.TormentedCrescendo] and talents[AF.Nightfall] and buff[AF.TormentedCrescendo].count and buff[AF.Nightfall].count) then
		return AF.MaleficRapture;
	end

	-- drain_life,if=buff.inevitable_demise.stack>48|buff.inevitable_demise.stack>20&fight_remains<4;
	if mana >= 0 and (buff[AF.InevitableDemise].count > 48 or buff[AF.InevitableDemise].count > 20 and timeToDie < 4) then
		return AF.DrainLife;
	end

	-- drain_soul,if=buff.nightfall.react;
	if talents[AF.DrainSoul] and mana >= 0 and (buff[AF.Nightfall].count) then
		return AF.DrainSoul;
	end

	-- shadow_bolt,if=buff.nightfall.react;
	if buff[AF.Nightfall].count then
		return AF.ShadowBolt;
	end

	-- agony,if=refreshable;
	if mana >= 500 and (debuff[AF.Agony].refreshable) then
		return AF.Agony;
	end

	-- corruption,if=refreshable;
	if mana >= 500 and (debuff[AF.Corruption].refreshable) then
		return AF.Corruption;
	end

	-- drain_soul,interrupt=1;
	if talents[AF.DrainSoul] and mana >= 0 then
		return AF.DrainSoul;
	end

	-- shadow_bolt;
	-- AF.ShadowBolt;
end
function Warlock:AfflictionAoe()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local timeToDie = fd.timeToDie;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;
	local soulShards = UnitPower('player', Enum.PowerType.SoulShards);
	local soulShardsMax = UnitPowerMax('player', Enum.PowerType.SoulShards);
	local soulShardsPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local soulShardsRegen = select(2,GetPowerRegen());
	local soulShardsRegenCombined = soulShardsRegen + soulShards;
	local soulShardsDeficit = UnitPowerMax('player', Enum.PowerType.SoulShards) - soulShards;
	local soulShardsTimeToMax = soulShardsMax - soulShards / soulShardsRegen;

	-- call_action_list,name=ogcd;
	local result = Warlock:AfflictionOgcd();
	if result then
		return result;
	end

	-- call_action_list,name=items;
	local result = Warlock:AfflictionItems();
	if result then
		return result;
	end

	-- haunt;
	if talents[AF.Haunt] and cooldown[AF.Haunt].ready and mana >= 1000 and currentSpell ~= AF.Haunt then
		return AF.Haunt;
	end

	-- vile_taint;
	if talents[AF.VileTaint] and cooldown[AF.VileTaint].ready and soulShards >= 1 and currentSpell ~= AF.VileTaint then
		return AF.VileTaint;
	end

	-- phantom_singularity;
	if talents[AF.PhantomSingularity] and cooldown[AF.PhantomSingularity].ready and mana >= 500 then
		return AF.PhantomSingularity;
	end

	-- soul_rot;
	if talents[AF.SoulRot] and cooldown[AF.SoulRot].ready and mana >= 250 and currentSpell ~= AF.SoulRot then
		return AF.SoulRot;
	end

	-- unstable_affliction,if=remains<5;
	if talents[AF.UnstableAffliction] and mana >= 500 and currentSpell ~= AF.UnstableAffliction and (debuff[AF.UnstableAffliction].remains < 5) then
		return AF.UnstableAffliction;
	end

	-- seed_of_corruption,if=dot.corruption.remains<5;
	if talents[AF.SeedOfCorruption] and soulShards >= 1 and currentSpell ~= AF.SeedOfCorruption and (debuff[AF.Corruption].remains < 5) then
		return AF.SeedOfCorruption;
	end

	-- malefic_rapture,if=talent.malefic_affliction&buff.malefic_affliction.stack<3&talent.doom_blossom;
	if talents[AF.MaleficRapture] and soulShards >= 1 and currentSpell ~= AF.MaleficRapture and (talents[AF.MaleficAffliction] and buff[AF.MaleficAffliction].count < 3 and talents[AF.DoomBlossom]) then
		return AF.MaleficRapture;
	end

	-- agony,target_if=remains<5,if=active_dot.agony<5;
	if mana >= 500 and (activeDot[AF.Agony] < 5) then
		return AF.Agony;
	end

	-- summon_darkglare;
	if talents[AF.SummonDarkglare] and cooldown[AF.SummonDarkglare].ready and mana >= 1000 then
		return AF.SummonDarkglare;
	end

	-- seed_of_corruption,if=talent.sow_the_seeds;
	if talents[AF.SeedOfCorruption] and soulShards >= 1 and currentSpell ~= AF.SeedOfCorruption and (talents[AF.SowTheSeeds]) then
		return AF.SeedOfCorruption;
	end

	-- malefic_rapture;
	if talents[AF.MaleficRapture] and soulShards >= 1 and currentSpell ~= AF.MaleficRapture then
		return AF.MaleficRapture;
	end

	-- drain_life,if=(buff.soul_rot.up|!talent.soul_rot)&buff.inevitable_demise.stack>10;
	if mana >= 0 and (( buff[AF.SoulRot].up or not talents[AF.SoulRot] ) and buff[AF.InevitableDemise].count > 10) then
		return AF.DrainLife;
	end

	-- summon_soulkeeper,if=buff.tormented_soul.stack=10|buff.tormented_soul.stack>3&fight_remains<10;
	if talents[AF.SummonSoulkeeper] and currentSpell ~= AF.SummonSoulkeeper and (buff[AF.TormentedSoul].count == 10 or buff[AF.TormentedSoul].count > 3 and timeToDie < 10) then
		return AF.SummonSoulkeeper;
	end

	-- siphon_life,target_if=remains<5,if=active_dot.siphon_life<3;
	if talents[AF.SiphonLife] and mana >= 500 and (activeDot[AF.SiphonLife] < 3) then
		return AF.SiphonLife;
	end

	-- drain_soul,interrupt_global=1;
	if talents[AF.DrainSoul] and mana >= 0 then
		return AF.DrainSoul;
	end

	-- shadow_bolt;
	-- AF.ShadowBolt;
end

function Warlock:AfflictionCleave()
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
	local gcd = fd.gcd;
	local timeToDie = fd.timeToDie;
	local soulShards = UnitPower('player', Enum.PowerType.SoulShards);
	local soulShardsMax = UnitPowerMax('player', Enum.PowerType.SoulShards);
	local soulShardsPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local soulShardsRegen = select(2,GetPowerRegen());
	local soulShardsRegenCombined = soulShardsRegen + soulShards;
	local soulShardsDeficit = UnitPowerMax('player', Enum.PowerType.SoulShards) - soulShards;
	local soulShardsTimeToMax = soulShardsMax - soulShards / soulShardsRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- call_action_list,name=ogcd;
	local result = Warlock:AfflictionOgcd();
	if result then
		return result;
	end

	-- call_action_list,name=items;
	local result = Warlock:AfflictionItems();
	if result then
		return result;
	end

	-- malefic_rapture,if=soul_shard=5;
	if talents[AF.MaleficRapture] and soulShards >= 1 and currentSpell ~= AF.MaleficRapture and (soulShards == 5) then
		return AF.MaleficRapture;
	end

	-- haunt;
	if talents[AF.Haunt] and cooldown[AF.Haunt].ready and mana >= 1000 and currentSpell ~= AF.Haunt then
		return AF.Haunt;
	end

	-- unstable_affliction,if=remains<5;
	if talents[AF.UnstableAffliction] and mana >= 500 and currentSpell ~= AF.UnstableAffliction and (debuff[AF.UnstableAffliction].remains < 5) then
		return AF.UnstableAffliction;
	end

	-- agony,if=remains<5;
	if mana >= 500 and (debuff[AF.Agony].remains < 5) then
		return AF.Agony;
	end

	-- agony,target_if=!(target=self.target)&remains<5;
	if mana >= 500 then
		return AF.Agony;
	end

	-- siphon_life,if=remains<5;
	if talents[AF.SiphonLife] and mana >= 500 and (debuff[AF.SiphonLife].remains < 5) then
		return AF.SiphonLife;
	end

	-- siphon_life,target_if=!(target=self.target)&remains<3;
	if talents[AF.SiphonLife] and mana >= 500 then
		return AF.SiphonLife;
	end

	-- seed_of_corruption,if=!talent.absolute_corruption&dot.corruption.remains<5;
	if talents[AF.SeedOfCorruption] and soulShards >= 1 and currentSpell ~= AF.SeedOfCorruption and (not talents[AF.AbsoluteCorruption] and debuff[AF.Corruption].remains < 5) then
		return AF.SeedOfCorruption;
	end

	-- corruption,target_if=remains<5&(talent.absolute_corruption|!talent.seed_of_corruption);
	if mana >= 500 then
		return AF.Corruption;
	end

	-- phantom_singularity;
	if talents[AF.PhantomSingularity] and cooldown[AF.PhantomSingularity].ready and mana >= 500 then
		return AF.PhantomSingularity;
	end

	-- vile_taint;
	if talents[AF.VileTaint] and cooldown[AF.VileTaint].ready and soulShards >= 1 and currentSpell ~= AF.VileTaint then
		return AF.VileTaint;
	end

	-- soul_rot;
	if talents[AF.SoulRot] and cooldown[AF.SoulRot].ready and mana >= 250 and currentSpell ~= AF.SoulRot then
		return AF.SoulRot;
	end

	-- summon_darkglare;
	if talents[AF.SummonDarkglare] and cooldown[AF.SummonDarkglare].ready and mana >= 1000 then
		return AF.SummonDarkglare;
	end

	-- malefic_rapture,if=talent.malefic_affliction&buff.malefic_affliction.stack<3;
	if talents[AF.MaleficRapture] and soulShards >= 1 and currentSpell ~= AF.MaleficRapture and (talents[AF.MaleficAffliction] and buff[AF.MaleficAffliction].count < 3) then
		return AF.MaleficRapture;
	end

	-- malefic_rapture,if=talent.dread_touch&debuff.dread_touch.remains<gcd;
	if talents[AF.MaleficRapture] and soulShards >= 1 and currentSpell ~= AF.MaleficRapture and (talents[AF.DreadTouch] and debuff[AF.DreadTouch].remains < gcd) then
		return AF.MaleficRapture;
	end

	-- malefic_rapture,if=!talent.dread_touch&buff.tormented_crescendo.up;
	if talents[AF.MaleficRapture] and soulShards >= 1 and currentSpell ~= AF.MaleficRapture and (not talents[AF.DreadTouch] and buff[AF.TormentedCrescendo].up) then
		return AF.MaleficRapture;
	end

	-- malefic_rapture,if=!talent.dread_touch&(dot.soul_rot.remains>cast_time|dot.phantom_singularity.remains>cast_time|dot.vile_taint_dot.remains>cast_time|pet.darkglare.active);
	if talents[AF.MaleficRapture] and soulShards >= 1 and currentSpell ~= AF.MaleficRapture and (not talents[AF.DreadTouch] and ( debuff[AF.SoulRot].remains > timeShift or debuff[AF.PhantomSingularity].remains > timeShift or debuff[AF.VileTaintDot].remains > timeShift )) then
		return AF.MaleficRapture;
	end

	-- drain_soul,if=buff.nightfall.react;
	if talents[AF.DrainSoul] and mana >= 0 and (buff[AF.Nightfall].count) then
		return AF.DrainSoul;
	end

	-- shadow_bolt,if=buff.nightfall.react;
	if buff[AF.Nightfall].count then
		return AF.ShadowBolt;
	end

	-- drain_life,if=buff.inevitable_demise.stack>48|buff.inevitable_demise.stack>20&fight_remains<4;
	if mana >= 0 and (buff[AF.InevitableDemise].count > 48 or buff[AF.InevitableDemise].count > 20 and timeToDie < 4) then
		return AF.DrainLife;
	end

	-- drain_life,if=buff.soul_rot.up&buff.inevitable_demise.stack>10;
	if mana >= 0 and (buff[AF.SoulRot].up and buff[AF.InevitableDemise].count > 10) then
		return AF.DrainLife;
	end

	-- agony,target_if=refreshable;
	if mana >= 500 then
		return AF.Agony;
	end

	-- corruption,target_if=refreshable;
	if mana >= 500 then
		return AF.Corruption;
	end

	-- drain_soul,interrupt_global=1;
	if talents[AF.DrainSoul] and mana >= 0 then
		return AF.DrainSoul;
	end

	-- shadow_bolt;
	-- AF.ShadowBolt;
end

function Warlock:AfflictionItems()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
end

function Warlock:AfflictionOgcd()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
end

function Warlock:AfflictionVariables()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;

	-- variable,name=ps_up,op=set,value=dot.phantom_singularity.ticking|!talent.phantom_singularity;
	local psUp = debuff[AF.PhantomSingularity].up or not talents[AF.PhantomSingularity];

	-- variable,name=vt_up,op=set,value=dot.vile_taint_dot.ticking|!talent.vile_taint;
	local vtUp = debuff[AF.VileTaintDot].up or not talents[AF.VileTaint];

	-- variable,name=sr_up,op=set,value=dot.soul_rot.ticking|!talent.soul_rot;
	local srUp = debuff[AF.SoulRot].up or not talents[AF.SoulRot];

	-- variable,name=cd_dots_up,op=set,value=variable.ps_up&variable.vt_up&variable.sr_up;
	local cdDotsUp = psUp and vtUp and srUp;

	-- variable,name=has_cds,op=set,value=talent.phantom_singularity|talent.vile_taint|talent.soul_rot|talent.summon_darkglare;
	local hasCds = talents[AF.PhantomSingularity] or talents[AF.VileTaint] or talents[AF.SoulRot] or talents[AF.SummonDarkglare];

	-- variable,name=cds_active,op=set,value=!variable.has_cds|(pet.darkglare.active|variable.cd_dots_up|buff.power_infusion.react);
	local cdsActive = not hasCds or ( cdDotsUp or buff[AF.PowerInfusion].count );
end


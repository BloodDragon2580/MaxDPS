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

local DE = {
	GrimoireFelguard = 111898,
	SummonVilefiend = 264119,
	PowerSiphon = 264130,
	Demonbolt = 264178,
	ShadowBolt = 686,
	HandOfGuldan = 105174,
	NetherPortal = 267217,
	DemonicStrength = 267171,
	Guillotine = 386833,
	BilescourgeBombers = 267211,
	Implosion = 196277,
	Tyrant = 265187,
	SacrificedSouls = 267214,
	TheExpendables = 387600,
	SoulStrike = 264057,
	SummonSoulkeeper = 386256,
	TormentedSoul = 386309,
	DemonicCore = 267102,
	Dreadstalkers = 104316,
	Doom = 603,
	Soulburn = 385899,
	GrandWarlocksDesign = 387084,
};
local A = {
};
function Warlock:Demonology()
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

	-- call_action_list,name=variables;
	local result = Warlock:DemonologyVariables();
	if result then
		return result;
	end

	-- call_action_list,name=fight_end,if=fight_remains<30;
	if timeToDie < 30 then
		local result = Warlock:DemonologyFightEnd();
		if result then
			return result;
		end
	end

	-- hand_of_guldan,if=time<0.5&(fight_remains%%95>40|fight_remains%%95<15);
	if soulShards >= 3 and currentSpell ~= DE.HandOfGuldan and (GetTime() < 0.5 and ( timeToDie / 95 > 40 or timeToDie / 95 < 15 )) then
		return DE.HandOfGuldan;
	end

	-- call_action_list,name=tyrant,if=cooldown.summon_demonic_tyrant.remains<15&cooldown.summon_vilefiend.remains<gcd.max*5&cooldown.call_dreadstalkers.remains<gcd.max*5&(cooldown.grimoire_felguard.remains<10|!set_bonus.tier30_2pc)&(!variable.shadow_timings|variable.tyrant_cd<15|fight_remains<40|buff.power_infusion.up);
	if cooldown[DE.SummonDemonicTyrant].remains < 15 and cooldown[DE.SummonVilefiend].remains < gcd * 5 and cooldown[DE.CallDreadstalkers].remains < gcd * 5 and ( cooldown[DE.GrimoireFelguard].remains < 10 or not MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2) ) and ( not shadowTimings or tyrantCd < 15 or timeToDie < 40 or buff[DE.PowerInfusion].up ) then
		local result = Warlock:DemonologyTyrant();
		if result then
			return result;
		end
	end

	-- call_action_list,name=tyrant,if=cooldown.summon_demonic_tyrant.remains<15&(buff.vilefiend.up|!talent.summon_vilefiend&(buff.grimoire_felguard.up|cooldown.grimoire_felguard.up|!set_bonus.tier30_2pc))&(!variable.shadow_timings|variable.tyrant_cd<15|fight_remains<40|buff.power_infusion.up);
	if cooldown[DE.SummonDemonicTyrant].remains < 15 and ( buff[DE.Vilefiend].up or not talents[DE.SummonVilefiend] and ( buff[DE.GrimoireFelguard].up or cooldown[DE.GrimoireFelguard].up or not MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2) ) ) and ( not shadowTimings or tyrantCd < 15 or timeToDie < 40 or buff[DE.PowerInfusion].up ) then
		local result = Warlock:DemonologyTyrant();
		if result then
			return result;
		end
	end

	-- summon_demonic_tyrant,if=buff.vilefiend.up|buff.grimoire_felguard.up|cooldown.grimoire_felguard.remains>90;
	if buff[DE.Vilefiend].up or buff[DE.GrimoireFelguard].up or cooldown[DE.GrimoireFelguard].remains > 90 then
		return DE.SummonDemonicTyrant;
	end

	-- call_action_list,name=racials,if=pet.demonic_tyrant.active&(buff.nether_portal.remains<=2)|fight_remains<22;
	if ( buff[DE.NetherPortal].remains <= 2 ) or timeToDie < 22 then
		local result = Warlock:DemonologyRacials();
		if result then
			return result;
		end
	end

	-- shadow_bolt,if=talent.fel_covenant&buff.fel_covenant.remains<5&!prev_gcd.1.shadow_bolt&soul_shard<5;
	if mana >= 750 and currentSpell ~= DE.ShadowBolt and (talents[DE.FelCovenant] and buff[DE.FelCovenant].remains < 5 and not spellHistory[1] == DE.ShadowBolt and soulShards < 5) then
		return DE.ShadowBolt;
	end

	-- hand_of_guldan,if=buff.nether_portal.remains>cast_time;
	if soulShards >= 3 and currentSpell ~= DE.HandOfGuldan and (buff[DE.NetherPortal].remains > timeShift) then
		return DE.HandOfGuldan;
	end

	-- demonic_strength,if=buff.nether_portal.remains<gcd.max&(fight_remains>63&!(fight_remains>cooldown.summon_demonic_tyrant.remains+69)|cooldown.summon_demonic_tyrant.remains>30|variable.shadow_timings|buff.rite_of_ruvaraad.up|!talent.summon_demonic_tyrant|!talent.grimoire_felguard|!set_bonus.tier30_2pc);
	if talents[DE.DemonicStrength] and cooldown[DE.DemonicStrength].ready and (buff[DE.NetherPortal].remains < gcd and ( timeToDie > 63 and not ( timeToDie > cooldown[DE.SummonDemonicTyrant].remains + 69 ) or cooldown[DE.SummonDemonicTyrant].remains > 30 or shadowTimings or buff[DE.RiteOfRuvaraad].up or not talents[DE.SummonDemonicTyrant] or not talents[DE.GrimoireFelguard] or not MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2) )) then
		return DE.DemonicStrength;
	end

	-- guillotine,if=buff.nether_portal.remains<gcd.max&(cooldown.demonic_strength.remains|!talent.demonic_strength);
	if talents[DE.Guillotine] and cooldown[DE.Guillotine].ready and (buff[DE.NetherPortal].remains < gcd and ( cooldown[DE.DemonicStrength].remains or not talents[DE.DemonicStrength] )) then
		return DE.Guillotine;
	end

	-- bilescourge_bombers,if=!pet.demonic_tyrant.active;
	if talents[DE.BilescourgeBombers] and cooldown[DE.BilescourgeBombers].ready then
		return DE.BilescourgeBombers;
	end

	-- call_dreadstalkers,if=cooldown.summon_demonic_tyrant.remains>25|variable.tyrant_cd>25|buff.nether_portal.up;
	if cooldown[DE.SummonDemonicTyrant].remains > 25 or tyrantCd > 25 or buff[DE.NetherPortal].up then
		return DE.CallDreadstalkers;
	end

	-- implosion,if=two_cast_imps>0&buff.tyrant.down&active_enemies>1+(talent.sacrificed_souls.enabled)&!prev_gcd.1.implosion;
	if talents[DE.Implosion] and mana >= 1000 and (0 and not buff[DE.Tyrant].up and targets > 1 + ( talents[DE.SacrificedSouls] ) and not spellHistory[1] == DE.Implosion) then
		return DE.Implosion;
	end

	-- implosion,if=buff.wild_imps.stack>9&buff.tyrant.up&active_enemies>2+(1*talent.sacrificed_souls.enabled)&cooldown.call_dreadstalkers.remains>17&talent.the_expendables&!prev_gcd.1.implosion;
	if talents[DE.Implosion] and mana >= 1000 and (buff[DE.WildImps].count > 9 and buff[DE.Tyrant].up and targets > 2 + ( 1 * (talents[DE.SacrificedSouls] and 1 or 0) ) and cooldown[DE.CallDreadstalkers].remains > 17 and talents[DE.TheExpendables] and not spellHistory[1] == DE.Implosion) then
		return DE.Implosion;
	end

	-- soul_strike,if=soul_shard<5&active_enemies>1;
	if talents[DE.SoulStrike] and cooldown[DE.SoulStrike].ready and (soulShards < 5 and targets > 1) then
		return DE.SoulStrike;
	end

	-- summon_soulkeeper,if=buff.tormented_soul.stack=10&active_enemies>1;
	if talents[DE.SummonSoulkeeper] and currentSpell ~= DE.SummonSoulkeeper and (buff[DE.TormentedSoul].count == 10 and targets > 1) then
		return DE.SummonSoulkeeper;
	end

	-- power_siphon,if=buff.demonic_core.stack<2&cooldown.summon_demonic_tyrant.remains>38&(buff.dreadstalkers.down|buff.dreadstalkers.remains>gcd.max*5);
	if talents[DE.PowerSiphon] and cooldown[DE.PowerSiphon].ready and (buff[DE.DemonicCore].count < 2 and cooldown[DE.SummonDemonicTyrant].remains > 38 and ( not buff[DE.Dreadstalkers].up or buff[DE.Dreadstalkers].remains > gcd * 5 )) then
		return DE.PowerSiphon;
	end

	-- hand_of_guldan,if=soul_shard>2;
	if soulShards >= 3 and currentSpell ~= DE.HandOfGuldan and (soulShards > 2) then
		return DE.HandOfGuldan;
	end

	-- demonbolt,if=buff.demonic_core.up&soul_shard<4;
	if talents[DE.Demonbolt] and mana >= 1000 and currentSpell ~= DE.Demonbolt and (buff[DE.DemonicCore].up and soulShards < 4) then
		return DE.Demonbolt;
	end

	-- demonbolt,if=fight_remains<buff.demonic_core.stack*gcd.max;
	if talents[DE.Demonbolt] and mana >= 1000 and currentSpell ~= DE.Demonbolt and (timeToDie < buff[DE.DemonicCore].count * gcd) then
		return DE.Demonbolt;
	end

	-- power_siphon,if=buff.demonic_core.stack<2&(cooldown.summon_demonic_tyrant.remains>38|variable.tyrant_cd>38)&(buff.dreadstalkers.down|buff.dreadstalkers.remains>gcd.max*5);
	if talents[DE.PowerSiphon] and cooldown[DE.PowerSiphon].ready and (buff[DE.DemonicCore].count < 2 and ( cooldown[DE.SummonDemonicTyrant].remains > 38 or tyrantCd > 38 ) and ( not buff[DE.Dreadstalkers].up or buff[DE.Dreadstalkers].remains > gcd * 5 )) then
		return DE.PowerSiphon;
	end

	-- demonic_strength,if=(fight_remains>63&!(fight_remains>cooldown.summon_demonic_tyrant.remains+69)|cooldown.summon_demonic_tyrant.remains>30|buff.rite_of_ruvaraad.up|variable.shadow_timings|!talent.summon_demonic_tyrant|!talent.grimoire_felguard|!set_bonus.tier30_2pc);
	if talents[DE.DemonicStrength] and cooldown[DE.DemonicStrength].ready and (( timeToDie > 63 and not ( timeToDie > cooldown[DE.SummonDemonicTyrant].remains + 69 ) or cooldown[DE.SummonDemonicTyrant].remains > 30 or buff[DE.RiteOfRuvaraad].up or shadowTimings or not talents[DE.SummonDemonicTyrant] or not talents[DE.GrimoireFelguard] or not MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2) )) then
		return DE.DemonicStrength;
	end

	-- summon_vilefiend,if=fight_remains<cooldown.summon_demonic_tyrant.remains+5;
	if talents[DE.SummonVilefiend] and cooldown[DE.SummonVilefiend].ready and soulShards >= 1 and currentSpell ~= DE.SummonVilefiend and (timeToDie < cooldown[DE.SummonDemonicTyrant].remains + 5) then
		return DE.SummonVilefiend;
	end

	-- hand_of_guldan,if=soul_shard>2&cooldown.summon_demonic_tyrant.remains>15|soul_shard=5;
	if soulShards >= 3 and currentSpell ~= DE.HandOfGuldan and (soulShards > 2 and cooldown[DE.SummonDemonicTyrant].remains > 15 or soulShards == 5) then
		return DE.HandOfGuldan;
	end

	-- doom,target_if=refreshable;
	if talents[DE.Doom] and mana >= 500 then
		return DE.Doom;
	end

	-- soul_strike,if=soul_shard<5;
	if talents[DE.SoulStrike] and cooldown[DE.SoulStrike].ready and (soulShards < 5) then
		return DE.SoulStrike;
	end

	-- shadow_bolt;
	if mana >= 750 and currentSpell ~= DE.ShadowBolt then
		return DE.ShadowBolt;
	end
end
function Warlock:DemonologyFightEnd()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
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

	-- grimoire_felguard,if=fight_remains<20;
	if talents[DE.GrimoireFelguard] and cooldown[DE.GrimoireFelguard].ready and soulShards >= 1 and (timeToDie < 20) then
		return DE.GrimoireFelguard;
	end

	-- call_dreadstalkers,if=fight_remains<20;
	if timeToDie < 20 then
		return DE.CallDreadstalkers;
	end

	-- summon_vilefiend,if=fight_remains<20;
	if talents[DE.SummonVilefiend] and cooldown[DE.SummonVilefiend].ready and soulShards >= 1 and currentSpell ~= DE.SummonVilefiend and (timeToDie < 20) then
		return DE.SummonVilefiend;
	end

	-- nether_portal,if=fight_remains<30;
	if talents[DE.NetherPortal] and cooldown[DE.NetherPortal].ready and soulShards >= 1 and currentSpell ~= DE.NetherPortal and (timeToDie < 30) then
		return DE.NetherPortal;
	end

	-- summon_demonic_tyrant,if=fight_remains<20;
	if timeToDie < 20 then
		return DE.SummonDemonicTyrant;
	end

	-- demonic_strength,if=fight_remains<10;
	if talents[DE.DemonicStrength] and cooldown[DE.DemonicStrength].ready and (timeToDie < 10) then
		return DE.DemonicStrength;
	end

	-- power_siphon,if=buff.demonic_core.stack<3&fight_remains<20;
	if talents[DE.PowerSiphon] and cooldown[DE.PowerSiphon].ready and (buff[DE.DemonicCore].count < 3 and timeToDie < 20) then
		return DE.PowerSiphon;
	end

	-- implosion,if=fight_remains<2*gcd.max;
	if talents[DE.Implosion] and mana >= 1000 and (timeToDie < 2 * gcd) then
		return DE.Implosion;
	end
end

function Warlock:DemonologyItems()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
end

function Warlock:DemonologyRacials()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
end

function Warlock:DemonologyTyrant()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local currentSpell = fd.currentSpell;
	local spellHistory = fd.spellHistory;
	local talents = fd.talents;
	local timeShift = fd.timeShift;
	local gcd = fd.gcd;
	local timeToDie = fd.timeToDie;
	local spellHaste = fd.spellHaste;
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

	-- hand_of_guldan,if=variable.pet_expire>gcd.max+action.summon_demonic_tyrant.cast_time&variable.pet_expire<gcd.max*4;
	if soulShards >= 3 and currentSpell ~= DE.HandOfGuldan and (petExpire > gcd + timeShift and petExpire < gcd * 4) then
		return DE.HandOfGuldan;
	end

	-- summon_demonic_tyrant,if=variable.pet_expire>0&variable.pet_expire<action.summon_demonic_tyrant.execute_time+(buff.demonic_core.down*action.shadow_bolt.execute_time+buff.demonic_core.up*gcd.max)+gcd.max;
	if petExpire > 0 and petExpire < timeShift + ( not buff[DE.DemonicCore].up * timeShift + buff[DE.DemonicCore].up * gcd ) + gcd then
		return DE.SummonDemonicTyrant;
	end

	-- shadow_bolt,if=buff.fel_covenant.remains<15&(!buff.vilefiend.up|!talent.summon_vilefiend&(!buff.dreadstalkers.up))&time>30,line_cd=40;
	if mana >= 750 and currentSpell ~= DE.ShadowBolt and (buff[DE.FelCovenant].remains < 15 and ( not buff[DE.Vilefiend].up or not talents[DE.SummonVilefiend] and ( not buff[DE.Dreadstalkers].up ) ) and GetTime() > 30) then
		return DE.ShadowBolt;
	end

	-- shadow_bolt,if=prev_gcd.1.grimoire_felguard&time>30&buff.nether_portal.down&buff.demonic_core.down|time<10&buff.fel_covenant.stack<2&talent.fel_covenant&fight_remains%%90>40;
	if mana >= 750 and currentSpell ~= DE.ShadowBolt and (spellHistory[1] == DE.GrimoireFelguard and GetTime() > 30 and not buff[DE.NetherPortal].up and not buff[DE.DemonicCore].up or GetTime() < 10 and buff[DE.FelCovenant].count < 2 and talents[DE.FelCovenant] and timeToDie / 90 > 40) then
		return DE.ShadowBolt;
	end

	-- power_siphon,if=buff.demonic_core.stack<2&soul_shard=5&(!buff.vilefiend.up|!talent.summon_vilefiend&(!buff.dreadstalkers.up))&(buff.nether_portal.down);
	if talents[DE.PowerSiphon] and cooldown[DE.PowerSiphon].ready and (buff[DE.DemonicCore].count < 2 and soulShards == 5 and ( not buff[DE.Vilefiend].up or not talents[DE.SummonVilefiend] and ( not buff[DE.Dreadstalkers].up ) ) and ( not buff[DE.NetherPortal].up )) then
		return DE.PowerSiphon;
	end

	-- shadow_bolt,if=buff.vilefiend.down&buff.nether_portal.down&buff.dreadstalkers.down&soul_shard<5-buff.demonic_core.stack;
	if mana >= 750 and currentSpell ~= DE.ShadowBolt and (not buff[DE.Vilefiend].up and not buff[DE.NetherPortal].up and not buff[DE.Dreadstalkers].up and soulShards < 5 - buff[DE.DemonicCore].count) then
		return DE.ShadowBolt;
	end

	-- nether_portal,if=soul_shard=5;
	if talents[DE.NetherPortal] and cooldown[DE.NetherPortal].ready and soulShards >= 1 and currentSpell ~= DE.NetherPortal and (soulShards == 5) then
		return DE.NetherPortal;
	end

	-- soulburn,if=buff.nether_portal.up&cooldown.call_dreadstalkers.remains>10&soul_shard>1;
	if talents[DE.Soulburn] and cooldown[DE.Soulburn].ready and soulShards >= 1 and (buff[DE.NetherPortal].up and cooldown[DE.CallDreadstalkers].remains > 10 and soulShards > 1) then
		return DE.Soulburn;
	end

	-- summon_vilefiend,if=(soul_shard=5|buff.nether_portal.up)&cooldown.summon_demonic_tyrant.remains<13&variable.np;
	if talents[DE.SummonVilefiend] and cooldown[DE.SummonVilefiend].ready and soulShards >= 1 and currentSpell ~= DE.SummonVilefiend and (( soulShards == 5 or buff[DE.NetherPortal].up ) and cooldown[DE.SummonDemonicTyrant].remains < 13 and np) then
		return DE.SummonVilefiend;
	end

	-- call_dreadstalkers,if=(buff.vilefiend.up|!talent.summon_vilefiend&(!talent.nether_portal|buff.nether_portal.up|cooldown.nether_portal.remains>30)&(buff.nether_portal.up|buff.grimoire_felguard.up|soul_shard=5))&cooldown.summon_demonic_tyrant.remains<11&variable.np;
	if ( buff[DE.Vilefiend].up or not talents[DE.SummonVilefiend] and ( not talents[DE.NetherPortal] or buff[DE.NetherPortal].up or cooldown[DE.NetherPortal].remains > 30 ) and ( buff[DE.NetherPortal].up or buff[DE.GrimoireFelguard].up or soulShards == 5 ) ) and cooldown[DE.SummonDemonicTyrant].remains < 11 and np then
		return DE.CallDreadstalkers;
	end

	-- grimoire_felguard,if=buff.vilefiend.up|!talent.summon_vilefiend&(!talent.nether_portal|buff.nether_portal.up|cooldown.nether_portal.remains>30)&(buff.nether_portal.up|buff.dreadstalkers.up|soul_shard=5)&variable.np&(!raid_event.adds.in<15-raid_event.add.duration);
	if talents[DE.GrimoireFelguard] and cooldown[DE.GrimoireFelguard].ready and soulShards >= 1 and (buff[DE.Vilefiend].up or not talents[DE.SummonVilefiend] and ( not talents[DE.NetherPortal] or buff[DE.NetherPortal].up or cooldown[DE.NetherPortal].remains > 30 ) and ( buff[DE.NetherPortal].up or buff[DE.Dreadstalkers].up or soulShards == 5 ) and np ) then
		return DE.GrimoireFelguard;
	end

	-- hand_of_guldan,if=soul_shard>2&(buff.vilefiend.up|!talent.summon_vilefiend&buff.dreadstalkers.up)&(soul_shard>2|buff.vilefiend.remains<gcd.max*2+2%spell_haste)|buff.nether_portal.up;
	if soulShards >= 3 and currentSpell ~= DE.HandOfGuldan and (soulShards > 2 and ( buff[DE.Vilefiend].up or not talents[DE.SummonVilefiend] and buff[DE.Dreadstalkers].up ) and ( soulShards > 2 or buff[DE.Vilefiend].remains < gcd * 2 + 2 / spellHaste ) or buff[DE.NetherPortal].up) then
		return DE.HandOfGuldan;
	end

	-- power_siphon,if=buff.demonic_core.down;
	if talents[DE.PowerSiphon] and cooldown[DE.PowerSiphon].ready and (not buff[DE.DemonicCore].up) then
		return DE.PowerSiphon;
	end

	-- demonbolt,if=soul_shard<4&buff.demonic_core.up&(buff.vilefiend.up|!talent.summon_vilefiend&buff.dreadstalkers.up);
	if talents[DE.Demonbolt] and mana >= 1000 and currentSpell ~= DE.Demonbolt and (soulShards < 4 and buff[DE.DemonicCore].up and ( buff[DE.Vilefiend].up or not talents[DE.SummonVilefiend] and buff[DE.Dreadstalkers].up )) then
		return DE.Demonbolt;
	end

	-- power_siphon,if=buff.demonic_core.stack<3&variable.pet_expire>action.summon_demonic_tyrant.execute_time+gcd.max*3|variable.pet_expire=0;
	if talents[DE.PowerSiphon] and cooldown[DE.PowerSiphon].ready and (buff[DE.DemonicCore].count < 3 and petExpire > timeShift + gcd * 3 or petExpire == 0) then
		return DE.PowerSiphon;
	end

	-- soul_strike;
	if talents[DE.SoulStrike] and cooldown[DE.SoulStrike].ready then
		return DE.SoulStrike;
	end

	-- shadow_bolt;
	if mana >= 750 and currentSpell ~= DE.ShadowBolt then
		return DE.ShadowBolt;
	end
end

function Warlock:DemonologyVariables()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local gcd = fd.gcd;
	local timeToDie = fd.timeToDie;

	-- variable,name=tyrant_cd,op=setif,value=cooldown.invoke_power_infusion_0.remains,value_else=cooldown.summon_demonic_tyrant.remains,condition=((((fight_remains+time)%%120<=85&(fight_remains+time)%%120>=25)|time>=210)&variable.shadow_timings)&cooldown.invoke_power_infusion_0.duration>0&!talent.grand_warlocks_design;
	if ( ( ( ( timeToDie + GetTime() ) / 120 <= 85 and ( timeToDie + GetTime() ) / 120 >= 25 ) or GetTime() >= 210 ) and shadowTimings ) and cooldown[DE.InvokePowerInfusion0].duration > 0 and not talents[DE.GrandWarlocksDesign] then
		local tyrantCd = cooldown[DE.InvokePowerInfusion0].remains;
	else
		local tyrantCd = cooldown[DE.SummonDemonicTyrant].remains;
	end

	-- variable,name=pet_expire,op=set,value=(buff.dreadstalkers.remains>?buff.vilefiend.remains)-gcd*0.5,if=buff.vilefiend.up&buff.dreadstalkers.up;
	if buff[DE.Vilefiend].up and buff[DE.Dreadstalkers].up then
		local petExpire = ( buff[DE.Dreadstalkers].remains >= buff[DE.Vilefiend].remains ) - gcd * 0.5;
	end

	-- variable,name=pet_expire,op=set,value=(buff.dreadstalkers.remains>?buff.grimoire_felguard.remains)-gcd*0.5,if=!talent.summon_vilefiend&talent.grimoire_felguard&buff.dreadstalkers.up;
	if not talents[DE.SummonVilefiend] and talents[DE.GrimoireFelguard] and buff[DE.Dreadstalkers].up then
		local petExpire = ( buff[DE.Dreadstalkers].remains >= buff[DE.GrimoireFelguard].remains ) - gcd * 0.5;
	end

	-- variable,name=pet_expire,op=set,value=(buff.dreadstalkers.remains)-gcd*0.5,if=!talent.summon_vilefiend&(!talent.grimoire_felguard|!set_bonus.tier30_2pc)&buff.dreadstalkers.up;
	if not talents[DE.SummonVilefiend] and ( not talents[DE.GrimoireFelguard] or not MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2) ) and buff[DE.Dreadstalkers].up then
		local petExpire = ( buff[DE.Dreadstalkers].remains ) - gcd * 0.5;
	end

	-- variable,name=pet_expire,op=set,value=0,if=!buff.vilefiend.up&talent.summon_vilefiend|!buff.dreadstalkers.up;
	if not buff[DE.Vilefiend].up and talents[DE.SummonVilefiend] or not buff[DE.Dreadstalkers].up then
		local petExpire = 0;
	end

	-- variable,name=np,op=set,value=(!talent.nether_portal|cooldown.nether_portal.remains>30|buff.nether_portal.up);
	local np = ( not talents[DE.NetherPortal] or cooldown[DE.NetherPortal].remains > 30 or buff[DE.NetherPortal].up );
end


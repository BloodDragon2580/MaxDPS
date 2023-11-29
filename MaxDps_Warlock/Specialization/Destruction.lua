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

local DS = {
	CrashingChaos = 417234,
	GrimoireOfSacrifice = 108503,
	SoulFire = 6353,
	Cataclysm = 152108,
	Incinerate = 29722,
	SummonInfernal = 1122,
	Inferno = 270545,
	MadnessOfTheAzjaqir = 387400,
	ChaosIncarnate = 387275,
	Conflagrate = 17962,
	RoaringBlaze = 205184,
	DimensionalRift = 387976,
	ChannelDemonfire = 196447,
	RagingDemonfire = 387166,
	Immolate = 348,
	Backdraft = 196406,
	InfernalCombustion = 266134,
	ChaosBolt = 116858,
	Tier304pc = 405576,
	MadnessCb = 387409,
	Ruin = 387103,
	DiabolicEmbers = 387173,
	AvatarOfDestruction = 387159,
	BurnToAshes = 387153,
	RainOfChaos = 266086,
	Eradication = 196412,
	SoulConduit = 215941,
	CryHavoc = 387522,
	RainOfFire = 5740,
	MadnessRof = 387413,
	Havoc = 80240,
	SummonSoulkeeper = 386256,
	TormentedSoul = 386309,
	GrandWarlocksDesign = 387084,
	Pyrogenics = 387095,
	FireAndBrimstone = 196408,
	Mayhem = 387506,
};
local A = {
};
function Warlock:Destruction()
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
	local soulShards = UnitPower('player', Enum.PowerType.SoulShards);
	local soulShardsMax = UnitPowerMax('player', Enum.PowerType.SoulShards);
	local soulShardsPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local soulShardsRegen = select(2,GetPowerRegen());
	local soulShardsRegenCombined = soulShardsRegen + soulShards;
	local soulShardsDeficit = UnitPowerMax('player', Enum.PowerType.SoulShards) - soulShards;
	local soulShardsTimeToMax = soulShardsMax - soulShards / soulShardsRegen;

	-- variable,name=havoc_immo_time,op=reset;
	local havocImmoTime

	-- cycling_variable,name=havoc_immo_time,op=add,value=dot.immolate.remains*debuff.havoc.up;
	--return havoc_immo_time;

	-- variable,name=infernal_active,op=set,value=pet.infernal.active|cooldown.summon_infernal.remains>160;
	local infernalActive = petInfernal or cooldown[DS.SummonInfernal].remains > 160;

	-- call_action_list,name=aoe,if=(active_enemies>=3-(talent.inferno&!talent.madness_of_the_azjaqir))&!(!talent.inferno&talent.madness_of_the_azjaqir&talent.chaos_incarnate&active_enemies<4)&!variable.cleave_apl;
	if ( targets >= 3 - ( talents[DS.Inferno] and not talents[DS.MadnessOfTheAzjaqir] ) ) and not ( not talents[DS.Inferno] and talents[DS.MadnessOfTheAzjaqir] and talents[DS.ChaosIncarnate] and targets < 4 ) and not cleaveApl then
		local result = Warlock:DestructionAoe();
		if result then
			return result;
		end
	end

	-- call_action_list,name=cleave,if=active_enemies!=1|variable.cleave_apl;
	if not targets == 1 or cleaveApl then
		local result = Warlock:DestructionCleave();
		if result then
			return result;
		end
	end

	-- call_action_list,name=ogcd;
	local result = Warlock:DestructionOgcd();
	if result then
		return result;
	end

	-- call_action_list,name=items;
	local result = Warlock:DestructionItems();
	if result then
		return result;
	end

	-- conflagrate,if=(talent.roaring_blaze&debuff.conflagrate.remains<1.5)|charges=max_charges;
	if talents[DS.Conflagrate] and cooldown[DS.Conflagrate].ready and mana >= 500 and (( talents[DS.RoaringBlaze] and debuff[DS.Conflagrate].remains < 1.5 ) or cooldown[DS.Conflagrate].charges == cooldown[DS.Conflagrate].maxCharges) then
		return DS.Conflagrate;
	end

	-- dimensional_rift,if=soul_shard<4.7&(charges>2|fight_remains<cooldown.dimensional_rift.duration);
	if talents[DS.DimensionalRift] and cooldown[DS.DimensionalRift].ready and (soulShards < 4.7 and ( cooldown[DS.DimensionalRift].charges > 2 or timeToDie < cooldown[DS.DimensionalRift].duration )) then
		return DS.DimensionalRift;
	end

	-- cataclysm,if=raid_event.adds.in>15;
	if talents[DS.Cataclysm] and cooldown[DS.Cataclysm].ready and mana >= 500 and currentSpell ~= DS.Cataclysm then
		return DS.Cataclysm;
	end

	-- channel_demonfire,if=talent.raging_demonfire&(dot.immolate.remains-5*(action.chaos_bolt.in_flight&talent.internal_combustion))>cast_time&(debuff.conflagrate.remains>execute_time|!talent.roaring_blaze);
	if talents[DS.ChannelDemonfire] and cooldown[DS.ChannelDemonfire].ready and mana >= 750 and (talents[DS.RagingDemonfire] and ( debuff[DS.Immolate].remains - 5 * ( inFlight and talents[DS.InternalCombustion] ) ) > timeShift and ( debuff[DS.Conflagrate].remains > timeShift or not talents[DS.RoaringBlaze] )) then
		return DS.ChannelDemonfire;
	end

	-- soul_fire,if=soul_shard<=3.5&(debuff.conflagrate.remains>cast_time+travel_time|!talent.roaring_blaze&buff.backdraft.up);
	if talents[DS.SoulFire] and cooldown[DS.SoulFire].ready and mana >= 1000 and currentSpell ~= DS.SoulFire and (soulShards <= 3.5 and ( debuff[DS.Conflagrate].remains > timeShift or not talents[DS.RoaringBlaze] and buff[DS.Backdraft].up )) then
		return DS.SoulFire;
	end

	-- immolate,if=(((dot.immolate.remains-5*(action.chaos_bolt.in_flight&talent.internal_combustion))<dot.immolate.duration*0.3)|dot.immolate.remains<3|(dot.immolate.remains-action.chaos_bolt.execute_time)<5&talent.infernal_combustion&action.chaos_bolt.usable)&(!talent.cataclysm|cooldown.cataclysm.remains>dot.immolate.remains)&(!talent.soul_fire|cooldown.soul_fire.remains+action.soul_fire.cast_time>(dot.immolate.remains-5*talent.internal_combustion))&target.time_to_die>8;
	if mana >= 750 and currentSpell ~= DS.Immolate and (( ( ( debuff[DS.Immolate].remains - 5 * ( inFlight and talents[DS.InternalCombustion] ) ) < debuff[DS.Immolate].duration * 0.3 ) or debuff[DS.Immolate].remains < 3 or ( debuff[DS.Immolate].remains - timeShift ) < 5 and talents[DS.InfernalCombustion] and MaxDps:FindSpell(DS.ChaosBolt) ) and ( not talents[DS.Cataclysm] or cooldown[DS.Cataclysm].remains > debuff[DS.Immolate].remains ) and ( not talents[DS.SoulFire] or cooldown[DS.SoulFire].remains + timeShift > ( debuff[DS.Immolate].remains - 5 * (talents[DS.InternalCombustion] and 1 or 0) ) ) and timeToDie > 8) then
		return DS.Immolate;
	end

	-- channel_demonfire,if=dot.immolate.remains>cast_time&set_bonus.tier30_4pc;
	if talents[DS.ChannelDemonfire] and cooldown[DS.ChannelDemonfire].ready and mana >= 750 and (debuff[DS.Immolate].remains > timeShift and MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 4)) then
		return DS.ChannelDemonfire;
	end

	-- chaos_bolt,if=cooldown.summon_infernal.remains=0&soul_shard>4&(trinket.spoils_of_neltharus.ready_cooldown|!equipped.spoils_of_neltharus)&buff.domineering_arrogance.stack<3&talent.crashing_chaos;
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (cooldown[DS.SummonInfernal].remains == 0 and soulShards > 4 and ( not IsEquippedItem(SpoilsOfNeltharus) ) and buff[DS.DomineeringArrogance].count < 3 and talents[DS.CrashingChaos]) then
		return DS.ChaosBolt;
	end

	-- summon_infernal,if=variable.opti_cc&((soul_shard>4&buff.domineering_arrogance.stack>=3|buff.domineering_arrogance.stack<3&buff.madness_cb.remains>2*gcd.max)&(trinket.spoils_of_neltharus.cooldown.remains<2|!equipped.spoils_of_neltharus))|!variable.opti_cc|fight_remains<30;
	if talents[DS.SummonInfernal] and cooldown[DS.SummonInfernal].ready and mana >= 1000 and (optiCc and ( ( soulShards > 4 and buff[DS.DomineeringArrogance].count >= 3 or buff[DS.DomineeringArrogance].count < 3 and buff[DS.MadnessCb].remains > 2 * gcd ) and ( 2 or not IsEquippedItem(SpoilsOfNeltharus) ) ) or not optiCc or timeToDie < 30) then
		return DS.SummonInfernal;
	end

	-- chaos_bolt,if=pet.infernal.active|pet.blasphemy.active|soul_shard>=4&(variable.opti_cc&(cooldown.summon_infernal.remains<?trinket.spoils_of_neltharus.cooldown.remains)>2|!variable.opti_cc);
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (petInfernal or soulShards >= 4 and ( optiCc and ( cooldown[DS.SummonInfernal].remains ) > 2 or not optiCc )) then
		return DS.ChaosBolt;
	end

	-- channel_demonfire,if=talent.ruin.rank>1&!(talent.diabolic_embers&talent.avatar_of_destruction&(talent.burn_to_ashes|talent.chaos_incarnate))&dot.immolate.remains>cast_time;
	if talents[DS.ChannelDemonfire] and cooldown[DS.ChannelDemonfire].ready and mana >= 750 and (talents[DS.Ruin] > 1 and not ( talents[DS.DiabolicEmbers] and talents[DS.AvatarOfDestruction] and ( talents[DS.BurnToAshes] or talents[DS.ChaosIncarnate] ) ) and debuff[DS.Immolate].remains > timeShift) then
		return DS.ChannelDemonfire;
	end

	-- conflagrate,if=buff.backdraft.down&soul_shard>=1.5&!talent.roaring_blaze;
	if talents[DS.Conflagrate] and cooldown[DS.Conflagrate].ready and mana >= 500 and (not buff[DS.Backdraft].up and soulShards >= 1.5 and not talents[DS.RoaringBlaze]) then
		return DS.Conflagrate;
	end

	-- incinerate,if=cast_time+action.chaos_bolt.cast_time<buff.madness_cb.remains&(buff.call_to_dominance.down|!variable.opti_cc);
	if mana >= 750 and currentSpell ~= DS.Incinerate and (timeShift + timeShift < buff[DS.MadnessCb].remains and ( not buff[DS.CallToDominance].up or not optiCc )) then
		return DS.Incinerate;
	end

	-- chaos_bolt,if=buff.rain_of_chaos.remains>cast_time;
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (buff[DS.RainOfChaos].remains > timeShift) then
		return DS.ChaosBolt;
	end

	-- chaos_bolt,if=buff.backdraft.up&!talent.eradication&!talent.madness_of_the_azjaqir;
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (buff[DS.Backdraft].up and not talents[DS.Eradication] and not talents[DS.MadnessOfTheAzjaqir]) then
		return DS.ChaosBolt;
	end

	-- chaos_bolt,if=buff.madness_cb.up&((cooldown.summon_infernal.remains<?trinket.spoils_of_neltharus.cooldown.remains)>10|!variable.opti_cc);
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (buff[DS.MadnessCb].up and ( ( cooldown[DS.SummonInfernal].remains ) > 10 or not optiCc )) then
		return DS.ChaosBolt;
	end

	-- channel_demonfire,if=!(talent.diabolic_embers&talent.avatar_of_destruction&(talent.burn_to_ashes|talent.chaos_incarnate))&dot.immolate.remains>cast_time;
	if talents[DS.ChannelDemonfire] and cooldown[DS.ChannelDemonfire].ready and mana >= 750 and (not ( talents[DS.DiabolicEmbers] and talents[DS.AvatarOfDestruction] and ( talents[DS.BurnToAshes] or talents[DS.ChaosIncarnate] ) ) and debuff[DS.Immolate].remains > timeShift) then
		return DS.ChannelDemonfire;
	end

	-- dimensional_rift;
	if talents[DS.DimensionalRift] and cooldown[DS.DimensionalRift].ready then
		return DS.DimensionalRift;
	end

	-- chaos_bolt,if=soul_shard>3.5&(cooldown.summon_infernal.remains_expected>5|!variable.opti_cc);
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (soulShards > 3.5 and ( cooldown[DS.SummonInfernal].remains > 5 or not optiCc )) then
		return DS.ChaosBolt;
	end

	-- chaos_bolt,if=talent.soul_conduit&!talent.madness_of_the_azjaqir|!talent.backdraft;
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (talents[DS.SoulConduit] and not talents[DS.MadnessOfTheAzjaqir] or not talents[DS.Backdraft]) then
		return DS.ChaosBolt;
	end

	-- chaos_bolt,if=fight_remains<5&fight_remains>cast_time+travel_time;
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (timeToDie < 5 and timeToDie > timeShift) then
		return DS.ChaosBolt;
	end

	-- conflagrate,if=charges>(max_charges-1)|fight_remains<gcd.max*charges;
	if talents[DS.Conflagrate] and cooldown[DS.Conflagrate].ready and mana >= 500 and (cooldown[DS.Conflagrate].charges > ( cooldown[DS.Conflagrate].maxCharges - 1 ) or timeToDie < gcd * cooldown[DS.Conflagrate].charges) then
		return DS.Conflagrate;
	end

	-- incinerate;
	if mana >= 750 and currentSpell ~= DS.Incinerate then
		return DS.Incinerate;
	end
end
function Warlock:DestructionAoe()
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
	local result = Warlock:DestructionOgcd();
	if result then
		return result;
	end

	-- call_action_list,name=items;
	local result = Warlock:DestructionItems();
	if result then
		return result;
	end

	-- call_action_list,name=havoc,if=havoc_active&havoc_remains>gcd.max&active_enemies<5+(talent.cry_havoc&!talent.inferno)&(!cooldown.summon_infernal.up|!talent.summon_infernal);
	if havocActive and havocRemains > gcd and targets < 5 + ( talents[DS.CryHavoc] and not talents[DS.Inferno] ) and ( not cooldown[DS.SummonInfernal].up or not talents[DS.SummonInfernal] ) then
		local result = Warlock:DestructionHavoc();
		if result then
			return result;
		end
	end

	-- rain_of_fire,if=pet.infernal.active|pet.blasphemy.active;
	if talents[DS.RainOfFire] and soulShards >= 3 and (petInfernal) then
		return DS.RainOfFire;
	end

	-- rain_of_fire,if=fight_remains<12;
	if talents[DS.RainOfFire] and soulShards >= 3 and (timeToDie < 12) then
		return DS.RainOfFire;
	end

	-- rain_of_fire,if=gcd.max>buff.madness_rof.remains&buff.madness_rof.up;
	if talents[DS.RainOfFire] and soulShards >= 3 and (gcd > buff[DS.MadnessRof].remains and buff[DS.MadnessRof].up) then
		return DS.RainOfFire;
	end

	-- rain_of_fire,if=soul_shard>=(4.5-0.1*active_dot.immolate)&time>5;
	if talents[DS.RainOfFire] and soulShards >= 3 and (soulShards >= ( 4.5 - 0.1 * activeDot[DS.Immolate] ) and GetTime() > 5) then
		return DS.RainOfFire;
	end

	-- chaos_bolt,if=soul_shard>3.5-(0.1*active_enemies)&!talent.rain_of_fire;
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (soulShards > 3.5 - ( 0.1 * targets ) and not talents[DS.RainOfFire]) then
		return DS.ChaosBolt;
	end

	-- cataclysm,if=raid_event.adds.in>15;
	if talents[DS.Cataclysm] and cooldown[DS.Cataclysm].ready and mana >= 500 and currentSpell ~= DS.Cataclysm then
		return DS.Cataclysm;
	end

	-- havoc,target_if=min:((-target.time_to_die)<?-15)+dot.immolate.remains+99*(self.target=target),if=(!cooldown.summon_infernal.up|!talent.summon_infernal|(talent.inferno&active_enemies>4))&target.time_to_die>8;
	if talents[DS.Havoc] and cooldown[DS.Havoc].ready and mana >= 1000 and (( not cooldown[DS.SummonInfernal].up or not talents[DS.SummonInfernal] or ( talents[DS.Inferno] and targets > 4 ) ) and timeToDie > 8) then
		return DS.Havoc;
	end

	-- immolate,target_if=min:dot.immolate.remains+99*debuff.havoc.remains,if=dot.immolate.refreshable&(!talent.cataclysm.enabled|cooldown.cataclysm.remains>dot.immolate.remains)&(!talent.raging_demonfire|cooldown.channel_demonfire.remains>remains|time<5)&active_dot.immolate<=4&target.time_to_die>18;
	if mana >= 750 and currentSpell ~= DS.Immolate and (debuff[DS.Immolate].refreshable and ( not talents[DS.Cataclysm] or cooldown[DS.Cataclysm].remains > debuff[DS.Immolate].remains ) and ( not talents[DS.RagingDemonfire] or cooldown[DS.ChannelDemonfire].remains > debuff[DS.Immolate].remains or GetTime() < 5 ) and activeDot[DS.Immolate] <= 4 and timeToDie > 18) then
		return DS.Immolate;
	end

	-- channel_demonfire,if=dot.immolate.remains>cast_time&talent.raging_demonfire;
	if talents[DS.ChannelDemonfire] and cooldown[DS.ChannelDemonfire].ready and mana >= 750 and (debuff[DS.Immolate].remains > timeShift and talents[DS.RagingDemonfire]) then
		return DS.ChannelDemonfire;
	end

	-- summon_soulkeeper,if=buff.tormented_soul.stack=10|buff.tormented_soul.stack>3&fight_remains<10;
	if talents[DS.SummonSoulkeeper] and currentSpell ~= DS.SummonSoulkeeper and (buff[DS.TormentedSoul].count == 10 or buff[DS.TormentedSoul].count > 3 and timeToDie < 10) then
		return DS.SummonSoulkeeper;
	end

	-- call_action_list,name=ogcd;
	local result = Warlock:DestructionOgcd();
	if result then
		return result;
	end

	-- summon_infernal,if=cooldown.invoke_power_infusion_0.up|cooldown.invoke_power_infusion_0.duration=0|fight_remains>=190&!talent.grand_warlocks_design;
	if talents[DS.SummonInfernal] and cooldown[DS.SummonInfernal].ready and mana >= 1000 and (cooldown[DS.InvokePowerInfusion0].up or cooldown[DS.InvokePowerInfusion0].duration == 0 or timeToDie >= 190 and not talents[DS.GrandWarlocksDesign]) then
		return DS.SummonInfernal;
	end

	-- rain_of_fire,if=debuff.pyrogenics.down&active_enemies<=4;
	if talents[DS.RainOfFire] and soulShards >= 3 and (not debuff[DS.Pyrogenics].up and targets <= 4) then
		return DS.RainOfFire;
	end

	-- channel_demonfire,if=dot.immolate.remains>cast_time;
	if talents[DS.ChannelDemonfire] and cooldown[DS.ChannelDemonfire].ready and mana >= 750 and (debuff[DS.Immolate].remains > timeShift) then
		return DS.ChannelDemonfire;
	end

	-- immolate,target_if=min:dot.immolate.remains+99*debuff.havoc.remains,if=((dot.immolate.refreshable&(!talent.cataclysm.enabled|cooldown.cataclysm.remains>dot.immolate.remains))|active_enemies>active_dot.immolate)&target.time_to_die>10&!havoc_active;
	if mana >= 750 and currentSpell ~= DS.Immolate and (( ( debuff[DS.Immolate].refreshable and ( not talents[DS.Cataclysm] or cooldown[DS.Cataclysm].remains > debuff[DS.Immolate].remains ) ) or targets > activeDot[DS.Immolate] ) and timeToDie > 10 and not havocActive) then
		return DS.Immolate;
	end

	-- immolate,target_if=min:dot.immolate.remains+99*debuff.havoc.remains,if=((dot.immolate.refreshable&variable.havoc_immo_time<5.4)|(dot.immolate.remains<2&dot.immolate.remains<havoc_remains)|!dot.immolate.ticking|(variable.havoc_immo_time<2)*havoc_active)&(!talent.cataclysm.enabled|cooldown.cataclysm.remains>dot.immolate.remains)&target.time_to_die>11;
	if mana >= 750 and currentSpell ~= DS.Immolate and (( ( debuff[DS.Immolate].refreshable and havocImmoTime < 5.4 ) or ( debuff[DS.Immolate].remains < 2 and debuff[DS.Immolate].remains < havocRemains ) or not debuff[DS.Immolate].up or ( havocImmoTime < 2 ) * havocActive ) and ( not talents[DS.Cataclysm] or cooldown[DS.Cataclysm].remains > debuff[DS.Immolate].remains ) and timeToDie > 11) then
		return DS.Immolate;
	end

	-- soul_fire,if=buff.backdraft.up;
	if talents[DS.SoulFire] and cooldown[DS.SoulFire].ready and mana >= 1000 and currentSpell ~= DS.SoulFire and (buff[DS.Backdraft].up) then
		return DS.SoulFire;
	end

	-- incinerate,if=talent.fire_and_brimstone.enabled&buff.backdraft.up;
	if mana >= 750 and currentSpell ~= DS.Incinerate and (talents[DS.FireAndBrimstone] and buff[DS.Backdraft].up) then
		return DS.Incinerate;
	end

	-- conflagrate,if=buff.backdraft.stack<2|!talent.backdraft;
	if talents[DS.Conflagrate] and cooldown[DS.Conflagrate].ready and mana >= 500 and (buff[DS.Backdraft].count < 2 or not talents[DS.Backdraft]) then
		return DS.Conflagrate;
	end

	-- dimensional_rift;
	if talents[DS.DimensionalRift] and cooldown[DS.DimensionalRift].ready then
		return DS.DimensionalRift;
	end

	-- incinerate;
	if mana >= 750 and currentSpell ~= DS.Incinerate then
		return DS.Incinerate;
	end
end

function Warlock:DestructionCleave()
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

	-- call_action_list,name=items;
	local result = Warlock:DestructionItems();
	if result then
		return result;
	end

	-- call_action_list,name=ogcd;
	local result = Warlock:DestructionOgcd();
	if result then
		return result;
	end

	-- call_action_list,name=havoc,if=havoc_active&havoc_remains>gcd.max;
	if havocActive and havocRemains > gcd then
		local result = Warlock:DestructionHavoc();
		if result then
			return result;
		end
	end

	-- variable,name=pool_soul_shards,value=cooldown.havoc.remains<=10|talent.mayhem;
	local poolSoulShards = cooldown[DS.Havoc].remains <= 10 or talents[DS.Mayhem];

	-- conflagrate,if=(talent.roaring_blaze.enabled&debuff.conflagrate.remains<1.5)|charges=max_charges;
	if talents[DS.Conflagrate] and cooldown[DS.Conflagrate].ready and mana >= 500 and (( talents[DS.RoaringBlaze] and debuff[DS.Conflagrate].remains < 1.5 ) or cooldown[DS.Conflagrate].charges == cooldown[DS.Conflagrate].maxCharges) then
		return DS.Conflagrate;
	end

	-- dimensional_rift,if=soul_shard<4.7&(charges>2|fight_remains<cooldown.dimensional_rift.duration);
	if talents[DS.DimensionalRift] and cooldown[DS.DimensionalRift].ready and (soulShards < 4.7 and ( cooldown[DS.DimensionalRift].charges > 2 or timeToDie < cooldown[DS.DimensionalRift].duration )) then
		return DS.DimensionalRift;
	end

	-- cataclysm,if=raid_event.adds.in>15;
	if talents[DS.Cataclysm] and cooldown[DS.Cataclysm].ready and mana >= 500 and currentSpell ~= DS.Cataclysm then
		return DS.Cataclysm;
	end

	-- channel_demonfire,if=talent.raging_demonfire&active_dot.immolate=2;
	if talents[DS.ChannelDemonfire] and cooldown[DS.ChannelDemonfire].ready and mana >= 750 and (talents[DS.RagingDemonfire] and activeDot[DS.Immolate] == 2) then
		return DS.ChannelDemonfire;
	end

	-- soul_fire,if=soul_shard<=3.5&(debuff.conflagrate.remains>cast_time+travel_time|!talent.roaring_blaze&buff.backdraft.up)&!variable.pool_soul_shards;
	if talents[DS.SoulFire] and cooldown[DS.SoulFire].ready and mana >= 1000 and currentSpell ~= DS.SoulFire and (soulShards <= 3.5 and ( debuff[DS.Conflagrate].remains > timeShift or not talents[DS.RoaringBlaze] and buff[DS.Backdraft].up ) and not poolSoulShards) then
		return DS.SoulFire;
	end

	-- immolate,target_if=min:dot.immolate.remains+99*debuff.havoc.remains,if=(dot.immolate.refreshable&(dot.immolate.remains<cooldown.havoc.remains|!dot.immolate.ticking))&(!talent.cataclysm|cooldown.cataclysm.remains>remains)&(!talent.soul_fire|cooldown.soul_fire.remains+(!talent.mayhem*action.soul_fire.cast_time)>dot.immolate.remains)&target.time_to_die>15;
	if mana >= 750 and currentSpell ~= DS.Immolate and (( debuff[DS.Immolate].refreshable and ( debuff[DS.Immolate].remains < cooldown[DS.Havoc].remains or not debuff[DS.Immolate].up ) ) and ( not talents[DS.Cataclysm] or cooldown[DS.Cataclysm].remains > debuff[DS.Immolate].remains ) and ( not talents[DS.SoulFire] or cooldown[DS.SoulFire].remains + ( not (talents[DS.Mayhem] and 1 or 0) * timeShift ) > debuff[DS.Immolate].remains ) and timeToDie > 15) then
		return DS.Immolate;
	end

	-- havoc,target_if=min:((-target.time_to_die)<?-15)+dot.immolate.remains+99*(self.target=target),if=(!cooldown.summon_infernal.up|!talent.summon_infernal)&target.time_to_die>8;
	if talents[DS.Havoc] and cooldown[DS.Havoc].ready and mana >= 1000 and (( not cooldown[DS.SummonInfernal].up or not talents[DS.SummonInfernal] ) and timeToDie > 8) then
		return DS.Havoc;
	end

	-- chaos_bolt,if=pet.infernal.active|pet.blasphemy.active|soul_shard>=4;
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (petInfernal or soulShards >= 4) then
		return DS.ChaosBolt;
	end

	-- summon_infernal;
	if talents[DS.SummonInfernal] and cooldown[DS.SummonInfernal].ready and mana >= 1000 then
		return DS.SummonInfernal;
	end

	-- channel_demonfire,if=talent.ruin.rank>1&!(talent.diabolic_embers&talent.avatar_of_destruction&(talent.burn_to_ashes|talent.chaos_incarnate));
	if talents[DS.ChannelDemonfire] and cooldown[DS.ChannelDemonfire].ready and mana >= 750 and (talents[DS.Ruin] > 1 and not ( talents[DS.DiabolicEmbers] and talents[DS.AvatarOfDestruction] and ( talents[DS.BurnToAshes] or talents[DS.ChaosIncarnate] ) )) then
		return DS.ChannelDemonfire;
	end

	-- conflagrate,if=buff.backdraft.down&soul_shard>=1.5&!variable.pool_soul_shards;
	if talents[DS.Conflagrate] and cooldown[DS.Conflagrate].ready and mana >= 500 and (not buff[DS.Backdraft].up and soulShards >= 1.5 and not poolSoulShards) then
		return DS.Conflagrate;
	end

	-- incinerate,if=cast_time+action.chaos_bolt.cast_time<buff.madness_cb.remains;
	if mana >= 750 and currentSpell ~= DS.Incinerate and (timeShift + timeShift < buff[DS.MadnessCb].remains) then
		return DS.Incinerate;
	end

	-- chaos_bolt,if=buff.rain_of_chaos.remains>cast_time;
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (buff[DS.RainOfChaos].remains > timeShift) then
		return DS.ChaosBolt;
	end

	-- chaos_bolt,if=buff.backdraft.up&!variable.pool_soul_shards;
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (buff[DS.Backdraft].up and not poolSoulShards) then
		return DS.ChaosBolt;
	end

	-- chaos_bolt,if=talent.eradication&!variable.pool_soul_shards&debuff.eradication.remains<cast_time&!action.chaos_bolt.in_flight;
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (talents[DS.Eradication] and not poolSoulShards and debuff[DS.Eradication].remains < timeShift and not inFlight) then
		return DS.ChaosBolt;
	end

	-- chaos_bolt,if=buff.madness_cb.up&(!variable.pool_soul_shards|(talent.burn_to_ashes&buff.burn_to_ashes.stack=0)|talent.soul_fire);
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (buff[DS.MadnessCb].up and ( not poolSoulShards or ( talents[DS.BurnToAshes] and buff[DS.BurnToAshes].count == 0 ) or talents[DS.SoulFire] )) then
		return DS.ChaosBolt;
	end

	-- soul_fire,if=soul_shard<=4&talent.mayhem;
	if talents[DS.SoulFire] and cooldown[DS.SoulFire].ready and mana >= 1000 and currentSpell ~= DS.SoulFire and (soulShards <= 4 and talents[DS.Mayhem]) then
		return DS.SoulFire;
	end

	-- channel_demonfire,if=!(talent.diabolic_embers&talent.avatar_of_destruction&(talent.burn_to_ashes|talent.chaos_incarnate));
	if talents[DS.ChannelDemonfire] and cooldown[DS.ChannelDemonfire].ready and mana >= 750 and (not ( talents[DS.DiabolicEmbers] and talents[DS.AvatarOfDestruction] and ( talents[DS.BurnToAshes] or talents[DS.ChaosIncarnate] ) )) then
		return DS.ChannelDemonfire;
	end

	-- dimensional_rift;
	if talents[DS.DimensionalRift] and cooldown[DS.DimensionalRift].ready then
		return DS.DimensionalRift;
	end

	-- chaos_bolt,if=soul_shard>3.5&!variable.pool_soul_shards;
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (soulShards > 3.5 and not poolSoulShards) then
		return DS.ChaosBolt;
	end

	-- chaos_bolt,if=!variable.pool_soul_shards&(talent.soul_conduit&!talent.madness_of_the_azjaqir|!talent.backdraft);
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (not poolSoulShards and ( talents[DS.SoulConduit] and not talents[DS.MadnessOfTheAzjaqir] or not talents[DS.Backdraft] )) then
		return DS.ChaosBolt;
	end

	-- chaos_bolt,if=fight_remains<5&fight_remains>cast_time+travel_time;
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (timeToDie < 5 and timeToDie > timeShift) then
		return DS.ChaosBolt;
	end

	-- summon_soulkeeper,if=buff.tormented_soul.stack=10|buff.tormented_soul.stack>3&fight_remains<10;
	if talents[DS.SummonSoulkeeper] and currentSpell ~= DS.SummonSoulkeeper and (buff[DS.TormentedSoul].count == 10 or buff[DS.TormentedSoul].count > 3 and timeToDie < 10) then
		return DS.SummonSoulkeeper;
	end

	-- conflagrate,if=charges>(max_charges-1)|fight_remains<gcd.max*charges;
	if talents[DS.Conflagrate] and cooldown[DS.Conflagrate].ready and mana >= 500 and (cooldown[DS.Conflagrate].charges > ( cooldown[DS.Conflagrate].maxCharges - 1 ) or timeToDie < gcd * cooldown[DS.Conflagrate].charges) then
		return DS.Conflagrate;
	end

	-- incinerate;
	if mana >= 750 and currentSpell ~= DS.Incinerate then
		return DS.Incinerate;
	end
end

function Warlock:DestructionHavoc()
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

	-- conflagrate,if=talent.backdraft&buff.backdraft.down&soul_shard>=1&soul_shard<=4;
	if talents[DS.Conflagrate] and cooldown[DS.Conflagrate].ready and mana >= 500 and (talents[DS.Backdraft] and not buff[DS.Backdraft].up and soulShards >= 1 and soulShards <= 4) then
		return DS.Conflagrate;
	end

	-- soul_fire,if=cast_time<havoc_remains&soul_shard<2.5;
	if talents[DS.SoulFire] and cooldown[DS.SoulFire].ready and mana >= 1000 and currentSpell ~= DS.SoulFire and (timeShift < havocRemains and soulShards < 2.5) then
		return DS.SoulFire;
	end

	-- channel_demonfire,if=soul_shard<4.5&talent.raging_demonfire.rank=2;
	if talents[DS.ChannelDemonfire] and cooldown[DS.ChannelDemonfire].ready and mana >= 750 and (soulShards < 4.5 and talents[DS.RagingDemonfire] == 2) then
		return DS.ChannelDemonfire;
	end

	-- immolate,target_if=min:dot.immolate.remains+100*debuff.havoc.remains,if=(((dot.immolate.refreshable&variable.havoc_immo_time<5.4)&target.time_to_die>5)|((dot.immolate.remains<2&dot.immolate.remains<havoc_remains)|!dot.immolate.ticking|variable.havoc_immo_time<2)&target.time_to_die>11)&soul_shard<4.5;
	if mana >= 750 and currentSpell ~= DS.Immolate and (( ( ( debuff[DS.Immolate].refreshable and havocImmoTime < 5.4 ) and timeToDie > 5 ) or ( ( debuff[DS.Immolate].remains < 2 and debuff[DS.Immolate].remains < havocRemains ) or not debuff[DS.Immolate].up or havocImmoTime < 2 ) and timeToDie > 11 ) and soulShards < 4.5) then
		return DS.Immolate;
	end

	-- chaos_bolt,if=((talent.cry_havoc&!talent.inferno)|!talent.rain_of_fire)&cast_time<havoc_remains;
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (( ( talents[DS.CryHavoc] and not talents[DS.Inferno] ) or not talents[DS.RainOfFire] ) and timeShift < havocRemains) then
		return DS.ChaosBolt;
	end

	-- chaos_bolt,if=cast_time<havoc_remains&(active_enemies<=3-talent.inferno+(talent.madness_of_the_azjaqir&!talent.inferno));
	if talents[DS.ChaosBolt] and soulShards >= 2 and currentSpell ~= DS.ChaosBolt and (timeShift < havocRemains and ( targets <= 3 - (talents[DS.Inferno] and 1 or 0) + ( talents[DS.MadnessOfTheAzjaqir] and not talents[DS.Inferno] ) )) then
		return DS.ChaosBolt;
	end

	-- rain_of_fire,if=active_enemies>=3&talent.inferno;
	if talents[DS.RainOfFire] and soulShards >= 3 and (targets >= 3 and talents[DS.Inferno]) then
		return DS.RainOfFire;
	end

	-- rain_of_fire,if=(active_enemies>=4-talent.inferno+talent.madness_of_the_azjaqir);
	if talents[DS.RainOfFire] and soulShards >= 3 and (( targets >= 4 - (talents[DS.Inferno] and 1 or 0) + (talents[DS.MadnessOfTheAzjaqir] and 1 or 0) )) then
		return DS.RainOfFire;
	end

	-- rain_of_fire,if=active_enemies>2&(talent.avatar_of_destruction|(talent.rain_of_chaos&buff.rain_of_chaos.up))&talent.inferno.enabled;
	if talents[DS.RainOfFire] and soulShards >= 3 and (targets > 2 and ( talents[DS.AvatarOfDestruction] or ( talents[DS.RainOfChaos] and buff[DS.RainOfChaos].up ) ) and talents[DS.Inferno]) then
		return DS.RainOfFire;
	end

	-- channel_demonfire,if=soul_shard<4.5;
	if talents[DS.ChannelDemonfire] and cooldown[DS.ChannelDemonfire].ready and mana >= 750 and (soulShards < 4.5) then
		return DS.ChannelDemonfire;
	end

	-- conflagrate,if=!talent.backdraft;
	if talents[DS.Conflagrate] and cooldown[DS.Conflagrate].ready and mana >= 500 and (not talents[DS.Backdraft]) then
		return DS.Conflagrate;
	end

	-- incinerate,if=cast_time<havoc_remains;
	if mana >= 750 and currentSpell ~= DS.Incinerate and (timeShift < havocRemains) then
		return DS.Incinerate;
	end
end

function Warlock:DestructionItems()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
end

function Warlock:DestructionOgcd()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
end


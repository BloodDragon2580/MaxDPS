local _, addonTable = ...;

-- @type MaxDps;
if not MaxDps then return end;
local Rogue = addonTable.Rogue;
local MaxDps = MaxDps;

local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;

local itemID = GetInventoryItemID('player', INVSLOT_MAINHAND);

local mainHandSubClassID = itemID and  select(13, GetItemInfo(itemID));

local TwoHanderWepCheck = mainHandSubClassID and (mainHandSubClassID == 1 or mainHandSubClassID == 5 or mainHandSubClassID == 8 or mainHandSubClassID == 10);

local AS = {
	MarkedForDeath = 137619,
	ResoundingClarity = 381622,
	Stealth = 1784,
	SliceAndDice = 315496,
	Kick = 1766,
	Deathmark = 360194,
	Exsanguinate = 200806,
	Sepsis = 385408,
	CutToTheChase = 51667,
	Envenom = 32645,
	MasterAssassin = 255989,
	Garrote = 703,
	Rupture = 1943,
	ImprovedGarrote = 381632,
	Kingsbane = 385627,
	Shiv = 5938,
	EchoingReprimand = 385616,
	CrimsonTempest = 121411,
	ArterialPrecision = 400783,
	LightweightShiv = 394983,
	ThistleTea = 381623,
	IndiscriminateCarnage = 381802,
	Vanish = 1856,
	ColdBlood = 382245,
	DeeperStratagem = 193531,
	AmplifyingPoison = 381664,
	SerratedBoneSpike = 385424,
	SerratedBoneSpikeDot = 394036,
	FanOfKnives = 51723,
	DragontemperedBlades = 381801,
	DeadlyPoisonDot = 394324,
	Ambush = 8676,
	Blindside = 328085,
	Mutilate = 1329,
	DashingScoundrel = 381797,
	Doomblade = 381673,
	ShadowDance = 185313,
};
local A = {
};
function Rogue:Assassination()
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
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;
	local comboPoints = UnitPower('player', Enum.PowerType.ComboPoints);
	local comboPointsMax = UnitPowerMax('player', Enum.PowerType.ComboPoints);
	local comboPointsPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local comboPointsRegen = select(2,GetPowerRegen());
	local comboPointsRegenCombined = comboPointsRegen + comboPoints;
	local comboPointsDeficit = UnitPowerMax('player', Enum.PowerType.ComboPoints) - comboPoints;
	local comboPointsTimeToMax = comboPointsMax - comboPoints / comboPointsRegen;

	-- stealth;
	if cooldown[AS.Stealth].ready then
		return AS.Stealth;
	end

	-- variable,name=single_target,value=spell_targets.fan_of_knives<2;
	local singleTarget = targets < 2;

	-- variable,name=regen_saturated,value=energy.regen_combined>35;
	local regenSaturated = energyRegenCombined > 35;

	-- variable,name=exsang_sync_remains,op=setif,condition=cooldown.deathmark.remains>cooldown.exsanguinate.remains&cooldown.deathmark.remains<fight_remains,value=cooldown.deathmark.remains,value_else=cooldown.exsanguinate.remains;
	if cooldown[AS.Deathmark].remains > cooldown[AS.Exsanguinate].remains and cooldown[AS.Deathmark].remains < timeToDie then
		local exsangSyncRemains = cooldown[AS.Deathmark].remains;
	else
		local exsangSyncRemains = cooldown[AS.Exsanguinate].remains;
	end

	-- variable,name=sepsis_sync_remains,op=setif,condition=cooldown.deathmark.remains>cooldown.sepsis.remains&cooldown.deathmark.remains<fight_remains,value=cooldown.deathmark.remains,value_else=cooldown.sepsis.remains;
	if cooldown[AS.Deathmark].remains > cooldown[AS.Sepsis].remains and cooldown[AS.Deathmark].remains < timeToDie then
		local sepsisSyncRemains = cooldown[AS.Deathmark].remains;
	else
		local sepsisSyncRemains = cooldown[AS.Sepsis].remains;
	end

	-- call_action_list,name=stealthed,if=stealthed.rogue|stealthed.improved_garrote;
	if stealthedRogue or stealthedImprovedGarrote then
		local result = Rogue:AssassinationStealthed();
		if result then
			return result;
		end
	end

	-- call_action_list,name=cds;
	local result = Rogue:AssassinationCds();
	if result then
		return result;
	end

	-- slice_and_dice,if=!buff.slice_and_dice.up&combo_points>=2|!talent.cut_to_the_chase&refreshable&combo_points>=4;
	if energy >= 20 and comboPoints >= 5 and (not buff[AS.SliceAndDice].up and comboPoints >= 2 or not talents[AS.CutToTheChase] and debuff[AS.SliceAndDice].refreshable and comboPoints >= 4) then
		return AS.SliceAndDice;
	end

	-- envenom,if=talent.cut_to_the_chase&buff.slice_and_dice.up&buff.slice_and_dice.remains<5&combo_points>=4;
	if energy >= 32 and comboPoints >= 5 and (talents[AS.CutToTheChase] and buff[AS.SliceAndDice].up and buff[AS.SliceAndDice].remains < 5 and comboPoints >= 4) then
		return AS.Envenom;
	end

	-- call_action_list,name=dot;
	local result = Rogue:AssassinationDot();
	if result then
		return result;
	end

	-- call_action_list,name=direct;
	local result = Rogue:AssassinationDirect();
	if result then
		return result;
	end
end
function Rogue:AssassinationCds()
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
	local comboPoints = UnitPower('player', Enum.PowerType.ComboPoints);
	local comboPointsMax = UnitPowerMax('player', Enum.PowerType.ComboPoints);
	local comboPointsPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local comboPointsRegen = select(2,GetPowerRegen());
	local comboPointsRegenCombined = comboPointsRegen + comboPoints;
	local comboPointsDeficit = UnitPowerMax('player', Enum.PowerType.ComboPoints) - comboPoints;
	local comboPointsTimeToMax = comboPointsMax - comboPoints / comboPointsRegen;
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;

	-- marked_for_death,line_cd=1.5,target_if=min:target.time_to_die,if=raid_event.adds.up&(!variable.single_target|target.time_to_die<30)&(target.time_to_die<combo_points.deficit*1.5|combo_points.deficit>=cp_max_spend);
	if talents[AS.MarkedForDeath] and cooldown[AS.MarkedForDeath].ready and (raid_event.adds.up and ( not singleTarget or timeToDie < 30 ) and ( timeToDie < comboPointsDeficit * 1.5 or comboPointsDeficit >= cpMaxSpend )) then
		return AS.MarkedForDeath;
	end

	-- marked_for_death,if=raid_event.adds.in>30-raid_event.adds.duration&combo_points.deficit>=cp_max_spend;
	if talents[AS.MarkedForDeath] and cooldown[AS.MarkedForDeath].ready and (comboPointsDeficit >= cpMaxSpend) then
		return AS.MarkedForDeath;
	end

	-- variable,name=deathmark_exsanguinate_condition,value=!talent.exsanguinate|cooldown.exsanguinate.remains>15|exsanguinated.rupture|exsanguinated.garrote;
	local deathmarkExsanguinateCondition = not talents[AS.Exsanguinate] or cooldown[AS.Exsanguinate].remains > 15;

	-- variable,name=deathmark_ma_condition,value=!talent.master_assassin.enabled|dot.garrote.ticking;
	local deathmarkMaCondition = not talents[AS.MasterAssassin] or debuff[AS.Garrote].up;

	-- sepsis,if=!stealthed.rogue&!stealthed.improved_garrote&dot.rupture.ticking&(!talent.exsanguinate|variable.exsang_sync_remains>7|dot.rupture.remains>20)&(!talent.improved_garrote&dot.garrote.ticking|talent.improved_garrote&cooldown.garrote.up)&(target.time_to_die>10|fight_remains<10);
	if talents[AS.Sepsis] and cooldown[AS.Sepsis].ready and energy >= 25 and (not stealthedRogue and not stealthedImprovedGarrote and debuff[AS.Rupture].up and ( not talents[AS.Exsanguinate] or exsangSyncRemains > 7 or debuff[AS.Rupture].remains > 20 ) and ( not talents[AS.ImprovedGarrote] and debuff[AS.Garrote].up or talents[AS.ImprovedGarrote] and cooldown[AS.Garrote].up ) and ( timeToDie > 10 or timeToDie < 10 )) then
		return AS.Sepsis;
	end

	-- variable,name=deathmark_condition,value=!stealthed.rogue&dot.rupture.ticking&!debuff.deathmark.up&variable.deathmark_exsanguinate_condition&variable.deathmark_ma_condition;
	local deathmarkCondition = not stealthedRogue and debuff[AS.Rupture].up and not debuff[AS.Deathmark].up and deathmarkExsanguinateCondition and deathmarkMaCondition;

	-- deathmark,if=variable.deathmark_condition;
	if talents[AS.Deathmark] and cooldown[AS.Deathmark].ready and (deathmarkCondition) then
		return AS.Deathmark;
	end

	-- kingsbane,if=(debuff.shiv.up|cooldown.shiv.remains<6)&buff.envenom.up&(cooldown.deathmark.remains>=50|dot.deathmark.ticking);
	if talents[AS.Kingsbane] and cooldown[AS.Kingsbane].ready and energy >= 35 and (( debuff[AS.Shiv].up or cooldown[AS.Shiv].remains < 6 ) and buff[AS.Envenom].up and ( cooldown[AS.Deathmark].remains >= 50 or debuff[AS.Deathmark].up )) then
		return AS.Kingsbane;
	end

	-- variable,name=exsanguinate_condition,value=talent.exsanguinate&!stealthed.rogue&(!stealthed.improved_garrote|dot.garrote.pmultiplier>1)&!dot.deathmark.ticking&target.time_to_die>variable.exsang_sync_remains+4&variable.exsang_sync_remains<4;
	local exsanguinateCondition = talents[AS.Exsanguinate] and not stealthedRogue and ( not stealthedImprovedGarrote ) and not debuff[AS.Deathmark].up and timeToDie > exsangSyncRemains + 4 and exsangSyncRemains < 4;

	-- echoing_reprimand,if=talent.exsanguinate&talent.resounding_clarity&(variable.exsanguinate_condition&combo_points<=2&variable.exsang_sync_remains<=2&!dot.garrote.refreshable&dot.rupture.remains>9.6);
	if talents[AS.EchoingReprimand] and cooldown[AS.EchoingReprimand].ready and energy >= 10 and (talents[AS.Exsanguinate] and talents[AS.ResoundingClarity] and ( exsanguinateCondition and comboPoints <= 2 and exsangSyncRemains <= 2 and not debuff[AS.Garrote].refreshable and debuff[AS.Rupture].remains > 9.6 )) then
		return AS.EchoingReprimand;
	end

	-- exsanguinate,if=variable.exsanguinate_condition&(!dot.garrote.refreshable&dot.rupture.remains>4+4*variable.exsanguinate_rupture_cp|dot.rupture.remains*0.5>target.time_to_die);
	if talents[AS.Exsanguinate] and cooldown[AS.Exsanguinate].ready and energy >= 25 and (exsanguinateCondition and ( not debuff[AS.Garrote].refreshable and debuff[AS.Rupture].remains > 4 + 4 * exsanguinateRuptureCp or debuff[AS.Rupture].remains * 0.5 > timeToDie )) then
		return AS.Exsanguinate;
	end

	-- shiv,if=talent.kingsbane&!debuff.shiv.up&dot.kingsbane.ticking&dot.garrote.ticking&dot.rupture.ticking&(!talent.crimson_tempest.enabled|variable.single_target|dot.crimson_tempest.ticking);
	if talents[AS.Shiv] and cooldown[AS.Shiv].ready and energy >= 20 and (talents[AS.Kingsbane] and not debuff[AS.Shiv].up and debuff[AS.Kingsbane].up and debuff[AS.Garrote].up and debuff[AS.Rupture].up and ( not talents[AS.CrimsonTempest] or singleTarget or debuff[AS.CrimsonTempest].up )) then
		return AS.Shiv;
	end

	-- shiv,if=talent.arterial_precision&!debuff.shiv.up&dot.garrote.ticking&dot.rupture.ticking&(debuff.deathmark.up|cooldown.shiv.charges_fractional>max_charges-0.5&cooldown.deathmark.remains>10);
	if talents[AS.Shiv] and cooldown[AS.Shiv].ready and energy >= 20 and (talents[AS.ArterialPrecision] and not debuff[AS.Shiv].up and debuff[AS.Garrote].up and debuff[AS.Rupture].up and ( debuff[AS.Deathmark].up or cooldown[AS.Shiv].charges > cooldown[AS.Shiv].maxCharges - 0.5 and cooldown[AS.Deathmark].remains > 10 )) then
		return AS.Shiv;
	end

	-- shiv,if=!talent.kingsbane&!talent.arterial_precision&!talent.sepsis&!debuff.shiv.up&dot.garrote.ticking&dot.rupture.ticking&(!talent.crimson_tempest.enabled|variable.single_target|dot.crimson_tempest.ticking)&(!talent.exsanguinate|variable.exsang_sync_remains>2);
	if talents[AS.Shiv] and cooldown[AS.Shiv].ready and energy >= 20 and (not talents[AS.Kingsbane] and not talents[AS.ArterialPrecision] and not talents[AS.Sepsis] and not debuff[AS.Shiv].up and debuff[AS.Garrote].up and debuff[AS.Rupture].up and ( not talents[AS.CrimsonTempest] or singleTarget or debuff[AS.CrimsonTempest].up ) and ( not talents[AS.Exsanguinate] or exsangSyncRemains > 2 )) then
		return AS.Shiv;
	end

	-- shiv,if=talent.sepsis&!talent.kingsbane&!talent.arterial_precision&!debuff.shiv.up&dot.garrote.ticking&dot.rupture.ticking&((cooldown.shiv.charges_fractional>0.9+talent.lightweight_shiv.enabled&variable.sepsis_sync_remains>5)|dot.sepsis.ticking|dot.deathmark.ticking|fight_remains<20);
	if talents[AS.Shiv] and cooldown[AS.Shiv].ready and energy >= 20 and (talents[AS.Sepsis] and not talents[AS.Kingsbane] and not talents[AS.ArterialPrecision] and not debuff[AS.Shiv].up and debuff[AS.Garrote].up and debuff[AS.Rupture].up and ( ( cooldown[AS.Shiv].charges > 0.9 + (talents[AS.LightweightShiv] and 1 or 0) and sepsisSyncRemains > 5 ) or debuff[AS.Sepsis].up or debuff[AS.Deathmark].up or timeToDie < 20 )) then
		return AS.Shiv;
	end

	-- thistle_tea,if=!buff.thistle_tea.up&(energy.deficit>=100|charges=3&(dot.kingsbane.ticking|debuff.deathmark.up)|fight_remains<charges*6);
	if talents[AS.ThistleTea] and cooldown[AS.ThistleTea].ready and (not buff[AS.ThistleTea].up and ( energyDeficit >= 100 or cooldown[AS.ThistleTea].charges == 3 and ( debuff[AS.Kingsbane].up or debuff[AS.Deathmark].up ) or timeToDie < cooldown[AS.ThistleTea].charges * 6 )) then
		return AS.ThistleTea;
	end

	-- indiscriminate_carnage,if=(spell_targets.fan_of_knives>desired_targets|spell_targets.fan_of_knives>1&raid_event.adds.in>60)&(!talent.improved_garrote|cooldown.vanish.remains>45);
	if talents[AS.IndiscriminateCarnage] and cooldown[AS.IndiscriminateCarnage].ready and (( targets > desiredTargets or targets > 1 ) and ( not talents[AS.ImprovedGarrote] or cooldown[AS.Vanish].remains > 45 )) then
		return AS.IndiscriminateCarnage;
	end

	-- call_action_list,name=vanish,if=!stealthed.all&master_assassin_remains=0;
	if not stealthedAll then
		local result = Rogue:AssassinationVanish();
		if result then
			return result;
		end
	end

	-- cold_blood,if=combo_points>=4;
	if talents[AS.ColdBlood] and cooldown[AS.ColdBlood].ready and (comboPoints >= 4) then
		return AS.ColdBlood;
	end
end

function Rogue:AssassinationDirect()
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
	local comboPoints = UnitPower('player', Enum.PowerType.ComboPoints);
	local comboPointsMax = UnitPowerMax('player', Enum.PowerType.ComboPoints);
	local comboPointsPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local comboPointsRegen = select(2,GetPowerRegen());
	local comboPointsRegenCombined = comboPointsRegen + comboPoints;
	local comboPointsDeficit = UnitPowerMax('player', Enum.PowerType.ComboPoints) - comboPoints;
	local comboPointsTimeToMax = comboPointsMax - comboPoints / comboPointsRegen;
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;

	-- envenom,if=effective_combo_points>=4+talent.deeper_stratagem.enabled&(debuff.deathmark.up|debuff.shiv.up|debuff.amplifying_poison.stack>=10|energy.deficit<=25+energy.regen_combined|!variable.single_target|effective_combo_points>cp_max_spend)&(!talent.exsanguinate.enabled|variable.exsang_sync_remains>2|talent.resounding_clarity&(cooldown.echoing_reprimand.ready&combo_points>2|effective_combo_points>5));
	if energy >= 32 and comboPoints >= 5 and (comboPoints >= 4 + (talents[AS.DeeperStratagem] and 1 or 0) and ( debuff[AS.Deathmark].up or debuff[AS.Shiv].up or debuff[AS.AmplifyingPoison].count >= 10 or energyDeficit <= 25 + energyRegenCombined or not singleTarget or comboPoints > cpMaxSpend ) and ( not talents[AS.Exsanguinate] or exsangSyncRemains > 2 or talents[AS.ResoundingClarity] and ( cooldown[AS.EchoingReprimand].ready and comboPoints > 2 or comboPoints > 5 ) )) then
		return AS.Envenom;
	end

	-- variable,name=use_filler,value=combo_points.deficit>1|energy.deficit<=25+energy.regen_combined|!variable.single_target;
	local useFiller = comboPointsDeficit > 1 or energyDeficit <= 25 + energyRegenCombined or not singleTarget;

	-- serrated_bone_spike,if=variable.use_filler&!dot.serrated_bone_spike_dot.ticking;
	if talents[AS.SerratedBoneSpike] and cooldown[AS.SerratedBoneSpike].ready and energy >= 15 and (useFiller and not debuff[AS.SerratedBoneSpikeDot].up) then
		return AS.SerratedBoneSpike;
	end

	-- serrated_bone_spike,target_if=min:target.time_to_die+(dot.serrated_bone_spike_dot.ticking*600),if=variable.use_filler&!dot.serrated_bone_spike_dot.ticking;
	if talents[AS.SerratedBoneSpike] and cooldown[AS.SerratedBoneSpike].ready and energy >= 15 and (useFiller and not debuff[AS.SerratedBoneSpikeDot].up) then
		return AS.SerratedBoneSpike;
	end

	-- serrated_bone_spike,if=variable.use_filler&master_assassin_remains<0.8&(fight_remains<=5|cooldown.serrated_bone_spike.max_charges-charges_fractional<=0.25);
	if talents[AS.SerratedBoneSpike] and cooldown[AS.SerratedBoneSpike].ready and energy >= 15 and (useFiller and 0.8 and ( timeToDie <= 5 or cooldown[AS.SerratedBoneSpike].maxCharges - cooldown[AS.SerratedBoneSpike].charges <= 0.25 )) then
		return AS.SerratedBoneSpike;
	end

	-- serrated_bone_spike,if=variable.use_filler&master_assassin_remains<0.8&!variable.single_target&debuff.shiv.up;
	if talents[AS.SerratedBoneSpike] and cooldown[AS.SerratedBoneSpike].ready and energy >= 15 and (useFiller and 0.8 and not singleTarget and debuff[AS.Shiv].up) then
		return AS.SerratedBoneSpike;
	end

	-- echoing_reprimand,if=(!talent.exsanguinate|!talent.resounding_clarity|variable.exsang_sync_remains>40)&variable.use_filler|fight_remains<20;
	if talents[AS.EchoingReprimand] and cooldown[AS.EchoingReprimand].ready and energy >= 10 and (( not talents[AS.Exsanguinate] or not talents[AS.ResoundingClarity] or exsangSyncRemains > 40 ) and useFiller or timeToDie < 20) then
		return AS.EchoingReprimand;
	end

	-- fan_of_knives,if=variable.use_filler&(!priority_rotation&spell_targets.fan_of_knives>=3+stealthed.rogue+talent.dragontempered_blades);
	if energy >= 35 and (useFiller and ( not targets >= 3 + stealthedRogue + (talents[AS.DragontemperedBlades] and 1 or 0) )) then
		return AS.FanOfKnives;
	end

	-- fan_of_knives,target_if=!dot.deadly_poison_dot.ticking&(!priority_rotation|dot.garrote.ticking|dot.rupture.ticking),if=variable.use_filler&spell_targets.fan_of_knives>=3;
	if energy >= 35 and (useFiller and targets >= 3) then
		return AS.FanOfKnives;
	end

	-- ambush,if=variable.use_filler&(buff.blindside.up|buff.sepsis_buff.remains<=1|stealthed.rogue);
	if energy >= 50 and (useFiller and ( buff[AS.Blindside].up or buff[AS.SepsisBuff].remains <= 1 or stealthedRogue )) then
		return AS.Ambush;
	end

	-- mutilate,target_if=!dot.deadly_poison_dot.ticking&!debuff.amplifying_poison.up,if=variable.use_filler&spell_targets.fan_of_knives=2;
	if energy >= 50 and (useFiller and targets == 2) then
		return AS.Mutilate;
	end

	-- mutilate,if=variable.use_filler;
	if energy >= 50 and (useFiller) then
		return AS.Mutilate;
	end
end

function Rogue:AssassinationDot()
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
	local comboPoints = UnitPower('player', Enum.PowerType.ComboPoints);
	local comboPointsMax = UnitPowerMax('player', Enum.PowerType.ComboPoints);
	local comboPointsPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local comboPointsRegen = select(2,GetPowerRegen());
	local comboPointsRegenCombined = comboPointsRegen + comboPoints;
	local comboPointsDeficit = UnitPowerMax('player', Enum.PowerType.ComboPoints) - comboPoints;
	local comboPointsTimeToMax = comboPointsMax - comboPoints / comboPointsRegen;
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;

	-- variable,name=skip_cycle_garrote,value=priority_rotation&(dot.garrote.remains<cooldown.garrote.duration|variable.regen_saturated);
	local skipCycleGarrote = ( debuff[AS.Garrote].remains < cooldown[AS.Garrote].duration or regenSaturated );

	-- variable,name=skip_cycle_rupture,value=priority_rotation&(debuff.shiv.up&spell_targets.fan_of_knives>2|variable.regen_saturated);
	local skipCycleRupture = ( debuff[AS.Shiv].up and targets > 2 or regenSaturated );

	-- variable,name=skip_rupture,value=0;
	local skipRupture = 0;

	-- rupture,if=talent.exsanguinate.enabled&!will_lose_exsanguinate&dot.rupture.pmultiplier<=1&!dot.rupture.ticking&effective_combo_points<=3&variable.single_target;
	if energy >= 22 and comboPoints >= 5 and (talents[AS.Exsanguinate] and not debuff[AS.Rupture].up and comboPoints <= 3 and singleTarget) then
		return AS.Rupture;
	end

	-- garrote,if=talent.exsanguinate.enabled&!will_lose_exsanguinate&dot.garrote.pmultiplier<=1&variable.exsang_sync_remains<2&spell_targets.fan_of_knives=1&raid_event.adds.in>6&dot.garrote.remains*0.5<target.time_to_die;
	if cooldown[AS.Garrote].ready and energy >= 45 and (talents[AS.Exsanguinate] and exsangSyncRemains < 2 and targets == 1 and debuff[AS.Garrote].remains * 0.5 < timeToDie) then
		return AS.Garrote;
	end

	-- rupture,if=talent.exsanguinate.enabled&!will_lose_exsanguinate&dot.rupture.pmultiplier<=1&variable.exsang_sync_remains<1&effective_combo_points>=variable.exsanguinate_rupture_cp&dot.rupture.remains*0.5<target.time_to_die;
	if energy >= 22 and comboPoints >= 5 and (talents[AS.Exsanguinate] and exsangSyncRemains < 1 and comboPoints >= exsanguinateRuptureCp and debuff[AS.Rupture].remains * 0.5 < timeToDie) then
		return AS.Rupture;
	end

	-- garrote,if=refreshable&combo_points.deficit>=1&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3)&(!will_lose_exsanguinate|remains<=tick_time*2&spell_targets.fan_of_knives>=3)&(target.time_to_die-remains)>4&master_assassin_remains=0;
	if cooldown[AS.Garrote].ready and energy >= 45 and (debuff[AS.Garrote].refreshable and comboPointsDeficit >= 1 and ( debuff[AS.Garrote].remains and targets >= 3 ) and ( not debuff[AS.Garrote].remains and targets >= 3 ) and ( timeToDie - debuff[AS.Garrote].remains ) > 4 ) then
		return AS.Garrote;
	end

	-- garrote,cycle_targets=1,if=!variable.skip_cycle_garrote&target!=self.target&refreshable&combo_points.deficit>=1&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3)&(!will_lose_exsanguinate|remains<=tick_time*2&spell_targets.fan_of_knives>=3)&(target.time_to_die-remains)>12&master_assassin_remains=0;
	if cooldown[AS.Garrote].ready and energy >= 45 and (not skipCycleGarrote and not debuff[AS.Garrote].refreshable and comboPointsDeficit >= 1 and ( debuff[AS.Garrote].remains and targets >= 3 ) and ( not debuff[AS.Garrote].remains and targets >= 3 ) and ( timeToDie - debuff[AS.Garrote].remains ) > 12 ) then
		return AS.Garrote;
	end

	-- crimson_tempest,target_if=min:remains,if=spell_targets>=2&effective_combo_points>=4&energy.regen_combined>20&(!cooldown.deathmark.ready|dot.rupture.ticking)&remains<(2+3*(spell_targets>=4));
	if talents[AS.CrimsonTempest] and energy >= 27 and comboPoints >= 5 and (targets >= 2 and comboPoints >= 4 and energyRegenCombined > 20 and ( not cooldown[AS.Deathmark].ready or debuff[AS.Rupture].up ) and debuff[AS.CrimsonTempest].remains < ( 2 + 3 * ( targets >= 4 ) )) then
		return AS.CrimsonTempest;
	end

	-- rupture,if=!variable.skip_rupture&effective_combo_points>=4&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3)&(!will_lose_exsanguinate|remains<=tick_time*2&spell_targets.fan_of_knives>=3)&target.time_to_die-remains>(4+(talent.dashing_scoundrel*5)+(talent.doomblade*5)+(variable.regen_saturated*6));
	if energy >= 22 and comboPoints >= 5 and (not skipRupture and comboPoints >= 4 and debuff[AS.Rupture].refreshable and ( debuff[AS.Rupture].remains and targets >= 3 ) and ( not debuff[AS.Rupture].remains and targets >= 3 ) and timeToDie - debuff[AS.Rupture].remains > ( 4 + ( (talents[AS.DashingScoundrel] and 1 or 0) * 5 ) + ( (talents[AS.Doomblade] and 1 or 0) * 5 ) + ( regenSaturated * 6 ) )) then
		return AS.Rupture;
	end

	-- rupture,cycle_targets=1,if=!variable.skip_cycle_rupture&!variable.skip_rupture&target!=self.target&effective_combo_points>=4&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3)&(!will_lose_exsanguinate|remains<=tick_time*2&spell_targets.fan_of_knives>=3)&target.time_to_die-remains>(4+(talent.dashing_scoundrel*5)+(talent.doomblade*5)+(variable.regen_saturated*6));
	if energy >= 22 and comboPoints >= 5 and (not skipCycleRupture and not skipRupture and not comboPoints >= 4 and debuff[AS.Rupture].refreshable and ( debuff[AS.Rupture].remains and targets >= 3 ) and ( not debuff[AS.Rupture].remains and targets >= 3 ) and timeToDie - debuff[AS.Rupture].remains > ( 4 + ( (talents[AS.DashingScoundrel] and 1 or 0) * 5 ) + ( (talents[AS.Doomblade] and 1 or 0) * 5 ) + ( regenSaturated * 6 ) )) then
		return AS.Rupture;
	end

	-- crimson_tempest,if=spell_targets>=2&effective_combo_points>=4&remains<2+3*(spell_targets>=4);
	if talents[AS.CrimsonTempest] and energy >= 27 and comboPoints >= 5 and (targets >= 2 and comboPoints >= 4 and debuff[AS.CrimsonTempest].remains < 2 + 3 * ( targets >= 4 )) then
		return AS.CrimsonTempest;
	end

	-- crimson_tempest,if=spell_targets=1&!talent.dashing_scoundrel&effective_combo_points>=(cp_max_spend-1)&refreshable&!will_lose_exsanguinate&!debuff.shiv.up&debuff.amplifying_poison.stack<15&(!talent.kingsbane|buff.envenom.up|!cooldown.kingsbane.up)&target.time_to_die-remains>4;
	if talents[AS.CrimsonTempest] and energy >= 27 and comboPoints >= 5 and (targets == 1 and not talents[AS.DashingScoundrel] and comboPoints >= ( cpMaxSpend - 1 ) and debuff[AS.CrimsonTempest].refreshable and not not debuff[AS.Shiv].up and debuff[AS.AmplifyingPoison].count < 15 and ( not talents[AS.Kingsbane] or buff[AS.Envenom].up or not cooldown[AS.Kingsbane].up ) and timeToDie - debuff[AS.CrimsonTempest].remains > 4) then
		return AS.CrimsonTempest;
	end
end

function Rogue:AssassinationStealthed()
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
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;

	-- indiscriminate_carnage,if=spell_targets.fan_of_knives>desired_targets|spell_targets.fan_of_knives>1&raid_event.adds.in>60;
	if talents[AS.IndiscriminateCarnage] and cooldown[AS.IndiscriminateCarnage].ready and (targets > desiredTargets or targets > 1 ) then
		return AS.IndiscriminateCarnage;
	end

	-- garrote,target_if=min:remains,if=stealthed.improved_garrote&!will_lose_exsanguinate&(remains<(12-buff.sepsis_buff.remains)%exsanguinated_rate|pmultiplier<=1)&target.time_to_die-remains>2;
	if cooldown[AS.Garrote].ready and energy >= 45 and (stealthedImprovedGarrote and not ( debuff[AS.Garrote].remains < ( 12 - buff[AS.SepsisBuff].remains )) and timeToDie - debuff[AS.Garrote].remains > 2) then
		return AS.Garrote;
	end

	-- garrote,if=talent.exsanguinate.enabled&stealthed.improved_garrote&active_enemies=1&!will_lose_exsanguinate&(remains<18%exsanguinated_rate|pmultiplier<=1)&variable.exsang_sync_remains<18&improved_garrote_remains<1.3;
	if cooldown[AS.Garrote].ready and energy >= 45 and (talents[AS.Exsanguinate] and stealthedImprovedGarrote and targets == 1 and not ( debuff[AS.Garrote].remains < 18) and exsangSyncRemains < 18 and 1.3) then
		return AS.Garrote;
	end
end

function Rogue:AssassinationVanish()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local comboPoints = UnitPower('player', Enum.PowerType.ComboPoints);
	local comboPointsMax = UnitPowerMax('player', Enum.PowerType.ComboPoints);
	local comboPointsPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local comboPointsRegen = select(2,GetPowerRegen());
	local comboPointsRegenCombined = comboPointsRegen + comboPoints;
	local comboPointsDeficit = UnitPowerMax('player', Enum.PowerType.ComboPoints) - comboPoints;
	local comboPointsTimeToMax = comboPointsMax - comboPoints / comboPointsRegen;

	-- vanish,if=talent.improved_garrote&cooldown.garrote.up&!exsanguinated.garrote&(dot.garrote.pmultiplier<=1|dot.garrote.refreshable)&(debuff.deathmark.up|cooldown.deathmark.remains<4)&combo_points.deficit>=(spell_targets.fan_of_knives>?4);
	if cooldown[AS.Vanish].ready and (talents[AS.ImprovedGarrote] and cooldown[AS.Garrote].up and not ( debuff[AS.Garrote].refreshable ) and ( debuff[AS.Deathmark].up or cooldown[AS.Deathmark].remains < 4 ) and comboPointsDeficit >= ( targets >= 4 )) then
		return AS.Vanish;
	end

	-- vanish,if=talent.improved_garrote&cooldown.garrote.up&!exsanguinated.garrote&(dot.garrote.pmultiplier<=1|dot.garrote.refreshable)&spell_targets.fan_of_knives>(3-talent.indiscriminate_carnage)&(!talent.indiscriminate_carnage|cooldown.indiscriminate_carnage.ready);
	if cooldown[AS.Vanish].ready and (talents[AS.ImprovedGarrote] and cooldown[AS.Garrote].up and not ( debuff[AS.Garrote].refreshable ) and targets > ( 3 - (talents[AS.IndiscriminateCarnage] and 1 or 0) ) and ( not talents[AS.IndiscriminateCarnage] or cooldown[AS.IndiscriminateCarnage].ready )) then
		return AS.Vanish;
	end

	-- vanish,if=!talent.improved_garrote&talent.master_assassin&!dot.rupture.refreshable&dot.garrote.remains>3&debuff.deathmark.up&(debuff.shiv.up|debuff.deathmark.remains<4|dot.sepsis.ticking)&dot.sepsis.remains<3;
	if cooldown[AS.Vanish].ready and (not talents[AS.ImprovedGarrote] and talents[AS.MasterAssassin] and not debuff[AS.Rupture].refreshable and debuff[AS.Garrote].remains > 3 and debuff[AS.Deathmark].up and ( debuff[AS.Shiv].up or debuff[AS.Deathmark].remains < 4 or debuff[AS.Sepsis].up ) and debuff[AS.Sepsis].remains < 3) then
		return AS.Vanish;
	end

	-- shadow_dance,if=talent.improved_garrote&cooldown.garrote.up&!exsanguinated.garrote&(dot.garrote.pmultiplier<=1|dot.garrote.refreshable)&(debuff.deathmark.up|cooldown.deathmark.remains<12|cooldown.deathmark.remains>60)&combo_points.deficit>=(spell_targets.fan_of_knives>?4);
	if talents[AS.ShadowDance] and cooldown[AS.ShadowDance].ready and (talents[AS.ImprovedGarrote] and cooldown[AS.Garrote].up and not ( debuff[AS.Garrote].refreshable ) and ( debuff[AS.Deathmark].up or cooldown[AS.Deathmark].remains < 12 or cooldown[AS.Deathmark].remains > 60 ) and comboPointsDeficit >= ( targets >= 4 )) then
		return AS.ShadowDance;
	end

	-- shadow_dance,if=!talent.improved_garrote&talent.master_assassin&!dot.rupture.refreshable&dot.garrote.remains>3&(debuff.deathmark.up|cooldown.deathmark.remains>60)&(debuff.shiv.up|debuff.deathmark.remains<4|dot.sepsis.ticking)&dot.sepsis.remains<3;
	if talents[AS.ShadowDance] and cooldown[AS.ShadowDance].ready and (not talents[AS.ImprovedGarrote] and talents[AS.MasterAssassin] and not debuff[AS.Rupture].refreshable and debuff[AS.Garrote].remains > 3 and ( debuff[AS.Deathmark].up or cooldown[AS.Deathmark].remains > 60 ) and ( debuff[AS.Shiv].up or debuff[AS.Deathmark].remains < 4 or debuff[AS.Sepsis].up ) and debuff[AS.Sepsis].remains < 3) then
		return AS.ShadowDance;
	end
end


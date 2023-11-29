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

local OL = {
	MarkedForDeath = 137619,
	AdrenalineRush = 13750,
	RollTheBones = 315508,
	SliceAndDice = 315496,
	Stealth = 1784,
	Kick = 1766,
	CountTheOdds = 381982,
	ShadowDance = 185313,
	HiddenOpportunity = 383281,
	Broadside = 193356,
	FanTheHammer = 381846,
	SkullAndCrossbones = 199603,
	TrueBearing = 193359,
	LoadedDice = 256170,
	BuriedTreasure = 199600,
	GrandMelee = 193358,
	KeepItRolling = 381989,
	RuthlessPrecision = 193357,
	Subterfuge = 108208,
	ImprovedAmbush = 381620,
	SummarilyDispatched = 381990,
	BladeFlurry = 13877,
	KillingSpree = 51690,
	Sepsis = 385408,
	BetweenTheEyes = 315341,
	GhostlyStrike = 196937,
	Dreadblades = 343142,
	Ambush = 8676,
	Audacity = 381845,
	FindWeakness = 91023,
	PistolShot = 185763,
	Opportunity = 279876,
	GreenskinsWickers = 386823,
	QuickDraw = 196938,
	EchoingReprimand = 385616,
	Weaponmaster = 200733,
	SinisterStrike = 193315,
	ImprovedAdrenalineRush = 395422,
	BladeRush = 271877,
	ThistleTea = 381623,
	ImprovedBetweenTheEyes = 235484,
	SwiftSlasher = 381988,
	ColdBlood = 382245,
	Dispatch = 2098,
	Vanish = 1856,
};
local A = {
};
function Rogue:Outlaw()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
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

	-- stealth;
	if cooldown[OL.Stealth].ready then
		return OL.Stealth;
	end

	-- variable,name=stealthed_cto,value=talent.count_the_odds&(stealthed.basic|buff.shadowmeld.up|buff.shadow_dance.up);
	local stealthedCto = talents[OL.CountTheOdds] and ( stealthedBasic or buff[OL.Shadowmeld].up or buff[OL.ShadowDance].up );

	-- variable,name=rtb_reroll,if=!talent.hidden_opportunity,value=rtb_buffs<2&(!buff.broadside.up&(!talent.fan_the_hammer|!buff.skull_and_crossbones.up)&!buff.true_bearing.up|buff.loaded_dice.up)|rtb_buffs=2&(buff.buried_treasure.up&buff.grand_melee.up|!buff.broadside.up&!buff.true_bearing.up&buff.loaded_dice.up);
	if not talents[OL.HiddenOpportunity] then
		local rtbReroll = WTFFFFFF;
	end

	-- variable,name=rtb_reroll,if=!talent.hidden_opportunity&(talent.keep_it_rolling|talent.count_the_odds),value=variable.rtb_reroll|((rtb_buffs.normal=0&rtb_buffs.longer>=1)&!(buff.broadside.up&buff.true_bearing.up&buff.skull_and_crossbones.up)&!(buff.broadside.remains>39|buff.true_bearing.remains>39|buff.ruthless_precision.remains>39|buff.skull_and_crossbones.remains>39));
	if not talents[OL.HiddenOpportunity] and ( talents[OL.KeepItRolling] or talents[OL.CountTheOdds] ) then
		local rtbReroll = WTFFFFFF;
	end

	-- variable,name=rtb_reroll,if=talent.hidden_opportunity,value=!rtb_buffs.will_lose.skull_and_crossbones&rtb_buffs.will_lose<2&buff.shadow_dance.down&buff.subterfuge.down;
	if talents[OL.HiddenOpportunity] then
		local rtbReroll = WTFFFFFF;
	end

	-- variable,name=rtb_reroll,op=reset,if=!(raid_event.adds.remains>12|raid_event.adds.up&(raid_event.adds.in-raid_event.adds.remains)<6|target.time_to_die>12)|fight_remains<12;
	if targets > 1 or timeToDie < 12 then
		local rtbReroll = 0;
	end

	-- variable,name=ambush_condition,value=(talent.hidden_opportunity|combo_points.deficit>=2+talent.improved_ambush+buff.broadside.up|buff.vicious_followup.up)&energy>=50;
	local ambushCondition = ( talents[OL.HiddenOpportunity] or comboPointsDeficit >= 2 + (talents[OL.ImprovedAmbush] and 1 or 0) + buff[OL.Broadside].up or buff[OL.ViciousFollowup].up ) and energy >= 50;

	-- variable,name=finish_condition,value=combo_points>=((cp_max_spend-1)<?(6-talent.summarily_dispatched))|effective_combo_points>=cp_max_spend;
	local finishCondition = comboPoints >= ( ( cpMaxSpend - 1 ) <= ( 6 - (talents[OL.SummarilyDispatched] and 1 or 0) ) ) or comboPoints >= cpMaxSpend;

	-- variable,name=blade_flurry_sync,value=spell_targets.blade_flurry<2&raid_event.adds.in>20|buff.blade_flurry.remains>1+talent.killing_spree.enabled;
	local bladeFlurrySync = targets < 2 or buff[OL.BladeFlurry].remains > 1 + talents[OL.KillingSpree];

	-- call_action_list,name=stealth,if=stealthed.basic|buff.shadowmeld.up;
	if stealthedBasic or buff[OL.Shadowmeld].up then
		local result = Rogue:OutlawStealth();
		if result then
			return result;
		end
	end

	-- call_action_list,name=cds;
	local result = Rogue:OutlawCds();
	if result then
		return result;
	end

	-- call_action_list,name=stealth,if=variable.stealthed_cto;
	if stealthedCto then
		local result = Rogue:OutlawStealth();
		if result then
			return result;
		end
	end

	-- run_action_list,name=finish,if=variable.finish_condition;
	if finishCondition then
		return Rogue:OutlawFinish();
	end

	-- call_action_list,name=build;
	local result = Rogue:OutlawBuild();
	if result then
		return result;
	end
end
function Rogue:OutlawBuild()
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

	-- sepsis,target_if=max:target.time_to_die*debuff.between_the_eyes.up,if=target.time_to_die>11&debuff.between_the_eyes.up|fight_remains<11;
	if talents[OL.Sepsis] and cooldown[OL.Sepsis].ready and energy >= 25 and (timeToDie > 11 and debuff[OL.BetweenTheEyes].up or timeToDie < 11) then
		return OL.Sepsis;
	end

	-- ghostly_strike,if=debuff.ghostly_strike.remains<=3&(spell_targets.blade_flurry<=2|buff.dreadblades.up)&!buff.subterfuge.up&target.time_to_die>=5;
	if talents[OL.GhostlyStrike] and cooldown[OL.GhostlyStrike].ready and energy >= 30 and (debuff[OL.GhostlyStrike].remains <= 3 and ( targets <= 2 or buff[OL.Dreadblades].up ) and not buff[OL.Subterfuge].up and timeToDie >= 5) then
		return OL.GhostlyStrike;
	end

	-- ambush,if=talent.keep_it_rolling&((buff.audacity.up|buff.sepsis_buff.up)&talent.find_weakness&debuff.find_weakness.remains<2|buff.subterfuge.up&cooldown.keep_it_rolling.ready);
	if energy >= 50 and (talents[OL.KeepItRolling] and ( ( buff[OL.Audacity].up or buff[OL.SepsisBuff].up ) and talents[OL.FindWeakness] and debuff[OL.FindWeakness].remains < 2 or buff[OL.Subterfuge].up and cooldown[OL.KeepItRolling].ready )) then
		return OL.Ambush;
	end

	-- ambush,if=talent.hidden_opportunity&(buff.audacity.up|buff.sepsis_buff.up);
	if energy >= 50 and (talents[OL.HiddenOpportunity] and ( buff[OL.Audacity].up or buff[OL.SepsisBuff].up )) then
		return OL.Ambush;
	end

	-- pistol_shot,if=talent.fan_the_hammer&talent.audacity&talent.hidden_opportunity&buff.opportunity.up&!buff.audacity.up&!buff.subterfuge.up&!buff.shadow_dance.up;
	if energy >= 40 and (talents[OL.FanTheHammer] and talents[OL.Audacity] and talents[OL.HiddenOpportunity] and buff[OL.Opportunity].up and not buff[OL.Audacity].up and not buff[OL.Subterfuge].up and not buff[OL.ShadowDance].up) then
		return OL.PistolShot;
	end

	-- pistol_shot,if=buff.greenskins_wickers.up&(!talent.fan_the_hammer&buff.opportunity.up|buff.greenskins_wickers.remains<1.5);
	if energy >= 40 and (buff[OL.GreenskinsWickers].up and ( not talents[OL.FanTheHammer] and buff[OL.Opportunity].up or buff[OL.GreenskinsWickers].remains < 1.5 )) then
		return OL.PistolShot;
	end

	-- pistol_shot,if=talent.fan_the_hammer&buff.opportunity.up&(buff.opportunity.stack>=buff.opportunity.max_stack|buff.opportunity.remains<2);
	if energy >= 40 and (talents[OL.FanTheHammer] and buff[OL.Opportunity].up and ( buff[OL.Opportunity].count >= buff[OL.Opportunity].maxStacks or buff[OL.Opportunity].remains < 2 )) then
		return OL.PistolShot;
	end

	-- pistol_shot,if=talent.fan_the_hammer&buff.opportunity.up&combo_points.deficit>((1+talent.quick_draw)*talent.fan_the_hammer.rank)&!buff.dreadblades.up&(!talent.hidden_opportunity|!buff.subterfuge.up&!buff.shadow_dance.up);
	if energy >= 40 and (talents[OL.FanTheHammer] and buff[OL.Opportunity].up and comboPointsDeficit > ( ( 1 + (talents[OL.QuickDraw] and 1 or 0) ) * (talents[OL.FanTheHammer] and 1 or 0) ) and not buff[OL.Dreadblades].up and ( not talents[OL.HiddenOpportunity] or not buff[OL.Subterfuge].up and not buff[OL.ShadowDance].up )) then
		return OL.PistolShot;
	end

	-- echoing_reprimand;
	if talents[OL.EchoingReprimand] and cooldown[OL.EchoingReprimand].ready and energy >= 10 then
		return OL.EchoingReprimand;
	end

	-- ambush,if=talent.hidden_opportunity|talent.find_weakness&debuff.find_weakness.down;
	if energy >= 50 and (talents[OL.HiddenOpportunity] or talents[OL.FindWeakness] and not debuff[OL.FindWeakness].up) then
		return OL.Ambush;
	end

	-- pistol_shot,if=!talent.fan_the_hammer&buff.opportunity.up&(energy.base_deficit>energy.regen*1.5|!talent.weaponmaster&combo_points.deficit<=1+buff.broadside.up|talent.quick_draw.enabled|talent.audacity.enabled&!buff.audacity.up);
	if energy >= 40 and (not talents[OL.FanTheHammer] and buff[OL.Opportunity].up and ( energyBaseDeficit > energyRegen * 1.5 or not talents[OL.Weaponmaster] and comboPointsDeficit <= 1 + buff[OL.Broadside].up or talents[OL.QuickDraw] or talents[OL.Audacity] and not buff[OL.Audacity].up )) then
		return OL.PistolShot;
	end

	-- sinister_strike;
	if energy >= 45 then
		return OL.SinisterStrike;
	end
end

function Rogue:OutlawCds()
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

	-- adrenaline_rush,if=!buff.adrenaline_rush.up&(!talent.improved_adrenaline_rush|combo_points<=2);
	if talents[OL.AdrenalineRush] and cooldown[OL.AdrenalineRush].ready and (not buff[OL.AdrenalineRush].up and ( not talents[OL.ImprovedAdrenalineRush] or comboPoints <= 2 )) then
		return OL.AdrenalineRush;
	end

	-- blade_flurry,if=(spell_targets>=2|((buff.grand_melee.up&talent.hidden_opportunity)|(buff.grand_melee.remains>10))&!stealthed.rogue&!buff.dreadblades.up)&buff.blade_flurry.remains<gcd;
	if talents[OL.BladeFlurry] and cooldown[OL.BladeFlurry].ready and energy >= 15 and (( targets >= 2 or ( ( buff[OL.GrandMelee].up and talents[OL.HiddenOpportunity] ) or ( buff[OL.GrandMelee].remains > 10 ) ) and not stealthedRogue and not buff[OL.Dreadblades].up ) and buff[OL.BladeFlurry].remains < gcd) then
		return OL.BladeFlurry;
	end

	-- roll_the_bones,if=buff.dreadblades.down&(rtb_buffs.total=0|variable.rtb_reroll);
	if talents[OL.RollTheBones] and cooldown[OL.RollTheBones].ready and energy >= 25 and (not buff[OL.Dreadblades].up and ( rtbBuffsTotal == 0 or rtbReroll )) then
		return OL.RollTheBones;
	end

	-- keep_it_rolling,if=!variable.rtb_reroll&(buff.broadside.up+buff.true_bearing.up+buff.skull_and_crossbones.up+buff.ruthless_precision.up+buff.grand_melee.up)>2&(buff.shadow_dance.down|rtb_buffs>=6);
	if talents[OL.KeepItRolling] and cooldown[OL.KeepItRolling].ready and (not rtbReroll and ( buff[OL.Broadside].up + buff[OL.TrueBearing].up + buff[OL.SkullAndCrossbones].up + buff[OL.RuthlessPrecision].up + buff[OL.GrandMelee].up ) > 2 and ( not buff[OL.ShadowDance].up or rtbBuffs >= 6 )) then
		return OL.KeepItRolling;
	end

	-- blade_rush,if=variable.blade_flurry_sync&!buff.dreadblades.up&(energy.base_time_to_max>4+stealthed.rogue-spell_targets%3);
	if talents[OL.BladeRush] and cooldown[OL.BladeRush].ready and (bladeFlurrySync and not buff[OL.Dreadblades].up and ( energyBaseTimeToMax > 4 + stealthedRogue - targets / 3 )) then
		return OL.BladeRush;
	end

	-- call_action_list,name=stealth_cds,if=!stealthed.all|talent.count_the_odds&!talent.hidden_opportunity&!variable.stealthed_cto;
	if not stealthedAll or talents[OL.CountTheOdds] and not talents[OL.HiddenOpportunity] and not stealthedCto then
		local result = Rogue:OutlawStealthCds();
		if result then
			return result;
		end
	end

	-- dreadblades,if=!(variable.stealthed_cto|stealthed.basic|talent.hidden_opportunity&stealthed.rogue)&combo_points<=2&(!talent.marked_for_death|!cooldown.marked_for_death.ready)&target.time_to_die>=10;
	if talents[OL.Dreadblades] and cooldown[OL.Dreadblades].ready and energy >= 40 and (not ( stealthedCto or stealthedBasic or talents[OL.HiddenOpportunity] and stealthedRogue ) and comboPoints <= 2 and ( not talents[OL.MarkedForDeath] or not cooldown[OL.MarkedForDeath].ready ) and timeToDie >= 10) then
		return OL.Dreadblades;
	end

	-- marked_for_death,line_cd=1.5,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit|combo_points.deficit>=cp_max_spend-1)&!buff.dreadblades.up;
	if talents[OL.MarkedForDeath] and cooldown[OL.MarkedForDeath].ready and (raid_event.adds.up and ( timeToDie < comboPointsDeficit or comboPointsDeficit >= cpMaxSpend - 1 ) and not buff[OL.Dreadblades].up) then
		return OL.MarkedForDeath;
	end

	-- marked_for_death,if=raid_event.adds.in>30-raid_event.adds.duration&combo_points.deficit>=cp_max_spend-1&!buff.dreadblades.up;
	if talents[OL.MarkedForDeath] and cooldown[OL.MarkedForDeath].ready and (comboPointsDeficit >= cpMaxSpend - 1 and not buff[OL.Dreadblades].up) then
		return OL.MarkedForDeath;
	end

	-- thistle_tea,if=!buff.thistle_tea.up&(energy.base_deficit>=100|fight_remains<charges*6);
	if talents[OL.ThistleTea] and cooldown[OL.ThistleTea].ready and (not buff[OL.ThistleTea].up and ( energyBaseDeficit >= 100 or timeToDie < cooldown[OL.ThistleTea].charges * 6 )) then
		return OL.ThistleTea;
	end

	-- killing_spree,if=variable.blade_flurry_sync&!stealthed.rogue&debuff.between_the_eyes.up&energy.base_time_to_max>4;
	if talents[OL.KillingSpree] and cooldown[OL.KillingSpree].ready and (bladeFlurrySync and not stealthedRogue and debuff[OL.BetweenTheEyes].up and energyBaseTimeToMax > 4) then
		return OL.KillingSpree;
	end
end

function Rogue:OutlawFinish()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
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

	-- between_the_eyes,if=target.time_to_die>3&(debuff.between_the_eyes.remains<4|talent.greenskins_wickers&!buff.greenskins_wickers.up|!talent.greenskins_wickers&talent.improved_between_the_eyes&buff.ruthless_precision.up|!talent.greenskins_wickers&set_bonus.tier30_4pc);
	if cooldown[OL.BetweenTheEyes].ready and energy >= 22 and comboPoints >= 6 and (timeToDie > 3 and ( debuff[OL.BetweenTheEyes].remains < 4 or talents[OL.GreenskinsWickers] and not buff[OL.GreenskinsWickers].up or not talents[OL.GreenskinsWickers] and talents[OL.ImprovedBetweenTheEyes] and buff[OL.RuthlessPrecision].up or not talents[OL.GreenskinsWickers] and MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 4) )) then
		return OL.BetweenTheEyes;
	end

	-- slice_and_dice,if=buff.slice_and_dice.remains<fight_remains&refreshable&(!talent.swift_slasher|combo_points>=cp_max_spend);
	if energy >= 20 and comboPoints >= 6 and (buff[OL.SliceAndDice].remains < timeToDie and debuff[OL.SliceAndDice].refreshable and ( not talents[OL.SwiftSlasher] or comboPoints >= cpMaxSpend )) then
		return OL.SliceAndDice;
	end

	-- cold_blood;
	if talents[OL.ColdBlood] and cooldown[OL.ColdBlood].ready then
		return OL.ColdBlood;
	end

	-- dispatch;
	if energy >= 32 and comboPoints >= 6 then
		return OL.Dispatch;
	end
end

function Rogue:OutlawStealth()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
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

	-- blade_flurry,if=talent.subterfuge&talent.hidden_opportunity&spell_targets>=2&!buff.blade_flurry.up;
	if talents[OL.BladeFlurry] and cooldown[OL.BladeFlurry].ready and energy >= 15 and (talents[OL.Subterfuge] and talents[OL.HiddenOpportunity] and targets >= 2 and not buff[OL.BladeFlurry].up) then
		return OL.BladeFlurry;
	end

	-- cold_blood,if=variable.finish_condition;
	if talents[OL.ColdBlood] and cooldown[OL.ColdBlood].ready and (finishCondition) then
		return OL.ColdBlood;
	end

	-- dispatch,if=variable.finish_condition;
	if energy >= 32 and comboPoints >= 6 and (finishCondition) then
		return OL.Dispatch;
	end

	-- ambush,if=variable.stealthed_cto|stealthed.basic&talent.find_weakness&!debuff.find_weakness.up|talent.hidden_opportunity;
	if energy >= 50 and (stealthedCto or stealthedBasic and talents[OL.FindWeakness] and not debuff[OL.FindWeakness].up or talents[OL.HiddenOpportunity]) then
		return OL.Ambush;
	end
end

function Rogue:OutlawStealthCds()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;

	-- variable,name=vanish_condition,value=talent.hidden_opportunity|!talent.shadow_dance|!cooldown.shadow_dance.ready;
	local vanishCondition = talents[OL.HiddenOpportunity] or not talents[OL.ShadowDance] or not cooldown[OL.ShadowDance].ready;

	-- variable,name=vanish_opportunity_condition,value=!talent.shadow_dance&talent.fan_the_hammer.rank+talent.quick_draw+talent.audacity<talent.count_the_odds+talent.keep_it_rolling;
	local vanishOpportunityCondition = not talents[OL.ShadowDance] and (talents[OL.FanTheHammer] and 1 or 0) + (talents[OL.QuickDraw] and 1 or 0) + (talents[OL.Audacity] and 1 or 0) < (talents[OL.CountTheOdds] and 1 or 0) + talents[OL.KeepItRolling];

	-- vanish,if=talent.find_weakness&!talent.audacity&debuff.find_weakness.down&variable.ambush_condition&variable.vanish_condition;
	if cooldown[OL.Vanish].ready and (talents[OL.FindWeakness] and not talents[OL.Audacity] and not debuff[OL.FindWeakness].up and ambushCondition and vanishCondition) then
		return OL.Vanish;
	end

	-- vanish,if=talent.hidden_opportunity&!buff.audacity.up&(variable.vanish_opportunity_condition|buff.opportunity.stack<buff.opportunity.max_stack)&variable.ambush_condition&variable.vanish_condition;
	if cooldown[OL.Vanish].ready and (talents[OL.HiddenOpportunity] and not buff[OL.Audacity].up and ( vanishOpportunityCondition or buff[OL.Opportunity].count < buff[OL.Opportunity].maxStacks ) and ambushCondition and vanishCondition) then
		return OL.Vanish;
	end

	-- vanish,if=(!talent.find_weakness|talent.audacity)&!talent.hidden_opportunity&variable.finish_condition&variable.vanish_condition;
	if cooldown[OL.Vanish].ready and (( not talents[OL.FindWeakness] or talents[OL.Audacity] ) and not talents[OL.HiddenOpportunity] and finishCondition and vanishCondition) then
		return OL.Vanish;
	end

	-- variable,name=shadow_dance_condition,value=talent.shadow_dance&debuff.between_the_eyes.up&(!talent.ghostly_strike|debuff.ghostly_strike.up)&(!talent.dreadblades|!cooldown.dreadblades.ready)&(!talent.hidden_opportunity|!buff.audacity.up&(talent.fan_the_hammer.rank<2|!buff.opportunity.up));
	local shadowDanceCondition = talents[OL.ShadowDance] and debuff[OL.BetweenTheEyes].up and ( not talents[OL.GhostlyStrike] or debuff[OL.GhostlyStrike].up ) and ( not talents[OL.Dreadblades] or not cooldown[OL.Dreadblades].ready ) and ( not talents[OL.HiddenOpportunity] or not buff[OL.Audacity].up and ( talents[OL.FanTheHammer] < 2 or not buff[OL.Opportunity].up ) );

	-- shadow_dance,if=!talent.keep_it_rolling&variable.shadow_dance_condition&buff.slice_and_dice.up&(variable.finish_condition|talent.hidden_opportunity)&(!talent.hidden_opportunity|!cooldown.vanish.ready);
	if talents[OL.ShadowDance] and cooldown[OL.ShadowDance].ready and (not talents[OL.KeepItRolling] and shadowDanceCondition and buff[OL.SliceAndDice].up and ( finishCondition or talents[OL.HiddenOpportunity] ) and ( not talents[OL.HiddenOpportunity] or not cooldown[OL.Vanish].ready )) then
		return OL.ShadowDance;
	end

	-- shadow_dance,if=talent.keep_it_rolling&variable.shadow_dance_condition&(cooldown.keep_it_rolling.remains<=30|cooldown.keep_it_rolling.remains>120&(variable.finish_condition|talent.hidden_opportunity));
	if talents[OL.ShadowDance] and cooldown[OL.ShadowDance].ready and (talents[OL.KeepItRolling] and shadowDanceCondition and ( cooldown[OL.KeepItRolling].remains <= 30 or cooldown[OL.KeepItRolling].remains > 120 and ( finishCondition or talents[OL.HiddenOpportunity] ) )) then
		return OL.ShadowDance;
	end
end


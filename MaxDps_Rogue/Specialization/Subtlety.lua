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

local SB = {
	Stealth = 1784,
	MarkedForDeath = 137619,
	SliceAndDice = 315496,
	Kick = 1766,
	EchoingReprimand = 385616,
	EchoingReprimand2 = 323558,
	EchoingReprimand3 = 323559,
	EchoingReprimand4 = 323560,
	EchoingReprimand5 = 354838,
	Vigor = 14983,
	MasterOfShadows = 196976,
	ShadowFocus = 108209,
	Alacrity = 193539,
	TheRotten = 382015,
	SealFate = 14190,
	ShurikenStorm = 197835,
	Gloomblade = 200758,
	LingeringShadow = 382524,
	PerforatedVeins = 382518,
	Backstab = 53,
	Premeditation = 343160,
	ShadowDance = 185313,
	ShurikenTornado = 277925,
	SymbolsOfDeath = 212283,
	Vanish = 1856,
	DanseMacabre = 382528,
	SecretTechnique = 280719,
	ColdBlood = 382245,
	Flagellation = 384631,
	Sepsis = 385408,
	Tier302pc = 405563,
	ShadowBlades = 121471,
	ResoundingClarity = 381622,
	Subterfuge = 108208,
	ThistleTea = 381623,
	Rupture = 1943,
	DarkBrew = 382504,
	BlackPowder = 319175,
	Eviscerate = 196819,
	Shadowstrike = 185438,
	SilentStorm = 385722,
	FindWeakness = 91023,
	ImprovedShurikenStorm = 319951,
	DeeperStratagem = 193531,
	SecretStratagem = 394320,
};
local A = {
};
function Rogue:Subtlety()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
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

	-- stealth;
	if cooldown[SB.Stealth].ready then
		return SB.Stealth;
	end

	-- variable,name=snd_condition,value=buff.slice_and_dice.up|spell_targets.shuriken_storm>=cp_max_spend;
	local sndCondition = buff[SB.SliceAndDice].up or targets >= cpMaxSpend;

	-- variable,name=is_next_cp_animacharged,if=talent.echoing_reprimand.enabled,value=combo_points=1&buff.echoing_reprimand_2.up|combo_points=2&buff.echoing_reprimand_3.up|combo_points=3&buff.echoing_reprimand_4.up|combo_points=4&buff.echoing_reprimand_5.up;
	if talents[SB.EchoingReprimand] then
		local isNextCpAnimacharged = WTFFFFFF;
	end

	-- variable,name=effective_combo_points,value=effective_combo_points;
	local effectiveComboPoints = comboPoints;

	-- variable,name=effective_combo_points,if=talent.echoing_reprimand.enabled&effective_combo_points>combo_points&combo_points.deficit>2&time_to_sht.4.plus<0.5&!variable.is_next_cp_animacharged,value=combo_points;
	if talents[SB.EchoingReprimand] and comboPoints > comboPoints and comboPointsDeficit > 2 and 0.5 and not isNextCpAnimacharged then
		local effectiveComboPoints = WTFFFFFF;
	end

	-- call_action_list,name=cds;
	local result = Rogue:SubtletyCds();
	if result then
		return result;
	end

	-- slice_and_dice,if=spell_targets.shuriken_storm<cp_max_spend&buff.slice_and_dice.remains<gcd.max&fight_remains>6&combo_points>=4;
	if energy >= 20 and comboPoints >= 6 and (targets < cpMaxSpend and buff[SB.SliceAndDice].remains < gcd and timeToDie > 6 and comboPoints >= 4) then
		return SB.SliceAndDice;
	end

	-- run_action_list,name=stealthed,if=stealthed.all;
	if stealthedAll then
		return Rogue:SubtletyStealthed();
	end

	-- variable,name=priority_rotation,value=priority_rotation;
	--local priorityRotation = ;

	-- variable,name=stealth_threshold,value=25+talent.vigor.enabled*20+talent.master_of_shadows.enabled*20+talent.shadow_focus.enabled*25+talent.alacrity.enabled*20+25*(spell_targets.shuriken_storm>=4);
	local stealthThreshold = 25 + (talents[SB.Vigor] and 1 or 0) * 20 + (talents[SB.MasterOfShadows] and 1 or 0) * 20 + (talents[SB.ShadowFocus] and 1 or 0) * 25 + (talents[SB.Alacrity] and 1 or 0) * 20 + 25 * ( targets >= 4 );

	-- call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold;
	if energyDeficit <= stealthThreshold then
		local result = Rogue:SubtletyStealthCds();
		if result then
			return result;
		end
	end

	-- call_action_list,name=finish,if=variable.effective_combo_points>=cp_max_spend;
	if effectiveComboPoints >= cpMaxSpend then
		local result = Rogue:SubtletyFinish();
		if result then
			return result;
		end
	end

	-- call_action_list,name=finish,if=combo_points.deficit<=1+buff.the_rotten.up|fight_remains<=1&variable.effective_combo_points>=3;
	if comboPointsDeficit <= 1 + buff[SB.TheRotten].up or timeToDie <= 1 and effectiveComboPoints >= 3 then
		local result = Rogue:SubtletyFinish();
		if result then
			return result;
		end
	end

	-- call_action_list,name=finish,if=spell_targets.shuriken_storm>=(4-talent.seal_fate)&variable.effective_combo_points>=4;
	if targets >= ( 4 - (talents[SB.SealFate] and 1 or 0) ) and effectiveComboPoints >= 4 then
		local result = Rogue:SubtletyFinish();
		if result then
			return result;
		end
	end

	-- call_action_list,name=build,if=energy.deficit<=variable.stealth_threshold;
	if energyDeficit <= stealthThreshold then
		local result = Rogue:SubtletyBuild();
		if result then
			return result;
		end
	end
end
function Rogue:SubtletyBuild()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local buff = fd.buff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;

	-- shuriken_storm,if=spell_targets>=2+(talent.gloomblade&buff.lingering_shadow.remains>=6|buff.perforated_veins.up);
	if energy >= 35 and (targets >= 2 + ( talents[SB.Gloomblade] and buff[SB.LingeringShadow].remains >= 6 or buff[SB.PerforatedVeins].up )) then
		return SB.ShurikenStorm;
	end

	-- variable,name=anima_helper,value=!talent.echoing_reprimand.enabled|!(variable.is_next_cp_animacharged&(time_to_sht.3.plus<0.5|time_to_sht.4.plus<1)&energy<60);
	local animaHelper = not talents[SB.EchoingReprimand] or not ( isNextCpAnimacharged and ( 0.5 or 1 ) and energy < 60 );

	-- gloomblade,if=variable.anima_helper;
	if talents[SB.Gloomblade] and energy >= 35 and (animaHelper) then
		return SB.Gloomblade;
	end

	-- backstab,if=variable.anima_helper;
	if energy >= 35 and (animaHelper) then
		return SB.Backstab;
	end
end

function Rogue:SubtletyCds()
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

	-- variable,name=rotten_condition,value=!buff.premeditation.up&spell_targets.shuriken_storm=1|!talent.the_rotten|spell_targets.shuriken_storm>1;
	local rottenCondition = not buff[SB.Premeditation].up and targets == 1 or not talents[SB.TheRotten] or targets > 1;

	-- shadow_dance,use_off_gcd=1,if=!buff.shadow_dance.up&buff.shuriken_tornado.up&buff.shuriken_tornado.remains<=3.5;
	if talents[SB.ShadowDance] and cooldown[SB.ShadowDance].ready and (not buff[SB.ShadowDance].up and buff[SB.ShurikenTornado].up and buff[SB.ShurikenTornado].remains <= 3.5) then
		return SB.ShadowDance;
	end

	-- symbols_of_death,use_off_gcd=1,if=buff.shuriken_tornado.up&buff.shuriken_tornado.remains<=3.5;
	if cooldown[SB.SymbolsOfDeath].ready and (buff[SB.ShurikenTornado].up and buff[SB.ShurikenTornado].remains <= 3.5) then
		return SB.SymbolsOfDeath;
	end

	-- vanish,if=buff.danse_macabre.stack>3&combo_points<=2&(cooldown.secret_technique.remains>=30|!talent.secret_technique);
	if cooldown[SB.Vanish].ready and (buff[SB.DanseMacabre].count > 3 and comboPoints <= 2 and ( cooldown[SB.SecretTechnique].remains >= 30 or not talents[SB.SecretTechnique] )) then
		return SB.Vanish;
	end

	-- cold_blood,if=!talent.secret_technique&combo_points>=5;
	if talents[SB.ColdBlood] and cooldown[SB.ColdBlood].ready and (not talents[SB.SecretTechnique] and comboPoints >= 5) then
		return SB.ColdBlood;
	end

	-- flagellation,target_if=max:target.time_to_die,if=variable.snd_condition&combo_points>=5&target.time_to_die>10;
	if talents[SB.Flagellation] and cooldown[SB.Flagellation].ready and (sndCondition and comboPoints >= 5 and timeToDie > 10) then
		return SB.Flagellation;
	end

	-- shuriken_tornado,if=spell_targets.shuriken_storm<=1&energy>=60&variable.snd_condition&cooldown.symbols_of_death.up&cooldown.shadow_dance.charges>=1&(!talent.flagellation.enabled&!cooldown.flagellation.up|buff.flagellation_buff.up|spell_targets.shuriken_storm>=5)&combo_points<=2&!buff.premeditation.up;
	if talents[SB.ShurikenTornado] and cooldown[SB.ShurikenTornado].ready and energy >= 60 and (targets <= 1 and energy >= 60 and sndCondition and cooldown[SB.SymbolsOfDeath].up and cooldown[SB.ShadowDance].charges >= 1 and ( not talents[SB.Flagellation] and not cooldown[SB.Flagellation].up or buff[SB.FlagellationBuff].up or targets >= 5 ) and comboPoints <= 2 and not buff[SB.Premeditation].up) then
		return SB.ShurikenTornado;
	end

	-- sepsis,if=variable.snd_condition&combo_points.deficit>=1&target.time_to_die>=16;
	if talents[SB.Sepsis] and cooldown[SB.Sepsis].ready and energy >= 25 and (sndCondition and comboPointsDeficit >= 1 and timeToDie >= 16) then
		return SB.Sepsis;
	end

	-- symbols_of_death,if=(buff.symbols_of_death.remains<=3&!cooldown.shadow_dance.ready|!set_bonus.tier30_2pc)&variable.rotten_condition&variable.snd_condition&(!talent.flagellation&(combo_points<=1|!talent.the_rotten)|cooldown.flagellation.remains>10|cooldown.flagellation.up&combo_points>=5);
	if cooldown[SB.SymbolsOfDeath].ready and (( buff[SB.SymbolsOfDeath].remains <= 3 and not cooldown[SB.ShadowDance].ready or not MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2) ) and rottenCondition and sndCondition and ( not talents[SB.Flagellation] and ( comboPoints <= 1 or not talents[SB.TheRotten] ) or cooldown[SB.Flagellation].remains > 10 or cooldown[SB.Flagellation].up and comboPoints >= 5 )) then
		return SB.SymbolsOfDeath;
	end

	-- marked_for_death,line_cd=1.5,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit|!stealthed.all&combo_points.deficit>=cp_max_spend);
	if talents[SB.MarkedForDeath] and cooldown[SB.MarkedForDeath].ready and (raid_event.adds.up and ( timeToDie < comboPointsDeficit or not stealthedAll and comboPointsDeficit >= cpMaxSpend )) then
		return SB.MarkedForDeath;
	end

	-- marked_for_death,if=raid_event.adds.in>30-raid_event.adds.duration&combo_points.deficit>=cp_max_spend;
	if talents[SB.MarkedForDeath] and cooldown[SB.MarkedForDeath].ready and (targets > 1 and comboPointsDeficit >= cpMaxSpend) then
		return SB.MarkedForDeath;
	end

	-- shadow_blades,if=variable.snd_condition&combo_points.deficit>=2&target.time_to_die>=10&(dot.sepsis.ticking|cooldown.sepsis.remains<=8|!talent.sepsis)|fight_remains<=20;
	if talents[SB.ShadowBlades] and cooldown[SB.ShadowBlades].ready and (sndCondition and comboPointsDeficit >= 2 and timeToDie >= 10 and ( debuff[SB.Sepsis].up or cooldown[SB.Sepsis].remains <= 8 or not talents[SB.Sepsis] ) or timeToDie <= 20) then
		return SB.ShadowBlades;
	end

	-- echoing_reprimand,if=variable.snd_condition&combo_points.deficit>=3&(variable.priority_rotation|spell_targets.shuriken_storm<=4|talent.resounding_clarity)&(buff.shadow_dance.up|!talent.danse_macabre);
	if talents[SB.EchoingReprimand] and cooldown[SB.EchoingReprimand].ready and energy >= 10 and (sndCondition and comboPointsDeficit >= 3 and ( priorityRotation or targets <= 4 or talents[SB.ResoundingClarity] ) and ( buff[SB.ShadowDance].up or not talents[SB.DanseMacabre] )) then
		return SB.EchoingReprimand;
	end

	-- shuriken_tornado,if=variable.snd_condition&buff.symbols_of_death.up&combo_points<=2&(!buff.premeditation.up|spell_targets.shuriken_storm>4);
	if talents[SB.ShurikenTornado] and cooldown[SB.ShurikenTornado].ready and energy >= 60 and (sndCondition and buff[SB.SymbolsOfDeath].up and comboPoints <= 2 and ( not buff[SB.Premeditation].up or targets > 4 )) then
		return SB.ShurikenTornado;
	end

	-- shuriken_tornado,if=cooldown.shadow_dance.ready&!stealthed.all&spell_targets.shuriken_storm>=3&!talent.flagellation.enabled;
	if talents[SB.ShurikenTornado] and cooldown[SB.ShurikenTornado].ready and energy >= 60 and (cooldown[SB.ShadowDance].ready and not stealthedAll and targets >= 3 and not talents[SB.Flagellation]) then
		return SB.ShurikenTornado;
	end

	-- shadow_dance,if=!buff.shadow_dance.up&fight_remains<=8+talent.subterfuge.enabled;
	if talents[SB.ShadowDance] and cooldown[SB.ShadowDance].ready and (not buff[SB.ShadowDance].up and timeToDie <= 8 + talents[SB.Subterfuge]) then
		return SB.ShadowDance;
	end

	-- thistle_tea,if=(cooldown.symbols_of_death.remains>=3|buff.symbols_of_death.up)&!buff.thistle_tea.up&(energy.deficit>=100&(combo_points.deficit>=2|spell_targets.shuriken_storm>=3)|cooldown.thistle_tea.charges_fractional>=2.75&buff.shadow_dance.up)|buff.shadow_dance.remains>=4&!buff.thistle_tea.up&spell_targets.shuriken_storm>=3|!buff.thistle_tea.up&fight_remains<=(6*cooldown.thistle_tea.charges);
	if talents[SB.ThistleTea] and cooldown[SB.ThistleTea].ready and (( cooldown[SB.SymbolsOfDeath].remains >= 3 or buff[SB.SymbolsOfDeath].up ) and not buff[SB.ThistleTea].up and ( energyDeficit >= 100 and ( comboPointsDeficit >= 2 or targets >= 3 ) or cooldown[SB.ThistleTea].charges >= 2.75 and buff[SB.ShadowDance].up ) or buff[SB.ShadowDance].remains >= 4 and not buff[SB.ThistleTea].up and targets >= 3 or not buff[SB.ThistleTea].up and timeToDie <= ( 6 * cooldown[SB.ThistleTea].charges )) then
		return SB.ThistleTea;
	end
end

function Rogue:SubtletyFinish()
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

	-- variable,name=secret_condition,value=buff.shadow_dance.up&(buff.danse_macabre.stack>=3|!talent.danse_macabre)&(!buff.premeditation.up|spell_targets.shuriken_storm!=2);
	local secretCondition = buff[SB.ShadowDance].up and ( buff[SB.DanseMacabre].count >= 3 or not talents[SB.DanseMacabre] ) and ( not buff[SB.Premeditation].up or targets );

	-- variable,name=premed_snd_condition,value=talent.premeditation.enabled&spell_targets.shuriken_storm<5;
	local premedSndCondition = talents[SB.Premeditation] and targets < 5;

	-- slice_and_dice,if=!variable.premed_snd_condition&spell_targets.shuriken_storm<6&!buff.shadow_dance.up&buff.slice_and_dice.remains<fight_remains&refreshable;
	if energy >= 20 and comboPoints >= 6 and (not premedSndCondition and targets < 6 and not buff[SB.ShadowDance].up and buff[SB.SliceAndDice].remains < timeToDie and debuff[SB.SliceAndDice].refreshable) then
		return SB.SliceAndDice;
	end

	-- slice_and_dice,if=variable.premed_snd_condition&cooldown.shadow_dance.charges_fractional<1.75&buff.slice_and_dice.remains<cooldown.symbols_of_death.remains&(cooldown.shadow_dance.ready&buff.symbols_of_death.remains-buff.shadow_dance.remains<1.2);
	if energy >= 20 and comboPoints >= 6 and (premedSndCondition and cooldown[SB.ShadowDance].charges < 1.75 and buff[SB.SliceAndDice].remains < cooldown[SB.SymbolsOfDeath].remains and ( cooldown[SB.ShadowDance].ready and buff[SB.SymbolsOfDeath].remains - buff[SB.ShadowDance].remains < 1.2 )) then
		return SB.SliceAndDice;
	end

	-- variable,name=skip_rupture,value=buff.thistle_tea.up&spell_targets.shuriken_storm=1|buff.shadow_dance.up&(spell_targets.shuriken_storm=1|dot.rupture.ticking&spell_targets.shuriken_storm>=2);
	local skipRupture = buff[SB.ThistleTea].up and targets == 1 or buff[SB.ShadowDance].up and ( targets == 1 or debuff[SB.Rupture].up and targets >= 2 );

	-- rupture,if=(!variable.skip_rupture|variable.priority_rotation)&target.time_to_die-remains>6&refreshable;
	if energy >= 22 and comboPoints >= 6 and (( not skipRupture or priorityRotation ) and timeToDie - debuff[SB.Rupture].remains > 6 and debuff[SB.Rupture].refreshable) then
		return SB.Rupture;
	end

	-- rupture,if=!variable.skip_rupture&buff.finality_rupture.up&cooldown.shadow_dance.remains<12&cooldown.shadow_dance.charges_fractional<=1&spell_targets.shuriken_storm=1&(talent.dark_brew|talent.danse_macabre);
	if energy >= 22 and comboPoints >= 6 and (not skipRupture and buff[SB.FinalityRupture].up and cooldown[SB.ShadowDance].remains < 12 and cooldown[SB.ShadowDance].charges <= 1 and targets == 1 and ( talents[SB.DarkBrew] or talents[SB.DanseMacabre] )) then
		return SB.Rupture;
	end

	-- cold_blood,if=variable.secret_condition&cooldown.secret_technique.ready;
	if talents[SB.ColdBlood] and cooldown[SB.ColdBlood].ready and (secretCondition and cooldown[SB.SecretTechnique].ready) then
		return SB.ColdBlood;
	end

	-- secret_technique,if=variable.secret_condition&(!talent.cold_blood|cooldown.cold_blood.remains>buff.shadow_dance.remains-2);
	if talents[SB.SecretTechnique] and cooldown[SB.SecretTechnique].ready and energy >= 27 and comboPoints >= 6 and (secretCondition and ( not talents[SB.ColdBlood] or cooldown[SB.ColdBlood].remains > buff[SB.ShadowDance].remains - 2 )) then
		return SB.SecretTechnique;
	end

	-- rupture,cycle_targets=1,if=!variable.skip_rupture&!variable.priority_rotation&spell_targets.shuriken_storm>=2&target.time_to_die>=(2*combo_points)&refreshable;
	if energy >= 22 and comboPoints >= 6 and (not skipRupture and not priorityRotation and targets >= 2 and timeToDie >= ( 2 * comboPoints ) and debuff[SB.Rupture].refreshable) then
		return SB.Rupture;
	end

	-- rupture,if=!variable.skip_rupture&remains<cooldown.symbols_of_death.remains+10&cooldown.symbols_of_death.remains<=5&target.time_to_die-remains>cooldown.symbols_of_death.remains+5;
	if energy >= 22 and comboPoints >= 6 and (not skipRupture and debuff[SB.Rupture].remains < cooldown[SB.SymbolsOfDeath].remains + 10 and cooldown[SB.SymbolsOfDeath].remains <= 5 and timeToDie - debuff[SB.Rupture].remains > cooldown[SB.SymbolsOfDeath].remains + 5) then
		return SB.Rupture;
	end

	-- black_powder,if=!variable.priority_rotation&spell_targets>=3|!used_for_danse&buff.shadow_dance.up&spell_targets.shuriken_storm=2&talent.danse_macabre;
	if talents[SB.BlackPowder] and energy >= 32 and comboPoints >= 6 and (not priorityRotation and targets >= 3 or not buff[SB.ShadowDance].up and targets == 2 and talents[SB.DanseMacabre]) then
		return SB.BlackPowder;
	end

	-- eviscerate;
	if energy >= 32 and comboPoints >= 6 then
		return SB.Eviscerate;
	end
end

function Rogue:SubtletyStealthCds()
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

	-- variable,name=shd_threshold,value=cooldown.shadow_dance.charges_fractional>=0.75+talent.shadow_dance;
	local shdThreshold = cooldown[SB.ShadowDance].charges >= 0.75 + talents[SB.ShadowDance];

	-- variable,name=rotten_threshold,value=!buff.the_rotten.up|spell_targets.shuriken_storm>1|combo_points<=2&buff.the_rotten.up&!set_bonus.tier30_2pc;
	local rottenThreshold = not buff[SB.TheRotten].up or targets > 1 or comboPoints <= 2 and buff[SB.TheRotten].up and not MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2);

	-- vanish,if=(!talent.danse_macabre|spell_targets.shuriken_storm>=3)&!variable.shd_threshold&combo_points.deficit>1&(cooldown.flagellation.remains>=60|!talent.flagellation|fight_remains<=(30*cooldown.vanish.charges));
	if cooldown[SB.Vanish].ready and (( not talents[SB.DanseMacabre] or targets >= 3 ) and not shdThreshold and comboPointsDeficit > 1 and ( cooldown[SB.Flagellation].remains >= 60 or not talents[SB.Flagellation] or timeToDie <= ( 30 * cooldown[SB.Vanish].charges ) )) then
		return SB.Vanish;
	end

	-- variable,name=shd_combo_points,value=combo_points<=1;
	local shdComboPoints = comboPoints <= 1;

	-- variable,name=shd_combo_points,value=combo_points.deficit<=1,if=spell_targets.shuriken_storm>(4-2*talent.shuriken_tornado.enabled)|variable.priority_rotation&spell_targets.shuriken_storm>=4;
	if targets > ( 4 - 2 * (talents[SB.ShurikenTornado] and 1 or 0) ) or priorityRotation and targets >= 4 then
		local shdComboPoints = WTFFFFFF;
	end

	-- variable,name=shd_combo_points,value=1,if=spell_targets.shuriken_storm=(4-talent.seal_fate);
	if targets == ( 4 - (talents[SB.SealFate] and 1 or 0) ) then
		local shdComboPoints = WTFFFFFF;
	end

	-- shadow_dance,if=(variable.shd_combo_points&(!talent.shadow_dance&buff.symbols_of_death.remains>=(2.2-talent.flagellation.enabled)|variable.shd_threshold)|talent.shadow_dance&cooldown.secret_technique.remains<=9&(spell_targets.shuriken_storm<=3|talent.danse_macabre)|buff.flagellation.up|buff.flagellation_persist.remains>=6|spell_targets.shuriken_storm>=4&cooldown.symbols_of_death.remains>10)&variable.rotten_threshold;
	if talents[SB.ShadowDance] and cooldown[SB.ShadowDance].ready and (( shdComboPoints and ( not talents[SB.ShadowDance] and buff[SB.SymbolsOfDeath].remains >= ( 2.2 - (talents[SB.Flagellation] and 1 or 0) ) or shdThreshold ) or talents[SB.ShadowDance] and cooldown[SB.SecretTechnique].remains <= 9 and ( targets <= 3 or talents[SB.DanseMacabre] ) or buff[SB.Flagellation].up or buff[SB.FlagellationPersist].remains >= 6 or targets >= 4 and cooldown[SB.SymbolsOfDeath].remains > 10 ) and rottenThreshold) then
		return SB.ShadowDance;
	end

	-- shadow_dance,if=variable.shd_combo_points&fight_remains<cooldown.symbols_of_death.remains|!talent.shadow_dance&dot.rupture.ticking&spell_targets.shuriken_storm<=4&variable.rotten_threshold;
	if talents[SB.ShadowDance] and cooldown[SB.ShadowDance].ready and (shdComboPoints and timeToDie < cooldown[SB.SymbolsOfDeath].remains or not talents[SB.ShadowDance] and debuff[SB.Rupture].up and targets <= 4 and rottenThreshold) then
		return SB.ShadowDance;
	end
end

function Rogue:SubtletyStealthed()
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

	-- shadowstrike,if=(buff.stealth.up|buff.vanish.up)&(spell_targets.shuriken_storm<4|variable.priority_rotation);
	if energy >= 40 and (( buff[SB.Stealth].up or buff[SB.Vanish].up ) and ( targets < 4 or priorityRotation )) then
		return SB.Shadowstrike;
	end

	-- variable,name=gloomblade_condition,value=buff.danse_macabre.stack<5&(combo_points.deficit=2|combo_points.deficit=3)&(buff.premeditation.up|effective_combo_points<7)&(spell_targets.shuriken_storm<=8|talent.lingering_shadow);
	local gloombladeCondition = buff[SB.DanseMacabre].count < 5 and ( comboPointsDeficit == 2 or comboPointsDeficit == 3 ) and ( buff[SB.Premeditation].up or comboPoints < 7 ) and ( targets <= 8 or talents[SB.LingeringShadow] );

	-- shuriken_storm,if=variable.gloomblade_condition&buff.silent_storm.up&!debuff.find_weakness.remains&talent.improved_shuriken_storm.enabled|combo_points<=1&!used_for_danse&spell_targets.shuriken_storm=2&talent.danse_macabre;
	if energy >= 35 and (gloombladeCondition and buff[SB.SilentStorm].up and not debuff[SB.FindWeakness].remains and talents[SB.ImprovedShurikenStorm] or comboPoints <= 1 and not targets == 2 and talents[SB.DanseMacabre]) then
		return SB.ShurikenStorm;
	end

	-- gloomblade,if=variable.gloomblade_condition&(!used_for_danse|spell_targets.shuriken_storm!=2)|combo_points<=2&buff.the_rotten.up&spell_targets.shuriken_storm<=3;
	if talents[SB.Gloomblade] and energy >= 35 and (gloombladeCondition and ( not targets ) or comboPoints <= 2 and buff[SB.TheRotten].up and targets <= 3) then
		return SB.Gloomblade;
	end

	-- backstab,if=variable.gloomblade_condition&talent.danse_macabre&buff.danse_macabre.stack<=2&spell_targets.shuriken_storm<=2;
	if energy >= 35 and (gloombladeCondition and talents[SB.DanseMacabre] and buff[SB.DanseMacabre].count <= 2 and targets <= 2) then
		return SB.Backstab;
	end

	-- call_action_list,name=finish,if=variable.effective_combo_points>=cp_max_spend;
	if effectiveComboPoints >= cpMaxSpend then
		local result = Rogue:SubtletyFinish();
		if result then
			return result;
		end
	end

	-- call_action_list,name=finish,if=buff.shuriken_tornado.up&combo_points.deficit<=2;
	if buff[SB.ShurikenTornado].up and comboPointsDeficit <= 2 then
		local result = Rogue:SubtletyFinish();
		if result then
			return result;
		end
	end

	-- call_action_list,name=finish,if=spell_targets.shuriken_storm>=4-talent.seal_fate&variable.effective_combo_points>=4;
	if targets >= 4 - (talents[SB.SealFate] and 1 or 0) and effectiveComboPoints >= 4 then
		local result = Rogue:SubtletyFinish();
		if result then
			return result;
		end
	end

	-- call_action_list,name=finish,if=combo_points.deficit<=1+(talent.seal_fate|talent.deeper_stratagem|talent.secret_stratagem);
	if comboPointsDeficit <= 1 + ( talents[SB.SealFate] or talents[SB.DeeperStratagem] or talents[SB.SecretStratagem] ) then
		local result = Rogue:SubtletyFinish();
		if result then
			return result;
		end
	end

	-- gloomblade,if=buff.perforated_veins.stack>=5&spell_targets.shuriken_storm<3;
	if talents[SB.Gloomblade] and energy >= 35 and (buff[SB.PerforatedVeins].count >= 5 and targets < 3) then
		return SB.Gloomblade;
	end

	-- backstab,if=buff.perforated_veins.stack>=5&spell_targets.shuriken_storm<3;
	if energy >= 35 and (buff[SB.PerforatedVeins].count >= 5 and targets < 3) then
		return SB.Backstab;
	end

	-- shadowstrike,if=stealthed.sepsis&spell_targets.shuriken_storm<4;
	if energy >= 40 and (stealthedSepsis and targets < 4) then
		return SB.Shadowstrike;
	end

	-- shuriken_storm,if=spell_targets>=3+buff.the_rotten.up&(!buff.premeditation.up|spell_targets>=7&!variable.priority_rotation);
	if energy >= 35 and (targets >= 3 + buff[SB.TheRotten].up and ( not buff[SB.Premeditation].up or targets >= 7 and not priorityRotation )) then
		return SB.ShurikenStorm;
	end

	-- shadowstrike,if=debuff.find_weakness.remains<=1|cooldown.symbols_of_death.remains<18&debuff.find_weakness.remains<cooldown.symbols_of_death.remains;
	if energy >= 40 and (debuff[SB.FindWeakness].remains <= 1 or cooldown[SB.SymbolsOfDeath].remains < 18 and debuff[SB.FindWeakness].remains < cooldown[SB.SymbolsOfDeath].remains) then
		return SB.Shadowstrike;
	end

	-- shadowstrike;
	if energy >= 40 then
		return SB.Shadowstrike;
	end
end


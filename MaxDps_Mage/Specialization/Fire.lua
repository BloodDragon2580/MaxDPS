local _, addonTable = ...;

-- @type MaxDps;
if not MaxDps then return end;
local Mage = addonTable.Mage;
local MaxDps = MaxDps;

local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;

local itemID = GetInventoryItemID('player', INVSLOT_MAINHAND);

local mainHandSubClassID = itemID and  select(13, GetItemInfo(itemID));

local TwoHanderWepCheck = mainHandSubClassID and (mainHandSubClassID == 1 or mainHandSubClassID == 5 or mainHandSubClassID == 8 or mainHandSubClassID == 10);

local FR = {
	ArcaneIntellect = 1459,
	SunKingsBlessing = 383886,
	FlamePatch = 205037,
	MirrorImage = 55342,
	Flamestrike = 2120,
	Pyroblast = 11366,
	Counterspell = 2139,
	TimeWarp = 80353,
	TemporalWarp = 386539,
	ShiftingPower = 382440,
	Combustion = 190319,
	FireBlast = 108853,
	HotStreak = 195283,
	PhoenixFlames = 257541,
	AlexstraszasFury = 235870,
	HeatingUp = 48107,
	IceNova = 157997,
	Scorch = 2948,
	LivingBomb = 44457,
	Meteor = 153561,
	DragonsBreath = 31661,
	FeelTheBurn = 383391,
	TemperedFlames = 383659,
	Tier302pc = 393655,
	CharringEmbers = 408665,
	Fireball = 133,
	ImprovedScorch = 383604,
	Hyperthermia = 383860,
	FlamesFury = 409964,
	FlameAccelerant = 203275,
	Firestarter = 205026,
	Kindling = 155148,
	ArcaneExplosion = 1449,
};
local A = {
};
function Mage:Fire()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
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

	-- call_action_list,name=combustion_timing,if=!variable.disable_combustion;
	if not disableCombustion then
		local result = Mage:FireCombustionTiming();
		if result then
			return result;
		end
	end

	-- time_warp,if=talent.temporal_warp&(buff.exhaustion.up|interpolated_fight_remains<buff.bloodlust.duration);
	if cooldown[FR.TimeWarp].ready and mana >= 2000 and (talents[FR.TemporalWarp] and ( buff[FR.Exhaustion].up or buff[FR.Bloodlust].duration )) then
		return FR.TimeWarp;
	end

	-- variable,name=shifting_power_before_combustion,value=variable.time_to_combustion>cooldown.shifting_power.remains;
	local shiftingPowerBeforeCombustion = timeToCombustion > cooldown[FR.ShiftingPower].remains;

	-- variable,name=item_cutoff_active,value=(variable.time_to_combustion<variable.on_use_cutoff|buff.combustion.remains>variable.skb_duration&!cooldown.item_cd_1141.remains)&((trinket.1.has_cooldown&trinket.1.cooldown.remains<variable.on_use_cutoff)+(trinket.2.has_cooldown&trinket.2.cooldown.remains<variable.on_use_cutoff)>1);
	local itemCutoffActive = ( timeToCombustion < onUseCutoff or buff[FR.Combustion].remains > skbDuration and not cooldown[FR.ItemCd1141].remains ) and ( ( onUseCutoff ) + ( onUseCutoff ) > 1 );

	-- variable,use_off_gcd=1,use_while_casting=1,name=fire_blast_pooling,value=buff.combustion.down&action.fire_blast.charges_fractional+(variable.time_to_combustion+action.shifting_power.full_reduction*variable.shifting_power_before_combustion)%cooldown.fire_blast.duration-1<cooldown.fire_blast.max_charges+variable.overpool_fire_blasts%cooldown.fire_blast.duration-(buff.combustion.duration%cooldown.fire_blast.duration)%%1&variable.time_to_combustion<fight_remains;
	local fireBlastPooling = not buff[FR.Combustion].up and ( timeToCombustion * shiftingPowerBeforeCombustion ) / cooldown[FR.FireBlast].duration - 1 < cooldown[FR.FireBlast].maxCharges + overpoolFireBlasts / cooldown[FR.FireBlast].duration - ( buff[FR.Combustion].duration / cooldown[FR.FireBlast].duration ) / 1 and timeToCombustion < timeToDie;

	-- call_action_list,name=combustion_phase,if=variable.time_to_combustion<=0|buff.combustion.up|variable.time_to_combustion<variable.combustion_precast_time&cooldown.combustion.remains<variable.combustion_precast_time;
	if timeToCombustion <= 0 or buff[FR.Combustion].up or timeToCombustion < combustionPrecastTime and cooldown[FR.Combustion].remains < combustionPrecastTime then
		local result = Mage:FireCombustionPhase();
		if result then
			return result;
		end
	end

	-- variable,use_off_gcd=1,use_while_casting=1,name=fire_blast_pooling,value=searing_touch.active&action.fire_blast.full_recharge_time>3*gcd.max,if=!variable.fire_blast_pooling&talent.sun_kings_blessing;
	if not fireBlastPooling and talents[FR.SunKingsBlessing] then
		local fireBlastPooling = WTFFFFFF;
	end

	-- shifting_power,if=buff.combustion.down&(action.fire_blast.charges=0|variable.fire_blast_pooling)&!buff.hot_streak.react&variable.shifting_power_before_combustion;
	if talents[FR.ShiftingPower] and cooldown[FR.ShiftingPower].ready and mana >= 2500 and (not buff[FR.Combustion].up and ( cooldown[FR.FireBlast].charges == 0 or fireBlastPooling ) and not buff[FR.HotStreak].count and shiftingPowerBeforeCombustion) then
		return FR.ShiftingPower;
	end

	-- variable,name=phoenix_pooling,if=active_enemies<variable.combustion_flamestrike,value=(variable.time_to_combustion+buff.combustion.duration-5<action.phoenix_flames.full_recharge_time+cooldown.phoenix_flames.duration-action.shifting_power.full_reduction*variable.shifting_power_before_combustion&variable.time_to_combustion<fight_remains|talent.sun_kings_blessing)&!talent.alexstraszas_fury;
	if targets < combustionFlamestrike then
		local phoenixPooling = WTFFFFFF;
	end

	-- variable,name=phoenix_pooling,if=active_enemies>=variable.combustion_flamestrike,value=(variable.time_to_combustion<action.phoenix_flames.full_recharge_time-action.shifting_power.full_reduction*variable.shifting_power_before_combustion&variable.time_to_combustion<fight_remains|talent.sun_kings_blessing)&!talent.alexstraszas_fury;
	if targets >= combustionFlamestrike then
		local phoenixPooling = WTFFFFFF;
	end

	-- fire_blast,use_off_gcd=1,use_while_casting=1,if=!variable.fire_blast_pooling&variable.time_to_combustion>0&active_enemies>=variable.hard_cast_flamestrike&!firestarter.active&!buff.hot_streak.react&(buff.heating_up.react&action.flamestrike.execute_remains<0.5|charges_fractional>=2);
	if talents[FR.FireBlast] and cooldown[FR.FireBlast].ready and mana >= 500 and (not fireBlastPooling and timeToCombustion > 0 and targets >= hardCastFlamestrike and not firestarterActive and not buff[FR.HotStreak].count and ( buff[FR.HeatingUp].count and cooldown[FR.Flamestrike].execute_remains < 0.5 or cooldown[FR.FireBlast].charges >= 2 )) then
		return FR.FireBlast;
	end

	-- call_action_list,name=firestarter_fire_blasts,if=buff.combustion.down&firestarter.active&variable.time_to_combustion>0;
	if not buff[FR.Combustion].up and firestarterActive and timeToCombustion > 0 then
		local result = Mage:FireFirestarterFireBlasts();
		if result then
			return result;
		end
	end

	-- fire_blast,use_while_casting=1,if=action.shifting_power.executing&full_recharge_time<action.shifting_power.tick_reduction;
	if talents[FR.FireBlast] and cooldown[FR.FireBlast].ready and mana >= 500 and (cooldown[FR.ShiftingPower].executing and cooldown[FR.FireBlast].fullRecharge ) then
		return FR.FireBlast;
	end

	-- call_action_list,name=standard_rotation,if=variable.time_to_combustion>0&buff.combustion.down;
	if timeToCombustion > 0 and not buff[FR.Combustion].up then
		local result = Mage:FireStandardRotation();
		if result then
			return result;
		end
	end

	-- ice_nova,if=!searing_touch.active;
	if talents[FR.IceNova] and cooldown[FR.IceNova].ready then
		return FR.IceNova;
	end

	-- scorch;
	if talents[FR.Scorch] and mana >= 500 and currentSpell ~= FR.Scorch then
		return FR.Scorch;
	end
end
function Mage:FireActiveTalents()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local timeToDie = fd.timeToDie;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- living_bomb,if=active_enemies>1&buff.combustion.down&(variable.time_to_combustion>cooldown.living_bomb.duration|variable.time_to_combustion<=0);
	if talents[FR.LivingBomb] and cooldown[FR.LivingBomb].ready and mana >= 750 and (targets > 1 and not buff[FR.Combustion].up and ( timeToCombustion > cooldown[FR.LivingBomb].duration or timeToCombustion <= 0 )) then
		return FR.LivingBomb;
	end

	-- meteor,if=variable.time_to_combustion<=0|buff.combustion.remains>travel_time|!talent.sun_kings_blessing&(cooldown.meteor.duration<variable.time_to_combustion|fight_remains<variable.time_to_combustion);
	if talents[FR.Meteor] and cooldown[FR.Meteor].ready and mana >= 500 and (timeToCombustion <= 0 or buff[FR.Combustion].remains or not talents[FR.SunKingsBlessing] and ( cooldown[FR.Meteor].duration < timeToCombustion or timeToDie < timeToCombustion )) then
		return FR.Meteor;
	end

	-- dragons_breath,if=talent.alexstraszas_fury&(buff.combustion.down&!buff.hot_streak.react)&(buff.feel_the_burn.up|time>15)&!firestarter.remains&!talent.tempered_flames;
	if talents[FR.DragonsBreath] and cooldown[FR.DragonsBreath].ready and mana >= 2000 and (talents[FR.AlexstraszasFury] and ( not buff[FR.Combustion].up and not buff[FR.HotStreak].count ) and ( buff[FR.FeelTheBurn].up or GetTime() > 15 ) and not firestarterRemains and not talents[FR.TemperedFlames]) then
		return FR.DragonsBreath;
	end

	-- dragons_breath,if=talent.alexstraszas_fury&(buff.combustion.down&!buff.hot_streak.react)&(buff.feel_the_burn.up|time>15)&talent.tempered_flames;
	if talents[FR.DragonsBreath] and cooldown[FR.DragonsBreath].ready and mana >= 2000 and (talents[FR.AlexstraszasFury] and ( not buff[FR.Combustion].up and not buff[FR.HotStreak].count ) and ( buff[FR.FeelTheBurn].up or GetTime() > 15 ) and talents[FR.TemperedFlames]) then
		return FR.DragonsBreath;
	end
end

function Mage:FireCombustionCooldowns()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- time_warp,if=talent.temporal_warp&buff.exhaustion.up;
	if cooldown[FR.TimeWarp].ready and mana >= 2000 and (talents[FR.TemporalWarp] and buff[FR.Exhaustion].up) then
		return FR.TimeWarp;
	end
end

function Mage:FireCombustionPhase()
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
	local gcdRemains = fd.gcdRemains;
	local timeToDie = fd.timeToDie;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- living_bomb,if=active_enemies>1&buff.combustion.down;
	if talents[FR.LivingBomb] and cooldown[FR.LivingBomb].ready and mana >= 750 and (targets > 1 and not buff[FR.Combustion].up) then
		return FR.LivingBomb;
	end

	-- call_action_list,name=combustion_cooldowns,if=buff.combustion.remains>variable.skb_duration|fight_remains<20;
	if buff[FR.Combustion].remains > skbDuration or timeToDie < 20 then
		local result = Mage:FireCombustionCooldowns();
		if result then
			return result;
		end
	end

	-- phoenix_flames,if=set_bonus.tier30_2pc&!action.phoenix_flames.in_flight&debuff.charring_embers.remains<2*gcd.max;
	if talents[FR.PhoenixFlames] and cooldown[FR.PhoenixFlames].ready and (MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2) and not inFlight and debuff[FR.CharringEmbers].remains < 2 * gcd) then
		return FR.PhoenixFlames;
	end

	-- call_action_list,name=active_talents;
	local result = Mage:FireActiveTalents();
	if result then
		return result;
	end

	-- flamestrike,if=buff.combustion.down&buff.fury_of_the_sun_king.up&buff.fury_of_the_sun_king.remains>cast_time&buff.fury_of_the_sun_king.expiration_delay_remains=0&cooldown.combustion.remains<cast_time&active_enemies>=variable.skb_flamestrike;
	if mana >= 1250 and currentSpell ~= FR.Flamestrike and (not buff[FR.Combustion].up and buff[FR.FuryOfTheSunKing].up and buff[FR.FuryOfTheSunKing].remains > timeShift and cooldown[FR.Combustion].remains < timeShift and targets >= skbFlamestrike) then
		return FR.Flamestrike;
	end

	-- pyroblast,if=buff.combustion.down&buff.fury_of_the_sun_king.up&buff.fury_of_the_sun_king.remains>cast_time&buff.fury_of_the_sun_king.expiration_delay_remains=0;
	if talents[FR.Pyroblast] and mana >= 1000 and currentSpell ~= FR.Pyroblast and (not buff[FR.Combustion].up and buff[FR.FuryOfTheSunKing].up and buff[FR.FuryOfTheSunKing].remains > timeShift ) then
		return FR.Pyroblast;
	end

	-- fireball,if=buff.combustion.down&cooldown.combustion.remains<cast_time&active_enemies<2;
	if mana >= 1000 and currentSpell ~= FR.Fireball and (not buff[FR.Combustion].up and cooldown[FR.Combustion].remains < timeShift and targets < 2) then
		return FR.Fireball;
	end

	-- scorch,if=buff.combustion.down&cooldown.combustion.remains<cast_time;
	if talents[FR.Scorch] and mana >= 500 and currentSpell ~= FR.Scorch and (not buff[FR.Combustion].up and cooldown[FR.Combustion].remains < timeShift) then
		return FR.Scorch;
	end

	-- combustion,use_off_gcd=1,use_while_casting=1,if=hot_streak_spells_in_flight=0&buff.combustion.down&variable.time_to_combustion<=0&(action.scorch.executing&action.scorch.execute_remains<variable.combustion_cast_remains|action.fireball.executing&action.fireball.execute_remains<variable.combustion_cast_remains|action.pyroblast.executing&action.pyroblast.execute_remains<variable.combustion_cast_remains|action.flamestrike.executing&action.flamestrike.execute_remains<variable.combustion_cast_remains|action.meteor.in_flight&action.meteor.in_flight_remains<variable.combustion_cast_remains);
	if talents[FR.Combustion] and cooldown[FR.Combustion].ready and mana >= 5000 and (not buff[FR.Combustion].up and timeToCombustion <= 0 and ( cooldown[FR.Scorch].executing and cooldown[FR.Scorch].execute_remains < combustionCastRemains or cooldown[FR.Fireball].executing and cooldown[FR.Fireball].execute_remains < combustionCastRemains or cooldown[FR.Pyroblast].executing and cooldown[FR.Pyroblast].execute_remains < combustionCastRemains or cooldown[FR.Flamestrike].executing and cooldown[FR.Flamestrike].execute_remains < combustionCastRemains or inFlight and cooldown[FR.Meteor].in_flight_remains < combustionCastRemains )) then
		return FR.Combustion;
	end

	-- fire_blast,use_off_gcd=1,use_while_casting=1,if=!variable.fire_blast_pooling&(!improved_scorch.active|action.scorch.executing|debuff.improved_scorch.remains>3)&(buff.fury_of_the_sun_king.down|action.pyroblast.executing)&buff.combustion.up&!buff.hyperthermia.react&!buff.hot_streak.react&hot_streak_spells_in_flight+buff.heating_up.react*(gcd.remains>0)<2;
	if talents[FR.FireBlast] and cooldown[FR.FireBlast].ready and mana >= 500 and (not fireBlastPooling and ( not debuff[FR.ImprovedScorch].up or cooldown[FR.Scorch].executing or debuff[FR.ImprovedScorch].remains > 3 ) and ( not buff[FR.FuryOfTheSunKing].up or cooldown[FR.Pyroblast].executing ) and buff[FR.Combustion].up and not buff[FR.Hyperthermia].count and not buff[FR.HotStreak].count and buff[FR.HeatingUp].count * ( gcdRemains > 0 ) < 2) then
		return FR.FireBlast;
	end

	-- flamestrike,if=(buff.hot_streak.react&active_enemies>=variable.combustion_flamestrike)|(buff.hyperthermia.react&active_enemies>=variable.combustion_flamestrike-talent.hyperthermia);
	if mana >= 1250 and currentSpell ~= FR.Flamestrike and (( buff[FR.HotStreak].count and targets >= combustionFlamestrike ) or ( buff[FR.Hyperthermia].count and targets >= combustionFlamestrike - (talents[FR.Hyperthermia] and 1 or 0) )) then
		return FR.Flamestrike;
	end

	-- pyroblast,if=buff.hyperthermia.react;
	if talents[FR.Pyroblast] and mana >= 1000 and currentSpell ~= FR.Pyroblast and (buff[FR.Hyperthermia].count) then
		return FR.Pyroblast;
	end

	-- pyroblast,if=buff.hot_streak.react&buff.combustion.up;
	if talents[FR.Pyroblast] and mana >= 1000 and currentSpell ~= FR.Pyroblast and (buff[FR.HotStreak].count and buff[FR.Combustion].up) then
		return FR.Pyroblast;
	end

	-- pyroblast,if=prev_gcd.1.scorch&buff.heating_up.react&active_enemies<variable.combustion_flamestrike&buff.combustion.up;
	if talents[FR.Pyroblast] and mana >= 1000 and currentSpell ~= FR.Pyroblast and (spellHistory[1] == FR.Scorch and buff[FR.HeatingUp].count and targets < combustionFlamestrike and buff[FR.Combustion].up) then
		return FR.Pyroblast;
	end

	-- shifting_power,if=buff.combustion.up&!action.fire_blast.charges&(action.phoenix_flames.charges<action.phoenix_flames.max_charges|talent.alexstraszas_fury)&variable.combustion_shifting_power;
	if talents[FR.ShiftingPower] and cooldown[FR.ShiftingPower].ready and mana >= 2500 and (buff[FR.Combustion].up and not cooldown[FR.FireBlast].charges and ( cooldown[FR.PhoenixFlames].charges < cooldown[FR.PhoenixFlames].maxCharges or talents[FR.AlexstraszasFury] ) and combustionShiftingPower) then
		return FR.ShiftingPower;
	end

	-- flamestrike,if=buff.fury_of_the_sun_king.up&buff.fury_of_the_sun_king.remains>cast_time&active_enemies>=variable.skb_flamestrike&buff.fury_of_the_sun_king.expiration_delay_remains=0;
	if mana >= 1250 and currentSpell ~= FR.Flamestrike and (buff[FR.FuryOfTheSunKing].up and buff[FR.FuryOfTheSunKing].remains > timeShift and targets >= skbFlamestrike ) then
		return FR.Flamestrike;
	end

	-- pyroblast,if=buff.fury_of_the_sun_king.up&buff.fury_of_the_sun_king.remains>cast_time&buff.fury_of_the_sun_king.expiration_delay_remains=0;
	if talents[FR.Pyroblast] and mana >= 1000 and currentSpell ~= FR.Pyroblast and (buff[FR.FuryOfTheSunKing].up and buff[FR.FuryOfTheSunKing].remains > timeShift ) then
		return FR.Pyroblast;
	end

	-- scorch,if=improved_scorch.active&debuff.improved_scorch.remains<3;
	if talents[FR.Scorch] and mana >= 500 and currentSpell ~= FR.Scorch and (debuff[FR.ImprovedScorch].up and debuff[FR.ImprovedScorch].remains < 3) then
		return FR.Scorch;
	end

	-- phoenix_flames,if=set_bonus.tier30_2pc&travel_time<buff.combustion.remains&buff.heating_up.react+hot_streak_spells_in_flight<2&(debuff.charring_embers.remains<2*gcd.max|buff.flames_fury.up);
	if talents[FR.PhoenixFlames] and cooldown[FR.PhoenixFlames].ready and (MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2) and buff[FR.Combustion].remains and ( debuff[FR.CharringEmbers].remains < 2 * gcd or buff[FR.FlamesFury].up )) then
		return FR.PhoenixFlames;
	end

	-- fireball,if=buff.combustion.remains>cast_time&buff.flame_accelerant.react;
	if mana >= 1000 and currentSpell ~= FR.Fireball and (buff[FR.Combustion].remains > timeShift and buff[FR.FlameAccelerant].count) then
		return FR.Fireball;
	end

	-- phoenix_flames,if=!set_bonus.tier30_2pc&!talent.alexstraszas_fury&travel_time<buff.combustion.remains&buff.heating_up.react+hot_streak_spells_in_flight<2;
	if talents[FR.PhoenixFlames] and cooldown[FR.PhoenixFlames].ready and (not MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2) and not talents[FR.AlexstraszasFury] and buff[FR.Combustion].remains and buff[FR.HeatingUp].count > 2) then
		return FR.PhoenixFlames;
	end

	-- scorch,if=buff.combustion.remains>cast_time&cast_time>=gcd.max;
	if talents[FR.Scorch] and mana >= 500 and currentSpell ~= FR.Scorch and (buff[FR.Combustion].remains > timeShift and timeShift >= gcd) then
		return FR.Scorch;
	end

	-- fireball,if=buff.combustion.remains>cast_time;
	if mana >= 1000 and currentSpell ~= FR.Fireball and (buff[FR.Combustion].remains > timeShift) then
		return FR.Fireball;
	end

	-- living_bomb,if=buff.combustion.remains<gcd.max&active_enemies>1;
	if talents[FR.LivingBomb] and cooldown[FR.LivingBomb].ready and mana >= 750 and (buff[FR.Combustion].remains < gcd and targets > 1) then
		return FR.LivingBomb;
	end

	-- ice_nova,if=buff.combustion.remains<gcd.max;
	if talents[FR.IceNova] and cooldown[FR.IceNova].ready and (buff[FR.Combustion].remains < gcd) then
		return FR.IceNova;
	end
end

function Mage:FireCombustionTiming()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local timeShift = fd.timeShift;
	local targets = fd.targets and fd.targets or 1;
	local gcd = fd.gcd;
	local timeToDie = fd.timeToDie;

	-- variable,use_off_gcd=1,use_while_casting=1,name=combustion_ready_time,value=cooldown.combustion.remains*expected_kindling_reduction;
	local combustionReadyTime = cooldown[FR.Combustion].remains;

	-- variable,use_off_gcd=1,use_while_casting=1,name=combustion_precast_time,value=action.fireball.cast_time*(active_enemies<variable.combustion_flamestrike)+action.flamestrike.cast_time*(active_enemies>=variable.combustion_flamestrike)-variable.combustion_cast_remains;
	local combustionPrecastTime = timeShift * ( targets < combustionFlamestrike ) + timeShift * ( targets >= combustionFlamestrike ) - combustionCastRemains;

	-- variable,use_off_gcd=1,use_while_casting=1,name=time_to_combustion,value=variable.combustion_ready_time;
	local timeToCombustion = combustionReadyTime;

	-- variable,use_off_gcd=1,use_while_casting=1,name=time_to_combustion,op=max,value=firestarter.remains,if=talent.firestarter&!variable.firestarter_combustion;
	if talents[FR.Firestarter] and not firestarterCombustion then
		local timeToCombustion = firestarterRemains;
	end

	-- variable,use_off_gcd=1,use_while_casting=1,name=time_to_combustion,op=max,value=(buff.sun_kings_blessing.max_stack-buff.sun_kings_blessing.stack)*(3*gcd.max),if=talent.sun_kings_blessing&firestarter.active&buff.fury_of_the_sun_king.down;
	if talents[FR.SunKingsBlessing] and firestarterActive and not buff[FR.FuryOfTheSunKing].up then
		local timeToCombustion = ( buff[FR.SunKingsBlessing].maxStacks - buff[FR.SunKingsBlessing].count ) * ( 3 * gcd );
	end

	-- variable,use_off_gcd=1,use_while_casting=1,name=time_to_combustion,op=max,value=cooldown.gladiators_badge_345228.remains,if=equipped.gladiators_badge&cooldown.gladiators_badge_345228.remains-20<variable.time_to_combustion;
	if IsEquippedItem(GladiatorsBadge) and cooldown[FR.GladiatorsBadge345228].remains - 20 < timeToCombustion then
		local timeToCombustion = cooldown[FR.GladiatorsBadge345228].remains;
	end

	-- variable,use_off_gcd=1,use_while_casting=1,name=time_to_combustion,op=max,value=buff.combustion.remains;
	local timeToCombustion = buff[FR.Combustion].remains;

	-- variable,use_off_gcd=1,use_while_casting=1,name=time_to_combustion,op=max,value=raid_event.adds.in,if=raid_event.adds.exists&raid_event.adds.count>=3&raid_event.adds.duration>15;
	if targets > 1 and raid_event.adds.count >= 3 and raid_event.adds.duration > 15 then
		local timeToCombustion
	end

	-- variable,use_off_gcd=1,use_while_casting=1,name=time_to_combustion,value=raid_event.vulnerable.in*!raid_event.vulnerable.up,if=raid_event.vulnerable.exists&variable.combustion_ready_time<raid_event.vulnerable.in;
	if combustionReadyTime then
		local timeToCombustion = WTFFFFFF;
	end

	-- variable,use_off_gcd=1,use_while_casting=1,name=time_to_combustion,value=variable.combustion_ready_time,if=variable.combustion_ready_time+cooldown.combustion.duration*(1-(0.4+0.2*talent.firestarter)*talent.kindling)<=variable.time_to_combustion|variable.time_to_combustion>fight_remains-20;
	if combustionReadyTime + cooldown[FR.Combustion].duration * ( 1 - ( 0.4 + 0.2 * (talents[FR.Firestarter] and 1 or 0) ) * (talents[FR.Kindling] and 1 or 0) ) <= timeToCombustion or timeToCombustion > timeToDie - 20 then
		local timeToCombustion = WTFFFFFF;
	end
end

function Mage:FireFirestarterFireBlasts()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local gcd = fd.gcd;
	local gcdRemains = fd.gcdRemains;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- fire_blast,use_while_casting=1,if=!variable.fire_blast_pooling&!buff.hot_streak.react&(action.fireball.execute_remains>gcd.remains|action.pyroblast.executing)&buff.heating_up.react+hot_streak_spells_in_flight=1&(cooldown.shifting_power.ready|charges>1|buff.feel_the_burn.remains<2*gcd.max);
	if talents[FR.FireBlast] and cooldown[FR.FireBlast].ready and mana >= 500 and (not fireBlastPooling and not buff[FR.HotStreak].count and ( cooldown[FR.Fireball].execute_remains > gcdRemains or cooldown[FR.Pyroblast].executing ) and buff[FR.HeatingUp].count == 1 and ( cooldown[FR.ShiftingPower].ready or cooldown[FR.FireBlast].charges > 1 or buff[FR.FeelTheBurn].remains < 2 * gcd )) then
		return FR.FireBlast;
	end

	-- fire_blast,use_off_gcd=1,if=!variable.fire_blast_pooling&buff.heating_up.react+hot_streak_spells_in_flight=1&(talent.feel_the_burn&buff.feel_the_burn.remains<gcd.remains|cooldown.shifting_power.ready&(!set_bonus.tier30_2pc|debuff.charring_embers.remains>2*gcd.max));
	if talents[FR.FireBlast] and cooldown[FR.FireBlast].ready and mana >= 500 and (not fireBlastPooling and buff[FR.HeatingUp].count == 1 and ( talents[FR.FeelTheBurn] and buff[FR.FeelTheBurn].remains < gcdRemains or cooldown[FR.ShiftingPower].ready and ( not MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2) or debuff[FR.CharringEmbers].remains > 2 * gcd ) )) then
		return FR.FireBlast;
	end
end

function Mage:FireStandardRotation()
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
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- flamestrike,if=active_enemies>=variable.hot_streak_flamestrike&(buff.hot_streak.react|buff.hyperthermia.react);
	if mana >= 1250 and currentSpell ~= FR.Flamestrike and (targets >= hotStreakFlamestrike and ( buff[FR.HotStreak].count or buff[FR.Hyperthermia].count )) then
		return FR.Flamestrike;
	end

	-- pyroblast,if=buff.hyperthermia.react;
	if talents[FR.Pyroblast] and mana >= 1000 and currentSpell ~= FR.Pyroblast and (buff[FR.Hyperthermia].count) then
		return FR.Pyroblast;
	end

	-- pyroblast,if=buff.hot_streak.react&(buff.hot_streak.remains<action.fireball.execute_time);
	if talents[FR.Pyroblast] and mana >= 1000 and currentSpell ~= FR.Pyroblast and (buff[FR.HotStreak].count and ( buff[FR.HotStreak].remains < timeShift )) then
		return FR.Pyroblast;
	end

	-- pyroblast,if=buff.hot_streak.react&(hot_streak_spells_in_flight|firestarter.active|talent.alexstraszas_fury&action.phoenix_flames.charges);
	if talents[FR.Pyroblast] and mana >= 1000 and currentSpell ~= FR.Pyroblast and (buff[FR.HotStreak].count and ( firestarterActive or talents[FR.AlexstraszasFury] and cooldown[FR.PhoenixFlames].charges )) then
		return FR.Pyroblast;
	end

	-- pyroblast,if=buff.hot_streak.react&searing_touch.active;
	if talents[FR.Pyroblast] and mana >= 1000 and currentSpell ~= FR.Pyroblast and (buff[FR.HotStreak].count ) then
		return FR.Pyroblast;
	end

	-- flamestrike,if=active_enemies>=variable.skb_flamestrike&buff.fury_of_the_sun_king.up&buff.fury_of_the_sun_king.expiration_delay_remains=0;
	if mana >= 1250 and currentSpell ~= FR.Flamestrike and (targets >= skbFlamestrike and buff[FR.FuryOfTheSunKing].up ) then
		return FR.Flamestrike;
	end

	-- pyroblast,if=buff.fury_of_the_sun_king.up&buff.fury_of_the_sun_king.expiration_delay_remains=0;
	if talents[FR.Pyroblast] and mana >= 1000 and currentSpell ~= FR.Pyroblast and (buff[FR.FuryOfTheSunKing].up ) then
		return FR.Pyroblast;
	end

	-- fire_blast,use_off_gcd=1,use_while_casting=1,if=!firestarter.active&!variable.fire_blast_pooling&buff.fury_of_the_sun_king.down&(((action.fireball.executing&(action.fireball.execute_remains<0.5|!talent.hyperthermia)|action.pyroblast.executing&(action.pyroblast.execute_remains<0.5|!talent.hyperthermia))&buff.heating_up.react)|(searing_touch.active&(!improved_scorch.active|debuff.improved_scorch.stack=debuff.improved_scorch.max_stack|full_recharge_time<3)&(buff.heating_up.react&!action.scorch.executing|!buff.hot_streak.react&!buff.heating_up.react&action.scorch.executing&!hot_streak_spells_in_flight)));
	if talents[FR.FireBlast] and cooldown[FR.FireBlast].ready and mana >= 500 and (not firestarterActive and not fireBlastPooling and not buff[FR.FuryOfTheSunKing].up and ( ( ( cooldown[FR.Fireball].executing and ( cooldown[FR.Fireball].execute_remains < 0.5 or not talents[FR.Hyperthermia] ) or cooldown[FR.Pyroblast].executing and ( cooldown[FR.Pyroblast].execute_remains < 0.5 or not talents[FR.Hyperthermia] ) ) and buff[FR.HeatingUp].count ) or ( ( not debuff[FR.ImprovedScorch].up or debuff[FR.ImprovedScorch].count == debuff[FR.ImprovedScorch].maxStacks or cooldown[FR.FireBlast].fullRecharge < 3 ) and ( buff[FR.HeatingUp].count and not cooldown[FR.Scorch].executing or not buff[FR.HotStreak].count and not buff[FR.HeatingUp].count and cooldown[FR.Scorch].executing ) ) )) then
		return FR.FireBlast;
	end

	-- pyroblast,if=prev_gcd.1.scorch&buff.heating_up.react&searing_touch.active&active_enemies<variable.hot_streak_flamestrike;
	if talents[FR.Pyroblast] and mana >= 1000 and currentSpell ~= FR.Pyroblast and (spellHistory[1] == FR.Scorch and buff[FR.HeatingUp].count and targets < hotStreakFlamestrike) then
		return FR.Pyroblast;
	end

	-- phoenix_flames,if=set_bonus.tier30_2pc&debuff.charring_embers.remains<2*gcd.max;
	if talents[FR.PhoenixFlames] and cooldown[FR.PhoenixFlames].ready and (MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2) and debuff[FR.CharringEmbers].remains < 2 * gcd) then
		return FR.PhoenixFlames;
	end

	-- scorch,if=improved_scorch.active&debuff.improved_scorch.stack<debuff.improved_scorch.max_stack;
	if talents[FR.Scorch] and mana >= 500 and currentSpell ~= FR.Scorch and (debuff[FR.ImprovedScorch].up and debuff[FR.ImprovedScorch].count < debuff[FR.ImprovedScorch].maxStacks) then
		return FR.Scorch;
	end

	-- phoenix_flames,if=!talent.alexstraszas_fury&!buff.hot_streak.react&!variable.phoenix_pooling&buff.flames_fury.up;
	if talents[FR.PhoenixFlames] and cooldown[FR.PhoenixFlames].ready and (not talents[FR.AlexstraszasFury] and not buff[FR.HotStreak].count and not phoenixPooling and buff[FR.FlamesFury].up) then
		return FR.PhoenixFlames;
	end

	-- phoenix_flames,if=talent.alexstraszas_fury&!buff.hot_streak.react&hot_streak_spells_in_flight=0&(!variable.phoenix_pooling&buff.flames_fury.up|charges_fractional>2.5|charges_fractional>1.5&buff.feel_the_burn.remains<2*gcd.max);
	if talents[FR.PhoenixFlames] and cooldown[FR.PhoenixFlames].ready and (talents[FR.AlexstraszasFury] and not buff[FR.HotStreak].count and ( not phoenixPooling and buff[FR.FlamesFury].up or cooldown[FR.PhoenixFlames].charges > 2.5 or cooldown[FR.PhoenixFlames].charges > 1.5 and buff[FR.FeelTheBurn].remains < 2 * gcd )) then
		return FR.PhoenixFlames;
	end

	-- call_action_list,name=active_talents;
	local result = Mage:FireActiveTalents();
	if result then
		return result;
	end

	-- dragons_breath,if=active_enemies>1;
	if talents[FR.DragonsBreath] and cooldown[FR.DragonsBreath].ready and mana >= 2000 and (targets > 1) then
		return FR.DragonsBreath;
	end

	-- scorch,if=searing_touch.active;
	if talents[FR.Scorch] and mana >= 500 and currentSpell ~= FR.Scorch then
		return FR.Scorch;
	end

	-- arcane_explosion,if=active_enemies>=variable.arcane_explosion&mana.pct>=variable.arcane_explosion_mana;
	if mana >= 5000 and (targets >= arcaneExplosion and manaPct >= arcaneExplosionMana) then
		return FR.ArcaneExplosion;
	end

	-- flamestrike,if=active_enemies>=variable.hard_cast_flamestrike;
	if mana >= 1250 and currentSpell ~= FR.Flamestrike and (targets >= hardCastFlamestrike) then
		return FR.Flamestrike;
	end

	-- pyroblast,if=talent.tempered_flames&!buff.flame_accelerant.react;
	if talents[FR.Pyroblast] and mana >= 1000 and currentSpell ~= FR.Pyroblast and (talents[FR.TemperedFlames] and not buff[FR.FlameAccelerant].count) then
		return FR.Pyroblast;
	end

	-- fireball;
	if mana >= 1000 and currentSpell ~= FR.Fireball then
		return FR.Fireball;
	end
end


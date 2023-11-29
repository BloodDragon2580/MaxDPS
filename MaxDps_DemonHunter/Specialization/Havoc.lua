local _, addonTable = ...;

-- @type MaxDps;
if not MaxDps then return end;
local Demonhunter = addonTable.Demonhunter;
local MaxDps = MaxDps;

local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;

local itemID = GetInventoryItemID('player', INVSLOT_MAINHAND);

local mainHandSubClassID = itemID and  select(13, GetItemInfo(itemID));

local TwoHanderWepCheck = mainHandSubClassID and (mainHandSubClassID == 1 or mainHandSubClassID == 5 or mainHandSubClassID == 8 or mainHandSubClassID == 10);

local HV = {
	SigilOfFlame = 204596,
	ImmolationAura = 258920,
	FirstBlood = 206416,
	TrailOfRuin = 258881,
	ChaosTheory = 389687,
	DemonBlades = 203555,
	BladeDance = 188499,
	Demonic = 213410,
	BlindFury = 203550,
	EyeBeam = 198013,
	Momentum = 206476,
	EssenceBreak = 258860,
	Metamorphosis = 191427,
	ShatteredDestiny = 388116,
	InnerDemon = 389693,
	Ragefire = 388107,
	ThrowGlaive = 185123,
	SerratedGlaive = 390154,
	Disrupt = 183752,
	FelRush = 195072,
	UnboundChaos = 347461,
	Annihilation = 201427,
	VengefulRetreat = 198793,
	Initiative = 388108,
	CycleOfHatred = 258887,
	AnyMeansNecessary = 388114,
	TacticalRetreat = 389688,
	DeathSweep = 210152,
	FelBarrage = 258925,
	GlaiveTempest = 342817,
	TheHunt = 370965,
	FuriousGaze = 343311,
	Tier302pc = 393628,
	RestlessHunter = 390142,
	Soulrend = 388106,
	FuriousThrows = 393029,
	IsolatedPrey = 388113,
	ChaosStrike = 162794,
	Felblade = 232893,
	DemonsBite = 162243,
	BurningWound = 391189,
	ChaoticTransformation = 388112,
	ElysianDecree = 390163,
};
local A = {
};
function Demonhunter:Havoc()
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
	local gcdRemains = fd.gcdRemains;
	local timeToDie = fd.timeToDie;
	local fury = UnitPower('player', Enum.PowerType.Fury);
	local furyMax = UnitPowerMax('player', Enum.PowerType.Fury);
	local furyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local furyRegen = select(2,GetPowerRegen());
	local furyRegenCombined = furyRegen + fury;
	local furyDeficit = UnitPowerMax('player', Enum.PowerType.Fury) - fury;
	local furyTimeToMax = furyMax - fury / furyRegen;

	-- variable,name=blade_dance,value=talent.first_blood|talent.trail_of_ruin|talent.chaos_theory&buff.chaos_theory.down|spell_targets.blade_dance1>1;
	local bladeDance = talents[HV.FirstBlood] or talents[HV.TrailOfRuin] or talents[HV.ChaosTheory] and not buff[HV.ChaosTheory].up or targets > 1;

	-- variable,name=pooling_for_blade_dance,value=variable.blade_dance&fury<(75-talent.demon_blades*20)&cooldown.blade_dance.remains<gcd.max;
	local poolingForBladeDance = bladeDance and fury < ( 75 - (talents[HV.DemonBlades] and 1 or 0) * 20 ) and cooldown[HV.BladeDance].remains < gcd;

	-- variable,name=pooling_for_eye_beam,value=talent.demonic&!talent.blind_fury&cooldown.eye_beam.remains<(gcd.max*2)&fury<60;
	local poolingForEyeBeam = talents[HV.Demonic] and not talents[HV.BlindFury] and cooldown[HV.EyeBeam].remains < ( gcd * 2 ) and fury < 60;

	-- variable,name=waiting_for_momentum,value=talent.momentum&!buff.momentum.up;
	local waitingForMomentum = talents[HV.Momentum] and not buff[HV.Momentum].up;

	-- variable,name=holding_meta,value=(talent.demonic&talent.essence_break)&variable.3min_trinket&fight_remains>cooldown.metamorphosis.remains+30+talent.shattered_destiny*60&cooldown.metamorphosis.remains<20&cooldown.metamorphosis.remains>action.eye_beam.execute_time+gcd.max*(talent.inner_demon+2);
	local holdingMeta = ( talents[HV.Demonic] and talents[HV.EssenceBreak] ) and timeToDie > cooldown[HV.Metamorphosis].remains + 30 + (talents[HV.ShatteredDestiny] and 1 or 0) * 60 and cooldown[HV.Metamorphosis].remains < 20 and cooldown[HV.Metamorphosis].remains > timeShift + gcd * ( (talents[HV.InnerDemon] and 1 or 0) + 2 );

	-- immolation_aura,if=talent.ragefire&active_enemies>=3&(cooldown.blade_dance.remains|debuff.essence_break.down);
	if cooldown[HV.ImmolationAura].ready and (talents[HV.Ragefire] and targets >= 3 and ( cooldown[HV.BladeDance].remains or not debuff[HV.EssenceBreak].up )) then
		return HV.ImmolationAura;
	end

	-- throw_glaive,if=talent.serrated_glaive&(buff.metamorphosis.remains>gcd.max*6&(debuff.serrated_glaive.down|debuff.serrated_glaive.remains<cooldown.essence_break.remains+5&cooldown.essence_break.remains<gcd.max*2)&(cooldown.blade_dance.remains|cooldown.essence_break.remains<gcd.max*2)|time<0.5)&debuff.essence_break.down&target.time_to_die>gcd.max*8;
	if cooldown[HV.ThrowGlaive].ready and fury >= 0 and (talents[HV.SerratedGlaive] and ( buff[HV.Metamorphosis].remains > gcd * 6 and ( not debuff[HV.SerratedGlaive].up or debuff[HV.SerratedGlaive].remains < cooldown[HV.EssenceBreak].remains + 5 and cooldown[HV.EssenceBreak].remains < gcd * 2 ) and ( cooldown[HV.BladeDance].remains or cooldown[HV.EssenceBreak].remains < gcd * 2 ) or GetTime() < 0.5 ) and not debuff[HV.EssenceBreak].up and timeToDie > gcd * 8) then
		return HV.ThrowGlaive;
	end

	-- throw_glaive,if=talent.serrated_glaive&cooldown.eye_beam.remains<gcd.max*2&debuff.serrated_glaive.remains<(2+buff.metamorphosis.down*6)&(cooldown.blade_dance.remains|buff.metamorphosis.down)&debuff.essence_break.down&target.time_to_die>gcd.max*8;
	if cooldown[HV.ThrowGlaive].ready and fury >= 0 and (talents[HV.SerratedGlaive] and cooldown[HV.EyeBeam].remains < gcd * 2 and debuff[HV.SerratedGlaive].remains < ( 2 + not buff[HV.Metamorphosis].up * 6 ) and ( cooldown[HV.BladeDance].remains or not buff[HV.Metamorphosis].up ) and not debuff[HV.EssenceBreak].up and timeToDie > gcd * 8) then
		return HV.ThrowGlaive;
	end

	-- disrupt;
	if cooldown[HV.Disrupt].ready then
		return HV.Disrupt;
	end

	-- fel_rush,if=buff.unbound_chaos.up&(buff.unbound_chaos.remains<gcd.max*2|target.time_to_die<gcd.max*2);
	if cooldown[HV.FelRush].ready and (buff[HV.UnboundChaos].up and ( buff[HV.UnboundChaos].remains < gcd * 2 or timeToDie < gcd * 2 )) then
		return HV.FelRush;
	end

	-- call_action_list,name=cooldown;
	local result = Demonhunter:HavocCooldown();
	if result then
		return result;
	end

	-- call_action_list,name=meta_end,if=buff.metamorphosis.up&buff.metamorphosis.remains<gcd.max&active_enemies<3;
	if buff[HV.Metamorphosis].up and buff[HV.Metamorphosis].remains < gcd and targets < 3 then
		local result = Demonhunter:HavocMetaEnd();
		if result then
			return result;
		end
	end

	-- annihilation,if=buff.inner_demon.up&cooldown.metamorphosis.remains<=gcd*3;
	if buff[HV.InnerDemon].up and cooldown[HV.Metamorphosis].remains <= gcd * 3 then
		return HV.Annihilation;
	end

	-- vengeful_retreat,use_off_gcd=1,if=talent.initiative&talent.essence_break&time>1&(cooldown.essence_break.remains>15|cooldown.essence_break.remains<gcd.max&(!talent.demonic|buff.metamorphosis.up|cooldown.eye_beam.remains>15+(10*talent.cycle_of_hatred)))&(time<30|gcd.remains-1<0)&!talent.any_means_necessary&(!talent.initiative|buff.initiative.remains<gcd.max|time>4);
	if talents[HV.VengefulRetreat] and cooldown[HV.VengefulRetreat].ready and (talents[HV.Initiative] and talents[HV.EssenceBreak] and GetTime() > 1 and ( cooldown[HV.EssenceBreak].remains > 15 or cooldown[HV.EssenceBreak].remains < gcd and ( not talents[HV.Demonic] or buff[HV.Metamorphosis].up or cooldown[HV.EyeBeam].remains > 15 + ( 10 * (talents[HV.CycleOfHatred] and 1 or 0) ) ) ) and ( GetTime() < 30 or gcdRemains - 1 < 0 ) and not talents[HV.AnyMeansNecessary] and ( not talents[HV.Initiative] or buff[HV.Initiative].remains < gcd or GetTime() > 4 )) then
		return HV.VengefulRetreat;
	end

	-- vengeful_retreat,use_off_gcd=1,if=talent.initiative&talent.essence_break&time>1&(cooldown.essence_break.remains>15|cooldown.essence_break.remains<gcd.max*2&(buff.initiative.remains<gcd.max&!variable.holding_meta&cooldown.eye_beam.remains=gcd.remains&(raid_event.adds.in>(40-talent.cycle_of_hatred*15))&fury>30|!talent.demonic|buff.metamorphosis.up|cooldown.eye_beam.remains>15+(10*talent.cycle_of_hatred)))&talent.any_means_necessary;
	if talents[HV.VengefulRetreat] and cooldown[HV.VengefulRetreat].ready and (talents[HV.Initiative] and talents[HV.EssenceBreak] and GetTime() > 1 and ( cooldown[HV.EssenceBreak].remains > 15 or cooldown[HV.EssenceBreak].remains < gcd * 2 and ( buff[HV.Initiative].remains < gcd and not holdingMeta and cooldown[HV.EyeBeam].remains == gcdRemains and ( 40 - (talents[HV.CycleOfHatred] and 1 or 0) * 15 )  and fury > 30 or not talents[HV.Demonic] or buff[HV.Metamorphosis].up or cooldown[HV.EyeBeam].remains > 15 + ( 10 * (talents[HV.CycleOfHatred] and 1 or 0) ) ) ) and talents[HV.AnyMeansNecessary]) then
		return HV.VengefulRetreat;
	end

	-- vengeful_retreat,use_off_gcd=1,if=talent.initiative&!talent.essence_break&time>1&!buff.momentum.up;
	if talents[HV.VengefulRetreat] and cooldown[HV.VengefulRetreat].ready and (talents[HV.Initiative] and not talents[HV.EssenceBreak] and GetTime() > 1 and not buff[HV.Momentum].up) then
		return HV.VengefulRetreat;
	end

	-- fel_rush,if=talent.momentum.enabled&buff.momentum.remains<gcd.max*2&(charges_fractional>1.8|cooldown.eye_beam.remains<3)&debuff.essence_break.down&cooldown.blade_dance.remains;
	if cooldown[HV.FelRush].ready and (talents[HV.Momentum] and buff[HV.Momentum].remains < gcd * 2 and ( cooldown[HV.FelRush].charges > 1.8 or cooldown[HV.EyeBeam].remains < 3 ) and not debuff[HV.EssenceBreak].up and cooldown[HV.BladeDance].remains) then
		return HV.FelRush;
	end

	-- essence_break,if=(active_enemies>desired_targets|raid_event.adds.in>40)&!variable.waiting_for_momentum&(buff.metamorphosis.remains>gcd.max*3|cooldown.eye_beam.remains>10)&(!talent.tactical_retreat|buff.tactical_retreat.up|time<10)&buff.vengeful_retreat_movement.remains<gcd.max*0.5&cooldown.blade_dance.remains<=3.1*gcd.max|fight_remains<6;
	if talents[HV.EssenceBreak] and cooldown[HV.EssenceBreak].ready and (( targets > desiredTargets ) and not waitingForMomentum and ( buff[HV.Metamorphosis].remains > gcd * 3 or cooldown[HV.EyeBeam].remains > 10 ) and ( not talents[HV.TacticalRetreat] or buff[HV.TacticalRetreat].up or GetTime() < 10 ) and buff[HV.VengefulRetreatMovement].remains < gcd * 0.5 and cooldown[HV.BladeDance].remains <= 3.1 * gcd or timeToDie < 6) then
		return HV.EssenceBreak;
	end

	-- death_sweep,if=variable.blade_dance&(!talent.essence_break|cooldown.essence_break.remains>gcd.max*2);
	if cooldown[HV.DeathSweep].ready and fury >= 30 and (bladeDance and ( not talents[HV.EssenceBreak] or cooldown[HV.EssenceBreak].remains > gcd * 2 )) then
		return HV.DeathSweep;
	end

	-- fel_barrage,if=active_enemies>desired_targets|raid_event.adds.in>30;
	if talents[HV.FelBarrage] and cooldown[HV.FelBarrage].ready and (targets > desiredTargets) then
		return HV.FelBarrage;
	end

	-- glaive_tempest,if=(active_enemies>desired_targets|raid_event.adds.in>10)&(debuff.essence_break.down|active_enemies>1);
	if talents[HV.GlaiveTempest] and cooldown[HV.GlaiveTempest].ready and fury >= 30 and (( targets > desiredTargets ) and ( not debuff[HV.EssenceBreak].up or targets > 1 )) then
		return HV.GlaiveTempest;
	end

	-- annihilation,if=buff.inner_demon.up&cooldown.eye_beam.remains<=gcd;
	if buff[HV.InnerDemon].up and cooldown[HV.EyeBeam].remains <= gcd then
		return HV.Annihilation;
	end

	-- fel_rush,if=talent.momentum.enabled&cooldown.eye_beam.remains<gcd.max*3&buff.momentum.remains<5&buff.metamorphosis.down;
	if cooldown[HV.FelRush].ready and (talents[HV.Momentum] and cooldown[HV.EyeBeam].remains < gcd * 3 and buff[HV.Momentum].remains < 5 and not buff[HV.Metamorphosis].up) then
		return HV.FelRush;
	end

	-- the_hunt,if=debuff.essence_break.down&(time<10|cooldown.metamorphosis.remains>10|!equipped.algethar_puzzle_box)&(raid_event.adds.in>90|active_enemies>3|time_to_die<10)&(time>6&debuff.essence_break.down&(!talent.furious_gaze|buff.furious_gaze.up)|!set_bonus.tier30_2pc);
	if talents[HV.TheHunt] and cooldown[HV.TheHunt].ready and currentSpell ~= HV.TheHunt and (not debuff[HV.EssenceBreak].up and ( GetTime() < 10 or cooldown[HV.Metamorphosis].remains > 10 or not IsEquippedItem(AlgetharPuzzleBox) ) and ( targets > 3 or timeToDie < 10 ) and ( GetTime() > 6 and not debuff[HV.EssenceBreak].up and ( not talents[HV.FuriousGaze] or buff[HV.FuriousGaze].up ) or not MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2) )) then
		return HV.TheHunt;
	end

	-- eye_beam,if=active_enemies>desired_targets|raid_event.adds.in>(40-talent.cycle_of_hatred*15)&!debuff.essence_break.up&(cooldown.metamorphosis.remains>40-talent.cycle_of_hatred*15|!variable.holding_meta)&(buff.metamorphosis.down|buff.metamorphosis.remains>gcd.max|!talent.restless_hunter)|fight_remains<15;
	if talents[HV.EyeBeam] and cooldown[HV.EyeBeam].ready and fury >= 30 and (targets > desiredTargets and not debuff[HV.EssenceBreak].up and ( cooldown[HV.Metamorphosis].remains > 40 - (talents[HV.CycleOfHatred] and 1 or 0) * 15 or not holdingMeta ) and ( not buff[HV.Metamorphosis].up or buff[HV.Metamorphosis].remains > gcd or not talents[HV.RestlessHunter] ) or timeToDie < 15) then
		return HV.EyeBeam;
	end

	-- blade_dance,if=variable.blade_dance&(cooldown.eye_beam.remains>5|equipped.algethar_puzzle_box&cooldown.metamorphosis.remains>(cooldown.blade_dance.duration)|!talent.demonic|(raid_event.adds.in>cooldown&raid_event.adds.in<25));
	if cooldown[HV.BladeDance].ready and fury >= 35 and (bladeDance and ( cooldown[HV.EyeBeam].remains > 5 or IsEquippedItem(AlgetharPuzzleBox) and cooldown[HV.Metamorphosis].remains > ( cooldown[HV.BladeDance].duration ) or not talents[HV.Demonic] )) then
		return HV.BladeDance;
	end

	-- sigil_of_flame,if=talent.any_means_necessary&debuff.essence_break.down&active_enemies>=4;
	if talents[HV.SigilOfFlame] and cooldown[HV.SigilOfFlame].ready and (talents[HV.AnyMeansNecessary] and not debuff[HV.EssenceBreak].up and targets >= 4) then
		return HV.SigilOfFlame;
	end

	-- throw_glaive,if=talent.soulrend&(active_enemies>desired_targets|raid_event.adds.in>full_recharge_time+9)&spell_targets>=(2-talent.furious_throws)&!debuff.essence_break.up&(full_recharge_time<gcd.max*3|active_enemies>1);
	if cooldown[HV.ThrowGlaive].ready and fury >= 0 and (talents[HV.Soulrend] and ( targets > desiredTargets ) and targets >= ( 2 - (talents[HV.FuriousThrows] and 1 or 0) ) and not debuff[HV.EssenceBreak].up and ( cooldown[HV.ThrowGlaive].fullRecharge < gcd * 3 or targets > 1 )) then
		return HV.ThrowGlaive;
	end

	-- sigil_of_flame,if=talent.any_means_necessary&debuff.essence_break.down;
	if talents[HV.SigilOfFlame] and cooldown[HV.SigilOfFlame].ready and (talents[HV.AnyMeansNecessary] and not debuff[HV.EssenceBreak].up) then
		return HV.SigilOfFlame;
	end

	-- immolation_aura,if=active_enemies>=2&fury<70&debuff.essence_break.down;
	if cooldown[HV.ImmolationAura].ready and (targets >= 2 and fury < 70 and not debuff[HV.EssenceBreak].up) then
		return HV.ImmolationAura;
	end

	-- annihilation,if=!variable.pooling_for_blade_dance|set_bonus.tier30_2pc;
	if not poolingForBladeDance or MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2) then
		return HV.Annihilation;
	end

	-- throw_glaive,if=talent.soulrend&(active_enemies>desired_targets|raid_event.adds.in>full_recharge_time+9)&spell_targets>=(2-talent.furious_throws)&!debuff.essence_break.up;
	if cooldown[HV.ThrowGlaive].ready and fury >= 0 and (talents[HV.Soulrend] and ( targets > desiredTargets ) and targets >= ( 2 - (talents[HV.FuriousThrows] and 1 or 0) ) and not debuff[HV.EssenceBreak].up) then
		return HV.ThrowGlaive;
	end

	-- immolation_aura,if=!buff.immolation_aura.up&(!talent.ragefire|active_enemies>desired_targets|raid_event.adds.in>15)&buff.out_of_range.down;
	if cooldown[HV.ImmolationAura].ready and (not buff[HV.ImmolationAura].up and ( not talents[HV.Ragefire] or targets > desiredTargets ) and not buff[HV.OutOfRange].up) then
		return HV.ImmolationAura;
	end

	-- fel_rush,if=talent.isolated_prey&active_enemies=1&fury.deficit>=35;
	if cooldown[HV.FelRush].ready and (talents[HV.IsolatedPrey] and targets == 1 and furyDeficit >= 35) then
		return HV.FelRush;
	end

	-- chaos_strike,if=!variable.pooling_for_blade_dance&!variable.pooling_for_eye_beam;
	if fury >= 40 and (not poolingForBladeDance and not poolingForEyeBeam) then
		return HV.ChaosStrike;
	end

	-- sigil_of_flame,if=raid_event.adds.in>15&fury.deficit>=30&buff.out_of_range.down;
	if talents[HV.SigilOfFlame] and cooldown[HV.SigilOfFlame].ready then
		return HV.SigilOfFlame;
	end

	-- felblade,if=fury.deficit>=40&buff.out_of_range.down;
	if talents[HV.Felblade] and cooldown[HV.Felblade].ready and (furyDeficit >= 40 and not buff[HV.OutOfRange].up) then
		return HV.Felblade;
	end

	-- fel_rush,if=!talent.momentum&talent.demon_blades&!cooldown.eye_beam.ready&(charges=2|(raid_event.movement.in>10&raid_event.adds.in>10));
	if cooldown[HV.FelRush].ready and (not talents[HV.Momentum] and talents[HV.DemonBlades] and not cooldown[HV.EyeBeam].ready and ( cooldown[HV.FelRush].charges == 2 )) then
		return HV.FelRush;
	end

	-- demons_bite,target_if=min:debuff.burning_wound.remains,if=talent.burning_wound&debuff.burning_wound.remains<4&active_dot.burning_wound<(spell_targets>?3);
	if talents[HV.BurningWound] and debuff[HV.BurningWound].remains < 4 and activeDot[HV.BurningWound] < ( targets >  3 ) then
		return HV.DemonsBite;
	end

	-- fel_rush,if=!talent.momentum&!talent.demon_blades&spell_targets>1&(charges=2|(raid_event.movement.in>10&raid_event.adds.in>10));
	if cooldown[HV.FelRush].ready and (not talents[HV.Momentum] and not talents[HV.DemonBlades] and targets > 1 and ( cooldown[HV.FelRush].charges == 2  )) then
		return HV.FelRush;
	end

	-- sigil_of_flame,if=raid_event.adds.in>15&fury.deficit>=30&buff.out_of_range.down;
	if talents[HV.SigilOfFlame] and cooldown[HV.SigilOfFlame].ready then
		return HV.SigilOfFlame;
	end

	-- demons_bite;
	-- HV.DemonsBite;

	-- fel_rush,if=movement.distance>15|(buff.out_of_range.up&!talent.momentum);
	if cooldown[HV.FelRush].ready and (15 or ( buff[HV.OutOfRange].up and not talents[HV.Momentum] )) then
		return HV.FelRush;
	end

	-- vengeful_retreat,if=!talent.initiative&movement.distance>15;
	if talents[HV.VengefulRetreat] and cooldown[HV.VengefulRetreat].ready and (not talents[HV.Initiative] and 15) then
		return HV.VengefulRetreat;
	end

	-- throw_glaive,if=(talent.demon_blades|buff.out_of_range.up)&!debuff.essence_break.up&buff.out_of_range.down;
	if cooldown[HV.ThrowGlaive].ready and fury >= 0 and (( talents[HV.DemonBlades] or buff[HV.OutOfRange].up ) and not debuff[HV.EssenceBreak].up and not buff[HV.OutOfRange].up) then
		return HV.ThrowGlaive;
	end
end
function Demonhunter:HavocCooldown()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local gcd = fd.gcd;
	local timeToDie = fd.timeToDie;

	-- metamorphosis,if=!talent.demonic&((!talent.chaotic_transformation|cooldown.eye_beam.remains>20)&active_enemies>desired_targets|raid_event.adds.in>60|fight_remains<25);
	if cooldown[HV.Metamorphosis].ready and (not talents[HV.Demonic] and ( ( not talents[HV.ChaoticTransformation] or cooldown[HV.EyeBeam].remains > 20 ) and targets > desiredTargets or timeToDie < 25 )) then
		return HV.Metamorphosis;
	end

	-- metamorphosis,if=talent.demonic&(!talent.chaotic_transformation|cooldown.eye_beam.remains>20&(!variable.blade_dance|cooldown.blade_dance.remains>gcd.max)|fight_remains<25+talent.shattered_destiny*70&cooldown.eye_beam.remains&cooldown.blade_dance.remains);
	if cooldown[HV.Metamorphosis].ready and (talents[HV.Demonic] and ( not talents[HV.ChaoticTransformation] or cooldown[HV.EyeBeam].remains > 20 and ( not bladeDance or cooldown[HV.BladeDance].remains > gcd ) or timeToDie < 25 + (talents[HV.ShatteredDestiny] and 1 or 0) * 70 and cooldown[HV.EyeBeam].remains and cooldown[HV.BladeDance].remains )) then
		return HV.Metamorphosis;
	end

	-- elysian_decree,if=(active_enemies>desired_targets|raid_event.adds.in>30);
	if talents[HV.ElysianDecree] and cooldown[HV.ElysianDecree].ready and (( targets > desiredTargets )) then
		return HV.ElysianDecree;
	end
end

function Demonhunter:HavocMetaEnd()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local fury = UnitPower('player', Enum.PowerType.Fury);
	local furyMax = UnitPowerMax('player', Enum.PowerType.Fury);
	local furyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local furyRegen = select(2,GetPowerRegen());
	local furyRegenCombined = furyRegen + fury;
	local furyDeficit = UnitPowerMax('player', Enum.PowerType.Fury) - fury;
	local furyTimeToMax = furyMax - fury / furyRegen;

	-- death_sweep;
	if cooldown[HV.DeathSweep].ready and fury >= 30 then
		return HV.DeathSweep;
	end

	-- annihilation;
	-- HV.Annihilation;
end


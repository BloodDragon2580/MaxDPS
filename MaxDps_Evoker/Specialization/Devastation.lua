local _, addonTable = ...;

-- @type MaxDps;
if not MaxDps then return end;
local Evoker = addonTable.Evoker;
local MaxDps = MaxDps;

local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;

local itemID = GetInventoryItemID('player', INVSLOT_MAINHAND);

local mainHandSubClassID = itemID and  select(13, GetItemInfo(itemID));

local TwoHanderWepCheck = mainHandSubClassID and (mainHandSubClassID == 1 or mainHandSubClassID == 5 or mainHandSubClassID == 8 or mainHandSubClassID == 10);

local DV = {
	Dragonrage = 375087,
	VerdantEmbrace = 360995,
	ScarletAdaptation = 372469,
	Firestorm = 368847,
	LivingFlame = 361469,
	EternitySurge = 359073,
	FireBreath = 357208,
	Quell = 351338,
	ShatteringStar = 370452,
	TipTheScales = 370553,
	EternitysSpan = 375757,
	Animosity = 375797,
	PowerSwell = 370839,
	BlazingShards = 409848,
	DeepBreath = 357210,
	EssenceBurst = 359565,
	ArcaneVigor = 386342,
	Pyre = 357211,
	Volatility = 369089,
	ChargedBlast = 370455,
	IridescenceBlue = 386399,
	RagingInferno = 405659,
	InFirestorm = 369372,
	Burnout = 375801,
	LeapingFlames = 369939,
	Disintegrate = 356995,
	Snapfire = 370783,
	AzureStrike = 362969,
	EmeraldBlossom = 355913,
	Hover = 358267,
	FontOfMagic = 411212,
	EverburningFlame = 370819,
	EventHorizon = 411164,
	EyeOfInfinity = 411165,
	OnyxLegacy = 386348,
	ImminentDestruction = 370781,
	AncientFlame = 369990,
	IridescenceRed = 386353,
};
local A = {
};
function Evoker:Devastation()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local targets = fd.targets and fd.targets or 1;
	local gcd = fd.gcd;

	-- variable,name=next_dragonrage,value=cooldown.dragonrage.remains<?(cooldown.eternity_surge.remains-2*gcd.max)<?(cooldown.fire_breath.remains-gcd.max);
	local nextDragonrage = cooldown[DV.Dragonrage].remains <= ( cooldown[DV.EternitySurge].remains - 2 * gcd ) <= ( cooldown[DV.FireBreath].remains - gcd );

	-- call_action_list,name=trinkets;

	-- run_action_list,name=aoe,if=active_enemies>=3;
	if targets >= 3 then
		return Evoker:DevastationAoe();
	end

	-- run_action_list,name=st;
	return Evoker:DevastationSt();
end
function Evoker:DevastationAoe()
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
	local timeToDie = fd.timeToDie;
	local essence = UnitPower('player', Enum.PowerType.Essence);
	local essenceMax = UnitPowerMax('player', Enum.PowerType.Essence);
	local essencePct = UnitPower('player')/UnitPowerMax('player') * 100;
	local essenceRegen = select(2,GetPowerRegen());
	local essenceRegenCombined = essenceRegen + essence;
	local essenceDeficit = UnitPowerMax('player', Enum.PowerType.Essence) - essence;
	local essenceTimeToMax = essenceMax - essence / essenceRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- shattering_star,target_if=max:target.health.pct,if=cooldown.dragonrage.up;
	if cooldown[DV.Dragonrage].up then
		return DV.ShatteringStar;
	end

	-- dragonrage,if=target.time_to_die>=32|fight_remains<30;
	if talents[DV.Dragonrage] and cooldown[DV.Dragonrage].ready and (timeToDie >= 32 or timeToDie < 30) then
		return DV.Dragonrage;
	end

	-- tip_the_scales,if=buff.dragonrage.up&(active_enemies<=3+3*talent.eternitys_span|!cooldown.fire_breath.up);
	if talents[DV.TipTheScales] and cooldown[DV.TipTheScales].ready and (buff[DV.Dragonrage].up and ( targets <= 3 + 3 * (talents[DV.EternitysSpan] and 1 or 0) or not cooldown[DV.FireBreath].up )) then
		return DV.TipTheScales;
	end

	-- call_action_list,name=fb,if=(!talent.dragonrage|variable.next_dragonrage>variable.dr_prep_time_aoe|!talent.animosity)&(buff.power_swell.remains<variable.r1_cast_time&buff.blazing_shards.remains<variable.r1_cast_time|buff.dragonrage.up)&(target.time_to_die>=8|fight_remains<30);
	if ( not talents[DV.Dragonrage] or nextDragonrage > drPrepTimeAoe or not talents[DV.Animosity] ) and ( buff[DV.PowerSwell].remains < r1CastTime and buff[DV.BlazingShards].remains < r1CastTime or buff[DV.Dragonrage].up ) and ( timeToDie >= 8 or timeToDie < 30 ) then
		local result = Evoker:DevastationFb();
		if result then
			return result;
		end
	end

	-- call_action_list,name=es,if=buff.dragonrage.up|!talent.dragonrage|(cooldown.dragonrage.remains>variable.dr_prep_time_aoe&buff.power_swell.remains<variable.r1_cast_time&buff.blazing_shards.remains<variable.r1_cast_time)&(target.time_to_die>=8|fight_remains<30);
	if buff[DV.Dragonrage].up or not talents[DV.Dragonrage] or ( cooldown[DV.Dragonrage].remains > drPrepTimeAoe and buff[DV.PowerSwell].remains < r1CastTime and buff[DV.BlazingShards].remains < r1CastTime ) and ( timeToDie >= 8 or timeToDie < 30 ) then
		local result = Evoker:DevastationEs();
		if result then
			return result;
		end
	end

	-- deep_breath,if=!buff.dragonrage.up;
	if cooldown[DV.DeepBreath].ready and (not buff[DV.Dragonrage].up) then
		return DV.DeepBreath;
	end

	-- shattering_star,target_if=max:target.health.pct,if=buff.essence_burst.stack<buff.essence_burst.max_stack|!talent.arcane_vigor;
	if buff[DV.EssenceBurst].count < buff[DV.EssenceBurst].maxStacks or not talents[DV.ArcaneVigor] then
		return DV.ShatteringStar;
	end

	-- firestorm;
	if talents[DV.Firestorm] and cooldown[DV.Firestorm].ready and currentSpell ~= DV.Firestorm then
		return DV.Firestorm;
	end

	-- pyre,target_if=max:target.health.pct,if=talent.volatility&(active_enemies>=4|(talent.charged_blast&!buff.essence_burst.up&!buff.iridescence_blue.up)|(!talent.charged_blast&(!buff.essence_burst.up|!buff.iridescence_blue.up))|(buff.charged_blast.stack>=15)|(talent.raging_inferno&debuff.in_firestorm.up));
	if talents[DV.Pyre] and essence >= 2 and (talents[DV.Volatility] and ( targets >= 4 or ( talents[DV.ChargedBlast] and not buff[DV.EssenceBurst].up and not buff[DV.IridescenceBlue].up ) or ( not talents[DV.ChargedBlast] and ( not buff[DV.EssenceBurst].up or not buff[DV.IridescenceBlue].up ) ) or ( buff[DV.ChargedBlast].count >= 15 ) or ( talents[DV.RagingInferno] and debuff[DV.InFirestorm].up ) )) then
		return DV.Pyre;
	end

	-- pyre,target_if=max:target.health.pct,if=(talent.raging_inferno&debuff.in_firestorm.up)|(active_enemies==3&buff.charged_blast.stack>=15)|active_enemies>=4;
	if talents[DV.Pyre] and essence >= 2 and (( talents[DV.RagingInferno] and debuff[DV.InFirestorm].up ) or ( targets == 3 and buff[DV.ChargedBlast].count >= 15 ) or targets >= 4) then
		return DV.Pyre;
	end

	-- living_flame,target_if=max:target.health.pct,if=(!talent.burnout|buff.burnout.up|active_enemies>=4|buff.scarlet_adaptation.up)&buff.leaping_flames.up&!buff.essence_burst.up&essence<essence.max-1;
	if mana >= 0 and currentSpell ~= DV.LivingFlame and (( not talents[DV.Burnout] or buff[DV.Burnout].up or targets >= 4 or buff[DV.ScarletAdaptation].up ) and buff[DV.LeapingFlames].up and not buff[DV.EssenceBurst].up and essence < essenceMax - 1) then
		return DV.LivingFlame;
	end

	-- living_flame,target_if=max:target.health.pct,if=talent.snapfire&buff.burnout.up;
	if mana >= 0 and currentSpell ~= DV.LivingFlame and (talents[DV.Snapfire] and buff[DV.Burnout].up) then
		return DV.LivingFlame;
	end

	-- azure_strike,target_if=max:target.health.pct;
	if mana >= 0 then
		return DV.AzureStrike;
	end
end

function Evoker:DevastationEs()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
end

function Evoker:DevastationFb()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
end

function Evoker:DevastationGreen()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local talents = fd.talents;
	local essence = UnitPower('player', Enum.PowerType.Essence);
	local essenceMax = UnitPowerMax('player', Enum.PowerType.Essence);
	local essencePct = UnitPower('player')/UnitPowerMax('player') * 100;
	local essenceRegen = select(2,GetPowerRegen());
	local essenceRegenCombined = essenceRegen + essence;
	local essenceDeficit = UnitPowerMax('player', Enum.PowerType.Essence) - essence;
	local essenceTimeToMax = essenceMax - essence / essenceRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- emerald_blossom;
	if cooldown[DV.EmeraldBlossom].ready and essence >= 0 and mana >= 0 then
		return DV.EmeraldBlossom;
	end

	-- verdant_embrace;
	if talents[DV.VerdantEmbrace] and cooldown[DV.VerdantEmbrace].ready and mana >= 0 then
		return DV.VerdantEmbrace;
	end
end

function Evoker:DevastationSt()
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
	local essence = UnitPower('player', Enum.PowerType.Essence);
	local essenceMax = UnitPowerMax('player', Enum.PowerType.Essence);
	local essencePct = UnitPower('player')/UnitPowerMax('player') * 100;
	local essenceRegen = select(2,GetPowerRegen());
	local essenceRegenCombined = essenceRegen + essence;
	local essenceDeficit = UnitPowerMax('player', Enum.PowerType.Essence) - essence;
	local essenceTimeToMax = essenceMax - essence / essenceRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- hover,use_off_gcd=1,if=raid_event.movement.in<2&!buff.hover.up;
	if cooldown[DV.Hover].ready and (not buff[DV.Hover].up) then
		return DV.Hover;
	end

	-- firestorm,if=buff.snapfire.up;
	if talents[DV.Firestorm] and cooldown[DV.Firestorm].ready and currentSpell ~= DV.Firestorm and (buff[DV.Snapfire].up) then
		return DV.Firestorm;
	end

	-- dragonrage,if=cooldown.fire_breath.remains<4&cooldown.eternity_surge.remains<10&target.time_to_die>=32|fight_remains<30;
	if talents[DV.Dragonrage] and cooldown[DV.Dragonrage].ready and (cooldown[DV.FireBreath].remains < 4 and cooldown[DV.EternitySurge].remains < 10 and timeToDie >= 32 or timeToDie < 30) then
		return DV.Dragonrage;
	end

	-- tip_the_scales,if=buff.dragonrage.up&(((!talent.font_of_magic|talent.everburning_flame)&cooldown.fire_breath.remains<cooldown.eternity_surge.remains&buff.dragonrage.remains<14)|(cooldown.eternity_surge.remains<cooldown.fire_breath.remains&!talent.everburning_flame&talent.font_of_magic));
	if talents[DV.TipTheScales] and cooldown[DV.TipTheScales].ready and (buff[DV.Dragonrage].up and ( ( ( not talents[DV.FontOfMagic] or talents[DV.EverburningFlame] ) and cooldown[DV.FireBreath].remains < cooldown[DV.EternitySurge].remains and buff[DV.Dragonrage].remains < 14 ) or ( cooldown[DV.EternitySurge].remains < cooldown[DV.FireBreath].remains and not talents[DV.EverburningFlame] and talents[DV.FontOfMagic] ) )) then
		return DV.TipTheScales;
	end

	-- call_action_list,name=fb,if=(!talent.dragonrage|variable.next_dragonrage>variable.dr_prep_time_st|!talent.animosity)&((buff.power_swell.remains<variable.r1_cast_time|buff.bloodlust.up|buff.power_infusion.up|buff.dragonrage.up)&(buff.blazing_shards.remains<variable.r1_cast_time|buff.dragonrage.up))&(!cooldown.eternity_surge.up|!talent.event_horizon|!buff.dragonrage.up)&(target.time_to_die>=8|fight_remains<30);
	if ( not talents[DV.Dragonrage] or nextDragonrage > drPrepTimeSt or not talents[DV.Animosity] ) and ( ( buff[DV.PowerSwell].remains < r1CastTime or buff[DV.Bloodlust].up or buff[DV.PowerInfusion].up or buff[DV.Dragonrage].up ) and ( buff[DV.BlazingShards].remains < r1CastTime or buff[DV.Dragonrage].up ) ) and ( not cooldown[DV.EternitySurge].up or not talents[DV.EventHorizon] or not buff[DV.Dragonrage].up ) and ( timeToDie >= 8 or timeToDie < 30 ) then
		local result = Evoker:DevastationFb();
		if result then
			return result;
		end
	end

	-- disintegrate,if=buff.dragonrage.remains>19&cooldown.fire_breath.remains>28&talent.eye_of_infinity;
	if essence >= 3 and (buff[DV.Dragonrage].remains > 19 and cooldown[DV.FireBreath].remains > 28 and talents[DV.EyeOfInfinity]) then
		return DV.Disintegrate;
	end

	-- shattering_star,if=(buff.essence_burst.stack<buff.essence_burst.max_stack|!talent.arcane_vigor)&(!cooldown.fire_breath.up|!talent.event_horizon);
	if ( buff[DV.EssenceBurst].count < buff[DV.EssenceBurst].maxStacks or not talents[DV.ArcaneVigor] ) and ( not cooldown[DV.FireBreath].up or not talents[DV.EventHorizon] ) then
		return DV.ShatteringStar;
	end

	-- call_action_list,name=es,if=(!talent.dragonrage|variable.next_dragonrage>variable.dr_prep_time_st|!talent.animosity)&((buff.power_swell.remains<variable.r1_cast_time|buff.bloodlust.up|buff.power_infusion.up)&(buff.blazing_shards.remains<variable.r1_cast_time|buff.dragonrage.up))&(target.time_to_die>=8|fight_remains<30);
	if ( not talents[DV.Dragonrage] or nextDragonrage > drPrepTimeSt or not talents[DV.Animosity] ) and ( ( buff[DV.PowerSwell].remains < r1CastTime or buff[DV.Bloodlust].up or buff[DV.PowerInfusion].up ) and ( buff[DV.BlazingShards].remains < r1CastTime or buff[DV.Dragonrage].up ) ) and ( timeToDie >= 8 or timeToDie < 30 ) then
		local result = Evoker:DevastationEs();
		if result then
			return result;
		end
	end

	-- living_flame,if=buff.dragonrage.up&buff.dragonrage.remains<(buff.essence_burst.max_stack-buff.essence_burst.stack)*gcd.max&buff.burnout.up;
	if mana >= 0 and currentSpell ~= DV.LivingFlame and (buff[DV.Dragonrage].up and buff[DV.Dragonrage].remains < ( buff[DV.EssenceBurst].maxStacks - buff[DV.EssenceBurst].count ) * gcd and buff[DV.Burnout].up) then
		return DV.LivingFlame;
	end

	-- azure_strike,if=buff.dragonrage.up&buff.dragonrage.remains<(buff.essence_burst.max_stack-buff.essence_burst.stack)*gcd.max;
	if mana >= 0 and (buff[DV.Dragonrage].up and buff[DV.Dragonrage].remains < ( buff[DV.EssenceBurst].maxStacks - buff[DV.EssenceBurst].count ) * gcd) then
		return DV.AzureStrike;
	end

	-- living_flame,if=buff.burnout.up&(buff.leaping_flames.up&!buff.essence_burst.up|!buff.leaping_flames.up&buff.essence_burst.stack<buff.essence_burst.max_stack)&essence.deficit>=2;
	if mana >= 0 and currentSpell ~= DV.LivingFlame and (buff[DV.Burnout].up and ( buff[DV.LeapingFlames].up and not buff[DV.EssenceBurst].up or not buff[DV.LeapingFlames].up and buff[DV.EssenceBurst].count < buff[DV.EssenceBurst].maxStacks ) and essenceDeficit >= 2) then
		return DV.LivingFlame;
	end

	-- pyre,if=debuff.in_firestorm.up&talent.raging_inferno&buff.charged_blast.stack==20&active_enemies>=2;
	if talents[DV.Pyre] and essence >= 2 and (debuff[DV.InFirestorm].up and talents[DV.RagingInferno] and buff[DV.ChargedBlast].count == 20 and targets >= 2) then
		return DV.Pyre;
	end

	-- firestorm,if=!buff.dragonrage.up&debuff.shattering_star_debuff.down;
	if talents[DV.Firestorm] and cooldown[DV.Firestorm].ready and currentSpell ~= DV.Firestorm and (not buff[DV.Dragonrage].up and not debuff[DV.ShatteringStarDebuff].up) then
		return DV.Firestorm;
	end

	-- deep_breath,if=!buff.dragonrage.up&active_enemies>=2&((raid_event.adds.in>=120&!talent.onyx_legacy)|(raid_event.adds.in>=60&talent.onyx_legacy));
	if cooldown[DV.DeepBreath].ready and (not buff[DV.Dragonrage].up and targets >= 2 and ( ( not talents[DV.OnyxLegacy] ) or ( talents[DV.OnyxLegacy] ) )) then
		return DV.DeepBreath;
	end

	-- deep_breath,if=!buff.dragonrage.up&talent.imminent_destruction&!debuff.shattering_star_debuff.up;
	if cooldown[DV.DeepBreath].ready and (not buff[DV.Dragonrage].up and talents[DV.ImminentDestruction] and not debuff[DV.ShatteringStarDebuff].up) then
		return DV.DeepBreath;
	end

	-- call_action_list,name=green,if=talent.ancient_flame&!buff.ancient_flame.up&!buff.shattering_star_debuff.up&talent.scarlet_adaptation&!buff.dragonrage.up;
	if talents[DV.AncientFlame] and not buff[DV.AncientFlame].up and not buff[DV.ShatteringStarDebuff].up and talents[DV.ScarletAdaptation] and not buff[DV.Dragonrage].up then
		local result = Evoker:DevastationGreen();
		if result then
			return result;
		end
	end

	-- living_flame,if=!buff.dragonrage.up|(buff.iridescence_red.remains>execute_time|buff.iridescence_blue.up)&active_enemies==1;
	if mana >= 0 and currentSpell ~= DV.LivingFlame and (not buff[DV.Dragonrage].up or ( buff[DV.IridescenceRed].remains > timeShift or buff[DV.IridescenceBlue].up ) and targets == 1) then
		return DV.LivingFlame;
	end

	-- azure_strike;
	if mana >= 0 then
		return DV.AzureStrike;
	end
end

function Evoker:DevastationTrinkets()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
end


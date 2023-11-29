local _, addonTable = ...;

-- @type MaxDps;
if not MaxDps then return end;
local Priest = addonTable.Priest;
local MaxDps = MaxDps;

local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;

local itemID = GetInventoryItemID('player', INVSLOT_MAINHAND);

local mainHandSubClassID = itemID and  select(13, GetItemInfo(itemID));

local TwoHanderWepCheck = mainHandSubClassID and (mainHandSubClassID == 1 or mainHandSubClassID == 5 or mainHandSubClassID == 8 or mainHandSubClassID == 10);

local SH = {
	Shadowform = 232698,
	ShadowCrash = 205385,
	MentalDecay = 375994,
	VampiricTouch = 34914,
	VoidEruption = 228260,
	DarkAscension = 391109,
	VoidTorrent = 263165,
	PsychicLink = 199484,
	Voidform = 228264,
	WhisperingShadows = 406777,
	Mindbender = 200174,
	ShadowWordPain = 589,
	MindBlast = 8092,
	InescapableTorment = 373427,
	MindDevourer = 373202,
	ShadowWordDeath = 32379,
	VoidBolt = 343355,
	DevouringPlague = 335467,
	DistortedReality = 409044,
	InsidiousIre = 373212,
	IdolOfYoggsaron = 373273,
	Deathspeaker = 392507,
	IdolOfCthun = 377349,
	MindFlay = 15407,
	DarkReveries = 394963,
	Mindgames = 375901,
	PowerInfusion = 10060,
	Fiend = 34433,
	DesperatePrayer = 19236,
	UnfurlingDarkness = 341273,
	Halo = 120644,
	DivineStar = 122121,
	MindSpike = 73510,
};
local A = {
};
function Priest:Shadow()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local gcd = fd.gcd;

	-- variable,name=holding_crash,op=set,value=raid_event.adds.in<15;
	--local holdingCrash = raid_event.adds.in < 15;

	-- variable,name=pool_for_cds,op=set,value=(cooldown.void_eruption.remains<=gcd.max*3&talent.void_eruption|cooldown.dark_ascension.up&talent.dark_ascension)|talent.void_torrent&talent.psychic_link&cooldown.void_torrent.remains<=4&(!raid_event.adds.exists&spell_targets.vampiric_touch>1|raid_event.adds.in<=5|raid_event.adds.remains>=6&!variable.holding_crash)&!buff.voidform.up;
	local poolForCds = ( cooldown[SH.VoidEruption].remains <= gcd * 3 and talents[SH.VoidEruption] or cooldown[SH.DarkAscension].up and talents[SH.DarkAscension] ) or talents[SH.VoidTorrent] and talents[SH.PsychicLink] and cooldown[SH.VoidTorrent].remains <= 4 and ( not targets > 1 and targets > 1 and not holdingCrash ) and not buff[SH.Voidform].up;

	-- run_action_list,name=aoe,if=active_enemies>2|spell_targets.vampiric_touch>3;
	if targets > 2 or targets > 3 then
		return Priest:ShadowAoe();
	end

	-- run_action_list,name=main;
	return Priest:ShadowMain();
end
function Priest:ShadowAoe()
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
	local insanity = UnitPower('player', Enum.PowerType.Insanity);
	local insanityMax = UnitPowerMax('player', Enum.PowerType.Insanity);
	local insanityPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local insanityRegen = select(2,GetPowerRegen());
	local insanityRegenCombined = insanityRegen + insanity;
	local insanityDeficit = UnitPowerMax('player', Enum.PowerType.Insanity) - insanity;
	local insanityTimeToMax = insanityMax - insanity / insanityRegen;

	-- call_action_list,name=aoe_variables;
	local result = Priest:ShadowAoeVariables();
	if result then
		return result;
	end

	-- vampiric_touch,target_if=refreshable&target.time_to_die>=18&(dot.vampiric_touch.ticking|!variable.vts_applied),if=variable.max_vts>0&!variable.manual_vts_applied&!action.shadow_crash.in_flight|!talent.whispering_shadows;
	if currentSpell ~= SH.VampiricTouch and (maxVts > 0 and not manualVtsApplied and not inFlight or not talents[SH.WhisperingShadows]) then
		return SH.VampiricTouch;
	end

	-- shadow_crash,if=!variable.holding_crash,target_if=dot.vampiric_touch.refreshable|dot.vampiric_touch.remains<=target.time_to_die&!buff.voidform.up&(raid_event.adds.in-dot.vampiric_touch.remains)<15;
	if talents[SH.ShadowCrash] and cooldown[SH.ShadowCrash].ready and (not holdingCrash) then
		return SH.ShadowCrash;
	end

	-- call_action_list,name=cds,if=fight_remains<30|target.time_to_die>15&(!variable.holding_crash|active_enemies>2);
	if timeToDie < 30 or timeToDie > 15 and ( not holdingCrash or targets > 2 ) then
		local result = Priest:ShadowCds();
		if result then
			return result;
		end
	end

	-- mindbender,if=(dot.shadow_word_pain.ticking&variable.vts_applied|action.shadow_crash.in_flight&talent.whispering_shadows)&(fight_remains<30|target.time_to_die>15)&(!talent.dark_ascension|cooldown.dark_ascension.remains<gcd.max|fight_remains<15);
	if talents[SH.Mindbender] and cooldown[SH.Mindbender].ready and (( debuff[SH.ShadowWordPain].up and vtsApplied or inFlight and talents[SH.WhisperingShadows] ) and ( timeToDie < 30 or timeToDie > 15 ) and ( not talents[SH.DarkAscension] or cooldown[SH.DarkAscension].remains < gcd or timeToDie < 15 )) then
		return SH.Mindbender;
	end

	-- mind_blast,if=(cooldown.mind_blast.full_recharge_time<=gcd.max+cast_time|pet.fiend.remains<=cast_time+gcd.max)&pet.fiend.active&talent.inescapable_torment&pet.fiend.remains>cast_time&active_enemies<=7&!buff.mind_devourer.up;
	if cooldown[SH.MindBlast].ready and mana >= 0 and currentSpell ~= SH.MindBlast and (( cooldown[SH.MindBlast].fullRecharge <= gcd + timeShift or fiendRemains <= timeShift + gcd ) and fiendActive and talents[SH.InescapableTorment] and fiendRemains > timeShift and targets <= 7 and not buff[SH.MindDevourer].up) then
		return SH.MindBlast;
	end

	-- shadow_word_death,if=pet.fiend.remains<=2&pet.fiend.active&talent.inescapable_torment&active_enemies<=7;
	if talents[SH.ShadowWordDeath] and cooldown[SH.ShadowWordDeath].ready and mana >= 250 and (fiendRemains <= 2 and fiendActive and talents[SH.InescapableTorment] and targets <= 7) then
		return SH.ShadowWordDeath;
	end

	-- void_bolt;
	-- SH.VoidBolt;

	-- devouring_plague,target_if=remains<=gcd.max|!talent.distorted_reality,if=remains<=gcd.max&!variable.pool_for_cds|insanity.deficit<=20|buff.voidform.up&cooldown.void_bolt.remains>buff.voidform.remains&cooldown.void_bolt.remains<=buff.voidform.remains+2;
	if talents[SH.DevouringPlague] and insanity >= 50 and (debuff[SH.DevouringPlague].remains <= gcd and not poolForCds or insanityDeficit <= 20 or buff[SH.Voidform].up and cooldown[SH.VoidBolt].remains > buff[SH.Voidform].remains and cooldown[SH.VoidBolt].remains <= buff[SH.Voidform].remains + 2) then
		return SH.DevouringPlague;
	end

	-- vampiric_touch,target_if=refreshable&target.time_to_die>=18&(dot.vampiric_touch.ticking|!variable.vts_applied),if=variable.max_vts>0&(cooldown.shadow_crash.remains>=dot.vampiric_touch.remains|variable.holding_crash)&!action.shadow_crash.in_flight|!talent.whispering_shadows;
	if currentSpell ~= SH.VampiricTouch and (maxVts > 0 and ( cooldown[SH.ShadowCrash].remains >= debuff[SH.VampiricTouch].remains or holdingCrash ) and not inFlight or not talents[SH.WhisperingShadows]) then
		return SH.VampiricTouch;
	end

	-- shadow_word_death,if=variable.vts_applied&talent.inescapable_torment&pet.fiend.active&((!talent.insidious_ire&!talent.idol_of_yoggsaron)|buff.deathspeaker.up);
	if talents[SH.ShadowWordDeath] and cooldown[SH.ShadowWordDeath].ready and mana >= 250 and (vtsApplied and talents[SH.InescapableTorment] and fiendActive and ( ( not talents[SH.InsidiousIre] and not talents[SH.IdolOfYoggsaron] ) or buff[SH.Deathspeaker].up )) then
		return SH.ShadowWordDeath;
	end

	-- mind_spike_insanity,if=variable.dots_up&cooldown.mind_blast.full_recharge_time>=gcd*3&talent.idol_of_cthun&(!cooldown.void_torrent.up|!talent.void_torrent);
	if dotsUp and cooldown[SH.MindBlast].fullRecharge >= gcd * 3 and talents[SH.IdolOfCthun] and ( not cooldown[SH.VoidTorrent].up or not talents[SH.VoidTorrent] ) then
		return SH.MindSpikeInsanity;
	end

	-- mind_flay,if=buff.mind_flay_insanity.up&variable.dots_up&cooldown.mind_blast.full_recharge_time>=gcd*3&talent.idol_of_cthun&(!cooldown.void_torrent.up|!talent.void_torrent);
	if buff[SH.MindFlayInsanity].up and dotsUp and cooldown[SH.MindBlast].fullRecharge >= gcd * 3 and talents[SH.IdolOfCthun] and ( not cooldown[SH.VoidTorrent].up or not talents[SH.VoidTorrent] ) then
		return SH.MindFlay;
	end

	-- mind_blast,if=variable.vts_applied&(!buff.mind_devourer.up|cooldown.void_eruption.up&talent.void_eruption);
	if cooldown[SH.MindBlast].ready and mana >= 0 and currentSpell ~= SH.MindBlast and (vtsApplied and ( not buff[SH.MindDevourer].up or cooldown[SH.VoidEruption].up and talents[SH.VoidEruption] )) then
		return SH.MindBlast;
	end

	-- call_action_list,name=pl_torrent,target_if=talent.void_torrent&talent.psychic_link&cooldown.void_torrent.remains<=3&(!variable.holding_crash|raid_event.adds.count%(active_dot.vampiric_touch+raid_event.adds.count)<1.5)&((insanity>=50|dot.devouring_plague.ticking|buff.dark_reveries.up)|buff.voidform.up|buff.dark_ascension.up);
	if talents[SH.VoidTorrent] and talents[SH.PsychicLink] and cooldown[SH.VoidTorrent].remains <= 3 and ( not holdingCrash or raid_event.adds.count / ( activeDot[SH.VampiricTouch] + raid_event.adds.count ) < 1.5 ) and ( ( insanity >= 50 or debuff[SH.DevouringPlague].up or buff[SH.DarkReveries].up ) or buff[SH.Voidform].up or buff[SH.DarkAscension].up ) then
		local result = Priest:ShadowPlTorrent();
		if result then
			return result;
		end
	end

	-- mindgames,if=active_enemies<5&dot.devouring_plague.ticking|talent.psychic_link;
	if talents[SH.Mindgames] and cooldown[SH.Mindgames].ready and mana >= 1000 and currentSpell ~= SH.Mindgames and (targets < 5 and debuff[SH.DevouringPlague].up or talents[SH.PsychicLink]) then
		return SH.Mindgames;
	end

	-- void_torrent,if=!talent.psychic_link,target_if=variable.dots_up;
	if talents[SH.VoidTorrent] and cooldown[SH.VoidTorrent].ready and (not talents[SH.PsychicLink]) then
		return SH.VoidTorrent;
	end

	-- mind_flay,if=buff.mind_flay_insanity.up&talent.idol_of_cthun,interrupt_if=ticks>=2,interrupt_immediate=1;
	if buff[SH.MindFlayInsanity].up and talents[SH.IdolOfCthun] then
		return SH.MindFlay;
	end

	-- call_action_list,name=filler;
	local result = Priest:ShadowFiller();
	if result then
		return result;
	end
end

function Priest:ShadowAoeVariables()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local timeToDie = fd.timeToDie;

	-- variable,name=max_vts,op=set,default=12,value=spell_targets.vampiric_touch>?12;
	local maxVts = targets >= 12;

	-- variable,name=is_vt_possible,op=set,value=0,default=1;
	local isVtPossible = 0;

	-- variable,name=is_vt_possible,op=set,value=1,target_if=max:(target.time_to_die*dot.vampiric_touch.refreshable),if=target.time_to_die>=18;
	if timeToDie >= 18 then
		local isVtPossible = 1;
	end

	-- variable,name=vts_applied,op=set,value=(active_dot.vampiric_touch+8*(action.shadow_crash.in_flight&talent.whispering_shadows))>=variable.max_vts|!variable.is_vt_possible;
	local vtsApplied = ( activeDot[SH.VampiricTouch] + 8 * ( inFlight and talents[SH.WhisperingShadows] ) ) >= maxVts or not isVtPossible;

	-- variable,name=holding_crash,op=set,value=(variable.max_vts-active_dot.vampiric_touch)<4|raid_event.adds.in<10&raid_event.adds.count>(variable.max_vts-active_dot.vampiric_touch),if=variable.holding_crash&talent.whispering_shadows;
	if holdingCrash and talents[SH.WhisperingShadows] then
		local holdingCrash = ( maxVts - activeDot[SH.VampiricTouch] ) < 4 or targets > ( maxVts - activeDot[SH.VampiricTouch] );
	end

	-- variable,name=manual_vts_applied,op=set,value=(active_dot.vampiric_touch+8*!variable.holding_crash)>=variable.max_vts|!variable.is_vt_possible;
	local manualVtsApplied = ( activeDot[SH.VampiricTouch] + 8 * not holdingCrash ) >= maxVts or not isVtPossible;
end

function Priest:ShadowCds()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;

	-- power_infusion,if=(buff.voidform.up|buff.dark_ascension.up);
	if talents[SH.PowerInfusion] and cooldown[SH.PowerInfusion].ready and (( buff[SH.Voidform].up or buff[SH.DarkAscension].up )) then
		return SH.PowerInfusion;
	end

	-- void_eruption,if=!cooldown.fiend.up&(pet.fiend.active&cooldown.fiend.remains>=4|!talent.mindbender|active_enemies>2&!talent.inescapable_torment.rank)&(cooldown.mind_blast.charges=0|time>15);
	if talents[SH.VoidEruption] and cooldown[SH.VoidEruption].ready and currentSpell ~= SH.VoidEruption and (not cooldown[SH.Fiend].up and ( fiendActive and cooldown[SH.Fiend].remains >= 4 or not talents[SH.Mindbender] or targets > 2 and not talents[SH.InescapableTorment] ) and ( cooldown[SH.MindBlast].charges == 0 or GetTime() > 15 )) then
		return SH.VoidEruption;
	end

	-- dark_ascension,if=pet.fiend.active&cooldown.fiend.remains>=4|!talent.mindbender&!cooldown.fiend.up|active_enemies>2&!talent.inescapable_torment;
	if talents[SH.DarkAscension] and cooldown[SH.DarkAscension].ready and currentSpell ~= SH.DarkAscension and (fiendActive and cooldown[SH.Fiend].remains >= 4 or not talents[SH.Mindbender] and not cooldown[SH.Fiend].up or targets > 2 and not talents[SH.InescapableTorment]) then
		return SH.DarkAscension;
	end

	-- call_action_list,name=trinkets;

	-- desperate_prayer,if=health.pct<=75;
	if cooldown[SH.DesperatePrayer].ready and (healthPct <= 75) then
		return SH.DesperatePrayer;
	end
end

function Priest:ShadowFiller()
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
	local insanity = UnitPower('player', Enum.PowerType.Insanity);
	local insanityMax = UnitPowerMax('player', Enum.PowerType.Insanity);
	local insanityPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local insanityRegen = select(2,GetPowerRegen());
	local insanityRegenCombined = insanityRegen + insanity;
	local insanityDeficit = UnitPowerMax('player', Enum.PowerType.Insanity) - insanity;
	local insanityTimeToMax = insanityMax - insanity / insanityRegen;

	-- vampiric_touch,target_if=min:remains,if=buff.unfurling_darkness.up;
	if currentSpell ~= SH.VampiricTouch and (buff[SH.UnfurlingDarkness].up) then
		return SH.VampiricTouch;
	end

	-- shadow_word_death,target_if=target.health.pct<20|buff.deathspeaker.up;
	if talents[SH.ShadowWordDeath] and cooldown[SH.ShadowWordDeath].ready and mana >= 250 then
		return SH.ShadowWordDeath;
	end

	-- mind_spike_insanity;
	-- SH.MindSpikeInsanity;

	-- mind_flay,if=buff.mind_flay_insanity.up;
	if buff[SH.MindFlayInsanity].up then
		return SH.MindFlay;
	end

	-- halo,if=raid_event.adds.in>20;
	if talents[SH.Halo] and cooldown[SH.Halo].ready and mana >= 2000 and currentSpell ~= SH.Halo then
		return SH.Halo;
	end

	-- shadow_word_death,target_if=min:target.time_to_die,if=talent.inescapable_torment&pet.fiend.active;
	if talents[SH.ShadowWordDeath] and cooldown[SH.ShadowWordDeath].ready and mana >= 250 and (talents[SH.InescapableTorment] and fiendActive) then
		return SH.ShadowWordDeath;
	end

	-- divine_star,if=raid_event.adds.in>10;
	if talents[SH.DivineStar] and cooldown[SH.DivineStar].ready and mana >= 1000 then
		return SH.DivineStar;
	end

	-- devouring_plague,if=buff.voidform.up;
	if talents[SH.DevouringPlague] and insanity >= 50 and (buff[SH.Voidform].up) then
		return SH.DevouringPlague;
	end

	-- mind_spike;
	if talents[SH.MindSpike] and currentSpell ~= SH.MindSpike then
		return SH.MindSpike;
	end

	-- mind_flay,chain=1,interrupt_immediate=1,interrupt_if=ticks>=2;
	--return SH.MindFlay;

	-- shadow_crash,if=raid_event.adds.in>20;
	if talents[SH.ShadowCrash] and cooldown[SH.ShadowCrash].ready then
		return SH.ShadowCrash;
	end

	-- shadow_word_death,target_if=target.health.pct<20;
	if talents[SH.ShadowWordDeath] and cooldown[SH.ShadowWordDeath].ready and mana >= 250 then
		return SH.ShadowWordDeath;
	end

	-- divine_star;
	if talents[SH.DivineStar] and cooldown[SH.DivineStar].ready and mana >= 1000 then
		return SH.DivineStar;
	end

	-- shadow_word_death;
	if talents[SH.ShadowWordDeath] and cooldown[SH.ShadowWordDeath].ready and mana >= 250 then
		return SH.ShadowWordDeath;
	end

	-- shadow_word_pain,target_if=min:remains;
	if mana >= 0 then
		return SH.ShadowWordPain;
	end
end

function Priest:ShadowMain()
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
	local insanity = UnitPower('player', Enum.PowerType.Insanity);
	local insanityMax = UnitPowerMax('player', Enum.PowerType.Insanity);
	local insanityPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local insanityRegen = select(2,GetPowerRegen());
	local insanityRegenCombined = insanityRegen + insanity;
	local insanityDeficit = UnitPowerMax('player', Enum.PowerType.Insanity) - insanity;
	local insanityTimeToMax = insanityMax - insanity / insanityRegen;

	-- call_action_list,name=main_variables;
	local result = Priest:ShadowMainVariables();
	if result then
		return result;
	end

	-- call_action_list,name=cds,if=fight_remains<30|target.time_to_die>15&(!variable.holding_crash|active_enemies>2);
	if timeToDie < 30 or timeToDie > 15 and ( not holdingCrash or targets > 2 ) then
		local result = Priest:ShadowCds();
		if result then
			return result;
		end
	end

	-- mindbender,if=variable.dots_up&(fight_remains<30|target.time_to_die>15)&(!talent.dark_ascension|cooldown.dark_ascension.remains<gcd.max|fight_remains<15);
	if talents[SH.Mindbender] and cooldown[SH.Mindbender].ready and (dotsUp and ( timeToDie < 30 or timeToDie > 15 ) and ( not talents[SH.DarkAscension] or cooldown[SH.DarkAscension].remains < gcd or timeToDie < 15 )) then
		return SH.Mindbender;
	end

	-- mind_blast,target_if=(dot.devouring_plague.ticking&(cooldown.mind_blast.full_recharge_time<=gcd.max+cast_time)|pet.fiend.remains<=cast_time+gcd.max)&pet.fiend.active&talent.inescapable_torment&pet.fiend.remains>cast_time&active_enemies<=7;
	if cooldown[SH.MindBlast].ready and mana >= 0 and currentSpell ~= SH.MindBlast then
		return SH.MindBlast;
	end

	-- shadow_word_death,target_if=dot.devouring_plague.ticking&pet.fiend.remains<=2&pet.fiend.active&talent.inescapable_torment&active_enemies<=7;
	if talents[SH.ShadowWordDeath] and cooldown[SH.ShadowWordDeath].ready and mana >= 250 then
		return SH.ShadowWordDeath;
	end

	-- void_bolt,if=variable.dots_up;
	if dotsUp then
		return SH.VoidBolt;
	end

	-- devouring_plague,if=fight_remains<=duration+4;
	if talents[SH.DevouringPlague] and insanity >= 50 and (timeToDie <= cooldown[SH.DevouringPlague].duration + 4) then
		return SH.DevouringPlague;
	end

	-- devouring_plague,target_if=!talent.distorted_reality|active_enemies=1|remains<=gcd.max,if=(remains<=gcd.max|remains<3&cooldown.void_torrent.up)|insanity.deficit<=20|buff.voidform.up&cooldown.void_bolt.remains>buff.voidform.remains&cooldown.void_bolt.remains<=buff.voidform.remains+2;
	if talents[SH.DevouringPlague] and insanity >= 50 and (( debuff[SH.DevouringPlague].remains <= gcd or debuff[SH.DevouringPlague].remains < 3 and cooldown[SH.VoidTorrent].up ) or insanityDeficit <= 20 or buff[SH.Voidform].up and cooldown[SH.VoidBolt].remains > buff[SH.Voidform].remains and cooldown[SH.VoidBolt].remains <= buff[SH.Voidform].remains + 2) then
		return SH.DevouringPlague;
	end

	-- shadow_crash,if=!variable.holding_crash&dot.vampiric_touch.refreshable;
	if talents[SH.ShadowCrash] and cooldown[SH.ShadowCrash].ready and (not holdingCrash and debuff[SH.VampiricTouch].refreshable) then
		return SH.ShadowCrash;
	end

	-- vampiric_touch,target_if=min:remains,if=refreshable&target.time_to_die>=12&(cooldown.shadow_crash.remains>=dot.vampiric_touch.remains&!action.shadow_crash.in_flight|variable.holding_crash|!talent.whispering_shadows);
	if currentSpell ~= SH.VampiricTouch and (debuff[SH.VampiricTouch].refreshable and timeToDie >= 12 and ( cooldown[SH.ShadowCrash].remains >= debuff[SH.VampiricTouch].remains and not inFlight or holdingCrash or not talents[SH.WhisperingShadows] )) then
		return SH.VampiricTouch;
	end

	-- shadow_word_death,if=variable.dots_up&talent.inescapable_torment&pet.fiend.active&((!talent.insidious_ire&!talent.idol_of_yoggsaron)|buff.deathspeaker.up);
	if talents[SH.ShadowWordDeath] and cooldown[SH.ShadowWordDeath].ready and mana >= 250 and (dotsUp and talents[SH.InescapableTorment] and fiendActive and ( ( not talents[SH.InsidiousIre] and not talents[SH.IdolOfYoggsaron] ) or buff[SH.Deathspeaker].up )) then
		return SH.ShadowWordDeath;
	end

	-- mind_spike_insanity,if=variable.dots_up&cooldown.mind_blast.full_recharge_time>=gcd*3&talent.idol_of_cthun&(!cooldown.void_torrent.up|!talent.void_torrent);
	if dotsUp and cooldown[SH.MindBlast].fullRecharge >= gcd * 3 and talents[SH.IdolOfCthun] and ( not cooldown[SH.VoidTorrent].up or not talents[SH.VoidTorrent] ) then
		return SH.MindSpikeInsanity;
	end

	-- mind_flay,if=buff.mind_flay_insanity.up&variable.dots_up&cooldown.mind_blast.full_recharge_time>=gcd*3&talent.idol_of_cthun&(!cooldown.void_torrent.up|!talent.void_torrent);
	if buff[SH.MindFlayInsanity].up and dotsUp and cooldown[SH.MindBlast].fullRecharge >= gcd * 3 and talents[SH.IdolOfCthun] and ( not cooldown[SH.VoidTorrent].up or not talents[SH.VoidTorrent] ) then
		return SH.MindFlay;
	end

	-- mind_blast,if=variable.dots_up&(!buff.mind_devourer.up|cooldown.void_eruption.up&talent.void_eruption);
	if cooldown[SH.MindBlast].ready and mana >= 0 and currentSpell ~= SH.MindBlast and (dotsUp and ( not buff[SH.MindDevourer].up or cooldown[SH.VoidEruption].up and talents[SH.VoidEruption] )) then
		return SH.MindBlast;
	end

	-- void_torrent,if=!variable.holding_crash,target_if=dot.vampiric_touch.ticking&dot.shadow_word_pain.ticking&dot.devouring_plague.remains>=2.5;
	if talents[SH.VoidTorrent] and cooldown[SH.VoidTorrent].ready and (not holdingCrash) then
		return SH.VoidTorrent;
	end

	-- mindgames,target_if=variable.all_dots_up&dot.devouring_plague.remains>=cast_time;
	if talents[SH.Mindgames] and cooldown[SH.Mindgames].ready and mana >= 1000 and currentSpell ~= SH.Mindgames then
		return SH.Mindgames;
	end

	-- call_action_list,name=filler;
	local result = Priest:ShadowFiller();
	if result then
		return result;
	end
end

function Priest:ShadowMainVariables()
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

	-- variable,name=dots_up,op=set,value=(dot.shadow_word_pain.ticking&dot.vampiric_touch.ticking)|action.shadow_crash.in_flight&talent.whispering_shadows;
	local dotsUp = ( debuff[SH.ShadowWordPain].up and debuff[SH.VampiricTouch].up ) or inFlight and talents[SH.WhisperingShadows];

	-- variable,name=all_dots_up,op=set,value=dot.shadow_word_pain.ticking&dot.vampiric_touch.ticking&dot.devouring_plague.ticking;
	local allDotsUp = debuff[SH.ShadowWordPain].up and debuff[SH.VampiricTouch].up and debuff[SH.DevouringPlague].up;

	-- variable,name=pool_for_cds,op=set,value=(cooldown.void_eruption.remains<=gcd.max*3&talent.void_eruption|cooldown.dark_ascension.up&talent.dark_ascension)|talent.void_torrent&talent.psychic_link&cooldown.void_torrent.remains<=4&(!raid_event.adds.exists&spell_targets.vampiric_touch>1|raid_event.adds.in<=5|raid_event.adds.remains>=6&!variable.holding_crash)&!buff.voidform.up;
	local poolForCds = ( cooldown[SH.VoidEruption].remains <= gcd * 3 and talents[SH.VoidEruption] or cooldown[SH.DarkAscension].up and talents[SH.DarkAscension] ) or talents[SH.VoidTorrent] and talents[SH.PsychicLink] and cooldown[SH.VoidTorrent].remains <= 4 and ( not targets > 1 and targets > 1 and not holdingCrash ) and not buff[SH.Voidform].up;
end

function Priest:ShadowPlTorrent()
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
	local gcd = fd.gcd;
	local insanity = UnitPower('player', Enum.PowerType.Insanity);
	local insanityMax = UnitPowerMax('player', Enum.PowerType.Insanity);
	local insanityPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local insanityRegen = select(2,GetPowerRegen());
	local insanityRegenCombined = insanityRegen + insanity;
	local insanityDeficit = UnitPowerMax('player', Enum.PowerType.Insanity) - insanity;
	local insanityTimeToMax = insanityMax - insanity / insanityRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- void_bolt;
	-- SH.VoidBolt;

	-- vampiric_touch,if=remains<=6&cooldown.void_torrent.remains<gcd*2;
	if currentSpell ~= SH.VampiricTouch and (debuff[SH.VampiricTouch].remains <= 6 and cooldown[SH.VoidTorrent].remains < gcd * 2) then
		return SH.VampiricTouch;
	end

	-- devouring_plague,if=remains<=4&cooldown.void_torrent.remains<gcd*2;
	if talents[SH.DevouringPlague] and insanity >= 50 and (debuff[SH.DevouringPlague].remains <= 4 and cooldown[SH.VoidTorrent].remains < gcd * 2) then
		return SH.DevouringPlague;
	end

	-- mind_blast,if=!talent.mindgames|cooldown.mindgames.remains>=3&!prev_gcd.1.mind_blast;
	if cooldown[SH.MindBlast].ready and mana >= 0 and currentSpell ~= SH.MindBlast and (not talents[SH.Mindgames] or cooldown[SH.Mindgames].remains >= 3 and not spellHistory[1] == SH.MindBlast) then
		return SH.MindBlast;
	end

	-- void_torrent,if=dot.vampiric_touch.ticking&dot.shadow_word_pain.ticking|buff.voidform.up;
	if talents[SH.VoidTorrent] and cooldown[SH.VoidTorrent].ready and (debuff[SH.VampiricTouch].up and debuff[SH.ShadowWordPain].up or buff[SH.Voidform].up) then
		return SH.VoidTorrent;
	end

	-- mindgames,if=dot.vampiric_touch.ticking&dot.shadow_word_pain.ticking&dot.devouring_plague.ticking|buff.voidform.up;
	if talents[SH.Mindgames] and cooldown[SH.Mindgames].ready and mana >= 1000 and currentSpell ~= SH.Mindgames and (debuff[SH.VampiricTouch].up and debuff[SH.ShadowWordPain].up and debuff[SH.DevouringPlague].up or buff[SH.Voidform].up) then
		return SH.Mindgames;
	end
end

function Priest:ShadowTrinkets()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
end


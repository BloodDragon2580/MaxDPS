local _, addonTable = ...;

-- @type MaxDps;
if not MaxDps then return end;
local Hunter = addonTable.Hunter;
local MaxDps = MaxDps;

local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;

local itemID = GetInventoryItemID('player', INVSLOT_MAINHAND);

local mainHandSubClassID = itemID and  select(13, GetItemInfo(itemID));

local TwoHanderWepCheck = mainHandSubClassID and (mainHandSubClassID == 1 or mainHandSubClassID == 5 or mainHandSubClassID == 8 or mainHandSubClassID == 10);

local MM = {
	Salvo = 400456,
	AimedShot = 19434,
	Volley = 260243,
	WailingArrow = 392060,
	SteadyFocus = 193533,
	SteadyShot = 56641,
	Trueshot = 288613,
	Bullseye = 204089,
	TrickShots = 257621,
	LegacyOfTheWindrunners = 406425,
	WindrunnersGuidance = 378905,
	KillShot = 53351,
	SteelTrap = 162488,
	SerpentSting = 271788,
	SerpentstalkersTrickery = 378888,
	ExplosiveShot = 212431,
	Stampede = 201430,
	DeathChakram = 375891,
	RapidFire = 257044,
	SurgingShots = 391559,
	Multishot = 257620,
	PreciseShots = 260240,
	ChimaeraShot = 342049,
	KillCommand = 34026,
	ArcaneShot = 185358,
	RazorFragments = 384790,
	HydrasBite = 260241,
	Barrage = 120360,
	Bulletstorm = 389019,
	PoisonInjection = 378014,
};
local A = {
};
function Hunter:Marksmanship()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local timeToDie = fd.timeToDie;

	-- variable,name=trueshot_ready,value=cooldown.trueshot.ready&buff.trueshot.down&(!raid_event.adds.exists&(!talent.bullseye|fight_remains>cooldown.trueshot.duration_guess+buff.trueshot.duration%2|buff.bullseye.stack=buff.bullseye.max_stack)&(!trinket.1.has_use_buff|trinket.1.cooldown.remains>30|trinket.1.cooldown.ready)&(!trinket.2.has_use_buff|trinket.2.cooldown.remains>30|trinket.2.cooldown.ready)|raid_event.adds.exists&(!raid_event.adds.up&(raid_event.adds.duration+raid_event.adds.in<25|raid_event.adds.in>60)|raid_event.adds.up&raid_event.adds.remains>10)|active_enemies>1|fight_remains<25);
	local trueshotReady = cooldown[MM.Trueshot].ready and not buff[MM.Trueshot].up and ( not targets > 1 and ( not talents[MM.Bullseye] or timeToDie > cooldown[MM.Trueshot].duration + buff[MM.Trueshot].duration / 2 or buff[MM.Bullseye].count == buff[MM.Bullseye].maxStacks ) or targets > 1 or timeToDie < 25 );

	-- call_action_list,name=cds;
	local result = Hunter:MarksmanshipCds();
	if result then
		return result;
	end

	-- call_action_list,name=trinkets;

	-- call_action_list,name=st,if=active_enemies<3|!talent.trick_shots;
	if targets < 3 or not talents[MM.TrickShots] then
		local result = Hunter:MarksmanshipSt();
		if result then
			return result;
		end
	end

	-- call_action_list,name=trickshots,if=active_enemies>2;
	if targets > 2 then
		local result = Hunter:MarksmanshipTrickshots();
		if result then
			return result;
		end
	end
end
function Hunter:MarksmanshipCds()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;

	-- salvo,if=active_enemies>2|cooldown.volley.remains<10;
	if talents[MM.Salvo] and cooldown[MM.Salvo].ready and (targets > 2 or cooldown[MM.Volley].remains < 10) then
		return MM.Salvo;
	end
end

function Hunter:MarksmanshipSt()
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
	local focus = UnitPower('player', Enum.PowerType.Focus);
	local focusMax = UnitPowerMax('player', Enum.PowerType.Focus);
	local focusPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local focusRegen = select(2,GetPowerRegen());
	local focusRegenCombined = focusRegen + focus;
	local focusDeficit = UnitPowerMax('player', Enum.PowerType.Focus) - focus;
	local focusTimeToMax = focusMax - focus / focusRegen;

	-- steady_shot,if=talent.steady_focus&(steady_focus_count&buff.steady_focus.remains<5|buff.steady_focus.down&!buff.trueshot.up);
	if currentSpell ~= MM.SteadyShot and (talents[MM.SteadyFocus] and ( buff[MM.SteadyFocus].remains < 5 or not buff[MM.SteadyFocus].up and not buff[MM.Trueshot].up )) then
		return MM.SteadyShot;
	end

	-- aimed_shot,if=buff.trueshot.up&full_recharge_time<gcd+cast_time&talent.legacy_of_the_windrunners&talent.windrunners_guidance;
	if talents[MM.AimedShot] and cooldown[MM.AimedShot].ready and focus >= 35 and currentSpell ~= MM.AimedShot and (buff[MM.Trueshot].up and cooldown[MM.AimedShot].fullRecharge < gcd + timeShift and talents[MM.LegacyOfTheWindrunners] and talents[MM.WindrunnersGuidance]) then
		return MM.AimedShot;
	end

	-- kill_shot,if=buff.trueshot.down;
	if talents[MM.KillShot] and cooldown[MM.KillShot].ready and focus >= 10 and (not buff[MM.Trueshot].up) then
		return MM.KillShot;
	end

	-- volley,if=buff.salvo.up;
	if talents[MM.Volley] and cooldown[MM.Volley].ready and (buff[MM.Salvo].up) then
		return MM.Volley;
	end

	-- steel_trap,if=buff.trueshot.down;
	if talents[MM.SteelTrap] and cooldown[MM.SteelTrap].ready and (not buff[MM.Trueshot].up) then
		return MM.SteelTrap;
	end

	-- serpent_sting,target_if=min:dot.serpent_sting.remains,if=refreshable&!talent.serpentstalkers_trickery&buff.trueshot.down;
	if talents[MM.SerpentSting] and focus >= 10 and (debuff[MM.SerpentSting].refreshable and not talents[MM.SerpentstalkersTrickery] and not buff[MM.Trueshot].up) then
		return MM.SerpentSting;
	end

	-- explosive_shot;
	if talents[MM.ExplosiveShot] and cooldown[MM.ExplosiveShot].ready and focus >= 20 then
		return MM.ExplosiveShot;
	end

	-- stampede;
	if talents[MM.Stampede] and cooldown[MM.Stampede].ready then
		return MM.Stampede;
	end

	-- death_chakram;
	if talents[MM.DeathChakram] and cooldown[MM.DeathChakram].ready then
		return MM.DeathChakram;
	end

	-- wailing_arrow,if=active_enemies>1;
	if talents[MM.WailingArrow] and cooldown[MM.WailingArrow].ready and focus >= 15 and currentSpell ~= MM.WailingArrow and (targets > 1) then
		return MM.WailingArrow;
	end

	-- rapid_fire,if=talent.surging_shots|action.aimed_shot.full_recharge_time>action.aimed_shot.cast_time+cast_time;
	if talents[MM.RapidFire] and cooldown[MM.RapidFire].ready and (talents[MM.SurgingShots] or cooldown[MM.AimedShot].fullRecharge > timeShift + timeShift) then
		return MM.RapidFire;
	end

	-- kill_shot;
	if talents[MM.KillShot] and cooldown[MM.KillShot].ready and focus >= 10 then
		return MM.KillShot;
	end

	-- trueshot,if=variable.trueshot_ready;
	if talents[MM.Trueshot] and cooldown[MM.Trueshot].ready and (trueshotReady) then
		return MM.Trueshot;
	end

	-- multishot,if=buff.salvo.up&!talent.volley;
	if talents[MM.Multishot] and focus >= 20 and (buff[MM.Salvo].up and not talents[MM.Volley]) then
		return MM.Multishot;
	end

	-- aimed_shot,target_if=min:dot.serpent_sting.remains+action.serpent_sting.in_flight_to_target*99,if=talent.serpentstalkers_trickery&(buff.precise_shots.down|(buff.trueshot.up|full_recharge_time<gcd+cast_time)&(!talent.chimaera_shot|active_enemies<2|ca_active)|buff.trick_shots.remains>execute_time&active_enemies>1);
	if talents[MM.AimedShot] and cooldown[MM.AimedShot].ready and focus >= 35 and currentSpell ~= MM.AimedShot and (talents[MM.SerpentstalkersTrickery] and ( not buff[MM.PreciseShots].up or ( buff[MM.Trueshot].up or cooldown[MM.AimedShot].fullRecharge < gcd + timeShift ) and ( not talents[MM.ChimaeraShot] or targets < 2 ) or buff[MM.TrickShots].remains > timeShift and targets > 1 )) then
		return MM.AimedShot;
	end

	-- aimed_shot,target_if=max:debuff.latent_poison.stack,if=buff.precise_shots.down|(buff.trueshot.up|full_recharge_time<gcd+cast_time)&(!talent.chimaera_shot|active_enemies<2|ca_active)|buff.trick_shots.remains>execute_time&active_enemies>1;
	if talents[MM.AimedShot] and cooldown[MM.AimedShot].ready and focus >= 35 and currentSpell ~= MM.AimedShot and (not buff[MM.PreciseShots].up or ( buff[MM.Trueshot].up or cooldown[MM.AimedShot].fullRecharge < gcd + timeShift ) and ( not talents[MM.ChimaeraShot] or targets < 2 ) or buff[MM.TrickShots].remains > timeShift and targets > 1) then
		return MM.AimedShot;
	end

	-- volley;
	if talents[MM.Volley] and cooldown[MM.Volley].ready then
		return MM.Volley;
	end

	-- rapid_fire;
	if talents[MM.RapidFire] and cooldown[MM.RapidFire].ready then
		return MM.RapidFire;
	end

	-- wailing_arrow,if=buff.trueshot.down;
	if talents[MM.WailingArrow] and cooldown[MM.WailingArrow].ready and focus >= 15 and currentSpell ~= MM.WailingArrow and (not buff[MM.Trueshot].up) then
		return MM.WailingArrow;
	end

	-- kill_command,if=buff.trueshot.down;
	if talents[MM.KillCommand] and cooldown[MM.KillCommand].ready and focus >= 30 and (not buff[MM.Trueshot].up) then
		return MM.KillCommand;
	end

	-- steel_trap;
	if talents[MM.SteelTrap] and cooldown[MM.SteelTrap].ready then
		return MM.SteelTrap;
	end

	-- chimaera_shot,if=buff.precise_shots.up|focus>cost+action.aimed_shot.cost;
	if talents[MM.ChimaeraShot] and focus >= 20 and (buff[MM.PreciseShots].up or focus > cooldown[MM.ChimaeraShot].cost + cooldown[MM.AimedShot].cost) then
		return MM.ChimaeraShot;
	end

	-- arcane_shot,if=buff.precise_shots.up|focus>cost+action.aimed_shot.cost;
	if focus >= 20 and (buff[MM.PreciseShots].up or focus > cooldown[MM.ArcaneShot].cost + cooldown[MM.AimedShot].cost) then
		return MM.ArcaneShot;
	end

	-- steady_shot;
	if currentSpell ~= MM.SteadyShot then
		return MM.SteadyShot;
	end
end

function Hunter:MarksmanshipTrickshots()
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
	local focus = UnitPower('player', Enum.PowerType.Focus);
	local focusMax = UnitPowerMax('player', Enum.PowerType.Focus);
	local focusPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local focusRegen = select(2,GetPowerRegen());
	local focusRegenCombined = focusRegen + focus;
	local focusDeficit = UnitPowerMax('player', Enum.PowerType.Focus) - focus;
	local focusTimeToMax = focusMax - focus / focusRegen;

	-- steady_shot,if=talent.steady_focus&steady_focus_count&buff.steady_focus.remains<8;
	if currentSpell ~= MM.SteadyShot and (talents[MM.SteadyFocus] and buff[MM.SteadyFocus].remains < 8) then
		return MM.SteadyShot;
	end

	-- kill_shot,if=buff.razor_fragments.up;
	if talents[MM.KillShot] and cooldown[MM.KillShot].ready and focus >= 10 and (buff[MM.RazorFragments].up) then
		return MM.KillShot;
	end

	-- explosive_shot;
	if talents[MM.ExplosiveShot] and cooldown[MM.ExplosiveShot].ready and focus >= 20 then
		return MM.ExplosiveShot;
	end

	-- death_chakram;
	if talents[MM.DeathChakram] and cooldown[MM.DeathChakram].ready then
		return MM.DeathChakram;
	end

	-- stampede;
	if talents[MM.Stampede] and cooldown[MM.Stampede].ready then
		return MM.Stampede;
	end

	-- wailing_arrow;
	if talents[MM.WailingArrow] and cooldown[MM.WailingArrow].ready and focus >= 15 and currentSpell ~= MM.WailingArrow then
		return MM.WailingArrow;
	end

	-- serpent_sting,target_if=min:dot.serpent_sting.remains,if=refreshable&talent.hydras_bite&!talent.serpentstalkers_trickery;
	if talents[MM.SerpentSting] and focus >= 10 and (debuff[MM.SerpentSting].refreshable and talents[MM.HydrasBite] and not talents[MM.SerpentstalkersTrickery]) then
		return MM.SerpentSting;
	end

	-- barrage,if=active_enemies>7;
	if talents[MM.Barrage] and cooldown[MM.Barrage].ready and focus >= 30 and (targets > 7) then
		return MM.Barrage;
	end

	-- volley;
	if talents[MM.Volley] and cooldown[MM.Volley].ready then
		return MM.Volley;
	end

	-- trueshot,if=buff.trueshot.down;
	if talents[MM.Trueshot] and cooldown[MM.Trueshot].ready and (not buff[MM.Trueshot].up) then
		return MM.Trueshot;
	end

	-- rapid_fire,if=buff.trick_shots.remains>=execute_time&talent.surging_shots;
	if talents[MM.RapidFire] and cooldown[MM.RapidFire].ready and (buff[MM.TrickShots].remains >= timeShift and talents[MM.SurgingShots]) then
		return MM.RapidFire;
	end

	-- aimed_shot,target_if=min:dot.serpent_sting.remains+action.serpent_sting.in_flight_to_target*99,if=talent.serpentstalkers_trickery&(buff.trick_shots.remains>=execute_time&(buff.precise_shots.down|buff.trueshot.up|full_recharge_time<cast_time+gcd));
	if talents[MM.AimedShot] and cooldown[MM.AimedShot].ready and focus >= 35 and currentSpell ~= MM.AimedShot and (talents[MM.SerpentstalkersTrickery] and ( buff[MM.TrickShots].remains >= timeShift and ( not buff[MM.PreciseShots].up or buff[MM.Trueshot].up or cooldown[MM.AimedShot].fullRecharge < timeShift + gcd ) )) then
		return MM.AimedShot;
	end

	-- aimed_shot,target_if=max:debuff.latent_poison.stack,if=(buff.trick_shots.remains>=execute_time&(buff.precise_shots.down|buff.trueshot.up|full_recharge_time<cast_time+gcd));
	if talents[MM.AimedShot] and cooldown[MM.AimedShot].ready and focus >= 35 and currentSpell ~= MM.AimedShot and (( buff[MM.TrickShots].remains >= timeShift and ( not buff[MM.PreciseShots].up or buff[MM.Trueshot].up or cooldown[MM.AimedShot].fullRecharge < timeShift + gcd ) )) then
		return MM.AimedShot;
	end

	-- rapid_fire,if=buff.trick_shots.remains>=execute_time;
	if talents[MM.RapidFire] and cooldown[MM.RapidFire].ready and (buff[MM.TrickShots].remains >= timeShift) then
		return MM.RapidFire;
	end

	-- chimaera_shot,if=buff.trick_shots.up&buff.precise_shots.up&focus>cost+action.aimed_shot.cost&active_enemies<4;
	if talents[MM.ChimaeraShot] and focus >= 20 and (buff[MM.TrickShots].up and buff[MM.PreciseShots].up and focus > cooldown[MM.ChimaeraShot].cost + cooldown[MM.AimedShot].cost and targets < 4) then
		return MM.ChimaeraShot;
	end

	-- multishot,if=buff.trick_shots.down|(buff.precise_shots.up|buff.bulletstorm.stack=10)&focus>cost+action.aimed_shot.cost;
	if talents[MM.Multishot] and focus >= 20 and (not buff[MM.TrickShots].up or ( buff[MM.PreciseShots].up or buff[MM.Bulletstorm].count == 10 ) and focus > cooldown[MM.Multishot].cost + cooldown[MM.AimedShot].cost) then
		return MM.Multishot;
	end

	-- serpent_sting,target_if=min:dot.serpent_sting.remains,if=refreshable&talent.poison_injection&!talent.serpentstalkers_trickery;
	if talents[MM.SerpentSting] and focus >= 10 and (debuff[MM.SerpentSting].refreshable and talents[MM.PoisonInjection] and not talents[MM.SerpentstalkersTrickery]) then
		return MM.SerpentSting;
	end

	-- steel_trap,if=buff.trueshot.down;
	if talents[MM.SteelTrap] and cooldown[MM.SteelTrap].ready and (not buff[MM.Trueshot].up) then
		return MM.SteelTrap;
	end

	-- kill_shot,if=focus>cost+action.aimed_shot.cost;
	if talents[MM.KillShot] and cooldown[MM.KillShot].ready and focus >= 10 and (focus > cooldown[MM.KillShot].cost + cooldown[MM.AimedShot].cost) then
		return MM.KillShot;
	end

	-- multishot,if=focus>cost+action.aimed_shot.cost;
	if talents[MM.Multishot] and focus >= 20 and (focus > cooldown[MM.Multishot].cost + cooldown[MM.AimedShot].cost) then
		return MM.Multishot;
	end

	-- steady_shot;
	if currentSpell ~= MM.SteadyShot then
		return MM.SteadyShot;
	end
end

function Hunter:MarksmanshipTrinkets()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;

	-- variable,name=sync_ready,value=variable.trueshot_ready;
	local syncReady = trueshotReady;

	-- variable,name=sync_active,value=buff.trueshot.up;
	local syncActive = buff[MM.Trueshot].up;

	-- variable,name=sync_remains,value=cooldown.trueshot.remains;
	local syncRemains = cooldown[MM.Trueshot].remains;

	-- variable,name=trinket_1_stronger,value=!trinket.2.has_cooldown|trinket.1.has_use_buff&(!trinket.2.has_use_buff|trinket.2.cooldown.duration<trinket.1.cooldown.duration|trinket.2.cast_time<trinket.1.cast_time|trinket.2.cast_time=trinket.1.cast_time&trinket.2.cooldown.duration=trinket.1.cooldown.duration)|!trinket.1.has_use_buff&(!trinket.2.has_use_buff&(trinket.2.cooldown.duration<trinket.1.cooldown.duration|trinket.2.cast_time<trinket.1.cast_time|trinket.2.cast_time=trinket.1.cast_time&trinket.2.cooldown.duration=trinket.1.cooldown.duration));
	--local trinket1Stronger = not ( not == == ) or not ( not ( == == ) );

	-- variable,name=trinket_2_stronger,value=!trinket.1.has_cooldown|trinket.2.has_use_buff&(!trinket.1.has_use_buff|trinket.1.cooldown.duration<trinket.2.cooldown.duration|trinket.1.cast_time<trinket.2.cast_time|trinket.1.cast_time=trinket.2.cast_time&trinket.1.cooldown.duration=trinket.2.cooldown.duration)|!trinket.2.has_use_buff&(!trinket.1.has_use_buff&(trinket.1.cooldown.duration<trinket.2.cooldown.duration|trinket.1.cast_time<trinket.2.cast_time|trinket.1.cast_time=trinket.2.cast_time&trinket.1.cooldown.duration=trinket.2.cooldown.duration));
	--local trinket2Stronger = not ( not == == ) or not ( not ( == == ) );
end


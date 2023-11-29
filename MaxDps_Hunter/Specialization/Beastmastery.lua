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

local BM = {
	SteelTrap = 162488,
	WailingArrow = 392060,
	BeastCleave = 115939,
	BarbedShot = 217200,
	ScentOfBlood = 193532,
	BestialWrath = 19574,
	Multishot = 2643,
	KillCommand = 34026,
	KillCleave = 378207,
	CallOfTheWild = 359844,
	ExplosiveShot = 212431,
	Stampede = 201430,
	Bloodshed = 321530,
	DeathChakram = 375891,
	AMurderOfCrows = 131894,
	WildInstincts = 378442,
	WildCall = 185789,
	DireBeast = 120679,
	SerpentSting = 271788,
	Barrage = 120360,
	AspectOfTheWild = 193530,
	CobraShot = 193455,
	KillShot = 53351,
	AlphaPredator = 269737,
};
local A = {
};
function Hunter:BeastMastery()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;

	-- call_action_list,name=cds;
	local result = Hunter:BeastMasteryCds();
	if result then
		return result;
	end

	-- call_action_list,name=trinkets;

	-- call_action_list,name=st,if=active_enemies<2|!talent.beast_cleave&active_enemies<3;
	if targets < 2 or not talents[BM.BeastCleave] and targets < 3 then
		local result = Hunter:BeastMasterySt();
		if result then
			return result;
		end
	end

	-- call_action_list,name=cleave,if=active_enemies>2|talent.beast_cleave&active_enemies>1;
	if targets > 2 or talents[BM.BeastCleave] and targets > 1 then
		local result = Hunter:BeastMasteryCleave();
		if result then
			return result;
		end
	end
end
function Hunter:BeastMasteryCds()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
end

function Hunter:BeastMasteryCleave()
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
	local focus = UnitPower('player', Enum.PowerType.Focus);
	local focusMax = UnitPowerMax('player', Enum.PowerType.Focus);
	local focusPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local focusRegen = select(2,GetPowerRegen());
	local focusRegenCombined = focusRegen + focus;
	local focusDeficit = UnitPowerMax('player', Enum.PowerType.Focus) - focus;
	local focusTimeToMax = focusMax - focus / focusRegen;

	-- barbed_shot,target_if=max:debuff.latent_poison.stack,if=debuff.latent_poison.stack>9&(pet.main.buff.frenzy.up&pet.main.buff.frenzy.remains<=gcd+0.25|talent.scent_of_blood&cooldown.bestial_wrath.remains<12+gcd|full_recharge_time<gcd&cooldown.bestial_wrath.remains);
	if talents[BM.BarbedShot] and cooldown[BM.BarbedShot].ready and (debuff[BM.LatentPoison].count > 9 and ( buff[Frenzy].up and buff[Frenzy].remains <= gcd + 0.25 or talents[BM.ScentOfBlood] and cooldown[BM.BestialWrath].remains < 12 + gcd or cooldown[BM.BarbedShot].fullRecharge < gcd and cooldown[BM.BestialWrath].remains )) then
		return BM.BarbedShot;
	end

	-- barbed_shot,target_if=min:dot.barbed_shot.remains,if=pet.main.buff.frenzy.up&pet.main.buff.frenzy.remains<=gcd+0.25|talent.scent_of_blood&cooldown.bestial_wrath.remains<12+gcd|full_recharge_time<gcd&cooldown.bestial_wrath.remains;
	if talents[BM.BarbedShot] and cooldown[BM.BarbedShot].ready and (buff[Frenzy].up and buff[Frenzy].remains <= gcd + 0.25 or talents[BM.ScentOfBlood] and cooldown[BM.BestialWrath].remains < 12 + gcd or cooldown[BM.BarbedShot].fullRecharge < gcd and cooldown[BM.BestialWrath].remains) then
		return BM.BarbedShot;
	end

	-- multishot,if=gcd-pet.main.buff.beast_cleave.remains>0.25;
	if talents[BM.Multishot] and focus >= 40 and (gcd - buff[BeastCleave].remains > 0.25) then
		return BM.Multishot;
	end

	-- bestial_wrath;
	if talents[BM.BestialWrath] and cooldown[BM.BestialWrath].ready then
		return BM.BestialWrath;
	end

	-- kill_command,if=talent.kill_cleave;
	if talents[BM.KillCommand] and cooldown[BM.KillCommand].ready and focus >= 30 and (talents[BM.KillCleave]) then
		return BM.KillCommand;
	end

	-- call_of_the_wild;
	if talents[BM.CallOfTheWild] and cooldown[BM.CallOfTheWild].ready then
		return BM.CallOfTheWild;
	end

	-- explosive_shot;
	if talents[BM.ExplosiveShot] and cooldown[BM.ExplosiveShot].ready and focus >= 20 then
		return BM.ExplosiveShot;
	end

	-- stampede,if=buff.bestial_wrath.up|target.time_to_die<15;
	if talents[BM.Stampede] and cooldown[BM.Stampede].ready and (buff[BM.BestialWrath].up or timeToDie < 15) then
		return BM.Stampede;
	end

	-- bloodshed;
	if talents[BM.Bloodshed] and cooldown[BM.Bloodshed].ready then
		return BM.Bloodshed;
	end

	-- death_chakram;
	if talents[BM.DeathChakram] and cooldown[BM.DeathChakram].ready then
		return BM.DeathChakram;
	end

	-- steel_trap;
	if talents[BM.SteelTrap] and cooldown[BM.SteelTrap].ready then
		return BM.SteelTrap;
	end

	-- a_murder_of_crows;
	if talents[BM.AMurderOfCrows] and cooldown[BM.AMurderOfCrows].ready and focus >= 30 then
		return BM.AMurderOfCrows;
	end

	-- barbed_shot,target_if=max:debuff.latent_poison.stack,if=debuff.latent_poison.stack>9&(talent.wild_instincts&buff.call_of_the_wild.up|fight_remains<9|talent.wild_call&charges_fractional>1.2);
	if talents[BM.BarbedShot] and cooldown[BM.BarbedShot].ready and (debuff[BM.LatentPoison].count > 9 and ( talents[BM.WildInstincts] and buff[BM.CallOfTheWild].up or timeToDie < 9 or talents[BM.WildCall] and cooldown[BM.BarbedShot].charges > 1.2 )) then
		return BM.BarbedShot;
	end

	-- barbed_shot,target_if=min:dot.barbed_shot.remains,if=talent.wild_instincts&buff.call_of_the_wild.up|fight_remains<9|talent.wild_call&charges_fractional>1.2;
	if talents[BM.BarbedShot] and cooldown[BM.BarbedShot].ready and (talents[BM.WildInstincts] and buff[BM.CallOfTheWild].up or timeToDie < 9 or talents[BM.WildCall] and cooldown[BM.BarbedShot].charges > 1.2) then
		return BM.BarbedShot;
	end

	-- kill_command;
	if talents[BM.KillCommand] and cooldown[BM.KillCommand].ready and focus >= 30 then
		return BM.KillCommand;
	end

	-- dire_beast;
	if talents[BM.DireBeast] and cooldown[BM.DireBeast].ready then
		return BM.DireBeast;
	end

	-- serpent_sting,target_if=min:remains,if=refreshable&target.time_to_die>duration;
	if talents[BM.SerpentSting] and focus >= 10 and (debuff[BM.SerpentSting].refreshable and timeToDie > cooldown[BM.SerpentSting].duration) then
		return BM.SerpentSting;
	end

	-- barrage,if=pet.main.buff.frenzy.remains>execute_time;
	if talents[BM.Barrage] and cooldown[BM.Barrage].ready and focus >= 60 and (buff[Frenzy].remains > timeShift) then
		return BM.Barrage;
	end

	-- multishot,if=pet.main.buff.beast_cleave.remains<gcd*2;
	if talents[BM.Multishot] and focus >= 40 and (buff[BeastCleave].remains < gcd * 2) then
		return BM.Multishot;
	end

	-- aspect_of_the_wild;
	if talents[BM.AspectOfTheWild] and cooldown[BM.AspectOfTheWild].ready then
		return BM.AspectOfTheWild;
	end

	-- cobra_shot,if=focus.time_to_max<gcd*2|buff.aspect_of_the_wild.up&focus.time_to_max<gcd*4;
	if talents[BM.CobraShot] and focus >= 35 and (focusTimeToMax < gcd * 2 or buff[BM.AspectOfTheWild].up and focusTimeToMax < gcd * 4) then
		return BM.CobraShot;
	end

	-- wailing_arrow,if=pet.main.buff.frenzy.remains>execute_time|fight_remains<5;
	if talents[BM.WailingArrow] and cooldown[BM.WailingArrow].ready and focus >= 15 and currentSpell ~= BM.WailingArrow and (buff[Frenzy].remains > timeShift or timeToDie < 5) then
		return BM.WailingArrow;
	end

	-- kill_shot;
	if talents[BM.KillShot] and cooldown[BM.KillShot].ready and focus >= 10 then
		return BM.KillShot;
	end
end

function Hunter:BeastMasterySt()
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
	local focus = UnitPower('player', Enum.PowerType.Focus);
	local focusMax = UnitPowerMax('player', Enum.PowerType.Focus);
	local focusPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local focusRegen = select(2,GetPowerRegen());
	local focusRegenCombined = focusRegen + focus;
	local focusDeficit = UnitPowerMax('player', Enum.PowerType.Focus) - focus;
	local focusTimeToMax = focusMax - focus / focusRegen;

	-- barbed_shot,target_if=min:dot.barbed_shot.remains,if=pet.main.buff.frenzy.up&pet.main.buff.frenzy.remains<=gcd+0.25|talent.scent_of_blood&pet.main.buff.frenzy.stack<3&cooldown.bestial_wrath.ready;
	if talents[BM.BarbedShot] and cooldown[BM.BarbedShot].ready and (buff[Frenzy].up and buff[Frenzy].remains <= gcd + 0.25 or talents[BM.ScentOfBlood] and buff[Frenzy].stack < 3 and cooldown[BM.BestialWrath].ready) then
		return BM.BarbedShot;
	end

	-- kill_command,if=full_recharge_time<gcd&talent.alpha_predator;
	if talents[BM.KillCommand] and cooldown[BM.KillCommand].ready and focus >= 30 and (cooldown[BM.KillCommand].fullRecharge < gcd and talents[BM.AlphaPredator]) then
		return BM.KillCommand;
	end

	-- call_of_the_wild;
	if talents[BM.CallOfTheWild] and cooldown[BM.CallOfTheWild].ready then
		return BM.CallOfTheWild;
	end

	-- death_chakram;
	if talents[BM.DeathChakram] and cooldown[BM.DeathChakram].ready then
		return BM.DeathChakram;
	end

	-- bloodshed;
	if talents[BM.Bloodshed] and cooldown[BM.Bloodshed].ready then
		return BM.Bloodshed;
	end

	-- stampede;
	if talents[BM.Stampede] and cooldown[BM.Stampede].ready then
		return BM.Stampede;
	end

	-- a_murder_of_crows;
	if talents[BM.AMurderOfCrows] and cooldown[BM.AMurderOfCrows].ready and focus >= 30 then
		return BM.AMurderOfCrows;
	end

	-- steel_trap;
	if talents[BM.SteelTrap] and cooldown[BM.SteelTrap].ready then
		return BM.SteelTrap;
	end

	-- explosive_shot;
	if talents[BM.ExplosiveShot] and cooldown[BM.ExplosiveShot].ready and focus >= 20 then
		return BM.ExplosiveShot;
	end

	-- bestial_wrath;
	if talents[BM.BestialWrath] and cooldown[BM.BestialWrath].ready then
		return BM.BestialWrath;
	end

	-- kill_command;
	if talents[BM.KillCommand] and cooldown[BM.KillCommand].ready and focus >= 30 then
		return BM.KillCommand;
	end

	-- barbed_shot,target_if=min:dot.barbed_shot.remains,if=talent.wild_instincts&buff.call_of_the_wild.up|talent.wild_call&charges_fractional>1.4|full_recharge_time<gcd&cooldown.bestial_wrath.remains|talent.scent_of_blood&(cooldown.bestial_wrath.remains<12+gcd|full_recharge_time+gcd<8&cooldown.bestial_wrath.remains<24+(8-gcd)+full_recharge_time)|fight_remains<9;
	if talents[BM.BarbedShot] and cooldown[BM.BarbedShot].ready and (talents[BM.WildInstincts] and buff[BM.CallOfTheWild].up or talents[BM.WildCall] and cooldown[BM.BarbedShot].charges > 1.4 or cooldown[BM.BarbedShot].fullRecharge < gcd and cooldown[BM.BestialWrath].remains or talents[BM.ScentOfBlood] and ( cooldown[BM.BestialWrath].remains < 12 + gcd or cooldown[BM.BarbedShot].fullRecharge + gcd < 8 and cooldown[BM.BestialWrath].remains < 24 + ( 8 - gcd ) + cooldown[BM.BarbedShot].fullRecharge ) or timeToDie < 9) then
		return BM.BarbedShot;
	end

	-- dire_beast;
	if talents[BM.DireBeast] and cooldown[BM.DireBeast].ready then
		return BM.DireBeast;
	end

	-- serpent_sting,target_if=min:remains,if=refreshable&target.time_to_die>duration;
	if talents[BM.SerpentSting] and focus >= 10 and (debuff[BM.SerpentSting].refreshable and timeToDie > cooldown[BM.SerpentSting].duration) then
		return BM.SerpentSting;
	end

	-- kill_shot;
	if talents[BM.KillShot] and cooldown[BM.KillShot].ready and focus >= 10 then
		return BM.KillShot;
	end

	-- aspect_of_the_wild;
	if talents[BM.AspectOfTheWild] and cooldown[BM.AspectOfTheWild].ready then
		return BM.AspectOfTheWild;
	end

	-- cobra_shot;
	if talents[BM.CobraShot] and focus >= 35 then
		return BM.CobraShot;
	end

	-- wailing_arrow,if=pet.main.buff.frenzy.remains>execute_time|target.time_to_die<5;
	if talents[BM.WailingArrow] and cooldown[BM.WailingArrow].ready and focus >= 15 and currentSpell ~= BM.WailingArrow and (buff[Frenzy].remains > timeShift or timeToDie < 5) then
		return BM.WailingArrow;
	end
end

function Hunter:BeastMasteryTrinkets()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local spellHistory = fd.spellHistory;
	local talents = fd.talents;

	-- variable,name=sync_up,value=buff.call_of_the_wild.up|cooldown.call_of_the_wild.remains<2|!talent.call_of_the_wild&(prev_gcd.1.bestial_wrath|cooldown.bestial_wrath.remains_guess<2);
	local syncUp = buff[BM.CallOfTheWild].up or cooldown[BM.CallOfTheWild].remains < 2 or not talents[BM.CallOfTheWild] and ( spellHistory[1] == BM.BestialWrath or cooldown[BM.BestialWrath].remains < 2 );

	-- variable,name=sync_remains,op=setif,value=cooldown.bestial_wrath.remains_guess,value_else=cooldown.call_of_the_wild.remains,condition=!talent.call_of_the_wild;
	if not talents[BM.CallOfTheWild] then
		local syncRemains = cooldown[BM.BestialWrath].remains;
	else
		local syncRemains = cooldown[BM.CallOfTheWild].remains;
	end

	-- variable,name=trinket_1_stronger,value=!trinket.2.has_cooldown|trinket.1.has_use_buff&(!trinket.2.has_use_buff|trinket.2.cooldown.duration<trinket.1.cooldown.duration|trinket.2.cast_time<trinket.1.cast_time|trinket.2.cast_time=trinket.1.cast_time&trinket.2.cooldown.duration=trinket.1.cooldown.duration)|!trinket.1.has_use_buff&(!trinket.2.has_use_buff&(trinket.2.cooldown.duration<trinket.1.cooldown.duration|trinket.2.cast_time<trinket.1.cast_time|trinket.2.cast_time=trinket.1.cast_time&trinket.2.cooldown.duration=trinket.1.cooldown.duration));
	--local trinket1Stronger = not ( not == == ) or not ( not ( == == ) );

	-- variable,name=trinket_2_stronger,value=!trinket.1.has_cooldown|trinket.2.has_use_buff&(!trinket.1.has_use_buff|trinket.1.cooldown.duration<trinket.2.cooldown.duration|trinket.1.cast_time<trinket.2.cast_time|trinket.1.cast_time=trinket.2.cast_time&trinket.1.cooldown.duration=trinket.2.cooldown.duration)|!trinket.2.has_use_buff&(!trinket.1.has_use_buff&(trinket.1.cooldown.duration<trinket.2.cooldown.duration|trinket.1.cast_time<trinket.2.cast_time|trinket.1.cast_time=trinket.2.cast_time&trinket.1.cooldown.duration=trinket.2.cooldown.duration));
	--local trinket2Stronger = not ( not == == ) or not ( not ( == == ) );
end


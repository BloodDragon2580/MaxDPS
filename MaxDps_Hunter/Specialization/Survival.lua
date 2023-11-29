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

local SV = {
	MongooseBite = 259387,
	RaptorStrike = 186270,
	SteelTrap = 162488,
	Harpoon = 190925,
	TermsOfEngagement = 265895,
	Muzzle = 187707,
	AspectOfTheEagle = 186289,
	KillShot = 320976,
	CoordinatedAssaultEmpower = 361738,
	BirdsOfPrey = 260331,
	DeathChakram = 375891,
	WildfireBomb = 259495,
	Stampede = 201430,
	CoordinatedAssault = 360952,
	FuryOfTheEagle = 203415,
	ExplosiveShot = 212431,
	Carve = 187708,
	Butchery = 212436,
	ShrapnelBomb = 270335,
	InternalBleeding = 270343,
	WildfireInfusion = 271014,
	KillCommand = 259489,
	FlankingStrike = 269751,
	Spearhead = 360966,
	SerpentSting = 271788,
	VipersVenom = 268501,
	HydrasBite = 260241,
	ShreddedArmor = 410167,
	Bombardier = 389880,
	DeadlyDuo = 378962,
	PheromoneBomb = 270323,
	MongooseFury = 259388,
	AlphaPredator = 269737,
	CoordinatedKill = 385739,
	Ranger = 385695,
	RuthlessMarauder = 385718,
};
local A = {
};
function Hunter:Survival()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local targets = fd.targets and fd.targets or 1;

	-- call_action_list,name=cds;
	local result = Hunter:SurvivalCds();
	if result then
		return result;
	end

	-- call_action_list,name=st,if=active_enemies<3;
	if targets < 3 then
		local result = Hunter:SurvivalSt();
		if result then
			return result;
		end
	end

	-- call_action_list,name=cleave,if=active_enemies>2;
	if targets > 2 then
		local result = Hunter:SurvivalCleave();
		if result then
			return result;
		end
	end
end
function Hunter:SurvivalCds()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local talents = fd.talents;
	local focus = UnitPower('player', Enum.PowerType.Focus);
	local focusMax = UnitPowerMax('player', Enum.PowerType.Focus);
	local focusPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local focusRegen = select(2,GetPowerRegen());
	local focusRegenCombined = focusRegen + focus;
	local focusDeficit = UnitPowerMax('player', Enum.PowerType.Focus) - focus;
	local focusTimeToMax = focusMax - focus / focusRegen;

	-- harpoon,if=talent.terms_of_engagement.enabled&focus<focus.max;
	if talents[SV.Harpoon] and cooldown[SV.Harpoon].ready and (talents[SV.TermsOfEngagement] and focus < focusMax) then
		return SV.Harpoon;
	end

	-- muzzle;
	if talents[SV.Muzzle] and cooldown[SV.Muzzle].ready then
		return SV.Muzzle;
	end

	-- aspect_of_the_eagle,if=target.distance>=6;
	if talents[SV.AspectOfTheEagle] and cooldown[SV.AspectOfTheEagle].ready then
		return SV.AspectOfTheEagle;
	end
end

function Hunter:SurvivalCleave()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local timeShift = fd.timeShift;
	local targets = fd.targets and fd.targets or 1;
	local gcd = fd.gcd;
	local timeToDie = fd.timeToDie;
	local focus = UnitPower('player', Enum.PowerType.Focus);
	local focusMax = UnitPowerMax('player', Enum.PowerType.Focus);
	local focusPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local focusRegen = select(2,GetPowerRegen());
	local focusRegenCombined = focusRegen + focus;
	local focusDeficit = UnitPowerMax('player', Enum.PowerType.Focus) - focus;
	local focusTimeToMax = focusMax - focus / focusRegen;
	local castRegen = UnitPower('player', Enum.PowerType.CastRegen);
	local castRegenMax = UnitPowerMax('player', Enum.PowerType.CastRegen);
	local castRegenPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local castRegenRegen = select(2,GetPowerRegen());
	local castRegenRegenCombined = castRegenRegen + castRegen;
	local castRegenDeficit = UnitPowerMax('player', Enum.PowerType.CastRegen) - castRegen;
	local castRegenTimeToMax = castRegenMax - castRegen / castRegenRegen;

	-- kill_shot,if=buff.coordinated_assault_empower.up&talent.birds_of_prey;
	if talents[SV.KillShot] and cooldown[SV.KillShot].ready and focus >= 10 and (buff[SV.CoordinatedAssaultEmpower].up and talents[SV.BirdsOfPrey]) then
		return SV.KillShot;
	end

	-- death_chakram;
	if talents[SV.DeathChakram] and cooldown[SV.DeathChakram].ready then
		return SV.DeathChakram;
	end

	-- wildfire_bomb;
	if talents[SV.WildfireBomb] and cooldown[SV.WildfireBomb].ready then
		return SV.WildfireBomb;
	end

	-- stampede;
	if talents[SV.Stampede] and cooldown[SV.Stampede].ready then
		return SV.Stampede;
	end

	-- coordinated_assault,if=cooldown.fury_of_the_eagle.remains|!talent.fury_of_the_eagle;
	if talents[SV.CoordinatedAssault] and cooldown[SV.CoordinatedAssault].ready and (cooldown[SV.FuryOfTheEagle].remains or not talents[SV.FuryOfTheEagle]) then
		return SV.CoordinatedAssault;
	end

	-- explosive_shot;
	if talents[SV.ExplosiveShot] and cooldown[SV.ExplosiveShot].ready and focus >= 20 then
		return SV.ExplosiveShot;
	end

	-- carve,if=cooldown.wildfire_bomb.full_recharge_time>spell_targets%2;
	if talents[SV.Carve] and cooldown[SV.Carve].ready and focus >= 35 and (cooldown[SV.WildfireBomb].fullRecharge > targets / 2) then
		return SV.Carve;
	end

	-- fury_of_the_eagle,if=raid_event.adds.exists&(!talent.butchery|cooldown.butchery.full_recharge_time>cast_time);
	if talents[SV.FuryOfTheEagle] and cooldown[SV.FuryOfTheEagle].ready and (targets > 1 and ( not talents[SV.Butchery] or cooldown[SV.Butchery].fullRecharge > timeShift )) then
		return SV.FuryOfTheEagle;
	end

	-- butchery,if=raid_event.adds.exists;
	if talents[SV.Butchery] and cooldown[SV.Butchery].ready and focus >= 30 and (targets > 1) then
		return SV.Butchery;
	end

	-- butchery,if=(full_recharge_time<gcd|dot.shrapnel_bomb.ticking&(dot.internal_bleeding.stack<2|dot.shrapnel_bomb.remains<gcd|raid_event.adds.remains<10))&!raid_event.adds.exists;
	if talents[SV.Butchery] and cooldown[SV.Butchery].ready and focus >= 30 and (( cooldown[SV.Butchery].fullRecharge < gcd or debuff[SV.ShrapnelBomb].up and ( debuff[SV.InternalBleeding].count < 2 or debuff[SV.ShrapnelBomb].remains < gcd or raid_event.adds.remains < 10 ) ) and not targets > 1) then
		return SV.Butchery;
	end

	-- fury_of_the_eagle,if=!raid_event.adds.exists;
	if talents[SV.FuryOfTheEagle] and cooldown[SV.FuryOfTheEagle].ready and (targets <= 1) then
		return SV.FuryOfTheEagle;
	end

	-- carve,if=dot.shrapnel_bomb.ticking;
	if talents[SV.Carve] and cooldown[SV.Carve].ready and focus >= 35 and (debuff[SV.ShrapnelBomb].up) then
		return SV.Carve;
	end

	-- butchery,if=(!next_wi_bomb.shrapnel|!talent.wildfire_infusion);
	if talents[SV.Butchery] and cooldown[SV.Butchery].ready and focus >= 30 and (( not nextWiBomb == SV.ShrapnelBomb or not talents[SV.WildfireInfusion] )) then
		return SV.Butchery;
	end

	-- mongoose_bite,target_if=max:debuff.latent_poison.stack,if=debuff.latent_poison.stack>8;
	if talents[SV.MongooseBite] and focus >= 30 and (debuff[SV.LatentPoison].count > 8) then
		return SV.MongooseBite;
	end

	-- raptor_strike,target_if=max:debuff.latent_poison.stack,if=debuff.latent_poison.stack>8;
	if talents[SV.RaptorStrike] and focus >= 30 and (debuff[SV.LatentPoison].count > 8) then
		return SV.RaptorStrike;
	end

	-- kill_command,target_if=min:bloodseeker.remains,if=focus+cast_regen<focus.max&full_recharge_time<gcd;
	if talents[SV.KillCommand] and cooldown[SV.KillCommand].ready and (focus + castRegen < focusMax and cooldown[SV.KillCommand].fullRecharge < gcd) then
		return SV.KillCommand;
	end

	-- flanking_strike,if=focus+cast_regen<focus.max;
	if talents[SV.FlankingStrike] and cooldown[SV.FlankingStrike].ready and (focus + castRegen < focusMax) then
		return SV.FlankingStrike;
	end

	-- carve;
	if talents[SV.Carve] and cooldown[SV.Carve].ready and focus >= 35 then
		return SV.Carve;
	end

	-- kill_shot,if=!buff.coordinated_assault.up;
	if talents[SV.KillShot] and cooldown[SV.KillShot].ready and focus >= 10 and (not buff[SV.CoordinatedAssault].up) then
		return SV.KillShot;
	end

	-- steel_trap,if=focus+cast_regen<focus.max;
	if talents[SV.SteelTrap] and cooldown[SV.SteelTrap].ready and (focus + castRegen < focusMax) then
		return SV.SteelTrap;
	end

	-- spearhead;
	if talents[SV.Spearhead] and cooldown[SV.Spearhead].ready then
		return SV.Spearhead;
	end

	-- mongoose_bite,target_if=min:dot.serpent_sting.remains,if=buff.spearhead.remains;
	if talents[SV.MongooseBite] and focus >= 30 and (buff[SV.Spearhead].remains) then
		return SV.MongooseBite;
	end

	-- serpent_sting,target_if=min:remains,if=refreshable&target.time_to_die>12&(!talent.vipers_venom|talent.hydras_bite);
	if talents[SV.SerpentSting] and focus >= 10 and (debuff[SV.SerpentSting].refreshable and timeToDie > 12 and ( not talents[SV.VipersVenom] or talents[SV.HydrasBite] )) then
		return SV.SerpentSting;
	end

	-- mongoose_bite,target_if=min:dot.serpent_sting.remains;
	if talents[SV.MongooseBite] and focus >= 30 then
		return SV.MongooseBite;
	end

	-- raptor_strike,target_if=min:dot.serpent_sting.remains;
	if talents[SV.RaptorStrike] and focus >= 30 then
		return SV.RaptorStrike;
	end
end

function Hunter:SurvivalSt()
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
	local focus = UnitPower('player', Enum.PowerType.Focus);
	local focusMax = UnitPowerMax('player', Enum.PowerType.Focus);
	local focusPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local focusRegen = select(2,GetPowerRegen());
	local focusRegenCombined = focusRegen + focus;
	local focusDeficit = UnitPowerMax('player', Enum.PowerType.Focus) - focus;
	local focusTimeToMax = focusMax - focus / focusRegen;
	local castRegen = UnitPower('player', Enum.PowerType.CastRegen);
	local castRegenMax = UnitPowerMax('player', Enum.PowerType.CastRegen);
	local castRegenPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local castRegenRegen = select(2,GetPowerRegen());
	local castRegenRegenCombined = castRegenRegen + castRegen;
	local castRegenDeficit = UnitPowerMax('player', Enum.PowerType.CastRegen) - castRegen;
	local castRegenTimeToMax = castRegenMax - castRegen / castRegenRegen;

	-- kill_command,target_if=min:bloodseeker.remains,if=talent.spearhead&debuff.shredded_armor.stack<1&cooldown.spearhead.remains<2*gcd;
	if talents[SV.KillCommand] and cooldown[SV.KillCommand].ready and (talents[SV.Spearhead] and debuff[SV.ShreddedArmor].count < 1 and cooldown[SV.Spearhead].remains < 2 * gcd) then
		return SV.KillCommand;
	end

	-- wildfire_bomb,if=talent.spearhead&cooldown.spearhead.remains<2*gcd&debuff.shredded_armor.stack>0;
	if talents[SV.WildfireBomb] and cooldown[SV.WildfireBomb].ready and (talents[SV.Spearhead] and cooldown[SV.Spearhead].remains < 2 * gcd and debuff[SV.ShreddedArmor].count > 0) then
		return SV.WildfireBomb;
	end

	-- death_chakram,if=focus+cast_regen<focus.max|talent.spearhead&!cooldown.spearhead.remains;
	if talents[SV.DeathChakram] and cooldown[SV.DeathChakram].ready and (focus + castRegen < focusMax or talents[SV.Spearhead] and not cooldown[SV.Spearhead].remains) then
		return SV.DeathChakram;
	end

	-- spearhead,if=focus+action.kill_command.cast_regen>focus.max-10&(cooldown.death_chakram.remains|!talent.death_chakram);
	if talents[SV.Spearhead] and cooldown[SV.Spearhead].ready and (focus > focusMax - 10 and ( cooldown[SV.DeathChakram].remains or not talents[SV.DeathChakram] )) then
		return SV.Spearhead;
	end

	-- kill_shot,if=buff.coordinated_assault_empower.up;
	if talents[SV.KillShot] and cooldown[SV.KillShot].ready and focus >= 10 and (buff[SV.CoordinatedAssaultEmpower].up) then
		return SV.KillShot;
	end

	-- wildfire_bomb,if=(raid_event.adds.in>cooldown.wildfire_bomb.full_recharge_time-(cooldown.wildfire_bomb.full_recharge_time%3.5)&debuff.shredded_armor.stack>0&(full_recharge_time<2*gcd|talent.bombardier&!cooldown.coordinated_assault.remains|talent.bombardier&buff.coordinated_assault.up&buff.coordinated_assault.remains<2*gcd)|!raid_event.adds.exists&time_to_die<7)&set_bonus.tier30_4pc;
	if talents[SV.WildfireBomb] and cooldown[SV.WildfireBomb].ready and (MaxDps.tier[30].count and (MaxDps.tier[30].count == 4)) then
		return SV.WildfireBomb;
	end

	-- kill_command,target_if=min:bloodseeker.remains,if=full_recharge_time<gcd&focus+cast_regen<focus.max&(buff.deadly_duo.stack>2|buff.spearhead.remains&dot.pheromone_bomb.remains);
	if talents[SV.KillCommand] and cooldown[SV.KillCommand].ready and (cooldown[SV.KillCommand].fullRecharge < gcd and focus + castRegen < focusMax and ( buff[SV.DeadlyDuo].count > 2 or buff[SV.Spearhead].remains and debuff[SV.PheromoneBomb].remains )) then
		return SV.KillCommand;
	end

	-- kill_command,target_if=min:bloodseeker.remains,if=cooldown.wildfire_bomb.full_recharge_time<3*gcd&debuff.shredded_armor.stack<1&set_bonus.tier30_4pc&!buff.spearhead.remains;
	if talents[SV.KillCommand] and cooldown[SV.KillCommand].ready and (cooldown[SV.WildfireBomb].fullRecharge < 3 * gcd and debuff[SV.ShreddedArmor].count < 1 and MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 4) and not buff[SV.Spearhead].remains) then
		return SV.KillCommand;
	end

	-- mongoose_bite,if=buff.spearhead.remains;
	if talents[SV.MongooseBite] and focus >= 30 and (buff[SV.Spearhead].remains) then
		return SV.MongooseBite;
	end

	-- mongoose_bite,if=active_enemies=1&target.time_to_die<focus%(variable.mb_rs_cost-cast_regen)*gcd|buff.mongoose_fury.up&buff.mongoose_fury.remains<gcd;
	if talents[SV.MongooseBite] and focus >= 30 and (targets == 1 and timeToDie < focus / ( mbRsCost - castRegen ) * gcd or buff[SV.MongooseFury].up and buff[SV.MongooseFury].remains < gcd) then
		return SV.MongooseBite;
	end

	-- kill_shot,if=!buff.coordinated_assault.up;
	if talents[SV.KillShot] and cooldown[SV.KillShot].ready and focus >= 10 and (not buff[SV.CoordinatedAssault].up) then
		return SV.KillShot;
	end

	-- raptor_strike,if=active_enemies=1&target.time_to_die<focus%(variable.mb_rs_cost-cast_regen)*gcd;
	if talents[SV.RaptorStrike] and focus >= 30 and (targets == 1 and timeToDie < focus / ( mbRsCost - castRegen ) * gcd) then
		return SV.RaptorStrike;
	end

	-- serpent_sting,target_if=min:remains,if=!dot.serpent_sting.ticking&target.time_to_die>7&!talent.vipers_venom;
	if talents[SV.SerpentSting] and focus >= 10 and (not debuff[SV.SerpentSting].up and timeToDie > 7 and not talents[SV.VipersVenom]) then
		return SV.SerpentSting;
	end

	-- fury_of_the_eagle,if=buff.seething_rage.up&buff.seething_rage.remains<3*gcd&(!raid_event.adds.exists|active_enemies>1|raid_event.adds.exists&raid_event.adds.in>40);
	if talents[SV.FuryOfTheEagle] and cooldown[SV.FuryOfTheEagle].ready and (buff[SV.SeethingRage].up and buff[SV.SeethingRage].remains < 3 * gcd and ( not targets > 1 or targets > 1 or targets > 1 )) then
		return SV.FuryOfTheEagle;
	end

	-- mongoose_bite,if=talent.alpha_predator&buff.mongoose_fury.up&buff.mongoose_fury.remains<focus%(variable.mb_rs_cost-cast_regen)*gcd|buff.seething_rage.remains&active_enemies=1;
	if talents[SV.MongooseBite] and focus >= 30 and (talents[SV.AlphaPredator] and buff[SV.MongooseFury].up and buff[SV.MongooseFury].remains < focus / ( mbRsCost - castRegen ) * gcd or buff[SV.SeethingRage].remains and targets == 1) then
		return SV.MongooseBite;
	end

	-- flanking_strike,if=focus+cast_regen<focus.max;
	if talents[SV.FlankingStrike] and cooldown[SV.FlankingStrike].ready and (focus + castRegen < focusMax) then
		return SV.FlankingStrike;
	end

	-- stampede;
	if talents[SV.Stampede] and cooldown[SV.Stampede].ready then
		return SV.Stampede;
	end

	-- coordinated_assault,if=(!talent.coordinated_kill&target.health.pct<20&(!buff.spearhead.remains&cooldown.spearhead.remains|!talent.spearhead)|talent.coordinated_kill&(!buff.spearhead.remains&cooldown.spearhead.remains|!talent.spearhead))&(!raid_event.adds.exists|raid_event.adds.in>90);
	if talents[SV.CoordinatedAssault] and cooldown[SV.CoordinatedAssault].ready and (( not talents[SV.CoordinatedKill] and targetHp < 20 and ( not buff[SV.Spearhead].remains and cooldown[SV.Spearhead].remains or not talents[SV.Spearhead] ) or talents[SV.CoordinatedKill] and ( not buff[SV.Spearhead].remains and cooldown[SV.Spearhead].remains or not talents[SV.Spearhead] ) ) and ( not targets > 1  )) then
		return SV.CoordinatedAssault;
	end

	-- kill_command,target_if=min:bloodseeker.remains,if=full_recharge_time<gcd&focus+cast_regen<focus.max&(cooldown.flanking_strike.remains|!talent.flanking_strike);
	if talents[SV.KillCommand] and cooldown[SV.KillCommand].ready and (cooldown[SV.KillCommand].fullRecharge < gcd and focus + castRegen < focusMax and ( cooldown[SV.FlankingStrike].remains or not talents[SV.FlankingStrike] )) then
		return SV.KillCommand;
	end

	-- serpent_sting,target_if=min:remains,if=refreshable&!talent.vipers_venom;
	if talents[SV.SerpentSting] and focus >= 10 and (debuff[SV.SerpentSting].refreshable and not talents[SV.VipersVenom]) then
		return SV.SerpentSting;
	end

	-- wildfire_bomb,if=raid_event.adds.in>cooldown.wildfire_bomb.full_recharge_time-(cooldown.wildfire_bomb.full_recharge_time%3.5)&full_recharge_time<2*gcd;
	if talents[SV.WildfireBomb] and cooldown[SV.WildfireBomb].ready and (cooldown[SV.WildfireBomb].fullRecharge - ( cooldown[SV.WildfireBomb].fullRecharge / 3.5 ) and cooldown[SV.WildfireBomb].fullRecharge < 2 * gcd) then
		return SV.WildfireBomb;
	end

	-- mongoose_bite,if=dot.shrapnel_bomb.ticking;
	if talents[SV.MongooseBite] and focus >= 30 and (debuff[SV.ShrapnelBomb].up) then
		return SV.MongooseBite;
	end

	-- wildfire_bomb,if=raid_event.adds.in>cooldown.wildfire_bomb.full_recharge_time-(cooldown.wildfire_bomb.full_recharge_time%3.5)&set_bonus.tier30_4pc&(!dot.wildfire_bomb.ticking&debuff.shredded_armor.stack>0&focus+cast_regen<focus.max|active_enemies>1);
	if talents[SV.WildfireBomb] and cooldown[SV.WildfireBomb].ready and (cooldown[SV.WildfireBomb].fullRecharge - ( cooldown[SV.WildfireBomb].fullRecharge / 3.5 ) and MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 4) and ( not debuff[SV.WildfireBomb].up and debuff[SV.ShreddedArmor].count > 0 and focus + castRegen < focusMax or targets > 1 )) then
		return SV.WildfireBomb;
	end

	-- mongoose_bite,target_if=max:debuff.latent_poison.stack,if=buff.mongoose_fury.up;
	if talents[SV.MongooseBite] and focus >= 30 and (buff[SV.MongooseFury].up) then
		return SV.MongooseBite;
	end

	-- explosive_shot,if=talent.ranger&(!raid_event.adds.exists|raid_event.adds.in>28);
	if talents[SV.ExplosiveShot] and cooldown[SV.ExplosiveShot].ready and focus >= 20 and (talents[SV.Ranger] and ( not targets > 1 )) then
		return SV.ExplosiveShot;
	end

	-- fury_of_the_eagle,if=(!equipped.djaruun_pillar_of_the_elder_flame|cooldown.elder_flame_408821.remains>40)&target.health.pct<65&talent.ruthless_marauder&(!raid_event.adds.exists|raid_event.adds.exists&raid_event.adds.in>40);
	if talents[SV.FuryOfTheEagle] and cooldown[SV.FuryOfTheEagle].ready and (( not IsEquippedItem(DjaruunPillarOfTheElderFlame) or cooldown[SV.ElderFlame408821].remains > 40 ) and targetHp < 65 and talents[SV.RuthlessMarauder] and ( not targets > 1 or targets > 1  )) then
		return SV.FuryOfTheEagle;
	end

	-- mongoose_bite,target_if=max:debuff.latent_poison.stack,if=focus+action.kill_command.cast_regen>focus.max-10|set_bonus.tier30_4pc;
	if talents[SV.MongooseBite] and focus >= 30 and (focus > focusMax - 10 or MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 4)) then
		return SV.MongooseBite;
	end

	-- raptor_strike,target_if=max:debuff.latent_poison.stack;
	if talents[SV.RaptorStrike] and focus >= 30 then
		return SV.RaptorStrike;
	end

	-- steel_trap;
	if talents[SV.SteelTrap] and cooldown[SV.SteelTrap].ready then
		return SV.SteelTrap;
	end

	-- wildfire_bomb,if=raid_event.adds.in>cooldown.wildfire_bomb.full_recharge_time-(cooldown.wildfire_bomb.full_recharge_time%3.5)&!dot.wildfire_bomb.ticking;
	if talents[SV.WildfireBomb] and cooldown[SV.WildfireBomb].ready and (cooldown[SV.WildfireBomb].fullRecharge - ( cooldown[SV.WildfireBomb].fullRecharge / 3.5 ) and not debuff[SV.WildfireBomb].up) then
		return SV.WildfireBomb;
	end

	-- kill_command,target_if=min:bloodseeker.remains,if=focus+cast_regen<focus.max;
	if talents[SV.KillCommand] and cooldown[SV.KillCommand].ready and (focus + castRegen < focusMax) then
		return SV.KillCommand;
	end

	-- coordinated_assault,if=!talent.coordinated_kill&time_to_die>140;
	if talents[SV.CoordinatedAssault] and cooldown[SV.CoordinatedAssault].ready and (not talents[SV.CoordinatedKill] and timeToDie > 140) then
		return SV.CoordinatedAssault;
	end
end


local _, addonTable = ...;

-- @type MaxDps;
if not MaxDps then return end;
local Warrior = addonTable.Warrior;
local MaxDps = MaxDps;

local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;

local itemID = GetInventoryItemID('player', INVSLOT_MAINHAND);

local mainHandSubClassID = itemID and  select(13, GetItemInfo(itemID));

local TwoHanderWepCheck = mainHandSubClassID and (mainHandSubClassID == 1 or mainHandSubClassID == 5 or mainHandSubClassID == 8 or mainHandSubClassID == 10);

local PR = {
	BattleStance = 386164,
	Charge = 100,
	Avatar = 401150,
	ShieldWall = 871,
	ImmovableObject = 394307,
	IgnorePain = 190456,
	ShieldSlam = 23922,
	ShieldCharge = 385952,
	ChampionsBulwark = 386328,
	DemoralizingShout = 1160,
	BoomingVoice = 202743,
	LastStand = 12975,
	UnnervingFocus = 384042,
	ViolentOutburst = 386477,
	HeavyRepercussions = 203177,
	ImpenetrableWall = 384072,
	Bolster = 280001,
	Ravager = 228920,
	SpearOfBastion = 376079,
	ThunderousRoar = 384318,
	Shockwave = 46968,
	SonicBoom = 390725,
	UnstoppableForce = 275336,
	RumblingEarth = 275339,
	ShieldBlock = 2565,
	EnduringDefenses = 386027,
	ThunderClap = 6343,
	Rend = 394062,
	EarthenTenacity = 410218,
	Revenge = 6572,
	SeismicReverberation = 382956,
	BarbaricTraining = 390675,
	Massacre = 281001,
	--SuddenDeathAura = ,
	Execute = 163201,
	SuddenDeath = 29725,
	Devastate = 20243,
};
local A = {
};
function Warrior:Protection()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local rage = UnitPower('player', Enum.PowerType.Rage);
	local rageMax = UnitPowerMax('player', Enum.PowerType.Rage);
	local ragePct = UnitPower('player')/UnitPowerMax('player') * 100;
	local rageRegen = select(2,GetPowerRegen());
	local rageRegenCombined = rageRegen + rage;
	local rageDeficit = UnitPowerMax('player', Enum.PowerType.Rage) - rage;
	local rageTimeToMax = rageMax - rage / rageRegen;
	local canExecute = ((talents[FR.Massacre] and targetHp < 35) or targetHp < 20) or buff[FR.SuddenDeathAura].up;

	-- avatar;
	if talents[PR.Avatar] and cooldown[PR.Avatar].ready then
		return PR.Avatar;
	end

	-- shield_wall,if=talent.immovable_object.enabled&buff.avatar.down;
	if talents[PR.ShieldWall] and cooldown[PR.ShieldWall].ready and (talents[PR.ImmovableObject] and not buff[PR.Avatar].up) then
		return PR.ShieldWall;
	end

	-- ignore_pain,if=target.health.pct>=20&(rage.deficit<=15&cooldown.shield_slam.ready|rage.deficit<=40&cooldown.shield_charge.ready&talent.champions_bulwark.enabled|rage.deficit<=20&cooldown.shield_charge.ready|rage.deficit<=30&cooldown.demoralizing_shout.ready&talent.booming_voice.enabled|rage.deficit<=20&cooldown.avatar.ready|rage.deficit<=45&cooldown.demoralizing_shout.ready&talent.booming_voice.enabled&buff.last_stand.up&talent.unnerving_focus.enabled|rage.deficit<=30&cooldown.avatar.ready&buff.last_stand.up&talent.unnerving_focus.enabled|rage.deficit<=20|rage.deficit<=40&cooldown.shield_slam.ready&buff.violent_outburst.up&talent.heavy_repercussions.enabled&talent.impenetrable_wall.enabled|rage.deficit<=55&cooldown.shield_slam.ready&buff.violent_outburst.up&buff.last_stand.up&talent.unnerving_focus.enabled&talent.heavy_repercussions.enabled&talent.impenetrable_wall.enabled|rage.deficit<=17&cooldown.shield_slam.ready&talent.heavy_repercussions.enabled|rage.deficit<=18&cooldown.shield_slam.ready&talent.impenetrable_wall.enabled),use_off_gcd=1;
	if talents[PR.IgnorePain] and cooldown[PR.IgnorePain].ready and rage >= 0 and (targetHp >= 20 and ( rageDeficit <= 15 and cooldown[PR.ShieldSlam].ready or rageDeficit <= 40 and cooldown[PR.ShieldCharge].ready and talents[PR.ChampionsBulwark] or rageDeficit <= 20 and cooldown[PR.ShieldCharge].ready or rageDeficit <= 30 and cooldown[PR.DemoralizingShout].ready and talents[PR.BoomingVoice] or rageDeficit <= 20 and cooldown[PR.Avatar].ready or rageDeficit <= 45 and cooldown[PR.DemoralizingShout].ready and talents[PR.BoomingVoice] and buff[PR.LastStand].up and talents[PR.UnnervingFocus] or rageDeficit <= 30 and cooldown[PR.Avatar].ready and buff[PR.LastStand].up and talents[PR.UnnervingFocus] or rageDeficit <= 20 or rageDeficit <= 40 and cooldown[PR.ShieldSlam].ready and buff[PR.ViolentOutburst].up and talents[PR.HeavyRepercussions] and talents[PR.ImpenetrableWall] or rageDeficit <= 55 and cooldown[PR.ShieldSlam].ready and buff[PR.ViolentOutburst].up and buff[PR.LastStand].up and talents[PR.UnnervingFocus] and talents[PR.HeavyRepercussions] and talents[PR.ImpenetrableWall] or rageDeficit <= 17 and cooldown[PR.ShieldSlam].ready and talents[PR.HeavyRepercussions] or rageDeficit <= 18 and cooldown[PR.ShieldSlam].ready and talents[PR.ImpenetrableWall] )) then
		return PR.IgnorePain;
	end

	-- last_stand,if=(target.health.pct>=90&talent.unnerving_focus.enabled|target.health.pct<=20&talent.unnerving_focus.enabled)|talent.bolster.enabled|set_bonus.tier30_2pc|set_bonus.tier30_4pc;
	if talents[PR.LastStand] and cooldown[PR.LastStand].ready and (( targetHp >= 90 and talents[PR.UnnervingFocus] or targetHp <= 20 and talents[PR.UnnervingFocus] ) or talents[PR.Bolster] or MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2) or MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 4)) then
		return PR.LastStand;
	end

	-- ravager;
	if talents[PR.Ravager] and cooldown[PR.Ravager].ready then
		return PR.Ravager;
	end

	-- demoralizing_shout,if=talent.booming_voice.enabled;
	if talents[PR.DemoralizingShout] and cooldown[PR.DemoralizingShout].ready and (talents[PR.BoomingVoice]) then
		return PR.DemoralizingShout;
	end

	-- spear_of_bastion;
	if talents[PR.SpearOfBastion] and cooldown[PR.SpearOfBastion].ready then
		return PR.SpearOfBastion;
	end

	-- thunderous_roar;
	if talents[PR.ThunderousRoar] and cooldown[PR.ThunderousRoar].ready then
		return PR.ThunderousRoar;
	end

	-- shockwave,if=talent.sonic_boom.enabled&buff.avatar.up&talent.unstoppable_force.enabled&!talent.rumbling_earth.enabled;
	if talents[PR.Shockwave] and cooldown[PR.Shockwave].ready and (talents[PR.SonicBoom] and buff[PR.Avatar].up and talents[PR.UnstoppableForce] and not talents[PR.RumblingEarth]) then
		return PR.Shockwave;
	end

	-- shield_charge;
	if talents[PR.ShieldCharge] and cooldown[PR.ShieldCharge].ready then
		return PR.ShieldCharge;
	end

	-- shield_block,if=buff.shield_block.duration<=18&talent.enduring_defenses.enabled|buff.shield_block.duration<=12;
	if cooldown[PR.ShieldBlock].ready and rage >= 30 and (buff[PR.ShieldBlock].duration <= 18 and talents[PR.EnduringDefenses] or buff[PR.ShieldBlock].duration <= 12) then
		return PR.ShieldBlock;
	end

	-- run_action_list,name=aoe,if=spell_targets.thunder_clap>=3;
	if targets >= 3 then
		return Warrior:ProtectionAoe();
	end

	-- call_action_list,name=generic;
	local result = Warrior:ProtectionGeneric();
	if result then
		return result;
	end
end
function Warrior:ProtectionAoe()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local rage = UnitPower('player', Enum.PowerType.Rage);
	local rageMax = UnitPowerMax('player', Enum.PowerType.Rage);
	local ragePct = UnitPower('player')/UnitPowerMax('player') * 100;
	local rageRegen = select(2,GetPowerRegen());
	local rageRegenCombined = rageRegen + rage;
	local rageDeficit = UnitPowerMax('player', Enum.PowerType.Rage) - rage;
	local rageTimeToMax = rageMax - rage / rageRegen;
	local canExecute = ((talents[FR.Massacre] and targetHp < 35) or targetHp < 20) or buff[FR.SuddenDeathAura].up;

	-- thunder_clap,if=dot.rend.remains<=1;
	if talents[PR.ThunderClap] and cooldown[PR.ThunderClap].ready and (debuff[PR.Rend].remains <= 1) then
		return PR.ThunderClap;
	end

	-- shield_slam,if=(set_bonus.tier30_2pc|set_bonus.tier30_4pc)&spell_targets.thunder_clap<=7|buff.earthen_tenacity.up;
	if cooldown[PR.ShieldSlam].ready and (( MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 2) or MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 4) ) and targets <= 7 or buff[PR.EarthenTenacity].up) then
		return PR.ShieldSlam;
	end

	-- thunder_clap,if=buff.violent_outburst.up&spell_targets.thunderclap>5&buff.avatar.up&talent.unstoppable_force.enabled;
	if talents[PR.ThunderClap] and cooldown[PR.ThunderClap].ready and (buff[PR.ViolentOutburst].up and targets > 5 and buff[PR.Avatar].up and talents[PR.UnstoppableForce]) then
		return PR.ThunderClap;
	end

	-- revenge,if=rage>=70&talent.seismic_reverberation.enabled&spell_targets.revenge>=3;
	if talents[PR.Revenge] and rage >= 20 and (rage >= 70 and talents[PR.SeismicReverberation] and targets >= 3) then
		return PR.Revenge;
	end

	-- shield_slam,if=rage<=60|buff.violent_outburst.up&spell_targets.thunderclap<=7;
	if cooldown[PR.ShieldSlam].ready and (rage <= 60 or buff[PR.ViolentOutburst].up and targets <= 7) then
		return PR.ShieldSlam;
	end

	-- thunder_clap;
	if talents[PR.ThunderClap] and cooldown[PR.ThunderClap].ready then
		return PR.ThunderClap;
	end

	-- revenge,if=rage>=30|rage>=40&talent.barbaric_training.enabled;
	if talents[PR.Revenge] and rage >= 20 and (rage >= 30 or rage >= 40 and talents[PR.BarbaricTraining]) then
		return PR.Revenge;
	end
end

function Warrior:ProtectionGeneric()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local rage = UnitPower('player', Enum.PowerType.Rage);
	local rageMax = UnitPowerMax('player', Enum.PowerType.Rage);
	local ragePct = UnitPower('player')/UnitPowerMax('player') * 100;
	local rageRegen = select(2,GetPowerRegen());
	local rageRegenCombined = rageRegen + rage;
	local rageDeficit = UnitPowerMax('player', Enum.PowerType.Rage) - rage;
	local rageTimeToMax = rageMax - rage / rageRegen;
	local canExecute = ((talents[FR.Massacre] and targetHp < 35) or targetHp < 20) or buff[FR.SuddenDeathAura].up;

	-- shield_slam;
	if cooldown[PR.ShieldSlam].ready then
		return PR.ShieldSlam;
	end

	-- thunder_clap,if=dot.rend.remains<=1&buff.violent_outburst.down;
	if talents[PR.ThunderClap] and cooldown[PR.ThunderClap].ready and (debuff[PR.Rend].remains <= 1 and not buff[PR.ViolentOutburst].up) then
		return PR.ThunderClap;
	end

	-- execute,if=buff.sudden_death.up&talent.sudden_death.enabled;
	if canExecute and cooldown[PR.Execute].ready and rage >= 40 and (buff[PR.SuddenDeath].up and talents[PR.SuddenDeath]) then
		return PR.Execute;
	end

	-- execute,if=spell_targets.revenge=1&rage>=50;
	if canExecute and cooldown[PR.Execute].ready and rage >= 40 and (targets == 1 and rage >= 50) then
		return PR.Execute;
	end

	-- thunder_clap,if=(spell_targets.thunder_clap>1|cooldown.shield_slam.remains&!buff.violent_outburst.up);
	if talents[PR.ThunderClap] and cooldown[PR.ThunderClap].ready and (( targets > 1 or cooldown[PR.ShieldSlam].remains and not buff[PR.ViolentOutburst].up )) then
		return PR.ThunderClap;
	end

	-- revenge,if=(rage>=60&target.health.pct>20|buff.revenge.up&target.health.pct<=20&rage<=18&cooldown.shield_slam.remains|buff.revenge.up&target.health.pct>20)|(rage>=60&target.health.pct>35|buff.revenge.up&target.health.pct<=35&rage<=18&cooldown.shield_slam.remains|buff.revenge.up&target.health.pct>35)&talent.massacre.enabled;
	if talents[PR.Revenge] and rage >= 20 and (( rage >= 60 and targetHp > 20 or buff[PR.Revenge].up and targetHp <= 20 and rage <= 18 and cooldown[PR.ShieldSlam].remains or buff[PR.Revenge].up and targetHp > 20 ) or ( rage >= 60 and targetHp > 35 or buff[PR.Revenge].up and targetHp <= 35 and rage <= 18 and cooldown[PR.ShieldSlam].remains or buff[PR.Revenge].up and targetHp > 35 ) and talents[PR.Massacre]) then
		return PR.Revenge;
	end

	-- execute,if=spell_targets.revenge=1;
	if canExecute and cooldown[PR.Execute].ready and rage >= 40 and (targets == 1) then
		return PR.Execute;
	end

	-- revenge;
	if talents[PR.Revenge] and rage >= 20 then
		return PR.Revenge;
	end

	-- thunder_clap,if=(spell_targets.thunder_clap>=1|cooldown.shield_slam.remains&buff.violent_outburst.up);
	if talents[PR.ThunderClap] and cooldown[PR.ThunderClap].ready and (( targets >= 1 or cooldown[PR.ShieldSlam].remains and buff[PR.ViolentOutburst].up )) then
		return PR.ThunderClap;
	end

	-- devastate;
	-- PR.Devastate;
end


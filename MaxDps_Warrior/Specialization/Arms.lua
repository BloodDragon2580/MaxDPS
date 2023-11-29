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

local AR = {
	BattleStance = 386164,
	Charge = 100,
	Pummel = 6552,
	Massacre = 281001,
	SweepingStrikes = 260708,
	Rend = 772,
	Warbreaker = 262161,
	ColossusSmash = 167105,
	Avatar = 107574,
	ThunderousRoar = 384318,
	TestOfMight = 385008,
	SpearOfBastion = 376079,
	Skullsplitter = 260643,
	Cleave = 845,
	DeepWounds = 115767,
	Overpower = 7384,
	MartialProwess = 316440,
	MortalStrike = 12294,
	ExecutionersPrecision = 386634,
	--SuddenDeathAura = ,
	Execute = 163201,
	Shockwave = 46968,
	SonicBoom = 390725,
	Bladestorm = 389774,
	Juggernaut = 383292,
	ThunderClap = 396719,
	BloodAndThunder = 384277,
	TideOfBlood = 386357,
	BlademastersTorment = 390138,
	Unhinged = 386628,
	Battlelord = 386630,
	MercilessBonegrinder = 383317,
	Whirlwind = 1680,
	StormOfSwords = 385512,
	Hurricane = 390563,
	CrushingAdvance = 411703,
	Tier304pc = 405578,
	Dreadnaught = 262150,
	SuddenDeath = 29725,
	Slam = 1464,
	FervorOfBattle = 202316,
	CrushingForce = 382764,
	IgnorePain = 190456,
	AngerManagement = 152278,
	WreckingThrow = 384110,
	WarlordsTorment = 390140,
	Tier292pc = 393706,
};
local A = {
};
function Warrior:Arms()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local canExecute = ((talents[FR.Massacre] and targetHp < 35) or targetHp < 20) or buff[FR.SuddenDeathAura].up;

	-- run_action_list,name=hac,if=raid_event.adds.exists|active_enemies>2;
	if targets > 1 or targets > 2 then
		return Warrior:ArmsHac();
	end

	-- call_action_list,name=execute,target_if=min:target.health.pct,if=(talent.massacre.enabled&target.health.pct<35)|target.health.pct<20;
	if ( talents[AR.Massacre] and targetHp < 35 ) or targetHp < 20 then
		local result = Warrior:ArmsExecute();
		if result then
			return result;
		end
	end

	-- run_action_list,name=single_target,if=!raid_event.adds.exists;
	if targets <= 1 then
		return Warrior:ArmsSingleTarget();
	end
end
function Warrior:ArmsExecute()
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
	local rage = UnitPower('player', Enum.PowerType.Rage);
	local rageMax = UnitPowerMax('player', Enum.PowerType.Rage);
	local ragePct = UnitPower('player')/UnitPowerMax('player') * 100;
	local rageRegen = select(2,GetPowerRegen());
	local rageRegenCombined = rageRegen + rage;
	local rageDeficit = UnitPowerMax('player', Enum.PowerType.Rage) - rage;
	local rageTimeToMax = rageMax - rage / rageRegen;
	local canExecute = ((talents[FR.Massacre] and targetHp < 35) or targetHp < 20) or buff[FR.SuddenDeathAura].up;

	-- sweeping_strikes,if=spell_targets.whirlwind>1;
	if cooldown[AR.SweepingStrikes].ready and (targets > 1) then
		return AR.SweepingStrikes;
	end

	-- rend,if=remains<=gcd&(!talent.warbreaker&cooldown.colossus_smash.remains<4|talent.warbreaker&cooldown.warbreaker.remains<4)&target.time_to_die>12;
	if talents[AR.Rend] and rage >= 30 and (debuff[AR.Rend].remains <= gcd and ( not talents[AR.Warbreaker] and cooldown[AR.ColossusSmash].remains < 4 or talents[AR.Warbreaker] and cooldown[AR.Warbreaker].remains < 4 ) and timeToDie > 12) then
		return AR.Rend;
	end

	-- avatar,if=cooldown.colossus_smash.ready|debuff.colossus_smash.up|target.time_to_die<20;
	if talents[AR.Avatar] and cooldown[AR.Avatar].ready and (cooldown[AR.ColossusSmash].ready or debuff[AR.ColossusSmash].up or timeToDie < 20) then
		return AR.Avatar;
	end

	-- warbreaker;
	if talents[AR.Warbreaker] and cooldown[AR.Warbreaker].ready then
		return AR.Warbreaker;
	end

	-- colossus_smash;
	if talents[AR.ColossusSmash] and cooldown[AR.ColossusSmash].ready then
		return AR.ColossusSmash;
	end

	-- thunderous_roar,if=buff.test_of_might.up|!talent.test_of_might&debuff.colossus_smash.up;
	if talents[AR.ThunderousRoar] and cooldown[AR.ThunderousRoar].ready and (buff[AR.TestOfMight].up or not talents[AR.TestOfMight] and debuff[AR.ColossusSmash].up) then
		return AR.ThunderousRoar;
	end

	-- spear_of_bastion,if=debuff.colossus_smash.up|buff.test_of_might.up;
	if talents[AR.SpearOfBastion] and cooldown[AR.SpearOfBastion].ready and (debuff[AR.ColossusSmash].up or buff[AR.TestOfMight].up) then
		return AR.SpearOfBastion;
	end

	-- skullsplitter,if=rage<40;
	if talents[AR.Skullsplitter] and cooldown[AR.Skullsplitter].ready and (rage < 40) then
		return AR.Skullsplitter;
	end

	-- cleave,if=spell_targets.whirlwind>2&dot.deep_wounds.remains<gcd;
	if talents[AR.Cleave] and cooldown[AR.Cleave].ready and rage >= 20 and (targets > 2 and debuff[AR.DeepWounds].remains < gcd) then
		return AR.Cleave;
	end

	-- overpower,if=rage<40&buff.martial_prowess.stack<2;
	if talents[AR.Overpower] and cooldown[AR.Overpower].ready and (rage < 40 and buff[AR.MartialProwess].count < 2) then
		return AR.Overpower;
	end

	-- mortal_strike,if=debuff.executioners_precision.stack=2|dot.deep_wounds.remains<=gcd;
	if talents[AR.MortalStrike] and cooldown[AR.MortalStrike].ready and rage >= 30 and (debuff[AR.ExecutionersPrecision].count == 2 or debuff[AR.DeepWounds].remains <= gcd) then
		return AR.MortalStrike;
	end

	-- execute;
	if canExecute and cooldown[AR.Execute].ready and rage >= 40 then
		return AR.Execute;
	end

	-- shockwave,if=talent.sonic_boom;
	if talents[AR.Shockwave] and cooldown[AR.Shockwave].ready and (talents[AR.SonicBoom]) then
		return AR.Shockwave;
	end

	-- overpower;
	if talents[AR.Overpower] and cooldown[AR.Overpower].ready then
		return AR.Overpower;
	end

	-- bladestorm;
	if cooldown[AR.Bladestorm].ready then
		return AR.Bladestorm;
	end
end

function Warrior:ArmsHac()
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
	local rage = UnitPower('player', Enum.PowerType.Rage);
	local rageMax = UnitPowerMax('player', Enum.PowerType.Rage);
	local ragePct = UnitPower('player')/UnitPowerMax('player') * 100;
	local rageRegen = select(2,GetPowerRegen());
	local rageRegenCombined = rageRegen + rage;
	local rageDeficit = UnitPowerMax('player', Enum.PowerType.Rage) - rage;
	local rageTimeToMax = rageMax - rage / rageRegen;
	local canExecute = ((talents[FR.Massacre] and targetHp < 35) or targetHp < 20) or buff[FR.SuddenDeathAura].up;

	-- execute,if=buff.juggernaut.up&buff.juggernaut.remains<gcd;
	if canExecute and cooldown[AR.Execute].ready and rage >= 40 and (buff[AR.Juggernaut].up and buff[AR.Juggernaut].remains < gcd) then
		return AR.Execute;
	end

	-- thunder_clap,if=active_enemies>2&talent.thunder_clap&talent.blood_and_thunder&talent.rend&dot.rend.remains<=dot.rend.duration*0.3;
	if talents[AR.ThunderClap] and cooldown[AR.ThunderClap].ready and rage >= 40 and (targets > 2 and talents[AR.ThunderClap] and talents[AR.BloodAndThunder] and talents[AR.Rend] and debuff[AR.Rend].remains <= debuff[AR.Rend].duration * 0.3) then
		return AR.ThunderClap;
	end

	-- sweeping_strikes,if=active_enemies>=2&(cooldown.bladestorm.remains>15|!talent.bladestorm);
	if cooldown[AR.SweepingStrikes].ready and (targets >= 2 and ( cooldown[AR.Bladestorm].remains > 15 or not talents[AR.Bladestorm] )) then
		return AR.SweepingStrikes;
	end

	-- rend,if=active_enemies=1&remains<=gcd&(target.health.pct>20|talent.massacre&target.health.pct>35)|talent.tide_of_blood&cooldown.skullsplitter.remains<=gcd&(cooldown.colossus_smash.remains<=gcd|debuff.colossus_smash.up)&dot.rend.remains<dot.rend.duration*0.85;
	if talents[AR.Rend] and rage >= 30 and (targets == 1 and debuff[AR.Rend].remains <= gcd and ( targetHp > 20 or talents[AR.Massacre] and targetHp > 35 ) or talents[AR.TideOfBlood] and cooldown[AR.Skullsplitter].remains <= gcd and ( cooldown[AR.ColossusSmash].remains <= gcd or debuff[AR.ColossusSmash].up ) and debuff[AR.Rend].remains < debuff[AR.Rend].duration * 0.85) then
		return AR.Rend;
	end

	-- avatar,if=raid_event.adds.in>15|talent.blademasters_torment&active_enemies>1|target.time_to_die<20;
	if talents[AR.Avatar] and cooldown[AR.Avatar].ready and (talents[AR.BlademastersTorment] and targets > 1 or timeToDie < 20) then
		return AR.Avatar;
	end

	-- warbreaker,if=raid_event.adds.in>22|active_enemies>1;
	if talents[AR.Warbreaker] and cooldown[AR.Warbreaker].ready and (targets > 1) then
		return AR.Warbreaker;
	end

	-- colossus_smash,cycle_targets=1,if=(target.health.pct<20|talent.massacre&target.health.pct<35);
	if talents[AR.ColossusSmash] and cooldown[AR.ColossusSmash].ready and (( targetHp < 20 or talents[AR.Massacre] and targetHp < 35 )) then
		return AR.ColossusSmash;
	end

	-- colossus_smash;
	if talents[AR.ColossusSmash] and cooldown[AR.ColossusSmash].ready then
		return AR.ColossusSmash;
	end

	-- thunderous_roar,if=(buff.test_of_might.up|!talent.test_of_might&debuff.colossus_smash.up)&raid_event.adds.in>15|active_enemies>1&dot.deep_wounds.remains;
	if talents[AR.ThunderousRoar] and cooldown[AR.ThunderousRoar].ready and (( buff[AR.TestOfMight].up or not talents[AR.TestOfMight] and debuff[AR.ColossusSmash].up ) or targets > 1 and debuff[AR.DeepWounds].remains) then
		return AR.ThunderousRoar;
	end

	-- spear_of_bastion,if=(buff.test_of_might.up|!talent.test_of_might&debuff.colossus_smash.up)&raid_event.adds.in>15;
	if talents[AR.SpearOfBastion] and cooldown[AR.SpearOfBastion].ready and (( buff[AR.TestOfMight].up or not talents[AR.TestOfMight] and debuff[AR.ColossusSmash].up ) ) then
		return AR.SpearOfBastion;
	end

	-- bladestorm,if=talent.unhinged&(buff.test_of_might.up|!talent.test_of_might&debuff.colossus_smash.up);
	if cooldown[AR.Bladestorm].ready and (talents[AR.Unhinged] and ( buff[AR.TestOfMight].up or not talents[AR.TestOfMight] and debuff[AR.ColossusSmash].up )) then
		return AR.Bladestorm;
	end

	-- bladestorm,if=active_enemies>1&(buff.test_of_might.up|!talent.test_of_might&debuff.colossus_smash.up)&raid_event.adds.in>30|active_enemies>1&dot.deep_wounds.remains;
	if cooldown[AR.Bladestorm].ready and (targets > 1 and ( buff[AR.TestOfMight].up or not talents[AR.TestOfMight] and debuff[AR.ColossusSmash].up ) or targets > 1 and debuff[AR.DeepWounds].remains) then
		return AR.Bladestorm;
	end

	-- cleave,if=active_enemies>2|!talent.battlelord&buff.merciless_bonegrinder.up&cooldown.mortal_strike.remains>gcd;
	if talents[AR.Cleave] and cooldown[AR.Cleave].ready and rage >= 20 and (targets > 2 or not talents[AR.Battlelord] and buff[AR.MercilessBonegrinder].up and cooldown[AR.MortalStrike].remains > gcd) then
		return AR.Cleave;
	end

	-- whirlwind,if=active_enemies>2|talent.storm_of_swords&(buff.merciless_bonegrinder.up|buff.hurricane.up);
	if rage >= 60 and (targets > 2 or talents[AR.StormOfSwords] and ( buff[AR.MercilessBonegrinder].up or buff[AR.Hurricane].up )) then
		return AR.Whirlwind;
	end

	-- skullsplitter,if=rage<40|talent.tide_of_blood&dot.rend.remains&(buff.sweeping_strikes.up&active_enemies>=2|debuff.colossus_smash.up|buff.test_of_might.up);
	if talents[AR.Skullsplitter] and cooldown[AR.Skullsplitter].ready and (rage < 40 or talents[AR.TideOfBlood] and debuff[AR.Rend].remains and ( buff[AR.SweepingStrikes].up and targets >= 2 or debuff[AR.ColossusSmash].up or buff[AR.TestOfMight].up )) then
		return AR.Skullsplitter;
	end

	-- mortal_strike,if=buff.sweeping_strikes.up&buff.crushing_advance.stack=3,if=set_bonus.tier30_4pc;
	if talents[AR.MortalStrike] and cooldown[AR.MortalStrike].ready and rage >= 30 and (MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 4)) then
		return AR.MortalStrike;
	end

	-- overpower,if=buff.sweeping_strikes.up&talent.dreadnaught;
	if talents[AR.Overpower] and cooldown[AR.Overpower].ready and (buff[AR.SweepingStrikes].up and talents[AR.Dreadnaught]) then
		return AR.Overpower;
	end

	-- mortal_strike,cycle_targets=1,if=debuff.executioners_precision.stack=2|dot.deep_wounds.remains<=gcd|talent.dreadnaught&talent.battlelord&active_enemies<=2;
	if talents[AR.MortalStrike] and cooldown[AR.MortalStrike].ready and rage >= 30 and (debuff[AR.ExecutionersPrecision].count == 2 or debuff[AR.DeepWounds].remains <= gcd or talents[AR.Dreadnaught] and talents[AR.Battlelord] and targets <= 2) then
		return AR.MortalStrike;
	end

	-- execute,cycle_targets=1,if=buff.sudden_death.react|active_enemies<=2&(target.health.pct<20|talent.massacre&target.health.pct<35)|buff.sweeping_strikes.up;
	if canExecute and cooldown[AR.Execute].ready and rage >= 40 and (buff[AR.SuddenDeath].count or targets <= 2 and ( targetHp < 20 or talents[AR.Massacre] and targetHp < 35 ) or buff[AR.SweepingStrikes].up) then
		return AR.Execute;
	end

	-- thunderous_roar,if=raid_event.adds.in>15;
	if talents[AR.ThunderousRoar] and cooldown[AR.ThunderousRoar].ready then
		return AR.ThunderousRoar;
	end

	-- shockwave,if=active_enemies>2&talent.sonic_boom;
	if talents[AR.Shockwave] and cooldown[AR.Shockwave].ready and (targets > 2 and talents[AR.SonicBoom]) then
		return AR.Shockwave;
	end

	-- overpower,if=active_enemies=1&(charges=2&!talent.battlelord&(debuff.colossus_smash.down|rage.pct<25)|talent.battlelord);
	if talents[AR.Overpower] and cooldown[AR.Overpower].ready and (targets == 1 and ( cooldown[AR.Overpower].charges == 2 and not talents[AR.Battlelord] and ( not debuff[AR.ColossusSmash].up or ragePct < 25 ) or talents[AR.Battlelord] )) then
		return AR.Overpower;
	end

	-- slam,if=active_enemies=1&!talent.battlelord&rage.pct>70;
	if rage >= 30 and (targets == 1 and not talents[AR.Battlelord] and ragePct > 70) then
		return AR.Slam;
	end

	-- overpower,if=charges=2&(!talent.test_of_might|talent.test_of_might&debuff.colossus_smash.down|talent.battlelord)|rage<70;
	if talents[AR.Overpower] and cooldown[AR.Overpower].ready and (cooldown[AR.Overpower].charges == 2 and ( not talents[AR.TestOfMight] or talents[AR.TestOfMight] and not debuff[AR.ColossusSmash].up or talents[AR.Battlelord] ) or rage < 70) then
		return AR.Overpower;
	end

	-- thunder_clap,if=active_enemies>2;
	if talents[AR.ThunderClap] and cooldown[AR.ThunderClap].ready and rage >= 40 and (targets > 2) then
		return AR.ThunderClap;
	end

	-- mortal_strike;
	if talents[AR.MortalStrike] and cooldown[AR.MortalStrike].ready and rage >= 30 then
		return AR.MortalStrike;
	end

	-- rend,if=active_enemies=1&dot.rend.remains<duration*0.3;
	if talents[AR.Rend] and rage >= 30 and (targets == 1 and debuff[AR.Rend].remains < cooldown[AR.Rend].duration * 0.3) then
		return AR.Rend;
	end

	-- whirlwind,if=talent.storm_of_swords|talent.fervor_of_battle&active_enemies>1;
	if rage >= 60 and (talents[AR.StormOfSwords] or talents[AR.FervorOfBattle] and targets > 1) then
		return AR.Whirlwind;
	end

	-- cleave,if=!talent.crushing_force;
	if talents[AR.Cleave] and cooldown[AR.Cleave].ready and rage >= 20 and (not talents[AR.CrushingForce]) then
		return AR.Cleave;
	end

	-- ignore_pain,if=talent.battlelord&talent.anger_management&rage>30&(target.health.pct>20|talent.massacre&target.health.pct>35);
	if talents[AR.IgnorePain] and cooldown[AR.IgnorePain].ready and rage >= 0 and (talents[AR.Battlelord] and talents[AR.AngerManagement] and rage > 30 and ( targetHp > 20 or talents[AR.Massacre] and targetHp > 35 )) then
		return AR.IgnorePain;
	end

	-- slam,if=talent.crushing_force&rage>30&(talent.fervor_of_battle&active_enemies=1|!talent.fervor_of_battle);
	if rage >= 30 and (talents[AR.CrushingForce] and rage > 30 and ( talents[AR.FervorOfBattle] and targets == 1 or not talents[AR.FervorOfBattle] )) then
		return AR.Slam;
	end

	-- shockwave,if=talent.sonic_boom;
	if talents[AR.Shockwave] and cooldown[AR.Shockwave].ready and (talents[AR.SonicBoom]) then
		return AR.Shockwave;
	end

	-- bladestorm,if=raid_event.adds.in>30;
	if cooldown[AR.Bladestorm].ready then
		return AR.Bladestorm;
	end

	-- wrecking_throw;
	if talents[AR.WreckingThrow] and cooldown[AR.WreckingThrow].ready then
		return AR.WreckingThrow;
	end
end

function Warrior:ArmsSingleTarget()
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
	local rage = UnitPower('player', Enum.PowerType.Rage);
	local rageMax = UnitPowerMax('player', Enum.PowerType.Rage);
	local ragePct = UnitPower('player')/UnitPowerMax('player') * 100;
	local rageRegen = select(2,GetPowerRegen());
	local rageRegenCombined = rageRegen + rage;
	local rageDeficit = UnitPowerMax('player', Enum.PowerType.Rage) - rage;
	local rageTimeToMax = rageMax - rage / rageRegen;
	local canExecute = ((talents[FR.Massacre] and targetHp < 35) or targetHp < 20) or buff[FR.SuddenDeathAura].up;

	-- sweeping_strikes,if=spell_targets.whirlwind>1;
	if cooldown[AR.SweepingStrikes].ready and (targets > 1) then
		return AR.SweepingStrikes;
	end

	-- mortal_strike;
	if talents[AR.MortalStrike] and cooldown[AR.MortalStrike].ready and rage >= 30 then
		return AR.MortalStrike;
	end

	-- rend,if=remains<=gcd|talent.tide_of_blood&cooldown.skullsplitter.remains<=gcd&(cooldown.colossus_smash.remains<=gcd|debuff.colossus_smash.up)&dot.rend.remains<dot.rend.duration*0.85;
	if talents[AR.Rend] and rage >= 30 and (debuff[AR.Rend].remains <= gcd or talents[AR.TideOfBlood] and cooldown[AR.Skullsplitter].remains <= gcd and ( cooldown[AR.ColossusSmash].remains <= gcd or debuff[AR.ColossusSmash].up ) and debuff[AR.Rend].remains < debuff[AR.Rend].duration * 0.85) then
		return AR.Rend;
	end

	-- avatar,if=talent.warlords_torment&rage.pct<33&(cooldown.colossus_smash.ready|debuff.colossus_smash.up|buff.test_of_might.up)|!talent.warlords_torment&(cooldown.colossus_smash.ready|debuff.colossus_smash.up);
	if talents[AR.Avatar] and cooldown[AR.Avatar].ready and (talents[AR.WarlordsTorment] and ragePct < 33 and ( cooldown[AR.ColossusSmash].ready or debuff[AR.ColossusSmash].up or buff[AR.TestOfMight].up ) or not talents[AR.WarlordsTorment] and ( cooldown[AR.ColossusSmash].ready or debuff[AR.ColossusSmash].up )) then
		return AR.Avatar;
	end

	-- spear_of_bastion,if=cooldown.colossus_smash.remains<=gcd|cooldown.warbreaker.remains<=gcd;
	if talents[AR.SpearOfBastion] and cooldown[AR.SpearOfBastion].ready and (cooldown[AR.ColossusSmash].remains <= gcd or cooldown[AR.Warbreaker].remains <= gcd) then
		return AR.SpearOfBastion;
	end

	-- warbreaker;
	if talents[AR.Warbreaker] and cooldown[AR.Warbreaker].ready then
		return AR.Warbreaker;
	end

	-- colossus_smash;
	if talents[AR.ColossusSmash] and cooldown[AR.ColossusSmash].ready then
		return AR.ColossusSmash;
	end

	-- thunderous_roar,if=buff.test_of_might.up|talent.test_of_might&debuff.colossus_smash.up&rage.pct<33|!talent.test_of_might&debuff.colossus_smash.up;
	if talents[AR.ThunderousRoar] and cooldown[AR.ThunderousRoar].ready and (buff[AR.TestOfMight].up or talents[AR.TestOfMight] and debuff[AR.ColossusSmash].up and ragePct < 33 or not talents[AR.TestOfMight] and debuff[AR.ColossusSmash].up) then
		return AR.ThunderousRoar;
	end

	-- bladestorm,if=talent.hurricane&(buff.test_of_might.up|!talent.test_of_might&debuff.colossus_smash.up)|talent.unhinged&(buff.test_of_might.up|!talent.test_of_might&debuff.colossus_smash.up);
	if cooldown[AR.Bladestorm].ready and (talents[AR.Hurricane] and ( buff[AR.TestOfMight].up or not talents[AR.TestOfMight] and debuff[AR.ColossusSmash].up ) or talents[AR.Unhinged] and ( buff[AR.TestOfMight].up or not talents[AR.TestOfMight] and debuff[AR.ColossusSmash].up )) then
		return AR.Bladestorm;
	end

	-- skullsplitter,if=talent.tide_of_blood&dot.rend.remains&(debuff.colossus_smash.up|cooldown.colossus_smash.remains>gcd*4&buff.test_of_might.up|!talent.test_of_might&cooldown.colossus_smash.remains>gcd*4)|rage<30;
	if talents[AR.Skullsplitter] and cooldown[AR.Skullsplitter].ready and (talents[AR.TideOfBlood] and debuff[AR.Rend].remains and ( debuff[AR.ColossusSmash].up or cooldown[AR.ColossusSmash].remains > gcd * 4 and buff[AR.TestOfMight].up or not talents[AR.TestOfMight] and cooldown[AR.ColossusSmash].remains > gcd * 4 ) or rage < 30) then
		return AR.Skullsplitter;
	end

	-- execute,if=buff.sudden_death.react;
	if canExecute and cooldown[AR.Execute].ready and rage >= 40 and (buff[AR.SuddenDeath].count) then
		return AR.Execute;
	end

	-- shockwave,if=talent.sonic_boom.enabled;
	if talents[AR.Shockwave] and cooldown[AR.Shockwave].ready and (talents[AR.SonicBoom]) then
		return AR.Shockwave;
	end

	-- ignore_pain,if=talent.anger_management|talent.test_of_might&debuff.colossus_smash.up;
	if talents[AR.IgnorePain] and cooldown[AR.IgnorePain].ready and rage >= 0 and (talents[AR.AngerManagement] or talents[AR.TestOfMight] and debuff[AR.ColossusSmash].up) then
		return AR.IgnorePain;
	end

	-- whirlwind,if=talent.storm_of_swords&talent.battlelord&rage.pct>80&debuff.colossus_smash.up;
	if rage >= 60 and (talents[AR.StormOfSwords] and talents[AR.Battlelord] and ragePct > 80 and debuff[AR.ColossusSmash].up) then
		return AR.Whirlwind;
	end

	-- overpower,if=charges=2&!talent.battlelord&(debuff.colossus_smash.down|rage.pct<25)|talent.battlelord;
	if talents[AR.Overpower] and cooldown[AR.Overpower].ready and (cooldown[AR.Overpower].charges == 2 and not talents[AR.Battlelord] and ( not debuff[AR.ColossusSmash].up or ragePct < 25 ) or talents[AR.Battlelord]) then
		return AR.Overpower;
	end

	-- whirlwind,if=talent.storm_of_swords|talent.fervor_of_battle&active_enemies>1;
	if rage >= 60 and (talents[AR.StormOfSwords] or talents[AR.FervorOfBattle] and targets > 1) then
		return AR.Whirlwind;
	end

	-- thunder_clap,if=talent.battlelord&talent.blood_and_thunder;
	if talents[AR.ThunderClap] and cooldown[AR.ThunderClap].ready and rage >= 40 and (talents[AR.Battlelord] and talents[AR.BloodAndThunder]) then
		return AR.ThunderClap;
	end

	-- overpower,if=debuff.colossus_smash.down&rage.pct<50&!talent.battlelord|rage.pct<25;
	if talents[AR.Overpower] and cooldown[AR.Overpower].ready and (not debuff[AR.ColossusSmash].up and ragePct < 50 and not talents[AR.Battlelord] or ragePct < 25) then
		return AR.Overpower;
	end

	-- whirlwind,if=buff.merciless_bonegrinder.up;
	if rage >= 60 and (buff[AR.MercilessBonegrinder].up) then
		return AR.Whirlwind;
	end

	-- cleave,if=set_bonus.tier29_2pc&!talent.crushing_force;
	if talents[AR.Cleave] and cooldown[AR.Cleave].ready and rage >= 20 and (MaxDps.tier[29] and MaxDps.tier[29].count and (MaxDps.tier[29].count == 2) and not talents[AR.CrushingForce]) then
		return AR.Cleave;
	end

	-- slam,if=rage>30&(!talent.fervor_of_battle|talent.fervor_of_battle&active_enemies=1);
	if rage >= 30 and (rage > 30 and ( not talents[AR.FervorOfBattle] or talents[AR.FervorOfBattle] and targets == 1 )) then
		return AR.Slam;
	end

	-- bladestorm;
	if cooldown[AR.Bladestorm].ready then
		return AR.Bladestorm;
	end

	-- cleave;
	if talents[AR.Cleave] and cooldown[AR.Cleave].ready and rage >= 20 then
		return AR.Cleave;
	end

	-- wrecking_throw;
	if talents[AR.WreckingThrow] and cooldown[AR.WreckingThrow].ready then
		return AR.WreckingThrow;
	end

	-- rend,if=remains<duration*0.3;
	if talents[AR.Rend] and rage >= 30 and (debuff[AR.Rend].remains < cooldown[AR.Rend].duration * 0.3) then
		return AR.Rend;
	end
end


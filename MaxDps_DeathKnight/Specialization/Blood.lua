local _, addonTable = ...;

-- @type MaxDps;
if not MaxDps then return end;
local DeathKnight = addonTable.Deathknight;
local MaxDps = MaxDps;

local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;

local itemID = GetInventoryItemID('player', INVSLOT_MAINHAND);

local mainHandSubClassID = itemID and  select(13, GetItemInfo(itemID));

local TwoHanderWepCheck = mainHandSubClassID and (mainHandSubClassID == 1 or mainHandSubClassID == 5 or mainHandSubClassID == 8 or mainHandSubClassID == 10);

local BL = {
	DeathsCaress = 195292,
	Consumption = 274156,
	Blooddrinker = 206931,
	MindFreeze = 47528,
	RaiseDead = 46585,
	IceboundFortitude = 48792,
	DancingRuneWeapon = 49028,
	VampiricBlood = 55233,
	VampiricStrength = 408356,
	BoneShield = 195181,
	DeathAndDecay = 43265,
	UnholyGround = 374265,
	SanguineGround = 391458,
	CrimsonScourge = 81136,
	DeathStrike = 49998,
	Coagulopathy = 391477,
	IcyTalons = 194878,
	SacrificialPact = 327574,
	BloodTap = 221699,
	GorefiendsGrasp = 108199,
	TighteningGrasp = 206970,
	EmpowerRuneWeapon = 47568,
	AbominationLimb = 383269,
	BloodBoil = 50842,
	BloodPlague = 55078,
	Tombstone = 219809,
	ShatteringBone = 377640,
	Marrowrend = 195182,
	SoulReaper = 343294,
	Heartbreaker = 221536,
	Hemostasis = 273946,
	HeartStrike = 206930,
	InsatiableBlade = 377637,
	Bonestorm = 194844,
};
local A = {
};
function DeathKnight:Blood()
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
	local runes = UnitPower('player', Enum.PowerType.Runes);
	local runesduration = select(2,GetRuneCooldown(1));
	local runesRegen = runesduration and math.floor(runesduration*100)/100;
	local runesTimeTo2 = DeathKnight:TimeToRunes(2);
	local runesTimeTo3 = DeathKnight:TimeToRunes(3);
	local runesTimeTo4 = DeathKnight:TimeToRunes(4);
	local runicPower = UnitPower('player', Enum.PowerType.RunicPower);
	local runicPowerMax = UnitPowerMax('player', Enum.PowerType.RunicPower);
	local runicPowerPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local runicPowerRegen = select(2,GetPowerRegen());
	local runicPowerRegenCombined = runicPowerRegen + runicPower;
	local runicPowerDeficit = UnitPowerMax('player', Enum.PowerType.RunicPower) - runicPower;
	local runicPowerTimeToMax = runicPowerMax - runicPower / runicPowerRegen;
	local runeforge = fd.runeforge;

	-- variable,name=death_strike_dump_amount,value=65;
	local deathStrikeDumpAmount = 65;

	-- variable,name=bone_shield_refresh_value,value=4,op=setif,condition=!talent.deaths_caress.enabled|talent.consumption.enabled|talent.blooddrinker.enabled,value_else=5;
	local boneShieldRefreshValue
	if not talents[BL.DeathsCaress] or talents[BL.Consumption] or talents[BL.Blooddrinker] then
		boneShieldRefreshValue = 4;
	else
		boneShieldRefreshValue = 5;
	end
	local heartStrikeRp = ( 10 + targets * (talents[BL.Heartbreaker] and 1 or 0) * 2 );

	-- call_action_list,name=trinkets;

	-- raise_dead;
	if talents[BL.RaiseDead] and cooldown[BL.RaiseDead].ready then
		return BL.RaiseDead;
	end

	-- icebound_fortitude,if=!(buff.dancing_rune_weapon.up|buff.vampiric_blood.up)&(target.cooldown.pause_action.remains>=8|target.cooldown.pause_action.duration>0);
	if talents[BL.IceboundFortitude] and cooldown[BL.IceboundFortitude].ready and (not ( buff[BL.DancingRuneWeapon].up or buff[BL.VampiricBlood].up ) and ( timeToDie >= 8 or timeToDie > 0 )) then
		return BL.IceboundFortitude;
	end

	-- vampiric_blood,if=!buff.vampiric_blood.up&!buff.vampiric_strength.up;
	if talents[BL.VampiricBlood] and cooldown[BL.VampiricBlood].ready and (not buff[BL.VampiricBlood].up and not buff[BL.VampiricStrength].up) then
		return BL.VampiricBlood;
	end

	-- vampiric_blood,if=!(buff.dancing_rune_weapon.up|buff.icebound_fortitude.up|buff.vampiric_blood.up|buff.vampiric_strength.up)&(target.cooldown.pause_action.remains>=13|target.cooldown.pause_action.duration>0);
	if talents[BL.VampiricBlood] and cooldown[BL.VampiricBlood].ready and (not ( buff[BL.DancingRuneWeapon].up or buff[BL.IceboundFortitude].up or buff[BL.VampiricBlood].up or buff[BL.VampiricStrength].up ) and ( timeToDie >= 13 or timeToDie > 0 )) then
		return BL.VampiricBlood;
	end

	-- deaths_caress,if=!buff.bone_shield.up;
	if talents[BL.DeathsCaress] and cooldown[BL.DeathsCaress].ready and runes >= 1 and runicPower >= 10 and (not buff[BL.BoneShield].up) then
		return BL.DeathsCaress;
	end

	-- death_and_decay,if=!death_and_decay.ticking&(talent.unholy_ground|talent.sanguine_ground|spell_targets.death_and_decay>3|buff.crimson_scourge.up);
	if cooldown[BL.DeathAndDecay].ready and runes >= 1 and runicPower >= 10 and (not debuff[BL.DeathAndDecay].up and ( talents[BL.UnholyGround] or talents[BL.SanguineGround] or targets > 3 or buff[BL.CrimsonScourge].up )) then
		return BL.DeathAndDecay;
	end

	-- death_strike,if=buff.coagulopathy.remains<=gcd|buff.icy_talons.remains<=gcd|runic_power>=variable.death_strike_dump_amount|runic_power.deficit<=variable.heart_strike_rp|target.time_to_die<10;
	if talents[BL.DeathStrike] and runicPower >= 40 and (buff[BL.Coagulopathy].remains <= gcd or buff[BL.IcyTalons].remains <= gcd or runicPower >= deathStrikeDumpAmount or runicPowerDeficit <= heartStrikeRp or timeToDie < 10) then
		return BL.DeathStrike;
	end

	-- blooddrinker,if=!buff.dancing_rune_weapon.up;
	if talents[BL.Blooddrinker] and cooldown[BL.Blooddrinker].ready and runes >= 1 and runicPower >= 10 and (not buff[BL.DancingRuneWeapon].up) then
		return BL.Blooddrinker;
	end

	-- call_action_list,name=racials;

	-- sacrificial_pact,if=!buff.dancing_rune_weapon.up&(pet.ghoul.remains<2|target.time_to_die<gcd);
	if talents[BL.SacrificialPact] and cooldown[BL.SacrificialPact].ready and runicPower >= 20 and (not buff[BL.DancingRuneWeapon].up and ( ghoulRemains < 2 or timeToDie < gcd )) then
		return BL.SacrificialPact;
	end

	-- blood_tap,if=(rune<=2&rune.time_to_4>gcd&charges_fractional>=1.8)|rune.time_to_3>gcd;
	if talents[BL.BloodTap] and cooldown[BL.BloodTap].ready and (( runes <= 2 and runesTimeTo4 > gcd and cooldown[BL.BloodTap].charges >= 1.8 ) or runesTimeTo3 > gcd) then
		return BL.BloodTap;
	end

	-- gorefiends_grasp,if=talent.tightening_grasp.enabled;
	if talents[BL.GorefiendsGrasp] and cooldown[BL.GorefiendsGrasp].ready and (talents[BL.TighteningGrasp]) then
		return BL.GorefiendsGrasp;
	end

	-- empower_rune_weapon,if=rune<6&runic_power.deficit>5;
	if talents[BL.EmpowerRuneWeapon] and cooldown[BL.EmpowerRuneWeapon].ready and (runes < 6 and runicPowerDeficit > 5) then
		return BL.EmpowerRuneWeapon;
	end

	-- abomination_limb;
	if talents[BL.AbominationLimb] and cooldown[BL.AbominationLimb].ready then
		return BL.AbominationLimb;
	end

	-- dancing_rune_weapon,if=!buff.dancing_rune_weapon.up;
	if talents[BL.DancingRuneWeapon] and cooldown[BL.DancingRuneWeapon].ready and (not buff[BL.DancingRuneWeapon].up) then
		return BL.DancingRuneWeapon;
	end

	-- run_action_list,name=drw_up,if=buff.dancing_rune_weapon.up;
	if buff[BL.DancingRuneWeapon].up then
		return DeathKnight:BloodDrwUp();
	end

	-- call_action_list,name=standard;
	local result = DeathKnight:BloodStandard();
	if result then
		return result;
	end
end
function DeathKnight:BloodDrwUp()
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
	local runes = UnitPower('player', Enum.PowerType.Runes);
	local runesduration = select(2,GetRuneCooldown(1));
	local runesRegen = runesduration and math.floor(runesduration*100)/100;
	local runesTimeTo2 = DeathKnight:TimeToRunes(2);
	local runesTimeTo3 = DeathKnight:TimeToRunes(3);
	local runesTimeTo4 = DeathKnight:TimeToRunes(4);
	local runicPower = UnitPower('player', Enum.PowerType.RunicPower);
	local runicPowerMax = UnitPowerMax('player', Enum.PowerType.RunicPower);
	local runicPowerPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local runicPowerRegen = select(2,GetPowerRegen());
	local runicPowerRegenCombined = runicPowerRegen + runicPower;
	local runicPowerDeficit = UnitPowerMax('player', Enum.PowerType.RunicPower) - runicPower;
	local runicPowerTimeToMax = runicPowerMax - runicPower / runicPowerRegen;
	local health = UnitPower('player', Enum.PowerType.Health);
	local healthMax = UnitPowerMax('player', Enum.PowerType.Health);
	local healthPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local healthRegen = select(2,GetPowerRegen());
	local healthRegenCombined = healthRegen + health;
	local healthDeficit = UnitPowerMax('player', Enum.PowerType.Health) - health;
	local healthTimeToMax = healthMax - health / healthRegen;
	local runeforge = fd.runeforge;

	local deathStrikeDumpAmount = 65;

	-- blood_boil,if=!dot.blood_plague.ticking;
	if talents[BL.BloodBoil] and cooldown[BL.BloodBoil].ready and (not debuff[BL.BloodPlague].up) then
		return BL.BloodBoil;
	end

	-- tombstone,if=buff.bone_shield.stack>5&rune>=2&runic_power.deficit>=30&!talent.shattering_bone|(talent.shattering_bone.enabled&death_and_decay.ticking);
	if talents[BL.Tombstone] and cooldown[BL.Tombstone].ready and (buff[BL.BoneShield].count > 5 and runes >= 2 and runicPowerDeficit >= 30 and not talents[BL.ShatteringBone] or ( talents[BL.ShatteringBone] and debuff[BL.DeathAndDecay].up )) then
		return BL.Tombstone;
	end

	-- death_strike,if=buff.coagulopathy.remains<=gcd|buff.icy_talons.remains<=gcd;
	if talents[BL.DeathStrike] and runicPower >= 40 and (buff[BL.Coagulopathy].remains <= gcd or buff[BL.IcyTalons].remains <= gcd) then
		return BL.DeathStrike;
	end

	-- marrowrend,if=(buff.bone_shield.remains<=4|buff.bone_shield.stack<variable.bone_shield_refresh_value)&runic_power.deficit>20;
	if talents[BL.Marrowrend] and runes >= 2 and runicPower >= 20 and (( buff[BL.BoneShield].remains <= 4 or buff[BL.BoneShield].count < boneShieldRefreshValue ) and runicPowerDeficit > 20) then
		return BL.Marrowrend;
	end

	-- soul_reaper,if=active_enemies=1&target.time_to_pct_35<5&target.time_to_die>(dot.soul_reaper.remains+5);
	if talents[BL.SoulReaper] and cooldown[BL.SoulReaper].ready and runes >= 1 and runicPower >= 10 and (targets == 1 and timeTo35 < 5 and timeToDie > ( debuff[BL.SoulReaper].remains + 5 )) then
		return BL.SoulReaper;
	end

	-- soul_reaper,target_if=min:dot.soul_reaper.remains,if=target.time_to_pct_35<5&active_enemies>=2&target.time_to_die>(dot.soul_reaper.remains+5);
	if talents[BL.SoulReaper] and cooldown[BL.SoulReaper].ready and runes >= 1 and runicPower >= 10 and (timeTo35 < 5 and targets >= 2 and timeToDie > ( debuff[BL.SoulReaper].remains + 5 )) then
		return BL.SoulReaper;
	end

	-- death_and_decay,if=!death_and_decay.ticking&(talent.sanguine_ground|talent.unholy_ground);
	if cooldown[BL.DeathAndDecay].ready and runes >= 1 and runicPower >= 10 and (not debuff[BL.DeathAndDecay].up and ( talents[BL.SanguineGround] or talents[BL.UnholyGround] )) then
		return BL.DeathAndDecay;
	end

	-- blood_boil,if=spell_targets.blood_boil>2&charges_fractional>=1.1;
	if talents[BL.BloodBoil] and cooldown[BL.BloodBoil].ready and (targets > 2 and cooldown[BL.BloodBoil].charges >= 1.1) then
		return BL.BloodBoil;
	end

	-- variable,name=heart_strike_rp_drw,value=(25+spell_targets.heart_strike*talent.heartbreaker.enabled*2);
	local heartStrikeRpDrw = ( 25 + targets * (talents[BL.Heartbreaker] and 1 or 0) * 2 );

	-- death_strike,if=runic_power.deficit<=variable.heart_strike_rp_drw|runic_power>=variable.death_strike_dump_amount;
	if talents[BL.DeathStrike] and runicPower >= 40 and (runicPowerDeficit <= heartStrikeRpDrw or runicPower >= deathStrikeDumpAmount) then
		return BL.DeathStrike;
	end

	-- consumption;
	if talents[BL.Consumption] and cooldown[BL.Consumption].ready then
		return BL.Consumption;
	end

	-- blood_boil,if=charges_fractional>=1.1&buff.hemostasis.stack<5;
	if talents[BL.BloodBoil] and cooldown[BL.BloodBoil].ready and (cooldown[BL.BloodBoil].charges >= 1.1 and buff[BL.Hemostasis].count < 5) then
		return BL.BloodBoil;
	end

	-- heart_strike,if=rune.time_to_2<gcd|runic_power.deficit>=variable.heart_strike_rp_drw;
	if talents[BL.HeartStrike] and runes >= 1 and runicPower >= 15 and health >= 0 and (runesTimeTo2 < gcd or runicPowerDeficit >= heartStrikeRpDrw) then
		return BL.HeartStrike;
	end
end

function DeathKnight:BloodStandard()
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
	local runes = UnitPower('player', Enum.PowerType.Runes);
	local runesduration = select(2,GetRuneCooldown(1));
	local runesRegen = runesduration and math.floor(runesduration*100)/100;
	local runesTimeTo2 = DeathKnight:TimeToRunes(2);
	local runesTimeTo3 = DeathKnight:TimeToRunes(3);
	local runesTimeTo4 = DeathKnight:TimeToRunes(4);
	local runicPower = UnitPower('player', Enum.PowerType.RunicPower);
	local runicPowerMax = UnitPowerMax('player', Enum.PowerType.RunicPower);
	local runicPowerPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local runicPowerRegen = select(2,GetPowerRegen());
	local runicPowerRegenCombined = runicPowerRegen + runicPower;
	local runicPowerDeficit = UnitPowerMax('player', Enum.PowerType.RunicPower) - runicPower;
	local runicPowerTimeToMax = runicPowerMax - runicPower / runicPowerRegen;
	local health = UnitPower('player', Enum.PowerType.Health);
	local healthMax = UnitPowerMax('player', Enum.PowerType.Health);
	local healthPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local healthRegen = select(2,GetPowerRegen());
	local healthRegenCombined = healthRegen + health;
	local healthDeficit = UnitPowerMax('player', Enum.PowerType.Health) - health;
	local healthTimeToMax = healthMax - health / healthRegen;
	local runeforge = fd.runeforge;

	local deathStrikeDumpAmount = 65;

	-- tombstone,if=buff.bone_shield.stack>5&rune>=2&runic_power.deficit>=30&!talent.shattering_bone|(talent.shattering_bone.enabled&death_and_decay.ticking)&cooldown.dancing_rune_weapon.remains>=25;
	if talents[BL.Tombstone] and cooldown[BL.Tombstone].ready and (buff[BL.BoneShield].count > 5 and runes >= 2 and runicPowerDeficit >= 30 and not talents[BL.ShatteringBone] or ( talents[BL.ShatteringBone] and debuff[BL.DeathAndDecay].up ) and cooldown[BL.DancingRuneWeapon].remains >= 25) then
		return BL.Tombstone;
	end

	-- variable,name=heart_strike_rp,value=(10+spell_targets.heart_strike*talent.heartbreaker.enabled*2);
	local heartStrikeRp = ( 10 + targets * (talents[BL.Heartbreaker] and 1 or 0) * 2 );

	-- death_strike,if=buff.coagulopathy.remains<=gcd|buff.icy_talons.remains<=gcd|runic_power>=variable.death_strike_dump_amount|runic_power.deficit<=variable.heart_strike_rp|target.time_to_die<10;
	if talents[BL.DeathStrike] and runicPower >= 40 and (buff[BL.Coagulopathy].remains <= gcd or buff[BL.IcyTalons].remains <= gcd or runicPower >= deathStrikeDumpAmount or runicPowerDeficit <= heartStrikeRp or timeToDie < 10) then
		return BL.DeathStrike;
	end

	-- deaths_caress,if=(buff.bone_shield.remains<=4|(buff.bone_shield.stack<variable.bone_shield_refresh_value+1))&runic_power.deficit>10&!(talent.insatiable_blade&cooldown.dancing_rune_weapon.remains<buff.bone_shield.remains)&!talent.consumption.enabled&!talent.blooddrinker.enabled&rune.time_to_3>gcd;
	if talents[BL.DeathsCaress] and cooldown[BL.DeathsCaress].ready and runes >= 1 and runicPower >= 10 and (( buff[BL.BoneShield].remains <= 4 or ( buff[BL.BoneShield].count < boneShieldRefreshValue + 1 ) ) and runicPowerDeficit > 10 and not ( talents[BL.InsatiableBlade] and cooldown[BL.DancingRuneWeapon].remains < buff[BL.BoneShield].remains ) and not talents[BL.Consumption] and not talents[BL.Blooddrinker] and runesTimeTo3 > gcd) then
		return BL.DeathsCaress;
	end

	-- marrowrend,if=(buff.bone_shield.remains<=4|buff.bone_shield.stack<variable.bone_shield_refresh_value)&runic_power.deficit>20&!(talent.insatiable_blade&cooldown.dancing_rune_weapon.remains<buff.bone_shield.remains);
	if talents[BL.Marrowrend] and runes >= 2 and runicPower >= 20 and (( buff[BL.BoneShield].remains <= 4 or buff[BL.BoneShield].count < boneShieldRefreshValue ) and runicPowerDeficit > 20 and not ( talents[BL.InsatiableBlade] and cooldown[BL.DancingRuneWeapon].remains < buff[BL.BoneShield].remains )) then
		return BL.Marrowrend;
	end

	-- consumption;
	if talents[BL.Consumption] and cooldown[BL.Consumption].ready then
		return BL.Consumption;
	end

	-- soul_reaper,if=active_enemies=1&target.time_to_pct_35<5&target.time_to_die>(dot.soul_reaper.remains+5);
	if talents[BL.SoulReaper] and cooldown[BL.SoulReaper].ready and runes >= 1 and runicPower >= 10 and (targets == 1 and timeTo35 < 5 and timeToDie > ( debuff[BL.SoulReaper].remains + 5 )) then
		return BL.SoulReaper;
	end

	-- soul_reaper,target_if=min:dot.soul_reaper.remains,if=target.time_to_pct_35<5&active_enemies>=2&target.time_to_die>(dot.soul_reaper.remains+5);
	if talents[BL.SoulReaper] and cooldown[BL.SoulReaper].ready and runes >= 1 and runicPower >= 10 and (timeTo35 < 5 and targets >= 2 and timeToDie > ( debuff[BL.SoulReaper].remains + 5 )) then
		return BL.SoulReaper;
	end

	-- bonestorm,if=runic_power>=100;
	if talents[BL.Bonestorm] and cooldown[BL.Bonestorm].ready and runicPower >= 100 and (runicPower >= 100) then
		return BL.Bonestorm;
	end

	-- blood_boil,if=charges_fractional>=1.8&(buff.hemostasis.stack<=(5-spell_targets.blood_boil)|spell_targets.blood_boil>2);
	if talents[BL.BloodBoil] and cooldown[BL.BloodBoil].ready and (cooldown[BL.BloodBoil].charges >= 1.8 and ( buff[BL.Hemostasis].count <= ( 5 - targets ) or targets > 2 )) then
		return BL.BloodBoil;
	end

	-- heart_strike,if=rune.time_to_4<gcd;
	if talents[BL.HeartStrike] and runes >= 1 and runicPower >= 15 and health >= 0 and (runesTimeTo4 < gcd) then
		return BL.HeartStrike;
	end

	-- blood_boil,if=charges_fractional>=1.1;
	if talents[BL.BloodBoil] and cooldown[BL.BloodBoil].ready and (cooldown[BL.BloodBoil].charges >= 1.1) then
		return BL.BloodBoil;
	end

	-- heart_strike,if=(rune>1&(rune.time_to_3<gcd|buff.bone_shield.stack>7));
	if talents[BL.HeartStrike] and runes >= 1 and runicPower >= 15 and health >= 0 and (( runes > 1 and ( runesTimeTo3 < gcd or buff[BL.BoneShield].count > 7 ) )) then
		return BL.HeartStrike;
	end
end



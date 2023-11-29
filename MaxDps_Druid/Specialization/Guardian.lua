local _, addonTable = ...;

-- @type MaxDps;
if not MaxDps then return end;
local Druid = addonTable.Druid;
local MaxDps = MaxDps;

local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;

local itemID = GetInventoryItemID('player', INVSLOT_MAINHAND);

local mainHandSubClassID = itemID and  select(13, GetItemInfo(itemID));

local TwoHanderWepCheck = mainHandSubClassID and (mainHandSubClassID == 1 or mainHandSubClassID == 5 or mainHandSubClassID == 8 or mainHandSubClassID == 10);

local GR = {
	ThornsOfIron = 400222,
	ReinforcedFur = 393618,
	CatForm = 768,
	MoonkinForm = 197625,
	HeartOfTheWild = 319454,
	Prowl = 5215,
	BearForm = 5487,
	ToothAndClaw = 135288,
	Berserk = 50334,
	Thrash = 106832,
	Mangle = 33917,
	Moonfire = 8921,
	FuryOfNature = 370695,
	FlashingClaws = 393427,
	BristlingFur = 155835,
	Barkskin = 22812,
	ConvokeTheSpirits = 391528,
	Incarnation = 102558,
	LunarBeam = 204066,
	RageOfTheSleeper = 200851,
	Maul = 6807,
	Raze = 400254,
	Ironfur = 192081,
	ToothAndClawDebuff = 135601,
	Gore = 210706,
	Swipe = 213771,
	SoulOfTheForest = 158477,
	Pulverize = 80313,
	GalacticGuardian = 203964,
	Rake = 1822,
	Rip = 1079,
	FerociousBite = 22568,
	Shred = 5221,
};
local A = {
};
function Druid:Guardian()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;

	-- run_action_list,name=catweave,if=(target.cooldown.pause_action.remains|time>=30)&druid.catweave_bear=1&buff.tooth_and_claw.remains>1.5&(buff.incarnation_guardian_of_ursoc.down&buff.berserk_bear.down)&(cooldown.thrash_bear.remains>0&cooldown.mangle.remains>0&dot.moonfire.remains>=2)|(buff.cat_form.up&energy>25&druid.catweave_bear=1&buff.tooth_and_claw.remains>1.5)|(buff.heart_of_the_wild.up&energy>90&druid.catweave_bear=1&buff.tooth_and_claw.remains>1.5);
	if ( timeToDie or GetTime() >= 30 ) and druidCatweaveBear == 1 and buff[GR.ToothAndClaw].remains > 1.5 and ( not buff[GR.IncarnationGuardianOfUrsoc].up and not buff[GR.BerserkBear].up ) and ( cooldown[GR.ThrashBear].remains > 0 and cooldown[GR.Mangle].remains > 0 and debuff[GR.Moonfire].remains >= 2 ) or ( buff[GR.CatForm].up and energy > 25 and druidCatweaveBear == 1 and buff[GR.ToothAndClaw].remains > 1.5 ) or ( buff[GR.HeartOfTheWild].up and energy > 90 and druidCatweaveBear == 1 and buff[GR.ToothAndClaw].remains > 1.5 ) then
		return Druid:GuardianCatweave();
	end

	-- run_action_list,name=bear;
	return Druid:GuardianBear();
end
function Druid:GuardianBear()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
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
	local rage = UnitPower('player', Enum.PowerType.Rage);
	local rageMax = UnitPowerMax('player', Enum.PowerType.Rage);
	local ragePct = UnitPower('player')/UnitPowerMax('player') * 100;
	local rageRegen = select(2,GetPowerRegen());
	local rageRegenCombined = rageRegen + rage;
	local rageDeficit = UnitPowerMax('player', Enum.PowerType.Rage) - rage;
	local rageTimeToMax = rageMax - rage / rageRegen;

	-- bear_form,if=!buff.bear_form.up;
	if not buff[GR.BearForm].up then
		return GR.BearForm;
	end

	-- heart_of_the_Wild,if=talent.heart_of_the_wild.enabled;
	if talents[GR.HeartOfTheWild] then
		return GR.HeartOfTheWild;
	end

	-- moonfire,cycle_targets=1,if=(((!ticking&time_to_die>12)|(refreshable&time_to_die>12))&active_enemies<7&talent.fury_of_nature.enabled)|(((!ticking&time_to_die>12)|(refreshable&time_to_die>12))&active_enemies<4&!talent.fury_of_nature.enabled);
	if mana >= 0 and (( ( ( not debuff[GR.Moonfire].up and timeToDie > 12 ) or ( debuff[GR.Moonfire].refreshable and timeToDie > 12 ) ) and targets < 7 and talents[GR.FuryOfNature] ) or ( ( ( not debuff[GR.Moonfire].up and timeToDie > 12 ) or ( debuff[GR.Moonfire].refreshable and timeToDie > 12 ) ) and targets < 4 and not talents[GR.FuryOfNature] )) then
		return GR.Moonfire;
	end

	-- thrash_bear,target_if=refreshable|(dot.thrash_bear.stack<5&talent.flashing_claws.rank=2|dot.thrash_bear.stack<4&talent.flashing_claws.rank=1|dot.thrash_bear.stack<3&!talent.flashing_claws.enabled);
	if talents[GR.Thrash] then
		return GR.Thrash;
	end

	-- bristling_fur,if=!cooldown.pause_action.remains;
	if talents[GR.BristlingFur] and cooldown[GR.BristlingFur].ready and (not cooldown[GR.BristlingFur].remains>=1) then
		return GR.BristlingFur;
	end

	-- barkskin,if=buff.bear_form.up;
	if cooldown[GR.Barkskin].ready and (buff[GR.BearForm].up) then
		return GR.Barkskin;
	end

	-- convoke_the_spirits;
	if talents[GR.ConvokeTheSpirits] and cooldown[GR.ConvokeTheSpirits].ready then
		return GR.ConvokeTheSpirits;
	end

	-- berserk_bear;
	if talents[GR.Berserk] and cooldown[GR.Berserk].ready then
		return GR.Berserk;
	end

	-- incarnation;
	-- GR.Incarnation;

	-- lunar_beam;
	if talents[GR.LunarBeam] and cooldown[GR.LunarBeam].ready then
		return GR.LunarBeam;
	end

	-- rage_of_the_sleeper,if=buff.incarnation_guardian_of_ursoc.down&cooldown.incarnation_guardian_of_ursoc.remains>60|buff.incarnation_guardian_of_ursoc.up|(talent.convoke_the_spirits.enabled);
	if talents[GR.RageOfTheSleeper] and cooldown[GR.RageOfTheSleeper].ready and (not buff[GR.IncarnationGuardianOfUrsoc].up and cooldown[GR.IncarnationGuardianOfUrsoc].remains > 60 or buff[GR.IncarnationGuardianOfUrsoc].up or ( talents[GR.ConvokeTheSpirits] )) then
		return GR.RageOfTheSleeper;
	end

	-- maul,if=(buff.rage_of_the_sleeper.up&buff.tooth_and_claw.stack>0&active_enemies<=6&!talent.raze.enabled&variable.If_build=0)|(buff.rage_of_the_sleeper.up&buff.tooth_and_claw.stack>0&active_enemies=1&talent.raze.enabled&variable.If_build=0);
	if talents[GR.Maul] and rage >= 40 and (( buff[GR.RageOfTheSleeper].up and buff[GR.ToothAndClaw].count > 0 and targets <= 6 and not talents[GR.Raze] and ifBuild == 0 ) or ( buff[GR.RageOfTheSleeper].up and buff[GR.ToothAndClaw].count > 0 and targets == 1 and talents[GR.Raze] and ifBuild == 0 )) then
		return GR.Maul;
	end

	-- raze,if=buff.rage_of_the_sleeper.up&buff.tooth_and_claw.stack>0&variable.If_build=0&active_enemies>1;
	if talents[GR.Raze] and rage >= 40 and (buff[GR.RageOfTheSleeper].up and buff[GR.ToothAndClaw].count > 0 and ifBuild == 0 and targets > 1) then
		return GR.Raze;
	end

	-- maul,if=(((buff.incarnation.up|buff.berserk_bear.up)&active_enemies<=5&!talent.raze.enabled&(buff.tooth_and_claw.stack>=1))&variable.If_build=0)|(((buff.incarnation.up|buff.berserk_bear.up)&active_enemies=1&talent.raze.enabled&(buff.tooth_and_claw.stack>=1))&variable.If_build=0);
	if talents[GR.Maul] and rage >= 40 and (( ( ( buff[GR.Incarnation].up or buff[GR.BerserkBear].up ) and targets <= 5 and not talents[GR.Raze] and ( buff[GR.ToothAndClaw].count >= 1 ) ) and ifBuild == 0 ) or ( ( ( buff[GR.Incarnation].up or buff[GR.BerserkBear].up ) and targets == 1 and talents[GR.Raze] and ( buff[GR.ToothAndClaw].count >= 1 ) ) and ifBuild == 0 )) then
		return GR.Maul;
	end

	-- raze,if=(buff.incarnation.up|buff.berserk_bear.up)&(variable.If_build=0)&active_enemies>1;
	if talents[GR.Raze] and rage >= 40 and (( buff[GR.Incarnation].up or buff[GR.BerserkBear].up ) and ( ifBuild == 0 ) and targets > 1) then
		return GR.Raze;
	end

	-- ironfur,target_if=!debuff.tooth_and_claw_debuff.up,if=!buff.ironfur.up&rage>50&!cooldown.pause_action.remains&variable.If_build=0&!buff.rage_of_the_sleeper.up|rage>90&variable.If_build=0&!buff.rage_of_the_sleeper.up;
	if talents[GR.Ironfur] and cooldown[GR.Ironfur].ready and rage >= 40 and (not buff[GR.Ironfur].up and rage > 50 and not cooldown[GR.Ironfur].remains>=1 and ifBuild == 0 and not buff[GR.RageOfTheSleeper].up or rage > 90 and ifBuild == 0 and not buff[GR.RageOfTheSleeper].up) then
		return GR.Ironfur;
	end

	-- ironfur,if=rage>90&variable.If_build=1|(buff.incarnation.up|buff.berserk_bear.up)&rage>20&variable.If_build=1;
	if talents[GR.Ironfur] and cooldown[GR.Ironfur].ready and rage >= 40 and (rage > 90 and ifBuild == 1 or ( buff[GR.Incarnation].up or buff[GR.BerserkBear].up ) and rage > 20 and ifBuild == 1) then
		return GR.Ironfur;
	end

	-- raze,if=(buff.tooth_and_claw.up)&active_enemies>1;
	if talents[GR.Raze] and rage >= 40 and (( buff[GR.ToothAndClaw].up ) and targets > 1) then
		return GR.Raze;
	end

	-- raze,if=(variable.If_build=0)&active_enemies>1;
	if talents[GR.Raze] and rage >= 40 and (( ifBuild == 0 ) and targets > 1) then
		return GR.Raze;
	end

	-- mangle,if=buff.gore.up&active_enemies<11|buff.vicious_cycle_mangle.stack=3;
	if cooldown[GR.Mangle].ready and (buff[GR.Gore].up and targets < 11 or buff[GR.ViciousCycleMangle].count == 3) then
		return GR.Mangle;
	end

	-- maul,if=(buff.tooth_and_claw.up&active_enemies<=5&!talent.raze.enabled)|(buff.tooth_and_claw.up&active_enemies=1&talent.raze.enabled);
	if talents[GR.Maul] and rage >= 40 and (( buff[GR.ToothAndClaw].up and targets <= 5 and not talents[GR.Raze] ) or ( buff[GR.ToothAndClaw].up and targets == 1 and talents[GR.Raze] )) then
		return GR.Maul;
	end

	-- maul,if=(active_enemies<=5&!talent.raze.enabled&variable.If_build=0)|(active_enemies=1&talent.raze.enabled&variable.If_build=0);
	if talents[GR.Maul] and rage >= 40 and (( targets <= 5 and not talents[GR.Raze] and ifBuild == 0 ) or ( targets == 1 and talents[GR.Raze] and ifBuild == 0 )) then
		return GR.Maul;
	end

	-- thrash_bear,target_if=active_enemies>=5;
	if talents[GR.Thrash] then
		return GR.Thrash;
	end

	-- swipe,if=buff.incarnation_guardian_of_ursoc.down&buff.berserk_bear.down&active_enemies>=11;
	if not buff[GR.IncarnationGuardianOfUrsoc].up and not buff[GR.BerserkBear].up and targets >= 11 then
		return GR.Swipe;
	end

	-- mangle,if=(buff.incarnation.up&active_enemies<=4)|(buff.incarnation.up&talent.soul_of_the_forest.enabled&active_enemies<=5)|((rage<90)&active_enemies<11)|((rage<85)&active_enemies<11&talent.soul_of_the_forest.enabled);
	if cooldown[GR.Mangle].ready and (( buff[GR.Incarnation].up and targets <= 4 ) or ( buff[GR.Incarnation].up and talents[GR.SoulOfTheForest] and targets <= 5 ) or ( ( rage < 90 ) and targets < 11 ) or ( ( rage < 85 ) and targets < 11 and talents[GR.SoulOfTheForest] )) then
		return GR.Mangle;
	end

	-- thrash_bear,if=active_enemies>1;
	if talents[GR.Thrash] and (targets > 1) then
		return GR.Thrash;
	end

	-- pulverize,target_if=dot.thrash_bear.stack>2;
	if talents[GR.Pulverize] and cooldown[GR.Pulverize].ready then
		return GR.Pulverize;
	end

	-- thrash_bear;
	if talents[GR.Thrash] then
		return GR.Thrash;
	end

	-- moonfire,if=buff.galactic_guardian.up;
	if mana >= 0 and (buff[GR.GalacticGuardian].up) then
		return GR.Moonfire;
	end

	-- swipe_bear;
	-- GR.Swipe;
end

function Druid:GuardianCatweave()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;
	local comboPoints = UnitPower('player', Enum.PowerType.ComboPoints);
	local comboPointsMax = UnitPowerMax('player', Enum.PowerType.ComboPoints);
	local comboPointsPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local comboPointsRegen = select(2,GetPowerRegen());
	local comboPointsRegenCombined = comboPointsRegen + comboPoints;
	local comboPointsDeficit = UnitPowerMax('player', Enum.PowerType.ComboPoints) - comboPoints;
	local comboPointsTimeToMax = comboPointsMax - comboPoints / comboPointsRegen;

	-- heart_of_the_wild,if=talent.heart_of_the_wild.enabled&!buff.heart_of_the_wild.up&!buff.cat_form.up;
	if talents[GR.HeartOfTheWild] and cooldown[GR.HeartOfTheWild].ready and (talents[GR.HeartOfTheWild] and not buff[GR.HeartOfTheWild].up and not buff[GR.CatForm].up) then
		return GR.HeartOfTheWild;
	end

	-- cat_form,if=!buff.cat_form.up;
	if not buff[GR.CatForm].up then
		return GR.CatForm;
	end

	-- rake,if=buff.prowl.up;
	if talents[GR.Rake] and energy >= 35 and (buff[GR.Prowl].up) then
		return GR.Rake;
	end

	-- heart_of_the_wild,if=talent.heart_of_the_wild.enabled&!buff.heart_of_the_wild.up;
	if talents[GR.HeartOfTheWild] and cooldown[GR.HeartOfTheWild].ready and (talents[GR.HeartOfTheWild] and not buff[GR.HeartOfTheWild].up) then
		return GR.HeartOfTheWild;
	end

	-- rake,if=dot.rake.refreshable|energy<45;
	if talents[GR.Rake] and energy >= 35 and (debuff[GR.Rake].refreshable or energy < 45) then
		return GR.Rake;
	end

	-- rip,if=dot.rip.refreshable&combo_points>=1;
	if talents[GR.Rip] and energy >= 20 and comboPoints >= 5 and (debuff[GR.Rip].refreshable and comboPoints >= 1) then
		return GR.Rip;
	end

	-- convoke_the_spirits;
	if talents[GR.ConvokeTheSpirits] and cooldown[GR.ConvokeTheSpirits].ready then
		return GR.ConvokeTheSpirits;
	end

	-- ferocious_bite,if=combo_points>=4&energy>50;
	if energy >= 25 and comboPoints >= 5 and (comboPoints >= 4 and energy > 50) then
		return GR.FerociousBite;
	end

	-- shred,if=combo_points<=5;
	if energy >= 40 and (comboPoints <= 5) then
		return GR.Shred;
	end
end


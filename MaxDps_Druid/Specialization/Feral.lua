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

local needBt
local align3minutes
local lastConvoke
local lastZerk
local zerkBiteweave;
local regrowth;

local FR = {
	CatForm = 768,
	HeartOfTheWild = 319454,
	Prowl = 5215,
	TigersFury = 5217,
	ConvokeTheSpirits = 391528,
	Rake = 1822,
	NaturesVigil = 124974,
	AdaptiveSwarm = 391888,
	AdaptiveSwarmDamage = 325733,
	UnbridledSwarm = 391951,
	FeralFrenzy = 274837,
	FerociousBite = 22568,
	ApexPredatorsCraving = 391881,
	PrimalWrath = 285381,
	Sabertooth = 202031,
	Bloodtalons = 319439,
	Regrowth = 8936,
	PredatorySwiftness = 16974,
	Clearcasting = 16870,
	BrutalSlash = 202028,
	Thrash = 106832,
	ThrashingClaws = 405300,
	SuddenAmbush = 384667,
	Moonfire = 8921,
	Swipe = 213771,
	Shred = 5221,
	WildSlashes = 390864,
	Rip = 1079,
	OverflowingPower = 405189,
	DireFixation = 417710,
	Incarnation = 102543,
	Berserk = 106951,
	CircleOfLifeAndDeath = 400320,
	TearOpenWounds = 391785,
	RampantFerocity = 391709,
	SoulOfTheForest = 158476,
	AshamanesGuidance = 391548,
	BerserkHeartOfTheLion = 391174,
};
local A = {
};
function Druid:Feral()
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
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;
	local comboPoints = UnitPower('player', Enum.PowerType.ComboPoints);
	local comboPointsMax = UnitPowerMax('player', Enum.PowerType.ComboPoints);
	local comboPointsPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local comboPointsRegen = select(2,GetPowerRegen());
	local comboPointsRegenCombined = comboPointsRegen + comboPoints;
	local comboPointsDeficit = UnitPowerMax('player', Enum.PowerType.ComboPoints) - comboPoints;
	local comboPointsTimeToMax = comboPointsMax - comboPoints / comboPointsRegen;

	-- prowl,if=(buff.bs_inc.down|!in_combat)&!buff.prowl.up;
	if cooldown[FR.Prowl].ready and (( not buff[FR.BsInc].up or not InCombatLockdown() ) and not buff[FR.Prowl].up) then
		return FR.Prowl;
	end

	-- cat_form,if=!buff.cat_form.up;
	if not buff[FR.CatForm].up then
		return FR.CatForm;
	end

	-- call_action_list,name=variables;
	local result = Druid:FeralVariables();
	if result then
		return result;
	end

	-- tigers_fury,if=!talent.convoke_the_spirits.enabled&(!buff.tigers_fury.up|energy.deficit>65);
	if talents[FR.TigersFury] and cooldown[FR.TigersFury].ready and (not talents[FR.ConvokeTheSpirits] and ( not buff[FR.TigersFury].up or energyDeficit > 65 )) then
		return FR.TigersFury;
	end

	-- tigers_fury,if=talent.convoke_the_spirits.enabled&(!variable.lastConvoke|(variable.lastConvoke&!buff.tigers_fury.up));
	if talents[FR.TigersFury] and cooldown[FR.TigersFury].ready and (talents[FR.ConvokeTheSpirits] and ( not lastConvoke or ( lastConvoke and not buff[FR.TigersFury].up ) )) then
		return FR.TigersFury;
	end

	-- rake,target_if=1.4*persistent_multiplier>dot.rake.pmultiplier,if=buff.prowl.up|buff.shadowmeld.up;
	if talents[FR.Rake] and energy >= 35 and (buff[FR.Prowl].up or buff[FR.Shadowmeld].up) then
		return FR.Rake;
	end

	-- natures_vigil,if=in_combat;
	if talents[FR.NaturesVigil] and cooldown[FR.NaturesVigil].ready and (InCombatLockdown()) then
		return FR.NaturesVigil;
	end

	-- adaptive_swarm,target_if=((!dot.adaptive_swarm_damage.ticking|dot.adaptive_swarm_damage.remains<2)&(dot.adaptive_swarm_damage.stack<3)&!action.adaptive_swarm_damage.in_flight&!action.adaptive_swarm.in_flight)&target.time_to_die>5,if=!(variable.need_bt&active_bt_triggers=2)&(!talent.unbridled_swarm.enabled|spell_targets.swipe_cat=1);
	if talents[FR.AdaptiveSwarm] and cooldown[FR.AdaptiveSwarm].ready and mana >= 2500 and (not ( needBt ) and ( not talents[FR.UnbridledSwarm] or targets == 1 )) then
		return FR.AdaptiveSwarm;
	end

	-- adaptive_swarm,target_if=max:(dot.adaptive_swarm_damage.stack*dot.adaptive_swarm_damage.stack<3*time_to_die),if=dot.adaptive_swarm_damage.stack<3&talent.unbridled_swarm.enabled&spell_targets.swipe_cat>1&!(variable.need_bt&active_bt_triggers=2);
	if talents[FR.AdaptiveSwarm] and cooldown[FR.AdaptiveSwarm].ready and mana >= 2500 and (debuff[FR.AdaptiveSwarmDamage].count < 3 and talents[FR.UnbridledSwarm] and targets > 1 and not ( needBt )) then
		return FR.AdaptiveSwarm;
	end

	-- call_action_list,name=cooldown;
	local result = Druid:FeralCooldown();
	if result then
		return result;
	end

	-- feral_frenzy,target_if=max:target.time_to_die,if=combo_points<2|combo_points<3&buff.bs_inc.up;
	if talents[FR.FeralFrenzy] and cooldown[FR.FeralFrenzy].ready and energy >= 25 and (comboPoints < 2 or comboPoints < 3 and buff[FR.BsInc].up) then
		return FR.FeralFrenzy;
	end

	-- ferocious_bite,target_if=max:target.time_to_die,if=buff.apex_predators_craving.up&(spell_targets.swipe_cat=1|!talent.primal_wrath.enabled|!buff.sabertooth.up)&!(variable.need_bt&active_bt_triggers=2);
	if energy >= 25 and comboPoints >= 5 and (buff[FR.ApexPredatorsCraving].up and ( targets == 1 or not talents[FR.PrimalWrath] or not buff[FR.Sabertooth].up ) and not ( needBt )) then
		return FR.FerociousBite;
	end

	-- call_action_list,name=berserk,if=buff.bs_inc.up;
	if buff[FR.BsInc].up then
		local result = Druid:FeralBerserk();
		if result then
			return result;
		end
	end

	-- call_action_list,name=finisher,if=combo_points>=4&!(combo_points=4&buff.bloodtalons.stack<=1&active_bt_triggers=2&spell_targets.swipe_cat=1);
	if comboPoints >= 4 and not ( comboPoints == 4 and buff[FR.Bloodtalons].count <= 1 and targets == 1 ) then
		local result = Druid:FeralFinisher();
		if result then
			return result;
		end
	end

	-- call_action_list,name=bloodtalons,if=variable.need_bt&!buff.bs_inc.up&combo_points<5;
	if needBt and not buff[FR.BsInc].up and comboPoints < 5 then
		local result = Druid:FeralBloodtalons();
		if result then
			return result;
		end
	end

	-- call_action_list,name=aoe_builder,if=spell_targets.swipe_cat>1&talent.primal_wrath.enabled;
	if targets > 1 and talents[FR.PrimalWrath] then
		local result = Druid:FeralAoeBuilder();
		if result then
			return result;
		end
	end

	-- call_action_list,name=builder,if=!buff.bs_inc.up&combo_points<5;
	if not buff[FR.BsInc].up and comboPoints < 5 then
		local result = Druid:FeralBuilder();
		if result then
			return result;
		end
	end

	-- regrowth,if=energy<20&buff.predatory_swiftness.up&!buff.clearcasting.up&variable.regrowth;
	if mana >= 0 and currentSpell ~= FR.Regrowth and (energy < 20 and buff[FR.PredatorySwiftness].up and not buff[FR.Clearcasting].up and regrowth) then
		return FR.Regrowth;
	end
end
function Druid:FeralAoeBuilder()
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
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- brutal_slash,target_if=min:target.time_to_die,if=cooldown.brutal_slash.full_recharge_time<4|target.time_to_die<5;
	if talents[FR.BrutalSlash] and cooldown[FR.BrutalSlash].ready and energy >= 25 and (cooldown[FR.BrutalSlash].fullRecharge < 4 or timeToDie < 5) then
		return FR.BrutalSlash;
	end

	-- thrash_cat,target_if=refreshable,if=buff.clearcasting.react|(spell_targets.thrash_cat>10|(spell_targets.thrash_cat>5&!talent.double_clawed_rake.enabled))&!talent.thrashing_claws;
	if talents[FR.Thrash] and (buff[FR.Clearcasting].count or ( targets > 10 or ( targets > 5 and not talents[FR.DoubleClawedRake] ) ) and not talents[FR.ThrashingClaws]) then
		return FR.Thrash;
	end

	-- rake,target_if=max:druid.rake.ticks_gained_on_refresh,if=buff.sudden_ambush.up&persistent_multiplier>dot.rake.pmultiplier;
	if talents[FR.Rake] and energy >= 35 and (buff[FR.SuddenAmbush].up) then
		return FR.Rake;
	end

	-- rake,target_if=buff.sudden_ambush.up&persistent_multiplier>dot.rake.pmultiplier|refreshable;
	if talents[FR.Rake] and energy >= 35 then
		return FR.Rake;
	end

	-- thrash_cat,target_if=refreshable;
	if talents[FR.Thrash] then
		return FR.Thrash;
	end

	-- brutal_slash;
	if talents[FR.BrutalSlash] and cooldown[FR.BrutalSlash].ready and energy >= 25 then
		return FR.BrutalSlash;
	end

	-- moonfire_cat,target_if=refreshable,if=spell_targets.swipe_cat<5;
	if mana >= 0 and (targets < 5) then
		return FR.Moonfire;
	end

	-- swipe_cat;
	-- FR.Swipe;

	-- moonfire_cat,target_if=refreshable;
	if mana >= 0 then
		return FR.Moonfire;
	end

	-- shred,target_if=max:target.time_to_die,if=action.shred.damage>action.thrash_cat.damage&!buff.sudden_ambush.up&!(variable.lazy_swipe&talent.wild_slashes);
	if energy >= 40 and (cooldown[FR.Shred].damage > cooldown[FR.ThrashCat].damage and not buff[FR.SuddenAmbush].up and not ( lazySwipe and talents[FR.WildSlashes] )) then
		return FR.Shred;
	end

	-- thrash_cat;
	if talents[FR.Thrash] then
		return FR.Thrash;
	end
end

function Druid:FeralBerserk()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local gcdRemains = fd.gcdRemains;
	local timeToDie = fd.timeToDie;
	local comboPoints = UnitPower('player', Enum.PowerType.ComboPoints);
	local comboPointsMax = UnitPowerMax('player', Enum.PowerType.ComboPoints);
	local comboPointsPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local comboPointsRegen = select(2,GetPowerRegen());
	local comboPointsRegenCombined = comboPointsRegen + comboPoints;
	local comboPointsDeficit = UnitPowerMax('player', Enum.PowerType.ComboPoints) - comboPoints;
	local comboPointsTimeToMax = comboPointsMax - comboPoints / comboPointsRegen;
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- ferocious_bite,target_if=max:target.time_to_die,if=combo_points=5&dot.rip.remains>8&variable.zerk_biteweave&spell_targets.swipe_cat>1;
	if energy >= 25 and comboPoints >= 5 and (comboPoints == 5 and debuff[FR.Rip].remains > 8 and zerkBiteweave and targets > 1) then
		return FR.FerociousBite;
	end

	-- call_action_list,name=finisher,if=combo_points=5&!(buff.overflowing_power.stack<=1&active_bt_triggers=2&buff.bloodtalons.stack<=1);
	if comboPoints == 5 and not ( buff[FR.OverflowingPower].count <= 1 and buff[FR.Bloodtalons].count <= 1 ) then
		local result = Druid:FeralFinisher();
		if result then
			return result;
		end
	end

	-- call_action_list,name=bloodtalons,if=spell_targets.swipe_cat>1;
	if targets > 1 then
		local result = Druid:FeralBloodtalons();
		if result then
			return result;
		end
	end

	-- prowl,if=!(buff.bt_rake.up&active_bt_triggers=2)&(action.rake.ready&gcd.remains=0&!buff.sudden_ambush.up&(dot.rake.refreshable|dot.rake.pmultiplier<1.4)&!buff.shadowmeld.up&cooldown.feral_frenzy.remains<44&!buff.apex_predators_craving.up);
	if cooldown[FR.Prowl].ready and (not ( buff[FR.BtRake].up ) and ( cooldown[FR.Rake].ready and gcdRemains == 0 and not buff[FR.SuddenAmbush].up and ( debuff[FR.Rake].refreshable ) and not buff[FR.Shadowmeld].up and cooldown[FR.FeralFrenzy].remains < 44 and not buff[FR.ApexPredatorsCraving].up )) then
		return FR.Prowl;
	end

	-- rake,if=!(buff.bt_rake.up&active_bt_triggers=2)&(refreshable|(buff.sudden_ambush.up&persistent_multiplier>dot.rake.pmultiplier&!dot.rake.refreshable));
	if talents[FR.Rake] and energy >= 35 and (not ( buff[FR.BtRake].up ) and ( debuff[FR.Rake].refreshable or ( buff[FR.SuddenAmbush].up and not debuff[FR.Rake].refreshable ) )) then
		return FR.Rake;
	end

	-- shred,if=active_bt_triggers=2&buff.bt_shred.down;
	if energy >= 40 and (not buff[FR.BtShred].up) then
		return FR.Shred;
	end

	-- brutal_slash,if=active_bt_triggers=2&buff.bt_brutal_slash.down;
	if talents[FR.BrutalSlash] and cooldown[FR.BrutalSlash].ready and energy >= 25 and (not buff[FR.BtBrutalSlash].up) then
		return FR.BrutalSlash;
	end

	-- moonfire_cat,if=active_bt_triggers=2&buff.bt_moonfire.down;
	if mana >= 0 and (not buff[FR.BtMoonfire].up) then
		return FR.Moonfire;
	end

	-- thrash_cat,if=active_bt_triggers=2&buff.bt_thrash.down&!talent.thrashing_claws&variable.need_bt&(refreshable|talent.brutal_slash.enabled);
	if talents[FR.Thrash] and (not buff[FR.BtThrash].up and not talents[FR.ThrashingClaws] and needBt and ( debuff[FR.Thrash].refreshable or talents[FR.BrutalSlash] )) then
		return FR.Thrash;
	end

	-- moonfire_cat,if=refreshable;
	if mana >= 0 and (debuff[FR.Moonfire].refreshable) then
		return FR.Moonfire;
	end

	-- brutal_slash,if=cooldown.brutal_slash.charges>1;
	if talents[FR.BrutalSlash] and cooldown[FR.BrutalSlash].ready and energy >= 25 and (cooldown[FR.BrutalSlash].charges > 1) then
		return FR.BrutalSlash;
	end

	-- shred;
	if energy >= 40 then
		return FR.Shred;
	end
end

function Druid:FeralBloodtalons()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local gcdRemains = fd.gcdRemains;
	local timeToDie = fd.timeToDie;
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- brutal_slash,target_if=min:target.time_to_die,if=(cooldown.brutal_slash.full_recharge_time<4|target.time_to_die<5)&(buff.bt_brutal_slash.down&(buff.bs_inc.up|variable.need_bt));
	if talents[FR.BrutalSlash] and cooldown[FR.BrutalSlash].ready and energy >= 25 and (( cooldown[FR.BrutalSlash].fullRecharge < 4 or timeToDie < 5 ) and ( not buff[FR.BtBrutalSlash].up and ( buff[FR.BsInc].up or needBt ) )) then
		return FR.BrutalSlash;
	end

	-- prowl,if=action.rake.ready&gcd.remains=0&!buff.sudden_ambush.up&(dot.rake.refreshable|dot.rake.pmultiplier<1.4)&!buff.shadowmeld.up&buff.bt_rake.down&!buff.prowl.up&!buff.apex_predators_craving.up;
	if cooldown[FR.Prowl].ready and (cooldown[FR.Rake].ready and gcdRemains == 0 and not buff[FR.SuddenAmbush].up and ( debuff[FR.Rake].refreshable ) and not buff[FR.Shadowmeld].up and not buff[FR.BtRake].up and not buff[FR.Prowl].up and not buff[FR.ApexPredatorsCraving].up) then
		return FR.Prowl;
	end

	-- rake,target_if=max:druid.rake.ticks_gained_on_refresh,if=(refreshable|buff.sudden_ambush.up&persistent_multiplier>dot.rake.pmultiplier)&buff.bt_rake.down;
	if talents[FR.Rake] and energy >= 35 and (( debuff[FR.Rake].refreshable or buff[FR.SuddenAmbush].up ) and not buff[FR.BtRake].up) then
		return FR.Rake;
	end

	-- rake,target_if=buff.sudden_ambush.up&persistent_multiplier>dot.rake.pmultiplier&buff.bt_rake.down;
	if talents[FR.Rake] and energy >= 35 then
		return FR.Rake;
	end

	-- shred,if=buff.bt_shred.down&buff.clearcasting.react&spell_targets.swipe_cat=1;
	if energy >= 40 and (not buff[FR.BtShred].up and buff[FR.Clearcasting].count and targets == 1) then
		return FR.Shred;
	end

	-- thrash_cat,target_if=refreshable,if=buff.bt_thrash.down&buff.clearcasting.react&spell_targets.swipe_cat=1&!talent.thrashing_claws.enabled;
	if talents[FR.Thrash] and (not buff[FR.BtThrash].up and buff[FR.Clearcasting].count and targets == 1 and not talents[FR.ThrashingClaws]) then
		return FR.Thrash;
	end

	-- brutal_slash,if=buff.bt_brutal_slash.down;
	if talents[FR.BrutalSlash] and cooldown[FR.BrutalSlash].ready and energy >= 25 and (not buff[FR.BtBrutalSlash].up) then
		return FR.BrutalSlash;
	end

	-- moonfire_cat,if=refreshable&buff.bt_moonfire.down&spell_targets.swipe_cat=1;
	if mana >= 0 and (debuff[FR.Moonfire].refreshable and not buff[FR.BtMoonfire].up and targets == 1) then
		return FR.Moonfire;
	end

	-- thrash_cat,target_if=refreshable,if=buff.bt_thrash.down&!talent.thrashing_claws.enabled;
	if talents[FR.Thrash] and (not buff[FR.BtThrash].up and not talents[FR.ThrashingClaws]) then
		return FR.Thrash;
	end

	-- shred,if=buff.bt_shred.down&spell_targets.swipe_cat=1&(!talent.wild_slashes.enabled|(!debuff.dire_fixation.up&talent.dire_fixation.enabled));
	if energy >= 40 and (not buff[FR.BtShred].up and targets == 1 and ( not talents[FR.WildSlashes] or ( not debuff[FR.DireFixation].up and talents[FR.DireFixation] ) )) then
		return FR.Shred;
	end

	-- swipe_cat,if=buff.bt_swipe.down&talent.wild_slashes.enabled;
	if not buff[FR.BtSwipe].up and talents[FR.WildSlashes] then
		return FR.Swipe;
	end

	-- moonfire_cat,target_if=max:ticks_gained_on_refresh,if=buff.bt_moonfire.down&spell_targets.swipe_cat<5;
	if mana >= 0 and (not buff[FR.BtMoonfire].up and targets < 5) then
		return FR.Moonfire;
	end

	-- swipe_cat,if=buff.bt_swipe.down;
	if not buff[FR.BtSwipe].up then
		return FR.Swipe;
	end

	-- moonfire_cat,target_if=max:ticks_gained_on_refresh,if=buff.bt_moonfire.down;
	if mana >= 0 and (not buff[FR.BtMoonfire].up) then
		return FR.Moonfire;
	end

	-- shred,target_if=max:target.time_to_die,if=action.shred.damage>action.thrash_cat.damage&buff.bt_shred.down&!buff.sudden_ambush.up&!(variable.lazy_swipe&talent.wild_slashes);
	if energy >= 40 and (cooldown[FR.Shred].damage > cooldown[FR.ThrashCat].damage and not buff[FR.BtShred].up and not buff[FR.SuddenAmbush].up and not ( lazySwipe and talents[FR.WildSlashes] )) then
		return FR.Shred;
	end

	-- thrash_cat,if=buff.bt_thrash.down;
	if talents[FR.Thrash] and (not buff[FR.BtThrash].up) then
		return FR.Thrash;
	end

	-- rake,target_if=min:(25*(persistent_multiplier<dot.rake.pmultiplier)+dot.rake.remains),if=buff.bt_rake.down&variable.lazy_swipe&talent.wild_slashes;
	if talents[FR.Rake] and energy >= 35 and (not buff[FR.BtRake].up and lazySwipe and talents[FR.WildSlashes]) then
		return FR.Rake;
	end
end

function Druid:FeralBuilder()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- run_action_list,name=clearcasting,if=buff.clearcasting.react;
	if buff[FR.Clearcasting].count then
		return Druid:FeralClearcasting();
	end

	-- brutal_slash,if=cooldown.brutal_slash.full_recharge_time<4;
	if talents[FR.BrutalSlash] and cooldown[FR.BrutalSlash].ready and energy >= 25 and (cooldown[FR.BrutalSlash].fullRecharge < 4) then
		return FR.BrutalSlash;
	end

	-- rake,if=refreshable|(buff.sudden_ambush.up&persistent_multiplier>dot.rake.pmultiplier&dot.rake.remains>6);
	if talents[FR.Rake] and energy >= 35 and (debuff[FR.Rake].refreshable or ( buff[FR.SuddenAmbush].up and debuff[FR.Rake].remains > 6 )) then
		return FR.Rake;
	end

	-- run_action_list,name=clearcasting,if=buff.clearcasting.react;
	if buff[FR.Clearcasting].count then
		return Druid:FeralClearcasting();
	end

	-- moonfire_cat,target_if=refreshable;
	if mana >= 0 then
		return FR.Moonfire;
	end

	-- thrash_cat,target_if=refreshable&!talent.thrashing_claws.enabled;
	if talents[FR.Thrash] then
		return FR.Thrash;
	end

	-- brutal_slash;
	if talents[FR.BrutalSlash] and cooldown[FR.BrutalSlash].ready and energy >= 25 then
		return FR.BrutalSlash;
	end

	-- swipe_cat,if=spell_targets.swipe_cat>1|(talent.wild_slashes.enabled&(debuff.dire_fixation.up|!talent.dire_fixation.enabled));
	if targets > 1 or ( talents[FR.WildSlashes] and ( debuff[FR.DireFixation].up or not talents[FR.DireFixation] ) ) then
		return FR.Swipe;
	end

	-- shred;
	if energy >= 40 then
		return FR.Shred;
	end
end

function Druid:FeralClearcasting()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local energy = UnitPower('player', Enum.PowerType.Energy);
	local energyMax = UnitPowerMax('player', Enum.PowerType.Energy);
	local energyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local energyRegen = select(2,GetPowerRegen());
	local energyRegenCombined = energyRegen + energy;
	local energyDeficit = UnitPowerMax('player', Enum.PowerType.Energy) - energy;
	local energyTimeToMax = energyMax - energy / energyRegen;

	-- thrash_cat,if=refreshable&!talent.thrashing_claws.enabled;
	if talents[FR.Thrash] and (debuff[FR.Thrash].refreshable and not talents[FR.ThrashingClaws]) then
		return FR.Thrash;
	end

	-- swipe_cat,if=spell_targets.swipe_cat>1;
	if targets > 1 then
		return FR.Swipe;
	end

	-- brutal_slash,if=spell_targets.brutal_slash>2;
	if talents[FR.BrutalSlash] and cooldown[FR.BrutalSlash].ready and energy >= 25 and (targets > 2) then
		return FR.BrutalSlash;
	end

	-- shred;
	if energy >= 40 then
		return FR.Shred;
	end
end

function Druid:FeralCooldown()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local timeToDie = fd.timeToDie;
	local comboPoints = UnitPower('player', Enum.PowerType.ComboPoints);
	local comboPointsMax = UnitPowerMax('player', Enum.PowerType.ComboPoints);
	local comboPointsPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local comboPointsRegen = select(2,GetPowerRegen());
	local comboPointsRegenCombined = comboPointsRegen + comboPoints;
	local comboPointsDeficit = UnitPowerMax('player', Enum.PowerType.ComboPoints) - comboPoints;
	local comboPointsTimeToMax = comboPointsMax - comboPoints / comboPointsRegen;

	-- incarnation,target_if=max:target.time_to_die,if=(target.time_to_die<fight_remains&target.time_to_die>25)|target.time_to_die=fight_remains;
	if ( timeToDie < timeToDie and timeToDie > 25 ) or timeToDie == timeToDie then
		return FR.Incarnation;
	end

	-- berserk,target_if=max:target.time_to_die,if=((target.time_to_die<fight_remains&target.time_to_die>18)|target.time_to_die=fight_remains)&((!variable.lastZerk)|(fight_remains<23)|(variable.lastZerk&!variable.lastConvoke)|(variable.lastConvoke&cooldown.convoke_the_spirits.remains<10));
	if talents[FR.Berserk] and cooldown[FR.Berserk].ready and (( ( timeToDie < timeToDie and timeToDie > 18 ) or timeToDie == timeToDie ) and ( ( not lastZerk ) or ( timeToDie < 23 ) or ( lastZerk and not lastConvoke ) or ( lastConvoke and cooldown[FR.ConvokeTheSpirits].remains < 10 ) )) then
		return FR.Berserk;
	end

	-- convoke_the_spirits,target_if=max:target.time_to_die,if=((target.time_to_die<fight_remains&target.time_to_die>5)|target.time_to_die=fight_remains)&(fight_remains<5|(dot.rip.remains>5&buff.tigers_fury.up&(combo_points<2|(buff.bs_inc.up&combo_points=2))&(!variable.lastConvoke|!variable.lastZerk|buff.bs_inc.up)));
	if talents[FR.ConvokeTheSpirits] and cooldown[FR.ConvokeTheSpirits].ready and (( ( timeToDie < timeToDie and timeToDie > 5 ) or timeToDie == timeToDie ) and ( timeToDie < 5 or ( debuff[FR.Rip].remains > 5 and buff[FR.TigersFury].up and ( comboPoints < 2 or ( buff[FR.BsInc].up and comboPoints == 2 ) ) and ( not lastConvoke or not lastZerk or buff[FR.BsInc].up ) ) )) then
		return FR.ConvokeTheSpirits;
	end
end

function Druid:FeralFinisher()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local timeToDie = fd.timeToDie;
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

	-- primal_wrath,if=((dot.primal_wrath.refreshable&!talent.circle_of_life_and_death.enabled)|dot.primal_wrath.remains<6|(talent.tear_open_wounds.enabled|(spell_targets.swipe_cat>4&!talent.rampant_ferocity.enabled)))&spell_targets.primal_wrath>1&talent.primal_wrath.enabled;
	if talents[FR.PrimalWrath] and energy >= 20 and comboPoints >= 5 and (( ( debuff[FR.PrimalWrath].refreshable and not talents[FR.CircleOfLifeAndDeath] ) or debuff[FR.PrimalWrath].remains < 6 or ( talents[FR.TearOpenWounds] or ( targets > 4 and not talents[FR.RampantFerocity] ) ) ) and targets > 1 and talents[FR.PrimalWrath]) then
		return FR.PrimalWrath;
	end

	-- rip,target_if=refreshable;
	if talents[FR.Rip] and energy >= 20 and comboPoints >= 5 then
		return FR.Rip;
	end

	-- ferocious_bite,max_energy=1,target_if=max:target.time_to_die,if=buff.apex_predators_craving.down&(!buff.bs_inc.up|(buff.bs_inc.up&!talent.soul_of_the_forest.enabled));
	if energy >= 25 and comboPoints >= 5 and (not buff[FR.ApexPredatorsCraving].up and ( not buff[FR.BsInc].up or ( buff[FR.BsInc].up and not talents[FR.SoulOfTheForest] ) )) then
		return FR.FerociousBite;
	end

	-- ferocious_bite,target_if=max:target.time_to_die,if=(buff.bs_inc.up&talent.soul_of_the_forest.enabled)|buff.apex_predators_craving.up;
	if energy >= 25 and comboPoints >= 5 and (( buff[FR.BsInc].up and talents[FR.SoulOfTheForest] ) or buff[FR.ApexPredatorsCraving].up) then
		return FR.FerociousBite;
	end
end

function Druid:FeralVariable()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;

	-- variable,name=lazy_swipe,op=reset;
	local lazySwipe;
end

function Druid:FeralVariables()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local timeToDie = fd.timeToDie;

	-- variable,name=need_bt,value=talent.bloodtalons.enabled&buff.bloodtalons.stack<2;
	needBt = talents[FR.Bloodtalons] and buff[FR.Bloodtalons].count < 2;

	-- variable,name=align_3minutes,value=spell_targets.swipe_cat=1&!fight_style.dungeonslice;
	align3minutes = targets == 1;

	-- variable,name=lastConvoke,value=fight_remains>cooldown.convoke_the_spirits.remains+3&((talent.ashamanes_guidance.enabled&fight_remains<(cooldown.convoke_the_spirits.remains+60))|(!talent.ashamanes_guidance.enabled&fight_remains<(cooldown.convoke_the_spirits.remains+120)));
	lastConvoke = timeToDie > cooldown[FR.ConvokeTheSpirits].remains + 3 and ( ( talents[FR.AshamanesGuidance] and timeToDie < ( cooldown[FR.ConvokeTheSpirits].remains + 60 ) ) or ( not talents[FR.AshamanesGuidance] and timeToDie < ( cooldown[FR.ConvokeTheSpirits].remains + 120 ) ) );

	-- variable,name=lastZerk,value=fight_remains>(30+(cooldown.bs_inc.remains%1.6))&((talent.berserk_heart_of_the_lion.enabled&fight_remains<(90+(cooldown.bs_inc.remains%1.6)))|(!talent.berserk_heart_of_the_lion.enabled&fight_remains<(180+cooldown.bs_inc.remains)));
	lastZerk = timeToDie > ( 30 + ( cooldown[FR.BsInc].remains / 1.6 ) ) and ( ( talents[FR.BerserkHeartOfTheLion] and timeToDie < ( 90 + ( cooldown[FR.BsInc].remains / 1.6 ) ) ) or ( not talents[FR.BerserkHeartOfTheLion] and timeToDie < ( 180 + cooldown[FR.BsInc].remains ) ) );

	-- variable,name=zerk_biteweave,op=reset;
	--zerkBiteweave;

	-- variable,name=regrowth,op=reset;
	--regrowth;
end


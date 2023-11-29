local _, addonTable = ...;

-- @type MaxDps;
if not MaxDps then return end;
local Mage = addonTable.Mage;
local MaxDps = MaxDps;

local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;

local itemID = GetInventoryItemID('player', INVSLOT_MAINHAND);

local mainHandSubClassID = itemID and  select(13, GetItemInfo(itemID));

local TwoHanderWepCheck = mainHandSubClassID and (mainHandSubClassID == 1 or mainHandSubClassID == 5 or mainHandSubClassID == 8 or mainHandSubClassID == 10);

local AR = {
	ArcaneIntellect = 1459,
	ArcaneFamiliar = 205022,
	ConjureManaGem = 759,
	ArcaneHarmony = 384452,
	Tier304pc = 393654,
	MirrorImage = 55342,
	ArcaneBlast = 30451,
	SiphonStorm = 384187,
	Evocation = 12051,
	Counterspell = 2139,
	TimeWarp = 80353,
	TemporalWarp = 386539,
	ArcaneSurge = 365350,
	ArcaneOrb = 153626,
	ArcaneCharge = 190427,
	RadiantSpark = 376103,
	TouchOfTheMagi = 321507,
	ArcaneBarrage = 44425,
	CascadingPower = 384276,
	Clearcasting = 79684,
	NetherTempest = 114923,
	ArcaneEcho = 342231,
	ArcaneOverload = 409022,
	ShiftingPower = 382440,
	ChargedOrb = 384651,
	OrbBarrage = 384858,
	ArcaneExplosion = 1449,
	PresenceOfMind = 205025,
	ArcaneMissiles = 5143,
	NetherPrecision = 383782,
	ArcaneBombardment = 384581,
	TimeAnomaly = 383243,
	Concentration = 384374,
};
local A = {
};
function Mage:Arcane()
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

	-- time_warp,if=talent.temporal_warp&buff.exhaustion.up&(cooldown.arcane_surge.ready|fight_remains<=40|buff.arcane_surge.up&fight_remains<=80);
	if cooldown[AR.TimeWarp].ready and mana >= 2000 and (talents[AR.TemporalWarp] and buff[AR.Exhaustion].up and ( cooldown[AR.ArcaneSurge].ready or timeToDie <= 40 or buff[AR.ArcaneSurge].up and timeToDie <= 80 )) then
		return AR.TimeWarp;
	end

	-- variable,name=aoe_spark_phase,op=set,value=1,if=active_enemies>=variable.aoe_target_count&(action.arcane_orb.charges>0|buff.arcane_charge.stack>=3)&cooldown.radiant_spark.ready&cooldown.touch_of_the_magi.remains<=(gcd.max*2);
	if targets >= aoeTargetCount and ( cooldown[AR.ArcaneOrb].charges > 0 or buff[AR.ArcaneCharge].count >= 3 ) and cooldown[AR.RadiantSpark].ready and cooldown[AR.TouchOfTheMagi].remains <= ( gcd * 2 ) then
		local aoeSparkPhase = 1;
	end

	-- variable,name=aoe_spark_phase,op=set,value=0,if=variable.aoe_spark_phase&debuff.radiant_spark_vulnerability.down&dot.radiant_spark.remains<7&cooldown.radiant_spark.remains;
	if aoeSparkPhase and not debuff[AR.RadiantSparkVulnerability].up and debuff[AR.RadiantSpark].remains < 7 and cooldown[AR.RadiantSpark].remains then
		local aoeSparkPhase = 0;
	end

	-- variable,name=spark_phase,op=set,value=1,if=buff.arcane_charge.stack>3&active_enemies<variable.aoe_target_count&cooldown.radiant_spark.ready&cooldown.touch_of_the_magi.remains<=(gcd.max*7);
	if buff[AR.ArcaneCharge].count > 3 and targets < aoeTargetCount and cooldown[AR.RadiantSpark].ready and cooldown[AR.TouchOfTheMagi].remains <= ( gcd * 7 ) then
		local sparkPhase = 1;
	end

	-- variable,name=spark_phase,op=set,value=0,if=variable.spark_phase&debuff.radiant_spark_vulnerability.down&dot.radiant_spark.remains<7&cooldown.radiant_spark.remains;
	if sparkPhase and not debuff[AR.RadiantSparkVulnerability].up and debuff[AR.RadiantSpark].remains < 7 and cooldown[AR.RadiantSpark].remains then
		local sparkPhase = 0;
	end

	-- variable,name=opener,op=set,if=debuff.touch_of_the_magi.up&variable.opener,value=0;
	if debuff[AR.TouchOfTheMagi].up and opener then
		local opener = 0;
	end

	-- arcane_barrage,if=fight_remains<2;
	if timeToDie < 2 then
		return AR.ArcaneBarrage;
	end

	-- evocation,if=buff.arcane_surge.down&debuff.touch_of_the_magi.down&((mana.pct<10&cooldown.touch_of_the_magi.remains<20)|cooldown.touch_of_the_magi.remains<15)&(mana.pct<fight_remains*4);
	if talents[AR.Evocation] and cooldown[AR.Evocation].ready and (not buff[AR.ArcaneSurge].up and not debuff[AR.TouchOfTheMagi].up and ( ( manaPct < 10 and cooldown[AR.TouchOfTheMagi].remains < 20 ) or cooldown[AR.TouchOfTheMagi].remains < 15 ) and ( manaPct < timeToDie * 4 )) then
		return AR.Evocation;
	end

	-- conjure_mana_gem,if=debuff.touch_of_the_magi.down&buff.arcane_surge.down&cooldown.arcane_surge.remains<fight_remains&!mana_gem_charges;
	if talents[AR.ConjureManaGem] and mana >= 9000 and currentSpell ~= AR.ConjureManaGem and (not debuff[AR.TouchOfTheMagi].up and not buff[AR.ArcaneSurge].up and cooldown[AR.ArcaneSurge].remains < timeToDie ) then
		return AR.ConjureManaGem;
	end

	-- use_mana_gem,if=talent.cascading_power&buff.clearcasting.stack<2&buff.arcane_surge.up;
	if talents[AR.CascadingPower] and buff[AR.Clearcasting].count < 2 and buff[AR.ArcaneSurge].up then
		return AR.UseManaGem;
	end

	-- use_mana_gem,if=!talent.cascading_power&prev_gcd.1.arcane_surge;
	if not talents[AR.CascadingPower] and spellHistory[1] == AR.ArcaneSurge then
		return AR.UseManaGem;
	end

	-- call_action_list,name=cooldown_phase,if=!variable.totm_on_last_spark_stack&(cooldown.arcane_surge.remains<=(gcd.max*(1+(talent.nether_tempest&talent.arcane_echo)))|buff.arcane_surge.up|buff.arcane_overload.up)&cooldown.evocation.remains>45&((cooldown.touch_of_the_magi.remains<gcd.max*4)|cooldown.touch_of_the_magi.remains>20)&active_enemies<variable.aoe_target_count;
	if not totmOnLastSparkStack and ( cooldown[AR.ArcaneSurge].remains <= ( gcd * ( 1 + ( talents[AR.NetherTempest] and talents[AR.ArcaneEcho] ) ) ) or buff[AR.ArcaneSurge].up or buff[AR.ArcaneOverload].up ) and cooldown[AR.Evocation].remains > 45 and ( ( cooldown[AR.TouchOfTheMagi].remains < gcd * 4 ) or cooldown[AR.TouchOfTheMagi].remains > 20 ) and targets < aoeTargetCount then
		local result = Mage:ArcaneCooldownPhase();
		if result then
			return result;
		end
	end

	-- call_action_list,name=cooldown_phase,if=!variable.totm_on_last_spark_stack&cooldown.arcane_surge.remains>30&(cooldown.radiant_spark.ready|dot.radiant_spark.remains|debuff.radiant_spark_vulnerability.up)&(cooldown.touch_of_the_magi.remains<=(gcd.max*3)|debuff.touch_of_the_magi.up)&active_enemies<variable.aoe_target_count;
	if not totmOnLastSparkStack and cooldown[AR.ArcaneSurge].remains > 30 and ( cooldown[AR.RadiantSpark].ready or debuff[AR.RadiantSpark].remains or debuff[AR.RadiantSparkVulnerability].up ) and ( cooldown[AR.TouchOfTheMagi].remains <= ( gcd * 3 ) or debuff[AR.TouchOfTheMagi].up ) and targets < aoeTargetCount then
		local result = Mage:ArcaneCooldownPhase();
		if result then
			return result;
		end
	end

	-- call_action_list,name=aoe_spark_phase,if=talent.radiant_spark&variable.aoe_spark_phase;
	if talents[AR.RadiantSpark] and aoeSparkPhase then
		local result = Mage:ArcaneAoeSparkPhase();
		if result then
			return result;
		end
	end

	-- call_action_list,name=spark_phase,if=variable.totm_on_last_spark_stack&talent.radiant_spark&variable.spark_phase;
	if totmOnLastSparkStack and talents[AR.RadiantSpark] and sparkPhase then
		local result = Mage:ArcaneSparkPhase();
		if result then
			return result;
		end
	end

	-- call_action_list,name=aoe_touch_phase,if=debuff.touch_of_the_magi.up&active_enemies>=variable.aoe_target_count;
	if debuff[AR.TouchOfTheMagi].up and targets >= aoeTargetCount then
		local result = Mage:ArcaneAoeTouchPhase();
		if result then
			return result;
		end
	end

	-- call_action_list,name=touch_phase,if=variable.totm_on_last_spark_stack&debuff.touch_of_the_magi.up&active_enemies<variable.aoe_target_count;
	if totmOnLastSparkStack and debuff[AR.TouchOfTheMagi].up and targets < aoeTargetCount then
		local result = Mage:ArcaneTouchPhase();
		if result then
			return result;
		end
	end

	-- call_action_list,name=aoe_rotation,if=active_enemies>=variable.aoe_target_count;
	if targets >= aoeTargetCount then
		local result = Mage:ArcaneAoeRotation();
		if result then
			return result;
		end
	end

	-- call_action_list,name=rotation;
	local result = Mage:ArcaneRotation();
	if result then
		return result;
	end
end
function Mage:ArcaneAoeRotation()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- shifting_power,if=(!talent.evocation|cooldown.evocation.remains>12)&(!talent.arcane_surge|cooldown.arcane_surge.remains>12)&(!talent.touch_of_the_magi|cooldown.touch_of_the_magi.remains>12)&buff.arcane_surge.down&((!talent.charged_orb&cooldown.arcane_orb.remains>12)|(action.arcane_orb.charges=0|cooldown.arcane_orb.remains>12));
	if talents[AR.ShiftingPower] and cooldown[AR.ShiftingPower].ready and mana >= 2500 and (( not talents[AR.Evocation] or cooldown[AR.Evocation].remains > 12 ) and ( not talents[AR.ArcaneSurge] or cooldown[AR.ArcaneSurge].remains > 12 ) and ( not talents[AR.TouchOfTheMagi] or cooldown[AR.TouchOfTheMagi].remains > 12 ) and not buff[AR.ArcaneSurge].up and ( ( not talents[AR.ChargedOrb] and cooldown[AR.ArcaneOrb].remains > 12 ) or ( cooldown[AR.ArcaneOrb].charges == 0 or cooldown[AR.ArcaneOrb].remains > 12 ) )) then
		return AR.ShiftingPower;
	end

	-- nether_tempest,if=(refreshable|!ticking)&buff.arcane_charge.stack=buff.arcane_charge.max_stack&buff.arcane_surge.down&(active_enemies>6|!talent.orb_barrage);
	if talents[AR.NetherTempest] and mana >= 750 and (( debuff[AR.NetherTempest].refreshable or not debuff[AR.NetherTempest].up ) and buff[AR.ArcaneCharge].count == buff[AR.ArcaneCharge].maxStacks and not buff[AR.ArcaneSurge].up and ( targets > 6 or not talents[AR.OrbBarrage] )) then
		return AR.NetherTempest;
	end

	-- arcane_barrage,if=(active_enemies<=4|buff.clearcasting.up)&buff.arcane_charge.stack=3;
	if ( targets <= 4 or buff[AR.Clearcasting].up ) and buff[AR.ArcaneCharge].count == 3 then
		return AR.ArcaneBarrage;
	end

	-- arcane_orb,if=buff.arcane_charge.stack=0&cooldown.touch_of_the_magi.remains>18;
	if talents[AR.ArcaneOrb] and cooldown[AR.ArcaneOrb].ready and mana >= 500 and (buff[AR.ArcaneCharge].count == 0 and cooldown[AR.TouchOfTheMagi].remains > 18) then
		return AR.ArcaneOrb;
	end

	-- arcane_barrage,if=buff.arcane_charge.stack=buff.arcane_charge.max_stack|mana.pct<10;
	if buff[AR.ArcaneCharge].count == buff[AR.ArcaneCharge].maxStacks or manaPct < 10 then
		return AR.ArcaneBarrage;
	end

	-- arcane_explosion;
	if mana >= 5000 then
		return AR.ArcaneExplosion;
	end
end

function Mage:ArcaneAoeSparkPhase()
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
	local targets = fd.targets and fd.targets or 1;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- touch_of_the_magi,use_off_gcd=1,if=prev_gcd.1.arcane_barrage;
	if talents[AR.TouchOfTheMagi] and cooldown[AR.TouchOfTheMagi].ready and mana >= 2500 and (spellHistory[1] == AR.ArcaneBarrage) then
		return AR.TouchOfTheMagi;
	end

	-- radiant_spark;
	if talents[AR.RadiantSpark] and cooldown[AR.RadiantSpark].ready and mana >= 1000 and currentSpell ~= AR.RadiantSpark then
		return AR.RadiantSpark;
	end

	-- arcane_orb,if=buff.arcane_charge.stack<3,line_cd=1;
	if talents[AR.ArcaneOrb] and cooldown[AR.ArcaneOrb].ready and mana >= 500 and (buff[AR.ArcaneCharge].count < 3) then
		return AR.ArcaneOrb;
	end

	-- nether_tempest,if=talent.arcane_echo,line_cd=15;
	if talents[AR.NetherTempest] and mana >= 750 and (talents[AR.ArcaneEcho]) then
		return AR.NetherTempest;
	end

	-- arcane_surge;
	if talents[AR.ArcaneSurge] and cooldown[AR.ArcaneSurge].ready and mana >= 63132 and currentSpell ~= AR.ArcaneSurge then
		return AR.ArcaneSurge;
	end

	-- arcane_barrage,if=cooldown.arcane_surge.remains<75&debuff.radiant_spark_vulnerability.stack=4&!talent.orb_barrage;
	if cooldown[AR.ArcaneSurge].remains < 75 and debuff[AR.RadiantSparkVulnerability].count == 4 and not talents[AR.OrbBarrage] then
		return AR.ArcaneBarrage;
	end

	-- arcane_barrage,if=(debuff.radiant_spark_vulnerability.stack=2&cooldown.arcane_surge.remains>75)|(debuff.radiant_spark_vulnerability.stack=1&cooldown.arcane_surge.remains<75)&!talent.orb_barrage;
	if ( debuff[AR.RadiantSparkVulnerability].count == 2 and cooldown[AR.ArcaneSurge].remains > 75 ) or ( debuff[AR.RadiantSparkVulnerability].count == 1 and cooldown[AR.ArcaneSurge].remains < 75 ) and not talents[AR.OrbBarrage] then
		return AR.ArcaneBarrage;
	end

	-- arcane_barrage,if=(debuff.radiant_spark_vulnerability.stack=1|debuff.radiant_spark_vulnerability.stack=2|(debuff.radiant_spark_vulnerability.stack=3&active_enemies>5)|debuff.radiant_spark_vulnerability.stack=4)&buff.arcane_charge.stack=buff.arcane_charge.max_stack&talent.orb_barrage;
	if ( debuff[AR.RadiantSparkVulnerability].count == 1 or debuff[AR.RadiantSparkVulnerability].count == 2 or ( debuff[AR.RadiantSparkVulnerability].count == 3 and targets > 5 ) or debuff[AR.RadiantSparkVulnerability].count == 4 ) and buff[AR.ArcaneCharge].count == buff[AR.ArcaneCharge].maxStacks and talents[AR.OrbBarrage] then
		return AR.ArcaneBarrage;
	end

	-- presence_of_mind;
	if talents[AR.PresenceOfMind] and cooldown[AR.PresenceOfMind].ready then
		return AR.PresenceOfMind;
	end

	-- arcane_blast,if=((debuff.radiant_spark_vulnerability.stack=2|debuff.radiant_spark_vulnerability.stack=3)&!talent.orb_barrage)|(debuff.radiant_spark_vulnerability.remains&talent.orb_barrage);
	if mana >= 1375 and currentSpell ~= AR.ArcaneBlast and (( ( debuff[AR.RadiantSparkVulnerability].count == 2 or debuff[AR.RadiantSparkVulnerability].count == 3 ) and not talents[AR.OrbBarrage] ) or ( debuff[AR.RadiantSparkVulnerability].remains and talents[AR.OrbBarrage] )) then
		return AR.ArcaneBlast;
	end

	-- arcane_barrage,if=(debuff.radiant_spark_vulnerability.stack=4&buff.arcane_surge.up)|(debuff.radiant_spark_vulnerability.stack=3&buff.arcane_surge.down)&!talent.orb_barrage;
	if ( debuff[AR.RadiantSparkVulnerability].count == 4 and buff[AR.ArcaneSurge].up ) or ( debuff[AR.RadiantSparkVulnerability].count == 3 and not buff[AR.ArcaneSurge].up ) and not talents[AR.OrbBarrage] then
		return AR.ArcaneBarrage;
	end
end

function Mage:ArcaneAoeTouchPhase()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- variable,name=conserve_mana,op=set,if=debuff.touch_of_the_magi.remains>9,value=1-variable.conserve_mana;
	if debuff[AR.TouchOfTheMagi].remains > 9 then
		local conserveMana = 1 - conserveMana;
	end

	-- arcane_barrage,if=(active_enemies<=4&buff.arcane_charge.stack=3)|buff.arcane_charge.stack=buff.arcane_charge.max_stack;
	if ( targets <= 4 and buff[AR.ArcaneCharge].count == 3 ) or buff[AR.ArcaneCharge].count == buff[AR.ArcaneCharge].maxStacks then
		return AR.ArcaneBarrage;
	end

	-- arcane_orb,if=buff.arcane_charge.stack<2;
	if talents[AR.ArcaneOrb] and cooldown[AR.ArcaneOrb].ready and mana >= 500 and (buff[AR.ArcaneCharge].count < 2) then
		return AR.ArcaneOrb;
	end

	-- arcane_explosion;
	if mana >= 5000 then
		return AR.ArcaneExplosion;
	end
end

function Mage:ArcaneCooldownPhase()
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
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- touch_of_the_magi,use_off_gcd=1,if=prev_gcd.1.arcane_barrage;
	if talents[AR.TouchOfTheMagi] and cooldown[AR.TouchOfTheMagi].ready and mana >= 2500 and (spellHistory[1] == AR.ArcaneBarrage) then
		return AR.TouchOfTheMagi;
	end

	-- variable,name=conserve_mana,op=set,if=cooldown.radiant_spark.ready,value=0+(cooldown.arcane_surge.remains<10);
	if cooldown[AR.RadiantSpark].ready then
		local conserveMana = 0 + ( cooldown[AR.ArcaneSurge].remains < 10 );
	end

	-- shifting_power,if=buff.arcane_surge.down&!talent.radiant_spark;
	if talents[AR.ShiftingPower] and cooldown[AR.ShiftingPower].ready and mana >= 2500 and (not buff[AR.ArcaneSurge].up and not talents[AR.RadiantSpark]) then
		return AR.ShiftingPower;
	end

	-- arcane_orb,if=cooldown.radiant_spark.ready&buff.arcane_charge.stack<buff.arcane_charge.max_stack;
	if talents[AR.ArcaneOrb] and cooldown[AR.ArcaneOrb].ready and mana >= 500 and (cooldown[AR.RadiantSpark].ready and buff[AR.ArcaneCharge].count < buff[AR.ArcaneCharge].maxStacks) then
		return AR.ArcaneOrb;
	end

	-- arcane_blast,if=cooldown.radiant_spark.ready&(buff.arcane_charge.stack<2|(buff.arcane_charge.stack<buff.arcane_charge.max_stack&cooldown.arcane_orb.remains>=gcd.max));
	if mana >= 1375 and currentSpell ~= AR.ArcaneBlast and (cooldown[AR.RadiantSpark].ready and ( buff[AR.ArcaneCharge].count < 2 or ( buff[AR.ArcaneCharge].count < buff[AR.ArcaneCharge].maxStacks and cooldown[AR.ArcaneOrb].remains >= gcd ) )) then
		return AR.ArcaneBlast;
	end

	-- arcane_missiles,if=cooldown.radiant_spark.ready&buff.clearcasting.react&(talent.nether_precision&(buff.nether_precision.down|buff.nether_precision.remains<gcd.max));
	if talents[AR.ArcaneMissiles] and mana >= 7500 and (cooldown[AR.RadiantSpark].ready and buff[AR.Clearcasting].count and ( talents[AR.NetherPrecision] and ( not buff[AR.NetherPrecision].up or buff[AR.NetherPrecision].remains < gcd ) )) then
		return AR.ArcaneMissiles;
	end

	-- radiant_spark;
	if talents[AR.RadiantSpark] and cooldown[AR.RadiantSpark].ready and mana >= 1000 and currentSpell ~= AR.RadiantSpark then
		return AR.RadiantSpark;
	end

	-- nether_tempest,if=talent.arcane_echo,line_cd=30;
	if talents[AR.NetherTempest] and mana >= 750 and (talents[AR.ArcaneEcho]) then
		return AR.NetherTempest;
	end

	-- arcane_surge;
	if talents[AR.ArcaneSurge] and cooldown[AR.ArcaneSurge].ready and mana >= 63132 and currentSpell ~= AR.ArcaneSurge then
		return AR.ArcaneSurge;
	end

	-- arcane_barrage,if=prev_gcd.1.arcane_surge|prev_gcd.1.nether_tempest|prev_gcd.1.radiant_spark;
	if spellHistory[1] == AR.ArcaneSurge or spellHistory[1] == AR.NetherTempest or spellHistory[1] == AR.RadiantSpark then
		return AR.ArcaneBarrage;
	end

	-- arcane_blast,if=prev_gcd.1.arcane_barrage|prev_gcd.2.arcane_barrage|prev_gcd.3.arcane_barrage|(prev_gcd.4.arcane_barrage&cooldown.arcane_surge.remains<60);
	if mana >= 1375 and currentSpell ~= AR.ArcaneBlast and (spellHistory[1] == AR.ArcaneBarrage or spellHistory[2] == AR.ArcaneBarrage or spellHistory[3] == AR.ArcaneBarrage or ( spellHistory[4] == AR.ArcaneBarrage and cooldown[AR.ArcaneSurge].remains < 60 )) then
		return AR.ArcaneBlast;
	end

	-- presence_of_mind,if=debuff.touch_of_the_magi.remains<=gcd.max;
	if talents[AR.PresenceOfMind] and cooldown[AR.PresenceOfMind].ready and (debuff[AR.TouchOfTheMagi].remains <= gcd) then
		return AR.PresenceOfMind;
	end

	-- arcane_blast,if=buff.presence_of_mind.up;
	if mana >= 1375 and currentSpell ~= AR.ArcaneBlast and (buff[AR.PresenceOfMind].up) then
		return AR.ArcaneBlast;
	end

	-- arcane_missiles,if=buff.nether_precision.down&buff.clearcasting.react;
	if talents[AR.ArcaneMissiles] and mana >= 7500 and (not buff[AR.NetherPrecision].up and buff[AR.Clearcasting].count) then
		return AR.ArcaneMissiles;
	end

	-- arcane_blast;
	if mana >= 1375 and currentSpell ~= AR.ArcaneBlast then
		return AR.ArcaneBlast;
	end
end

function Mage:ArcaneRotation()
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

	-- arcane_orb,if=buff.arcane_charge.stack<3&(buff.bloodlust.down|mana.pct>70|(variable.totm_on_last_spark_stack&cooldown.touch_of_the_magi.remains>30));
	if talents[AR.ArcaneOrb] and cooldown[AR.ArcaneOrb].ready and mana >= 500 and (buff[AR.ArcaneCharge].count < 3 and ( not buff[AR.Bloodlust].up or manaPct > 70 or ( totmOnLastSparkStack and cooldown[AR.TouchOfTheMagi].remains > 30 ) )) then
		return AR.ArcaneOrb;
	end

	-- shifting_power,if=variable.totm_on_last_spark_stack&(!talent.evocation|cooldown.evocation.remains>12)&(!talent.arcane_surge|cooldown.arcane_surge.remains>12)&(!talent.touch_of_the_magi|cooldown.touch_of_the_magi.remains>12)&buff.arcane_surge.down&fight_remains>15;
	if talents[AR.ShiftingPower] and cooldown[AR.ShiftingPower].ready and mana >= 2500 and (totmOnLastSparkStack and ( not talents[AR.Evocation] or cooldown[AR.Evocation].remains > 12 ) and ( not talents[AR.ArcaneSurge] or cooldown[AR.ArcaneSurge].remains > 12 ) and ( not talents[AR.TouchOfTheMagi] or cooldown[AR.TouchOfTheMagi].remains > 12 ) and not buff[AR.ArcaneSurge].up and timeToDie > 15) then
		return AR.ShiftingPower;
	end

	-- shifting_power,if=!variable.totm_on_last_spark_stack&buff.arcane_surge.down&cooldown.arcane_surge.remains>45&fight_remains>15;
	if talents[AR.ShiftingPower] and cooldown[AR.ShiftingPower].ready and mana >= 2500 and (not totmOnLastSparkStack and not buff[AR.ArcaneSurge].up and cooldown[AR.ArcaneSurge].remains > 45 and timeToDie > 15) then
		return AR.ShiftingPower;
	end

	-- presence_of_mind,if=buff.arcane_charge.stack<3&target.health.pct<35&talent.arcane_bombardment;
	if talents[AR.PresenceOfMind] and cooldown[AR.PresenceOfMind].ready and (buff[AR.ArcaneCharge].count < 3 and targetHp < 35 and talents[AR.ArcaneBombardment]) then
		return AR.PresenceOfMind;
	end

	-- arcane_blast,if=talent.time_anomaly&buff.arcane_surge.up&buff.arcane_surge.remains<=6;
	if mana >= 1375 and currentSpell ~= AR.ArcaneBlast and (talents[AR.TimeAnomaly] and buff[AR.ArcaneSurge].up and buff[AR.ArcaneSurge].remains <= 6) then
		return AR.ArcaneBlast;
	end

	-- arcane_blast,if=buff.presence_of_mind.up&target.health.pct<35&talent.arcane_bombardment&buff.arcane_charge.stack<3;
	if mana >= 1375 and currentSpell ~= AR.ArcaneBlast and (buff[AR.PresenceOfMind].up and targetHp < 35 and talents[AR.ArcaneBombardment] and buff[AR.ArcaneCharge].count < 3) then
		return AR.ArcaneBlast;
	end

	-- arcane_missiles,if=buff.clearcasting.react&buff.clearcasting.stack=buff.clearcasting.max_stack;
	if talents[AR.ArcaneMissiles] and mana >= 7500 and (buff[AR.Clearcasting].count and buff[AR.Clearcasting].count == buff[AR.Clearcasting].maxStacks) then
		return AR.ArcaneMissiles;
	end

	-- nether_tempest,if=(refreshable|!ticking)&buff.arcane_charge.stack=buff.arcane_charge.max_stack&(buff.temporal_warp.up|mana.pct<10|!talent.shifting_power)&buff.arcane_surge.down&fight_remains>=12;
	if talents[AR.NetherTempest] and mana >= 750 and (( debuff[AR.NetherTempest].refreshable or not debuff[AR.NetherTempest].up ) and buff[AR.ArcaneCharge].count == buff[AR.ArcaneCharge].maxStacks and ( buff[AR.TemporalWarp].up or manaPct < 10 or not talents[AR.ShiftingPower] ) and not buff[AR.ArcaneSurge].up and timeToDie >= 12) then
		return AR.NetherTempest;
	end

	-- arcane_barrage,if=buff.arcane_charge.stack=buff.arcane_charge.max_stack&mana.pct<50&!talent.evocation&fight_remains>20;
	if buff[AR.ArcaneCharge].count == buff[AR.ArcaneCharge].maxStacks and manaPct < 50 and not talents[AR.Evocation] and timeToDie > 20 then
		return AR.ArcaneBarrage;
	end

	-- arcane_barrage,if=buff.arcane_charge.stack=buff.arcane_charge.max_stack&mana.pct<70&variable.conserve_mana&buff.bloodlust.up&cooldown.touch_of_the_magi.remains>5&fight_remains>20;
	if buff[AR.ArcaneCharge].count == buff[AR.ArcaneCharge].maxStacks and manaPct < 70 and conserveMana and buff[AR.Bloodlust].up and cooldown[AR.TouchOfTheMagi].remains > 5 and timeToDie > 20 then
		return AR.ArcaneBarrage;
	end

	-- arcane_missiles,if=buff.clearcasting.react&buff.concentration.up&buff.arcane_charge.stack=buff.arcane_charge.max_stack;
	if talents[AR.ArcaneMissiles] and mana >= 7500 and (buff[AR.Clearcasting].count and buff[AR.Concentration].up and buff[AR.ArcaneCharge].count == buff[AR.ArcaneCharge].maxStacks) then
		return AR.ArcaneMissiles;
	end

	-- arcane_blast,if=buff.arcane_charge.stack=buff.arcane_charge.max_stack&buff.nether_precision.up;
	if mana >= 1375 and currentSpell ~= AR.ArcaneBlast and (buff[AR.ArcaneCharge].count == buff[AR.ArcaneCharge].maxStacks and buff[AR.NetherPrecision].up) then
		return AR.ArcaneBlast;
	end

	-- arcane_barrage,if=buff.arcane_charge.stack=buff.arcane_charge.max_stack&mana.pct<60&variable.conserve_mana&cooldown.touch_of_the_magi.remains>10&cooldown.evocation.remains>40&fight_remains>20;
	if buff[AR.ArcaneCharge].count == buff[AR.ArcaneCharge].maxStacks and manaPct < 60 and conserveMana and cooldown[AR.TouchOfTheMagi].remains > 10 and cooldown[AR.Evocation].remains > 40 and timeToDie > 20 then
		return AR.ArcaneBarrage;
	end

	-- arcane_missiles,if=buff.clearcasting.react&buff.nether_precision.down;
	if talents[AR.ArcaneMissiles] and mana >= 7500 and (buff[AR.Clearcasting].count and not buff[AR.NetherPrecision].up) then
		return AR.ArcaneMissiles;
	end

	-- arcane_blast;
	if mana >= 1375 and currentSpell ~= AR.ArcaneBlast then
		return AR.ArcaneBlast;
	end

	-- arcane_barrage;
	-- AR.ArcaneBarrage;
end

function Mage:ArcaneSparkPhase()
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
	local timeShift = fd.timeShift;
	local gcd = fd.gcd;
	local gcdRemains = fd.gcdRemains;
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- nether_tempest,if=!ticking&variable.opener&buff.bloodlust.up,line_cd=45;
	if talents[AR.NetherTempest] and mana >= 750 and (not debuff[AR.NetherTempest].up and opener and buff[AR.Bloodlust].up) then
		return AR.NetherTempest;
	end

	-- arcane_blast,if=variable.opener&cooldown.arcane_surge.ready&buff.bloodlust.up&mana>=variable.opener_min_mana;
	if mana >= 1375 and currentSpell ~= AR.ArcaneBlast and (opener and cooldown[AR.ArcaneSurge].ready and buff[AR.Bloodlust].up and mana >= openerMinMana) then
		return AR.ArcaneBlast;
	end

	-- arcane_missiles,if=variable.opener&buff.bloodlust.up&buff.clearcasting.react&buff.clearcasting.stack>=2&cooldown.radiant_spark.remains<5&buff.nether_precision.down,chain=1;
	if talents[AR.ArcaneMissiles] and mana >= 7500 and (opener and buff[AR.Bloodlust].up and buff[AR.Clearcasting].count and buff[AR.Clearcasting].count >= 2 and cooldown[AR.RadiantSpark].remains < 5 and not buff[AR.NetherPrecision].up) then
		return AR.ArcaneMissiles;
	end

	-- arcane_missiles,if=talent.arcane_harmony&buff.arcane_harmony.stack<15&((variable.opener&buff.bloodlust.up)|buff.clearcasting.react&cooldown.radiant_spark.remains<5)&cooldown.arcane_surge.remains<30,chain=1;
	if talents[AR.ArcaneMissiles] and mana >= 7500 and (talents[AR.ArcaneHarmony] and buff[AR.ArcaneHarmony].count < 15 and ( ( opener and buff[AR.Bloodlust].up ) or buff[AR.Clearcasting].count and cooldown[AR.RadiantSpark].remains < 5 ) and cooldown[AR.ArcaneSurge].remains < 30) then
		return AR.ArcaneMissiles;
	end

	-- radiant_spark;
	if talents[AR.RadiantSpark] and cooldown[AR.RadiantSpark].ready and mana >= 1000 and currentSpell ~= AR.RadiantSpark then
		return AR.RadiantSpark;
	end

	-- nether_tempest,if=(prev_gcd.4.radiant_spark&cooldown.arcane_surge.remains<=execute_time)|prev_gcd.5.radiant_spark,line_cd=15;
	if talents[AR.NetherTempest] and mana >= 750 and (( spellHistory[4] == AR.RadiantSpark and cooldown[AR.ArcaneSurge].remains <= timeShift ) or spellHistory[5] == AR.RadiantSpark) then
		return AR.NetherTempest;
	end

	-- arcane_surge,if=(!talent.nether_tempest&prev_gcd.4.radiant_spark)|prev_gcd.1.nether_tempest;
	if talents[AR.ArcaneSurge] and cooldown[AR.ArcaneSurge].ready and mana >= 63132 and currentSpell ~= AR.ArcaneSurge and (( not talents[AR.NetherTempest] and spellHistory[4] == AR.RadiantSpark ) or spellHistory[1] == AR.NetherTempest) then
		return AR.ArcaneSurge;
	end

	-- arcane_blast,if=cast_time>=gcd&execute_time<debuff.radiant_spark_vulnerability.remains&(!talent.arcane_bombardment|target.health.pct>=35)&(talent.nether_tempest&prev_gcd.6.radiant_spark|!talent.nether_tempest&prev_gcd.5.radiant_spark);
	if mana >= 1375 and currentSpell ~= AR.ArcaneBlast and (timeShift >= gcd and timeShift < debuff[AR.RadiantSparkVulnerability].remains and ( not talents[AR.ArcaneBombardment] or targetHp >= 35 ) and ( talents[AR.NetherTempest] and spellHistory[6] == AR.RadiantSpark or not talents[AR.NetherTempest] and spellHistory[5] == AR.RadiantSpark )) then
		return AR.ArcaneBlast;
	end

	-- arcane_barrage,if=debuff.radiant_spark_vulnerability.stack=4;
	if debuff[AR.RadiantSparkVulnerability].count == 4 then
		return AR.ArcaneBarrage;
	end

	-- touch_of_the_magi,use_off_gcd=1,if=prev_gcd.1.arcane_barrage&(action.arcane_barrage.in_flight_remains<=0.2|gcd.remains<=0.2);
	if talents[AR.TouchOfTheMagi] and cooldown[AR.TouchOfTheMagi].ready and mana >= 2500 and (spellHistory[1] == AR.ArcaneBarrage and ( cooldown[AR.ArcaneBarrage].in_flight_remains <= 0.2 or gcdRemains <= 0.2 )) then
		return AR.TouchOfTheMagi;
	end

	-- arcane_blast;
	if mana >= 1375 and currentSpell ~= AR.ArcaneBlast then
		return AR.ArcaneBlast;
	end

	-- arcane_barrage;
	-- AR.ArcaneBarrage;
end

function Mage:ArcaneTouchPhase()
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
	local mana = UnitPower('player', Enum.PowerType.Mana);
	local manaMax = UnitPowerMax('player', Enum.PowerType.Mana);
	local manaPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local manaRegen = select(2,GetPowerRegen());
	local manaRegenCombined = manaRegen + mana;
	local manaDeficit = UnitPowerMax('player', Enum.PowerType.Mana) - mana;
	local manaTimeToMax = manaMax - mana / manaRegen;

	-- variable,name=conserve_mana,op=set,if=debuff.touch_of_the_magi.remains>9,value=1-variable.conserve_mana;
	if debuff[AR.TouchOfTheMagi].remains > 9 then
		local conserveMana = 1 - conserveMana;
	end

	-- presence_of_mind,if=debuff.touch_of_the_magi.remains<=gcd.max;
	if talents[AR.PresenceOfMind] and cooldown[AR.PresenceOfMind].ready and (debuff[AR.TouchOfTheMagi].remains <= gcd) then
		return AR.PresenceOfMind;
	end

	-- arcane_blast,if=buff.presence_of_mind.up&buff.arcane_charge.stack=buff.arcane_charge.max_stack;
	if mana >= 1375 and currentSpell ~= AR.ArcaneBlast and (buff[AR.PresenceOfMind].up and buff[AR.ArcaneCharge].count == buff[AR.ArcaneCharge].maxStacks) then
		return AR.ArcaneBlast;
	end

	-- arcane_barrage,if=(buff.arcane_harmony.up|(talent.arcane_bombardment&target.health.pct<35))&debuff.touch_of_the_magi.remains<=gcd.max;
	if ( buff[AR.ArcaneHarmony].up or ( talents[AR.ArcaneBombardment] and targetHp < 35 ) ) and debuff[AR.TouchOfTheMagi].remains <= gcd then
		return AR.ArcaneBarrage;
	end

	-- arcane_missiles,if=buff.clearcasting.stack>1&talent.conjure_mana_gem&cooldown.use_mana_gem.ready,chain=1;
	if talents[AR.ArcaneMissiles] and mana >= 7500 and (buff[AR.Clearcasting].count > 1 and talents[AR.ConjureManaGem] and cooldown[AR.UseManaGem].ready) then
		return AR.ArcaneMissiles;
	end

	-- arcane_blast,if=buff.nether_precision.up;
	if mana >= 1375 and currentSpell ~= AR.ArcaneBlast and (buff[AR.NetherPrecision].up) then
		return AR.ArcaneBlast;
	end

	-- arcane_missiles,if=buff.clearcasting.react&(debuff.touch_of_the_magi.remains>execute_time|!talent.presence_of_mind),chain=1;
	if talents[AR.ArcaneMissiles] and mana >= 7500 and (buff[AR.Clearcasting].count and ( debuff[AR.TouchOfTheMagi].remains > timeShift or not talents[AR.PresenceOfMind] )) then
		return AR.ArcaneMissiles;
	end

	-- arcane_blast;
	if mana >= 1375 and currentSpell ~= AR.ArcaneBlast then
		return AR.ArcaneBlast;
	end

	-- arcane_barrage;
	-- AR.ArcaneBarrage;
end


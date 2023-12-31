local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then return end

local DeathKnight = addonTable.DeathKnight;
local MaxDps = MaxDps;
local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;
local GetTotemInfo = GetTotemInfo;
local GetTime = GetTime;

local RunicPower = Enum.PowerType.RunicPower;
local Runes = Enum.PowerType.Runes;

local FR = {
	Avalanche 			= 207142,
	BitingCold 			= 377056,
	BreathOfSindragosa 	= 152279,
	ChainsOfIce 		= 45524,
	ColdHeart 			= 281208,
	ColdHeartBuff 		= 281209,
	Everfrost 			= 376938,
	FrostFever 			= 55095,
	Frostscythe 		= 207230,
	FrostStrike 		= 49143,
	FrostwyrmsFury 		= 279302,
	GatheringStorm 		= 194912,
	GlacialAdvance 		= 194913,
	HornOfWinter 		= 57330,
	HowlingBlast 		= 49184,
	Icecap 				= 207126,
	KillingMachine 		= 51128,
	KillingMachineBuff 	= 51124,
	Obliterate 			= 49020,
	Obliteration 		= 281238,
	PillarOfFrost 		= 51271,
	Razorice 			= 51714,
	RemorselessWinter 	= 196770,
	Rime 				= 59052,
	RunicAttenuation 	= 207104,
	ShackleTheUnworthy 	= 312202,
	SwarmingMist		= 311648,
	UnholyStrength 		= 53365,
};

setmetatable(FR, DeathKnight.spellMeta);

local enchant = DeathKnight.hasEnchant;
local weaponRunes = DeathKnight.weaponRunes;

function DeathKnight:Frost()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = MaxDps:SmartAoe();
	local gcd = fd.gcd;
	local runes = DeathKnight:Runes(fd.timeShift);
	local runicPower = UnitPower('player', RunicPower);
	local runicPowerMax = UnitPowerMax('player', RunicPower);
	local deathKnightRuneforgeRazorice = enchant[weaponRunes.Razorice];
	local timeTo2Runes = DeathKnight:TimeToRunes(2);
	local timeTo3Runes = DeathKnight:TimeToRunes(3);
	local timeTo4Runes = DeathKnight:TimeToRunes(4);
	local timeTo5Runes = DeathKnight:TimeToRunes(5);
	local targetHpPercent = MaxDps:TargetPercentHealth() * 100;

	fd.targets = targets;
	fd.runes = runes;
	fd.runicPower = runicPower;
	fd.runicPowerMax = runicPowerMax;
	fd.timeTo2Runes = timeTo2Runes;
	fd.timeTo3Runes = timeTo3Runes;
	fd.timeTo4Runes = timeTo4Runes;
	fd.timeTo5Runes = timeTo5Runes;

	DeathKnight:FrostGlowCooldowns();
	
	if talents[COMMON.SoulReaper] and targetHpPercent <= 35 and cooldown[COMMON.SoulReaper].ready then
		return COMMON.SoulReaper;
	end

	-- howling_blast,if=!dot.frost_fever.ticking&(talent.icecap|cooldown.breath_of_sindragosa.remains>15|talent.obliteration&cooldown.pillar_of_frost.remains&!buff.killing_machine.up);
	if runes >= 1 and
		not debuff[FR.FrostFever].up and
		(
			talents[FR.Icecap] or
			cooldown[FR.BreathOfSindragosa].remains > 15 or
			(
				talents[FR.Obliteration] and
				cooldown[FR.PillarOfFrost].remains and
				not buff[FR.KillingMachineBuff].up
			)
		)
	then
		return FR.HowlingBlast;
	end

	-- glacial_advance,if=buff.icy_talons.remains<=gcd&buff.icy_talons.up&spell_targets.glacial_advance>=2&(!talent.breath_of_sindragosa|cooldown.breath_of_sindragosa.remains>15);
	if talents[FR.GlacialAdvance] and
		cooldown[FR.GlacialAdvance].ready and
		runicPower >= 30 and
		buff[COMMON.IcyTalons].remains <= gcd and
		buff[COMMON.IcyTalons].up and
		targets >= 2 and
		(not talents[FR.BreathOfSindragosa] or cooldown[FR.BreathOfSindragosa].remains > 15)
	then
		return FR.GlacialAdvance;
	end

	-- frost_strike,if=buff.icy_talons.remains<=gcd&buff.icy_talons.up&(!talent.breath_of_sindragosa|cooldown.breath_of_sindragosa.remains>15);
	if runicPower >= 25 and
		buff[COMMON.IcyTalons].remains <= gcd and
		buff[COMMON.IcyTalons].up and
		(not talents[FR.BreathOfSindragosa] or cooldown[FR.BreathOfSindragosa].remains > 15 )
	then
		return FR.FrostStrike;
	end

	local result;

	-- call_action_list,name=cooldowns;
	result = DeathKnight:FrostCooldowns();
	if result then
		return result;
	end

	-- call_action_list,name=cold_heart,if=talent.cold_heart&(buff.cold_heart.stack>=10&(debuff.razorice.stack=5|!death_knight.runeforge.razorice)|fight_remains<=gcd);
	if talents[FR.ColdHeart] and
		buff[FR.ColdHeartBuff].count >= 10 and
		( debuff[FR.Razorice].count == 5 or not deathKnightRuneforgeRazorice )
	-- or fightRemains <= gcd )
	then
		result = DeathKnight:FrostColdHeart();
		if result then
			return result;
		end
	end

	-- run_action_list,name=bos_ticking,if=buff.breath_of_sindragosa.up;
	if buff[FR.BreathOfSindragosa].up then
		return DeathKnight:FrostBosTicking();
	end

	-- run_action_list,name=bos_pooling,if=talent.breath_of_sindragosa&(cooldown.breath_of_sindragosa.remains<10);
	if talents[FR.BreathOfSindragosa] and cooldown[FR.BreathOfSindragosa].remains < 10 then
		return DeathKnight:FrostBosPooling();
	end

	-- run_action_list,name=obliteration,if=buff.pillar_of_frost.up&talent.obliteration;
	if buff[FR.PillarOfFrost].up and talents[FR.Obliteration] then
		return DeathKnight:FrostObliteration();
	end

	-- run_action_list,name=obliteration_pooling,if=talent.obliteration&cooldown.pillar_of_frost.remains<10;
	if talents[FR.Obliteration] and cooldown[FR.PillarOfFrost].remains < 10 then
		return DeathKnight:FrostObliterationPooling();
	end

	-- run_action_list,name=aoe,if=active_enemies>=2;
	if targets >= 2 then
		return DeathKnight:FrostAoe();
	end

	-- call_action_list,name=standard;
	result = DeathKnight:FrostStandard();
	if result then
		return result;
	end
end

function DeathKnight:FrostGlowCooldowns()
	local fd = MaxDps.FrameData;
	local gcd = fd.gcd;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets;
	local deathKnightRuneforgeFallenCrusader = enchant[weaponRunes.FallenCrusader];
	local deathKnightRuneforgeRazorice = enchant[weaponRunes.Razorice];

	local frostwyrmsFuryReady = DeathKnight.db.frostFrostwyrmsFuryAsCooldown and cooldown[FR.FrostwyrmsFury].ready;
	local abominationLimbReady = DeathKnight.db.abominationLimbAsCooldown and talents[COMMON.AbominationLimbTalent] and cooldown[COMMON.AbominationLimbTalent].ready;

	if DeathKnight.db.alwaysGlowCooldowns then
		MaxDps:GlowCooldown(FR.FrostwyrmsFury, frostwyrmsFuryReady);
		MaxDps:GlowCooldown(COMMON.AbominationLimbTalent, abominationLimbReady);
	else
		local frostwyrmsFuryCooldownTrigger = frostwyrmsFuryReady and
			(
				(
					buff[FR.PillarOfFrost].remains < gcd and
					buff[FR.PillarOfFrost].up and
					not talents[FR.Obliteration]
				) or
				(
					targets >= 2 and
					buff[FR.PillarOfFrost].up and
					buff[FR.PillarOfFrost].remains < gcd
				) or
				(
					talents[FR.Obliteration] and
					not buff[FR.PillarOfFrost].up and
					(buff[FR.UnholyStrength].up or not deathKnightRuneforgeFallenCrusader) and
					(debuff[FR.Razorice].count == 5 or not deathKnightRuneforgeRazorice)
				)
			);

		local abominationLimbCooldownTrigger = abominationLimbReady and
			(
				(targets <= 1 and cooldown[FR.PillarOfFrost].remains < 3) or
					targets >= 2
			)

		MaxDps:GlowCooldown(FR.FrostwyrmsFury, frostwyrmsFuryCooldownTrigger);
		MaxDps:GlowCooldown(COMMON.AbominationLimbTalent, abominationLimbCooldownTrigger);
	end
end

function DeathKnight:FrostAoe()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local gcd = fd.gcd;
	local runes = fd.runes;
	local runicPower = fd.runicPower;
	local runicPowerMax = fd.runicPowerMax;
	local runicPowerDeficit = runicPowerMax - runicPower;

	-- remorseless_winter;
	if cooldown[FR.RemorselessWinter].ready and runes >= 1 then
		return FR.RemorselessWinter;
	end

	-- glacial_advance,if=talent.frostscythe;
	if talents[FR.GlacialAdvance] and cooldown[FR.GlacialAdvance].ready and runicPower >= 30 and talents[FR.Frostscythe] then
		return FR.GlacialAdvance;
	end

	-- frost_strike,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice,if=cooldown.remorseless_winter.remains<=2*gcd&talent.gathering_storm;
	if runicPower >= 25 and cooldown[FR.RemorselessWinter].remains <= 2 * gcd and talents[FR.GatheringStorm] then
		return FR.FrostStrike;
	end

	-- howling_blast,if=buff.rime.up;
	if buff[FR.Rime].up then
		return FR.HowlingBlast;
	end

	-- glacial_advance,if=runic_power.deficit<(15+talent.runic_attenuation*3);
	if talents[FR.GlacialAdvance] and
		cooldown[FR.GlacialAdvance].ready and
		runicPower >= 30 and
		(runicPowerDeficit < (15 + (talents[FR.RunicAttenuation] and 1 or 0) * 3))
	then
		return FR.GlacialAdvance;
	end

	-- frost_strike,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice,if=runic_power.deficit<(15+talent.runic_attenuation*3);
	if runicPower >= 25 and (runicPowerDeficit < (15 + (talents[FR.RunicAttenuation] and 1 or 0) * 3)) then
		return FR.FrostStrike;
	end

	if talents[FR.Frostscythe] and runes >= 1 then
		return FR.Frostscythe;
	end

	-- obliterate,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice,if=runic_power.deficit>(25+talent.runic_attenuation*3);
	if runes >= 2 and (runicPowerDeficit > (25 + (talents[FR.RunicAttenuation] and 1 or 0) * 3)) then
		return FR.Obliterate;
	end

	-- glacial_advance;
	if talents[FR.GlacialAdvance] and cooldown[FR.GlacialAdvance].ready and runicPower >= 30 then
		return FR.GlacialAdvance;
	end

	-- frost_strike,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice;
	if runicPower >= 25 then
		return FR.FrostStrike;
	end

	-- horn_of_winter;
	if talents[FR.HornOfWinter] and cooldown[FR.HornOfWinter].ready then
		return FR.HornOfWinter;
	end
end

function DeathKnight:FrostBosPooling()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local targets = fd.targets;
	local gcd = fd.gcd;
	local runes = fd.runes;
	local runicPower = fd.runicPower;
	local runicPowerMax = fd.runicPowerMax;
	local runicPowerDeficit = runicPowerMax - runicPower;
	local runeforge = fd.runeforge;
	local timeTo4Runes = fd.timeTo4Runes;
	local timeTo5Runes = fd.timeTo5Runes;

	-- howling_blast,if=buff.rime.up;
	if buff[FR.Rime].up then
		return FR.HowlingBlast;
	end

	-- remorseless_winter,if=active_enemies>=2|rune.time_to_5<=gcd&(talent.gathering_storm|runeforge.biting_cold);
	if cooldown[FR.RemorselessWinter].ready and
		runes >= 1 and
		(
			targets >= 2 or
			timeTo5Runes <= gcd and ( talents[FR.GatheringStorm] or runeforge[FR.BitingCold])
		)
	then
		return FR.RemorselessWinter;
	end

	-- obliterate,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice,if=runic_power.deficit>=25;
	if runes >= 2 and (runicPowerDeficit >= 25) then
		return FR.Obliterate;
	end

	-- glacial_advance,if=runic_power.deficit<20&spell_targets.glacial_advance>=2&cooldown.pillar_of_frost.remains>5;
	if talents[FR.GlacialAdvance] and
		cooldown[FR.GlacialAdvance].ready and
		runicPower >= 30 and
		(runicPowerDeficit < 20 and targets >= 2 and cooldown[FR.PillarOfFrost].remains > 5)
	then
		return FR.GlacialAdvance;
	end

	-- frost_strike,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice,if=runic_power.deficit<20&cooldown.pillar_of_frost.remains>5;
	if runicPower >= 25 and (runicPowerDeficit < 20 and cooldown[FR.PillarOfFrost].remains > 5) then
		return FR.FrostStrike;
	end

	-- frostscythe,if=runic_power.deficit>=(35+talent.runic_attenuation*3)&spell_targets.frostscythe>=2&(buff.deaths_due.stack=8|!death_and_decay.ticking);
	if talents[FR.Frostscythe] and
		runes >= 1 and
		runicPowerDeficit >= (35 + (talents[FR.RunicAttenuation] and 1 or 0) * 3) and
		targets >= 2 
	then
		return FR.Frostscythe;
	end

	-- glacial_advance,if=cooldown.pillar_of_frost.remains>rune.time_to_4&runic_power.deficit<40&spell_targets.glacial_advance>=2;
	if talents[FR.GlacialAdvance] and
		cooldown[FR.GlacialAdvance].ready and
		runicPower >= 30 and
		cooldown[FR.PillarOfFrost].remains > timeTo4Runes and
		runicPowerDeficit < 40 and
		targets >= 2
	then
		return FR.GlacialAdvance;
	end

	-- frost_strike,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice,if=cooldown.pillar_of_frost.remains>rune.time_to_4&runic_power.deficit<40;
	if runicPower >= 25 and cooldown[FR.PillarOfFrost].remains > timeTo4Runes and runicPowerDeficit < 40 then
		return FR.FrostStrike;
	end
end

function DeathKnight:FrostBosTicking()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local targets = fd.targets;
	local gcd = fd.gcd;
	local runes = fd.runes;
	local runicPower = fd.runicPower;
	local runicPowerMax = fd.runicPowerMax;
	local runicPowerDeficit = runicPowerMax - runicPower;
	local runeforge = fd.runeforge;
	local timeTo3Runes = fd.timeTo3Runes;
	local timeTo4Runes = fd.timeTo4Runes;

	-- obliterate,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice,if=runic_power.deficit>=60;
	if runes >= 2 and (runicPowerDeficit >= 60) then
		return FR.Obliterate;
	end

	-- remorseless_winter,if=talent.gathering_storm|runeforge.biting_cold|active_enemies>=2;
	if cooldown[FR.RemorselessWinter].ready and
		runes >= 1 and
		(talents[FR.GatheringStorm] or talents[FR.Everfrost] or runeforge[FR.BitingCold] or targets >= 2)
	then
		return FR.RemorselessWinter;
	end

	-- howling_blast,if=buff.rime.up&(runic_power.deficit<55|rune.time_to_3<=gcd|spell_targets.howling_blast>=2);
	if buff[FR.Rime].up and (runicPowerDeficit < 55 or timeTo3Runes <= gcd or targets >= 2) then
		return FR.HowlingBlast;
	end

	-- obliterate,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice,if=rune.time_to_4<gcd|runic_power.deficit>=45;
	if runes >= 2 and (timeTo4Runes < gcd or runicPowerDeficit >= 45) then
		return FR.Obliterate;
	end

	-- frostscythe,if=buff.killing_machine.up&spell_targets.frostscythe>=2&(!death_and_decay.ticking);
	if talents[FR.Frostscythe] and
		runes >= 1 and
		buff[FR.KillingMachineBuff].up and
		targets >= 2 then
		return FR.Frostscythe;
	end

	-- horn_of_winter,if=runic_power.deficit>=40&rune.time_to_3>gcd;
	if talents[FR.HornOfWinter] and
		cooldown[FR.HornOfWinter].ready and
		runicPowerDeficit >= 40 and
		timeTo3Runes > gcd
	then
		return FR.HornOfWinter;
	end

	-- frostscythe,if=spell_targets.frostscythe>=2&(buff.deaths_due.stack=8|!death_and_decay.ticking);
	if talents[FR.Frostscythe] and
		runes >= 1 and
		targets >= 2
	then
		return FR.Frostscythe;
	end

	-- obliterate,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice,if=runic_power.deficit>25&rune>3;
	if runes >= 2 and runicPowerDeficit > 25 and runes > 3 then
		return FR.Obliterate;
	end

	-- howling_blast,if=buff.rime.up;
	if buff[FR.Rime].up then
		return FR.HowlingBlast;
	end
end

function DeathKnight:FrostColdHeart()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local runes = fd.runes;
	local deathKnightRuneforgeFallenCrusader = enchant[weaponRunes.FallenCrusader];

	-- chains_of_ice,if=fight_remains<gcd;
	if runes >= 1
	--and (fightRemains < gcd)
	then
		return FR.ChainsOfIce;
	end

	-- chains_of_ice,if=!talent.obliteration&buff.pillar_of_frost.remains<3&buff.pillar_of_frost.up&buff.cold_heart.stack>=10;
	if runes >= 1 and
		not talents[FR.Obliteration] and
		buff[FR.PillarOfFrost].remains < 3 and
		buff[FR.PillarOfFrost].up and
		buff[FR.ColdHeartBuff].count >= 10
	then
		return FR.ChainsOfIce;
	end

	-- chains_of_ice,if=!talent.obliteration&death_knight.runeforge.fallen_crusader&!buff.pillar_of_frost.up&(buff.cold_heart.stack>=16&buff.unholy_strength.up|buff.cold_heart.stack>=19&cooldown.pillar_of_frost.remains>10)
	if runes >= 1 and
		not talents[FR.Obliteration] and
		deathKnightRuneforgeFallenCrusader and
		not buff[FR.PillarOfFrost].up and
		(
			buff[FR.ColdHeartBuff].count >= 16 and buff[FR.UnholyStrength].up or
			buff[FR.ColdHeartBuff].count >= 19 and cooldown[FR.PillarOfFrost].remains > 10
		)
	then
		return FR.ChainsOfIce;
	end

	-- chains_of_ice,if=!talent.obliteration&!death_knight.runeforge.fallen_crusader&buff.cold_heart.stack>=10&!buff.pillar_of_frost.up&cooldown.pillar_of_frost.remains>20
	if runes >= 1 and
		not talents[FR.Obliteration] and
		not deathKnightRuneforgeFallenCrusader and
		buff[FR.ColdHeartBuff].count >= 10 and
		not buff[FR.PillarOfFrost].up and
		cooldown[FR.PillarOfFrost].remains > 20
	then
		return FR.ChainsOfIce;
	end

	-- chains_of_ice,if=talent.obliteration&!buff.pillar_of_frost.up&(buff.cold_heart.stack>=16&buff.unholy_strength.up|buff.cold_heart.stack>=19|cooldown.pillar_of_frost.remains<3&buff.cold_heart.stack>=14);
	if runes >= 1 and
		talents[FR.Obliteration] and
		not buff[FR.PillarOfFrost].up and
		(
			buff[FR.ColdHeartBuff].count >= 16 and buff[FR.UnholyStrength].up or
			buff[FR.ColdHeartBuff].count >= 19 or
			cooldown[FR.PillarOfFrost].remains < 3 and buff[FR.ColdHeartBuff].count >= 14
		)
	then
		return FR.ChainsOfIce;
	end
end

function DeathKnight:FrostCooldowns()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets;
	local gcd = fd.gcd;
	local timeToDie = fd.timeToDie;
	local runes = fd.runes;
	local runicPower = fd.runicPower;
	local runicPowerMax = fd.runicPowerMax;
	local runicPowerDeficit = runicPowerMax - runicPower;
	local runeforge = fd.runeforge;
	local deathKnightRuneforgeFallenCrusader = enchant[weaponRunes.FallenCrusader];
	local deathKnightRuneforgeRazorice = enchant[weaponRunes.Razorice];
	local timeTo5Runes = fd.timeTo5Runes;

	local ghoulActive, _, ghoulStart, ghoulDuration = GetTotemInfo(1);
	local ghoulRemains = 0;
	if ghoulActive then
		ghoulRemains = ghoulDuration - (GetTime() - ghoulStart);
	end

	-- empower_rune_weapon,if=talent.obliteration&(cooldown.pillar_of_frost.ready&rune.time_to_5>gcd&runic_power.deficit>=10|buff.pillar_of_frost.up&rune.time_to_5>gcd)|fight_remains<20;
	if cooldown[COMMON.EmpowerRuneWeapon].ready and
		talents[FR.Obliteration] and
		(
			cooldown[FR.PillarOfFrost].ready and timeTo5Runes > gcd and runicPowerDeficit >= 10 or
			buff[FR.PillarOfFrost].up and timeTo5Runes > gcd
		)
	-- or fightRemains < 20)
	then
		return COMMON.EmpowerRuneWeapon;
	end

	-- empower_rune_weapon,if=talent.breath_of_sindragosa&runic_power.deficit>40&rune.time_to_5>gcd&(buff.breath_of_sindragosa.up|fight_remains<20);
	if cooldown[COMMON.EmpowerRuneWeapon].ready and
		talents[FR.BreathOfSindragosa] and
		runicPowerDeficit > 40 and
		timeTo5Runes > gcd and
		buff[FR.BreathOfSindragosa].up
	-- or fightRemains < 20 ))
	then
		return COMMON.EmpowerRuneWeapon;
	end

	-- empower_rune_weapon,if=talent.icecap&rune<3;
	if cooldown[COMMON.EmpowerRuneWeapon].ready and talents[FR.Icecap] and runes < 3 then
		return COMMON.EmpowerRuneWeapon;
	end

	-- pillar_of_frost,if=talent.breath_of_sindragosa&(cooldown.breath_of_sindragosa.remains|cooldown.breath_of_sindragosa.ready&runic_power.deficit<60);
	if cooldown[FR.PillarOfFrost].ready and
		talents[FR.BreathOfSindragosa] and
		(cooldown[FR.BreathOfSindragosa].remains or cooldown[FR.BreathOfSindragosa].ready and runicPowerDeficit < 60)
	then
		return FR.PillarOfFrost;
	end

	-- pillar_of_frost,if=talent.icecap&!buff.pillar_of_frost.up;
	if cooldown[FR.PillarOfFrost].ready and talents[FR.Icecap] and not buff[FR.PillarOfFrost].up then
		return FR.PillarOfFrost;
	end

	-- pillar_of_frost,if=talent.obliteration&(talent.gathering_storm.enabled&buff.remorseless_winter.up|!talent.gathering_storm.enabled);
	if cooldown[FR.PillarOfFrost].ready and
		talents[FR.Obliteration] and
		((talents[FR.GatheringStorm] and buff[FR.RemorselessWinter].up) or not talents[FR.GatheringStorm])
	then
		return FR.PillarOfFrost;
	end

	-- breath_of_sindragosa,if=buff.pillar_of_frost.up;
	if talents[FR.BreathOfSindragosa] and
		cooldown[FR.BreathOfSindragosa].ready and
		runicPower >= 16 and
		buff[FR.PillarOfFrost].up
	then
		return FR.BreathOfSindragosa;
	end

	-- frostwyrms_fury,if=buff.pillar_of_frost.remains<gcd&buff.pillar_of_frost.up&!talent.obliteration;
	if cooldown[FR.FrostwyrmsFury].ready and
		not DeathKnight.db.frostFrostwyrmsFuryAsCooldown and
		buff[FR.PillarOfFrost].remains < gcd and
		buff[FR.PillarOfFrost].up and
		not talents[FR.Obliteration]
	then
		return FR.FrostwyrmsFury;
	end

	-- frostwyrms_fury,if=active_enemies>=2&(buff.pillar_of_frost.up&buff.pillar_of_frost.remains<gcd|raid_event.adds.exists&raid_event.adds.remains<gcd|fight_remains<gcd);
	if cooldown[FR.FrostwyrmsFury].ready and
		not DeathKnight.db.frostFrostwyrmsFuryAsCooldown and
		targets >= 2 and
		buff[FR.PillarOfFrost].up and
		buff[FR.PillarOfFrost].remains < gcd
	then
		return FR.FrostwyrmsFury;
	end

	-- frostwyrms_fury,if=talent.obliteration&!buff.pillar_of_frost.up&((buff.unholy_strength.up|!death_knight.runeforge.fallen_crusader)&(debuff.razorice.stack=5|!death_knight.runeforge.razorice));
	if cooldown[FR.FrostwyrmsFury].ready and
		not DeathKnight.db.frostFrostwyrmsFuryAsCooldown and
		talents[FR.Obliteration] and
		not buff[FR.PillarOfFrost].up and
		(buff[FR.UnholyStrength].up or not deathKnightRuneforgeFallenCrusader) and
		(debuff[FR.Razorice].count == 5 or not deathKnightRuneforgeRazorice)
	then
		return FR.FrostwyrmsFury;
	end

	-- raise_dead,if=buff.pillar_of_frost.up;
	if cooldown[COMMON.RaiseDead].ready and buff[FR.PillarOfFrost].up then
		return COMMON.RaiseDead;
	end

	-- sacrificial_pact,if=active_enemies>=2&(pet.ghoul.remains<gcd|target.time_to_die<gcd);
	if cooldown[COMMON.SacrificialPact].ready and
		runicPower >= 20 and
		targets >= 2 and
		ghoulActive and
		ghoulRemains < gcd
	then
		return COMMON.SacrificialPact;
	end

	-- death_and_decay,if=active_enemies>5;
	if cooldown[COMMON.DeathAndDecay].ready and
		runes >= 1 and
		(targets > 5)
	then
		return COMMON.DeathAndDecay;
	end
end

function DeathKnight:FrostObliteration()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets;
	local gcd = fd.gcd;
	local runicPower = fd.runicPower;
	local runicPowerMax = fd.runicPowerMax;
	local runicPowerDeficit = runicPowerMax - runicPower;
	local runes = fd.runes;
	local runeforge = fd.runeforge;
	local timeTo2Runes = fd.timeTo2Runes;

	-- remorseless_winter,if=active_enemies>=3&(talent.gathering_storm|runeforge.biting_cold);
	if cooldown[FR.RemorselessWinter].ready and
		runes >= 1 and
		targets >= 3 and
		(talents[FR.GatheringStorm] or runeforge[FR.BitingCold])
	then
		return FR.RemorselessWinter;
	end

	-- howling_blast,if=!dot.frost_fever.ticking&!buff.killing_machine.up;
	if runes >= 1 and not debuff[FR.FrostFever].up and not buff[FR.KillingMachineBuff].up then
		return FR.HowlingBlast;
	end

	-- frostscythe,if=buff.killing_machine.react&spell_targets.frostscythe>=2&(buff.deaths_due.stack=8|!death_and_decay.ticking);
	if talents[FR.Frostscythe] and
		runes >= 1 and
		buff[FR.KillingMachineBuff].up and targets >= 2 then
		return FR.Frostscythe;
	end

	-- obliterate,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice,if=buff.killing_machine.react|!buff.rime.up&spell_targets.howling_blast>=3;
	if runes >= 2 and (buff[FR.KillingMachineBuff].up or not buff[FR.Rime].up and targets >= 3) then
		return FR.Obliterate;
	end

	-- glacial_advance,if=spell_targets.glacial_advance>=2&(runic_power.deficit<10|rune.time_to_2>gcd)|(debuff.razorice.stack<5|debuff.razorice.remains<15);
	if talents[FR.GlacialAdvance] and
		cooldown[FR.GlacialAdvance].ready and
		runicPower >= 30 and
		(
			targets >= 2 and (runicPowerDeficit < 10 or timeTo2Runes > gcd) or
			(debuff[FR.Razorice].count < 5 or debuff[FR.Razorice].remains < 15)
		)
	then
		return FR.GlacialAdvance;
	end

	-- howling_blast,if=buff.rime.up&spell_targets.howling_blast>=2;
	if buff[FR.Rime].up and targets >= 2 then
		return FR.HowlingBlast;
	end

	-- glacial_advance,if=spell_targets.glacial_advance>=2;
	if talents[FR.GlacialAdvance] and cooldown[FR.GlacialAdvance].ready and runicPower >= 30 and (targets >= 2) then
		return FR.GlacialAdvance;
	end

	-- frost_strike,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice,if=!talent.avalanche&!buff.killing_machine.up|talent.avalanche&!buff.rime.up;
	if runicPower >= 25 and
		(
			not talents[FR.Avalanche] and not buff[FR.KillingMachineBuff].up or
			talents[FR.Avalanche] and not buff[FR.Rime].up
		)
	then
		return FR.FrostStrike;
	end

	-- howling_blast,if=buff.rime.up;
	if buff[FR.Rime].up then
		return FR.HowlingBlast;
	end

	-- obliterate,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice;
	if runes >= 2 then
		return FR.Obliterate;
	end
end

function DeathKnight:FrostObliterationPooling()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local targets = fd.targets;
	local runicPower = fd.runicPower;
	local runicPowerMax = fd.runicPowerMax;
	local runicPowerDeficit = runicPowerMax - runicPower;
	local runes = fd.runes;
	local runeforge = fd.runeforge;

	-- remorseless_winter,if=talent.gathering_storm|runeforge.biting_cold|active_enemies>=2;
	if cooldown[FR.RemorselessWinter].ready and
		runes >= 1 and
		(talents[FR.GatheringStorm] or runeforge[FR.BitingCold] or targets >= 2)
	then
		return FR.RemorselessWinter;
	end

	-- howling_blast,if=buff.rime.up;
	if buff[FR.Rime].up then
		return FR.HowlingBlast;
	end

	-- obliterate,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice,if=buff.killing_machine.react;
	if runes >= 2 and (buff[FR.KillingMachineBuff].up) then
		return FR.Obliterate;
	end

	-- glacial_advance,if=spell_targets.glacial_advance>=2&runic_power.deficit<60;
	if talents[FR.GlacialAdvance] and
		cooldown[FR.GlacialAdvance].ready and
		runicPower >= 30 and
		targets >= 2 and
		runicPowerDeficit < 60
	then
		return FR.GlacialAdvance;
	end

	-- frost_strike,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice,if=runic_power.deficit<70;
	if runicPower >= 25 and runicPowerDeficit < 70 then
		return FR.FrostStrike;
	end

	-- obliterate,target_if=max:(debuff.razorice.stack+1)%(debuff.razorice.remains+1)*death_knight.runeforge.razorice,if=rune>4;
	if runes > 4 then
		return FR.Obliterate;
	end

	-- frostscythe,if=active_enemies>=4&);
	if talents[FR.Frostscythe] and
		runes >= 1 and
		targets >= 4 then
		return FR.Frostscythe;
	end
end

function DeathKnight:FrostStandard()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local gcd = fd.gcd;
	local runicPower = fd.runicPower;
	local runicPowerMax = fd.runicPowerMax;
	local runicPowerDeficit = runicPowerMax - runicPower;
	local runes = fd.runes;
	local runeforge = fd.runeforge;
	local deathKnightRuneforgeRazorice = enchant[weaponRunes.Razorice];
	local timeTo4Runes = fd.timeTo4Runes;

	-- remorseless_winter,if=talent.gathering_storm|runeforge.biting_cold;
	if cooldown[FR.RemorselessWinter].ready and
		runes >= 1 and
		(talents[FR.GatheringStorm] or runeforge[FR.BitingCold])
	then
		return FR.RemorselessWinter;
	end

	-- glacial_advance,if=!death_knight.runeforge.razorice&(debuff.razorice.stack<5|debuff.razorice.remains<7);
	if talents[FR.GlacialAdvance] and
		cooldown[FR.GlacialAdvance].ready and
		runicPower >= 30 and
		not deathKnightRuneforgeRazorice and
		(debuff[FR.Razorice].count < 5 or debuff[FR.Razorice].remains < 7)
	then
		return FR.GlacialAdvance;
	end

	-- frost_strike,if=cooldown.remorseless_winter.remains<=2*gcd&talent.gathering_storm;
	if runicPower >= 25 and cooldown[FR.RemorselessWinter].remains <= 2 * gcd and talents[FR.GatheringStorm] then
		return FR.FrostStrike;
	end

	-- howling_blast,if=buff.rime.up;
	if buff[FR.Rime].up then
		return FR.HowlingBlast;
	end

	-- obliterate,if=!buff.frozen_pulse.up&talent.frozen_pulse|buff.killing_machine.react|death_and_decay.ticking|rune.time_to_4<=gcd;
	if runes >= 2 and (buff[FR.KillingMachineBuff].up or timeTo4Runes <= gcd) then
		return FR.Obliterate;
	end

	-- frost_strike,if=runic_power.deficit<(15+talent.runic_attenuation*3);
	if runicPower >= 25 and (runicPowerDeficit < (15 + (talents[FR.RunicAttenuation] and 1 or 0) * 3)) then
		return FR.FrostStrike;
	end

	-- obliterate,if=runic_power.deficit>(25+talent.runic_attenuation*3);
	if runes >= 2 and (runicPowerDeficit > (25 + (talents[FR.RunicAttenuation] and 1 or 0) * 3)) then
		return FR.Obliterate;
	end

	-- frost_strike;
	if runicPower >= 25 then
		return FR.FrostStrike;
	end

	-- horn_of_winter;
	if talents[FR.HornOfWinter] and cooldown[FR.HornOfWinter].ready then
		return FR.HornOfWinter;
	end
end
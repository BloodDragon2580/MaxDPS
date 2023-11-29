local _, addonTable = ...;

-- @type MaxDps;
if not MaxDps then return end;
local Demonhunter = addonTable.Demonhunter;
local MaxDps = MaxDps;

local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;

local itemID = GetInventoryItemID('player', INVSLOT_MAINHAND);

local mainHandSubClassID = itemID and  select(13, GetItemInfo(itemID));

local TwoHanderWepCheck = mainHandSubClassID and (mainHandSubClassID == 1 or mainHandSubClassID == 5 or mainHandSubClassID == 8 or mainHandSubClassID == 10);

local nextCdTime
local nextFireCdTime
local fD
local frailtyReady

local VG = {
	SigilOfFlame = 204596,
	ImmolationAura = 258920,
	FelDevastation = 212084,
	ElysianDecree = 390163,
	TheHunt = 370965,
	SoulCarver = 207407,
	FieryDemise = 389220,
	FieryBrand = 204021,
	Soulcrush = 389985,
	Frailty = 389958,
	Disrupt = 183752,
	InfernalStrike = 189110,
	DemonSpikes = 203720,
	StokeTheFlames = 393827,
	Demonic = 213410,
	Metamorphosis = 187827,
	SpiritBomb = 247454,
	Fracture = 263642,
	SoulCleave = 228477,
	FocusedCleave = 343207,
	BulkExtraction = 320341,
	Felblade = 232893,
	Shear = 203782,
	ThrowGlaive = 204157,
	FirstOfTheIllidari = 235893,
};
local A = {
};
function Demonhunter:Vengeance()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets and fd.targets or 1;

	-- variable,name=next_cd_time,value=cooldown.fel_devastation.remains;
	nextCdTime = cooldown[VG.FelDevastation].remains;

	-- variable,name=next_cd_time,op=min,value=cooldown.elysian_decree.remains,if=talent.elysian_decree;
	if talents[VG.ElysianDecree] then
		nextCdTime = cooldown[VG.ElysianDecree].remains;
	end

	-- variable,name=next_cd_time,op=min,value=cooldown.the_hunt.remains,if=talent.the_hunt;
	if talents[VG.TheHunt] then
		nextCdTime = cooldown[VG.TheHunt].remains;
	end

	-- variable,name=next_cd_time,op=min,value=cooldown.soul_carver.remains,if=talent.soul_carver;
	if talents[VG.SoulCarver] then
		nextCdTime = cooldown[VG.SoulCarver].remains;
	end

	-- variable,name=next_fire_cd_time,value=cooldown.fel_devastation.remains;
	nextFireCdTime = cooldown[VG.FelDevastation].remains;

	-- variable,name=next_fire_cd_time,op=min,value=cooldown.soul_carver.remains,if=talent.soul_carver;
	if talents[VG.SoulCarver] then
		nextFireCdTime = cooldown[VG.SoulCarver].remains;
	end

	-- variable,name=fd,value=talent.fiery_demise&dot.fiery_brand.ticking;
	fD = talents[VG.FieryDemise] and debuff[VG.FieryBrand].up;

	-- variable,name=frailty_ready,value=!talent.soulcrush|debuff.frailty.stack>=2;
	frailtyReady = not talents[VG.Soulcrush] or debuff[VG.Frailty].count >= 2;

	-- disrupt,if=target.debuff.casting.react;
	if cooldown[VG.Disrupt].ready and (select(9,UnitCastingInfo("target")) == false) then
		return VG.Disrupt;
	end

	-- infernal_strike,use_off_gcd=1;
	if cooldown[VG.InfernalStrike].ready then
		return VG.InfernalStrike;
	end

	-- demon_spikes,use_off_gcd=1,if=!buff.demon_spikes.up&!cooldown.pause_action.remains;
	if cooldown[VG.DemonSpikes].ready and (not buff[VG.DemonSpikes].up and not cooldown[VG.DemonSpikes].remains>=1) then
		return VG.DemonSpikes;
	end

	-- call_action_list,name=maintenance;
	local result = Demonhunter:VengeanceMaintenance();
	if result then
		return result;
	end

	-- run_action_list,name=single_target,if=active_enemies=1;
	if targets == 1 then
		return Demonhunter:VengeanceSingleTarget();
	end

	-- run_action_list,name=small_aoe,if=active_enemies>1&active_enemies<=5;
	if targets > 1 and targets <= 5 then
		return Demonhunter:VengeanceSmallAoe();
	end

	-- run_action_list,name=big_aoe,if=active_enemies>=6;
	if targets >= 6 then
		return Demonhunter:VengeanceBigAoe();
	end
end
function Demonhunter:VengeanceBigAoe()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local fury = UnitPower('player', Enum.PowerType.Fury);
	local furyMax = UnitPowerMax('player', Enum.PowerType.Fury);
	local furyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local furyRegen = select(2,GetPowerRegen());
	local furyRegenCombined = furyRegen + fury;
	local furyDeficit = UnitPowerMax('player', Enum.PowerType.Fury) - fury;
	local furyTimeToMax = furyMax - fury / furyRegen;

	-- fel_devastation,if=variable.frailty_ready&variable.fd&talent.stoke_the_flames&!(talent.demonic&buff.metamorphosis.up);
	if talents[VG.FelDevastation] and cooldown[VG.FelDevastation].ready and fury >= 50 and (frailtyReady and fD and talents[VG.StokeTheFlames] and not ( talents[VG.Demonic] and buff[VG.Metamorphosis].up )) then
		return VG.FelDevastation;
	end

	-- elysian_decree,if=variable.frailty_ready;
	if talents[VG.ElysianDecree] and cooldown[VG.ElysianDecree].ready and (frailtyReady) then
		return VG.ElysianDecree;
	end

	-- fel_devastation,if=variable.frailty_ready&(variable.fd|talent.stoke_the_flames)&!(talent.demonic&buff.metamorphosis.up);
	if talents[VG.FelDevastation] and cooldown[VG.FelDevastation].ready and fury >= 50 and (frailtyReady and ( fD or talents[VG.StokeTheFlames] ) and not ( talents[VG.Demonic] and buff[VG.Metamorphosis].up )) then
		return VG.FelDevastation;
	end

	-- the_hunt,if=variable.frailty_ready;
	if talents[VG.TheHunt] and cooldown[VG.TheHunt].ready and currentSpell ~= VG.TheHunt and (frailtyReady) then
		return VG.TheHunt;
	end

	-- fel_devastation,if=!(talent.demonic&buff.metamorphosis.up);
	if talents[VG.FelDevastation] and cooldown[VG.FelDevastation].ready and fury >= 50 and (not ( talents[VG.Demonic] and buff[VG.Metamorphosis].up )) then
		return VG.FelDevastation;
	end

	-- spirit_bomb,if=((variable.fd&soul_fragments>=4)|soul_fragments>=5);
	if talents[VG.SpiritBomb] and fury >= 40 and (( ( fD and soulFragments >= 4 ) or soulFragments >= 5 )) then
		return VG.SpiritBomb;
	end

	-- fracture,if=soul_fragments<=3&soul_fragments>=1;
	if talents[VG.Fracture] and cooldown[VG.Fracture].ready and (soulFragments <= 3 and soulFragments >= 1) then
		return VG.Fracture;
	end

	-- soul_carver,if=variable.fd&variable.frailty_ready&soul_fragments<=3;
	if talents[VG.SoulCarver] and cooldown[VG.SoulCarver].ready and (fD and frailtyReady and soulFragments <= 3) then
		return VG.SoulCarver;
	end

	-- spirit_bomb,if=((variable.fd&soul_fragments>=3)|soul_fragments>=4);
	if talents[VG.SpiritBomb] and fury >= 40 and (( ( fD and soulFragments >= 3 ) or soulFragments >= 4 )) then
		return VG.SpiritBomb;
	end

	-- soul_carver,if=soul_fragments<=3;
	if talents[VG.SoulCarver] and cooldown[VG.SoulCarver].ready and (soulFragments <= 3) then
		return VG.SoulCarver;
	end

	-- soul_cleave,if=talent.focused_cleave;
	if fury >= 30 and (talents[VG.FocusedCleave]) then
		return VG.SoulCleave;
	end

	-- spirit_bomb,if=((variable.fd&soul_fragments>=2)|soul_fragments>=3);
	if talents[VG.SpiritBomb] and fury >= 40 and (( ( fD and soulFragments >= 2 ) or soulFragments >= 3 )) then
		return VG.SpiritBomb;
	end

	-- soul_cleave;
	if fury >= 30 then
		return VG.SoulCleave;
	end

	-- fracture,if=soul_fragments<=3;
	if talents[VG.Fracture] and cooldown[VG.Fracture].ready and (soulFragments <= 3) then
		return VG.Fracture;
	end

	-- call_action_list,name=filler;
	local result = Demonhunter:VengeanceFiller();
	if result then
		return result;
	end
end

function Demonhunter:VengeanceFiller()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local talents = fd.talents;
	local fury = UnitPower('player', Enum.PowerType.Fury);
	local furyMax = UnitPowerMax('player', Enum.PowerType.Fury);
	local furyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local furyRegen = select(2,GetPowerRegen());
	local furyRegenCombined = furyRegen + fury;
	local furyDeficit = UnitPowerMax('player', Enum.PowerType.Fury) - fury;
	local furyTimeToMax = furyMax - fury / furyRegen;

	-- bulk_extraction;
	if talents[VG.BulkExtraction] and cooldown[VG.BulkExtraction].ready then
		return VG.BulkExtraction;
	end

	-- soul_cleave;
	if fury >= 30 then
		return VG.SoulCleave;
	end

	-- spirit_bomb;
	if talents[VG.SpiritBomb] and fury >= 40 then
		return VG.SpiritBomb;
	end

	-- felblade;
	if talents[VG.Felblade] and cooldown[VG.Felblade].ready then
		return VG.Felblade;
	end

	-- fracture;
	if talents[VG.Fracture] and cooldown[VG.Fracture].ready then
		return VG.Fracture;
	end

	-- shear;
	-- VG.Shear;

	-- throw_glaive;
	if cooldown[VG.ThrowGlaive].ready then
		return VG.ThrowGlaive;
	end
end

function Demonhunter:VengeanceMaintenance()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local timeShift = fd.timeShift;
	local gcdRemains = fd.gcdRemains;
	local timeToDie = fd.timeToDie;
	local fury = UnitPower('player', Enum.PowerType.Fury);
	local furyMax = UnitPowerMax('player', Enum.PowerType.Fury);
	local furyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local furyRegen = select(2,GetPowerRegen());
	local furyRegenCombined = furyRegen + fury;
	local furyDeficit = UnitPowerMax('player', Enum.PowerType.Fury) - fury;
	local furyTimeToMax = furyMax - fury / furyRegen;

	-- metamorphosis,if=talent.first_of_the_illidari&trinket.beacon_to_the_beyond.cooldown.remains<10|fight_remains<20;
	if cooldown[VG.Metamorphosis].ready and (talents[VG.FirstOfTheIllidari] and 10 or timeToDie < 20) then
		return VG.Metamorphosis;
	end

	-- call_action_list,name=trinkets;

	-- fiery_brand,if=charges>=2|(!ticking&((variable.next_fire_cd_time<7)|(variable.next_fire_cd_time>28)));
	if talents[VG.FieryBrand] and cooldown[VG.FieryBrand].ready and (cooldown[VG.FieryBrand].charges >= 2 or ( not debuff[VG.FieryBrand].up and ( ( nextFireCdTime < 7 ) or ( nextFireCdTime > 28 ) ) )) then
		return VG.FieryBrand;
	end

	-- spirit_bomb,if=soul_fragments>=5;
	if talents[VG.SpiritBomb] and fury >= 40 and (soulFragments >= 5) then
		return VG.SpiritBomb;
	end

	-- fracture,target_if=max:dot.fiery_brand.remains,if=dot.fiery_brand.ticking&buff.recrimination.up;
	if talents[VG.Fracture] and cooldown[VG.Fracture].ready and (debuff[VG.FieryBrand].up and buff[VG.Recrimination].up) then
		return VG.Fracture;
	end

	-- fracture,if=(full_recharge_time<=cast_time+gcd.remains);
	if talents[VG.Fracture] and cooldown[VG.Fracture].ready and (( cooldown[VG.Fracture].fullRecharge <= timeShift + gcdRemains )) then
		return VG.Fracture;
	end

	-- immolation_aura;
	if cooldown[VG.ImmolationAura].ready then
		return VG.ImmolationAura;
	end

	-- sigil_of_flame,if=dot.fiery_brand.ticking;
	if talents[VG.SigilOfFlame] and cooldown[VG.SigilOfFlame].ready and (debuff[VG.FieryBrand].up) then
		return VG.SigilOfFlame;
	end

	-- metamorphosis,if=talent.demonic&!buff.metamorphosis.up&!cooldown.fel_devastation.up;
	if cooldown[VG.Metamorphosis].ready and (talents[VG.Demonic] and not buff[VG.Metamorphosis].up and not cooldown[VG.FelDevastation].up) then
		return VG.Metamorphosis;
	end
end

function Demonhunter:VengeanceSingleTarget()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local fury = UnitPower('player', Enum.PowerType.Fury);
	local furyMax = UnitPowerMax('player', Enum.PowerType.Fury);
	local furyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local furyRegen = select(2,GetPowerRegen());
	local furyRegenCombined = furyRegen + fury;
	local furyDeficit = UnitPowerMax('player', Enum.PowerType.Fury) - fury;
	local furyTimeToMax = furyMax - fury / furyRegen;

	-- soul_carver,if=variable.fd&variable.frailty_ready&soul_fragments<=3;
	if talents[VG.SoulCarver] and cooldown[VG.SoulCarver].ready and (fD and frailtyReady and soulFragments <= 3) then
		return VG.SoulCarver;
	end

	-- the_hunt,if=variable.frailty_ready;
	if talents[VG.TheHunt] and cooldown[VG.TheHunt].ready and currentSpell ~= VG.TheHunt and (frailtyReady) then
		return VG.TheHunt;
	end

	-- soul_carver,if=variable.frailty_ready&soul_fragments<=3;
	if talents[VG.SoulCarver] and cooldown[VG.SoulCarver].ready and (frailtyReady and soulFragments <= 3) then
		return VG.SoulCarver;
	end

	-- fel_devastation,if=variable.frailty_ready&(variable.fd|talent.stoke_the_flames)&!(talent.demonic&buff.metamorphosis.up);
	if talents[VG.FelDevastation] and cooldown[VG.FelDevastation].ready and fury >= 50 and (frailtyReady and ( fD or talents[VG.StokeTheFlames] ) and not ( talents[VG.Demonic] and buff[VG.Metamorphosis].up )) then
		return VG.FelDevastation;
	end

	-- elysian_decree,if=variable.frailty_ready;
	if talents[VG.ElysianDecree] and cooldown[VG.ElysianDecree].ready and (frailtyReady) then
		return VG.ElysianDecree;
	end

	-- fracture,if=set_bonus.tier30_4pc&variable.fd&(soul_fragments<=3|(buff.metamorphosis.up&soul_fragments<=2));
	if talents[VG.Fracture] and cooldown[VG.Fracture].ready and (MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 4) and fD and ( soulFragments <= 3 or ( buff[VG.Metamorphosis].up and soulFragments <= 2 ) )) then
		return VG.Fracture;
	end

	-- fel_devastation,if=!(talent.demonic&buff.metamorphosis.up);
	if talents[VG.FelDevastation] and cooldown[VG.FelDevastation].ready and fury >= 50 and (not ( talents[VG.Demonic] and buff[VG.Metamorphosis].up )) then
		return VG.FelDevastation;
	end

	-- sigil_of_flame,if=fury<70;
	if talents[VG.SigilOfFlame] and cooldown[VG.SigilOfFlame].ready and (fury < 70) then
		return VG.SigilOfFlame;
	end

	-- spirit_bomb,if=((variable.fd&soul_fragments>=4)|soul_fragments>=5);
	if talents[VG.SpiritBomb] and fury >= 40 and (( ( fD and soulFragments >= 4 ) or soulFragments >= 5 )) then
		return VG.SpiritBomb;
	end

	-- fracture,if=set_bonus.tier30_4pc&variable.fd;
	if talents[VG.Fracture] and cooldown[VG.Fracture].ready and (MaxDps.tier[30] and MaxDps.tier[30].count and (MaxDps.tier[30].count == 4) and fD) then
		return VG.Fracture;
	end

	-- soul_cleave,if=talent.focused_cleave;
	if fury >= 30 and (talents[VG.FocusedCleave]) then
		return VG.SoulCleave;
	end

	-- spirit_bomb,if=((variable.fd&soul_fragments>=3)|soul_fragments>=4);
	if talents[VG.SpiritBomb] and fury >= 40 and (( ( fD and soulFragments >= 3 ) or soulFragments >= 4 )) then
		return VG.SpiritBomb;
	end

	-- soul_cleave;
	if fury >= 30 then
		return VG.SoulCleave;
	end

	-- fracture;
	if talents[VG.Fracture] and cooldown[VG.Fracture].ready then
		return VG.Fracture;
	end

	-- spirit_bomb,if=((variable.fd&soul_fragments>=2)|soul_fragments>=3);
	if talents[VG.SpiritBomb] and fury >= 40 and (( ( fD and soulFragments >= 2 ) or soulFragments >= 3 )) then
		return VG.SpiritBomb;
	end

	-- sigil_of_flame;
	if talents[VG.SigilOfFlame] and cooldown[VG.SigilOfFlame].ready then
		return VG.SigilOfFlame;
	end

	-- call_action_list,name=filler;
	local result = Demonhunter:VengeanceFiller();
	if result then
		return result;
	end
end

function Demonhunter:VengeanceSmallAoe()
	local fd = MaxDps.FrameData;
	local timeTo35 = fd.timeToDie;
	local timeTo20 = fd.timeToDie;
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local fury = UnitPower('player', Enum.PowerType.Fury);
	local furyMax = UnitPowerMax('player', Enum.PowerType.Fury);
	local furyPct = UnitPower('player')/UnitPowerMax('player') * 100;
	local furyRegen = select(2,GetPowerRegen());
	local furyRegenCombined = furyRegen + fury;
	local furyDeficit = UnitPowerMax('player', Enum.PowerType.Fury) - fury;
	local furyTimeToMax = furyMax - fury / furyRegen;

	-- elysian_decree,if=variable.frailty_ready;
	if talents[VG.ElysianDecree] and cooldown[VG.ElysianDecree].ready and (frailtyReady) then
		return VG.ElysianDecree;
	end

	-- fel_devastation,if=variable.frailty_ready&variable.fd&talent.stoke_the_flames&!(talent.demonic&buff.metamorphosis.up);
	if talents[VG.FelDevastation] and cooldown[VG.FelDevastation].ready and fury >= 50 and (frailtyReady and fD and talents[VG.StokeTheFlames] and not ( talents[VG.Demonic] and buff[VG.Metamorphosis].up )) then
		return VG.FelDevastation;
	end

	-- the_hunt,if=variable.frailty_ready;
	if talents[VG.TheHunt] and cooldown[VG.TheHunt].ready and currentSpell ~= VG.TheHunt and (frailtyReady) then
		return VG.TheHunt;
	end

	-- fel_devastation,if=variable.frailty_ready&(variable.fd|talent.stoke_the_flames)&!(talent.demonic&buff.metamorphosis.up);
	if talents[VG.FelDevastation] and cooldown[VG.FelDevastation].ready and fury >= 50 and (frailtyReady and ( fD or talents[VG.StokeTheFlames] ) and not ( talents[VG.Demonic] and buff[VG.Metamorphosis].up )) then
		return VG.FelDevastation;
	end

	-- spirit_bomb,if=((variable.fd&soul_fragments>=4)|soul_fragments>=5);
	if talents[VG.SpiritBomb] and fury >= 40 and (( ( fD and soulFragments >= 4 ) or soulFragments >= 5 )) then
		return VG.SpiritBomb;
	end

	-- soul_carver,if=variable.frailty_ready&variable.fd&soul_fragments<=3;
	if talents[VG.SoulCarver] and cooldown[VG.SoulCarver].ready and (frailtyReady and fD and soulFragments <= 3) then
		return VG.SoulCarver;
	end

	-- fel_devastation,if=!(talent.demonic&buff.metamorphosis.up);
	if talents[VG.FelDevastation] and cooldown[VG.FelDevastation].ready and fury >= 50 and (not ( talents[VG.Demonic] and buff[VG.Metamorphosis].up )) then
		return VG.FelDevastation;
	end

	-- fracture,if=soul_fragments<=3&soul_fragments>=1;
	if talents[VG.Fracture] and cooldown[VG.Fracture].ready and (soulFragments <= 3 and soulFragments >= 1) then
		return VG.Fracture;
	end

	-- sigil_of_flame;
	if talents[VG.SigilOfFlame] and cooldown[VG.SigilOfFlame].ready then
		return VG.SigilOfFlame;
	end

	-- soul_carver,if=variable.frailty_ready&soul_fragments<=3;
	if talents[VG.SoulCarver] and cooldown[VG.SoulCarver].ready and (frailtyReady and soulFragments <= 3) then
		return VG.SoulCarver;
	end

	-- spirit_bomb,if=((variable.fd&soul_fragments>=3)|soul_fragments>=4);
	if talents[VG.SpiritBomb] and fury >= 40 and (( ( fD and soulFragments >= 3 ) or soulFragments >= 4 )) then
		return VG.SpiritBomb;
	end

	-- soul_cleave,if=talent.focused_cleave;
	if fury >= 30 and (talents[VG.FocusedCleave]) then
		return VG.SoulCleave;
	end

	-- spirit_bomb,if=((variable.fd&soul_fragments>=2)|soul_fragments>=3);
	if talents[VG.SpiritBomb] and fury >= 40 and (( ( fD and soulFragments >= 2 ) or soulFragments >= 3 )) then
		return VG.SpiritBomb;
	end

	-- soul_cleave;
	if fury >= 30 then
		return VG.SoulCleave;
	end

	-- spirit_bomb,if=((variable.fd&soul_fragments>=1)|soul_fragments>=2);
	if talents[VG.SpiritBomb] and fury >= 40 and (( ( fD and soulFragments >= 1 ) or soulFragments >= 2 )) then
		return VG.SpiritBomb;
	end

	-- fracture;
	if talents[VG.Fracture] and cooldown[VG.Fracture].ready then
		return VG.Fracture;
	end

	-- call_action_list,name=filler;
	local result = Demonhunter:VengeanceFiller();
	if result then
		return result;
	end
end


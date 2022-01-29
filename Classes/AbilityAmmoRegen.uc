class AbilityAmmoRegen extends LoadAbility
	abstract;

static simulated function int Cost(RPGPlayerDataObject Data, int CurrentLevel)
{
	if (Data.AmmoMax < 50)
		return 0;
	else
		return Super.Cost(Data, CurrentLevel);
}

static simulated function RealModifyPawn(Pawn Other, int AbilityLevel, rpgstatsinv statsinv, skillinv inv)
{
	local ammoregeninv R;
	local float m;
	local rpgplayerdataobject data;

    data = statsinv.DataObject;
    if(data!=none)
        m = 1.0 + float(data.AmmoMax)/100.0;
    else m = 1.0;
	R = ammoregeninv(inv);
	R.RegenAmount = AbilityLevel;
	r.maxammo=m;
}

defaultproperties
{
     Index=5
     InventoryType=Class'mcgRPG1_9_9_1.AmmoRegenInv'
     AbilityName="Resupply"
     Description="Adds 1 ammo per level to each ammo type you own every 3 seconds. Does not give ammo to superweapons or the translocator. You must have a Max Ammo stat of at least 50 to purchase this ability. (Max Level: %maxlevel% , cost (per level): %costs% )"
     StartingCost=15
     CostAddPerLevel=5
     MaxLevel=10
}

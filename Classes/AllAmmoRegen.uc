//=============================================================================
// AllAmmoRegen.
//=============================================================================
class AllAmmoRegen extends LoadAbility abstract;

static simulated function int Cost(RPGPlayerDataObject Data, int CurrentLevel)
{
    local int x;

	for (x = 0; x < Data.Abilities.length; x++)
		if ( ( Data.Abilities[x] == class'abilityAmmoRegen' ) && (data.AbilityLevels[x]==10))
				return Super.Cost(Data, CurrentLevel);


	return 0;
}

static simulated function RealModifyPawn(Pawn Other, int AbilityLevel, rpgstatsinv statsinv, skillinv inv)
{
	local allammoregeninv R;
	local float m;
	local rpgplayerdataobject data;

    data = statsinv.DataObject;
    if(data!=none)
        m = 1.0 + float(data.AmmoMax)/100.0;
    else m = 1.0;
	R = allammoregeninv(inv);
	R.RegenAmount = AbilityLevel;
	r.maxammo=m;
}

defaultproperties
{
     Index=3
     InventoryType=Class'mcgRPG1_9_9_1.AllAmmoRegenInv'
     AbilityName="SuperResupply"
     Description="It gives ammo to superweapons. You must have a Max level resupply to purchase this ability. (Max Level: %maxlevel%, Cost (per level): %costs%.)"
     StartingCost=800
     MaxLevel=1
}

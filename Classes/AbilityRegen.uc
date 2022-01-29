//Regeneration ability
class AbilityRegen extends LoadAbility
	abstract;

static function int Cost(RPGPlayerDataObject Data, int CurrentLevel)
{
	if ( (Data.HealthBonus < 30 * (CurrentLevel + 1) ) && data.Defense < 200 )
		return 0;
	else
		return Super.Cost(Data, CurrentLevel);
}

static function RealModifyPawn(Pawn Other, int AbilityLevel, rpgstatsinv statsinv, skillinv inv)
{
	local regeninv R;
	R = regeninv(inv);
	R.RegenAmount = AbilityLevel;
}

defaultproperties
{
     Index=4
     InventoryType=Class'mcgRPG1_9_9_1.RegenInv'
     AbilityName="Regeneration"
     Description="Heals 1 health per second per level. Does not heal past starting health amount. You must have a Health Bonus stat equal to 30 times the ability level you wish to have or 200 Damage Reduction before you can purchase it. (Max Level: %maxlevel%, Cost (per level): %costs%. )"
     StartingCost=15
     CostAddPerLevel=5
     MaxLevel=10
}

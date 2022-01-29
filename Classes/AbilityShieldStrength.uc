class AbilityShieldStrength extends RPGAbility
	abstract;

static simulated function int Cost(RPGPlayerDataObject Data, int CurrentLevel)
{
	if (Data.HealthBonus < 100 && data.Defense < 250)
		return 0;
	else
		return Super.Cost(Data, CurrentLevel);
}

static function ModifyPawn(Pawn Other, int AbilityLevel, RPGStatsInv statsinv)
{
	if (xPawn(Other) != None)
		xPawn(Other).ShieldStrengthMax = xPawn(Other).default.ShieldStrengthMax + 50 * AbilityLevel;
}

defaultproperties
{
     AbilityName="Shields Up!"
     Description="Increases your maximum shield by 50 per level. You must have a Health Bonus stat of 100, or damage reduction 250 before you can purchase this ability. (Max Level: %maxlevel%, cost (per level) : %costs%)"
     StartingCost=20
     CostAddPerLevel=5
     MaxLevel=10
}

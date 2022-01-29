class AbilityReduceFallDamage extends RPGAbility
	abstract;

static function int Cost(RPGPlayerDataObject Data, int CurrentLevel)
{
	if (Data.HealthBonus < 50 && data.Defense<100)
		return 0;
	else
		return Super.Cost(Data, CurrentLevel);
}

static function ModifyPawn(Pawn Other, int AbilityLevel, RPGStatsInv statsinv)
{
	Other.MaxFallSpeed = Other.default.MaxFallSpeed * (1.0 + 0.25 * float(AbilityLevel));
}

defaultproperties
{
     AbilityName="Iron Legs"
     Description="Increases the distance you can safely fall by 25% per level and reduces fall damage for distances still beyond your capacity to handle. Your Health Bonus stat must be at least 50, or your damage reduction must be 100 to purchase this ability. (Max Level: %maxlevel%, cost (per level): %costs%.)"
     StartingCost=10
     CostAddPerLevel=5
     BotChance=6
     MaxLevel=4
}

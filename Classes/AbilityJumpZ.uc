class abilityJumpZ extends RPGAbility
	abstract;

static simulated function int Cost(RPGPlayerDataObject Data, int CurrentLevel)
{
	if (Data.Level < 10 * (CurrentLevel + 1))
		return 0;
	else
		return Super.Cost(Data, CurrentLevel);
}

static function ModifyPawn(Pawn Other, int AbilityLevel, RPGStatsInv statsinv)
{
	Other.JumpZ = Other.default.JumpZ * (1.0 + 0.1 * float(AbilityLevel));
}

defaultproperties
{
     AbilityName="Power Jump"
     Description="Increases your jumping height by 10% per level. The Speed adrenaline combo will stack with this effect. You must be a Level equal to ten times the ability level you wish to have before you can purchase it. (Max Level: %maxlevel%, cost (per level) %costs%.)"
     StartingCost=15
     CostAddPerLevel=5
     MaxLevel=10
}

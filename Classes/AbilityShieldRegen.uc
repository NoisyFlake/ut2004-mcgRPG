//shield regeneration ability
class AbilityShieldRegen extends LoadAbility
	abstract;

static function int Cost(RPGPlayerDataObject Data, int CurrentLevel)
{
	local int x;

	for (x = 0; x < Data.Abilities.length; x++)
	{
		if ( Data.Abilities[x] == class'abilityRegen' )
		{
            if( Data.AbilityLevels[x] > CurrentLevel || Data.AbilityLevels[x] >= Data.Abilities[x].default.MaxLevel)
		        return Super.Cost(Data, CurrentLevel);
            return 0;
        }
	}
	return 0;
}

static function RealModifyPawn(Pawn Other, int AbilityLevel, rpgstatsinv statsinv, skillinv inv)
{
	local shieldregeninv R;
	R = shieldregeninv(inv);
	R.RegenAmount = AbilityLevel;
}

defaultproperties
{
     Index=6
     InventoryType=Class'mcgRPG1_9_9_1.ShieldRegenInv'
     AbilityName="Shield Builder"
     Description="Raise your shield 1 per second per level to your maximum shield strength. You must have Regeneration skill equal to the ability level you wish to have before you can purchase it. (Max Level: %maxlevel%, Cost (per level): %costs%. )"
     StartingCost=15
     CostAddPerLevel=5
     MaxLevel=10
}

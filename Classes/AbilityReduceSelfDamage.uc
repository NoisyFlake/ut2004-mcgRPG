class AbilityReduceSelfDamage extends RPGAbility
	abstract;

static function int Cost(RPGPlayerDataObject Data, int CurrentLevel)
{
	if (Data.HealthBonus < 100 && Data.Defense < 50)
		return 0;
	else
		return Super.Cost(Data, CurrentLevel);
}

static function HandleDamage(out int Damage, Pawn Injured, Pawn Instigator, out vector Momentum, class<DamageType> DamageType, bool bOwnedByInstigator, int AbilityLevel, rpgstatsinv statsinv)
{
	if (Injured != Instigator || !bOwnedByInstigator || DamageType == class'Fell')
		return;

	Damage *= fmax(1.0 - 0.15 * float(AbilityLevel), 0.0 );
}

defaultproperties
{
     AbilityName="Cautiousness"
     Description="Reduces self damage by 15% per level. Your Health Bonus stat must be at least 100, or your Damage Reduction stat at least 50 to purchase this ability. (Max Level: %maxlevel% , cost (per level): %costs% )"
     StartingCost=15
     CostAddPerLevel=5
     MaxLevel=6
     bDefensive=True
}

class AbilityReduceMomentum extends RPGAbility
	abstract;

static simulated function int Cost(RPGPlayerDataObject Data, int CurrentLevel)
{
	if ( Data.Defense < 50)
		return 0;
	else
		return Super.Cost(Data, CurrentLevel);
}

static function HandleDamage(out int Damage, Pawn Injured, Pawn Instigator, out vector Momentum, class<DamageType> DamageType, bool bOwnedByInstigator, int AbilityLevel, rpgstatsinv statsinv)
{
	if (Injured == none || bOwnedByInstigator )
		return;

	Momentum *= fmax(0.0, 1.0 - 0.15 * float(AbilityLevel) );
}

defaultproperties
{
     AbilityName="Sturdiness"
     Description="Reduces momentum of damage by 15% per level. Your Damage Reduction stat must be at least 50 to purchase this ability. (Max Level: %maxlevel% , cost (per level): %costs% )"
     StartingCost=40
     CostAddPerLevel=5
     MaxLevel=6
     bDefensive=True
}

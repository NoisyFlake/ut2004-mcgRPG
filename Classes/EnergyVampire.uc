class energyvampire extends rpgability
 config(mcgRPG1991)
	abstract;


static simulated function int Cost(RPGPlayerDataObject Data, int CurrentLevel)
{
	if (Data.AdrenalineMax < 50 || Data.Attack < 150)
		return 0;
	else
		return Super.Cost(Data, CurrentLevel);
}

static function HandleDamage(out int Damage, Pawn Injured, Pawn Instigator, out vector Momentum, class<DamageType> DamageType, bool bOwnedByInstigator, int AbilityLevel, rpgstatsinv statsinv)
{
	local float AdrenalineBonus;

	if (Damage < 1 || !bOwnedByInstigator || DamageType == class'damtypeRetaliation' || Injured == Instigator || Instigator == None || Injured == None ||
        Instigator.Controller == None || Instigator.Controller.SameTeamAs(injured.Controller) )
		return;

	if (Damage > Injured.Health)
		AdrenalineBonus = Injured.Health;
	else
		AdrenalineBonus = Damage;
	AdrenalineBonus *= 0.01 * AbilityLevel;
    if(statsinv != none)
    {
        statsinv.adrenaline += adrenalinebonus;
        adrenalinebonus = float(int(statsinv.adrenaline) );
        statsinv.adrenaline -= adrenalinebonus;
    }
	Instigator.Controller.awardAdrenaline ( AdrenalineBonus );
}

defaultproperties
{
     AbilityName="Energy Leech"
     Description="Whenever you damage another player, you gain 1% of the damage as adrenaline. You must have 50 adrenaline bonus and 150 damage bonus to purchase this ability. Each level increases this by 1%. (Max Level: %maxlevel% , cost (per level): %costs% )"
     StartingCost=10
     CostAddPerLevel=10
     MaxLevel=10
}

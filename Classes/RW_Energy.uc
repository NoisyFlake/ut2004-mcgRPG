class rw_Energy extends rw_Damage
	CacheExempt;


static function bool AllowedFor(class<Weapon> Weapon, Pawn Other)
{
	local bool bAllowed;
    bAllowed = super.AllowedFor(weapon, other);
    if(!bAllowed)
        return false;

	if (other != none && Other.Controller != None && Other.Controller.bAdrenalineEnabled)
		return true;

	return false;
}

function AdjustTargetDamage(out int Damage, Actor Victim, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	local float AdrenalineBonus;

	if (Pawn(Victim) == None)
		return;

	if (Damage > Pawn(Victim).Health)
		AdrenalineBonus = Pawn(Victim).Health;
	else
		AdrenalineBonus = Damage;
	AdrenalineBonus *= 0.02 * Modifier;
    if(holderstatsinv != none)
    {
        holderstatsinv.adrenaline += adrenalinebonus;
        adrenalinebonus = float(int(holderstatsinv.adrenaline) );
        holderstatsinv.adrenaline -= adrenalinebonus;
    }
	Instigator.Controller.awardAdrenaline ( AdrenalineBonus );
}

defaultproperties
{
     ModifierOverlay=Shader'RPGShaders.LightningHit'
     MinModifier=1
     MaxModifier=3
     RPGWeaponInfo="Gives adrenaline equal to 2% of damage per modifier."
     AIRatingBonus=0.020000
     Postfix=" of Energy"
     sanitymax=50000
}

class rw_Poison extends rw_Damage
	CacheExempt;

function AdjustTargetDamage(out int Damage, Actor Victim, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	local poisoninv Inv;
	local Pawn P;

	if (DamageType == class'damtypePoison' || Damage <= 0)
		return;

	P = Pawn(Victim);
	if (P != None)
	{
		Inv = poisoninv(P.FindInventoryType(class'poisoninv') );
		if (Inv != None)
			Inv.LifeSpan += Rand(Damage / 10) + 1;
		else
		{
			Inv = spawn(class'poisoninv', P,,, rot(0,0,0) );
			Inv.Modifier = Modifier;
			Inv.GiveTo(P);
			Inv.LifeSpan = Rand(Damage / 10) + 1;
			inv.hitlocation = hitlocation;
		}
	}
}

defaultproperties
{
     ModifierOverlay=Shader'RPGShaders.LinkHit'
     MinModifier=1
     MaxModifier=4
     RPGWeaponInfo="Poisons the victim. Poison takes damage of twice as much modifier several times."
     AIRatingBonus=0.020000
     Prefix="Poisoned "
}

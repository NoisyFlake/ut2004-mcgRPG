class rw_NullEntropy extends rw_Damage
	CacheExempt
	config(mcgRPG1991);


static function bool AllowedFor(class<Weapon> Weapon, Pawn Other)
{
	local int x;
	local bool bAllowed;
    bAllowed = super.AllowedFor(weapon, other);
    if(!bAllowed)
        return false;

	for (x = 0; x < 2; x++)
		if( ( ( class<instantfire>(weapon.default.firemodeclass[x]) != none || class<projectilefire>(weapon.default.firemodeclass[x]) != none ||
            class<linkfire>(weapon.default.firemodeclass[x]) != none ) && Weapon.default.FireModeClass[x].default.FireRate <= 0.5 ) ||
            ( class<projectilefire>(Weapon.default.FireModeClass[x])!=none && class<projectilefire>(Weapon.default.FireModeClass[x]).default.projperfire > 1 ) ||
            class<painterfire>(weapon.default.firemodeclass[x]) != none )    //compatibility hack
			return false;

	return true;
}

static function float AdjustBotDesire(bot b)
{
    if(b.Enemy.Physics != PHYS_Karma && b.Enemy.GroundSpeed > 1.5 * b.Enemy.default.GroundSpeed)
        return fmin(b.Enemy.GroundSpeed / 5 * b.Enemy.default.GroundSpeed, 1.0);
    if(b.Enemy.Physics == PHYS_Karma && KarmaParams(b.Enemy.KParams) != none )
        return 0.5 + fmin(0.5, vsize(b.Enemy.Velocity) / 2500.0);
}

function NewAdjustTargetDamage(out int Damage, int OriginalDamage, Actor Victim, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local Pawn P;
	Local nullentropyInv Inv;

    AdjustTargetDamage(damage, victim, hitlocation, momentum, damagetype);

	if(Instigator == None)
		return;
	if(Victim != Instigator && Pawn(Victim) != None && (Pawn(Victim).GetTeam() == Instigator.GetTeam() && Instigator.GetTeam() != None) )
		return;

	P = Pawn(Victim);
	if(P == None || !class'rw_Freeze'.static.canTriggerPhysics(P))
		return;

	if(P.FindInventoryType(class'nullentropyInv') != None)
		return ;

	Inv = spawn(class'nullentropyInv', P,,, rot(0,0,0));
	if(Inv == None)
		return; //wow

	Inv.LifeSpan = Modifier;
	Inv.Modifier = Modifier;
	Inv.GiveTo(P);
	if(asturret(p) != none && p.FindInventoryType(class'physicsinv') == none)
	    spawn(class'physicsinv').giveto(p);

	Momentum.X = 0;
	Momentum.Y = 0;
	Momentum.Z = 0;
}

static function string magicname()
{
    return "Nullentropy";
}

defaultproperties
{
     ModifierOverlay=Shader'RPGShaders.MutantGlowShader'
     MinModifier=1
     MaxModifier=3
     RPGWeaponInfo="Takes 10% more damage per modifier, and stops the victim for 1 second per modifier."
     Prefix="Null Entropy "
     sanitymax=200
}

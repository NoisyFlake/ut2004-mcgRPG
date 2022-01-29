class rw_Freeze extends rw_Damage
	CacheExempt
	config(mcgRPG1991);

var() Sound FreezeSound;

static function bool AllowedFor(class<Weapon> Weapon, Pawn Other)
{
	local int x;
	local bool bAllowed;
    bAllowed = super.AllowedFor(weapon, other);
    if(!bAllowed)
        return false;

	for (x = 0; x < 2; x++)
		if( ( ( class<instantfire>(weapon.default.firemodeclass[x]) != none ||
            class<projectilefire>(weapon.default.firemodeclass[x]) != none ||
            class<linkfire>(weapon.default.firemodeclass[x]) != none ) &&
            Weapon.default.FireModeClass[x].default.FireRate <= 0.5 ) ||
            ( class<projectilefire>(Weapon.default.FireModeClass[x])!=none &&
            class<projectilefire>(Weapon.default.FireModeClass[x]).default.projperfire > 1 ) ||
            class<painterfire>(weapon.default.firemodeclass[x]) != none )    //compatibility hack
			return false;

	return true;
}

static function float AdjustBotDesire(bot b)
{
    if(b.Enemy == none)
        return 0;
    if(b.Enemy.Physics != PHYS_Karma && b.Enemy.GroundSpeed > b.Pawn.GroundSpeed)
        return fmin(b.Enemy.GroundSpeed / 5 * b.Pawn.GroundSpeed, 1.0);
}

function AdjustTargetDamage(out int Damage, Actor Victim, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	local freezeInv Inv;
	local Pawn P;
	Local Actor A;

	if(Victim != Instigator && Pawn(Victim) != None && (Pawn(Victim).GetTeam() == Instigator.GetTeam()))
		return;

    super.AdjustTargetDamage(damage, victim, hitlocation, momentum, damagetype);

	P = Pawn(Victim);
	if (P != None && canTriggerPhysics(P))
	{
		Inv = freezeInv(P.FindInventoryType(class'freezeInv'));
		//dont add to the time a pawn is already frozen. It just wouldn't be fair.
		if (Inv == None)
		{
			Inv = spawn(class'freezeInv', P,,, rot(0,0,0));
			Inv.Modifier = Modifier;
			Inv.LifeSpan = Modifier;
			Inv.GiveTo(P);
			if(Victim.isA('Pawn'))
			{
				A = P.spawn(class'icesmoke', P,, P.Location, P.Rotation);
				if (A != None)
				{
					A.RemoteRole = ROLE_SimulatedProxy;
					A.PlaySound(FreezeSound,,2.5*Victim.TransientSoundVolume,,Victim.TransientSoundRadius);
				}
			}
		}
	}
}

static function bool canTriggerPhysics(Pawn victim)
{
	return(victim == None || Victim.PlayerReplicationInfo == None || Victim.PlayerReplicationInfo.HasFlag == None);
}

defaultproperties
{
     FreezeSound=Sound'Slaughtersounds.Machinery.Heavy_End'
     ModifierOverlay=Shader'RPGShaders.PulseGreyShader'
     MinModifier=1
     MaxModifier=3
     RPGWeaponInfo="Takes 10% more damage per modifier, and slow down the victim with 1 + half of modifier for 1 second per modifier."
     AIRatingBonus=0.025000
     Prefix="Freezing "
     sanitymax=300
}

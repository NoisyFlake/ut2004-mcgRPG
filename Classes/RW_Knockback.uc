class rw_Knockback extends rw_Damage
	CacheExempt
	config(mcgRPG1991);

var() Sound KnockbackSound;

function NewAdjustTargetDamage(out int Damage, int OriginalDamage, Actor Victim, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local Pawn P;
	Local knockbackInv Inv;
	Local Vector newLocation;

	super.NewAdjustTargetDamage(Damage, OriginalDamage, Victim, HitLocation, Momentum, DamageType);

	if(Instigator == None)
		return;
	if(Victim != Instigator && Pawn(Victim) != None && (Pawn(Victim).GetTeam() == Instigator.GetTeam() && Instigator.GetTeam() != None) )
		return;

	P = Pawn(Victim);
	if(P == None || !class'rw_Freeze'.static.canTriggerPhysics(P))
		return;

	if(P.FindInventoryType(class'knockbackInv') != None)
		return ;

	Inv = spawn(class'knockbackInv', P,,, rot(0,0,0));
	if(Inv == None)
		return; //wow

	Inv.LifeSpan = (MaxModifier + 1) - Modifier;
	Inv.Modifier = Modifier;
	Inv.GiveTo(P);
	if(asturret(p) != none && p.FindInventoryType(class'physicsinv') == none)
	    spawn(class'physicsinv').giveto(p);

	// if they're not walking, falling, or hovering,
	// the momentum won't affect them correctly, so make them hover.
	// this effect will end when the knockbackInv expires.
	if(P.Physics != PHYS_Walking && P.Physics != PHYS_Falling && P.Physics != PHYS_Hovering)
		P.SetPhysics(PHYS_Hovering);

	//I check the x,y, and z to see if this projectile has no momentum (some weapons have none)
	if( vsize(Momentum) < 200 )
	{
		if(Instigator == Victim)
	 		Momentum = Instigator.Location - HitLocation;
		else
	 		Momentum = Victim.Location - Instigator.Location ;
		Momentum = Normal(Momentum);
		Momentum *= 200;
		if(vehicle(victim)!=none && onsweaponpawn(victim)==none )
		    momentum *= 100;

		// if they're walking, I need to bump them up
		// in the air a bit or they won't be knocked back
		// on no momentum weapons.
		if(P.Physics == PHYS_Walking)
		{
			newLocation = P.Location;
			newLocation.z += 10;
			P.SetLocation(newLocation);
		}
	}

	Momentum *= Max(2.0, Max(Modifier * 0.5, Damage * 0.1)); //kawham!

	P.SetOverlayMaterial(ModifierOverlay, 1.0, false);
	if(PlayerController(P.Controller) != None)
	    PlayerController(P.Controller).ReceiveLocalizedMessage(class'knockbackConditionMessage', 0);
	P.PlaySound(KnockbackSound,,1.5 * Victim.TransientSoundVolume,,Victim.TransientSoundRadius);
}

defaultproperties
{
     KnockbackSound=Sound'WeaponSounds.Misc.ballgun_launch'
     ModifierOverlay=Shader'RPGShaders.PulseRedShader'
     MinModifier=2
     MaxModifier=4
     RPGWeaponInfo="Takes 10% more damage per modifier, and push the victim."
     Postfix=" of Knockback"
     sanitymax=20000
}

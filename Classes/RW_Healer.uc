class rw_Healer extends rw_Damage
	CacheExempt;


static function bool AllowedFor(class<Weapon> Weapon, Pawn Other)
{
	local int x;
	local class<ProjectileFire> ProjFire;
	local bool bAllowed;
    bAllowed = super.AllowedFor(weapon, other);
    if(!bAllowed)
        return false;

	// if it's a team game, always allowed (no matter what it is player can use it to heal teammates)
	if (other != none && other.PlayerReplicationInfo != none && !Other.PlayerReplicationInfo.bNoTeam)   //client-friendly version:)
		return true;
	else
	{
		//otherwise only allowed on splash damage weapons
		for (x = 0; x < NUM_FIRE_MODES; x++)
			if (!ClassIsChildOf(Weapon.default.FireModeClass[x], class'InstantFire'))
			{
				ProjFire = class<ProjectileFire>(Weapon.default.FireModeClass[x]);
				if (Weapon.default.FireModeClass[x] == class'shieldfire' ||
                    (ProjFire != None && ProjFire.default.ProjectileClass != None && ProjFire.default.ProjectileClass.default.DamageRadius > 0) )
				{
					return true;
				}
			}
	}
	return false;
}

function NewAdjustTargetDamage(out int Damage, int OriginalDamage, Actor Victim, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local Pawn P;
	local int BestDamage,hp;
	local rpgstatsinv inv;

	BestDamage = Max(Damage, OriginalDamage);
	if (BestDamage > 0)
	{
		P = Pawn(Victim);
		if (Instigator != None && P != None && ( P == Instigator || (P.GetTeam() == Instigator.GetTeam() && Instigator.GetTeam() != None) ) )
		{
            if( PlayerController(P.Controller) != None )
		        PlayerController(P.Controller).ReceiveLocalizedMessage(class'healedconditionmessage', 0, Instigator.PlayerReplicationInfo);
            hp = p.Health;
			P.GiveHealth(Max(1, BestDamage * (0.05 * Modifier)), P.HealthMax + 50);
			P.SetOverlayMaterial(ModifierOverlay, 1.0, false);
			Damage = 0;
			if(vehicle(p) != none)
			    inv = rpgstatsinv(vehicle(p).Driver.FindInventoryType(class'rpgstatsinv') );
            else inv = rpgstatsinv(p.FindInventoryType(class'rpgstatsinv') );
			if(holderstatsinv != none && RPGMut != none && RPGMut.bEXPForHealing && p.Health > hp && p != instigator && inv != none && !inv.blastdamageteam )
			{
			    if(holderstatsinv.DataObject != none)
			        RPGMut.rpgrulz.ShareExperience( holderstatsinv,float(p.health - hp) / 100.0,, Instigator);
			}
		}
	}
	Super.NewAdjustTargetDamage(Damage, OriginalDamage, Victim, HitLocation, Momentum, DamageType);
}

defaultproperties
{
     ModifierOverlay=Shader'RPGShaders.PulseBlueShader'
     MinModifier=1
     MaxModifier=3
     RPGWeaponInfo="Heals teammates with 5% of damage per modifier."
     AIRatingBonus=0.020000
     Prefix="Healing "
}

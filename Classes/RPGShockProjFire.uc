//Hack fix for Shock Rifle so bots will recognize that they can do combos with a RPGWeapon modifying a shock rifle
class RPGShockProjFire extends ShockProjFire;

function projectile SpawnProjectile(Vector Start, Rotator Dir)
{
    local Projectile p;
    p = Super(ProjectileFire).SpawnProjectile(Start,Dir);
	if ( (ShockRifle(Weapon) != None) && (p != None) )
		ShockRifle(Weapon).SetComboTarget(ShockProjectile(P));
	return p;
}

defaultproperties
{
     ProjectileClass=Class'mcgRPG1_9_9_1.RPGShockProjectile'
}

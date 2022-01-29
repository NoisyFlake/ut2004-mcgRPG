class RPGTurretFire extends FM_BallTurret_Fire;

function projectile SpawnProjectile(Vector Start, Rotator Dir)
{
    local Projectile p;

    if(Instigator.GetTeamNum() > 1)
	    p = Weapon.Spawn(ProjectileClass, Instigator, , Start, Dir);
	else
	    p = Weapon.Spawn(TeamProjectileClasses[Instigator.GetTeamNum()], Instigator, , Start, Dir);
    if ( p == None )
        return None;

    p.Damage *= DamageAtten;
    return p;
}

defaultproperties
{
     ProjectileClass=Class'mcgRPG1_9_9_1.PROJ_TurretSkaarjPlasma_Green'
}

//hack to update projectile speed since neither Speed nor MaxSpeed is a replicated variable
//Used by rw_Force
class projectilespeedchanger extends Actor;

var() int Modifier;
var() Projectile ModifiedProjectile;

replication
{
	reliable if (bNetInitial && Role == ROLE_Authority)
		Modifier, ModifiedProjectile;
}

simulated function PostNetBeginPlay()
{
	if (Level.NetMode == NM_Client)
		SetTimer(10, false);
}

simulated function Tick(float deltaTime)
{
	if (Role == ROLE_Authority)
	{
		if (ModifiedProjectile == None)
			Destroy();
		return;
	}
	else if (ModifiedProjectile == None)
	{
		//bNetTemporary projectiles don't always get hooked up, so find it
		if (Modifier == 0)
			return;
		foreach CollidingActors(class'Projectile', ModifiedProjectile, 200)
			if (ModifiedProjectile.MaxSpeed == ModifiedProjectile.default.MaxSpeed)
				break;
		if (ModifiedProjectile == None)
			return;
	}
	ModifiedProjectile.Speed *= 1.0 + 0.2 * Modifier;
	ModifiedProjectile.MaxSpeed *= 1.0 + 0.2 * Modifier;
	Destroy();
}

simulated function Timer()
{
	Destroy();
}

defaultproperties
{
     bHidden=True
     bNetTemporary=True
     RemoteRole=ROLE_SimulatedProxy
     bGameRelevant=True
}

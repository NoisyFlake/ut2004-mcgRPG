class FixedRocketExplosion extends RocketExplosion;                      //effect spawned by the server

simulated function PostBeginPlay()
{
	local PlayerController PC;
    if(level.NetMode==nm_dedicatedserver)
        return;
	PC = Level.GetLocalPlayerController();
	if ( (PC.ViewTarget == None) || (VSize(PC.ViewTarget.Location - Location) > 5000) )
	{
		LightType = LT_None;
		bDynamicLight = false;
	}
	else
	{
		Spawn(class'RocketSmokeRing');
		if ( Level.bDropDetail )
			LightRadius = 7;
	}
}

defaultproperties
{
     RemoteRole=ROLE_DumbProxy
}

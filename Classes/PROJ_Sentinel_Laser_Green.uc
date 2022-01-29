class PROJ_Sentinel_Laser_Green extends PROJ_Sentinel_Laser;


simulated function SetupProjectile()
{
	super.SetupProjectile();

	if ( Laser != None )
		SetGreenColor();
}

simulated function SpawnExplodeFX(vector HitLocation, vector HitNormal)
{
	local	FX_PlasmaImpact			FX_Impact;

    if ( EffectIsRelevant(Location, false) )
	{
		FX_Impact = Spawn(class'FX_PlasmaImpact',,, HitLocation + HitNormal * 2, rotator(HitNormal));
		FX_Impact.SetGreenColor();
	}
}

simulated function SetGreenColor()
{
	Laser.Emitters[0].ColorScale[0].Color = class'Canvas'.static.MakeColor(0, 200, 80);
	Laser.Emitters[0].ColorScale[1].Color = Laser.Emitters[0].ColorScale[2].Color;
	Laser.Emitters[1].ColorScale[0].Color = Laser.Emitters[0].ColorScale[2].Color;
	Laser.Emitters[1].ColorScale[1].Color = Laser.Emitters[0].ColorScale[2].Color;
}

defaultproperties
{
}

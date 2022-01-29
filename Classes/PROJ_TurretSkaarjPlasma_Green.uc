class PROJ_TurretSkaarjPlasma_Green extends PROJ_TurretSkaarjPlasma;


simulated function SetupProjectile()
{
	super.SetupProjectile();
	if(FX_SpaceFighter_SkaarjPlasma(FX) != none)
	    SetGreenColor();
}

simulated function SpawnExplodeFX(vector HitLocation, vector HitNormal)
{
	super.SpawnExplodeFX(HitLocation, HitNormal);

	if ( FX_Impact != None )
		FX_Impact.SetGreenColor();
}

simulated function SetGreenColor()
{
	fx.Emitters[0].ColorScale[0].Color = class'Canvas'.static.MakeColor(0, 255, 64);
	fx.Emitters[0].ColorScale[1].Color = class'Canvas'.static.MakeColor(0, 255, 64);

	fx.Emitters[1].ColorScale[0].Color = class'Canvas'.static.MakeColor(0,255, 128);
	fx.Emitters[1].ColorScale[1].Color = class'Canvas'.static.MakeColor(0, 255, 64);

	fx.Emitters[2].ColorScale[0].Color = class'Canvas'.static.MakeColor(0, 200, 64);
	fx.Emitters[2].ColorScale[1].Color = class'Canvas'.static.MakeColor(0, 200, 64);
}

defaultproperties
{
}

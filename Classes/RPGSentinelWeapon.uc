class RPGSentinelWeapon extends Weapon_Sentinel
    config(user)
	CacheExempt;


simulated function IncrementFlashCount(int Mode)
{
    super.IncrementFlashCount(mode);
    if(instigator.GetTeamNum() > 1 && wa_sentinel(thirdpersonactor) != none )
    {
        if( wa_sentinel(thirdpersonactor).MuzFlash != none)
            setgreencolor(wa_sentinel(thirdpersonactor).MuzFlash);
    }
}

simulated function SetGreenColor(FX_SpaceFighter_3rdpMuzzle fx)
{
	fx.Emitters[0].ColorScale[0].Color = class'Canvas'.static.MakeColor(0, 200, 48);
}

defaultproperties
{
     FireModeClass(0)=Class'mcgRPG1_9_9_1.RPGSentinelFire'
     FireModeClass(1)=Class'mcgRPG1_9_9_1.RPGSentinelFire'
}

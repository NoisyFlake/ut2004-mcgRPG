class RPGTurretWeapon extends Weapon_Turret
    config(user)
	CacheExempt;


simulated function IncrementFlashCount(int Mode)
{
    local int i;
    super.IncrementFlashCount(mode);
    if(instigator.GetTeamNum() > 1 && wa_turret(thirdpersonactor) != none )
    {
        for(i = 0; i < 2; i++)
            if( wa_turret(thirdpersonactor).MuzFlash[i] != none)
                setgreencolor(wa_turret(thirdpersonactor).MuzFlash[i]);
    }
}

simulated function SetGreenColor(FX_SpaceFighter_3rdpMuzzle fx)
{
	fx.Emitters[0].ColorScale[0].Color = class'Canvas'.static.MakeColor(0, 200, 48);
}

defaultproperties
{
     FireModeClass(0)=Class'mcgRPG1_9_9_1.RPGTurretFire'
}

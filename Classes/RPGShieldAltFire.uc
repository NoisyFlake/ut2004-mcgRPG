class RPGShieldAltFire extends shieldaltfire;

var() rpgstatsinv statsinv;
var() bool bset;
var() shieldammo ammo;

function postnetbeginplay()
{
    settimer(0.1,false);
}

function Timer()
{
    if(!bset)
    {
        statsinv=rpgstatsinv(instigator.FindInventoryType(class'rpgstatsinv') );
        bset=true;
        ammo=shieldammo(instigator.FindInventoryType(class'shieldammo') );
        if(statsinv!=none && ammoclass.default.charge == 0  )
            weapon.AmmoCharge[0] = weapon.MaxAmmo(1) * ( 1.0 + float(statsinv.Data.AmmoMax) / 100);
        else
            weapon.AmmoCharge[0] = weapon.MaxAmmo(1);
        weapon.NetUpdateTime = Level.TimeSeconds - 1;
        return;
    }
    if( ammoclass.default.charge > 0 )
    {
        super.Timer();
        return;
    }
    if (!bIsFiring)
    {
		RampTime = 0;
        if ( !Weapon.AmmoMaxed(1)  )
            weapon.AddAmmo(1,1);
        else if( (  statsinv!=none && weapon.AmmoAmount(1) < weapon.MaxAmmo(1) * ( 1.0 + float(statsinv.Data.AmmoMax) / 100) ) )
            AddAmmo(1);
        else
            SetTimer(0, false);
    }
    else
    {
        if ( !Weapon.ConsumeAmmo(1,1) )
        {
            if (Weapon.ClientState == WS_ReadyToFire)
                Weapon.PlayIdle();
            StopFiring();
        }
        else
			RampTime += AmmoRegenTime;
    }

	SetBrightness(false);
}

function AddAmmo(int AmmoToAdd)
{
	if ( weapon.bNoAmmoInstances )
	{
		if ( Level.GRI.WeaponBerserk > 1.0 )
			weapon.AmmoCharge[0] = weapon.MaxAmmo(1)*( 1.0 + float(statsinv.Data.AmmoMax) / 100);
		else
			weapon.AmmoCharge[0] = Min(weapon.MaxAmmo(1)*( 1.0 + float(statsinv.Data.AmmoMax) / 100),weapon.AmmoCharge[0] + 1);
		weapon.NetUpdateTime = Level.TimeSeconds - 1;
		return;
	}
    if (Ammo != None)
		Ammo.AddAmmo(1);
}

defaultproperties
{
}

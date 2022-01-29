class RPGLinkAltFire extends LinkAltFire;

function ModeDoFire()
{
    local bool bRPGlink;
    if (!AllowFire())
        return;

    bRPGlink = ( instigator != none && rpgweapon(instigator.Weapon) != none && LinkGun(weapon) != none && rpgweapon(instigator.Weapon).modifiedweapon == LinkGun(weapon) );

    if (MaxHoldTime > 0.0)
        HoldTime = FMin(HoldTime, MaxHoldTime);

    // server
    if (Weapon.Role == ROLE_Authority)
    {
        if( bRPGlink )
            instigator.Weapon.ConsumeAmmo(ThisModeNum, AmmoPerFire);
        else
            weapon.ConsumeAmmo(ThisModeNum, AmmoPerFire);
        DoFireEffect();
		HoldTime = 0;	// if bot decides to stop firing, HoldTime must be reset first
        if ( (Instigator == None) || (Instigator.Controller == None) )
			return;

        if ( AIController(Instigator.Controller) != None )
            AIController(Instigator.Controller).WeaponFireAgain(BotRefireRate, true);

        Instigator.DeactivateSpawnProtection();
    }

    // client
    if (Instigator.IsLocallyControlled())
    {
        ShakeView();
        PlayFiring();
        FlashMuzzleFlash();
        StartMuzzleSmoke();
    }
    else // server
    {
        ServerPlayFiring();
    }
    if(bRPGlink)
        instigator.Weapon.IncrementFlashCount(ThisModeNum);
    else
        Weapon.IncrementFlashCount(ThisModeNum);

    // set the next firing time. must be careful here so client and server do not get out of sync
    if (bFireOnRelease)
    {
        if (bIsFiring)
            NextFireTime += MaxHoldTime + FireRate;
        else
            NextFireTime = Level.TimeSeconds + FireRate;
    }
    else
    {
        NextFireTime += FireRate;
        NextFireTime = FMax(NextFireTime, Level.TimeSeconds);
    }

    Load = AmmoPerFire;
    HoldTime = 0;

    if (Instigator.PendingWeapon != Weapon && Instigator.PendingWeapon != None)
    {
        bIsFiring = false;
        Weapon.PutDown();
    }
}

defaultproperties
{
}

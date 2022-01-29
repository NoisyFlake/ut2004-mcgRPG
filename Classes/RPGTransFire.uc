class RPGTransFire extends TransFire;

var() class<transbeacon> beaconclass[2];


function projectile SpawnProjectile(Vector Start, Rotator Dir)
{
    local TransBeacon TransBeacon;

    if (TransLauncher(Weapon).TransBeacon == None)
    {
		if ( Instigator == None || (Instigator.GetTeamNum() != 1 && Instigator.GetTeamNum() != 0) )
			TransBeacon = TransBeacon(Weapon.Spawn(ProjectileClass,,, Start, Dir) );
		else
			TransBeacon = Weapon.Spawn(beaconclass[Instigator.GetTeamNum()],,, Start, Dir);
        TransLauncher(Weapon).TransBeacon = TransBeacon;
        Weapon.PlaySound(TransFireSound,SLOT_Interact,,,,,false);
    }
    else
    {
        TransLauncher(Weapon).ViewPlayer();
        if ( TransLauncher(Weapon).TransBeacon.Disrupted() )
        {
			if( (Instigator != None) && (PlayerController(Instigator.Controller) != None) )
				PlayerController(Instigator.Controller).ClientPlaySound(Sound'WeaponSounds.BSeekLost1');
		}
		else
		{
			TransLauncher(Weapon).TransBeacon.Destroy();
			TransLauncher(Weapon).TransBeacon = None;
			Weapon.PlaySound(RecallFireSound,SLOT_Interact,,,,,false);
		}
    }
    return TransBeacon;
}

defaultproperties
{
     beaconclass(0)=Class'mcgRPG1_9_9_1.RPGRedBeacon'
     beaconclass(1)=Class'mcgRPG1_9_9_1.RPGBlueBeacon'
     ProjectileClass=Class'mcgRPG1_9_9_1.RPGTransBeacon'
}

class ProjSpeedTool extends tool;

var() float ticktime;

function tick(float dt)
{
    checkprojectile();
    ticktime = level.timeseconds;
}

function checkprojectile()
{
	local Projectile P;
	local projectilespeedchanger C;
    local rw_force myweapon;
    local int i;
    local bool found;

    if(instigator == none )
    {
        destroy();
        return;
    }
    if(rw_force(instigator.weapon) == none)
        return;
    myweapon = rw_force(instigator.weapon);

	if ( WeaponAttachment(myweapon.ThirdPersonActor) == None || myweapon.LastFlashCount != WeaponAttachment(myweapon.ThirdPersonActor).FlashCount )
	{
		foreach Instigator.CollidingActors(class'Projectile', P, 200.0)
		{
			if (P.Instigator == Instigator )
			{
			    for(i = 0; i < p.Attached.length; i++)
			        if(projectilespeedchanger(p.Attached[i]) != none)
			        {
			            found = true;
			            i = p.Attached.length;
                    }
                if(found)
                {
                    found = false;
                    continue;
                }
				P.Speed *= 1.0 + 0.2 * myweapon.Modifier;
				P.MaxSpeed *= 1.0 + 0.2 * myweapon.Modifier;
				P.Velocity *= 1.0 + 0.2 * myweapon.Modifier;
				C = Instigator.spawn(class'projectilespeedchanger',,,P.Location, P.Rotation);
				if (C != None)
				{
				    C.SetBase(P);
				    if (Level.NetMode != NM_Standalone)
				    {
						C.Modifier = myweapon.Modifier;
						C.ModifiedProjectile = P;
						if (P.AmbientSound != None)
						{
							C.AmbientSound = P.AmbientSound;
							C.SoundRadius = P.SoundRadius;
						}
						else
							C.bAlwaysRelevant = true;
					}
				}
			}
		}
		if (WeaponAttachment(myweapon.ThirdPersonActor) != None)
			myweapon.LastFlashCount = WeaponAttachment(myweapon.ThirdPersonActor).FlashCount;
	}
}

defaultproperties
{
}

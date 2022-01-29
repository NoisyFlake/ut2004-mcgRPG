class physicsinv extends inventory;

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	if(Other == None)
	{
		destroy();
		return;
	}
	Super.GiveTo(Other);
	enable('tick');
}

function tick(float d)
{
    if(asturret(Instigator) != none )
    {
        if(Instigator.Base == asturret(Instigator).TurretSwivel || Instigator.Base == asturret(Instigator).TurretBase)
            instigator.SetBase(none);
    }
    else if(!bpendingdelete)
        destroy();
}

defaultproperties
{
     RemoteRole=ROLE_None
}

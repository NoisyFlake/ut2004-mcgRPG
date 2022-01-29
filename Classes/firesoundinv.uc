class firesoundinv extends inventory;

var() controller myowner;

function postnetbeginplay()
{
    if(controller(owner) != none)
    {
        myowner = controller(owner);
        enable('tick');
    }
    else destroy();
}

function tick(float dt)
{
	local WeaponFire FireMode[2];

    if(myowner == none || myowner.bPendingDelete)
    {
        destroy();
        return;
    }

    if(myowner.Pawn != none && !myowner.Pawn.bPendingDelete && myowner.Pawn.Weapon != None)
    {
        FireMode[0] = myowner.Pawn.Weapon.GetFireMode(0);
        FireMode[1] = myowner.Pawn.Weapon.GetFireMode(1);
        if(firemode[0] != none && FireMode[0].FireAnimRate != FireMode[0].default.FireAnimRate)
            FireMode[0].FireAnimRate = FireMode[0].default.FireAnimRate;
        if(firemode[1] != none && FireMode[1].FireAnimRate != FireMode[1].default.FireAnimRate)
            FireMode[1].FireAnimRate = FireMode[1].default.FireAnimRate;
   }
}

function destroyed()
{
}

function AttachToPawn(Pawn P)
{
}

exec function updaterelative(int pitch, int yaw, int roll)
{
}

function DetachFromPawn(Pawn P)
{
}

simulated function RenderOverlays( canvas Canvas )
{
}

function DropFrom(vector StartLocation)
{
}

defaultproperties
{
     RemoteRole=ROLE_None
     CollisionRadius=0.000000
     CollisionHeight=0.000000
     bBlockZeroExtentTraces=False
     bBlockNonZeroExtentTraces=False
}

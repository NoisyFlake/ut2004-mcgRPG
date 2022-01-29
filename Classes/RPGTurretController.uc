class rpgturretcontroller extends assentinelcontroller;

var() turretmarker mymarker;

function tick(float d)
{
    local pawn p;
    local controller c;
    if(pawn == none || pawn.bPendingDelete)
    {
        destroy();
        return;
    }
    for(c = level.ControllerList; c != none; c = c.nextController)
    {
        p = c.Pawn;
        if( !c.bIsPlayer && p != none && p != pawn && ( vsize(p.Location - pawn.Location) < pawn.sightradius ) && p.Health > 0 &&
            !sameteamas(c) && cansee(p) )
        {
            SeePlayer(p);
            break;
        }
    }
}

auto state Searching
{
	function ScanRotation()
	{
		local Rotator OldDesired;

		if ( ASTurret_LinkTurret(Pawn) == None )
		{
			Super(TurretController).ScanRotation();
			return;
		}

		OldDesired = DesiredRotation;
		DesiredRotation = ASTurret_LinkTurret(Pawn).OriginalRotation;
		DesiredRotation.Yaw = DesiredRotation.Yaw + 8192;
		if ( (DesiredRotation.Yaw & 65535) == (OldDesired.Yaw & 65535) )
			DesiredRotation.Yaw -= 16384;
	}
    Begin:
		ScanRotation();
		FocalPoint = Pawn.Location + 1000 * vector(DesiredRotation);
		Sleep( GetScanDelay() );
		Goto('Begin');
}

state Closing
{
	function BeginState()
	{
        disable('tick');
	}

	function EndState()
	{
        enable('tick');
	}
	function tick(float d);
}

state Opening
{
	function BeginState()
	{
        disable('tick');
	}

	function EndState()
	{
        enable('tick');
	}
	function tick(float d);
}

state Engaged
{
	function BeginState()
	{
        disable('tick');
        super.BeginState();
	}

	function EndState()
	{
        enable('tick');
	}
	function tick(float d);
}

state Sleeping
{
	function Awake()
	{
		LastRotation = Rotation;
		ASVehicle_Sentinel(Pawn).Awake();
		GotoState('Opening');
	}

}

function SetInitialState()
{
    if(asvehicle_sentinel(instigator) != none)
        InitialState = 'Sleeping';
    super.SetInitialState();
}

function Possess(Pawn aPawn)
{
	super(TurretController).Possess( aPawn );

	if ( IsSpawnCampProtecting() )
	{
		Skill = 10;
		FocusLead = 0;
		pawn.RotationRate = pawn.default.RotationRate * 4;
	}
	else AcquisitionYawRate = 20000;
	enable('tick');
}

function bool IsSpawnCampProtecting()
{
    return ( asvehicle_sentinel(pawn) != none );
}

function bool IsTargetRelevant( Pawn Target )
{
	return ( (Target != None) && (Target.Controller != None) && !SameTeamAs(Target.Controller) && ( level.Game.bTeamGame ||
        (mymarker == none || ( Target.Controller != mymarker.instigatorcontroller && (rpgturretcontroller(Target.Controller) == none ||
        rpgturretcontroller(Target.Controller).mymarker == none ||
        rpgturretcontroller(Target.Controller).mymarker.instigatorcontroller != mymarker.instigatorcontroller ) ) ) )
		&& (Target.Health > 0) && VSize(Target.Location - Pawn.Location) < Pawn.SightRadius*1.25 );
}

defaultproperties
{
}

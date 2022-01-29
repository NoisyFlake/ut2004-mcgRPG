class TurretLauncher extends RPGArtifact 
	config(mcgRPG1991);

var() Emitter myEmitter;
var() float AdrenalineUsed;
var() config array<class<vehicle> > turretlist;
var() array<int> turretcost;
var() TurretBeacon Beacon;
var() class<vehicle> temp;

replication
{
    reliable if(role==role_authority)
        temp;
}

function BotConsider()
{
	if (bActive)
		return;

	if ( (Instigator.Health + Instigator.ShieldStrength < 0.4*instigator.HealthMax || (Bot(Instigator.Controller) != None &&
        Bot(Instigator.Controller).NeedWeapon() ) ) && (Instigator.Controller.Enemy == None ||
        !Instigator.Controller.CanSee(Instigator.Controller.Enemy) ) && (Instigator.Controller.Adrenaline > 2 * CostPerSec ||
        NoArtifactsActive()) )
		Activate();
}

static function bool ArtifactIsAllowed(GameInfo Game)
{
    local MutMCGRPG mut;
	mut = class'MutMCGRPG'.static.GetRPGMutator(game);
	    return ( mut == none || mut.MaxTurrets > 0 );
}

function DoEffect();

function postbeginplay()
{
    local int i,a;
    turretcost.Insert(0, turretlist.Length);
    for(i = 0;i < turretlist.Length;i++)
    {
        if( turretlist[i] != none )
        {
            a = int(float(turretlist[i].default.Health) / 8.0 ) * (1 + int(turretlist[i].default.bAutoTurret) ) *
                (1 + int(classischildof(turretlist[i], class'asturret_linkturret') ||
                classischildof(turretlist[i], class'asturret_minigun') ) ) *
                (1 + 2 * int( (classischildof(turretlist[i], class'onsweaponpawn') &&
                class<onsweaponpawn>(turretlist[i] ).default.GunClass != none &&
                class<onsweaponpawn>(turretlist[i] ).default.GunClass.default.bInstantFire) ||
                classischildof(turretlist[i], class'onsvehicle') ||
                classischildof(turretlist[i], class'asvehicle_sentinel') ) );
            turretcost[i] = a;
            if( ( temp == none ) || ( a < costpersec ) )
            {
                temp = turretlist[i];
                costpersec = a;
            }
        }
        else continue;
    }
    temp = none;
}

simulated function string ExtraData()
{
    if(temp!=none)
    {
        if(instigatorController == none || instigatorController.Adrenaline < minadrenalinecost)
        {
            temp = none;
            return "";
        }

        return temp.default.VehicleNameString;
    }
    return "";
}

function tick(float dt)
{
    local int i,a,b;
    if(bactive)
    {
        super.Tick(dt);
        return;
    }
    if(instigatorController == none || instigatorController.Adrenaline < minadrenalinecost )
    {
        if(temp != none)
            temp = none;
        return;
    }
    for(i = 0;i < turretlist.Length;i++)
    {
        if( turretlist[i] != none )
        {
            a = turretcost[i];
            if( ( a <= instigatorController.Adrenaline ) && ( ( temp == none ) || ( a > b ) ) )
            {
                temp = turretlist[i];
                b = a;
            }
        }
        else continue;
    }
}

function Activate()
{
    local int i;
    local bool enabled;
	if (bActivatable )
	{
        if (!bActive && Instigator != None && Instigator.Controller != None && ( beacon==none || beacon.bPendingDelete ||
            beacon.Disrupted() ) )
		{
			if (Instigator.Controller.Adrenaline >= CostPerSec * MinActivationTime )
			{
			    if(statsinv != none)
			    {
			        for(i=0;i < statsinv.turrets.Length;i++)
                        if(statsinv.turrets[i] == none )
			                statsinv.turrets.Remove(i,1);
			        if(statsinv.turrets.Length < statsinv.RPGMut.MaxTurrets)
			            enabled=true;
                    if( !enabled)
			        {
			            Instigator.ClientMessage("You can't have more, than "$statsinv.RPGMut.MaxTurrets$" turrets at once.", 'event');
			                return;
                    }
				    ActivatedTime = Level.TimeSeconds;
				    GotoState('Activated');
				}
			}
			else Instigator.ReceiveLocalizedMessage(MessageClass, 1, None, None, Class);
		}
	}
}


state Activated
{
	function BeginState()
	{
		local int x;

		myEmitter = spawn(class'teleportchargeeffect', Instigator,, Instigator.Location, Instigator.Rotation);
		myEmitter.SetBase(Instigator);
		if (Instigator.PlayerReplicationInfo != None && Instigator.PlayerReplicationInfo.Team != None && Instigator.PlayerReplicationInfo.Team.TeamIndex == 1)
			for (x = 0; x < myEmitter.Emitters[0].ColorScale.Length; x++)
				myEmitter.Emitters[0].ColorScale[x].Color = class'Hud'.default.BlueColor;

		bActive = true;
		AdrenalineUsed = CostPerSec;
	}

	function Tick(float deltaTime)
	{
		local float Cost;
		Cost = FMin(AdrenalineUsed, deltaTime * CostPerSec);
		AdrenalineUsed -= Cost;
		if (AdrenalineUsed <= 0.f)
		{
			//take the last bit of adrenaline from the player
			//add a tiny bit extra to fix float precision issues
			Instigator.Controller.Adrenaline -= Cost - 0.001;
			DoEffect();
		}
		else
		{
			Global.Tick(deltaTime);
		}
	}

	function DoEffect()
	{
	    local int EffectNum;
        local Vector Start, StartTrace, X,Y,Z;
        local Rotator dir;
        local Vector HitLocation, HitNormal;
        local Actor Other;

        Instigator.MakeNoise(1.0);
        GetAxes( Instigator.Rotation, x, y, z );

        StartTrace = Instigator.Location + Instigator.EyePosition();
        start = starttrace;
        // check if projectile would spawn through a wall and adjust start location accordingly
        Other = instigator.Trace(HitLocation, HitNormal, Start, StartTrace, false);
        if (Other != None)
            Start = HitLocation;
        dir = instigator.controller.rotation;

		if ( (Instigator.PlayerReplicationInfo == None) || (Instigator.PlayerReplicationInfo.Team == None) )
			Beacon = Instigator.Spawn(class'TurretBeacon',,, Start, Dir);
		else if ( Instigator.PlayerReplicationInfo.Team.TeamIndex == 0 )
			Beacon = Instigator.Spawn(class'RedTurretBeacon',,, Start, Dir);
		else
			Beacon = Instigator.Spawn(class'BlueTurretBeacon',,, Start, Dir);
        if(Beacon != none )
        {
            beacon.statsinv=statsinv;
            beacon.amount=costpersec;
            beacon.turretlist=turretlist;
            beacon.calculatecost();
        }
		if (Instigator.PlayerReplicationInfo != None && Instigator.PlayerReplicationInfo.Team != None)
			EffectNum = Instigator.PlayerReplicationInfo.Team.TeamIndex;
		Instigator.SetOverlayMaterial(class'TransRecall'.default.TransMaterials[EffectNum], 1.0, false);
		Instigator.PlayTeleportEffect(false, false);

		GotoState('');
	}

	function EndState()
	{
		if (myEmitter != None)
			myEmitter.Destroy();
        super.EndState();
	}
}

defaultproperties
{
     turretlist(0)=Class'mcgRPG1_9_9_1.RPGTurret'
     turretlist(1)=Class'mcgRPG1_9_9_1.RPGLinkTurret'
     turretlist(2)=Class'UT2k4Assault.ASVehicle_Sentinel_Floor'
     MinActivationTime=1.000000
     PickupClass=Class'mcgRPG1_9_9_1.TurretPickup'
     IconMaterial=Texture'RPGTextures.Turret'
     ItemName="Turret Launcher"
}

class TurretBeacon extends projectile;

var() bool bCanHitOwner;
var() bool bDamaged;
var() xEmitter Trail;
var() xEmitter Flare;
var() int Disruption;
var() int DisruptionThreshold;
var() Pawn Disruptor;
var() TransBeaconSparks Sparks;
var() class<TransTrail> TransTrailClass;
var() class<TransFlareBlue> TransFlareClass;
var() int amount;
var() array<class<vehicle> > turretlist;
var() bool bdone;
var() class<vehicle> temp;
var() byte team;
var() rpgstatsinv statsinv;

replication
{
    reliable if ( Role == ROLE_Authority )
        Disruption;
}

simulated function Destroyed()
{
    if ( Trail != None )
        Trail.mRegen = false;
    if ( Flare != None )
    {
		Flare.mRegen = false;
        Flare.Destroy();
    }
    if ( Sparks != None )
        Sparks.Destroy();
	Super.Destroyed();
}

function EncroachedBy( actor Other )
{
	if ( Mover(Other) != None )
		Destroy();
}

simulated function bool Disrupted()
{
	return ( Disruption > DisruptionThreshold );
}

function calculatecost()
{
    local int i,a,b;
    for(i = 0;i < turretlist.Length;i++)
    {
        if( turretlist[i] != none )
        {
            a = int(float(turretlist[i].default.Health) / 8.0 ) * (1 + int(turretlist[i].default.bAutoTurret) ) *
                (1 + int(classischildof(turretlist[i], class'asturret_linkturret') || classischildof(turretlist[i], class'asturret_minigun') ) ) *
                (1 + 2 * int( (classischildof(turretlist[i], class'onsweaponpawn') && class<onsweaponpawn>(turretlist[i] ).default.GunClass != none &&
                class<onsweaponpawn>(turretlist[i] ).default.GunClass.default.bInstantFire) || classischildof(turretlist[i], class'onsvehicle') ||
                classischildof(turretlist[i], class'asvehicle_sentinel') ) );
            if( ( a <= instigatorController.Adrenaline + amount ) && ( ( temp == none ) || ( a > b ) ) )
            {
                temp = turretlist[i];
                b = a;
            }
        }
        else continue;
    }

    amount = b - amount;
    if(temp!=none)
        instigatorController.Adrenaline -= float(amount);
    else amount = 0;
}

simulated function PostBeginPlay()
{
    local Rotator r;

    Super.PostBeginPlay();

    if ( Role == ROLE_Authority )
    {
		R = Rotation;
        Velocity = Speed * Vector(R);
        R.Yaw = Rotation.Yaw;
        R.Pitch = 0;
        R.Roll = 0;
        SetRotation(R);
        bCanHitOwner = false;
        team=instigator.GetTeamNum();
    }
    Trail = Spawn(TransTrailClass, self,, Location, Rotation);
    SetTimer(0.3,false);
}

simulated function PhysicsVolumeChange( PhysicsVolume Volume )
{
}

simulated function Landed( vector HitNormal )
{
    HitWall( HitNormal, None );
}

function spawnturret()
{
    local vehicle v;
    local float offset;
    local turretmarker t;
    local class<controller> tc;
    if ( Disrupted() )
    {
        if( (PlayerController(InstigatorController) != None) )
            PlayerController(InstigatorController).ClientPlaySound(Sound'WeaponSounds.BSeekLost1');
        return;
    }
    if(temp !=none && statsinv != none && !statsinv.bPendingDelete)
    {
        if( classischildof(temp, class'asvehicle_sentinel') )
            offset=70;
        if(temp.default.AutoTurretControllerClass != class'mcgRPG1_9_9_1.rpgturretcontroller')
        {
            tc = temp.default.AutoTurretControllerClass;
            if( tc != none)
                temp.default.AutoTurretControllerClass = class'mcgRPG1_9_9_1.rpgturretcontroller';
            v=spawn(temp,,,location + vect(0,0,0.85)*(offset+temp.default.CollisionHeight),rotation );
            temp.default.AutoTurretControllerClass = tc;
        }
        else v=spawn(temp,,,location + vect(0,0,0.85)*(offset+temp.default.CollisionHeight),rotation );
        if(v!=none)
        {
            if(statsinv.Instigator != none)
                statsinv.deactivatespawnprotection();
            statsinv.activateplayer();
            if(v.bAutoTurret)
            {
                t=v.spawn(class'turretmarker',v );
                if(t!=none)
                {
                    t.giveto(v);
                    t.instigatorcontroller=instigatorcontroller;
                    if(rpgturretcontroller(v.Controller) != none)
                    {
                        t.basecontroller = rpgturretcontroller(v.Controller);
                        rpgturretcontroller(v.Controller).mymarker = t;
                        t.Enable('tick');
                    }
                    else t.Disable('tick');
                }
            }
            v.SetTeamNum(team);
            v.bTeamLocked=false;
            if(!v.bNonHumanControl)
                v.EntryRadius=fmax(fmax(300.0,v.EntryRadius),2.0 * v.collisionradius);
            statsinv.addvehicle(v);
            if(asvehicle_sentinel(v)!=none)
                asvehicle_sentinel(v).bSpawnCampProtection=true;
        }
    }
    else if( instigatorController!=none && !instigatorcontroller.bpendingdelete)
        instigatorController.Adrenaline+=amount;
}

simulated function ProcessTouch( actor Other, vector HitLocation )
{
	local vector Vel2D;

    if ( (Other != Instigator) || bCanHitOwner )
    {
   		if ( (Pawn(Other) != None) && (Vehicle(Other) == None) )
		{
			Vel2D = Velocity;
			Vel2D.Z = 0;
			if ( VSize(Vel2D) < 200 )
				return;
		}
		HitWall( -Normal(Velocity), Other );
    }
}

// poll for disruption
simulated function Timer()
{
    if ( Level.NetMode == NM_DedicatedServer )
        return;

    if ( !Disrupted() )
    {
        SetTimer(0.3, false);
        return;
    }

    // create the disrupted effect
    if (Sparks == None)
    {
        Sparks = Spawn(class'TransBeaconSparks',,,Location+vect(0,0,5),Rotator(vect(0,0,1)));
        Sparks.SetBase(self);
    }

    if (Flare != None)
        Flare.Destroy();
}

function TakeDamage(int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType)
{
    if ( Level.Game.bTeamGame && (EventInstigator != None) && (EventInstigator.PlayerReplicationInfo != None) && (InstigatorController != None) &&
        (InstigatorController.pawn != EventInstigator) && (InstigatorController.PlayerReplicationInfo != None) &&
        (EventInstigator.PlayerReplicationInfo.Team == InstigatorController.PlayerReplicationInfo.Team) )
    {
		return;
    }
    else
    {
        Disruption += Damage;
		Disruptor = EventInstigator;
    }
}

simulated function HitWall( vector HitNormal, actor Wall )
{
	local CTFBase B;
    bCanHitOwner = true;

	Velocity = 0.3*(( Velocity dot HitNormal ) * HitNormal * (-2.0) + Velocity);   // Reflect off Wall w/damping
	Speed = VSize(Velocity);

	if ( Speed < 100 )
	{
		ForEach TouchingActors(class'CTFBase', B)
			break;

		if ( B != None )
		{
			Speed = VSize(Velocity);
			if ( Speed < 100 )
			{
				Speed = 90;
				Velocity = 90 * Normal(Velocity);
			}
			Disruption += 5;
			if ( Disruptor == None )
				Disruptor = Instigator;
		}
	}


	if ( Speed < 20 && wall!=none && Wall.bWorldGeometry && (HitNormal.Z >= 0.7) )
	{
		if ( Level.NetMode != NM_DedicatedServer )
			PlaySound(ImpactSound, SLOT_Misc );
		bBounce = false;
		SetPhysics(PHYS_None);

		if (Trail != None)
			Trail.mRegen = false;

		if ( (Level.NetMode != NM_DedicatedServer) && (Flare == None) )
		{
			Flare = Spawn(TransFlareClass, self,, Location - vect(0,0,5), rot(16384,0,0));
			Flare.SetBase(self);
		}
	}
	if ( role == role_authority && !bdone && wall!=none && Wall.bWorldGeometry  && VSize(Velocity) == 0 )
	{
	    bdone=true;
        spawnturret();
        destroy();
	}
}

defaultproperties
{
     DisruptionThreshold=20
     TransTrailClass=Class'XEffects.TransTrail'
     TransFlareClass=Class'XEffects.TransFlareRed'
     Speed=1200.000000
     MomentumTransfer=50000.000000
     ImpactSound=ProceduralSound'WeaponSounds.PGrenFloor1.P1GrenFloor1'
     ExplosionDecal=Class'XEffects.RocketMark'
     DrawType=DT_StaticMesh
     StaticMesh=StaticMesh'WeaponStaticMesh.NEWTranslocatorPUCK'
     bNetTemporary=False
     bUpdateSimulatedPosition=True
     bOnlyDirtyReplication=True
     Physics=PHYS_Falling
     NetUpdateFrequency=8.000000
     AmbientSound=Sound'WeaponSounds.Misc.redeemer_flight'
     LifeSpan=120.000000
     DrawScale=0.350000
     PrePivot=(Z=25.000000)
     AmbientGlow=64
     bUnlit=False
     bOwnerNoSee=True
     SoundVolume=250
     SoundPitch=128
     SoundRadius=7.000000
     CollisionRadius=10.000000
     CollisionHeight=10.000000
     bProjTarget=True
     bNetNotify=True
     bBounce=True
}

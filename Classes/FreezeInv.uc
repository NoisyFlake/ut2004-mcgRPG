class FreezeInv extends Inventory;

var() Controller InstigatorController;
var() Pawn PawnOwner;
var() int Modifier;

var() class <xEmitter> FreezeEffectClass;
var() Shader ModifierOverlay;

var() bool stopped;

replication
{
	reliable if (bNetInitial && Role == ROLE_Authority)
		PawnOwner;
	reliable if (Role == ROLE_Authority)
		stopped;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	if (Instigator != None)
		InstigatorController = Instigator.Controller;

	SetTimer(0.5, true);
}

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	local Pawn OldInstigator;

	if(Other == None)
	{
		destroy();
		return;
	}

	stopped = false;
	if (InstigatorController == None)
		InstigatorController = Other.Controller;

	//want Instigator to be the one that caused the freeze
	OldInstigator = Instigator;
	Super.GiveTo(Other);
	PawnOwner = Other;

	Instigator = OldInstigator;
	PawnOwner.setOverlayMaterial(ModifierOverlay, (LifeSpan-2), true);
}

simulated function Timer()
{
	Local Actor A;
	if(!stopped)
	{
		if (Level.NetMode != NM_DedicatedServer && PawnOwner != None)
		{
		    if ( PlayerController(PawnOwner.Controller) != None && PawnOwner.Controller.Pawn == PawnOwner && PawnOwner.Controller == level.GetLocalPlayerController() )
				PlayerController(PawnOwner.Controller).ReceiveLocalizedMessage(class'FreezeConditionMessage', 0);
		}
		if (Role == ROLE_Authority)
		{
			if(Owner != None)
				A = PawnOwner.spawn(class'IceSmoke', PawnOwner,, PawnOwner.Location, PawnOwner.Rotation);

			if(!class'RW_Freeze'.static.canTriggerPhysics(PawnOwner))
			{
				stopEffect();
				return;
			}

			if(LifeSpan <= 0.5)
			{
				stopEffect();
				return;
			}

			if (Owner == None)
			{
				Destroy();
				return;
			}

			if (Instigator == None && InstigatorController != None)
				Instigator = InstigatorController.Pawn;
			else if(PawnOwner != None)
				quickfoot(-10 * Modifier, PawnOWner);
		}
	}
}

static function quickfoot(int localModifier, Pawn PawnOwner)
{
	local int x;
	local bool found;
	local RPGStatsInv StatsInv;

	StatsInv = RPGStatsInv(PawnOwner.FindInventoryType(class'RPGStatsInv'));
	found = false;

	for (x = 0; StatsInv != None && x < StatsInv.Data.Abilities.length; x++)
		if (StatsInv.Data.Abilities[x] == class'AbilitySpeed')
		{
			found = true;
			break;
		}

	if(!found)
		ModifyPawn(PawnOwner, localModifier);
	else
		ModifyPawn(PawnOwner, StatsInv.Data.AbilityLevels[x] + localModifier);
}

static function ModifyPawn(Pawn Other, int AbilityLevel)
{
    local float modifier;
	if(AbilityLevel >= 0)
	{
	    modifier = 1.0 + 0.05 * float(AbilityLevel);
		Other.GroundSpeed = Other.default.GroundSpeed * modifier;
		Other.WaterSpeed = Other.default.WaterSpeed * modifier;
		Other.AirSpeed = Other.default.AirSpeed * modifier;
		if(karmaparams(other.KParams) != none)
		{
		    karmaparams(other.KParams).KMaxSpeed = karmaparams(other.Class.default.KParams).KMaxSpeed * modifier;
            if(onschoppercraft(other) != none)
                onschoppercraft(other).MaxThrustForce = onschoppercraft(other).default.MaxThrustForce * modifier;
            else if(onshovercraft(other) != none)
                onshovercraft(other).MaxThrustForce = onshovercraft(other).default.MaxThrustForce * modifier;
            else if(onsplanecraft(other) != none)
                onsplanecraft(other).MaxThrust = onsplanecraft(other).default.MaxThrust * modifier;
            else if(onstreadcraft(other) != none)
            {
                onstreadcraft(other).MaxThrust = onstreadcraft(other).default.MaxThrust * modifier;
		        if(onshovertank(other) != none)
		            onshovertank(other).MaxGroundSpeed = onshovertank(other).default.MaxGroundSpeed * modifier;
            }
            else if(onswheeledcraft(other) != none)
                onswheeledcraft(other).TransRatio = onswheeledcraft(other).default.TransRatio * modifier;
        }
	}
	else
	{
	    modifier = 1.0 - 0.05 * float(AbilityLevel);
		Other.GroundSpeed = Other.default.GroundSpeed / modifier;
		Other.WaterSpeed = Other.default.WaterSpeed / modifier;
		Other.AirSpeed = Other.default.AirSpeed / modifier;
		if(karmaparams(other.KParams) != none)
		{
		    karmaparams(other.KParams).KMaxSpeed = karmaparams(other.Class.default.KParams).KMaxSpeed / modifier;
            if(onschoppercraft(other) != none)
                onschoppercraft(other).MaxThrustForce = onschoppercraft(other).default.MaxThrustForce / modifier;
            else if(onshovercraft(other) != none)
                onshovercraft(other).MaxThrustForce = onshovercraft(other).default.MaxThrustForce / modifier;
            else if(onsplanecraft(other) != none)
                onsplanecraft(other).MaxThrust = onsplanecraft(other).default.MaxThrust / modifier;
            else if(onstreadcraft(other) != none)
            {
                onstreadcraft(other).MaxThrust = onstreadcraft(other).default.MaxThrust / modifier;
		        if(onshovertank(other) != none)
		            onshovertank(other).MaxGroundSpeed = onshovertank(other).default.MaxGroundSpeed / modifier;
            }
            else if(onswheeledcraft(other) != none)
                onswheeledcraft(other).TransRatio = onswheeledcraft(other).default.TransRatio / modifier;
        }
	}
}

function stopEffect()
{
	if(stopped)
		return;
	else
		stopped = true;
	if(PawnOwner != None)
		quickfoot(0, PawnOwner);
}

function destroyed()
{
	stopEffect();
	super.destroyed();
}

defaultproperties
{
     ModifierOverlay=Shader'DruidsRPGShaders1.DomShaders.PulseGreyShader'
     bOnlyRelevantToOwner=False
     bAlwaysRelevant=True
     bReplicateInstigator=True
}

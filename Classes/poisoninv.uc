class poisoninv extends Inventory;

var() Controller InstigatorController;
var() Pawn PawnOwner;
var() int Modifier;
var() vector HitLocation;

replication
{
	reliable if (bNetInitial && Role == ROLE_Authority)
		PawnOwner;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	if (Instigator != None)
		InstigatorController = Instigator.Controller;

	SetTimer(1, true);
}

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	local Pawn OldInstigator;

	if (InstigatorController == None)
		InstigatorController = Other.DelayedDamageInstigatorController;

	//want Instigator to be the one that caused the poison
	OldInstigator = Instigator;
	Super.GiveTo(Other);
	PawnOwner = Other;
	Instigator = OldInstigator;
}

simulated function Timer()
{
	if (Role == ROLE_Authority)
	{
		if (Owner == None)
		{
			Destroy();
			return;
		}

		if (Instigator == None && InstigatorController != None)
			Instigator = InstigatorController.Pawn;

		PawnOwner.SetDelayedDamageInstigatorController(InstigatorController);
		PawnOwner.TakeDamage(Modifier * 2, Instigator, HitLocation, vect(0,0,0), class'damtypePoison');
	}

	if (Level.NetMode != NM_DedicatedServer && PawnOwner != None)
	{
		PawnOwner.Spawn(class'GoopSmoke');
		if ( PlayerController(PawnOwner.Controller) != None && PawnOwner.Controller.Pawn == PawnOwner && PawnOwner.Controller == level.GetLocalPlayerController() )
			PlayerController(PawnOwner.Controller).ReceiveLocalizedMessage(class'RPGDamageConditionMessage', 0);
	}
}

defaultproperties
{
     bOnlyRelevantToOwner=False
}

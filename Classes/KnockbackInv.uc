class knockbackInv extends Inventory;

var() Pawn PawnOwner;
var() int Modifier;

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	PawnOwner = Other;

	if(PawnOwner == None)
	{
		destroy();
		return;
	}
    pawnowner.bCollideWorld=true;
	SetTimer(1/Modifier, true);
	Super.GiveTo(Other);
}

function Destroyed()
{
	if(PawnOwner == None)
		return;

	if(PawnOwner.Physics != PHYS_Walking && PawnOwner.Physics != PHYS_Falling) //still going?
		PawnOwner.setPhysics(PHYS_Falling);
	super.destroyed();
}

function Timer()
{
	if(PawnOwner.Physics != PHYS_Hovering && PawnOwner.Physics != PHYS_Falling)
		Destroy();
}

defaultproperties
{
     bOnlyRelevantToOwner=False
     bAlwaysRelevant=True
     bReplicateInstigator=True
}

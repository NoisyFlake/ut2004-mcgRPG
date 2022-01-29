class RPGArtifactPickup extends TournamentPickup;

var() config float LifeTime;
var() RPGArtifactManager ArtifactManager;

function PostBeginPlay()
{
	Super.PostBeginPlay();

	if (ArtifactManager != None)
		SetTimer(Lifetime, false);
	else
		Destroy();
}

function bool CanPickupArtifact(Pawn Other)
{
	local Inventory Inv;
	local int Count, NumArtifacts;

	if (ArtifactManager == None)
	{
		//PostBeginPlay() hasn't been called yet, wait until later
		PendingTouch = Other.PendingTouch;
		Other.PendingTouch = self;
		return false;
	}


	for (Inv = Other.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if (RPGArtifact(Inv) != None)
		{
		    if(inv.Class == inventorytype)
		        return false;
			NumArtifacts++;
		}
		Count++;
		if (Count > 1000)
			break;
	}
	if (ArtifactManager.MaxHeldArtifacts <= 0)
		return true;

	if (NumArtifacts >= ArtifactManager.MaxHeldArtifacts)
		return false;

	return true;
}

function float DetourWeight(Pawn Other, float PathWeight)
{
	if (CanPickupArtifact(Other))
		return MaxDesireability/PathWeight;
	else
		return 0;
}

function float BotDesireability(Pawn Bot)
{
	if (CanPickupArtifact(Bot))
		return MaxDesireability;
	else
		return 0;
}

auto state Pickup
{
	function bool ValidTouch(Actor Other)
	{
		if (!Super.ValidTouch(Other))
			return false;

		return CanPickupArtifact(Pawn(Other));
	}
}

defaultproperties
{
     Lifetime=160.000000
     MaxDesireability=1.500000
}

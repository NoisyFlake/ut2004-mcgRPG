class RPGWeaponPickup extends UTWeaponPickup;

var() MutMCGRPG RPGMut;
var() weaponpickup ReplacedPickup;
var() bool bRealWeaponStay; //hack for compatibility with Random Weapon Swap
var() bool bdone;

function PostBeginPlay()
{
	Super(Pickup).PostBeginPlay();
	RPGMut = class'MutMCGRPG'.static.GetRPGMutator(Level);
	SetTimer(0.1, false);
}

function Timer()
{
    if(ReplacedPickup == none || ReplacedPickup.MyMarker == none)
        destroy();
    else
        GetPropertiesFrom();
}

function SetWeaponStay()
{
	bWeaponStay = ( bRealWeaponStay && Level.Game.bWeaponStay );
}

function GetPropertiesFrom()
{
    PickUpBase = ReplacedPickup.PickUpBase;
    MyMarker = ReplacedPickup.myMarker;
    GotoState('');
    MyMarker.MarkedItem = self;

    //hack for ChaosUT - handle its special pickup-swapping pickupbases
    if (PickupBase != None && PickupBase.IsA('MultiPickupBase') && bool(PickupBase.GetPropertyText("bChangeOnlyOnPickup") ) )
    {
        bWeaponStay = false;
    }
    if(ReplacedPickup.GetStateName() != ReplacedPickup.Class.name)
        GotoState(ReplacedPickup.GetStateName() );
	bRealWeaponStay = ReplacedPickup.default.bWeaponStay;
	SetWeaponStay();
	InventoryType = ReplacedPickup.InventoryType;
	RespawnTime = ReplacedPickup.RespawnTime;
	MaxDesireability = ReplacedPickup.MaxDesireability;
}

function float DetourWeight(Pawn Other, float PathWeight)
{
	local float desire;
	local Inventory Inv,temp,AlreadyHas;
	local int Count;
	local bool bFound;


    InventoryType = ReplacedPickup.InventoryType;
	if(Other.FindInventoryType(InventoryType) != none)
	    return ReplacedPickup.DetourWeight(Other,PathWeight);
	for (Inv = Other.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if ( !bFound && RPGWeapon(Inv) != None && RPGWeapon(Inv).ModifiedWeapon != none && RPGWeapon(Inv).ModifiedWeapon.Class == InventoryType )
		{
			AlreadyHas = RPGWeapon(Inv).ModifiedWeapon;
			bFound = true;
		}
		Count++;
		if (Count > 999 || Inv.Inventory == None)
			break;
	}
    if(AlreadyHas != none)
    {
        temp = inv.Inventory;
        inv.Inventory = AlreadyHas;
        desire = ReplacedPickup.DetourWeight(Other,PathWeight);
        inv.Inventory = temp;
        return desire;
    }
	for (Inv = Other.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if ( !bFound && RPGWeapon(Inv) != None && RPGWeapon(Inv).ModifiedWeapon != none && ClassIsChildOf(RPGWeapon(Inv).ModifiedWeapon.Class,InventoryType) )
		{
			AlreadyHas = RPGWeapon(Inv).ModifiedWeapon;
			bFound = true;
		}
		Count++;
		if (Count > 999 || Inv.Inventory == None)
			break;
	}
    temp = inv.Inventory;
    inv.Inventory = AlreadyHas;
    desire = ReplacedPickup.DetourWeight(Other,PathWeight);
    inv.Inventory = temp;
    return desire;
}

function float BotDesireability(Pawn Bot)
{
	local float desire;
	local Inventory Inv,temp,AlreadyHas;
	local int Count;
	local bool bFound;

    InventoryType = ReplacedPickup.InventoryType;
	if(Bot.FindInventoryType(InventoryType) != none)
	    return ReplacedPickup.BotDesireability(bot);
	for (Inv = Bot.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if ( !bFound && RPGWeapon(Inv) != None && RPGWeapon(Inv).ModifiedWeapon != none && RPGWeapon(Inv).ModifiedWeapon.Class == InventoryType )
		{
			AlreadyHas = RPGWeapon(Inv).ModifiedWeapon;
			bFound = true;
		}
		Count++;
		if (Count > 999 || Inv.Inventory == None)
			break;
	}
    if(AlreadyHas != none)
    {
        temp = inv.Inventory;
        inv.Inventory = AlreadyHas;
        desire = ReplacedPickup.BotDesireability(bot);
        inv.Inventory = temp;
        return desire;
    }
	for (Inv = Bot.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if ( !bFound && RPGWeapon(Inv) != None && RPGWeapon(Inv).ModifiedWeapon != none && ClassIsChildOf(RPGWeapon(Inv).ModifiedWeapon.Class,InventoryType) )
		{
			AlreadyHas = RPGWeapon(Inv).ModifiedWeapon;
			bFound = true;
		}
		Count++;
		if (Count > 999 || Inv.Inventory == None)
			break;
	}
    temp = inv.Inventory;
    inv.Inventory = AlreadyHas;
    desire = ReplacedPickup.BotDesireability(bot);
    inv.Inventory = temp;
    return desire;
}

function bool ReadyToPickup(float MaxWait)
{
    if(ReplacedPickup.GetStateName() != ReplacedPickup.Class.name)
    {
        if(ReplacedPickup.GetStateName() != GetStateName() )
            GotoState(ReplacedPickup.GetStateName() );
    }
    else if(GetStateName() != Class.name)
        gotostate('');
    return ReplacedPickup.ReadyToPickup(MaxWait);
}
/*
function bool ValidTouch( actor Other )
{
    return ReplacedPickup.ValidTouch(other);
}
*/
auto state Pickup
{
	function bool ReadyToPickup(float MaxWait)
	{
		return global.ReadyToPickup(MaxWait);;
	}
	function Touch( actor Other )
	{
	}
	function CheckTouching()
	{
	}

	function Timer()
	{
		if ( bDropped )
			GotoState('FadeOut');
		else global.timer();
	}
Begin:
}

State Sleeping
{
	function bool ReadyToPickup(float MaxWait)
	{
		return global.ReadyToPickup(MaxWait);;
	}
}

function BaseChange()
{
    if(base == none )
    {
        if(ReplacedPickup == none || ReplacedPickup.bPendingDelete )
            destroy();
        else
            setbase(ReplacedPickup);
    }
}

function RespawnEffect()
{
}

function bool AllowRepeatPickup()
{
    return ReplacedPickup.AllowRepeatPickup();
}

function float GetRespawnTime()
{
    return ReplacedPickup.GetRespawnTime();
}

function Reset()
{
}

function InitDroppedPickupFor(Inventory Inv)
{
}

function Destroyed()
{
	if (MyMarker != None )
		MyMarker.markedItem = ReplacedPickup;
	if (Inventory != None )
		Inventory.Destroy();
}

defaultproperties
{
     MaxDesireability=0.000000
     PickupMessage="WeaponPickup"
     DrawType=DT_None
     CullDistance=0.000000
     bHidden=True
     bOrientOnSlope=False
     bAlwaysRelevant=False
     Physics=PHYS_None
     RemoteRole=ROLE_None
     AmbientGlow=0
     bGameRelevant=True
     CollisionRadius=0.000000
     CollisionHeight=0.000000
     bCollideActors=False
     bCollideWorld=False
     bBlockZeroExtentTraces=False
     bBlockNonZeroExtentTraces=False
     RotationRate=(Yaw=0)
     DesiredRotation=(Yaw=0)
     MessageClass=Class'mcgRPG1_9_9_1.EmptyMessage'
}

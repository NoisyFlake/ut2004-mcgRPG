class RPGArtifact extends Powerups
	config(mcgRPG1991);

var() int CostPerSec; //adrenaline cost per second
var() float ActivatedTime, MinActivationTime;
var() localized string NotEnoughAdrenalineMessage;
var() controller instigatorcontroller;
var() MutMCGRPG RPGMut;
var() rpgstatsinv statsinv;
var() bool bdropped;
var() int minadrenalinecost;
var() int index, position;

replication
{
	reliable if (Role < ROLE_Authority)
		TossArtifact,selectme;
	reliable if (Role == ROLE_Authority)
	     instigatorcontroller,minadrenalinecost,RPGMut;
}

simulated function string ExtraData()
{
    return "";
}

static function bool ArtifactIsAllowed(GameInfo Game)
{
	return true;
}

function postnetbeginplay()
{
    calculatecost();
}

function calculatecost()
{
    minadrenalinecost = CostPerSec * MinActivationTime;
}

//Hack for bots
function OwnerEvent(name EventName)
{
	if (EventName == 'ChangedWeapon' && AIController(Instigator.Controller) != None)
		BotConsider();

	Super.OwnerEvent(EventName);
}

//AI for activating/deactivating this artifact
function BotConsider();

//returns true if Instigator currently has no active artifacts
simulated function bool NoArtifactsActive()
{
	local Inventory Inv;
	local int Count;

	for (Inv = Instigator.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if (RPGArtifact(Inv) != None && RPGArtifact(Inv).bActive)
			return false;
		Count++;
		if (Count > 250)
			break;
	}

	return true;
}

function bool HandlePickupQuery(Pickup Item)
{
	return super(Inventory).HandlePickupQuery(Item);
}

//Toss out this artifact
exec function TossArtifact()
{
	local vector X, Y, Z;

    if(bActive)
        return;
	Velocity = Vector(InstigatorController.GetViewRotation());
	Velocity = Velocity * ((Instigator.Velocity Dot Velocity) + 500) + Vect(0,0,200);
	GetAxes(Instigator.Rotation, X, Y, Z);
	DropFrom(Instigator.Location + 0.8 * Instigator.CollisionRadius * X - 0.5 * Instigator.CollisionRadius * Y);
}

function giveto(pawn p, optional pickup pickup)
{
    local controller c;
    local inventory i;
    local int x;
    if(p == none)
        return;
    for(i=p.Inventory;i!=none;i=i.Inventory)
    {
        if(i.Class == class)
        {
            destroy();
            return;
        }
        else x++;
    }
    super.GiveTo(p);
    if(bpendingdelete)
        return;
    if(instigator.Controller!=none)
        c = instigator.Controller;
    else if(instigator.DrivenVehicle!=none)
        c = instigator.DrivenVehicle.Controller;
    if(c==none)
    {
        destroy();
        return;
    }
    else instigatorcontroller=c;
    statsinv=class'rpgrules'.static.GetStatsInvFor(c);
    bdropped=false;
}

function DropFrom(vector StartLocation)
{
	bdropped=true;
    if (bActive)
		GotoState('');
	if(instigator != none && instigator.Health > 0)
	    Instigator.NextItem();
	instigatorcontroller=none;

	Super.DropFrom(StartLocation);
}

function UsedUp()
{
    ActivatedTime = -1000000.0;
    Activate();
	if ( Instigator != None )
	{
		Instigator.ReceiveLocalizedMessage(MessageClass, 0, None, None, Class);
	    Instigator.PlaySound(DeactivateSound,SLOT_Interface);
	}
}

function Activate()
{
    if(statsinv!=none)
    {
        statsinv.activateplayer();
        statsinv.deactivatespawnprotection();
    }
	if (bActivatable)
	{
		if (bActive && Level.TimeSeconds > ActivatedTime + MinActivationTime)
			GotoState('');
		else if (!bActive && Instigator != None && Instigator.Controller != None)
		{
			if (Instigator.Controller.Adrenaline >= CostPerSec * MinActivationTime)
			{
				ActivatedTime = Level.TimeSeconds;
				GotoState('Activated');
			}
			else
				Instigator.ReceiveLocalizedMessage(MessageClass, 1, None, None, Class);
		}
	}
}

static function string GetLocalString(optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2)
{
	if (Switch == 1)
		return Default.NotEnoughAdrenalineMessage;

	return Super.GetLocalString(Switch, RelatedPRI_1, RelatedPRI_2);
}

function Tick(float deltaTime)
{
	if (bActive )
	{
	    if ( InstigatorController == none)
		{
			UsedUp();
			return;
		}
		if ( InstigatorController.Adrenaline <= 0.0)
		{
			InstigatorController.Adrenaline = 0.0;
			UsedUp();
			return;
		}
	    InstigatorController.Adrenaline -= deltaTime * CostPerSec;
	}
}

state Activated
{
	function EndState()
	{
		bActive = false;
		if(instigatorcontroller!=none)
		    instigatorcontroller.Adrenaline = max(0.0,instigatorcontroller.Adrenaline);  //fix negative adrenaline
		if(bdropped)
	        instigatorcontroller=none;
	}
}

function selectme()
{
    if(instigator != none)
        instigator.SelectedItem = self;
}

defaultproperties
{
     MinActivationTime=2.000000
     NotEnoughAdrenalineMessage="You do not have enough adrenaline to activate this artifact."
     Position=-1
     bActivatable=True
     ExpireMessage="Your adrenaline has run out."
     bReplicateInstigator=True
     MessageClass=Class'UnrealGame.StringMessagePlus'
}

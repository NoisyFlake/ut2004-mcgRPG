class DruidMaxModifier extends RPGArtifact;

var() Pawn RealInstigator;
var() RPGWeapon Weapon;
var() bool needsIdentify;


static function bool ArtifactIsAllowed(GameInfo Game)
{
    local MutMCGRPG mut;
    mut = class'MutMCGRPG'.static.GetRPGMutator(game);
    return ( mut == none || mut.WeaponModifierChance > 0.0 );
}

function BotConsider()
{
	if (Instigator.Controller.Adrenaline < getcost() || bactive)
		return;

    if ( Instigator.Controller.Enemy != None && Instigator.Weapon != None && Instigator.Weapon.AIRating > 0.5
        && Instigator.Controller.Enemy.Health > 70 && Instigator.Controller.CanSee(Instigator.Controller.Enemy) && NoArtifactsActive() &&
        FRand() < 0.7 )
		Activate();
}


function PostBeginPlay()
{
	super.PostBeginPlay();
	disable('Tick');
}

function Activate()
{
	local Vehicle V;

    if(statsinv!=none)
        statsinv.activateplayer();
	if (Instigator != None && Instigator.Controller != None)
	{
		if(Instigator.Controller.Adrenaline < getCost())
		{
			Instigator.ReceiveLocalizedMessage(MessageClass, getCost(), None, None, Class);
			bActive = false;
			GotoState('');
			return;
		}

		V = Vehicle(Instigator);
		if (V != None && V.Driver != None)
			RealInstigator = V.Driver;
		else
			RealInstigator = Instigator;

		Weapon = RPGWeapon(RealInstigator.Weapon);
		if(Weapon != None)
		{
			if(Weapon.Modifier > Weapon.MaxModifier)
			{
				Instigator.ReceiveLocalizedMessage(MessageClass, 3000, None, None, Class);
				bActive = false;
				GotoState('');
				return;
			}
            if(Weapon.Modifier < Weapon.MaxModifier)
			    Weapon.Modifier = Weapon.MaxModifier;
            else
                Weapon.Modifier = Weapon.MaxModifier + 1;
			needsIdentify = true;
			setTimer(1, true);

			Instigator.Controller.Adrenaline -= getCost();

			bActive = false;
			GotoState('');
			return;
		}
		else
		{
			Instigator.ReceiveLocalizedMessage(MessageClass, 2000, None, None, Class);
			bActive = false;
			GotoState('');
			return;
		}
	}
	else
	{
		bActive = false;
		GotoState('');
		return;
	}
}

function Timer()
{
	if(needsIdentify && Weapon != None)
	{
		Weapon.Identify();
		needsIdentify=false;
	}
	setTimer(0, false);
}

exec function TossArtifact()
{
	//do nothing. This artifact cant be thrown
}

function DropFrom(vector StartLocation)
{
	if (bActive)
		GotoState('');
	bActive = false;

	Destroy();
	if(instigator != none && instigator.Health > 0)
	    Instigator.NextItem();
}

static function string GetLocalString(optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2)
{
	if (Switch == 2000)
		return "Unable to modify magic weapon";
	if (Switch == 3000)
		return "Magic weapon is already above the maximum modifier.";
	else
		return switch @ "Adrenaline is required to generate a magic weapon";
}

function calculatecost()
{
    minadrenalinecost = getcost();
}

function int getCost()
{
	return 150;
}

defaultproperties
{
     CostPerSec=1
     MinActivationTime=0.000001
     Index=5
     IconMaterial=FinalBlend'XGameTextures.SuperPickups.UDamageC'
     ItemName="Extra Magic Modifier"
}

class DruidDoubleModifier extends RPGArtifact;

var() Pawn RealInstigator;
var() RPGWeapon Weapon;
var() bool oldCanThrow;
var() bool needsIdentify;
var() int oldmodifier;

static function bool ArtifactIsAllowed(GameInfo Game)
{
    local MutMCGRPG mut;
    mut = class'MutMCGRPG'.static.GetRPGMutator(game);
    return ( mut == none || mut.WeaponModifierChance > 0.0 );
}

function BotConsider()
{
	if (Instigator.Controller.Adrenaline < 30)
		return;

	if (bActive && (Instigator.Controller.Enemy == None || !Instigator.Controller.CanSee(Instigator.Controller.Enemy)))
		Activate();
	else if ( !bActive && Instigator.Controller.Enemy != None && Instigator.Weapon != None && Instigator.Weapon.AIRating > 0.5
		  && Instigator.Controller.Enemy.Health > 70 && Instigator.Controller.CanSee(Instigator.Controller.Enemy) && NoArtifactsActive() && FRand() < 0.7 )
		Activate();
}

function Timer()
{
	if(needsIdentify && Weapon != None)
	{
		Weapon.Identify();
		needsIdentify=false;
	}
	setTimer(0, true);
}

state Activated
{
    function Tick(float deltaTime)
    {
	    if (bActive )
	    {
	        if(weapon != none)
	        {
		        if ( InstigatorController.Adrenaline <= 0.0)
		        {
			        InstigatorController.Adrenaline = 0.0;
			        UsedUp();
			        return;
	            }
	            InstigatorController.Adrenaline -= deltaTime * CostPerSec;
	        }
	        else gotostate('');
        }
    }

	function BeginState()
	{
		local Vehicle V;
		local RPGWeapon aWeapon;
		if(bActive)
			return;

		V = Vehicle(Instigator);
		if (V != None && V.Driver != None)
			RealInstigator = V.Driver;
		else
			RealInstigator = Instigator;
		bActive = true;

		aWeapon = RPGWeapon(RealInstigator.Weapon);
		if (aWeapon != None)
		{
		    oldmodifier= aWeapon.Modifier;
			aWeapon.Modifier = aWeapon.Modifier * 2;
			if(rw_protection(aweapon)!=none )
			{
			    if(oldmodifier > 8)
			        return;
                if( aweapon.modifier > 9 )
			    {
			        costpersec = 2 * default.costpersec - int(float(aweapon.modifier) / 9.0 * float(default.costpersec) );
			        costpersec = clamp(costpersec, 0, default.costpersec);
			        aweapon.Modifier = 9;
			    }
			}
			else costpersec = default.CostPerSec;
			needsIdentify = true;
			setTimer(1, true);

			Weapon = aWeapon;
			oldCanThrow = aWeapon.bCanThrow;
			aWeapon.bCanThrow = false;
			aWeapon.ModifiedWeapon.bCanThrow = false;
		}
	}

	function EndState()
	{
	    if(weapon != none)
	    {
		    Weapon.Modifier = oldmodifier;
		    Weapon.bCanThrow = oldCanThrow;
		    Weapon.ModifiedWeapon.bCanThrow = oldCanThrow;
		    needsIdentify = true;
		    setTimer(1, true);
		}

		super.EndState();
	}
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

defaultproperties
{
     CostPerSec=12
     Index=6
     IconMaterial=TexPanner'XGameShaders.PlayerShaders.PlayerTransPanRed'
     ItemName="Double Magic Modifier"
}

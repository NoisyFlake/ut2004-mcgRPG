class artifactTripleDamage extends RPGArtifact;

var() Weapon LastWeapon;
var() bool ddhack;   //hack for incompatible function vehicle.hasudamage()

replication
{
	reliable if( Role==ROLE_Authority )
		ClientSetUDamageTime;
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

function Activate()
{
	if (!bActive && Instigator != None && Instigator.HasUDamage())
		return;

	Super.Activate();
}

function bool HandlePickupQuery(Pickup Item)
{
	if (Super.HandlePickupQuery(Item))
		return true;
	if (UDamagePack(Item) != None && bActive)
	{
	    ActivatedTime = -1000000;
		Activate();
	}

	return false;
}

simulated function ClientSetUDamageTime(float NewUDam, xpawn p)
{
	p.UDamageTime = Level.TimeSeconds + NewUDam;
}

state Activated
{
	function BeginState()
	{
		local Vehicle V;

		Instigator.DamageScaling *= 1.5;
		V = Vehicle(Instigator);
		if (V != None && V.Driver != None)
		{
			V.Driver.EnableUDamage(1000000.f);
			if(xpawn(v.Driver) != none)
			    ClientSetUDamageTime(xpawn(v.Driver).UDamageTime - Level.TimeSeconds, xpawn(v.Driver));       //hmmm
			if(!instigator.HasUDamage() )
			{
			    instigator.DamageScaling *= 2.0;
			    ddhack = true;
            }
		}
		else
			Instigator.EnableUDamage(1000000.f);
		bActive = true;
	}

	function EndState()
	{
		local Vehicle V;
		local actor a;

		if (Instigator != None)
		{
		    if(ddhack)
		    {
			    Instigator.DamageScaling /= 3.0;
			    ddhack = false;
		    }
		    else
			    Instigator.DamageScaling /= 1.5;
			V = Vehicle(Instigator);
			if (V != None && V.Driver != None)
			{
				V.Driver.DisableUDamage();
			    if(xpawn(v.Driver) != none)
			    {
                    a = owner;
			        if(!bnetowner)
			            setowner(instigatorcontroller);
	                ClientSetUDamageTime(-1, xpawn(v.Driver));
	                if(a != owner)
	                    setowner(a);
                }
			}
			else
				Instigator.DisableUDamage();
		}
		super.EndState();
	}
}

defaultproperties
{
     CostPerSec=7
     Index=8
     PickupClass=Class'mcgRPG1_9_9_1.ArtifactTripleDamagePickup'
     IconMaterial=Texture'UTRPGTextures.Icons.TripleDamageIcon'
     ItemName="Triple Damage"
}

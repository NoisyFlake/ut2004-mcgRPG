//-----------------------------------------------------------
//
//-----------------------------------------------------------
class nullentropyInv extends Inventory;

var() Shader ModifierOverlay;
var() int Modifier;
var() Sound NullEntropySound;
var() bool bKarma,bcanturn,bcanfly;

replication
{
    reliable if(role == role_authority)
        Modifier;
}

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	if(Other == None)
	{
		destroy();
		return;
	}

	if(Other.Controller != None && PlayerController(Other.Controller) != None)
		PlayerController(Other.Controller).ReceiveLocalizedMessage(class'nullentropyConditionMessage', 0);
	Other.PlaySound(NullEntropySound,,1.5 * Other.TransientSoundVolume,,Other.TransientSoundRadius);
	Other.setOverlayMaterial(ModifierOverlay, LifeSpan, true);
    Other.bCollideWorld=true;

	Super.GiveTo(Other);
}

simulated function postnetbeginplay()
{
    if(role == role_authority)
    {
        modifier = rw_nullentropy(instigator.Weapon).Modifier;
        instigator = pawn(owner);
    }
    bKarma = (instigator != none && instigator.Physics == phys_karma);
    if(bkarma)
    {
        if(karmaparams(instigator.KParams)!=none)
		{
		    bcanturn=karmaparams(instigator.KParams).bKAllowRotate;
		    bcanfly=karmaparams(instigator.KParams).bKStayUpright;
		}
    }

    if(bkarma || role == role_authority)
    {
	    if(Modifier < 7)
	    {
		    LifeSpan = (Modifier / 3) + ((7 - Modifier) * 0.1);
		    settimer(0.1,true);
	    }
	    else
		    LifeSpan = (Modifier / 3);
	    instigator.SetPhysics(PHYS_None);
	    enable('Tick');
    }
    else disable('tick');
}

simulated function Tick(float deltaTime)
{
	if(!class'rw_Freeze'.static.canTriggerPhysics(Pawn(Owner) ) )
		return;

	if(instigator != None && instigator.Physics != PHYS_NONE)
		instigator.setPhysics(PHYS_NONE);
}

simulated function destroyed()
{
	disable('Tick');
	if(instigator != None )
	{
        if(instigator.Physics == PHYS_NONE)
        {
		    if(bkarma)
		    {
		        instigator.SetPhysics(phys_karma);
                if(karmaparams(instigator.KParams)!=none)
		            instigator.KSetStayUpright(bcanfly,bcanturn);
		    }
		    else if(role == role_authority)
		        instigator.SetPhysics(PHYS_Falling);
        }
	}
	super.destroyed();
}

simulated function Timer()
{
	if(LifeSpan <= (7 - Modifier) * 0.1)
	{
		SetTimer(0, false);
		disable('Tick');
		if(!bkarma)
		    instigator.SetPhysics(PHYS_Falling);
	}
}

defaultproperties
{
     ModifierOverlay=Shader'MutantSkins.Shaders.MutantGlowShader'
     NullEntropySound=SoundGroup'WeaponSounds.Translocator.TranslocatorModuleRegeneration'
     bOnlyRelevantToOwner=False
     bAlwaysRelevant=True
     bReplicateInstigator=True
}

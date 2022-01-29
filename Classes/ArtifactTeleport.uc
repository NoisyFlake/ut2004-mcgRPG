class ArtifactTeleport extends RPGArtifact;

var() Emitter myEmitter;
var() float AdrenalineUsed;



function BotConsider()
{
	if (bActive)
		return;

	if ( (Instigator.Health + Instigator.ShieldStrength < 0.4*instigator.HealthMax || (Bot(Instigator.Controller) != None &&
    Bot(Instigator.Controller).NeedWeapon() ) ) && (Instigator.Controller.Enemy == None || !Instigator.Controller.CanSee(Instigator.Controller.Enemy) ) &&
    (Instigator.Controller.Adrenaline > 2 * CostPerSec || NoArtifactsActive()) )
		Activate();
}

function DoEffect();



function Activate()
{
    if(statsinv!=none)
    {
        statsinv.activateplayer();
        statsinv.deactivatespawnprotection();
    }
	if (bActivatable )
	{
		if (bActive && Level.TimeSeconds > ActivatedTime + MinActivationTime)
			GotoState('');
		else if (!bActive && Instigator != None && Instigator.Controller != None)
		{
			if (Instigator.Controller.Adrenaline >= CostPerSec * MinActivationTime )
			{
				ActivatedTime = Level.TimeSeconds;
				GotoState('Activated');
			}
			else if (Instigator.Controller.Adrenaline < CostPerSec * MinActivationTime )
				Instigator.ReceiveLocalizedMessage(MessageClass, 1, None, None, Class);
		}
	}
}


state Activated
{
	function BeginState()
	{
		local int x;

		myEmitter = spawn(class'teleportchargeeffect', Instigator,, Instigator.Location, Instigator.Rotation);
		myEmitter.SetBase(Instigator);
		if (Instigator.PlayerReplicationInfo != None && Instigator.PlayerReplicationInfo.Team != None && Instigator.PlayerReplicationInfo.Team.TeamIndex == 1)
			for (x = 0; x < myEmitter.Emitters[0].ColorScale.Length; x++)
				myEmitter.Emitters[0].ColorScale[x].Color = class'Hud'.default.BlueColor;

		bActive = true;
		AdrenalineUsed = CostPerSec;
	}

	simulated function Tick(float deltaTime)
	{
		local float Cost;

		Cost = FMin(AdrenalineUsed, deltaTime * CostPerSec);
		AdrenalineUsed -= Cost;
		if (AdrenalineUsed <= 0.f)
		{
			//take the last bit of adrenaline from the player
			//add a tiny bit extra to fix float precision issues
			Instigator.Controller.Adrenaline -= Cost - 0.001;
			DoEffect();
		}
		else
		{
			Global.Tick(deltaTime);
		}
	}

	function DoEffect()
	{
		local NavigationPoint Dest;
		local vector PrevLocation;
		local int EffectNum;
	    local bool bcanturn,bcanfly,bkarma,bcanmove;
	    local asturret t;
	    local onsmanualgunpawn o;
	    local vector hitlocation;
	    local pawn oldinstigator;

		if (myEmitter != None)
		{
			myEmitter.SetBase(None);
			myEmitter.Kill();
			myEmitter = None;
		}
        t=asturret(instigator);
        o=onsmanualgunpawn(instigator);
		Dest = Instigator.Controller.FindRandomDest();
		PrevLocation = Instigator.Location;
		oldinstigator = instigator;
		if(dest!=none)
		{
		    if(instigator.Physics==phys_karma )
            {
                if(karmaparams(instigator.KParams)!=none)
		        {
		            bcanturn=karmaparams(instigator.KParams).bKAllowRotate;
		            bcanfly=karmaparams(instigator.KParams).bKStayUpright;
                }
		        instigator.SetPhysics(phys_none);
		        bkarma=true;
            }
		    hitlocation=Dest.Location + vect(0,0,40);
		    Instigator.SetLocation(hitlocation);
		    if(oldinstigator == none)
		        return;
            if(t!=none )
            {
                if(t.TurretBase!=none)
                {
                    bcanmove=t.TurretBase.bMovable;
                    t.TurretBase.bMovable=true;
                    t.TurretBase.SetLocation(HitLocation);
                    t.TurretBase.bMovable=bcanmove;
                }
                if(t.TurretSwivel!=none)
                    t.TurretSwivel.SetLocation(HitLocation);
                clientteleport(t,hitlocation);
            }
            else if(o!=none && o.Gun!=none)
            {
                o.Gun.SetLocation(hitlocation);
                clientteleport(o.Gun, hitlocation);
            }
		    if(bkarma)
		    {
		        oldinstigator.SetPhysics(phys_karma);
                if(karmaparams(oldinstigator.KParams)!=none)
		            oldinstigator.KSetStayUpright(bcanfly,bcanturn);
            }
		}
		if (xPawn(oldInstigator) != None)
			xPawn(oldInstigator).DoTranslocateOut(PrevLocation);
		if (oldInstigator.PlayerReplicationInfo != None && oldInstigator.PlayerReplicationInfo.Team != None)
			EffectNum = oldInstigator.PlayerReplicationInfo.Team.TeamIndex;
		oldInstigator.SetOverlayMaterial(class'TransRecall'.default.TransMaterials[EffectNum], 1.0, false);
		oldInstigator.PlayTeleportEffect(false, false);

		GotoState('');
	}

	function EndState()
	{
		if (myEmitter != None)
			myEmitter.Destroy();
		super.EndState();
	}
}

function clientteleport(actor a, vector newloc)
{
local int i;
for(i=0;i< RPGMut.statsinves.Length;i++)
RPGMut.statsinves[i].clientteleport(a,newloc);
}

defaultproperties
{
     CostPerSec=25
     MinActivationTime=1.000000
     Index=2
     PickupClass=Class'mcgRPG1_9_9_1.ArtifactTeleportPickup'
     IconMaterial=Texture'UTRPGTextures.Icons.TeleporterIcon'
     ItemName="Teleporter"
}

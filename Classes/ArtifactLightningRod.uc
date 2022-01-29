class ArtifactLightningRod extends RPGArtifact;

var() float TargetRadius;
var() int DamagePerHit;
var() class<xEmitter> HitEmitterClass;

function BotConsider()
{
	if (Instigator.Controller.Adrenaline < 30)
		return;

	if (bActive && (Instigator.Controller.Enemy == None || !Instigator.Controller.CanSee(Instigator.Controller.Enemy)))
		Activate();
	else if ( !bActive && Instigator.Controller.Enemy != None
		  && Instigator.Controller.Enemy.Health < 70 && Instigator.Controller.CanSee(Instigator.Controller.Enemy) && NoArtifactsActive() && FRand() < 0.7 )
		Activate();
}

state Activated
{
	function Timer()
	{
		local Controller C, NextC;
		local int Targets;
		local xEmitter HitEmitter;

		//need to be moving for it to do anything... so can't just sit somewhere and camp
		if (VSize(Instigator.Velocity) ~= 0)
		{
			CostPerSec = default.CostPerSec;
			return;
		}

		C = Level.ControllerList;
		while (C != None)
		{
			// get next controller here because C may be destroyed if it's a nonplayer and C.Pawn is killed
			NextC = C.NextController;
			if ( C.Pawn != None && C.Pawn != Instigator && C.Pawn.Health > 0 &&
                !C.SameTeamAs(InstigatorController) && VSize(C.Pawn.Location - Instigator.Location) < TargetRadius &&
                FastTrace(C.Pawn.Location, Instigator.Location) )
			{
				HitEmitter = spawn(HitEmitterClass,,, Instigator.Location, rotator(C.Pawn.Location - Instigator.Location));
				if (HitEmitter != None)
					HitEmitter.mSpawnVecA = C.Pawn.Location;
				C.Pawn.TakeDamage(DamagePerHit, Instigator, C.Pawn.Location, vect(0,0,0), class'damtypeLightningRod');
				Targets++;
			}
			C = NextC;
		}

		CostPerSec = default.CostPerSec + Targets * 3;
	}

	function BeginState()
	{
		SetTimer(0.5, true);
		bActive = true;
	}

	function EndState()
	{
		SetTimer(0, false);
		super.EndState();
	}
}

defaultproperties
{
     TargetRadius=2000.000000
     DamagePerHit=5
     HitEmitterClass=Class'XEffects.LightningBolt'
     CostPerSec=5
     Index=7
     PickupClass=Class'mcgRPG1_9_9_1.ArtifactLightningRodPickup'
     IconMaterial=Texture'UTRPGTextures.Icons.LightningIcon'
     ItemName="Lightning Rod"
}

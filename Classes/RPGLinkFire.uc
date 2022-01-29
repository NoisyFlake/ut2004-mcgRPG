//Hack fix for Link Gun so you can link with RPGWeapons that have LinkGun as their ModifiedWeapon
class RPGLinkFire extends LinkFire;

function bool IsLinkable(Actor Other)
{
    local Pawn P;
    local LinkGun LG;
    local LinkFire LF;
    local int sanity;

    if (Pawn(Other) != none && Other.bProjTarget)
    {
        P = Pawn(Other);

        if(LinkGun(P.Weapon) == none && (RPGWeapon(P.Weapon) == None || LinkGun(RPGWeapon(P.Weapon).ModifiedWeapon) == none) )
	    {
		    if (Vehicle(P) != None)
			    return P.TeamLink(Instigator.GetTeamNum());
		    return false;
	    }

        LG = LinkGun(P.Weapon);
        if (LG == None)
        	LG = LinkGun(RPGWeapon(P.Weapon).ModifiedWeapon);
        LF = LinkFire(LG.GetFireMode(1));
        while (LF != None && LF.LockedPawn != None && LF.LockedPawn != P && sanity < 32)
        {
            if (LF.LockedPawn == Instigator)
                return false;
            LG = LinkGun(LF.LockedPawn.Weapon);
            if (LG == None)
            {
            	if (RPGWeapon(LF.LockedPawn.Weapon) != None)
            		LG = LinkGun(RPGWeapon(LF.LockedPawn.Weapon).ModifiedWeapon);
            	if (LG == None)
	                break;
	        }
            LF = LinkFire(LG.GetFireMode(1));
            sanity++;
        }
        LG = LinkGun(P.Weapon);
        if (LG == None)
        	LG = LinkGun(RPGWeapon(P.Weapon).ModifiedWeapon);
        LF = LinkFire(LG.GetFireMode(0));
        while (LF != None && LF.LockedPawn != None && LF.LockedPawn != P && sanity < 32)
        {
            if (LF.LockedPawn == Instigator)
                return false;
            LG = LinkGun(LF.LockedPawn.Weapon);
            if (LG == None)
            {
            	if (RPGWeapon(LF.LockedPawn.Weapon) != None)
            		LG = LinkGun(RPGWeapon(LF.LockedPawn.Weapon).ModifiedWeapon);
            	if (LG == None)
	                break;
	        }
            LF = LinkFire(LG.GetFireMode(0));
            sanity++;
        }

        return (Level.Game.bTeamGame && P.GetTeamNum() == Instigator.GetTeamNum());
    }
    return false;
}

function bool AddLink(int Size, Pawn Starter)
{
    local Inventory Inv;
    if (LockedPawn != None && !bFeedbackDeath)
    {
        if (LockedPawn == Starter)
        {
            return false;
        }
        else
        {
	        for (Inv = LockedPawn.Inventory; Inv != None; Inv = Inv.Inventory)
            {
            	if (LinkGun(Inv) != None)
            		break;
            	else if (RPGWeapon(Inv) != None && LinkGun(RPGWeapon(Inv).ModifiedWeapon) != None)
            	{
            		Inv = RPGWeapon(Inv).ModifiedWeapon;
            		break;
            	}
            }
            if (Inv != None)
            {
                if (LinkFire(LinkGun(Inv).GetFireMode(1)) != none && LinkFire(LinkGun(Inv).GetFireMode(1)).AddLink(Size, Starter))
                    LinkGun(Inv).Links += Size;
                else if (LinkFire(LinkGun(Inv).GetFireMode(0)) != none && LinkFire(LinkGun(Inv).GetFireMode(0)).AddLink(Size, Starter))
                    LinkGun(Inv).Links += Size;
                else
                    return false;
            }
        }
    }
    return true;
}

function RemoveLink(int Size, Pawn Starter)
{
    local Inventory Inv;
    if (LockedPawn != None && !bFeedbackDeath)
    {
        if (LockedPawn != Starter)
        {
            for (Inv = LockedPawn.Inventory; Inv != None; Inv = Inv.Inventory)
            {
            	if (LinkGun(Inv) != None)
            		break;
            	else if (RPGWeapon(Inv) != None && LinkGun(RPGWeapon(Inv).ModifiedWeapon) != None)
            	{
            		Inv = RPGWeapon(Inv).ModifiedWeapon;
            		break;
            	}
            }
            if (Inv != None)
            {
                if(LinkFire(LinkGun(Inv).GetFireMode(1)) != none)
                    LinkFire(LinkGun(Inv).GetFireMode(1)).RemoveLink(Size, Starter);
                else if(LinkFire(LinkGun(Inv).GetFireMode(0)) != none)
                    LinkFire(LinkGun(Inv).GetFireMode(0)).RemoveLink(Size, Starter);
                LinkGun(Inv).Links -= Size;
            }
        }
    }
}

simulated function bool AllowFire()
{
    return ( instigator != none && weapon != none && Weapon.AmmoAmount(ThisModeNum) >= AmmoPerFire);
}

function ModeDoFire()
{
    if (!AllowFire())
        return;

    if (MaxHoldTime > 0.0)
        HoldTime = FMin(HoldTime, MaxHoldTime);

    // server
    if (Weapon.Role == ROLE_Authority)
    {
        DoFireEffect();
		HoldTime = 0;	// if bot decides to stop firing, HoldTime must be reset first
        if ( (Instigator == None) || (Instigator.Controller == None) )
			return;

        if ( AIController(Instigator.Controller) != None )
            AIController(Instigator.Controller).WeaponFireAgain(BotRefireRate, true);

        Instigator.DeactivateSpawnProtection();
    }

    // client
    if (Instigator.IsLocallyControlled())
    {
        ShakeView();
        PlayFiring();
        FlashMuzzleFlash();
        StartMuzzleSmoke();
    }
    else // server
    {
        ServerPlayFiring();
    }
    if(rpgweapon(instigator.Weapon) != none)
        instigator.Weapon.IncrementFlashCount(ThisModeNum);
    else
        Weapon.IncrementFlashCount(ThisModeNum);

    // set the next firing time. must be careful here so client and server do not get out of sync
    if (bFireOnRelease)
    {
        if (bIsFiring)
            NextFireTime += MaxHoldTime + FireRate;
        else
            NextFireTime = Level.TimeSeconds + FireRate;
    }
    else
    {
        NextFireTime += FireRate;
        NextFireTime = FMax(NextFireTime, Level.TimeSeconds);
    }

    Load = AmmoPerFire;
    HoldTime = 0;

    if (Instigator.PendingWeapon != Weapon && Instigator.PendingWeapon != None)
    {
        bIsFiring = false;
        Weapon.PutDown();
    }
}

simulated function ModeTick(float dt)
{
	local Vector StartTrace, EndTrace, V, X, Y, Z;
	local Vector HitLocation, HitNormal, EndEffect;
	local Actor Other;
	local Rotator Aim;
	local LinkGun LinkGun;
	local float Step, ls;
	local bot B;
	local bool bShouldStop, bIsHealingObjective, bRPGlink;
	local int AdjustedDamage;
	local LinkBeamEffect LB;
	local DestroyableObjective HealObjective;
	local Vehicle LinkedVehicle;
	local rpgweapon rw;

    if ( !bIsFiring )
    {
		bInitAimError = true;
        return;
    }

    LinkGun = LinkGun(Weapon);
    bRPGlink = ( rpgweapon(instigator.Weapon) != none && rpgweapon(instigator.Weapon).modifiedweapon == LinkGun);
    if(bRPGlink)
    {
        rw = rpgweapon(instigator.Weapon);
    }

    if ( LinkGun.Links < 0 )
    {
        log("warning:"@Instigator@"linkgun had"@LinkGun.Links@"links");
        LinkGun.Links = 0;
    }

    ls = LinkScale[Min(LinkGun.Links,5)];

    if ( myHasAmmo(LinkGun) && ((UpTime > 0.0) || (Instigator.Role < ROLE_Authority)) )
    {
        UpTime -= dt;

		// the to-hit trace always starts right in front of the eye
		LinkGun.GetViewAxes(X, Y, Z);
		StartTrace = GetFireStart( X, Y, Z);
        TraceRange = default.TraceRange + LinkGun.Links*250;

        if ( Instigator.Role < ROLE_Authority )
        {
			if ( Beam == None )
				ForEach Weapon.DynamicActors(class'LinkBeamEffect', LB )
					if ( !LB.bDeleteMe && (LB.Instigator != None) && (LB.Instigator == Instigator) )
					{
						Beam = LB;
						break;
					}

			if ( Beam != None )
				LockedPawn = Beam.LinkedPawn;
		}

        if ( LockedPawn != None )
			TraceRange *= 1.5;

        if ( Instigator.Role == ROLE_Authority )
		{
		    if ( bDoHit )
		    {
                if( bRPGlink )
                    instigator.Weapon.ConsumeAmmo(ThisModeNum, AmmoPerFire);
                else
			        LinkGun.ConsumeAmmo(ThisModeNum, AmmoPerFire);
		    }

			B = Bot(Instigator.Controller);
			if ( (B != None) && (PlayerController(B.Squad.SquadLeader) != None) && (B.Squad.SquadLeader.Pawn != None) )
			{
				if ( IsLinkable(B.Squad.SquadLeader.Pawn)
					&& (B.Squad.SquadLeader.Pawn.Weapon != None && B.Squad.SquadLeader.Pawn.Weapon.GetFireMode(1).bIsFiring)
					&& (VSize(B.Squad.SquadLeader.Pawn.Location - StartTrace) < TraceRange) )
				{
					Other = Weapon.Trace(HitLocation, HitNormal, B.Squad.SquadLeader.Pawn.Location, StartTrace, true);
					if ( Other == B.Squad.SquadLeader.Pawn )
					{
						B.Focus = B.Squad.SquadLeader.Pawn;
						if ( B.Focus != LockedPawn )
							SetLinkTo(B.Squad.SquadLeader.Pawn);
						B.SetRotation(Rotator(B.Focus.Location - StartTrace));
 						X = Normal(B.Focus.Location - StartTrace);
 					}
 					else if ( B.Focus == B.Squad.SquadLeader.Pawn )
						bShouldStop = true;
				}
 				else if ( B.Focus == B.Squad.SquadLeader.Pawn )
					bShouldStop = true;
			}
		}

		if ( LockedPawn != None )
		{
			EndTrace = LockedPawn.Location + LockedPawn.BaseEyeHeight*Vect(0,0,0.5);
			if ( Instigator.Role == ROLE_Authority )
			{
				V = Normal(EndTrace - StartTrace);
				if ( (V dot X < LinkFlexibility) || LockedPawn.Health <= 0 || LockedPawn.bDeleteMe || (VSize(EndTrace - StartTrace) > 1.5 * TraceRange) )
				{
					SetLinkTo( None );
				}
			}
		}

        if ( LockedPawn == None )
        {
            if ( Bot(Instigator.Controller) != None )
            {
				if ( bInitAimError )
				{
					CurrentAimError = AdjustAim(StartTrace, AimError);
					bInitAimError = false;
				}
				else
				{
					BoundError();
					CurrentAimError.Yaw = CurrentAimError.Yaw + Instigator.Rotation.Yaw;
				}


				Step = 7500.0 * dt;
				if ( DesiredAimError.Yaw ClockWiseFrom CurrentAimError.Yaw )
				{
					CurrentAimError.Yaw += Step;
					if ( !(DesiredAimError.Yaw ClockWiseFrom CurrentAimError.Yaw) )
					{
						CurrentAimError.Yaw = DesiredAimError.Yaw;
						DesiredAimError = AdjustAim(StartTrace, AimError);
					}
				}
				else
				{
					CurrentAimError.Yaw -= Step;
					if ( DesiredAimError.Yaw ClockWiseFrom CurrentAimError.Yaw )
					{
						CurrentAimError.Yaw = DesiredAimError.Yaw;
						DesiredAimError = AdjustAim(StartTrace, AimError);
					}
				}
				CurrentAimError.Yaw = CurrentAimError.Yaw - Instigator.Rotation.Yaw;
				if ( BoundError() )
					DesiredAimError = AdjustAim(StartTrace, AimError);
				CurrentAimError.Yaw = CurrentAimError.Yaw + Instigator.Rotation.Yaw;

				if ( Instigator.Controller.Target == None )
					Aim = Rotator(Instigator.Controller.FocalPoint - StartTrace);
				else
					Aim = Rotator(Instigator.Controller.Target.Location - StartTrace);

				Aim.Yaw = CurrentAimError.Yaw;

				// save difference
				CurrentAimError.Yaw = CurrentAimError.Yaw - Instigator.Rotation.Yaw;
			}
			else
	            Aim = GetPlayerAim(StartTrace, AimError);

            X = Vector(Aim);
            EndTrace = StartTrace + TraceRange * X;
        }

        Other = Weapon.Trace(HitLocation, HitNormal, EndTrace, StartTrace, true);
        if ( Other != None && Other != Instigator )
			EndEffect = HitLocation;
		else
			EndEffect = EndTrace;

		if ( Beam != None )
			Beam.EndEffect = EndEffect;

		if ( Instigator.Role < ROLE_Authority )
		{
			if ( LinkAttachment(LinkGun.ThirdPersonActor) != None )
			{
                if(bRPGlink)
                    instigator.Weapon = LinkGun;
				if ( LinkGun.Linking || (Other != None && Instigator.PlayerReplicationInfo != None && Instigator.PlayerReplicationInfo.Team != None &&
                    Other.TeamLink(Instigator.PlayerReplicationInfo.Team.TeamIndex)) )
				{
					if (Instigator.PlayerReplicationInfo == None || Instigator.PlayerReplicationInfo.Team == None || Instigator.PlayerReplicationInfo.Team.TeamIndex == 1)
						LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Blue );
					else
						LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Red );
				}
				else
				{
					if ( LinkGun.Links > 0 )
						LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Gold );
					else
						LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Green );
				}
                if(bRPGlink)
                    instigator.Weapon = rw;
			}
			return;
		}
        if ( Other != None && Other != Instigator )
        {
            // target can be linked to
            if ( IsLinkable(Other) )
            {
                if ( Other != lockedpawn )
                    SetLinkTo( Pawn(Other) );

                if ( lockedpawn != None )
                    LinkBreakTime = LinkBreakDelay;
            }
            else
            {
                // stop linking
                if ( lockedpawn != None )
                {
                    if ( LinkBreakTime <= 0.0 )
                        SetLinkTo( None );
                    else
                        LinkBreakTime -= dt;
                }

                // beam is updated every frame, but damage is only done based on the firing rate
                if ( bDoHit )
                {
                    if ( Beam != None )
						Beam.bLockedOn = false;

                    Instigator.MakeNoise(1.0);

                    AdjustedDamage = AdjustLinkDamage( LinkGun, Other, Damage );

                    if ( !Other.bWorldGeometry )
                    {
                        if ( Level.Game.bTeamGame && Pawn(Other) != None && Pawn(Other).PlayerReplicationInfo != None
							&& Pawn(Other).PlayerReplicationInfo.Team == Instigator.PlayerReplicationInfo.Team) // so even if friendly fire is on you can't hurt teammates
                            AdjustedDamage = 0;

						HealObjective = DestroyableObjective(Other);
						if ( HealObjective == None )
							HealObjective = DestroyableObjective(Other.Owner);
						if ( HealObjective != None && HealObjective.TeamLink(Instigator.GetTeamNum()) )
						{
							SetLinkTo(None);
							bIsHealingObjective = true;
							if (!HealObjective.HealDamage(AdjustedDamage, Instigator.Controller, DamageType))
			                {
                                if( bRPGlink )
                                    instigator.Weapon.ConsumeAmmo(ThisModeNum, -AmmoPerFire);
                                else
				                    LinkGun.ConsumeAmmo(ThisModeNum, -AmmoPerFire);
			                }
						}
						else
							Other.TakeDamage(AdjustedDamage, Instigator, HitLocation, MomentumTransfer*X, DamageType);

						if ( Beam != None )
							Beam.bLockedOn = true;
					}
				}
			}
		}

		// vehicle healing
		LinkedVehicle = Vehicle(LockedPawn);
		if ( LinkedVehicle != None && bDoHit )
		{
			AdjustedDamage = Damage * (1.5*Linkgun.Links+1) * Instigator.DamageScaling;
			if (Instigator.HasUDamage())
				AdjustedDamage *= 2;
			if (!LinkedVehicle.HealDamage(AdjustedDamage, Instigator.Controller, DamageType) )
			{
                if( bRPGlink )
                    instigator.Weapon.ConsumeAmmo(ThisModeNum, -AmmoPerFire);
                else
				    LinkGun.ConsumeAmmo(ThisModeNum, -AmmoPerFire);
			}
		}
		LinkGun(Weapon).Linking = (LockedPawn != None) || bIsHealingObjective;

		if ( bShouldStop )
			B.StopFiring();
		else
		{
			// beam effect is created and destroyed when firing starts and stops
			if ( (Beam == None) && bIsFiring )
			{
				Beam = Weapon.Spawn( BeamEffectClass, Instigator );
				// vary link volume to make sure it gets replicated (in case owning player changed it client side)
				if ( SentLinkVolume == Default.LinkVolume )
					SentLinkVolume = Default.LinkVolume + 1;
				else
					SentLinkVolume = Default.LinkVolume;
			}

			if ( Beam != None )
			{
				if ( LinkGun.Linking || ( Other != None && Instigator.PlayerReplicationInfo != None && Instigator.PlayerReplicationInfo.Team != None &&
                    Other.TeamLink(Instigator.PlayerReplicationInfo.Team.TeamIndex) ) )
				{
				    if(Instigator != none && Instigator.PlayerReplicationInfo != none && Instigator.PlayerReplicationInfo.Team != none)
					    Beam.LinkColor = Instigator.PlayerReplicationInfo.Team.TeamIndex + 1;
				    else Beam.LinkColor = 2;
					if ( LinkAttachment(LinkGun.ThirdPersonActor) != None )
					{
					    if(bRPGlink)
					        instigator.Weapon = LinkGun;
						if ( Instigator.PlayerReplicationInfo == None || Instigator.PlayerReplicationInfo.Team == None || Instigator.PlayerReplicationInfo.Team.TeamIndex == 0 )
							LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Red );
						else
							LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Blue );
					    if(bRPGlink)
					        instigator.Weapon = rw;
					}
				}
				else
				{
					Beam.LinkColor = 0;
					if ( LinkAttachment(LinkGun.ThirdPersonActor) != None )
					{
					    if(bRPGlink)
					        instigator.Weapon = LinkGun;
						if ( LinkGun.Links > 0 )
							LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Gold );
						else
							LinkAttachment(LinkGun.ThirdPersonActor).SetLinkColor( LC_Green );
					    if(bRPGlink)
					        instigator.Weapon = rw;
					}
				}

				Beam.Links = LinkGun.Links;
				Instigator.AmbientSound = BeamSounds[Min(Beam.Links,3)];
				Instigator.SoundVolume = SentLinkVolume;
				Beam.LinkedPawn = LockedPawn;
				Beam.bHitSomething = (Other != None);
				Beam.EndEffect = EndEffect;
			}
		}
    }
    else
        StopFiring();

    bStartFire = false;
    bDoHit = false;
}

defaultproperties
{
}

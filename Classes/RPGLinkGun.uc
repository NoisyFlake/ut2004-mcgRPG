//Hack fix for Link Gun so you can link RPGWeapons that have LinkGun as their ModifiedWeapon
class RPGLinkGun extends LinkGun
	CacheExempt;



function bool LinkedTo(LinkGun L)
{
	local Pawn Other;
	local LinkGun OtherWeapon, Head;
	local int sanity;

	Head = self;
	while (Head != None && Head.Linking && sanity < 20)
	{
            Other = LinkFire(Head.FireMode[1]).LockedPawn;
            if (Other == None)
                return false;
            else
            {
                OtherWeapon = LinkGun(Other.Weapon);
                if (OtherWeapon == None && RPGWeapon(Other.Weapon) != None)
                	OtherWeapon = LinkGun(RPGWeapon(Other.Weapon).ModifiedWeapon);
                if (OtherWeapon == None)
                    return false;
                else
                    Head = OtherWeapon;
            }
            if (Head == L)
            	return true;

            sanity++;
        }

        return false;
}

simulated function bool HasAmmo()
{
	return super(weapon).HasAmmo() || ( AmmoClass[0] != None && FireMode[0] != None && AmmoCharge[0] >= 1 );
}

function bool ConsumeAmmo(int Mode, float load, optional bool bAmountNeededIsMax)
{
	local Controller C;

	if (Linking && LinkFire(FireMode[1]).LockedPawn != None && Vehicle(LinkFire(FireMode[1]).LockedPawn) == None)
		return true;

	if ( mode == 0 )
		bAmountNeededIsMax = true;

	//use ammo from linking teammates
	if (Instigator != None && Instigator.PlayerReplicationInfo != None && Instigator.PlayerReplicationInfo.Team != None)
	{
		for (C = Level.ControllerList; C != None; C = C.NextController)
			if (C.Pawn != None && C.Pawn.Weapon != None)
			{
				if (LinkGun(C.Pawn.Weapon) != None && LinkGun(C.Pawn.Weapon).LinkedTo(self))
					LinkGun(C.Pawn.Weapon).LinkedConsumeAmmo(Mode, load, bAmountNeededIsMax);
				else if ( RPGWeapon(C.Pawn.Weapon) != None && LinkGun(RPGWeapon(C.Pawn.Weapon).ModifiedWeapon) != None
					  && LinkGun(RPGWeapon(C.Pawn.Weapon).ModifiedWeapon).LinkedTo(self) )
					LinkGun(RPGWeapon(C.Pawn.Weapon).ModifiedWeapon).LinkedConsumeAmmo(Mode, load, bAmountNeededIsMax);
			}
	}

	return Super(weapon).ConsumeAmmo(Mode, load, bAmountNeededIsMax);
}

simulated function bool StartFire(int Mode)
{
	local SquadAI S;
	local Bot B;
	local vector AimDir;

	if ( (Role == ROLE_Authority) && (PlayerController(Instigator.Controller) != None) && (UnrealTeamInfo(Instigator.PlayerReplicationInfo.Team) != None))
	{
		S = UnrealTeamInfo(Instigator.PlayerReplicationInfo.Team).AI.GetSquadLedBy(Instigator.Controller);
		if ( S != None )
		{
			AimDir = vector(Instigator.Controller.Rotation);
			for ( B=S.SquadMembers; B!=None; B=B.NextSquadMember )
				if ( (HoldSpot(B.GoalScript) == None)
					&& (B.Pawn != None)
					&& (LinkGun(B.Pawn.Weapon) != None || (RPGWeapon(B.Pawn.Weapon) != None && LinkGun(RPGWeapon(B.Pawn.Weapon).ModifiedWeapon) != None))
					&& B.Pawn.Weapon.FocusOnLeader(true)
					&& ((AimDir dot Normal(B.Pawn.Location - Instigator.Location)) < 0.9) )
				{
					B.Focus = Instigator;
					B.FireWeaponAt(Instigator);
				}
		}
	}
	return Super(weapon).StartFire(Mode);
}

function bool FocusOnLeader(bool bLeaderFiring)
{
	local Bot B;
	local Pawn LeaderPawn;
	local Actor Other;
	local vector HitLocation, HitNormal, StartTrace;
	local Vehicle V;

	B = Bot(Instigator.Controller);
	if ( B == None )
		return false;
	if ( PlayerController(B.Squad.SquadLeader) != None )
		LeaderPawn = B.Squad.SquadLeader.Pawn;
	else
	{
		V = B.Squad.GetLinkVehicle(B);
		if ( V != None )
		{
			LeaderPawn = V;
			bLeaderFiring = (LeaderPawn.Health < LeaderPawn.HealthMax) && (V.LinkHealMult > 0)
							&& ((B.Enemy == None) || V.bKeyVehicle);
		}
	}
	if ( LeaderPawn == None )
	{
		LeaderPawn = B.Squad.SquadLeader.Pawn;
		if ( LeaderPawn == None )
			return false;
	}
	if ( !bLeaderFiring && (LeaderPawn.Weapon == None || !LeaderPawn.Weapon.IsFiring()) )
		return false;
	if ( (Vehicle(LeaderPawn) != None)
		|| ( (LinkGun(LeaderPawn.Weapon) != None || (RPGWeapon(LeaderPawn.Weapon) != None && LinkGun(RPGWeapon(LeaderPawn.Weapon).ModifiedWeapon) != None))
		     && ((vector(B.Squad.SquadLeader.Rotation) dot Normal(Instigator.Location - LeaderPawn.Location)) < 0.9) ) )
	{
		StartTrace = Instigator.Location + Instigator.EyePosition();
		if ( VSize(LeaderPawn.Location - StartTrace) < LinkFire(FireMode[1]).TraceRange )
		{
			Other = Trace(HitLocation, HitNormal, LeaderPawn.Location, StartTrace, true);
			if ( Other == LeaderPawn )
			{
				B.Focus = Other;
				return true;
			}
		}
	}
	return false;
}

function float GetAIRating()
{
	local Bot B;
	local DestroyableObjective O;
	local Vehicle V;

	B = Bot(Instigator.Controller);
	if ( B == None )
		return AIRating;

	if ( (PlayerController(B.Squad.SquadLeader) != None)
		&& (B.Squad.SquadLeader.Pawn != None)
		&& ( LinkGun(B.Squad.SquadLeader.Pawn.Weapon) != None
		     || (RPGWeapon(B.Squad.SquadLeader.Pawn.Weapon) != None && LinkGun(RPGWeapon(B.Squad.SquadLeader.Pawn.Weapon).ModifiedWeapon) != None) ) )
		return 1.2;

	V = B.Squad.GetLinkVehicle(B);
	if ( (V != None)
		&& (VSize(Instigator.Location - V.Location) < 1.5 * LinkFire(FireMode[1]).TraceRange)
		&& (V.Health < V.HealthMax) && (V.LinkHealMult > 0) )
		return 1.2;

	if ( Vehicle(B.RouteGoal) != None && B.Enemy == None && VSize(Instigator.Location - B.RouteGoal.Location) < 1.5 * LinkFire(FireMode[1]).TraceRange
	     && Vehicle(B.RouteGoal).TeamLink(B.GetTeamNum()) )
		return 1.2;

	O = DestroyableObjective(B.Squad.SquadObjective);
	if ( O != None && B.Enemy == None && O.TeamLink(B.GetTeamNum()) && O.Health < O.DamageCapacity
	     && VSize(Instigator.Location - O.Location) < 1.1 * LinkFire(FireMode[1]).TraceRange && B.LineOfSightTo(O) )
		return 1.2;

	return AIRating * FMin(Pawn(Owner).DamageScaling, 1.5);
}

defaultproperties
{
     FireModeClass(1)=Class'mcgRPG1_9_9_1.RPGLinkFire'
     PickupClass=Class'mcgRPG1_9_9_1.RPGLinkGunPickup'
     AttachmentClass=Class'mcgRPG1_9_9_1.RPGLinkAttachment'
}

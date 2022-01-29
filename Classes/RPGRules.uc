class RPGRules extends GameRules;

var() MutMCGRPG RPGMut;
var() int PointsPerLevel;
var() float LevelDiffExpGainDiv;
var() float MA_AdjustDamageByVehicleScale; // hack for Monster Assault and EXP by damage
var() bool bAwardedFirstBlood;
var() bool domhack;
var() controller dom[2];
var() byte bcheckafk;
var() byte loopkill;
var() float spawnprotectiontime; //spawn protection hack
var() string someonestring;
var() float counter;
var() playerreplicationinfo pri[2]; //0 - killer, 1 - killed
var() float adrenaline;
var() float Score[2];
var() float Deaths[2];
var() int NumLives[2];
var() byte bOutOfLives[2];
var() int Kills[2];
var() float starttime,endtime;
var() class<xdeathmessage> message;
var() array<GameObjective> objectives;


replication
{
	reliable if ( Role == ROLE_Authority)
		message;
}

delegate resetcount0();
delegate resetcount1();

function PostBeginPlay()
{
	local GameObjective GO;


	SetTimer(Level.TimeDilation, true);
	//hack to deal with Assault's stupid hardcoded scoring setup
	if (Level.Game.IsA('ASGameInfo'))
		foreach AllActors(class'GameObjective', GO)
		{
		    if(destroyableobjective(go)!=none || holdobjective(go)!=none )
			    GO.Score = 0;
			else if(go.bOptionalObjective)
			    go.Score=5;
			else go.score=10;
        }
	foreach AllActors(class'GameObjective', GO)
	    if(!go.bBotOnlyObjective)
	        objectives[objectives.Length] = go;

	Super.PostBeginPlay();
	level.Game.bAllowVehicles=true;
	message = class<xdeathmessage>(level.Game.DeathMessageClass);
    if(message!=none)
        someonestring = message.default.SomeoneString;
}

function matchstarting()
{
    if( xdoubledom(level.Game)!=none && xdoubledom(level.Game).xDomPoints[0]!=none && xdoubledom(level.Game).xDomPoints[1]!=none)   //double domination hack
    {
        resetcount0 = xdoubledom(level.Game).xDomPoints[0].ResetCount;
        resetcount1 = xdoubledom(level.Game).xDomPoints[1].ResetCount;
        xdoubledom(level.Game).xDomPoints[0].ResetCount=resetcountdom0;
        xdoubledom(level.Game).xDomPoints[1].ResetCount=resetcountdom1;
    }
    starttime = level.TimeSeconds;
}

//---------- very ugly double dom hack

function resetcountdom0()
{
    local rpgstatsinv statsinv;

    if(domhack && ( !xdoubledom(level.Game).xDomPoints[0].bControllable || !xdoubledom(level.Game).xDomPoints[1].bControllable ) )
    {
        statsinv=none;
        if(dom[0]!=none )
        {
            statsinv=getstatsinvfor(dom[0]);
    		if (StatsInv != None)
		    {
			    StatsInv.DataObject.Experience += 15;
			    RPGMut.CheckLevelUp(StatsInv.DataObject,  dom[0].PlayerReplicationInfo);
	        }
        }
        statsinv=none;
        if(dom[1]!=none )
        {
            statsinv=getstatsinvfor(dom[1]);
    		if (StatsInv != None)
		    {
			    StatsInv.DataObject.Experience += 15;
			    RPGMut.CheckLevelUp(StatsInv.DataObject,  dom[1].PlayerReplicationInfo);
	        }
        }
		domhack=false;
		dom[0]=none;
		dom[1]=none;
    }
    if( xdoubledom(level.Game).xDomPoints[0].ControllingPawn != none )
        dom[0]=xdoubledom(level.Game).xDomPoints[0].ControllingPawn.controller;
    if( xdoubledom(level.Game).xDomPoints[1].ControllingPawn != none )
        dom[1]=xdoubledom(level.Game).xDomPoints[1].ControllingPawn.controller;
    domhack=false;
    ResetCount0();
}

function resetcountdom1()
{
    local rpgstatsinv statsinv;

    if(domhack && ( !xdoubledom(level.Game).xDomPoints[0].bControllable || !xdoubledom(level.Game).xDomPoints[1].bControllable ) )
    {
        statsinv=none;
        if(dom[0]!=none )
        {
            statsinv=getstatsinvfor(dom[0]);
    		if (StatsInv != None)
		    {
			    StatsInv.DataObject.Experience += 15;
			    RPGMut.CheckLevelUp(StatsInv.DataObject,  dom[0].PlayerReplicationInfo);
	        }
        }
        statsinv=none;
        if(dom[1]!=none )
        {
            statsinv=getstatsinvfor(dom[1]);
    		if (StatsInv != None)
		    {
			    StatsInv.DataObject.Experience += 15;
			    RPGMut.CheckLevelUp(StatsInv.DataObject,  dom[1].PlayerReplicationInfo);
	        }
        }
		domhack=false;
		dom[0]=none;
		dom[1]=none;
    }
    if( xdoubledom(level.Game).xDomPoints[0].ControllingPawn != none )
        dom[0]=xdoubledom(level.Game).xDomPoints[0].ControllingPawn.controller;
    if( xdoubledom(level.Game).xDomPoints[1].ControllingPawn != none )
        dom[1]=xdoubledom(level.Game).xDomPoints[1].ControllingPawn.controller;
    domhack=false;
    ResetCount1();
}

//------------------------------


static function RPGStatsInv GetStatsInvFor(Controller C)
{
	local Inventory Inv;
	local rpgstatsinv statsinv;
	local pawn p;
    if(c==none)
        return none;
	for (Inv = C.Inventory; Inv != None; Inv = Inv.Inventory)
		if ( RPGStatsInv(inv)!=none )
			return RPGStatsInv(Inv);

	    //fallback - shouldn't happen
    p=c.pawn;
    if(p!=none)
    {
        Inv = P.FindInventoryType(class'RPGStatsInv');
        if ( Inv != None )
            return RPGStatsInv(Inv);
        else if( vehicle(p)!=none && vehicle(p).Driver!=none)
        {
            p=vehicle(p).Driver;
            Inv = P.FindInventoryType(class'RPGStatsInv');
            if ( Inv != None )
                return RPGStatsInv(Inv);
        }
    }
    else
    {
        foreach c.childactors(class'pawn',p)
            break;
        if(p!=none)
        {
            Inv = P.FindInventoryType(class'RPGStatsInv');
            if ( Inv != None )
                return RPGStatsInv(Inv);
        }
        else
        {
            foreach c.dynamicactors(class'rpgstatsinv',statsinv)
                if(statsinv.ownerc==c || statsinv.owner==c)
            return statsinv;
        }
    }
    return None;
}

//checks if the player that owns the specified RPGStatsInv is linked up to anybody and if so shares Amount EXP
//equally between them, otherwise gives it all to the lone player
function ShareExperience(RPGStatsInv InstigatorInv, float Amount, optional int cap, optional pawn p)
{
	local LinkGun HeadLG, LG;
	local Controller C;
	local RPGStatsInv StatsInv;
	local array<RPGStatsInv> Links;
	local int i;

    if(Level.Game.bGameRestarted || Level.Game.bGameEnded)
        return;

	if(p == none && instigatorinv.ownerc != none )
        p = instigatorinv.ownerc.Pawn;
	if (p == None || p.Weapon == None)
	{
		// dead or has no weapon, so can't be linked up
		if (p != None)
            InstigatorInv.DataObject.AddExperienceFraction(Amount, RPGMut, p.PlayerReplicationInfo);
		else
            InstigatorInv.DataObject.AddExperienceFraction(Amount, RPGMut, InstigatorInv.OwnerC.PlayerReplicationInfo);
	}
	else
	{
		HeadLG = LinkGun(p.Weapon);
		if (HeadLG == None && rpgweapon(p.Weapon)!=none)
			HeadLG = LinkGun(RPGWeapon(p.Weapon).ModifiedWeapon);
		if (HeadLG == None)
			// Instigator is not using a Link Gun
            InstigatorInv.DataObject.AddExperienceFraction(Amount, RPGMut, p.PlayerReplicationInfo);
		else
		{
			//create a list of everyone that should share the EXP
			Links[0] = InstigatorInv;
			for (C = Level.ControllerList; C != None; C = C.NextController)
			{
				if (C.Pawn != None && C.Pawn.Weapon != None)
				{
					LG = LinkGun(C.Pawn.Weapon);
					if (LG == None && RPGWeapon(C.Pawn.Weapon) != None)
						LG = LinkGun(RPGWeapon(C.Pawn.Weapon).ModifiedWeapon);
					if (LG != None && (LG.LinkedTo(HeadLG) || (RPGWeapon(p.Weapon) != none && RPGWeapon(p.Weapon).LinkedTo(lg) ) ) )
					{
						//this player is linked, find the RPGStatsInv
						StatsInv = GetStatsInvFor(C);
						if (StatsInv != None)
                            Links[Links.length] = StatsInv;
					}
				}
			}

			// share the experience among the linked players
			for (i = 0; i < Links.length; i++)
			{
			    if(cap>0 && links[i].DataObject.Level >= cap && i>0 )
                    Links[i].DataObject.AddExperienceFraction( 1 / Links.length, RPGMut, Links[i].Instigator.PlayerReplicationInfo);
                else if(i>0)
                    Links[i].DataObject.AddExperienceFraction(Amount / Links.length, RPGMut, Links[i].Instigator.PlayerReplicationInfo,cap);
                else
                    Links[i].DataObject.AddExperienceFraction(Amount / Links.length, RPGMut, Links[i].Instigator.PlayerReplicationInfo);
			}
		}
	}
}

// award EXP based on damage done
function AwardEXPForDamage(Controller InstigatedBy, RPGStatsInv InstigatedStatsInv, Pawn injured, float Damage, optional pawn p)
{
	if(instigatedby!=none && injured!=none && InstigatedBy != injured.Controller && InstigatedStatsInv != None &&
        MonsterController(injured.controller)!=none && Monster(injured) != none )
	{
		//if the game is MonsterAssault and it's a vehicle hitting a monster, scale damage
		if (Level.Game.IsA('MonsterAssault') && Vehicle(InstigatedBy.Pawn) != None)
			Damage *= MA_AdjustDamageByVehicleScale;
		//cap to how much health monster has left so we don't hand out too much EXP
		Damage = FMin(Damage, injured.Health);
		ShareExperience(InstigatedStatsInv, Damage / injured.HealthMax * Monster(injured).ScoringValue,, p);
	}
}

function bool CriticalPlayer(Controller Other)
{
    local gameobjective o;
    if(!other.bIsPlayer || other.Pawn==none || teamgame(level.Game)==none )
        return super.CriticalPlayer(other);
    for( o=teamgame(level.game).Teams[0].AI.Objectives;o!=none;o=o.NextObjective )
        if( o.IsActive() && other.GetTeamNum()!=o.DefenderTeamIndex && vsize(other.Pawn.Location-o.Location ) <= 1500 &&
            unrealmpgameinfo(level.Game).CanDisableObjective(o) )
		    return true;

	return super.CriticalPlayer(other);
}

function ScoreKill(Controller Killer, Controller Killed)
{
	local RPGPlayerDataObject KillerData, KilledData;
	local int x, LevelDifference;
	local Inventory Inv, NextInv;
	local RPGStatsInv StatsInv, KillerStatsInv;
	local vector TossVel, U, V, W;
	local bool teamscorehack;
	local turretmarker tm;
	local pawn killerpawn;

	if (Killed == None)
	{
		Super.ScoreKill(Killer, Killed);
		loopkill=0;
		return;
	}

	//make killed pawn drop any artifacts he's got
	if (Killed.Pawn != None)
	{
	    Killed.Pawn.HitDamageType = none; //to reduce unnecessary replication
		Inv = Killed.Pawn.Inventory;
		while (Inv != None && x < 1000)
		{
		    x++;
			NextInv = Inv.Inventory;
			if (RPGArtifact(Inv) != None)
			{
				TossVel = Vector(Killed.Pawn.GetViewRotation());
				TossVel = TossVel * ((Killed.Pawn.Velocity Dot TossVel) + 500) + Vect(0,0,200);
				TossVel += VRand() * (100 + Rand(250));
				Inv.Velocity = TossVel;
				Killed.Pawn.GetAxes(Killed.Pawn.Rotation, U, V, W);
				Inv.DropFrom(Killed.Pawn.Location + 0.8 * Killed.Pawn.CollisionRadius * U - 0.5 * Killed.Pawn.CollisionRadius * V);
			}
			Inv = NextInv;
		}
	}

	Super.ScoreKill(Killer, Killed);

	if(killer!=none && !killer.bIsPlayer)
	{
	    if(vehicle(killer.Pawn)==none || killed == killer )
	    {
	        loopkill=0;
	        return;
	    }
	    tm=turretmarker(killer.Pawn.FindInventoryType(class'turretmarker') );
	    if(tm==none || tm.instigatorcontroller==none || tm.instigatorcontroller==killed )
	    {
	        loopkill=0;
	        return;
	    }
	    killerpawn = killer.Pawn;
        killer=tm.instigatorcontroller;
        if( Killer.PlayerReplicationInfo!=none )
        {
            loopkill++;
            if(loopkill==1)
            {
                for(x = 0; x < 2; x++)
                {
                    if(pri[x] != none)
                    {
                        pri[x].Score = Score[x];
                        pri[x].Deaths = Deaths[x];
                        pri[x].NumLives = NumLives[x];
                        pri[x].bOutOfLives = bool(bOutOfLives[x]);
                        pri[x].Kills = Kills[x];
                    }
                }
                if(adrenaline > -1)
                    killed.Adrenaline = adrenaline;
                class'turretdamtype'.default.myturret = vehicle(killerpawn);
                RPGMut.bTurretHack = true;
                if( (MonsterController(killed) != none || Monster(killed.pawn) != none) && level.Game.IsA('Invasion') )
                    level.Game.SetPropertyText("nummonsters", string(int(level.Game.GetPropertyText("nummonsters") ) + 1) );
                level.Game.Killed(killer,killed,killed.pawn,class'turretdamtype');
            }
        }
        loopkill=0;
        return;
	}
	//EXP for killing nonplayer pawns
	//note: most monster EXP is awarded in NetDamage(); this just notifies abilities and awards an extra 1 EXP
	//to make sure the killer got at least 1 total (plus it's an easy way to know who got the final blow)
	if (!killed.bIsPlayer)
	{
	    if(killer!=none)
	        KillerStatsInv = GetStatsInvFor(Killer);
        if( (level.Game.Class == class'xDeathMatch' || level.Game.Class == class'xTeamGame') && pri[0] != none)
        {
            pri[0].Score = Score[0];
            pri[0].Kills = Kills[0];
        }
		if (KillerStatsInv != None && KillerStatsInv.DataObject != none)
		{
			KillerData = KillerStatsInv.DataObject;
			for (x = 0; x < KillerData.Abilities.length; x++)
                KillerData.Abilities[x].static.ScoreKill(Killer, Killed, true, KillerData.AbilityLevels[x]);
            ShareExperience(KillerStatsInv, 1.0,,killerpawn);

		}
		loopkill=0;
		return;
	}

    if(class'turretdamtype'.default.myturret != none)
    {
        killerpawn = class'turretdamtype'.default.myturret;
        class'turretdamtype'.default.myturret = none;
        RPGMut.bTurretHack = false;
    }
	// if this player is now out of the game, find the lowest level player that remains
	if (Killed.PlayerReplicationInfo != None && Killed.PlayerReplicationInfo.bOutOfLives)
		RPGMut.FindCurrentLowestLevelPlayer();

	StatsInv = GetStatsInvFor(Killed);

	if (Killer == None || killer == killed)
	{
	    if( StatsInv != none && StatsInv.LastHitBy!=none && StatsInv.LastHitBy!=killed )
        {
	        killer=StatsInv.LastHitBy;
	        if( killed.SameTeamAs(killer) && statsinv.team != none && statsinv.team.TeamIndex == killed.GetTeamNum() )
	        {
	            loopkill=0;
	            return;
            }
	        teamscorehack = true;
            loopkill++;
            if(loopkill==1)
            {
                for(x = 0; x < 2; x++)
                {
                    if(pri[x] != none)
                    {
                        pri[x].Score = Score[x];
                        pri[x].Deaths = Deaths[x];
                        pri[x].NumLives = NumLives[x];
                        pri[x].bOutOfLives = bool(bOutOfLives[x]);
                        pri[x].Kills = Kills[x];
                    }
                }
                if(adrenaline > -1)
                    killed.Adrenaline = adrenaline;
                if(  Monster(killed.pawn) != none && level.Game.IsA('Invasion') )
                    level.Game.SetPropertyText("nummonsters", string(int(level.Game.GetPropertyText("nummonsters") ) + 1) );
                if( statsinv.team != none && killer.PlayerReplicationInfo != none && killed.PlayerReplicationInfo != none &&
                    killed.PlayerReplicationInfo.Team == killer.PlayerReplicationInfo.Team &&
                    killed.PlayerReplicationInfo.Team != statsinv.team )
                {
                    killed.PlayerReplicationInfo.Team = statsinv.team;
                    level.Game.Killed(killer,killed,killed.pawn,class'suicidekilldamage');
                    killed.PlayerReplicationInfo.Team = killer.PlayerReplicationInfo.Team;
                }
                else
                    level.Game.Killed(killer,killed,killed.pawn,class'suicidekilldamage');
            }
        }
        loopkill=0;
        return;
	}
	loopkill=0;


	if ( !teamscorehack && Killer.PlayerReplicationInfo != None && Killer.PlayerReplicationInfo.Team != None && Killed.PlayerReplicationInfo != None &&
        Killer.PlayerReplicationInfo.Team == Killed.PlayerReplicationInfo.Team )
		return;

    if(StatsInv != none)
    {
	    KilledData = StatsInv.DataObject;
	    for (x = 0; x < KilledData.Abilities.length; x++)
		    KilledData.Abilities[x].static.ScoreKill(Killer, Killed, false, KilledData.AbilityLevels[x]);
	}
    KillerStatsInv = GetStatsInvFor(Killer);
	if (KillerStatsInv == None)
		return;
    if(	KillerStatsInv.afk && RPGMut.bcheckafk > 0 && killerstatsinv.Instigator != none &&
        ( killerstatsinv.Instigator.LastStartTime < level.TimeSeconds - 1.5) )
        return;
	KillerData = KillerStatsInv.DataObject;

    if(teamgame(level.Game)!=none && teamgame(level.Game).CriticalPlayer(killed) )
        ShareExperience(KillerStatsInv, 5,, killerpawn);  //need it before spawnkill check 'cause of small maps like ctf-1on1-joust


	for (x = 0; x < KillerData.Abilities.length; x++)
		KillerData.Abilities[x].static.ScoreKill(Killer, Killed, true, KillerData.AbilityLevels[x]);
	// against extreme levelup by spawnkill
	if ( Killed.Pawn != None && ( ( ( Level.TimeSeconds - Killed.Pawn.LastStartTime ) < 2.5 ) || ( teamgame(level.game) != none &&
        level.Game.Class!=class'xteamgame' && ( ( Level.TimeSeconds - Killed.Pawn.LastStartTime ) < 6.0 ) ) ||
        ( level.TimeSeconds < ( killed.Pawn.SpawnTime + SpawnProtectionTime ) ) ) )
	    return;


    if(killeddata != none)
    {
	    LevelDifference = Max(0, KilledData.Level - KillerData.Level);
	    if (LevelDifference > 0)
		    LevelDifference = int(float(LevelDifference*LevelDifference) / LevelDiffExpGainDiv);
        //cap gained exp to enough to get to Killed's level
	    if (KilledData.Level - KillerData.Level > 0 && LevelDifference > (KilledData.Level - KillerData.Level) * KilledData.NeededExp)
		    LevelDifference = (KilledData.Level - KillerData.Level) * KilledData.NeededExp;

        if( statsinv.afk && bcheckafk > 0)
	        leveldifference=0;
        ShareExperience(KillerStatsInv, 1.0 + LevelDifference, killeddata.level,killerpawn);
    }
    else
        ShareExperience(KillerStatsInv, 1.0,,killerpawn);


	//bonus experience for multikills
	if (UnrealPlayer(Killer) != None && UnrealPlayer(Killer).MultiKillLevel > 0)
		ShareExperience( KillerStatsInv, Min(Square(float(UnrealPlayer(Killer).MultiKillLevel)), RPGMut.maxmultikillexp) ,,killerpawn);
	else if (AIController(Killer) != None && Killer.Pawn != None && Killer.Pawn.Inventory != None)
		Killer.Pawn.Inventory.OwnerEvent('RPGScoreKill'); //hack to record multikills for bots (handled by RPGStatsInv)

	//bonus experience for sprees
	if (Killer.Pawn != None && Killer.Pawn.GetSpree() % 5 == 0)
		ShareExperience( KillerStatsInv,  min(2 * Killer.Pawn.GetSpree(), RPGMut.maxmultikillexp) ,,killerpawn);

	//bonus experience for ending someone else's spree
	if (Killed.Pawn != None && Killed.Pawn.GetSpree() > 4)
		ShareExperience( KillerStatsInv,  min(Killed.Pawn.GetSpree() * 5 , 5 * RPGMut.maxmultikillexp) ,,killerpawn);

	//bonus experience for first blood
	if (!bAwardedFirstBlood && TeamPlayerReplicationInfo(Killer.PlayerReplicationInfo) != None &&
        TeamPlayerReplicationInfo(Killer.PlayerReplicationInfo).bFirstBlood)
	{
	    if(killeddata != none && ( !statsinv.afk || bcheckafk == 0) )
            ShareExperience( KillerStatsInv,  2 * Max(KilledData.Level - KillerData.Level, 5) ,,killerpawn);  // first blood min 10 exp:D
	    else ShareExperience( KillerStatsInv,  10 ,,killerpawn);
		bAwardedFirstBlood = true;
	}

	//level up
	RPGMut.CheckLevelUp(KillerData, Killer.PlayerReplicationInfo);
}

function AwardEXP(controller c, int exp)
{
    local rpgstatsinv statsinv;
    statsinv=none;
    if(c!=none && !level.Game.bgameended && !Level.Game.bGameRestarted)
        statsinv=getstatsinvfor(c);
    if(statsinv!=none && exp>0)
    {
        statsinv.DataObject.Experience+=exp;
        RPGMut.CheckLevelUp(statsinv.DataObject,c.playerreplicationinfo);
    }
}

//Give experience for game objectives
function ScoreObjective(PlayerReplicationInfo Scorer, Int Score)
{
	local RPGStatsInv StatsInv;

	if (Score >= 0 && Scorer != None && Scorer.Owner != None)
	{
		StatsInv = GetStatsInvFor(Controller(Scorer.Owner));
		if (StatsInv != None)
		    shareexperience(StatsInv, 2*Max(Score, 1) );     //double score
	}

	Super.ScoreObjective(Scorer, Score);

	// jailbreak execution hack - the victorious team's pawns are destroyed and respawned with no notification
	// so they'd lose their RPGStatsInv without this
	if (Level.Game.IsA('Jailbreak') &&
    Level.Game.IsInState('Executing') && Score == 1 && StatsInv != None)
	{
		StatsInv.OwnerDied();
	}
}

function checkviewshake(rpgstatsinv statsinv)
{
    if(statsinv!=none && statsinv.lasthittime < level.TimeSeconds-0.7)
    {
        statsinv.lasthittime = level.timeseconds;
        statsinv.setlasthittime();
    }
}

function DeactivateSpawnProtection(pawn p)
{
    if(xpawn(p)!=none)
        xpawn(p).bSpawnDone=false;
    if( deathmatch(level.Game).SpawnProtectionTime == -1.0)
        deathmatch(level.Game).SpawnProtectionTime=RPGMut.spawnprotectiontime;
    else
    {
        RPGMut.spawnprotectiontime = deathmatch(level.Game).SpawnProtectionTime;
        spawnprotectiontime = deathmatch(level.Game).SpawnProtectionTime;
    }
    p.DeactivateSpawnProtection();
    deathmatch(level.Game).SpawnProtectionTime=-1.0;
    if(xpawn(p)!=none)
        xpawn(p).bSpawnDone=false;
}

function int NetDamage(int OriginalDamage, int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local RPGPlayerDataObject InjuredData, InstigatedData;
	local RPGStatsInv InjuredStatsInv, InstigatedStatsInv, temp;
	local int x, MonsterLevel;
	local bool bZeroDamage;
	local playercontroller pc;
	local gameobjective o,g;
	local array<vehicle> turrets;
	local controller c;
    local inventory i;
    local rpgweapon w;

    if(asvehicle_spacefighter(injured)!=none && damagetype==class'damagetype' && instigatedby==injured && hitlocation==injured.Location &&
        momentum==vect(0,0,0) && originaldamage > 0 )
    {
        injured.Health=0;
        return 0;         //lol hack
    }
    if(vehicle(injured)!=none )
    {
        if(injured.Event != '' && injured.Event != 'none')
        {
	        for(x = 0; x < objectives.Length; x++)
	        {
	            o = objectives[x];
	            if( o.Tag == injured.Event && (DestroyVehicleObjective(o) != none || TriggeredObjective(o) != none) && o.IsActive() &&
                    !unrealmpgameinfo(level.Game).CanDisableObjective(o) && !o.bOptionalObjective )
	                return 0;
	        }
        }
    }

    if(asvehicle(injured)!=none)
        asvehicle(injured).DamLastDamageTime=level.TimeSeconds-1; //haha

    if(/*!PlatformIsWindows() && */damagetype == class'fell' && injured != none && injured.MaxFallSpeed == 0)
    {
        originaldamage = 0;
        damage = 0;            //hack against stupid division by zero bug on unix os
    }

    if(RPGMut.WeaponModifierChance > 0.0 && injured != none && RPGWeapon(Injured.Weapon) == none && Injured.Weapon != none &&
        !Injured.Weapon.bNoInstagibReplace)
    {
        for(i = Injured.Inventory; i != none; i = i.Inventory)
        {
            w = rpgweapon(i);
            if(w != none && w.ModifiedWeapon == Injured.Weapon)
            {
                if(w.TimerRate > 0.0)
                    w.SetTimer(0.0,false);
                if(w.bcheck)
                    w.bcheck = false;
                Injured.Weapon = w;
                break;
            }
        }
    }


    if(injured!=none  && ( (Level.TimeSeconds - injured.SpawnTime ) < SpawnProtectionTime) && ( (injured.Weapon!=none &&
        (injured.Weapon.IsFiring() || (injured.Weapon.GetFireMode(0) != none && injured.Weapon.GetFireMode(0).bInstantStop) ||
        (injured.Weapon.GetFireMode(1) != none && injured.Weapon.GetFireMode(1).bInstantStop) ) ) ||
        (injured.PlayerReplicationInfo != none && injured.PlayerReplicationInfo.HasFlag != none) ) )
        DeactivateSpawnProtection(injured);

    if(injured!=none && RPGWeapon(Injured.Weapon)!=none)
        RPGWeapon(Injured.Weapon).NewAdjustPlayerDamage(Damage, OriginalDamage, instigatedBy, HitLocation, Momentum, DamageType);

    if(injured!=none && injured.Controller!=none)
    {
	    if ( (Level.TimeSeconds - injured.SpawnTime ) < SpawnProtectionTime)
        {
            if( playercontroller(injured.Controller)!=none && momentum!=vect(0,0,0) && vehicle(injured) == none &&
                ( instigatedby==none || vehicle(instigatedby)!=none || instigatedby.Velocity == vect(0,0,0) ||
                ( ( vsize(injured.Velocity) > injured.GroundSpeed*0.5 ) &&
                ( ( normal(injured.Velocity) dot normal(instigatedby.Velocity) ) > -0.98 ) ) ||
                ( ( normal(injured.location - instigatedby.Location) dot normal(instigatedby.Velocity) ) < 0.98 ) ) )
            {
                foreach injured.TouchingActors(class'gameobjective',o)
                {
                    g = o;
                    break;
                }
                if(g==none)
                    momentum=vect(0,0,0);
            }
            return 0; //spawn protection hack.
        }
	    InjuredStatsInv = GetStatsInvFor(injured.Controller);
    }
    else
    {
        if(injured != none)
        {
	        if ( (instigatedby!=injured && ( (Level.TimeSeconds - injured.SpawnTime ) < SpawnProtectionTime) ) )
                return 0; //spawn protection hack.
            if( instigatedby != none && playercontroller(instigatedby.Controller)!=none )
            {
                c = controller(injured.Owner);
                if( (c == none || !c.bIsPlayer) && injured.DrivenVehicle != none)
                    c = injured.DrivenVehicle.Controller;
                if(c != none && !c.bIsPlayer)
                    c = none;
                if( vehicle(injured) != none)
                    turrets = vehicle(injured).GetTurrets();
                InjuredStatsInv = rpgstatsinv(injured.FindInventoryType(class'rpgstatsinv') );
                if(injuredstatsinv == none)
                    injuredstatsinv = getstatsinvfor(c);
                for(x = 0; x < turrets.Length; x++)
                {
                    if(turrets[x] != none && turrets[x].Controller != none && turrets[x].Controller.bIsPlayer && !instigatedby.Controller.SameTeamAs(turrets[x].Controller) )
                    {
                        temp = getstatsinvfor(turrets[x].Controller);
                        if(temp != none)
                            temp.LastHitBy = instigatedby.Controller;
                        turrets[x].LastHitBy = instigatedby.Controller;
                    }
                }
                if(!instigatedby.Controller.SameTeamAs(c) )
                {
                    if(injuredstatsinv!=none)
	                    injuredstatsinv.lasthitby=instigatedby.Controller;
	                injured.lasthitby=instigatedby.Controller;
	                if(injured.DrivenVehicle != none)
	                    injured.DrivenVehicle.LastHitBy = instigatedby.Controller;
	            }
            }
	        if(RPGMut.bEXPForHealing  && InjuredStatsInv != none)
	        {
                if( instigatedby == none || injured == instigatedby || ( level.Game.bTeamGame && (injured.GetTeamNum() == instigatedby.GetTeamNum() ) ) )
                {
                    if( instigatedby == none || rw_healer(InstigatedBy.Weapon) == none )
	                    InjuredStatsInv.blastdamageteam = true;
                }
                else InjuredStatsInv.blastdamageteam = false;
            }
        	if (InjuredStatsInv != None && injuredstatsinv.DataObject != none)
	        {
		        for (x = 0; x < injuredstatsinv.DataObject.Abilities.length; x++)
		            if(injuredstatsinv.DataObject.Abilities[x].default.bdefensive)
                        injuredstatsinv.DataObject.Abilities[x].static.HandleDamage
                        (Damage, injured, instigatedBy, Momentum, DamageType, false, injuredstatsinv.DataObject.AbilityLevels[x],InjuredStatsInv);
            }
	        if(injuredstatsinv!=none && instigatedby != none && playercontroller(instigatedby.Controller)!=none && level.TimeSeconds - injured.SpawnTime >= spawnprotectiontime)
            {
                if(!instigatedby.Controller.SameTeamAs(c) )
                {
	                injuredstatsinv.lasthitby=instigatedby.Controller;
	                injured.lasthitby=instigatedby.Controller;
	            }
            }
	    }
        return super.NetDamage(originaldamage,damage,injured,instigatedby,hitlocation ,momentum,damagetype);
    }

    pc=playercontroller(injured.Controller);

    if ( instigatedBy != None && instigatedBy.Controller != None)
    {
	    InstigatedStatsInv = GetStatsInvFor(instigatedBy.Controller);
	    if(InstigatedStatsInv !=none && bcheckafk > 0 && InstigatedStatsInv.afk && ( ( instigatedBy.Weapon!=none && (instigatedBy.Weapon.IsFiring() ||
            (instigatedBy.Weapon.GetFireMode(0) != none && instigatedBy.Weapon.GetFireMode(0).bInstantStop) ||
            (instigatedBy.Weapon.GetFireMode(1) != none && instigatedBy.Weapon.GetFireMode(1).bInstantStop) ) ) ||
            ( vehicle(instigatedBy)!=none && ( vehicle(instigatedBy).bWeaponisAltFiring || vehicle(instigatedBy).bWeaponisFiring ) ) ) )
            InstigatedStatsInv.activateplayer();
	    if(  bcheckafk > 0 && InstigatedStatsInv != none && InstigatedStatsInv.afk && instigatedby.SpawnTime < ( level.TimeSeconds - 1.5 ) )
	    {
	        momentum=vect(0,0,0);
	        super.NetDamage(originaldamage,0,injured,instigatedby,hitlocation ,momentum,damagetype);
	        return 0;
        }
	    if( playercontroller(instigatedby.Controller)!=none && instigatedby.Controller!=injured.Controller &&
            !instigatedby.Controller.SameTeamAs(injured.Controller) && level.TimeSeconds - injured.SpawnTime >= spawnprotectiontime)
        {
            if(injuredstatsinv!=none)
	            injuredstatsinv.lasthitby=instigatedby.Controller;
	        injured.lasthitby=instigatedby.Controller;
	        if(vehicle(injured) != none && vehicle(injured).Driver != none)
	            vehicle(injured).Driver.lasthitby=instigatedby.Controller;
        }
	    if ( injured.InGodMode() )
	        return 0;

        if(RPGMut.WeaponModifierChance > 0.0 && InstigatedBy != none && RPGWeapon(InstigatedBy.Weapon) == none && InstigatedBy.Weapon != none &&
            !InstigatedBy.Weapon.bNoInstagibReplace)
        {
            for(i = InstigatedBy.Inventory; i != none; i = i.Inventory)
            {
                w = rpgweapon(i);
                if(w != none && w.ModifiedWeapon == InstigatedBy.Weapon)
                {
                    if(w.TimerRate > 0.0)
                        w.SetTimer(0.0,false);
                    if(w.bcheck)
                        w.bcheck = false;
                    InstigatedBy.Weapon = w;
                    break;
                }
            }
        }

        if ( (DamageType.name == 'damtypebrutalshockbeam' || DamageType.name == 'damtypebrutalshockball' || DamageType.name == 'damtypebrutalshockcombo') &&
            xpawn(injured) != none )     //hehe
        {
		    //if this is weapon damage and the player doing the damage has an RPGWeapon, let it modify the damage
		    if( !injured.PhysicsVolume.bNeutralZone && ( teamgame(level.Game)==none || teamgame(level.game).FriendlyFireScale > 0 ||
                !injured.Controller.SameTeamAs(instigatedby.Controller) ) )
                damage=originaldamage;
            if ( RPGWeapon(InstigatedBy.Weapon) != None)
                RPGWeapon(InstigatedBy.Weapon).NewAdjustTargetDamage(Damage, OriginalDamage, Injured, HitLocation, Momentum, DamageType);
	        if(RPGMut.bEXPForHealing  && InjuredStatsInv != none)
	        {
                if( injured == instigatedby || ( level.Game.bTeamGame && (injured.GetTeamNum() == instigatedby.GetTeamNum() ) ) )
                {
                    if( rw_healer(InstigatedBy.Weapon) == none )
	                    InjuredStatsInv.blastdamageteam = true;
                }
                else InjuredStatsInv.blastdamageteam = false;
            }
            if(pc!=none)
                checkviewshake(injuredstatsinv);
            else AwardEXPForDamage(instigatedBy.Controller, InstigatedStatsInv, injured, Damage);
            return super.NetDamage(originaldamage,damage,injured,instigatedby,hitlocation ,momentum,damagetype);
        }
	    //get data
	    if (InstigatedStatsInv != None)
		    InstigatedData = InstigatedStatsInv.DataObject;

        if (InjuredStatsInv != None)
		    InjuredData = InjuredStatsInv.DataObject;

   	    if (DamageType.default.bSuperWeapon  )
	    {
		    //if this is weapon damage and the player doing the damage has an RPGWeapon, let it modify the damage
            if (ClassIsChildOf(DamageType, class'WeaponDamageType') && RPGWeapon(InstigatedBy.Weapon) != None)
                RPGWeapon(InstigatedBy.Weapon).NewAdjustTargetDamage(Damage, OriginalDamage, Injured, HitLocation, Momentum, DamageType);
	        if (InjuredData != None )
	        {
		        for (x = 0; x < InjuredData.Abilities.length; x++)
                    if(InjuredData.Abilities[x].default.bdefensive)
                        InjuredData.Abilities[x].static.HandleDamage(Damage, injured, instigatedBy, Momentum, DamageType, false, InjuredData.AbilityLevels[x],
                            InjuredStatsInv);
            }
	        if(RPGMut.bEXPForHealing  && InjuredStatsInv != none)
	        {
                if( injured == instigatedby || ( level.Game.bTeamGame && (injured.GetTeamNum() == instigatedby.GetTeamNum() ) ) )
                {
                    if( rw_healer(InstigatedBy.Weapon) == none )
	                    InjuredStatsInv.blastdamageteam = true;
                }
                else InjuredStatsInv.blastdamageteam = false;
            }
            if(pc!=none )
                checkviewshake(injuredstatsinv);
            else  AwardEXPForDamage(instigatedBy.Controller, InstigatedStatsInv, injured, Damage);
            return super.NetDamage(originaldamage,damage,injured,instigatedby,hitlocation ,momentum,damagetype);
        }

	    if ( Damage >= 1000 || ( ( classischildof(DamageType,class'damtypesupershockbeam') || DamageType.name == 'ZoomSuperShockBeamDamage' ||
            DamageType.name == 'damtypesupershockbeam') && xpawn(injured) != none ) )
        {
		    //if this is weapon damage and the player doing the damage has an RPGWeapon, let it modify the damage
            if (ClassIsChildOf(DamageType, class'WeaponDamageType') && RPGWeapon(InstigatedBy.Weapon) != None)
                RPGWeapon(InstigatedBy.Weapon).NewAdjustTargetDamage(Damage, OriginalDamage, Injured, HitLocation, Momentum, DamageType);
	        if (InjuredData != None )
	        {
		        for (x = 0; x < InjuredData.Abilities.length; x++)
                    if(InjuredData.Abilities[x].default.bdefensive)
                        InjuredData.Abilities[x].static.HandleDamage(Damage, injured, instigatedBy, Momentum, DamageType, false, InjuredData.AbilityLevels[x],
                            InjuredStatsInv);
            }
	        if(RPGMut.bEXPForHealing  && InjuredStatsInv != none)
	        {
                if( injured == instigatedby || ( level.Game.bTeamGame && (injured.GetTeamNum() == instigatedby.GetTeamNum() ) ) )
                {
                    if( rw_healer(InstigatedBy.Weapon) == none )
	                    InjuredStatsInv.blastdamageteam = true;
                }
                else InjuredStatsInv.blastdamageteam = false;
            }
            if(pc!=none)
                checkviewshake(injuredstatsinv);
            else
            {
                if(rpgturretcontroller(instigatedBy.Controller) == none || rpgturretcontroller(instigatedBy.Controller).mymarker == none ||
                    rpgturretcontroller(instigatedBy.Controller).mymarker.instigatorcontroller == none )
                AwardEXPForDamage(instigatedBy.Controller, InstigatedStatsInv, injured, Damage);
                else AwardEXPForDamage(rpgturretcontroller(instigatedBy.Controller).mymarker.instigatorcontroller,
                    getstatsinvfor(rpgturretcontroller(instigatedBy.Controller).mymarker.instigatorcontroller), injured, Damage, instigatedBy);
            }
            return super.NetDamage(originaldamage,damage,injured,instigatedby,hitlocation ,momentum,damagetype);
        }

	    if (Damage <= 0)
	    {
		    Damage = Super.NetDamage(OriginalDamage, Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);
		    if (Damage < 0)
			    return Damage;
	        else if (Damage == 0) //for zero damage, still process abilities/magic weapons so effects relying on hits instead of damage still work
			    bZeroDamage = true;
	    }

        if (InstigatedData == None || InjuredData == None)
	    {
		    if (Invasion(Level.Game) != none)
		    {
		        if (RPGMut.bAutoAdjustMonsterLevel > ma_normal)
		        {
		            if( injureddata!=none )
				        MonsterLevel = Max(0, (injureddata.Attack*2+injureddata.Defense*2+int(float(injureddata.HealthBonus)/1.5) +
                            int(float(injureddata.WeaponSpeed)*2.5) ) * RPGMut.InvasionAutoAdjustFactor);
		            else if(instigateddata!=none)
				        MonsterLevel = Max(0, (instigateddata.Attack*2+instigateddata.Defense*2+
                            int(float(instigateddata.HealthBonus)/1.5)+int(float(instigateddata.WeaponSpeed)*2.5) ) *
                            RPGMut.InvasionAutoAdjustFactor);
                    monsterlevel/=pointsperlevel;
		        }
		        else
		            MonsterLevel = 0;
			    MonsterLevel += (Invasion(Level.Game).WaveNum + 1) * 2;
	        }
		    else if ( ( RPGMut.bAutoAdjustMonsterLevel == ma_normal || RPGMut.bAutoAdjustMonsterLevel == ma_all ) &&
                ( injureddata!=none || instigateddata!=none ) )
		    {
		        if( injureddata!=none )
		            monsterlevel = injureddata.Attack*2+injureddata.Defense*2+int(float(injureddata.HealthBonus)/1.5) +
                        int(float(injureddata.WeaponSpeed)*2.5);
                else monsterlevel =
                    instigateddata.Attack*2+instigateddata.Defense*2+int(float(instigateddata.HealthBonus)/1.5)+
                        int(float(instigateddata.WeaponSpeed)*2.5);
                monsterlevel/=pointsperlevel;
            }
		    else
		    {
                if (RPGMut.CurrentLowestLevelPlayer != None)
			        MonsterLevel = RPGMut.CurrentLowestLevelPlayer.Level - 1;
                else
			        MonsterLevel = 0;
            }
			monsterlevel=max(monsterlevel,0);
		    if ( InstigatedData == None && !instigatedby.Controller.bIsPlayer )
		    {
			    InstigatedData = RPGPlayerDataObject(Level.ObjectPool.AllocateObject(class'RPGPlayerDataObject'));
			    InstigatedData.Attack = MonsterLevel  * PointsPerLevel / 4;
			    InstigatedData.Defense = InstigatedData.Attack;
			    InstigatedData.Level = MonsterLevel + 1;
	        }
		    if ( InjuredData == None && !injured.Controller.bIsPlayer )
		    {
			    InjuredData = RPGPlayerDataObject(Level.ObjectPool.AllocateObject(class'RPGPlayerDataObject'));
			    InjuredData.Attack = MonsterLevel  * PointsPerLevel / 4;
			    InjuredData.Defense = InjuredData.Attack;
			    InjuredData.Level = MonsterLevel + 1;
            }
        }

	    if ( InjuredData == None)
	    {
            //if this is weapon damage and the player doing the damage has an RPGWeapon, let it modify the damage
	        if (ClassIsChildOf(DamageType, class'WeaponDamageType') && RPGWeapon(InstigatedBy.Weapon) != None)
                RPGWeapon(InstigatedBy.Weapon).NewAdjustTargetDamage(Damage, OriginalDamage, Injured, HitLocation, Momentum, DamageType);
	        if(pc!=none)
	            checkviewshake(injuredstatsinv);
            return super.NetDamage(originaldamage,damage,injured,instigatedby,hitlocation ,momentum,damagetype);
        }
        if( InstigatedData != None )
        {
            if( InstigatedData.Attack > InjuredData.Defense )
	            Damage = int(float(Damage) * (1.0 + float(InstigatedData.Attack) * 0.01 - float(InjuredData.Defense) * 0.01 ) );
            else if( InstigatedData.Attack < InjuredData.Defense )
	            Damage = int(float(Damage) / (1.0 + float(InjuredData.Defense) * 0.01 - float(InstigatedData.Attack) * 0.01 ) );
            if (Damage < 1 && !bZeroDamage)
		        Damage = 1;

            //if this is weapon damage and the player doing the damage has an RPGWeapon, let it modify the damage
	        if (ClassIsChildOf(DamageType, class'WeaponDamageType') && RPGWeapon(InstigatedBy.Weapon) != None)
                RPGWeapon(InstigatedBy.Weapon).NewAdjustTargetDamage(Damage, OriginalDamage, Injured, HitLocation, Momentum, DamageType);
	        if(RPGMut.bEXPForHealing  && InjuredStatsInv != none)
	        {
                if( injured == instigatedby || ( level.Game.bTeamGame && (injured.GetTeamNum() == instigatedby.GetTeamNum() ) ) )
                {
                    if( rw_healer(InstigatedBy.Weapon) == none )
	                    InjuredStatsInv.blastdamageteam = true;
                }
                else InjuredStatsInv.blastdamageteam = false;
            }
            //headshot bonus EXP
	        if ( damage > 0 && InstigatedStatsInv != None && !instigatedBy.Controller.SameTeamAs(injured.Controller) &&
                ( DamageType.Name == 'DamTypeSniperHeadShot' || DamageType.Name == 'DamTypeclassicHeadShot' || DamageType.Name == 'DamTypeShotgunHeadshot' ||
                ( instigatedby.Weapon != none &&
                (
                (instigatedby.Weapon.GetFireMode(0) != none && instigatedby.Weapon.GetFireMode(0).bIsFiring &&
                (instigatedby.Weapon.GetFireMode(0).GetPropertyText("DamageTypeHeadShot") ~= ("class'"$string(DamageType)$"'" ) ) ) ||
                (instigatedby.Weapon.GetFireMode(1) != none && instigatedby.Weapon.GetFireMode(1).bIsFiring &&
                (instigatedby.Weapon.GetFireMode(1).GetPropertyText("DamageTypeHeadShot") ~= ("class'"$string(DamageType)$"'" ) ) )
                )
                )
                )
                )
            {
	            if ( DamageType.Name == 'DamTypeSniperHeadShot' )
	                instigateddata.AddExperienceFraction(1.5,RPGMut, instigatedby.PlayerReplicationInfo );     //lightning headshot more exp;)
                else
	            {
		            InstigatedData.Experience++;
		            RPGMut.CheckLevelUp(InstigatedData, InstigatedBy.PlayerReplicationInfo);
	            }
            }

	        if(injuredstatsinv!= none && injuredstatsinv.afk && bcheckafk > 0)
	        {
	            if (bZeroDamage || damage==0)
	            {
	                super.NetDamage(originaldamage,0,injured,instigatedby,hitlocation ,momentum,damagetype);
		            return 0;
	            }
	            else
	            {
                    if(pc!=none )
                        checkviewshake(injuredstatsinv);
                    return super.NetDamage(originaldamage,damage,injured,instigatedby,hitlocation ,momentum,damagetype);
                }
            }
        }
        else
        {

            //if this is weapon damage and the player doing the damage has an RPGWeapon, let it modify the damage
	        if (ClassIsChildOf(DamageType, class'WeaponDamageType') && RPGWeapon(InstigatedBy.Weapon) != None)
                RPGWeapon(InstigatedBy.Weapon).NewAdjustTargetDamage(Damage, OriginalDamage, Injured, HitLocation, Momentum, DamageType);
	        if (InjuredStatsInv != None && (!injuredstatsinv.afk || ( bcheckafk == 0 ) ) )
	        {
		        for (x = 0; x < InjuredData.Abilities.length; x++)
                    InjuredData.Abilities[x].static.HandleDamage(Damage, injured, instigatedBy, Momentum, DamageType, false, InjuredData.AbilityLevels[x],
                    InjuredStatsInv);
            }
	        else Level.ObjectPool.FreeObject(InjuredData);
            if(pc!=none )
                checkviewshake(injuredstatsinv);
            return super.NetDamage(originaldamage,damage,injured,instigatedby,hitlocation ,momentum,damagetype);
        }
    }
    else
    {
	    if ( injured.InGodMode() )
	        return 0;
	    if (InjuredStatsInv != None)
	    {
		    InjuredData = InjuredStatsInv.DataObject;
	        if(RPGMut.bEXPForHealing )
	        {
                if(instigatedby == none || injured == instigatedby || ( level.Game.bTeamGame && (injured.GetTeamNum() == instigatedby.GetTeamNum() ) ) )
                {
                    if( instigatedby == none || rw_healer(InstigatedBy.Weapon) == none )
	                    InjuredStatsInv.blastdamageteam = true;
                }
                else InjuredStatsInv.blastdamageteam = false;
            }
        }
	    if (InjuredData != None )
	    {
		    for (x = 0; x < InjuredData.Abilities.length; x++)
		        if(InjuredData.Abilities[x].default.bdefensive)
                    InjuredData.Abilities[x].static.HandleDamage(Damage, injured, instigatedBy, Momentum, DamageType, false, InjuredData.AbilityLevels[x],
                    InjuredStatsInv);
        }
        if(pc!=none )
            checkviewshake(injuredstatsinv);
        return super.NetDamage(originaldamage,damage,injured,instigatedby,hitlocation ,momentum,damagetype);
    }

	//Allow Abilities to react to damage
	if (InstigatedStatsInv != None)
	{
		for (x = 0; x < InstigatedData.Abilities.length; x++)
            InstigatedData.Abilities[x].static.HandleDamage
                (Damage, injured, instigatedBy, Momentum, DamageType, true, InstigatedData.AbilityLevels[x],InstigatedStatsInv);
	}
	else if( InstigatedData!=none)
		Level.ObjectPool.FreeObject(InstigatedData);
	if (InjuredStatsInv != None && (!injuredstatsinv.afk || ( bcheckafk == 0 ) ) )
	{
		for (x = 0; x < InjuredData.Abilities.length; x++)
            InjuredData.Abilities[x].static.HandleDamage
                (Damage, injured, instigatedBy, Momentum, DamageType, false, InjuredData.AbilityLevels[x],InjuredStatsInv);
	}
	else if( InjuredData != none )
		Level.ObjectPool.FreeObject(InjuredData);

	if (bZeroDamage || damage==0)
	{
	    super.NetDamage(originaldamage,0,injured,instigatedby,hitlocation ,momentum,damagetype);
		return 0;
	}
	else
	{
	    if(pc!=none)
	        checkviewshake(injuredstatsinv);
		else
		{
            if(rpgturretcontroller(instigatedBy.Controller) == none || rpgturretcontroller(instigatedBy.Controller).mymarker == none ||
                rpgturretcontroller(instigatedBy.Controller).mymarker.instigatorcontroller == none )
                AwardEXPForDamage(instigatedBy.Controller, InstigatedStatsInv, injured, Damage);
            else AwardEXPForDamage(rpgturretcontroller(instigatedBy.Controller).mymarker.instigatorcontroller,
                getstatsinvfor(rpgturretcontroller(instigatedBy.Controller).mymarker.instigatorcontroller), injured, Damage, instigatedBy);
		}
        return super.NetDamage(originaldamage,damage,injured,instigatedby,hitlocation ,momentum,damagetype);
    }
}

function bool OverridePickupQuery(Pawn Other, Pickup item, out byte bAllowPickup)
{
	local RPGStatsInv StatsInv;
	local int x,i;
	local class<ammunition> m[2];
	local float ammomax;
	local class<weapon> w;
	local bool bdropped,bRemoveReference;
	local controller c;
	local Weapon WeaponCopy;
	local Inventory Inv;
	local Pawn P;
	local RPGWeapon OldWeapon, Copy;
	local class<RPGWeapon> NewWeaponClass;
	local weapon wep;

	if (Other.Controller != None)
		c = Other.Controller;
	else if (Other.DrivenVehicle != None )
		c = Other.DrivenVehicle.Controller;
	if (c != None)
		StatsInv = GetStatsInvFor(c);
	if(statsinv==none)
	{
	    if(vehicle(other) == none)
		    statsinv=rpgstatsinv( other.FindInventoryType(class'rpgstatsinv') );
        else if(vehicle(other).driver != none)
		    statsinv=rpgstatsinv( vehicle(other).driver.FindInventoryType(class'rpgstatsinv') );
	}
	if(statsinv!=none && c==none)
	    c=statsinv.ownerc;
    if(vehicle(other)!=none )
    {
        if( c!=none && rpgartifactpickup(item)!=none)
        {
            if (StatsInv != None && !RPGMut.bGameRestarted)
			    for (x = 0; x < StatsInv.DataObject.Abilities.length; x++)
				    if(StatsInv.DataObject.Abilities[x].static.OverridePickupQuery(Other, item, bAllowPickup, StatsInv.DataObject.AbilityLevels[x]) )
                        return true;
            ballowpickup = 1;
            return true; //hehe
        }
    }

	//increase value of ammo pickups based on Max Ammo stat
	if (!RPGMut.bGameRestarted)
	{
		if(other.Controller==none && c!=none && weaponlocker(item) == none)
		    c.HandlePickup(item);
        if (StatsInv != None)
		    ammomax=float(statsinv.DataObject.AmmoMax)/100.0;
        if ( ammo(item)!=none || WeaponPickup(item)!=none)
        {
            if(ammo(item)!=none )
            {
                m[0]=class<ammunition>(item.InventoryType);
	            Ammo(item).AmmoAmount = int(Ammo(item).default.AmmoAmount * (1.0 + ammomax));
                if(m[0]!=none  )
                {
                    if( m[0].default.Charge==0)
                        m[0].default.Charge=m[0].default.MaxAmmo;
                    if(!class'MutMCGRPG'.static.IsSuperWeaponAmmo(m[0]))
                    {
                        if( m[0].default.AmmoAmount>0)
                        {
                            m[0].default.InitialAmount=m[0].default.AmmoAmount;
                            m[0].default.AmmoAmount=0;
                        }
                    }
                    m[0].default.MaxAmmo=m[0].default.Charge*(1.0 + AmmoMax);
                }
                if (StatsInv != None)
			        for (x = 0; x < StatsInv.DataObject.Abilities.length; x++)
				        if(StatsInv.DataObject.Abilities[x].static.OverridePickupQuery(Other, item, bAllowPickup, StatsInv.DataObject.AbilityLevels[x]) )
                            return true;
            }
            else if(weaponpickup(item)!=none)
            {
                bdropped = weaponpickup(item).bDropped;
                if(class<weapon>(weaponpickup(item).inventorytype) != none && !class<weapon>(weaponpickup(item).inventorytype).default.bNoInstagibReplace)
                {
                    w=class<weapon>( weaponpickup(item).InventoryType);
                    for(i=0;i<2;i++)
                    {
                        if(w.default.FireModeClass[i]!=none)
                            m[i]=w.default.FireModeClass[i].default.AmmoClass;
                        if(m[i]!=none  )
                        {
                            if( m[i].default.Charge==0)
                                m[i].default.Charge=m[i].default.MaxAmmo;
                            if(!class'MutMCGRPG'.static.IsSuperWeaponAmmo(m[i]))
                            {
                                if( m[i].default.AmmoAmount>0)
                                    m[i].default.InitialAmount=m[i].default.AmmoAmount;
                                m[i].default.AmmoAmount=0;
                            }
                            m[i].default.MaxAmmo=m[i].default.Charge*(1.0 + AmmoMax);
                        }
                    }
                    if (StatsInv != None)
			            for (x = 0; x < StatsInv.DataObject.Abilities.length; x++)
				            if(StatsInv.DataObject.Abilities[x].static.OverridePickupQuery(Other, item, bAllowPickup, StatsInv.DataObject.AbilityLevels[x]) )
				            {
                                if( ballowpickup == 1 && RPGMut.WeaponModifierChance > 0.0)
                                {
                                    if(!bdropped && level.Game.bWeaponStay && weaponpickup(item).bWeaponStay )
                                    {
	                                    //if player previously had a weapon of class InventoryType, force modifier to be the same
	                                    for (x = 0; x < StatsInv.OldRPGWeapons.length; x++)
	                                        if (StatsInv.OldRPGWeapons[x].ModifiedClass == w)
	                                        {
	                                            OldWeapon = StatsInv.OldRPGWeapons[x].Weapon;
	                                            if (OldWeapon == None)
	                                            {
	                                                StatsInv.OldRPGWeapons.Remove(x, 1);
	                                                x--;
                                                }
	                                            else
	                                            {
					                                NewWeaponClass = OldWeapon.Class;
					                                StatsInv.OldRPGWeapons.Remove(x, 1);
					                                bRemoveReference = true;
					                                break;
                                                }
                                            }
                                    }
                                    else if(rpgweapon(item.owner) != none )
                                    {
                                        oldweapon = rpgweapon(item.Owner);
                                        newweaponclass = rpgweapon(item.Owner).Class;
                                        item.SetOwner(none);
                                    }
                                    if (NewWeaponClass == None)
                                        NewWeaponClass = RPGMut.GetRandomWeaponModifier(w, Other);
                                    Copy = item.spawn(NewWeaponClass,Other,,,rot(0,0,0) );
                                    Copy.Generate(OldWeapon);
                                    wep = Weapon(other.spawn(item.InventoryType,Copy,,,rot(0,0,0) ) );
                                    wep.SetOwner(other);
                                    Copy.SetModifiedWeapon(wep, false);
                                    item.inventory = copy;
                                    if (bRemoveReference)
                                        OldWeapon.RemoveReference();
                                    if(rpgweaponpickup(c.MoveTarget) != none && rpgweaponpickup(c.MoveTarget).ReplacedPickup == item)
                                        c.HandlePickup(rpgweaponpickup(c.MoveTarget) );
                                }
                                return true;
                            }
                    if(vehicle(other) == none && RPGMut.WeaponModifierChance > 0.0 && (other.Inventory == none ||
                        !other.Inventory.HandlePickupQuery(item) ) )
                        ballowpickup=1;
                    if(item == none || item.IsInState('sleeping') )  //maybe it destroyed at handle
                    {
                        ballowpickup = 0;
                            return true;
                    }
                    if( ballowpickup == 1 && RPGMut.WeaponModifierChance > 0.0 )
                    {
                        if(!bdropped && level.Game.bWeaponStay && weaponpickup(item).bWeaponStay )
                        {
	                        //if player previously had a weapon of class InventoryType, force modifier to be the same
	                        if (StatsInv != None)
	                            for (x = 0; x < StatsInv.OldRPGWeapons.length; x++)
	                                if (StatsInv.OldRPGWeapons[x].ModifiedClass == w)
	                                {
	                                    OldWeapon = StatsInv.OldRPGWeapons[x].Weapon;
	                                    if (OldWeapon == None)
	                                    {
	                                        StatsInv.OldRPGWeapons.Remove(x, 1);
	                                        x--;
                                        }
	                                    else
	                                    {
					                        NewWeaponClass = OldWeapon.Class;
					                        StatsInv.OldRPGWeapons.Remove(x, 1);
					                        bRemoveReference = true;
					                        break;
                                        }
                                    }
                        }
                        else if(rpgweapon(item.owner) != none )
                        {
                            oldweapon = rpgweapon(item.Owner);
                            newweaponclass = rpgweapon(item.Owner).Class;
                        }
                        if (NewWeaponClass == None)
                            NewWeaponClass = RPGMut.GetRandomWeaponModifier(w, Other);
                        Copy = item.spawn(NewWeaponClass,Other,,,rot(0,0,0) );
                        Copy.Generate(OldWeapon);
                        wep = Weapon(other.spawn(item.InventoryType,Copy,,,rot(0,0,0) ) );
                        wep.SetOwner(other);
                        Copy.SetModifiedWeapon(wep, false);
                        item.inventory = copy;
                        if (bRemoveReference)
                            OldWeapon.RemoveReference();
                        item.SetOwner(none);
                        if(rpgweaponpickup(c.MoveTarget) != none && rpgweaponpickup(c.MoveTarget).ReplacedPickup == item)
                            c.HandlePickup(rpgweaponpickup(c.MoveTarget) );
                    }
                }
                if(vehicle(other)==none && RPGMut.WeaponModifierChance > 0.0) //for vehicle pickup mutator
                    return true;
            }
        }
        else if(weaponlocker(item)!=none)
        {
            if(class<weapon>(weaponlocker(item).inventorytype) != none)
            {
                w=class<weapon>( weaponlocker(item).InventoryType);
                for(i=0;i<2;i++)
                    if(w.default.FireModeClass[i]!=none)
                        m[i]=w.default.FireModeClass[i].default.AmmoClass;
				p = other;
				for (Inv = P.Inventory; Inv != None; Inv = Inv.Inventory)
					if ( Inv.Class == item.InventoryType || (RPGWeapon(Inv) != None && RPGWeapon(Inv).ModifiedWeapon.Class == weaponlocker(item).InventoryType ) )
					{
						WeaponCopy = Weapon(Inv);
						break;
					}
				if ( WeaponCopy != None && RPGMut.WeaponModifierChance > 0.0 )
				{
                    ballowpickup = 0;
					WeaponCopy.FillToInitialAmmo();
                    for(i=0;i<2;i++)
                    {
                        if(m[i]!=none  )
                        {
                            if (!class'MutMCGRPG'.static.IsSuperWeaponAmmo(m[i]))
                            {
                                if( m[i].default.AmmoAmount>0)
                                    m[i].default.InitialAmount=m[i].default.AmmoAmount;
                                m[i].default.AmmoAmount=0;
                            }
                        }
                    }
                    item.AnnouncePickup(other);
                    return true;
				}
                for(i=0;i<2;i++)
                {
                    if(m[i]!=none  )
                    {
                        if (!class'MutMCGRPG'.static.IsSuperWeaponAmmo(m[i]))
                        {
                            if( m[i].default.AmmoAmount>0)
                                m[i].default.InitialAmount=m[i].default.AmmoAmount;
                            m[i].default.AmmoAmount=0;
                        }
                    }
                }
				if (StatsInv != None)
	                for (x = 0; x < StatsInv.DataObject.Abilities.length; x++)
		                if(StatsInv.DataObject.Abilities[x].static.OverridePickupQuery(Other, item, bAllowPickup, StatsInv.DataObject.AbilityLevels[x]) )
		                {
				            if(ballowpickup == 1 && RPGMut.WeaponModifierChance > 0.0 )
				            {
                                //if player previously had a weapon of class InventoryType, force modifier to be the same
                                for (x = 0; x < StatsInv.OldRPGWeapons.length; x++)
                                    if (StatsInv.OldRPGWeapons[x].ModifiedClass == w)
                                    {
                                        OldWeapon = StatsInv.OldRPGWeapons[x].Weapon;
                                        if (OldWeapon == None)
                                        {
                                            StatsInv.OldRPGWeapons.Remove(x, 1);
                                            x--;
                                        }
                                        else
                                        {
                                            NewWeaponClass = OldWeapon.Class;
                                            StatsInv.OldRPGWeapons.Remove(x, 1);
                                            bRemoveReference = true;
                                            break;
                                        }
                                    }

                                if (NewWeaponClass == None)
		                            NewWeaponClass = RPGMut.GetRandomWeaponModifier(class<Weapon>(weaponlocker(item).InventoryType), Other);
                                Copy = item.spawn(NewWeaponClass,Other,,,rot(0,0,0));
	                            Copy.Generate(OldWeapon);
	                            wep = Weapon(other.spawn(item.InventoryType,Copy,,,rot(0,0,0) ) );
                                wep.SetOwner(other);
	                            Copy.SetModifiedWeapon(wep, false);
	                            item.inventory = copy;
	                            if (bRemoveReference)
		                            OldWeapon.RemoveReference();
                            }
                            return true;
                        }
                if(vehicle(other) == none && RPGMut.WeaponModifierChance > 0.0 && (other.Inventory == none || !other.Inventory.HandlePickupQuery(item) ) )
                    ballowpickup=1;
                if(item == none || item.IsInState('sleeping') )  //maybe it destroyed at handle
                {
                    ballowpickup = 0;
                    return true;
                }
				if(ballowpickup == 1 && RPGMut.WeaponModifierChance > 0.0)
				{
                    //if player previously had a weapon of class InventoryType, force modifier to be the same
                    if (StatsInv != None)
                        for (x = 0; x < StatsInv.OldRPGWeapons.length; x++)
                            if (StatsInv.OldRPGWeapons[x].ModifiedClass == w)
                            {
                                OldWeapon = StatsInv.OldRPGWeapons[x].Weapon;
                                if (OldWeapon == None)
                                {
                                    StatsInv.OldRPGWeapons.Remove(x, 1);
                                    x--;
                                }
                                else
                                {
                                    NewWeaponClass = OldWeapon.Class;
                                    StatsInv.OldRPGWeapons.Remove(x, 1);
                                    bRemoveReference = true;
                                    break;
                                }
                            }

                        if (NewWeaponClass == None)
		                    NewWeaponClass = RPGMut.GetRandomWeaponModifier(class<Weapon>(weaponlocker(item).InventoryType), Other);
                        Copy = item.spawn(NewWeaponClass,Other,,,rot(0,0,0));
	                    Copy.Generate(OldWeapon);
	                    wep = Weapon(other.spawn(item.InventoryType,Copy,,,rot(0,0,0) ) );
                        wep.SetOwner(other);
	                    Copy.SetModifiedWeapon(wep, false);
	                    item.inventory = copy;
	                    if (bRemoveReference)
		                    OldWeapon.RemoveReference();
				}
		    }
            if(vehicle(other)==none && RPGMut.WeaponModifierChance > 0.0) //for vehicle pickup mutator
                return true;
        }
        else
        {
            if (StatsInv != None)
            {
                if(UDamagePack(item) != none)
                    StatsInv.bUDamage = true;
                for (x = 0; x < StatsInv.DataObject.Abilities.length; x++)
                    if(StatsInv.DataObject.Abilities[x].static.OverridePickupQuery(Other, item, bAllowPickup, StatsInv.DataObject.AbilityLevels[x]) )
                        return true;
            }
        }
    }
    return Super.OverridePickupQuery(Other, item, bAllowPickup);
}

function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	local bool bAlreadyPrevented;
	local int x,y;
	local RPGStatsInv StatsInv;
    local saveinv s;
    local redeemerwarhead w;
	local Controller KilledController;
	local playercontroller pc;
	local vehicle v;
	local actor a;
	local GameObjective o;
	local bool found,bVehicleDestroyed;

    if(onsvehicle(killed) != none && vehicle(killed).bVehicleDestroyed)
    {
        bVehicleDestroyed = true;
        vehicle(killed).bVehicleDestroyed = false;   //lol
    }
    bAlreadyPrevented = Super.PreventDeath(Killed, Killer, damageType, HitLocation) && damagetype!=class'destroydamagetype';

    if(killed == none)
        return bAlreadyPrevented;
    if(bAlreadyPrevented || classischildof(damagetype,class'damtyperetaliation') || ( damagetype.name == 'damtypetelefrag' &&
        (Level.TimeSeconds - killed.SpawnTime < SpawnProtectionTime) ) )
	    return true;

    if(vehicle(killed)!=none && vehicle(killed).Driver!=none && ( vehicle(killed).bEjectDriver || vehicle(killed).bRemoteControlled ||
        ( onsweaponpawn(killed)!=none && onsweaponpawn(killed).VehicleBase!=none && onsweaponpawn(killed).VehicleBase.bEjectDriver ) ) )
    {
        if( vehicle(killed).bEjectDriver || ( onsweaponpawn(killed)!=none && onsweaponpawn(killed).VehicleBase!=none &&
            onsweaponpawn(killed).VehicleBase.bEjectDriver )  )
            vehicle(killed).EjectDriver();
        else if(!vehicle(killed).KDriverLeave(false))
            vehicle(killed).KDriverLeave(true);
        s=saveinv( killed.FindInventoryType(class'saveinv') );
        if(s!=none && !s.bpendingdelete)
        {
            s.bDestroying=true;
            killed.DeleteInventory(s);
            s.Destroy();
        }
        if(killed.Event != '' && killed.Event != 'none')
        {
	        for(x = 0; x < objectives.Length; x++)
	        {
	            o = objectives[x];
	            if( o.Tag == killed.Event && (DestroyVehicleObjective(o) != none || TriggeredObjective(o) != none) && o.IsActive() &&
                    !unrealmpgameinfo(level.Game).CanDisableObjective(o) && !o.bOptionalObjective )
                {
                    o.bDisabled = true;
                    o.SetActive(false);
	                for(y = 0; y < objectives.Length; y++)
	                {
	                    if(objectives[y].IsActive() && objectives[y].DefensePriority == o.DefensePriority &&
                            objectives[y].DefenderTeamIndex == o.DefenderTeamIndex && !objectives[y].bOptionalObjective)
	                    {
	                        if(objectives[y].Tag == killed.Event && (DestroyVehicleObjective(objectives[y]) != none ||
                                TriggeredObjective(objectives[y]) != none) &&
                                !unrealmpgameinfo(level.Game).CanDisableObjective(objectives[y]) )
	                        {
	                            objectives[y].bDisabled = true;
	                            objectives[y].SetActive(false);
	                        }
	                        else
	                            found = true;
	                    }
	                }
	                if(!found)
	                {
	                    for(y = 0; y < objectives.Length; y++)
	                    {
	                        if(objectives[y].ObjectivePriority > o.ObjectivePriority)
	                            objectives[y].ObjectivePriority--;
	                    }
	                }
	                break;
                }
	        }
        }
        if(bVehicleDestroyed)
            vehicle(killed).bVehicleDestroyed = true;   //lol

        return false;
    }
    if( onsvehicle(killed) != none && killed.Physics != phys_karma && damagetype!=class'destroydamagetype' )        //try to clear a brutal basic epic bug
    {
        killed.SetPhysics(phys_karma);
	    killed.died( Killer, damageType, HitLocation);
        return true;
    }

    if(killed.Controller==none && Controller(Killed.owner) != None )
    {
        w = redeemerwarhead(Controller(Killed.owner).pawn);
        if(w != none)
        {
            killed.Health=1;     //lol
            w.RelinquishController();
            killed.Health=0;
        }
    }
	if (Killed.Controller != None)
		KilledController = Killed.Controller;
	else if (Killed.DrivenVehicle != None && Killed.DrivenVehicle.Controller != None)
		KilledController = Killed.DrivenVehicle.Controller;
	else if ( vehicle(Killed.owner) != None && vehicle(Killed.owner).Controller != None)
		KilledController = vehicle(Killed.owner).Controller;
	else if ( vehicle(Killed.owner) != None && Controller( Killed.owner.owner) != None)
		KilledController = Controller( Killed.owner.owner);
	else if ( vehicle(killed) == none && Controller(Killed.owner) != None )
		KilledController = Controller(Killed.owner);
	if (KilledController != None)
		StatsInv = GetStatsInvFor(KilledController);
	if(statsinv==none)
		statsinv=rpgstatsinv( killed.FindInventoryType(class'rpgstatsinv') );
	if(statsinv!=none && killedcontroller==none)
	    killedcontroller=statsinv.ownerc;
	if(killedcontroller==none)
	{
	    if(statsinv!=none)
	    {
	        killed.DeleteInventory(statsinv);
	        statsinv.Instigator=none;
	    }
	    statsinv=none;
	}
	if (StatsInv != None )
	{
		//FIXME Pawn should probably still call PreventDeath() in cases like this, but it might be wiser to ignore the value
		if ( !RPGMut.bGameRestarted && (KilledController.PlayerReplicationInfo == None ||
            !KilledController.PlayerReplicationInfo.bOnlySpectator) )
		{
		    if( !KilledController.bPendingDelete )
		    {
			    for (x = 0; x < StatsInv.DataObject.Abilities.length; x++)
			        if (StatsInv.DataObject.Abilities[x].default.bdefensive && StatsInv.DataObject.Abilities[x].static.PreventDeath
                        (Killed, Killer, damageType, HitLocation, StatsInv.DataObject.AbilityLevels[x], bAlreadyPrevented))
					    bAlreadyPrevented = damagetype!=class'destroydamagetype';
			    for (x = 0; x < StatsInv.DataObject.Abilities.length; x++)
			        if (!StatsInv.DataObject.Abilities[x].default.bdefensive && StatsInv.DataObject.Abilities[x].static.PreventDeath
                        (Killed, Killer, damageType, HitLocation, StatsInv.DataObject.AbilityLevels[x], bAlreadyPrevented))
					    bAlreadyPrevented = damagetype!=class'destroydamagetype';
			}
			else if( playercontroller(KilledController) != none )
		    {
			    for (x = 0; x < StatsInv.DataObject.Abilities.length; x++)
			        StatsInv.DataObject.Abilities[x].static.playerexited
                        (playercontroller(KilledController), killed, StatsInv.DataObject.AbilityLevels[x]);
			}
		}

		//tell StatsInv its owner died
		if (!bAlreadyPrevented)
			StatsInv.OwnerDied(killedcontroller);
	    else
	        return true;


        if(statsinv.team != none && statsinv.team.TeamIndex != killedcontroller.GetTeamNum() )
            foreach dynamicactors(class'actor',a)
                if( ( projectile(a) != none && projectile(a).InstigatorController==killedcontroller ) ||
                    ( ultimacharger(a) != none && ultimacharger(a).InstigatorController==killedcontroller ))
                    a.Destroy();
    }
    killed.HitDamageType = DamageType;
    if(asvehicle_spacefighter(killed.DrivenVehicle)!=none )
        killed.DrivenVehicle.Died(killed.DrivenVehicle.Controller, class'damagetype', killed.DrivenVehicle.Location);      //lol hack
    if(vehicle(killed)!=none )
    {
        if(killed.Event != '' && killed.Event != 'none')
        {
	        for(x = 0; x < objectives.Length; x++)
	        {
	            o = objectives[x];
	            if( o.Tag == killed.Event && (DestroyVehicleObjective(o) != none || TriggeredObjective(o) != none) && o.IsActive() &&
                    !unrealmpgameinfo(level.Game).CanDisableObjective(o) && !o.bOptionalObjective )
                {
                    o.bDisabled = true;
                    o.SetActive(false);
	                for(y = 0; y < objectives.Length; y++)
	                {
	                    if(objectives[y].IsActive() && objectives[y].DefensePriority == o.DefensePriority &&
                            objectives[y].DefenderTeamIndex == o.DefenderTeamIndex && !objectives[y].bOptionalObjective)
	                    {
	                        if(objectives[y].Tag == killed.Event && (DestroyVehicleObjective(objectives[y]) != none ||
                                TriggeredObjective(objectives[y]) != none) &&
                                !unrealmpgameinfo(level.Game).CanDisableObjective(objectives[y]) )
	                        {
	                            objectives[y].bDisabled = true;
	                            objectives[y].SetActive(false);
	                        }
	                        else
	                            found = true;
	                    }
	                }
	                if(!found)
	                {
	                    for(y = 0; y < objectives.Length; y++)
	                    {
	                        if(objectives[y].ObjectivePriority > o.ObjectivePriority)
	                            objectives[y].ObjectivePriority--;
	                    }
	                }
	                break;
                }
	        }
        }
        if(bVehicleDestroyed)
            vehicle(killed).bVehicleDestroyed = true;   //lol
    }
    if(killer != none && killer.Pawn != none && killer.PlayerReplicationInfo == none &&
        class<xdeathmessage>(level.Game.DeathMessageClass) != none)
    {
        for(x=0; x< RPGMut.statsinves.Length; x++)
            if(RPGMut.statsinves[x] != none)
                RPGMut.statsinves[x].clientsetsomeonestring(killer.Pawn.class);
    }

 	s=saveinv( killed.FindInventoryType(class'saveinv') );
    if(s!=none && !s.bdestroying)
    {
        s.bDestroying=true;
        killed.DeleteInventory(s);
        s.Destroy();
    }
    v=vehicle(killed);
    if(v!=none && v.Driver!=none)
    {
        killed=v.Driver;
		statsinv=rpgstatsinv( killed.FindInventoryType(class'rpgstatsinv') );
	    if (StatsInv != None )
			StatsInv.OwnerDied(killedcontroller);
        s=none;
 	    s=saveinv( killed.FindInventoryType(class'saveinv') );
        if(s!=none && !s.bdestroying)
        {
            s.bDestroying=true;
            killed.DeleteInventory(s);
            s.Destroy();
        }
    }
    if(killer != none)
        pri[0] = killer.PlayerReplicationInfo;
    if(killedcontroller != none)
    {
        pri[1] = killedcontroller.PlayerReplicationInfo;
        adrenaline = killedcontroller.Adrenaline;
    }
    else adrenaline = -1.0;
    for(x = 0; x < 2; x++)
    {
        if(pri[x] != none)
        {
            Score[x] = pri[x].Score;
            Deaths[x] = pri[x].Deaths;
            NumLives[x] = pri[x].NumLives;
            bOutOfLives[x] = byte(pri[x].bOutOfLives);
            Kills[x] = pri[x].Kills;
        }
    }
    if(killedcontroller == none)
    {
        if(vehicle(killed) != none && vehicle(killed).Driver == none && controller(killed.Owner) != none)
            killed.SetOwner(none);           //Trigger_ASUseAndRespawn bug fix
        return false;
    }

    if( !level.Game.bTeamGame && unrealplayer(killer) != none && killedController == killer )     //deathmatch debug
        unrealplayer(killer).LastKillTime = -5.0;

    pc=playercontroller(killedcontroller);
    if(pc!=none)
    {
        pc.StopViewShaking();
        pc.ShakeRot=rot(0,0,0);
        pc.ShakeOffset=vect(0,0,0);
    }

    if ((damageType.default.bCausedByWorld || damageType.Name =='DamTypeTeleFrag' || damageType.Name =='DamTypeTeleFragged' ||
        damageType.Name =='gibbed' ) && Killed.Health > 0)
	{
		// if this damagetype is an instant kill that bypasses Pawn.TakeDamage() and calls Pawn.Died() directly
		// then we need to award EXP by damage for the rest of the monster's health
		AwardEXPForDamage(Killer, GetStatsInvFor(Killer), Killed, Killed.Health);
	}

	// Yet Another Invasion Hack - Invasion doesn't call ScoreKill() on the GameRules if a monster kills something
	// This one's so bad I swear I'm fixing it for a patch
	if (int(Level.EngineVersion) < 3190 && Level.Game.IsA('Invasion') && KilledController != None && MonsterController(Killer) != None)
	{
		if (KilledController.PlayerReplicationInfo != None)
			KilledController.PlayerReplicationInfo.bOutOfLives = true;
		ScoreKill(Killer, KilledController);
	}

	return false;
}

function bool PreventSever(Pawn Killed, name boneName, int Damage, class<DamageType> DamageType)
{
	local int x;
	local RPGStatsInv StatsInv;

    if(RPGMut.bGameRestarted || classischildof(damagetype,class'damtyperetaliation') || killed==none ||
        ( damagetype.name == 'damtypetelefrag' && (Level.TimeSeconds - killed.SpawnTime < SpawnProtectionTime) ) )
	    return true;
	if (Killed.Controller != None)
	{
		StatsInv = GetStatsInvFor(Killed.Controller);
		if (StatsInv != None)
			for (x = 0; x < StatsInv.DataObject.Abilities.length; x++)
				if (StatsInv.DataObject.Abilities[x].static.PreventSever(Killed, boneName, Damage, DamageType,
                    StatsInv.DataObject.AbilityLevels[x]))
					return true;
	}

	return Super.PreventSever(Killed, boneName, Damage, DamageType);
}

state GameEnded
{
    function Timer()
    {
        local actor a;
        local controller c;

        a=deathmatch(level.game).EndGameFocus;
        deathmatch(level.game).EndGameFocus=none;
        for (C = Level.ControllerList; C != None; C = C.NextController)
        {
            c.bGodMode = true;
            if (playercontroller(c)!=none && a != none )
            {
                if(c.Pawn!=none && playercontroller(c).ViewTarget == a)
                {
                    playercontroller(c).SetViewTarget(c.Pawn);
                    playercontroller(c).ClientSetViewTarget(c.Pawn);
                }
                else if( playercontroller(c).ViewTarget == a)
                {
                    playercontroller(c).SetViewTarget(c);
                    playercontroller(c).ClientSetViewTarget(c);
                }
                    //endgame hack
            }
        }
    }
}

function bool CheckEndGame(PlayerReplicationInfo Winner, string Reason)
{
    endtime = level.TimeSeconds;
	if ( NextGameRules != None )
		return NextGameRules.CheckEndGame(Winner,Reason);

	return true;
}

function Timer()
{
	local Controller C;
	local Inventory Inv;
	local RPGStatsInv StatsInv;
	local int x;
	local saveinv s;
	local vehicle v;
    local xPlayer p;
    local svehiclefactory vf;

    if(RPGMut.cancheat && counter < level.TimeSeconds - 150.0 )
    {
        counter=level.TimeSeconds;
        foreach dynamicactors(class'xPlayer',p)
            if(p.bIsPlayer )
                p.ClientMessage("This is a fun mode. You can use these cheat commands : teleport, loadme, rpgloaded, setweaponspeed. "$
                "Teleport moves you to a point, what you watch, loadme gives you a magic weapon you want ( example loadme infinity minigun 3 ), "$
                "rpgloaded loads you with some weapons, and max adrenaline, setweaponspeed increase your weaponspeed stat.");
    }

    if(message != level.Game.DeathMessageClass )
        message = class<xdeathmessage>(level.Game.DeathMessageClass);

	if (Level.Game.bGameEnded)
	{
        ForEach DynamicActors(class'vehicle', v)
        {
		    if ( Level.NetMode != NM_Standalone )
			    v.RemoteRole = v.default.RemoteRole;
            v.bTeamLocked=false;
            if(onsweaponpawn(v)!=none)
                continue;
            v.SetPhysics(v.default.Physics);
            v.SetCollision( true, true );
            if ( v.Weapon != None )
		        v.Weapon.bEndOfRound = false;
            v.bNoWeaponFiring=false;
            v.bIgnoreForces = false;
            if(karmaparams(v.KParams)!=none)
		        v.KSetStayUpright(karmaparams(v.default.KParams).bKAllowRotate,karmaparams(v.default.KParams).bKStayUpright);
	    }
	    foreach dynamicactors(class'svehiclefactory',vf)
	    {
	        if(asvehiclefactory(vf) !=none)
	            asvehiclefactory(vf).bVehicleTeamLock=false;
            else if(vf.GetPropertyText( "bVehicleTeamLock" ) ~= "true" )
	            vf.SetPropertyText( "bVehicleTeamLock" , "false" );
	    }
	    deathmatch(level.game).EndGameFocus=none;
	    for (C = Level.ControllerList; C != None; C = C.NextController)
	    {
	        c.bGodMode = true;
	        if (playercontroller(c)!=none  )
	        {
	            if(c.Pawn!=none )
                {
		            if ( Level.NetMode != NM_Standalone )
			            c.pawn.RemoteRole = ROLE_AutonomousProxy;
                    playercontroller(c).SetViewTarget(c.Pawn);
                    playercontroller(c).ClientSetViewTarget(c.Pawn);
                    if(xpawn(c.Pawn) != none)
                        playercontroller(c).BehindView(false);
                    if(c.Pawn.Controller==none)
                        c.Pawn.Controller=c;
                    if(vehicle(c.Pawn)!=none)
                    {
                        c.pawn.SetPhysics(c.pawn.default.Physics);
                        vehicle(c.pawn).driver.bNoWeaponFiring=false;
                        if(karmaparams(vehicle(c.pawn).KParams)!=none)
		                    vehicle(c.pawn).KSetStayUpright(karmaparams(vehicle(c.pawn).default.KParams).bKAllowRotate,
                            karmaparams(vehicle(c.pawn).default.KParams).bKStayUpright);
                    }
                    else
                    {
                        c.Pawn.bPhysicsAnimUpdate=c.Pawn.default.bPhysicsAnimUpdate;
                        if(c.Pawn.PhysicsVolume.bWaterVolume)
                            c.Pawn.SetPhysics(phys_swimming);
                        else
                            c.Pawn.SetPhysics(phys_falling);
                    }
                    c.pawn.SetCollision( true, true );
                    if ( c.Pawn.Weapon != None )
			            c.Pawn.Weapon.bEndOfRound = false;
		            if(c.Pawn.PhysicsVolume.bWaterVolume)
		            {
                        c.GotoState(c.Pawn.WaterMovementState);
                        playercontroller(c).ClientGotoState(c.Pawn.WaterMovementState,'');
                    }
                    else
                    {
                        c.GotoState(c.Pawn.LandMovementState);
                        playercontroller(c).ClientGotoState(c.Pawn.LandMovementState,'');
                    }
                    c.Pawn.bNoWeaponFiring=false;
                    c.Pawn.bIgnoreForces = false;
                    if(vehicle(c.Pawn)==none)
                        class'druidartifactloaded'.static.ModifyPawn(c.pawn, max(3,class'druidartifactloaded'.default.maxlevel),
                            getstatsinvfor(c) );
                }
                else if(!c.IsInState('BaseSpectating') )
                {
                    c.GotoState('dead');
                    playercontroller(c).ClientGotoState('dead','begin');
                }
                    //endgame hack

            }
        }
        for(x=0;x< RPGMut.statsinves.Length;x++)
            if(RPGMut.statsinves[x]!=none)
                RPGMut.statsinves[x].clientgameended();
        if (!RPGMut.cancheat && TeamInfo(Level.Game.GameReplicationInfo.Winner) != None)
        {
            for (C = Level.ControllerList; C != None; C = C.NextController)
                if (c!=none  && C.PlayerReplicationInfo != None &&C.PlayerReplicationInfo.team != None &&
                    ( C.PlayerReplicationInfo.Team == Level.Game.GameReplicationInfo.Winner || RPGMut.bTeamBasedEXP) )
                {
                    StatsInv = GetStatsInvFor(C);
				    if (StatsInv != None)
				    {
				        if( !RPGMut.bTeamBasedEXP)
				        {
                            StatsInv.DataObject.Experience += RPGMut.EXPForWin;
                            RPGMut.CheckLevelUp(StatsInv.DataObject, C.PlayerReplicationInfo);
                        }
                        else
                        {
                            statsinv.DataObject.AddExperienceFraction(float(RPGMut.EXPForWin) *
                                (0.25 * float( C.PlayerReplicationInfo.Team == Level.Game.GameReplicationInfo.Winner ) +
                                fmin(1.0, statsinv.teamtime[TeamInfo(Level.Game.GameReplicationInfo.Winner).TeamIndex] /
                                (endtime - starttime) ) ),RPGMut,C.PlayerReplicationInfo);
                        }
                        if(playercontroller(c) != none || ( !RPGMut.bFakeBotLevels && RPGMut.BotBonusLevels == 0 ) )
                            statsinv.DataObject.SaveConfig();
				    }
                }
                Log(Level.Game.GameReplicationInfo.Winner.GetHumanReadableName()@"won the match, awarded"@RPGMut.EXPForWin@"EXP");
        }
        else if ( !RPGMut.cancheat && PlayerReplicationInfo(Level.Game.GameReplicationInfo.Winner) != None &&
            Controller(Level.Game.GameReplicationInfo.Winner.Owner) != None )
        {
            StatsInv = GetStatsInvFor(Controller(Level.Game.GameReplicationInfo.Winner.Owner));
            if (StatsInv != None)
            {
                StatsInv.DataObject.Experience += RPGMut.EXPForWin;
                RPGMut.CheckLevelUp(StatsInv.DataObject, PlayerReplicationInfo(Level.Game.GameReplicationInfo.Winner));
                if(playercontroller(Level.Game.GameReplicationInfo.Winner.Owner) != none || ( !RPGMut.bFakeBotLevels && RPGMut.BotBonusLevels == 0 ) )
                    statsinv.DataObject.SaveConfig();
                Log(PlayerReplicationInfo(Level.Game.GameReplicationInfo.Winner).PlayerName@"won the match, awarded "$RPGMut.EXPForWin$" EXP");
            }
        }
        if (!RPGMut.cancheat && !RPGMut.bGameRestarted)
            RPGMut.SaveAllData();

        if (!RPGMut.bFakeBotLevels && RPGMut.BotBonusLevels > 0)
		{
			//If Fake Bot Levels is off, bots get a configurable amount of bonus levels after the game
			//to counter that they're in only a fraction of the total games played on the machine
			for (C = Level.ControllerList; C != None; C = C.NextController)
				if (Bot(C) != None)
				{
					StatsInv = GetStatsInvFor(C);
					if (StatsInv != None)
					{
						for (x = 0; x < RPGMut.BotBonusLevels; x++)
						{
                            StatsInv.DataObject.Experience += StatsInv.DataObject.NeededExp;
                            RPGMut.CheckLevelUp(StatsInv.DataObject, None);
						}
						RPGMut.BotLevelUp(Bot(C), StatsInv.DataObject);
                        statsinv.DataObject.SaveConfig();
					}
				}
		}
		gotostate('gameended');
	}
	else  if (Level.Game.ResetCountDown == 2)
	{
		//unattach all RPGStatsInv from any pawns because the game is resetting and all pawns are about to be destroyed
		//this is done here to insure it happens right before the game actually resets anything
		for (C = Level.ControllerList; C != None; C = C.NextController)
        {
			if (C != None && C.bIsPlayer)
			{
			    if(c.Pawn!=none)
			    {
			        s=saveinv(c.Pawn.FindInventoryType(class'saveinv') );
			        if(s!=none)
			        {
			            c.Pawn.DeleteInventory(s);
			            s.bDestroying=true;
			            s.Destroy();
                    }
                    if(vehicle(c.Pawn) != none && vehicle(c.Pawn).Driver != none)
                    {
			            s=saveinv(vehicle(c.Pawn).Driver.FindInventoryType(class'saveinv') );
			            if(s!=none)
			            {
			                vehicle(c.Pawn).Driver.DeleteInventory(s);
			                s.bDestroying=true;
			                s.Destroy();
                        }
                    }
                    else if(redeemerwarhead(c.Pawn) != none && redeemerwarhead(c.Pawn).OldPawn != none)
                    {
			            s=saveinv(redeemerwarhead(c.Pawn).OldPawn.FindInventoryType(class'saveinv') );
			            if(s!=none)
			            {
			                redeemerwarhead(c.Pawn).OldPawn.DeleteInventory(s);
			                s.bDestroying=true;
			                s.Destroy();
                        }
                    }
			    }
			    for (Inv = C.Inventory; Inv != None; Inv = Inv.Inventory)
       			    if (Inv.IsA('RPGStatsInv') && Inv.Owner != C && Inv.Owner != None)
			        {
			            Log("Resetting StatsInv:"$Inv);
                        RPGStatsInv(Inv).OwnerDied();
			            break;
                    }
		    }
        }
        if ( xBombingRun(level.Game)!=none)
        {
            for ( C = Level.ControllerList; C != None; C = C.NextController )
	            if ( C.PlayerReplicationInfo != None && !C.PlayerReplicationInfo.bOnlySpectator && C.Pawn != None )
	            {
				    for ( Inv=C.Pawn.Inventory; Inv!=None; Inv=Inv.Inventory )
				        if ( rpgweapon(inv) != none && rpgweapon(inv).ModifiedWeapon != none && rpgweapon(inv).ModifiedWeapon.IsA('TransLauncher') )
				            Weapon(Inv).GiveAmmo(0, None, false);
	            }
        }
	}
	else if(level.Game.ResetCountDown <= 0 && xdoubledom(level.Game)!=none && xdoubledom(level.Game).xDomPoints[0]!=none &&
        xdoubledom(level.Game).xDomPoints[1]!=none)
	{
	    if( xdoubledom(level.Game).xDomPoints[0].ControllingTeam!=none &&
            xdoubledom(level.Game).xDomPoints[0].ControllingTeam == xdoubledom(level.Game).xDomPoints[1].ControllingTeam &&
            xdoubledom(level.Game).ScoreCountDown==1)
            domhack=true;
	}
}

function Tick(float DeltaTime)
{
	local Object MonsterConfig;

	//hack for Monster Assault - get the vehicle vs monster damagescaling for EXP by damage calculation
	//is it bad that I'm so good at evil hacks like this...?
	if (Level.Game.IsA('MonsterAssault'))
	{
		MonsterConfig = FindObject( "Package." $Repl(Left(string(Level), InStr(string(Level), ".")), " ", Chr(27)), class(DynamicLoadObject(Level.Game.Class.Outer $ ".MAMonsterSetting", class'Class')) );
		if (MonsterConfig == None)  //failsafe, just incase it gets changed for savegame compatibility
			MonsterConfig = FindObject( string(xLevel) $ "." $Repl(Left(string(Level), InStr(string(Level), ".")), " ", Chr(27)), class(DynamicLoadObject(Level.Game.Class.Outer $ ".MAMonsterSetting", class'Class')) );
		if (MonsterConfig != None)
			MA_AdjustDamageByVehicleScale = float(MonsterConfig.GetPropertyText("AdjustDamageByVehicleScale"));
		else
			log("Could not find MonsterConfig for MonsterAssault game!");
	}

	Disable('Tick');
}

defaultproperties
{
     MA_AdjustDamageByVehicleScale=1.000000
     bAlwaysRelevant=True
     RemoteRole=ROLE_SimulatedProxy
}

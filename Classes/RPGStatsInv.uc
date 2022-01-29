class RPGStatsInv extends Inventory
	DependsOn(RPGPlayerDataObject)
    config(mcgRPG1991);

var() RPGPlayerDataObject DataObject; //object holding player's data (server side only)
var() RPGPlayerDataObject.RPGPlayerData Data; //struct version of data in DataObject - replicated to clients to show on HUD and stat menu
var() MutMCGRPG RPGMut;
var() RPGRules RPGRulz;
var() array<class<RPGAbility> > AllAbilities; //all abilities available
var() int StatCaps[6]; //curse the need for it
var() RPGStatsMenu StatsMenu; //clients only - pointer to stats menu if it exists so we don't have to do an iterator search
var() bool bGotInstigator; //netplay only - set to true first tick after Instigator has been replicated
var() bool bMagicWeapons; //does the server have magic weapons enabled?
var() bool bSentInitialData; //sent initial data that requires function replication (ability list, stat caps, etc)
var() bool bscriptcalled;
var() bool afk;
var() bool bberserk;
var() controller OwnerC;
var() rpginteraction myinteraction;
var() int weaponindex;
var() float adrenaline; //save adrenaline from adrenaline regen skill, useful, when player has low level in this ability,
                        // 'cause stupid awardadrenaline function doesn't allow fragments

//store the abilities made inventories in the statsinv instead of increase instigator's inventory chain
var() SkillInv ownerinv[256];

var() class<Powerups> selected;

var() array<vehicle> turrets;
var() bool bhasturret;
var() vehicle currentturret;
var() bool blocked;
var() float lastlocktime;

var() bool bCanRebuild;

var() ProjSpeedTool proj;

var() float nextrefresh; //refresh owner's inventory at this time if needed

var() float aForward, aStrafe, aUp;
var() bool bFlying;


var() bool motd;
var() float hand;

var() bool bdefaultsdone;
var() bool bClear;

var() string PendingName;

var() float lastloaded;

var() private editconst float nextcheck;
var() playercontroller LocalPlayer;
var() rotator startrot;

var() int savedexperience,savedlevel,savedpoints,lastexp,lastlevel;  //for cpu optimization

var() float lasthittime;
var() controller lasthitby;
var() bool blastdamageteam;
var() TeamInfo team;

var() float deathtime;
var() float lastdeleted;

var() float teamtime[2];

var() string someonestring;

struct OldRPGWeaponInfo
{
	var RPGWeapon Weapon;
	var class<Weapon> ModifiedClass;
};
var() array<OldRPGWeaponInfo> OldRPGWeapons; //used to prevent throwing a weapon just to try for a different modifier

//bot multikill tracking (the stock code doesn't track multikills for bots)
var() int BotMultiKillLevel;
var() float BotLastKillTime;

struct pointstruct
{
    var int Level;
    var int NeededExp;
    var int PointsAvailable;
};

var() pointstruct points;
var() float nextsend;
var() bool bNeedSend, bNeedSendLevel;

enum EStatType
{
	STAT_WSpeed,
	STAT_HealthBonus,
	STAT_AdrenalineMax,
	STAT_Attack,
	STAT_Defense,
	STAT_AmmoMax
};

enum ESkinQuality
{
    SQ_Normal,
    SQ_High
};

var() config ESkinQuality SkinQuality;

var() playerinput myinput;

var() xbombflag bomb;

var() config bool bShowStatPointMessage;

var() array<string> PlayerNames;
var() int NameIndex;
var() string CurrentName;

var() float nextdelete;

var() bool bUDamage;

delegate ProcessPlayerLevel(string PlayerString);
delegate render1(hud h);
delegate render2(hud h, canvas c);

replication
{
	reliable if (bNetInitial && Role == ROLE_Authority)
		Data, bMagicWeapons, ownerc, CurrentName;
	reliable if (bNetDirty && Role == ROLE_Authority)
		bcanrebuild;
	reliable if (Role < ROLE_Authority)
		ServerAddPointTo, ServerAddAbility, ServerRequestPlayerLevels, activateplayer, ServerResetData, Serverrestartplayer,
        destroyturrets,rpgloaded,loadme,teleport,die,killme,setweaponspeed,rpgcheat,nihil,obliterate,logitems,deleteweapons,
        toggleturretlock,Suicide,rebuild,AskForPawn,DeleteCharacter,getproperty;
	reliable if (Role == ROLE_Authority)
		ClientUpdateStatMenu, ClientAddAbility, ClientAdjustFireRate, ClientSendPlayerLevel,ClientReInitMenu, ClientResetData,
        ClientReceiveAbilityInfo,ClientSetWeaponSpeed,ClientReceiveAllowedAbility, ClientReceiveStatCap, ClientModifyVehicle,
        ClientUnModifyVehicle, calldestroy, clientsethealthmax,clientswitchweapon,sendexp,sendlevel,setlasthittime, clientteleport,
        clientenabletick, clientsetconfigs, clientgameended, clientsetsomeonestring, clientupdateturretstate,refreshturretlock,
        clientreceivemodifiers,getplayernames,resetplayernames,ClientSetUDamageTime,removeplayer,clientlog;
}

simulated function ClientSetUDamageTime(float NewUDam, xpawn p)
{
	p.UDamageTime = Level.TimeSeconds + NewUDam;
}

simulated function removeplayer(playerreplicationinfo p)
{
    local int i;
    if(p != none && level.GRI != none)
    {
        for(i = 0; i < level.GRI.PRIArray.Length; i++)
            if( level.GRI.PRIArray[i] == p)
            {
                level.GRI.PRIArray.Remove(i,1);
                break;
            }
    }
}

function DeleteCharacter(string charname)
{
    local int i;
    local playercontroller p;
    local string s;
    if(RPGMut != none && nextdelete < level.TimeSeconds)
    {
        nextdelete = level.TimeSeconds + 32.0;
        p = playercontroller(ownerc);
        if(p != none)
        {
            s = p.GetPlayerIDHash();
            for(i = 0; i < RPGMut.DataObjectList.Length; i++)
            {
                if(!(string(RPGMut.DataObjectList[i].Name) ~= string(DataObject.Name) ) && RPGMut.DataObjectList[i].OwnerID ~= s &&
                    string(RPGMut.DataObjectList[i].Name) ~= charname)
                {
                    RPGMut.DataObjectList[i].ClearConfig();
                    p.ClientMessage(RPGMut.DataObjectList[i].Name$" deleted.");
                    break;
                }
            }
        }
    }
}

function SkillInv GetOwnerInv(byte i)
{
    return ownerinv[i];
}

function SetOwnerInv(byte i, skillinv inv)
{
    ownerinv[i] = inv;
}

function Suicide()
{
    if ( instigator != None && Level.TimeSeconds - instigator.LastStartTime > 0.5 )
        instigator.Suicide();
}

simulated function resetplayernames(string s)
{
    local array<string> parts;
    local int i;
    class'RPGStatsInv'.default.PlayerNames.Remove(0,class'RPGStatsInv'.default.PlayerNames.Length);
    if(s == "")
        return;
    split(s,",",parts);
    for(i = 0; i < parts.Length; i++)
    {
	    class'RPGStatsInv'.default.PlayerNames.Insert(class'RPGStatsInv'.default.PlayerNames.Length,1);
        class'RPGStatsInv'.default.PlayerNames[class'RPGStatsInv'.default.PlayerNames.Length - 1] = parts[i];
    }
}

simulated function getplayernames(string s)
{
    local array<string> parts;
    local int i;
    if(s == "")
        return;
    split(s,",",parts);
    for(i = 0; i < parts.Length; i++)
    {
	    class'RPGStatsInv'.default.PlayerNames.Insert(class'RPGStatsInv'.default.PlayerNames.Length,1);
        class'RPGStatsInv'.default.PlayerNames[class'RPGStatsInv'.default.PlayerNames.Length - 1] = parts[i];
    }
}

simulated function sendlevel(int l, int n, int p)
{
    data.Level = l;
    data.NeededExp = n;
    data.PointsAvailable = p;
    ClientReInitMenu();
}

simulated function sendexp(int e)
{
    data.Experience = e;
}

simulated function ClientSwitchWeapon(weapon oldweapon, weapon newweapon)
{
    if(instigator == none || level.NetMode != nm_client)
        return;
    if(oldweapon == none || newweapon == none || instigator.weapon == newweapon)
    {
        if(ownerc != none)
            ownerc.SwitchToBestWeapon();
        return;
    }
    instigator.PendingWeapon = newweapon;
    if(ownerc != none)
        ownerc.StopFiring();
    else
        instigator.StopWeaponFiring();
	if ( instigator.Weapon == None )
		instigator.ChangedWeapon();
	else
		instigator.Weapon.PutDown();
}

function rebuild()
{
	local int i;

    if(!bcanrebuild || role < role_authority)
        return;

	if (RPGMut != None && !Level.Game.bGameRestarted && DataObject.Level > 1 && DataObject.PointsAvailable != RPGMut.PointsPerLevel * (DataObject.Level - 1) )
	{
	    bcanrebuild = false;
		DataObject.Reset(self,RPGMut,true);
        if(ownerc != none)
		    ownerc.Adrenaline = fmin(ownerc.Adrenaline,100.0);
		DataObject.CreateDataStruct(data, false);
		ClientResetData();
		if (Instigator != None && Instigator.Health > 0)
		{
		    OwnerDied(ownerc);
            Level.Game.SetPlayerDefaults(Instigator);
            for(i=0;i< RPGMut.statsinves.Length;i++)
                if(RPGMut.statsinves[i]!=self)
                    RPGMut.statsinves[i].clientsethealthmax(Instigator, Instigator.HealthMax);
	        if ( instigator.Weapon!=none)
                adjustfirerate( instigator.Weapon );
            if(instigator.DrivenVehicle != none)
            {
                modifyvehicle( instigator.DrivenVehicle, instigator.DrivenVehicle.ParentFactory );
                clientmodifyvehicle( instigator.DrivenVehicle, instigator.DrivenVehicle.ParentFactory );
            }
        }
	}
}

simulated function calldestroy()
{
    bscriptcalled=true;
}

function toggleturretlock()
{
    local turretmarker t;
    if(lastlocktime < level.TimeSeconds - 0.5 && ownerc != none && vehicle(ownerc.pawn) != none )
    {
        lastlocktime = level.TimeSeconds;
        t = turretmarker(ownerc.Pawn.FindInventoryType(class'turretmarker') );
        if(t != none && t.instigatorcontroller == ownerc)
        {
            t.bunlocked = !t.bunlocked;
            refreshturretlock(!t.bunlocked);
        }
    }
}

simulated function refreshturretlock(bool newlock)
{
    blocked = newlock;
}

simulated function clientsetsomeonestring( class<pawn> pclass)
{
    local string ss;

    if(rpgrulz == none)
        foreach dynamicactors(class'rpgrules',rpgrulz)
        {
            if(rpgrulz.Level == level)
                break;
        }

    if(rpgrulz == none || rpgrulz.message == none)
        return;

    if(pclass == none)
    {
        rpgrulz.message.default.someonestring = someonestring;
        return;
    }
    if(class<vehicle>(pclass)!=none)
        ss = class<vehicle>(pclass).default.VehicleNameString;
    else
        ss = pclass.default.menuname;
    if(ss == "")
        ss = getitemname(string(pclass) );
    if(left(ss,1) ~= "a" || left(ss,1) ~= "e" || left(ss,1) ~= "o" || left(ss,1) ~= "i" )
        ss = "an "$ss;
    else
        ss = "a "$ss;
    rpgrulz.message.default.someonestring = ss;
}

simulated function clientgameended()
{
    local playercontroller c;
    local vehicle v;
    if(level.NetMode!=nm_client)
        return;
    c=level.GetLocalPlayerController();
    ForEach DynamicActors(class'vehicle', v)
    {
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
    if (c!=none )
    {
        if(c.Pawn!=none )
        {
            if(vehicle(c.Pawn)!=none)
            {
                if(vehicle(c.Pawn).driver!=none)
                    vehicle(c.Pawn).driver.bNoWeaponFiring=false;
            }
            else
            {
                c.Pawn.bPhysicsAnimUpdate=c.Pawn.default.bPhysicsAnimUpdate;
                if(c.Pawn.PhysicsVolume.bWaterVolume)
                    c.Pawn.SetPhysics(phys_swimming);
                else
                    c.Pawn.SetPhysics(phys_falling);
                c.pawn.SetCollision( true, true );
                if ( c.Pawn.Weapon != None )
                    c.Pawn.Weapon.bEndOfRound = false;
                c.Pawn.bNoWeaponFiring=false;
                c.Pawn.bIgnoreForces = false;
            }
        }
        //endgame hack
    }
}

simulated function fire()
{
    if(ownerc.IsInState( 'WaitingForPawn' ) )
		AskForPawn();
    else if(ownerc.IsInState( 'PlayerWaiting' ) )
    {
        playercontroller(ownerc).LoadPlayers();
        if ( !playercontroller(ownerc).bForcePrecache && unrealplayer(ownerc).bReadyToStart )
			ServerReStartPlayer();
    }
    else if(ownerc.IsInState( 'Dead' ) )
    {
        playercontroller(ownerc).LoadPlayers();

        if (!playercontroller(ownerc).bMenuBeforeRespawn)
	        ServerReStartPlayer();
    }
}

function Serverrestartplayer()
{
    local name oldstate;
	if( deathtime < level.TimeSeconds - 1.5 && level.Game.bGameEnded && ownerc != none && ( ownerc.IsInState('dead') ||
        ownerc.IsInState( 'PlayerWaiting' ) ) )
	{
	    oldstate=level.Game.GetStateName();
	    level.Game.GotoState('matchinprogress');
        ownerc.ServerReStartPlayer();
	    level.Game.GotoState(oldstate);
	}
}

function AskForPawn()
{
    local name oldstate;
	if( deathtime < level.TimeSeconds - 1.5 && level.Game.bGameEnded && ownerc != none && ownerc.IsInState('WaitingForPawn') )
	{
	    oldstate=level.Game.GetStateName();
	    level.Game.GotoState('matchinprogress');

	    if ( playercontroller(ownerc).Pawn != None )
		    playercontroller(ownerc).GivePawn(playercontroller(ownerc).Pawn);
        else
	    {
		    playercontroller(ownerc).bFrozen = false;
		    playercontroller(ownerc).ServerRestartPlayer();
	    }

	    level.Game.GotoState(oldstate);
	}
}

simulated function clientreceivemodifiers(class<rpgweapon> r, int a, int b)
{
    if(r != none)
    {
        if(bClear)
        {
            bClear = false;
            if(RPGMut == none)
                RPGMut = class'MutMCGRPG'.static.GetRPGMutator(self);
            if(RPGMut != none)
                RPGMut.WeaponModifiers.Remove(0,RPGMut.WeaponModifiers.Length);
        }
        r.default.minmodifier = a;
        r.default.maxmodifier = b;
        if(RPGMut != none)
        {
            RPGMut.WeaponModifiers.Insert(RPGMut.WeaponModifiers.Length,1);
            RPGMut.WeaponModifiers[RPGMut.WeaponModifiers.Length - 1].WeaponClass = r;
            RPGMut.WeaponModifiers[RPGMut.WeaponModifiers.Length - 1].Chance = 1;
        }
    }
}

simulated function clientsetconfigs(class<rpgability> a, string value)
{
    local array<string> parts;
    local int i;
    if(a != none)
        split(value,",",parts);
    else
        return;
    if(parts.Length==0)
        return;
    for(i=0;i< parts.Length;i++)
    {
        if(i==0)
            a.default.StartingCost=int(parts[i]);
        else if(i==1)
            a.default.CostAddPerLevel=int(parts[i]);
        else if(i==2)
            a.default.MaxLevel=int(parts[i]);
        else if(i==3)
        {
            if(class<DruidArtifactLoaded>(a)!=none)
                class'DruidArtifactLoaded'.default.Level2Cost=int(parts[i]);
            else if(class<druidnoweapondrop>(a)!=none)
                class'druidnoweapondrop'.default.Level2Cost=int(parts[i]);
            else if(class<druidloaded>(a)!=none)
                class'druidloaded'.default.MinLev2=int(parts[i]);
            else if(class<abilityultima>(a)!=none)
                class'abilityultima'.default.level2cost=int(parts[i]);
        }
        else if(i==4)
        {
            if(class<druidnoweapondrop>(a)!=none)
                class'druidnoweapondrop'.default.Level3Cost=int(parts[i]);
            else if(class<DruidArtifactLoaded>(a)!=none)
                class'DruidArtifactLoaded'.default.Level3Cost=int(parts[i]);
            else if(class<druidloaded>(a)!=none)
                class'druidloaded'.default.MinLev3=int(parts[i]);
            else if(class<abilityultima>(a)!=none)
                class'abilityultima'.default.level3cost=int(parts[i]);
        }
        else if(i==5)
        {
            if(class<abilityultima>(a)!=none)
                class'abilityultima'.default.level4cost=int(parts[i]);
        }
    }
}

function activateplayer()
{
    if(RPGMut!=none && RPGMut.bcheckafk > 1 && instigator!=none && instigator.DrivenVehicle==none)
        instigator.SetCollision(true,true);
    afk=false;
}

function setup()
{
	local int x;
	local class<rpgability> a;
	local string value;

	if (!bSentInitialData)
	{
		if (ownerc != Level.GetLocalPlayerController() )
			for (x = 0; x < Data.Abilities.length; x++)
				ClientReceiveAbilityInfo(x, Data.Abilities[x], Data.AbilityLevels[x]);
		for (x = 0; x < RPGMut.Abilities.length; x++)
			ClientReceiveAllowedAbility(x, RPGMut.Abilities[x]);
		for (x = 0; x < 6; x++)
			ClientReceiveStatCap(x, RPGMut.StatCaps[x]);

		bMagicWeapons = (RPGMut.WeaponModifierChance > 0);

		bSentInitialData = true;
	}

	if(level.NetMode == nm_standalone )
	    return;

    clientupdateturretstate(turrets.Length > 0);
	if(!bdefaultsdone)
	{
	    for(x=0;x< RPGMut.Abilities.Length; x++)
	    {
	        a = RPGMut.abilities[x];
	        if(class<DruidArtifactLoaded>(a)==none || RPGMut.MaxTurrets > 0 || a.default.MaxLevel < 3)
	            value=string(a.default.StartingCost)$","$string(a.default.CostAddPerLevel)$","$string(a.default.MaxLevel);
            else
	            value=string(a.default.StartingCost)$","$string(a.default.CostAddPerLevel)$","$string(2);
            if(class<druidnoweapondrop>(a)!=none)
                value$=","$string(class'druidnoweapondrop'.default.Level2Cost)$","$string(class'druidnoweapondrop'.default.Level3Cost);
            else if(class<DruidArtifactLoaded>(a)!=none)
                value$=","$string(class'DruidArtifactLoaded'.default.Level2Cost)$","$string(class'DruidArtifactLoaded'.default.level3cost );
            else if(class<druidloaded>(a)!=none)
                value$=","$string(class'druidloaded'.default.MinLev2)$","$string(class'druidloaded'.default.MinLev3);
            else if(class<abilityultima>(a)!=none)
                value$=","$string(class'abilityultima'.default.level2cost)$","$string(class'abilityultima'.default.level3cost)$","$
                string(class'abilityultima'.default.level4cost);
	        clientsetconfigs( a, value );
        }
	}
}

function GiveTo(pawn Other, optional Pickup Pickup)
{
	Instigator = Other;
	if ( Other.AddInventory( Self ) )
		GotoState('');
	AdjustMaxAmmo();
	lasthitby=none;
	blastdamageteam = true;
	team=instigator.GetTeam();
	if ( xpawn(Instigator) != None && Instigator.Weapon != None )
	{
        if( instigator.Weapon.bBerserk!=xpawn(instigator).bBerserk)
            instigator.Weapon.bBerserk=xpawn(instigator).bBerserk;
        adjustfirerate(instigator.weapon,true);
	    clientadjustfirerate(true);
	}
    if(playercontroller(other.Controller)!=none)
    {
        afk=true;
        if(RPGMut!=none && RPGMut.bcheckafk > 1 )
        {
            if( instigator.DrivenVehicle==none)
                instigator.SetCollision(false,false);
            startrot=instigator.Rotation;
        }
        setup();
    }
    else
    {
        bdefaultsdone=true;
        afk=false;
    }
}

function OwnerEvent(name EventName)
{
	if (EventName == 'ChangedWeapon' && xpawn(Instigator) != None && Instigator.Weapon != None )
	{
        if( instigator.Weapon.bBerserk!=xpawn(instigator).bBerserk)
            instigator.Weapon.bBerserk=xpawn(instigator).bBerserk;
        adjustfirerate(instigator.weapon,true);
	    clientadjustfirerate(true);
	}
	else if (EventName == 'RPGScoreKill')
	{
		//the stock code doesn't record multikills for bots, so do it here where we can track it and increment EXP appropriately
		//the fact that we can also add the info to the stats for the bots is a cool bonus :)
		//however, unlike the normal player multikill code, the multikill level is lost on death due to Inventory being lost on death
		if (Level.TimeSeconds - BotLastKillTime < 4)
		{
			Instigator.Controller.AwardAdrenaline(DeathMatch(Level.Game).ADR_MajorKill);
			if ( TeamPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != None )
			{
				TeamPlayerReplicationInfo(Instigator.PlayerReplicationInfo).MultiKills[BotMultiKillLevel] += 1;
				if ( BotMultiKillLevel > 0 )
					TeamPlayerReplicationInfo(Instigator.PlayerReplicationInfo).MultiKills[BotMultiKillLevel-1] -= 1;
			}
			BotMultiKillLevel++;
			UnrealMPGameInfo(Level.Game).SpecialEvent(Instigator.PlayerReplicationInfo,"multikill_"$BotMultiKillLevel);
			DataObject.Experience += int(Square(float(BotMultiKillLevel)));
			RPGMut.CheckLevelUp(DataObject, Instigator.PlayerReplicationInfo);
		}
		else
			BotMultiKillLevel=0;

		BotLastKillTime = Level.TimeSeconds;
	}

	Super.OwnerEvent(EventName);
}

simulated function AdjustMaxAmmo()
{
	local Inventory Inv;
	local Ammunition Ammo;
	local int Count;
	local float Modifier;

	Modifier = 1.0 + float(Data.AmmoMax) * 0.01;
	for (Inv = Instigator.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		Ammo = Ammunition(Inv);
		if (Ammo != None)
		{
		    if(Ammo.default.Charge == 0)
			    Ammo.MaxAmmo = Ammo.default.MaxAmmo * Modifier;
		    else
			    Ammo.MaxAmmo = Ammo.default.Charge * Modifier;
			if (Ammo.AmmoAmount > Ammo.MaxAmmo)
				Ammo.AmmoAmount = Ammo.MaxAmmo;
			if (!class'MutMCGRPG'.static.IsSuperWeaponAmmo(Ammo.Class))
			{
			    if(Ammo.default.AmmoAmount == 0)
				    Ammo.InitialAmount = Ammo.default.InitialAmount * Modifier;
			    else
				    Ammo.InitialAmount = Ammo.default.AmmoAmount * Modifier;
			}
		}
		Count++;
		if (Count > 1000)
			break;
	}
}

simulated function AdjustFireRate(Weapon W, optional bool needmodify)
{
	local int x;
	local float Modifier;
	local WeaponFire FireMode[2];
	local float berserk;
    if(w==none)
        return;
	FireMode[0] = W.GetFireMode(0);
	FireMode[1] = W.GetFireMode(1);
	if(level.GRI != none)
	    berserk = level.GRI.WeaponBerserk;
    else berserk = 1.0;
	Modifier = (1.f + 0.01 * Data.WeaponSpeed) * berserk * (1.0 + float(w.bBerserk) / 3.0 );
	if (MinigunFire(FireMode[0]) != None) //minigun needs a hack because it fires differently than normal weapons
	{
		MinigunFire(FireMode[0]).BarrelRotationsPerSec = MinigunFire(FireMode[0]).default.BarrelRotationsPerSec * Modifier;
		MinigunFire(FireMode[0]).FireRate = 1.f / (MinigunFire(FireMode[0]).RoundsPerRotation * MinigunFire(FireMode[0]).BarrelRotationsPerSec);
		MinigunFire(FireMode[0]).MaxRollSpeed = 65536.f*MinigunFire(FireMode[0]).BarrelRotationsPerSec;
	}
	else if (BioChargedFire(FireMode[0]) != None)
	    BioChargedFire(FireMode[0]).GoopUpRate = BioChargedFire(FireMode[0]).default.GoopUpRate / Modifier;
	else if (AssaultGrenade(FireMode[0]) != None)
    {
        AssaultGrenade(FireMode[0]).mHoldSpeedGainPerSec = AssaultGrenade(FireMode[0]).default.mHoldSpeedGainPerSec * Modifier;
        AssaultGrenade(FireMode[0]).mHoldClampMax = (AssaultGrenade(FireMode[0]).mHoldSpeedMax - AssaultGrenade(FireMode[0]).mHoldSpeedMin) /
            AssaultGrenade(FireMode[0]).mHoldSpeedGainPerSec;
        AssaultGrenade(FireMode[0]).mWaitTime = AssaultGrenade(FireMode[0]).default.mWaitTime / Modifier;   //lol
        AssaultGrenade(FireMode[0]).FireRate = AssaultGrenade(FireMode[0]).mWaitTime + 1.f / (AssaultGrenade(FireMode[0]).mDrumRotationsPerSec *
            AssaultGrenade(FireMode[0]).mNumGrenades) / Modifier;
    }
	else if (firemode[0]!=none && !FireMode[0].IsA('TransFire') && !FireMode[0].IsA('BallShoot') && !FireMode[0].IsA('MeleeSwordFire') )
	{
	    if (ShieldFire(FireMode[0]) != None) //shieldgun primary needs a hack to do charging speedup
	        ShieldFire(FireMode[0]).FullyChargedTime = ShieldFire(FireMode[0]).default.FullyChargedTime / Modifier;
	    FireMode[0].FireRate = FireMode[0].default.FireRate / Modifier;
	    FireMode[0].FireAnimRate = FireMode[0].default.FireAnimRate * Modifier;
	    FireMode[0].MaxHoldTime = FireMode[0].default.MaxHoldTime / Modifier;
	}
	if (MinigunFire(FireMode[1]) != None)
	{
		MinigunFire(FireMode[1]).BarrelRotationsPerSec = MinigunFire(FireMode[1]).default.BarrelRotationsPerSec * Modifier;
		MinigunFire(FireMode[1]).FireRate = 1.f / (MinigunFire(FireMode[1]).RoundsPerRotation * MinigunFire(FireMode[1]).BarrelRotationsPerSec);
		MinigunFire(FireMode[1]).MaxRollSpeed = 65536.f*MinigunFire(FireMode[1]).BarrelRotationsPerSec;
	}
	else if (BioChargedFire(FireMode[1]) != None)
	    BioChargedFire(FireMode[1]).GoopUpRate = BioChargedFire(FireMode[1]).default.GoopUpRate / Modifier;
	else if (AssaultGrenade(FireMode[1]) != None)
    {
        AssaultGrenade(FireMode[1]).mHoldSpeedGainPerSec = AssaultGrenade(FireMode[1]).default.mHoldSpeedGainPerSec * Modifier;
        AssaultGrenade(FireMode[1]).mHoldClampMax = (AssaultGrenade(FireMode[1]).mHoldSpeedMax - AssaultGrenade(FireMode[1]).mHoldSpeedMin) /
            AssaultGrenade(FireMode[1]).mHoldSpeedGainPerSec;
        AssaultGrenade(FireMode[1]).mWaitTime = AssaultGrenade(FireMode[1]).default.mWaitTime / Modifier;
        AssaultGrenade(FireMode[1]).FireRate = AssaultGrenade(FireMode[1]).mWaitTime + 1.f / (AssaultGrenade(FireMode[1]).mDrumRotationsPerSec *
            AssaultGrenade(FireMode[1]).mNumGrenades) / Modifier;
    }
	else if (firemode[1]!=none && !FireMode[1].IsA('TransFire') && !FireMode[1].IsA('BallShoot') && !FireMode[1].IsA('MeleeSwordFire') )
	{
	    if (ShieldFire(FireMode[1]) != None) //shieldgun primary needs a hack to do charging speedup
	        ShieldFire(FireMode[1]).FullyChargedTime = ShieldFire(FireMode[1]).default.FullyChargedTime / Modifier;
	    FireMode[1].FireRate = FireMode[1].default.FireRate / Modifier;
	    FireMode[1].FireAnimRate = FireMode[1].default.FireAnimRate * Modifier;
	    FireMode[1].MaxHoldTime = FireMode[1].default.MaxHoldTime / Modifier;
	}
	if(needmodify)
	{
	    bberserk=false;
	    for (x = 0; x < Data.Abilities.length; x++)
		    Data.Abilities[x].static.ModifyWeapon(W, Data.AbilityLevels[x]);
	}
}

//Call AdjustFireRate() clientside
simulated function ClientAdjustFireRate(optional bool needmodify)
{
	if (instigator!=none  && Instigator.Weapon != None)
	{
		AdjustFireRate(Instigator.Weapon,needmodify);
	}
}



function DropFrom(vector StartLocation)
{
	if (Instigator != None && Instigator.Controller != None)
		SetOwner(Instigator.Controller);
	lasthitby=none;
}

//owning pawn died
function OwnerDied(optional controller c)
{
	local int x;
	for (x = 0; x < OldRPGWeapons.Length; x++)
		if (OldRPGWeapons[x].Weapon != None)
			OldRPGWeapons[x].Weapon.RemoveReference();
    for(x = 0; x < arraycount(ownerinv); x++)
    {
        if(ownerinv[x] != none)
        {
            ownerinv[x].Destroy();
            ownerinv[x] = none;
        }
    }
	OldRPGWeapons.length = 0;
	bberserk=false;
    deathtime = level.TimeSeconds;
	//prevent RPGStatsInv from being destroyed and keep it relevant to owning player
    if(c==none)
        C = ownerc;
	if (Instigator != None)
	{
	    if(c==none)
		    C = Instigator.Controller;
		if (C == None && Instigator.DrivenVehicle != None)
			C = Instigator.DrivenVehicle.Controller;
		if (C == None && vehicle(Instigator.owner) != None)
			C = vehicle(Instigator.owner).Controller;
        if (C == None )
            c=controller(Instigator.owner);

		Instigator.DeleteInventory(self);
		instigator=none;
	}
    if(c == none)
        for(c = level.ControllerList; c != none; c = c.nextController)
            if(class'rpgrules'.static.GetStatsInvFor(c) == self)
                break;
	SetOwner(C);
	if(c != none && c.Pawn != none && c.Pawn.SelectedItem != none)
	    selected = c.Pawn.SelectedItem.Class;
}

function reset()
{
    local int i,x;
    super.Reset();
	lasthitby=none;
	if(turrets.Length>0)
        for(i=0;i< turrets.Length;i++)
            if(turrets[i] != none && !turrets[i].bPendingDelete)
            {
                if(turrets[i].Driver != none)
                    turrets[i].KDriverLeave(true);
                if(onsvehicle(turrets[i]) != none)
                {
		            for (x = 0; x < onsvehicle(turrets[i]).WeaponPawns.length; x++)
			            if(onsvehicle(turrets[i]).WeaponPawns[x].Driver != None)
                            onsvehicle(turrets[i]).WeaponPawns[x].KDriverLeave(true);
                }
                turrets[i].Destroy();
            }
    if(Instigator != none)
        ownerdied();
}



//returns true and sends a message to the player if the game is already restarting (servertraveling or voting for next map)
function bool GameRestarting()
{
	local PlayerController PC;

	if (Level.Game.bGameRestarted || level.Game.bGameEnded)
	{
		// we can get here if game restart was interrupted by mapvote
		// DataObject has already been cleared so we can't do anything but tell the player to try again later
		if (Instigator != None)
			PC = PlayerController(Instigator.Controller);
		if (PC == None)
			PC = PlayerController(Owner);
		if (PC != None)
			PC.ClientOpenMenu("GUI2K4.UT2K4GenericMessageBox",,, "Sorry, you cannot use stat points once endgame voting has begun.");

		return true;
	}

	return false;
}

//Called by owning player's stat menu to add points to a statistic
function ServerAddPointTo(int Amount, EStatType Stat)
{
    local int i;
    if(amount == 0)
		return;

	if (GameRestarting())
		return;

	if (DataObject.PointsAvailable < Amount)
		Amount = DataObject.PointsAvailable;

	switch (Stat)
	{
		case STAT_WSpeed:
		    while(amount % 5 != 0 )
		        amount--;
		    if(amount == 0)
		        return;
			if (RPGMut.StatCaps[0] >= 0 && RPGMut.StatCaps[0] - DataObject.WeaponSpeed < int(float(Amount) / 2.5) )
				Amount = int(float(RPGMut.StatCaps[0] - DataObject.WeaponSpeed) * 2.5);
			DataObject.WeaponSpeed += int(float(Amount) / 2.5);
			Data.WeaponSpeed = DataObject.WeaponSpeed;
			if(instigator!=none )
            {
                if( instigator.Weapon!=none)
			        adjustfirerate(instigator.Weapon);
                if(instigator.DrivenVehicle!=none)
			        modifyvehicle(instigator.DrivenVehicle, instigator.DrivenVehicle.ParentFactory);
			}
			break;
		case STAT_HealthBonus:
		    if(amount % 2 != 0 )
		        amount--;
		    if(amount == 0)
		        return;
			if (RPGMut.StatCaps[1] >= 0 && RPGMut.StatCaps[1] - DataObject.HealthBonus < int( float(Amount) * 1.5) )
				Amount = int( float(RPGMut.StatCaps[1] - DataObject.HealthBonus) / 1.5);
			DataObject.HealthBonus += int(1.5 * float(Amount) );
			Data.HealthBonus = DataObject.HealthBonus;
			if (Instigator != None)
			{
			    if(instigator.DrivenVehicle!=none)
			        modifyvehicle(instigator.DrivenVehicle, instigator.DrivenVehicle.ParentFactory);
				Instigator.HealthMax += int(1.5 * float(Amount) );
				Instigator.SuperHealthMax += int(1.5 * float(Amount) );
		        for(i=0;i< RPGMut.statsinves.Length;i++)
		            if(RPGMut.statsinves[i]!=self)
		                RPGMut.statsinves[i].clientsethealthmax(Instigator,Instigator.healthmax);
			}
			break;
		case STAT_AdrenalineMax:
			if (RPGMut.StatCaps[2] >= 0 && RPGMut.StatCaps[2] - DataObject.AdrenalineMax < Amount)
				Amount = RPGMut.StatCaps[2] - DataObject.AdrenalineMax;
			DataObject.AdrenalineMax += Amount;
			Data.AdrenalineMax = DataObject.AdrenalineMax;
			if (Instigator != None && Instigator.Controller != None)
				Instigator.Controller.AdrenalineMax += Amount;
			break;
		case STAT_Attack:
		    if(amount % 2 != 0 )
		        amount--;
		    if(amount == 0)
		        return;
			if (RPGMut.StatCaps[3] >= 0 && RPGMut.StatCaps[3] - DataObject.Attack < Amount / 2)
				Amount = (RPGMut.StatCaps[3] - DataObject.Attack) * 2;
			DataObject.Attack += Amount / 2;
			Data.Attack = DataObject.Attack;
			break;
		case STAT_Defense:
		    if(amount % 2 != 0 )
		        amount--;
            if(amount == 0)
		        return;
			if (RPGMut.StatCaps[4] >= 0 && RPGMut.StatCaps[4] - DataObject.Defense < Amount / 2)
				Amount = (RPGMut.StatCaps[4] - DataObject.Defense) * 2;
			DataObject.Defense += Amount / 2;
			Data.Defense = DataObject.Defense;
			break;
		case STAT_AmmoMax:
			if (RPGMut.StatCaps[5] >= 0 && RPGMut.StatCaps[5] - DataObject.AmmoMax < Amount)
				Amount = RPGMut.StatCaps[5] - DataObject.AmmoMax;
			DataObject.AmmoMax += Amount;
			Data.AmmoMax = DataObject.AmmoMax;
			if(instigator != none)
	            AdjustMaxAmmo();
			break;
	}
	DataObject.PointsAvailable -= Amount;
	Data.PointsAvailable = DataObject.PointsAvailable;

	if(bcanrebuild)
	{
        bcanrebuild = false;
        for(i = 0; i < arraycount(RPGMut.StatCaps); i++)
            dataobject.StatCaps[i] = RPGMut.StatCaps[i];
    }
	ClientUpdateStatMenu(Amount, Stat);
	switch (Stat)
	{
		case STAT_WSpeed:
			if(instigator!=none && instigator.DrivenVehicle!=none)
			    clientmodifyvehicle(instigator.DrivenVehicle, instigator.DrivenVehicle.ParentFactory);
			break;
		case STAT_HealthBonus:
			if (Instigator != None && instigator.DrivenVehicle!=none)
			    clientmodifyvehicle(instigator.DrivenVehicle, instigator.DrivenVehicle.ParentFactory);
			break;
	}
}

//After server adds points to a statistic, it calls this to update the local player's stat menu
simulated function ClientUpdateStatMenu(int Amount, EStatType Stat)
{
	if (Level.NetMode == NM_Client) //already did this on listen/standalone servers
	{
		switch (Stat)
		{
			case STAT_WSpeed:
				Data.WeaponSpeed += int(float(Amount) / 2.5);
			    if(instigator!=none && instigator.Weapon!=none)
			        adjustfirerate(instigator.Weapon);
				break;
			case STAT_HealthBonus:
				Data.HealthBonus += int(1.5 * float(Amount) );
				break;
			case STAT_AdrenalineMax:
				Data.AdrenalineMax += Amount;
				if (Instigator != None && Instigator.Controller != None)
					Instigator.Controller.AdrenalineMax += Amount;
				break;
			case STAT_Attack:
				Data.Attack += Amount / 2;
				break;
			case STAT_Defense:
				Data.Defense += Amount / 2;
				break;
			case STAT_AmmoMax:
				Data.AmmoMax += Amount;
			    if(instigator != none)
	                AdjustMaxAmmo();
				break;
		}
        Data.PointsAvailable -= Amount;
	}
	if(bcanrebuild)
        bcanrebuild = false;

	if (StatsMenu != None)
		StatsMenu.InitFor(self);
}
simulated function ClientSetWeaponSpeed(int Amount)
{
	if (Level.NetMode == NM_Client)
	{
	    Data.WeaponSpeed += int(float(Amount) / 2.5);
	    if(instigator!=none && instigator.Weapon!=none)
            adjustfirerate(instigator.Weapon);
	}

	if (StatsMenu != None)
		StatsMenu.InitFor(self);
}

//Called by owning player's stat menu to buy an ability
function ServerAddAbility(class<RPGAbility> Ability)
{
	local int x, Index, Cost;
	local bool bAllowed;

	if (GameRestarting())
		return;

	bAllowed = false;
	for (x = 0; x < RPGMut.Abilities.length; x++)
		if (RPGMut.Abilities[x] == Ability)
		{
			bAllowed = true;
			break;
		}
	if (!bAllowed)
		return;

	Index = -1;
	for (x = 0; x < DataObject.Abilities.length; x++)
		if (DataObject.Abilities[x] == Ability)
		{
			Cost = Ability.static.Cost(DataObject, DataObject.AbilityLevels[x]);
			if (Cost <= 0 || Cost > DataObject.PointsAvailable)
				return;
			Index = x;
			break;
		}
	if (Index == -1)
	{
		Cost = Ability.static.Cost(DataObject, 0);
		if (Cost <= 0 || Cost > DataObject.PointsAvailable)
			return;
		Index = DataObject.Abilities.length;
		DataObject.AbilityLevels[Index] = 0;
		Data.AbilityLevels[Index] = 0;
	}

	DataObject.Abilities[Index] = Ability;
	dataobject.abilitynames[index] = getitemname(string(Ability) );
	DataObject.AbilityLevels[Index]++;
	DataObject.PointsAvailable -= Cost;
	Data.Abilities[Index] = Ability;
	Data.AbilityLevels[Index]++;
	Data.PointsAvailable = DataObject.PointsAvailable;

	//Activate ability immediately
	if (Instigator != None)
	{
		Ability.static.ModifyPawn(Instigator, DataObject.AbilityLevels[Index], self);
		if (Instigator.Weapon != None)
			Ability.static.ModifyWeapon(Instigator.Weapon, DataObject.AbilityLevels[Index]);
		if (Instigator.drivenvehicle != None)
			Ability.static.ModifyVehicle(Instigator.drivenvehicle, Data.AbilityLevels[Index]);
	}
	if(bcanrebuild)
	{
        bcanrebuild = false;
        for(x = 0; x < arraycount(RPGMut.StatCaps); x++)
            dataobject.StatCaps[x] = RPGMut.StatCaps[x];
    }

	//Send to client
	ClientAddAbility(Ability, Cost);
}

//After server adds an ability, it calls this to do the same on the client
simulated function ClientAddAbility(class<RPGAbility> Ability, int Cost)
{
	local int x, Index;

	if (Level.NetMode == NM_Client) //already did this on listen/standalone servers
	{
		Index = -1;
		for (x = 0; x < Data.Abilities.length; x++)
			if (Data.Abilities[x] == Ability)
			{
				Index = x;
				break;
			}
		if (Index == -1)
		{
			Index = Data.Abilities.length;
			Data.AbilityLevels[Index] = 0;
		}

		Data.Abilities[Index] = Ability;
		Data.AbilityLevels[Index]++;
		Data.PointsAvailable -= Cost;

		//Activate ability immediately
		if (Instigator != None)
		{
			Ability.static.ModifyPawn(Instigator, Data.AbilityLevels[Index], self);
			if (Instigator.Weapon != None)
				Ability.static.ModifyWeapon(Instigator.Weapon, Data.AbilityLevels[Index]);
		if (Instigator.drivenvehicle != None)
			Ability.static.ModifyVehicle(Instigator.drivenvehicle, Data.AbilityLevels[Index]);
		}
	}
	if(bcanrebuild)
        bcanrebuild = false;
	if (StatsMenu != None)
		StatsMenu.InitFor(self);
}

simulated function postnetbeginplay()
{
    local int i;
    local playercontroller pc;
    local playerinput temp;

    super.PostNetBeginPlay();
    pc = level.GetLocalPlayerController();
    if(pc == none && playercontroller(owner) != none && ( level.NetMode == nm_standalone || level.NetMode == nm_listenserver ) )
        pc = playercontroller(owner);
    if(pawn(owner) != none && pawn(owner).PlayerReplicationInfo != none && level.NetMode != nm_client)
        PendingName = pawn(owner).PlayerReplicationInfo.PlayerName;
    if(level.NetMode==nm_dedicatedserver || pc == none || ( owner!=pc && owner!= pc.pawn ) )
        return;
    RPGMut = class'MutMCGRPG'.static.GetRPGMutator(self);

	ForEach DynamicActors(class'PlayerController', LocalPlayer)
	{
		if ( Viewport(LocalPlayer.Player) != None && LocalPlayer.Player.Actor == LocalPlayer)
			break;
		localplayer = none;
	}
	if(localplayer == none && ( level.NetMode == nm_standalone || level.NetMode == nm_listenserver ) )
	    localplayer = pc;
    if(level.NetMode != nm_client)
        return;
    if(pc.InputClass == class'rpgplayerinput' || pc.InputClass == class'rpgxboxplayerinput' || pc.InputClass == none)
    {
        if(class'PlayerController'.default.InputClass != none &&
            class'PlayerController'.default.InputClass != class'rpgplayerinput' &&
            class'PlayerController'.default.InputClass != class'rpgxboxplayerinput')
            pc.InputClass = class'PlayerController'.default.InputClass;
        else
            pc.InputClass = class'rpgplayerinput';
    }
    if(myinput == none)
    {
        foreach allobjects(class'playerinput',temp)
        {
            if(temp.Outer == pc && temp.Class == class'rpgplayerinput')
            {
                myinput = temp;
                rpgplayerinput(myinput).statsinv = self;
                pc.SetPropertyText("myinput",string(myinput.name) );  //loooooool hack
                break;
            }
            else if(temp.Outer == pc && temp.Class == class'rpgxboxplayerinput')
            {
                myinput = temp;
                rpgxboxplayerinput(myinput).statsinv = self;
                pc.SetPropertyText("myinput",string(myinput.name) );  //loooooool hack
                break;
            }
        }
    }
    if(myinput == none)
    {
        if(pc.InputClass == class'playerinput')
        {
            pc.InputClass = class'rpgplayerinput';
            pc.InitInputSystem();
            pc.InputClass = class'playerinput';
        }
        else if(pc.InputClass == class'xboxplayerinput')
        {
            pc.InputClass = class'rpgxboxplayerinput';
            pc.InitInputSystem();
            pc.InputClass = class'xboxplayerinput';
        }
        foreach allobjects(class'playerinput',temp)
        {
            if(temp.Outer == pc && temp.Class == class'rpgplayerinput')
            {
                myinput = temp;
                rpgplayerinput(myinput).statsinv = self;
                pc.SetPropertyText("myinput",string(myinput.name) );  //loooooool hack
                break;
            }
            else if(temp.Outer == pc && temp.Class == class'rpgxboxplayerinput')
            {
                myinput = temp;
                rpgxboxplayerinput(myinput).statsinv = self;
                pc.SetPropertyText("myinput",string(myinput.name) );  //loooooool hack
                break;
            }
        }
    }
    else
        pc.SetPropertyText("myinput",string(myinput.name) );
    pc.SaveConfig();
    render1 = pc.myHUD.OnBuildMOTD;
    render2 = pc.myHUD.OnPostRender;
    pc.myHUD.OnBuildMOTD=render;
    pc.myHUD.OnPostRender=postrender;
    for(i=0;i< pc.player.LocalInteractions.Length;i++)
    {
        if(awarenessInteraction(pc.player.LocalInteractions[i])!=none)
            pc.player.LocalInteractions[i].NotifyLevelChange();
    }
    if(instigator != none)
	    AdjustMaxAmmo();
}

//this is total brutal hack to show ammo status correctly on hud
simulated function postrender(hud h, canvas c)
{
    local weapon w;
    local inventory inv;
    local class<ammunition> a[2];
    local int i,j;
    if(instigator!=none )
    {
        for(inv=instigator.Inventory;inv!=none && j < 1000;inv=inv.Inventory)
        {
            j++;
            w=weapon(inv);
            if(w!=none && w.bNoAmmoInstances)
            {
                for(i=0;i<2;i++)
                {
                    if(w.FireModeClass[i]!=none)
                        a[i]=w.FireModeClass[i].default.AmmoClass;
                    if(a[i]!=none)
                    {
                        if(a[i].default.Charge>0)
                        {
                            a[i].default.MaxAmmo=a[i].default.Charge;
                            a[i].default.Charge=0;
                        }
                        if(a[i].default.AmmoAmount>0)
                        {
                            a[i].default.InitialAmount=a[i].default.AmmoAmount;
                            a[i].default.AmmoAmount=0;       //easier way to reset on standalone or listen server
                        }
                    }
                }
            }
        }
    }
    if(playercontroller(ownerc) != none && ownerc.Handedness != hand)
        ownerc.Handedness = hand;
    render2(h,c);
    h.bBuiltMOTD=false;
}

simulated function render(hud h)
{
    local weapon w;
    local inventory inv;
    local class<ammunition> a[2];
    local int i,j;
    local float ammomax;
    local playercontroller p;
    local ammunition m;
    if(instigator!=none)
    {
        ammomax=1.0+float(data.AmmoMax)/100.0;
        for(inv=instigator.Inventory;inv!=none && j < 1000;inv=inv.Inventory)
        {
            j++;
            w=weapon(inv);
            if(w!=none && w.bNoAmmoInstances)
            {
                for(i=0;i<2;i++)
                {
                    if(w.FireModeClass[i]!=none)
                        a[i]=w.FireModeClass[i].default.AmmoClass;
                    if(a[i]!=none)
                    {
                        if(a[i].default.Charge==0)
                            a[i].default.Charge=a[i].default.MaxAmmo;
                        a[i].default.MaxAmmo=a[i].default.Charge*ammomax;
                    }
                }
            }
            else
            {
                m = ammunition(inv);
                if(m != none)
                {
                    if(m.default.Charge==0)
                        m.MaxAmmo=m.default.MaxAmmo * ammomax;
                    else
                        m.MaxAmmo=m.default.Charge*ammomax;
                }
            }
        }
    }
    p = playercontroller(ownerc);
    if(p != none)
    {
        hand = p.Handedness;
        if(!p.bbehindview && p.viewtarget != p.Pawn)
            p.Handedness = 2.0;
        else if(asturret(p.Pawn) != none)
            p.Handedness = 1.0;
    }
    if( p != none && !p.bbehindview && pawn(p.viewtarget) != none && pawn(p.viewtarget).Weapon!=none && p.Handedness == 0.0 )
    {
        if(rpgweapon(pawn(p.viewtarget).Weapon) != none && rpgweapon(pawn(p.viewtarget).Weapon).ModifiedWeapon != none)
            w = rpgweapon(pawn(p.viewtarget).Weapon).ModifiedWeapon;
        else w = pawn(p.viewtarget).Weapon;
        if(w.Mesh == w.OldMesh)
        {
            w.CenteredRoll = p.Rotation.Roll + w.OldCenteredRoll;
            w.PlayerViewPivot.yaw = w.OldPlayerViewPivot.Yaw + w.oldCenteredYaw;
            w.PlayerViewPivot.pitch = w.oldPlayerViewPivot.Pitch + w.oldCenteredYaw * 0.25;
            w.CenteredYaw = 0;
        }
        else
        {
            w.CenteredRoll = p.Rotation.Roll + w.Default.CenteredRoll;
            w.PlayerViewPivot.yaw = w.default.PlayerViewPivot.Yaw + w.default.CenteredYaw;
            w.PlayerViewPivot.pitch = w.default.PlayerViewPivot.Pitch + w.default.CenteredYaw * 0.25;
            w.CenteredYaw = 0;
        }
    }
    render1(h);
    if(motd)
        h.bBuiltMOTD=true;
    else
        motd=true;
}

//brutal hack ends----------------------------------------

simulated function clientenabletick()
{
    if(role<role_authority)
    {
        if(bpendingdelete)
            activateplayer();
        else
            enable('tick');
    }
}

function DeactivateSpawnProtection()
{
    if(xpawn(instigator)!=none)
        xpawn(instigator).bSpawnDone=false;
    if( deathmatch(level.Game).SpawnProtectionTime == -1.0)
        deathmatch(level.Game).SpawnProtectionTime=RPGMut.spawnprotectiontime;
    else
    {
        RPGMut.spawnprotectiontime = deathmatch(level.Game).SpawnProtectionTime;
        RPGMut.rpgrulz.spawnprotectiontime = deathmatch(level.Game).SpawnProtectionTime;
    }
    instigator.DeactivateSpawnProtection();
    deathmatch(level.Game).SpawnProtectionTime=-1.0;
    if(xpawn(instigator)!=none)
        xpawn(instigator).bSpawnDone=false;
}

simulated function Tick(float dT)
{
	local int x;
	local float RealNextFireTime;
	local WeaponFire FireMode[2];
	local gameobjective o;
	local bool found;
	local inventory i;
    local vector a,b,c;
    local playercontroller pc;
    local translauncher t;
    local class<rpgweapon> rw;
    local string s,h;
    local playerinput temp;

	if( playercontroller(ownerc) != none && ownerc.IsInState(ownerc.Class.name) && bFlying)
	{
	    if(ownerc.Pawn != none)
	    {
	        ownerc.GotoState('playerflying');
	        if(myinput != none)
	        {
                GetAxes(ownerc.Rotation,a,b,c);
                a.Z=0;
                if(a == vect(0,0,0) )
                    a = vsize(c) * c;
                ownerc.Pawn.Acceleration = aForward * normal(a) + aStrafe * b + aUp * vect(0,0,1);
            }
            if ( VSize(ownerc.Pawn.Acceleration) < 1.0 )
                ownerc.Pawn.Acceleration = vect(0,0,0);
            if ( ownerc.Pawn.Acceleration == vect(0,0,0) )
                ownerc.Pawn.Velocity = vect(0,0,0);
	        if(myinput != none)
	        {
                if(level.NetMode == nm_client)
	                playercontroller(ownerc).ReplicateMove(dt, ownerc.Pawn.Acceleration, DCLICK_None, rot(0,0,0));
	            else if(level.NetMode != nm_dedicatedserver)
	                playercontroller(ownerc).ProcessMove(dt, ownerc.Pawn.Acceleration, DCLICK_None, rot(0,0,0));
            }
        }
        else ownerc.GotoState('dead');
    }


    if(instigator != none )
    {
        if(xpawn(instigator)!=none && instigator.Weapon!=none  )
        {
            if(bberserk!=xpawn(instigator).bBerserk)
            {
                if( instigator.Weapon.bBerserk!=xpawn(instigator).bBerserk)
                    instigator.Weapon.bBerserk=xpawn(instigator).bBerserk;
                adjustfirerate(instigator.Weapon);
                bberserk=xpawn(instigator).bBerserk;
            }
        }
        if(	team != instigator.GetTeam() )
       	    team=instigator.GetTeam();
    }
    else if(ownerc != none && ownerc.PlayerReplicationInfo != none && team != ownerc.PlayerReplicationInfo.Team )
        team = ownerc.PlayerReplicationInfo.Team;
    if(team != none && (team.TeamIndex == 0 || team.TeamIndex == 1) )
        teamtime[team.TeamIndex] += dt;
    if(role==role_authority && instigator!=none )
    {
        if(bUDamage)
        {
            bUDamage = false;
            if(xpawn(instigator) != none && xpawn(instigator).UDamageTime > Level.TimeSeconds)
                ClientSetUDamageTime(xpawn(instigator).UDamageTime - Level.TimeSeconds, xpawn(instigator) );
        }
        if(level.netmode == nm_dedicatedserver )
            if( nextcheck < Level.TimeSeconds )
            {
                clientenabletick();
                nextcheck=Level.TimeSeconds + 3;
            }
        if(afk && RPGMut!=none && RPGMut.bcheckafk > 0 && ( ( instigator.DrivenVehicle==none && ( ( instigator.Weapon!=none &&
            (instigator.Weapon.IsFiring() || (instigator.Weapon.GetFireMode(0) != none &&
            instigator.Weapon.GetFireMode(0).bInstantStop) || (instigator.Weapon.GetFireMode(1) != none &&
            instigator.Weapon.GetFireMode(1).bInstantStop) ) ) || (RPGMut.bcheckafk > 1 && instigator.Rotation != startrot ) ) ) ||
            (instigator.DrivenVehicle!=none && ( instigator.DrivenVehicle.bWeaponisAltFiring ||
            instigator.DrivenVehicle.bWeaponisFiring ) ) ) )
            activateplayer();
        if(instigator.SpawnTime > level.TimeSeconds - RPGMut.SpawnProtectionTime )
        {
            if(instigator.Weapon!=none && (instigator.Weapon.IsFiring() || (instigator.Weapon.GetFireMode(0) != none &&
                instigator.Weapon.GetFireMode(0).bInstantStop) || (instigator.Weapon.GetFireMode(1) != none &&
                instigator.Weapon.GetFireMode(1).bInstantStop) ) )
                DeactivateSpawnProtection();
            else if(ownerc != none && redeemerwarhead(ownerc.pawn)!=none )
                DeactivateSpawnProtection();
            else if(instigator.LastStartTime + RPGMut.SpawnProtectionTime < level.TimeSeconds)
                DeactivateSpawnProtection();
            else if(instigator.PlayerReplicationInfo!=none && instigator.PlayerReplicationInfo.HasFlag !=none)
                DeactivateSpawnProtection();
            else if(instigator.LastStartSpot != none && vsize(instigator.Location-instigator.LastStartSpot.Location) > 7000.0)
                DeactivateSpawnProtection();
            else
            {
                foreach instigator.CollidingActors(class'gameobjective',o,vsize(instigator.Location-instigator.LastStartSpot.Location)/2,instigator.location)
                    if(o.IsActive() && o.DefenderTeamIndex!=instigator.GetTeamNum() &&
                        unrealmpgameinfo(level.game).CanDisableObjective(o) )
                    {
                        DeactivateSpawnProtection();
                        break;
                    }
            }
       }
    }
    if(level.NetMode != nm_dedicatedserver )
    {
        if( lastdeleted < level.TimeSeconds - 20.0 && lastdeleted > 0.0 && statsmenu != none)
        {
            lastdeleted = 0.0;
            for (x = 0; x < Data.Abilities.length; x++)
            {
                if(Data.Abilities[x] == class'druidnoweapondrop' && Data.Abilitylevels[x] > 2)
                {
                    statsmenu.b_Delete.MenuStateChange(MSAT_Blurry);
                    break;
                }
            }
        }
        if(instigator != none && instigator.Weapon == none && instigator.DrivenVehicle == none && instigator.Controller != none)
        {
            if(instigator.PendingWeapon != none)
                instigator.ChangedWeapon();
            else if(instigator.FindInventoryType(class'weapon') != none)
                instigator.Controller.SwitchToBestWeapon();
        }
        if(RPGMut == none && ownerc == level.GetLocalPlayerController() )
        {
            RPGMut = class'MutMCGRPG'.static.GetRPGMutator(self);
            if(RPGMut != none)
                RPGMut.LocalStatsinv = self;
        }
    }
	//Set initial values clientside (e.g. ModifyPawn changes that don't get replicated for whatever reason)
	//We don't use PostNetBeginPlay() because it doesn't seem to be guaranteed that the values have all been replicated
	//at the time that function is called
	if (Level.NetMode == NM_Client)
	{
	    if(someonestring == "")
	    {
	        foreach dynamicactors(class'rpgrules',rpgrulz)
	        {
	            if(rpgrulz.Level == level)
	                break;
            }
            if(rpgrulz != none && rpgrulz.message != none)
            {
                someonestring = rpgrulz.message.default.SomeoneString;
                if(someonestring == "")
                    someonestring = "someone";
            }
            if(playercontroller(ownerc) != none)
            {
                pc = playercontroller(ownerc);
                if(pc.InputClass == class'rpgplayerinput' || pc.InputClass == class'rpgxboxplayerinput' || pc.InputClass == none)
                {
                    if(class'PlayerController'.default.InputClass != none &&
                        class'PlayerController'.default.InputClass != class'rpgplayerinput' &&
                        class'PlayerController'.default.InputClass != class'rpgxboxplayerinput')
                        pc.InputClass = class'PlayerController'.default.InputClass;
                    else
                        pc.InputClass = class'rpgplayerinput';
                }
                if(myinput == none)
                {
                    foreach allobjects(class'playerinput',temp)
                    {
                        if(temp.Outer == pc && temp.Class == class'rpgplayerinput')
                        {
                            myinput = temp;
                            rpgplayerinput(myinput).statsinv = self;
                            pc.SetPropertyText("myinput",string(myinput.name) );  //loooooool hack
                            break;
                        }
                        else if(temp.Outer == pc && temp.Class == class'rpgxboxplayerinput')
                        {
                            myinput = temp;
                            rpgxboxplayerinput(myinput).statsinv = self;
                            pc.SetPropertyText("myinput",string(myinput.name) );  //loooooool hack
                            break;
                        }
                    }
                }
                if(myinput == none)
                {
                    if(pc.InputClass == class'playerinput')
                    {
                        pc.InputClass = class'rpgplayerinput';
                        pc.InitInputSystem();
                        pc.InputClass = class'playerinput';
                    }
                    else if(pc.InputClass == class'xboxplayerinput')
                    {
                        pc.InputClass = class'rpgxboxplayerinput';
                        pc.InitInputSystem();
                        pc.InputClass = class'xboxplayerinput';
                    }
                    foreach allobjects(class'playerinput',temp)
                    {
                        if(temp.Outer == pc && temp.Class == class'rpgplayerinput')
                        {
                            myinput = temp;
                            rpgplayerinput(myinput).statsinv = self;
                            pc.SetPropertyText("myinput",string(myinput.name) );  //loooooool hack
                            break;
                        }
                        else if(temp.Outer == pc && temp.Class == class'rpgxboxplayerinput')
                        {
                            myinput = temp;
                            rpgxboxplayerinput(myinput).statsinv = self;
                            pc.SetPropertyText("myinput",string(myinput.name) );  //loooooool hack
                            break;
                        }
                    }
                }
                else
                    pc.SetPropertyText("myinput",string(myinput.name) );
                pc.SaveConfig();
            }
        }

	    if (Instigator != None)
	    {
		    CheckPlayerViewShake();
		    if (Instigator.Weapon != None && Instigator.Weapon.Instigator!=instigator)
		        instigator.Weapon.ClientWeaponSet(true);
            if(bMagicWeapons )
            {
                if(instigator.PlayerReplicationInfo != none && xbombflag(instigator.PlayerReplicationInfo.HasFlag) != none && instigator.PlayerReplicationInfo.HasFlag != bomb)
                    bomb = xbombflag(instigator.PlayerReplicationInfo.HasFlag);
                else if( bomb != none && bomb.bBallDrainsTransloc && !bomb.bHeld && BallLauncher(Instigator.Weapon) != None && Instigator.Weapon.ClientState == ws_putdown )
                {
                    bomb = none;
                    for(i = instigator.Inventory; i != none && x < 1000; i = i.Inventory)
                    {
                        x++;
                        if(rpgweapon(i) != none && rpgweapon(i).ModifiedWeapon != none && rpgweapon(i).ModifiedWeapon.Class == class'translauncher')
                        {
                            t = translauncher(rpgweapon(i).ModifiedWeapon);
                            t.DrainCharges();
                            break;
                        }
                    }
                    if(t == none)
                    {
                        x = 0;
                        for(i = instigator.Inventory; i != none && x < 1000; i = i.Inventory)
                        {
                            x++;
                            if(rpgweapon(i) != none && translauncher(rpgweapon(i).ModifiedWeapon) != none )
                            {
                                translauncher(rpgweapon(i).ModifiedWeapon).DrainCharges();
                                break;
                            }
                        }
                    }
                }
            }
        }

        if( nextcheck == 0 || nextcheck < Level.TimeSeconds - (4.0 + 2.0 * frand() ) || nextcheck > Level.TimeSeconds )   //anti hack haha
        {
            if(LocalPlayer != none && viewport(LocalPlayer.Player) != none && LocalPlayer.Player.Actor == LocalPlayer)
            {
                for(x=0;x<LocalPlayer.Player.LocalInteractions.Length;x++)
                {
                    if(rpginteraction(LocalPlayer.Player.LocalInteractions[x])!=none)
                    {
                        if(LocalPlayer.Player.LocalInteractions[x].bActive )
                        {
                            if( LocalPlayer.Player.LocalInteractions[x].ViewportOwner!=none &&
                                LocalPlayer.Player.LocalInteractions[x].ViewportOwner == LocalPlayer.Player &&
                                LocalPlayer.Player.LocalInteractions[x].ViewportOwner.Actor!=none &&
                                LocalPlayer.Player.LocalInteractions[x].ViewportOwner.Actor ==
                                LocalPlayer && LocalPlayer.level == level  )
                                found=true;
                        }
                        else LocalPlayer.Player.LocalInteractions[x].bActive=true;
                            break;
                    }
                }
            }
            if(!found)
                activateplayer();
            nextcheck=Level.TimeSeconds;
        }
		if (Instigator != None && ownerc != None )
		{
			if (!bGotInstigator)
			{
				ownerc.AdrenalineMax = Data.AdrenalineMax + ownerc.default.AdrenalineMax;
				for (x = 0; x < Data.Abilities.length; x++)
					Data.Abilities[x].static.ModifyPawn(Instigator, Data.AbilityLevels[x], self);
				bGotInstigator = true;
			}
		}
		else
			bGotInstigator = false;

		return;
	}

	if (Instigator != None)
	{
        if(bMagicWeapons )
        {
            if(instigator.PlayerReplicationInfo != none && xbombflag(instigator.PlayerReplicationInfo.HasFlag) != none &&
                instigator.PlayerReplicationInfo.HasFlag != bomb)
                bomb = xbombflag(instigator.PlayerReplicationInfo.HasFlag);
            else if( bomb != none && bomb.bBallDrainsTransloc && !bomb.bHeld && bomb.Instigator == instigator)
            {
                    bomb = none;
                    for(i = instigator.Inventory; i != none && x < 1000; i = i.Inventory)
                    {
                        x++;
                        if(rpgweapon(i) != none && rpgweapon(i).ModifiedWeapon != none && rpgweapon(i).ModifiedWeapon.Class == class'translauncher')
                        {
                            t = translauncher(rpgweapon(i).ModifiedWeapon);
                            t.DrainCharges();
                            break;
                        }
                    }
                    if(t == none)
                    {
                        x = 0;
                        for(i = instigator.Inventory; i != none && x < 1000; i = i.Inventory)
                        {
                            x++;
                            if(rpgweapon(i) != none && translauncher(rpgweapon(i).ModifiedWeapon) != none )
                            {
                                translauncher(rpgweapon(i).ModifiedWeapon).DrainCharges();
                                break;
                            }
                        }
                    }
            }
        }
		CheckPlayerViewShake();

		//Awful hack to get around WeaponFire capping FireRate to tick delta
		if (Instigator.Weapon != None && Instigator.DrivenVehicle == none)
		{
			FireMode[0] = Instigator.Weapon.GetFireMode(0);
			FireMode[1] = Instigator.Weapon.GetFireMode(1);
			if (FireMode[0] != None && FireMode[0].bIsFiring && !FireMode[0].bFireOnRelease && !FireMode[0].bNowWaiting)
			{
				x = 0;
				while (FireMode[0].NextFireTime + FireMode[0].FireRate < Level.TimeSeconds && x < 100)
				{
					RealNextFireTime = FireMode[0].NextFireTime + FireMode[0].FireRate;
					FireMode[0].ModeDoFire();
                    if(linkfire(FireMode[0])!=none)
					    firemode[0].ModeTick(dt);
	                if(Instigator == none)
	                    break;
                    FireMode[0].NextFireTime = RealNextFireTime;
					x++;
				}

				if(x==0 && FireMode[0].FireRate < dt && (FireMode[0].NextFireTime == Level.TimeSeconds ) && !FireMode[0].bFireOnRelease && !FireMode[0].bNowWaiting)
				{
				    while (FireMode[0].NextFireTime + FireMode[0].FireRate - dt < Level.TimeSeconds && x < 100)
				    {
					    RealNextFireTime = FireMode[0].NextFireTime + FireMode[0].FireRate - dt;
					    FireMode[0].ModeDoFire();
					    if(linkfire(FireMode[0])!=none)
					        firemode[0].ModeTick(dt);
	                    if(Instigator == none)
	                        break;
					    FireMode[0].NextFireTime = RealNextFireTime + dt;
					    x++;
				    }
				}

			}
			if (FireMode[1] != None && FireMode[1].bIsFiring && !FireMode[1].bFireOnRelease && !FireMode[1].bNowWaiting)
			{
				x = 0;
				while (FireMode[1].NextFireTime + FireMode[1].FireRate < Level.TimeSeconds && x < 100)
				{
					RealNextFireTime = FireMode[1].NextFireTime + FireMode[1].FireRate;
					FireMode[1].ModeDoFire();
					if(linkfire(FireMode[1])!=none)
					    firemode[1].ModeTick(dt);
	                if(Instigator == none)
	                    break;
					FireMode[1].NextFireTime = RealNextFireTime;
					x++;
				}
				if(x==0 && FireMode[1].FireRate < dt && (FireMode[1].NextFireTime == Level.TimeSeconds ) && !FireMode[1].bFireOnRelease && !FireMode[1].bNowWaiting )
				{
				    while (FireMode[1].NextFireTime + FireMode[1].FireRate - dt < Level.TimeSeconds && x < 100)
				    {
					    RealNextFireTime = FireMode[1].NextFireTime + FireMode[1].FireRate - dt;
					    FireMode[1].ModeDoFire();
					    if(linkfire(FireMode[1])!=none)
					        firemode[1].ModeTick(dt);
	                    if(Instigator == none)
	                        break;
					    FireMode[1].NextFireTime = RealNextFireTime + dt;
					    x++;
				    }
				}
			}
			if(proj != none && proj.ticktime == level.TimeSeconds)
			    proj.checkprojectile();
		}
	}
	if(nextrefresh < level.TimeSeconds && ownerc!=none)
	{
	    for(x = 0; x < turrets.Length; x++)
	    {
	        if(turrets[x] == none)
	        {
	            turrets.Remove(x,1);
	            x--;
	        }
	    }
	    if(bhasturret != (turrets.Length > 0) )
	    {
	        bhasturret = (turrets.Length > 0);
	        clientupdateturretstate(bhasturret);
 	    }
	    found=false;
	    nextrefresh = level.TimeSeconds + 2.0;
	    if(ownerc.Inventory!=self)
	    {
	        if(ownerc.Inventory==none)
	            ownerc.Inventory=self;
            else
	        {
	            for(i=ownerc.Inventory;i.inventory!=none;i=i.Inventory)
	            {
	                if(i==self || i.inventory==self)
	                {
	                    found=true;
	                    break;
                    }
	            }
	            if(!found)
	            {
	                if(i.Inventory==none)
	                    i.Inventory=self;
                    else
	                    i.Inventory.Inventory=self;
                }
            }
	    }
	}

	//update data with 'official' data from mutator if necessary
	if (DataObject.Experience != Data.Experience || DataObject.Level != Data.Level)
	{
		if (DataObject.Level > Data.Level)
			bNeedSendLevel = true;
		DataObject.CreateDataStruct(Data, true);
		bNeedSend = true;
	}
    if(level.NetMode != nm_standalone)
    {
        if(nextsend < level.TimeSeconds && bNeedSend)
        {
            nextsend = level.TimeSeconds + 0.3;
            bNeedSend = false;
            sendexp(DataObject.Experience);
            if(bNeedSendLevel)
            {
                bNeedSendLevel = false;
                sendlevel(DataObject.Level, DataObject.NeededExp, DataObject.PointsAvailable);
            }
        }
        if(!bdefaultsdone )
        {
            if(playercontroller(ownerc) == none)
            {
                bdefaultsdone = true;
                return;
            }
            if(NameIndex < RPGMut.DataObjectList.Length)
            {
                h = playercontroller(ownerc).GetPlayerIDHash();
                for(x = NameIndex; x < RPGMut.DataObjectList.Length && x < NameIndex + 10000 && len(s) < 61; x++)
                {
                    if(RPGMut.DataObjectList[x] != none && RPGMut.DataObjectList[x].OwnerID ~= h )
                    {
                        if(s != "")
                            s $= ",";
                        s $= RPGMut.DataObjectList[x].Name;
                    }
                }
                if(NameIndex == 0)
                    resetplayernames(s);
                else if(s != "")
                    getplayernames(s);
                NameIndex = x;
            }
            else if(weaponindex < RPGMut.WeaponModifiers.Length)
            {
                rw = RPGMut.WeaponModifiers[weaponindex].WeaponClass;
                clientreceivemodifiers(rw, rw.default.MinModifier, rw.default.MaxModifier);
                weaponindex++;
            }
            if(weaponindex >= RPGMut.WeaponModifiers.Length && NameIndex >= RPGMut.DataObjectList.Length)
                bdefaultsdone = true;
        }
    }
    else
    {
        if(NameIndex < RPGMut.DataObjectList.Length)
        {
            h = playercontroller(ownerc).GetPlayerIDHash();
            for(x = NameIndex; x < RPGMut.DataObjectList.Length && x < NameIndex + 10000; x++)
            {
                if(RPGMut.DataObjectList[x] != none && RPGMut.DataObjectList[x].OwnerID ~= h )
                {
                    if(s != "")
                        s $= ",";
                    s $= RPGMut.DataObjectList[x].Name;
                }
            }
            if(NameIndex == 0)
                resetplayernames(s);
            else if(s != "")
                getplayernames(s);
            NameIndex = x;
        }
    }

	if(PendingName != "" && ownerc != none && ownerc.PlayerReplicationInfo != none)
	{
        if( (level.NetMode == nm_standalone || level.NetMode == nm_listenserver) && ownerc == level.GetLocalPlayerController() )
        {
            pc = level.GetLocalPlayerController();
            render1 = pc.myHUD.OnBuildMOTD;
            render2 = pc.myHUD.OnPostRender;
            pc.myHUD.OnBuildMOTD=render;
            pc.myHUD.OnPostRender=postrender;
            for(x=0;x< pc.player.LocalInteractions.Length;x++)
            {
                if(awarenessInteraction(pc.player.LocalInteractions[x])!=none)
                    pc.player.LocalInteractions[x].NotifyLevelChange();
            }
            if(pc.InputClass == class'rpgplayerinput' || pc.InputClass == class'rpgxboxplayerinput' || pc.InputClass == none)
            {
                if(class'PlayerController'.default.InputClass != none &&
                    class'PlayerController'.default.InputClass != class'rpgplayerinput' &&
                    class'PlayerController'.default.InputClass != class'rpgxboxplayerinput')
                    pc.InputClass = class'PlayerController'.default.InputClass;
                else
                    pc.InputClass = class'rpgplayerinput';
            }
            if(myinput == none)
            {
                foreach allobjects(class'playerinput',temp)
                {
                    if(temp.Outer == pc && temp.Class == class'rpgplayerinput')
                    {
                        myinput = temp;
                        rpgplayerinput(myinput).statsinv = self;
                        pc.SetPropertyText("myinput",string(myinput.name) );  //loooooool hack
                        break;
                    }
                    else if(temp.Outer == pc && temp.Class == class'rpgxboxplayerinput')
                    {
                        myinput = temp;
                        rpgxboxplayerinput(myinput).statsinv = self;
                        pc.SetPropertyText("myinput",string(myinput.name) );  //loooooool hack
                        break;
                    }
                }
            }
            if(myinput == none)
            {
                if(pc.InputClass == class'playerinput')
                {
                    pc.InputClass = class'rpgplayerinput';
                    pc.InitInputSystem();
                    pc.InputClass = class'playerinput';
                }
                else if(pc.InputClass == class'xboxplayerinput')
                {
                    pc.InputClass = class'rpgxboxplayerinput';
                    pc.InitInputSystem();
                    pc.InputClass = class'xboxplayerinput';
                }
                foreach allobjects(class'playerinput',temp)
                {
                    if(temp.Outer == pc && temp.Class == class'rpgplayerinput')
                    {
                        myinput = temp;
                        rpgplayerinput(myinput).statsinv = self;
                        pc.SetPropertyText("myinput",string(myinput.name) );  //loooooool hack
                        break;
                    }
                    else if(temp.Outer == pc && temp.Class == class'rpgxboxplayerinput')
                    {
                        myinput = temp;
                        rpgxboxplayerinput(myinput).statsinv = self;
                        pc.SetPropertyText("myinput",string(myinput.name) );  //loooooool hack
                        break;
                    }
                }
            }
            else
                pc.SetPropertyText("myinput",string(myinput.name) );
            pc.SaveConfig();
        }
	    ownerc.PlayerReplicationInfo.SetPlayerName(PendingName);
	    PendingName = "";
	    setup();
	}
}

simulated function toggleskinquality()
{
    if(skinquality == sq_high)
        skinquality = sq_normal;
    else
        skinquality = sq_high;
    saveconfig();
}

//High level players can potentially take a lot of damage in one hit, which screws up PlayerController
//viewshaking functions because they're scaled to damage but not capped so if a player survives
//a high damage hit it'll totally screw up his screen.
simulated function CheckPlayerViewShake()
{
	local PlayerController PC;
	local float size;

	PC = PlayerController(Instigator.Controller);
	if (PC == None && instigator.DrivenVehicle!=none)
	    PC = PlayerController(Instigator.DrivenVehicle.Controller);
	if(pc==none)
		return;
	if(vsize(pc.ShakeRotMax)>1000)
	{
	    size=1000/vsize(pc.ShakeRotMax);
	    pc.ShakeRotMax*=size;
	    pc.ShakeOffsetMax*=size;
	}
    if( lasthittime==0 || lasthittime > level.TimeSeconds-0.7 )
        return;
    pc.StopViewShaking();
    pc.ShakeRot=rot(0,0,0);
    pc.ShakeOffset=vect(0,0,0);
    lasthittime=0;
}

simulated function setlasthittime()
{
    lasthittime=level.TimeSeconds;
}

//Just update the menu. Used when a levelup occurs while the menu is open (rare, but possible)
simulated function ClientReInitMenu()
{
	if (StatsMenu != None)
		StatsMenu.InitFor(self);
}

function addvehicle(vehicle v)
{
    if(v != none)
    {
        if(turrets.Length == 0)
        {
            bhasturret = true;
            clientupdateturretstate(true);
        }
        turrets[turrets.Length]=v;
    }
}

function destroyturrets()
{
	local int x;
	local turretmarker t;
	local controller c,temp;
	if(ownerc!=none)
        c=ownerc;
    else
    {
        for(temp=level.ControllerList;temp!=none;temp=temp.nextController)
            if( class'rpgrules'.static.GetStatsInvFor(temp) == self)
            {
                c = temp;
                ownerc = temp;
                break;
            }
    }
    if(c!=none)
    {
        for(x=0;x< turrets.Length;x++)
        {
            if(turrets[x] !=none && !turrets[x].bPendingDelete)
            {
                t=turretmarker( turrets[x].FindInventoryType(class'turretmarker') );
                if(t == none || t.instigatorcontroller == c || t.instigatorcontroller == none )
                {
                    if( turrets[x].IsVehicleEmpty() )
                    {
                        turrets[x].bAutoTurret=false;
                        turrets[x].Died(turrets[x].Controller,class'damagetype',vect(0,0,0) );
                        turrets.Remove(x,1);
                        x--;
                    }
                }
            }
            else
            {
                turrets.Remove(x,1);
                x--;
            }
        }
        if(turrets.Length == 0)
        {
            clientupdateturretstate(false);
            bhasturret = false;
        }
    }
}

simulated function Destroyed()
{
	local int x;
	local inventory i;
	local PlayerController PC;
	local controller c,temp;
	local MutMCGRPG.turretstruct ts;
	local RPGPlayerDataObject d;

	Super.Destroyed();
	if (Role == ROLE_Authority)
	{
	    for(x = 0; x < arraycount(ownerinv); x++)
	    {
            if(ownerinv[x] != none)
            {
                ownerinv[x].Destroy();
                ownerinv[x] = none;
            }
        }
        if(proj != none)
            proj.Destroy();
		for (x = 0; x < OldRPGWeapons.Length; x++)
			if (OldRPGWeapons[x].Weapon != None)
				OldRPGWeapons[x].Weapon.RemoveReference();
		OldRPGWeapons.length = 0;
        for(x=0;x< RPGMut.statsinves.Length;x++)
        {
            if(RPGMut.statsinves[x]==self)
            {
		        RPGMut.statsinves.Remove(x,1);
		        break;
            }
		}
		if(ownerc!=none)
            c=ownerc;
        else
        {
            for(temp=level.ControllerList;temp!=none;temp=temp.nextController)
                if( class'rpgrules'.static.GetStatsInvFor(temp) == self)
                {
                    c = temp;
                    ownerc = temp;
                    break;
                }
        }
        if(c!=none)
        {
            destroyturrets();
            if(c.inventory==self)
                c.inventory=inventory;
            else
            {
                for(i=c.inventory;i!=none;i=i.Inventory)
                    if(i.Inventory==self)
                    {
                        i.Inventory=inventory;
                        break;
                    }
            }
            Inventory = none;
        }
        if(turrets.Length > 0 )
        {
            ts.id = dataobject.OwnerID;
            ts.turrets = turrets;
            RPGMut.turretstructs[RPGMut.turretstructs.Length] = ts;
        }
        if(DataObject != none)
        {
            if(RPGMut != none && PlayerController(ownerc) != none && !RPGMut.cancheat && !level.Game.bGameEnded)
            {
	            for(x = 0; x < RPGMut.DataObjectList.Length; x++)
	            {
	                if(string(RPGMut.DataObjectList[x].Name) ~= string(DataObject.Name) )
	                {
	                    d = RPGMut.DataObjectList[x];
	                    break;
                    }
	            }
	            if(d != none)
	            {
                    d.CopyDataFrom(DataObject);
                    d.SaveConfig();
	                DataObject.ClearConfig();
	            }
                else
                {
                    log("Can't find permanent data for "$DataObject.Name$", data saved temporary, and system tries to load it at the next map");
                    DataObject.SaveConfig();
                }
            }
	        DataObject = None;
	    }
	}

	if (StatsMenu != None)
		StatsMenu.StatsInv = None;
	StatsMenu = None;


	//since various gametypes enjoy destroying pawns (and thus their inventory) without giving notification,
	//it's possible for RPGStatsInv to get destroyed while the player owning it is still playing. Since there's
	//no way to prevent the destruction, the only choice is to reset everything and wait for a new one.
	if (Level.NetMode != NM_DedicatedServer)
	{

		PC = Level.GetLocalPlayerController();
		if (PC.Player != None)
		{
		    if(rpgplayerinput(myinput) != none)
		        rpgplayerinput(myinput).statsinv = none;
		    else if(rpgxboxplayerinput(myinput) != none)
		        rpgxboxplayerinput(myinput).statsinv = none;
            if(rpgrulz != none && rpgrulz.message != none )
                rpgrulz.message.default.someonestring = someonestring;
			for (x = 0; x < PC.Player.LocalInteractions.length; x++)
			{
				if (RPGInteraction(PC.Player.LocalInteractions[x]) != None && RPGInteraction(PC.Player.LocalInteractions[x]).StatsInv == self)
				{
					RPGInteraction(PC.Player.LocalInteractions[x]).StatsInv = None;
					//this is a horrible memory leak, not to mention potential stats loss, so print a big warning
					if(!bscriptcalled)
					    Log("RPGStatsInv destroyed prematurely!", 'Warning');
				}
			}
		}
	}
}

simulated function clientupdateturretstate(bool b)
{
    bhasturret = b;
    if(statsmenu != none)
        statsmenu.updateturretstate(b);
}

function ServerRequestPlayerLevels()
{
	local Controller C;
	local Inventory Inv;
	local RPGStatsInv StatsInv;

	if (RPGMut == None || RPGMut.bGameRestarted)
		return;

	for (C = Level.ControllerList; C != None; C = C.NextController)
	{
		if (C.bIsPlayer)
		{
			for (Inv = C.Inventory; Inv != None; Inv = Inv.Inventory)
			{
				StatsInv = RPGStatsInv(Inv);
				if (StatsInv != None)
					ClientSendPlayerLevel(StatsInv.DataObject.Name$": "$StatsInv.DataObject.Level);
			}
		}
	}
}

simulated function ClientSendPlayerLevel(string PlayerString)
{
	ProcessPlayerLevel(PlayerString);
}

//Reset the player's data. Called by the client from the stats menu, after clicking the obscenely small button and confirming it
function ServerResetData()
{
	local int i;

	if (RPGMut != None && !Level.Game.bGameRestarted && ( DataObject.Level > RPGMut.StartingLevel || DataObject.Experience > 0 || DataObject.PointsAvailable !=
    RPGMut.PointsPerLevel * (RPGMut.StartingLevel - 1) ) )
	{
	    bcanrebuild = false;
		DataObject.Reset(self,RPGMut);
        if(ownerc != none)
		    ownerc.Adrenaline = fmin(ownerc.Adrenaline,100.0);
		DataObject.CreateDataStruct(data, false);
		ClientResetData();
		if (Instigator != None && Instigator.Health > 0)
		{
		    OwnerDied(ownerc);
            Level.Game.SetPlayerDefaults(Instigator);
            for(i=0;i< RPGMut.statsinves.Length;i++)
                if(RPGMut.statsinves[i]!=self)
                    RPGMut.statsinves[i].clientsethealthmax(Instigator, Instigator.HealthMax);
	        if ( instigator.Weapon!=none)
                adjustfirerate( instigator.Weapon );
            if(instigator.DrivenVehicle != none)
            {
                modifyvehicle( instigator.DrivenVehicle, instigator.DrivenVehicle.ParentFactory );
                clientmodifyvehicle( instigator.DrivenVehicle, instigator.DrivenVehicle.ParentFactory );
            }
        }
        if(ownerc != none && ownerc.PlayerReplicationInfo != none)
		    Level.Game.BroadCastLocalized(self, class'gainlevelmessage', Data.Level, ownerc.PlayerReplicationInfo);
		if (RPGMut.HighestLevelPlayerName ~= string(DataObject.Name))
		{
			RPGMut.HighestLevelPlayerLevel = 0;
			RPGMut.default.HighestLevelPlayerLevel = 0;
			if(!RPGMut.cancheat)
			    RPGMut.static.StaticSaveConfig();
		}
	}
}

simulated function ClientResetData()
{
	Data.Abilities.length = 0;
	Data.AbilityLevels.length = 0;
	data.WeaponSpeed=0;
	data.HealthBonus=0;
	data.Attack=0;
	data.Defense=0;
	data.AmmoMax=0;
	data.AdrenalineMax=0;
	if (Instigator != None && Instigator.Health > 0 )
	{
        if( instigator.Weapon!=none)
            adjustfirerate( instigator.Weapon );
        instigator.HealthMax = instigator.default.HealthMax;
        AdjustMaxAmmo();
    }
    if(ownerc != none)
        ownerc.AdrenalineMax = ownerc.default.AdrenalineMax;
    bcanrebuild = false;
    clientreinitmenu();
}

simulated function ClientReceiveAbilityInfo(int Index, class<RPGAbility> Ability, int Level)
{
	Data.Abilities[Index] = Ability;
	Data.AbilityLevels[Index] = Level;
}

simulated function ClientReceiveAllowedAbility(int Index, class<RPGAbility> Ability)
{
	AllAbilities[Index] = Ability;
}

//Even though it's a static length array, StatCaps doesn't seem to replicate the normal way...
simulated function ClientReceiveStatCap(int Index, int Cap)
{
	StatCaps[Index] = Cap;


}

simulated function clientsethealthmax(pawn p,int hp)
{
    if(p!=none && !p.bPendingDelete)
        p.HealthMax=hp;
}

simulated function ModifyVehicle(Vehicle V, optional svehiclefactory s,optional bool n)
{
	local ONSVehicle OV;
	local ONSWeaponPawn WP;
	local ONSHoverTank_IonPlasma_Weapon ion;
	local float modifier;
	local weapon w;
	local int DefHealth, i;
	local float DefLinkHealMult, HealthPct,health;
    Modifier = (1.f + 0.01 * Data.WeaponSpeed)*level.GRI.WeaponBerserk;
	//for some reason we need this to continue sending data updates to the client
	if (Owner == Instigator)
		SetOwner(V);

    //FIXME maybe give it inventory to remember original values instead so it works with other mods that change vehicle properties?
    if(onsweaponpawn(v)==none || onsweaponpawn(v).bHasOwnHealth)
    {
		if (ASVehicleFactory(s) != None)
		{
		    if( ASVehicleFactory(s).VehicleHealth > 0)
			    DefHealth = ASVehicleFactory(s).VehicleHealth;
		    else
			    DefHealth = V.default.Health;
			DefLinkHealMult = ASVehicleFactory(s).VehicleLinkHealMult;
		}
		else
		{
		    if(s!=none && s.GetPropertyText("VehicleHealth")!="" && int(s.GetPropertyText("VehicleHealth") ) > 0 )  //hack for newonsfactory
		        defhealth=int(s.GetPropertyText("VehicleHealth"));
		    else
			    DefHealth = V.default.Health;
            if(s!=none && s.GetPropertyText("VehicleLinkHealMult")!="")
		        DefLinkHealMult=float(s.GetPropertyText("VehicleLinkHealMult"));
		    else
			    DefLinkHealMult = V.default.LinkHealMult;
		}
		HealthPct = float(V.Health) / V.HealthMax;

		V.HealthMax = DefHealth + Data.HealthBonus;
		if(role==role_authority)
		    for(i=0;i< RPGMut.statsinves.Length;i++)
		        if(RPGMut.statsinves[i]!=self)
		            RPGMut.statsinves[i].clientsethealthmax(v,v.healthmax);
        health = HealthPct * V.HealthMax;
        V.Health = int(health);
        if(health - float(V.Health) >= 0.5)
		    V.Health++;
		V.LinkHealMult = DefLinkHealMult * (V.HealthMax / DefHealth);
    }

	OV = ONSVehicle(V);
	if (OV != None)
	{
        if(role==role_authority)
        {
		    for (i = 0; i < OV.Weapons.length; i++)
		    {
    		    if (ov.Weapons[i] == None)
		        {
			        ov.Weapons.Remove(i, 1);
			        i--;
	            }
				else
		        {
			        ov.ClientRegisterVehicleWeapon(ov.Weapons[i], i);    //lol it took 2 long years while i found the cause of problem thx epic:P
			        OV.Weapons[i].SetFireRateModifier(modifier);
			        if(ONSHoverTank_IonPlasma_Weapon(ov.Weapons[i]) != none )
			        {
			            ion = ONSHoverTank_IonPlasma_Weapon(ov.Weapons[i]);
			            ion.MaxHoldTime = ion.default.MaxHoldTime/modifier;
                    }
                }
            }
        }
        else
        {
		    for (i = 0; i < OV.Weapons.length; i++)
		    {
			    OV.Weapons[i].SetFireRateModifier(modifier);
			    if(ov.Weapons[i].IsA('ONSHoverTank_IonPlasma_Weapon')  )
			    {
			        ion=ONSHoverTank_IonPlasma_Weapon(ov.Weapons[i]);
			        ion.MaxHoldTime=ion.default.MaxHoldTime/modifier;
                }
            }
        }
	}
	else
	{
		WP = ONSWeaponPawn(V);
		if (WP != None && wp.Gun != none)
			WP.Gun.SetFireRateModifier(modifier);
		else
        {
            w=v.Weapon;
            if(w==none)
                w=v.PendingWeapon;
            if(w==none)
                w=weapon(v.FindInventoryType(class'weapon') );
            if (W != None)
                AdjustFireRate(W);
        }
	}
    if(n)
	    for (i = 0; i < Data.Abilities.length; i++)
		    Data.Abilities[i].static.ModifyVehicle(V, Data.AbilityLevels[i]);
}

simulated function ClientModifyVehicle(Vehicle V, optional svehiclefactory s, optional byte t)
{
    local bool n;
    if(t % 2 == 1)
    {
        n = true;
        t --;
    }
    if(t % 4 == 2)
    {
        v.bCanPickupInventory = true;
        t -= 2;
    }
    else v.bCanPickupInventory = false;

    if(t > 7)
    {
        t -= 8;
	    currentturret = v;
	    if( t == 4)
	        blocked = false;
        else blocked = true;
    }
	if (V != None)
		ModifyVehicle(V,s,n);
}

simulated function UnModifyVehicle(Vehicle V, optional svehiclefactory s,optional bool n)
{
	local int DefHealth, i;
	local float DefLinkHealMult, HealthPct, health;

	if (Owner == V)
		SetOwner(Instigator);

    if(n)
	    for (i = 0; i < Data.Abilities.length; i++)
		    Data.Abilities[i].static.UnModifyVehicle(V, Data.AbilityLevels[i]);
    if(onsweaponpawn(v)==none || onsweaponpawn(v).bHasOwnHealth)
    {
		if (ASVehicleFactory(s) != None)
		{
		    if( ASVehicleFactory(s).VehicleHealth > 0)
			    DefHealth = ASVehicleFactory(s).VehicleHealth;
		    else
			    DefHealth = V.default.Health;
			DefLinkHealMult = ASVehicleFactory(s).VehicleLinkHealMult;
		}
		else
		{
		    if(s!=none && s.GetPropertyText("VehicleHealth")!="" && int(s.GetPropertyText("VehicleHealth") ) > 0 )   //hack for newonsfactory
		        defhealth=int(s.GetPropertyText("VehicleHealth"));
		    else
			    DefHealth = V.default.Health;
            if(s!=none && s.GetPropertyText("VehicleLinkHealMult")!="")
		        DefLinkHealMult=float(s.GetPropertyText("VehicleLinkHealMult"));
		    else
			    DefLinkHealMult = V.default.LinkHealMult;
		}
		HealthPct = float(V.Health) / V.HealthMax;
		V.HealthMax = DefHealth;
		if(role==role_authority)
		    for(i=0;i< RPGMut.statsinves.Length;i++)
		        if(RPGMut.statsinves[i]!=self)
		            RPGMut.statsinves[i].clientsethealthmax(v,v.healthmax);
        health = HealthPct * V.HealthMax;
        V.Health = int(health);
        if(health - float(V.Health) >= 0.5)
		    V.Health++;
		V.LinkHealMult = DefLinkHealMult;
    }
}

simulated function ClientUnModifyVehicle(Vehicle V, optional svehiclefactory s, optional bool n)
{
    currentturret = none;
	if (V != None)
	{
	    if(role < role_authority)
	        V.Controller = none;
		UnModifyVehicle(V,s,n);
	}
}

simulated function clientteleport(actor a, vector newloc)
{
    local asturret t;
    local bool bcanmove;
    t=asturret(a);
    if(a!=none && t==none)
        a.SetLocation(newloc);
    else if(t!=none)
    {
        if(t.TurretBase!=none)
        {
            bcanmove=t.TurretBase.bMovable;
            t.TurretBase.bMovable=true;
            t.TurretBase.SetLocation(newloc);
            t.TurretBase.bMovable=bcanmove;
        }
    if(t.TurretSwivel!=none)
        t.TurretSwivel.SetLocation(newloc);
    }
}

//hehe
function killme()
{
    if ( ownerc == none || ( level.NetMode != nm_standalone && ( ownerc.playerreplicationinfo == none || !ownerc.playerreplicationinfo.bAdmin ) ) )
        return;
    instigator.Destroy();
}

function die()
{
    if ( ownerc == none || ( level.NetMode != nm_standalone && ( ownerc.playerreplicationinfo == none || !ownerc.playerreplicationinfo.bAdmin ) ) )
        return;
    instigator.Died(instigator.Controller,class'crushed',instigator.Location);
}

function obliterate()
{
    if ( ownerc == none || ( level.NetMode != nm_standalone && ( ownerc.playerreplicationinfo == none || !ownerc.playerreplicationinfo.bAdmin ) ) )
        return;
    ownerc.Pawn.Died(ownerc,class'crushed',ownerc.Pawn.Location);
}

function nihil()
{
    if ( ownerc == none || ( level.NetMode != nm_standalone && ( ownerc.playerreplicationinfo == none || !ownerc.playerreplicationinfo.bAdmin ) ) )
        return;
    ownerc.Pawn.Destroy();
}
//---------------

function rpgcheat()
{
    if ( playercontroller(ownerc) == none || ownerc.playerreplicationinfo == none || !ownerc.playerreplicationinfo.bAdmin )
        return;
    if(RPGMut.cancheat || RPGMut.bGameRestarted)
        return;
    if(!level.Game.bGameEnded )
        RPGMut.SaveAllData();
    RPGMut.cancheat=true;
}

function Teleport()
{
	local actor HitActor;
	local vector HitNormal, HitLocation;
	local bool bcanturn,bcanfly,bkarma,bcanmove,blockzero1,blockzero2;
	local asturret t;
	local onsmanualgunpawn o;
	local int i;
	local xpawn p;
	local actor viewtarget;
	local weapon w;

    if ( playercontroller(ownerc) == none || ( level.NetMode != nm_standalone && (ownerc.playerreplicationinfo == none ||
        !ownerc.playerreplicationinfo.bAdmin ) && ( ( !RPGMut.cancheat && !level.Game.bGameEnded &&
        ( !playercontroller(ownerc).isspectating() ||
        playercontroller(ownerc).viewtarget!=playercontroller(ownerc) ) ) ||
        ( playercontroller(ownerc).viewtarget!=playercontroller(ownerc) &&
        playercontroller(ownerc).viewtarget!=playercontroller(ownerc).pawn ) ) ) )
        return;
    if(playercontroller(ownerc).viewtarget==none || playercontroller(ownerc).viewtarget.Physics==phys_karmaragdoll)
        return;
    viewtarget=playercontroller(ownerc).viewtarget;
    t=asturret(viewtarget);
    o=onsmanualgunpawn(viewtarget);
    if(t!=none )
    {
        if(t.TurretBase!=none)
        {
            blockzero1=t.TurretBase.bBlockZeroExtentTraces;
            t.TurretBase.bBlockZeroExtentTraces=false;
        }
        if(t.TurretSwivel!=none)
        {
            blockzero2=t.TurretSwivel.bBlockZeroExtentTraces;
            t.TurretSwivel.bBlockZeroExtentTraces=false;
        }
    }
	HitActor = Trace(HitLocation, HitNormal, ViewTarget.Location + 20000 * vector(ownerc.Rotation),ViewTarget.Location, true);
    if(t!=none )
    {
        if(t.TurretBase!=none)
        {
            t.TurretBase.bBlockZeroExtentTraces=blockzero1;
        }
        if(t.TurretSwivel!=none)
        {
            t.TurretSwivel.bBlockZeroExtentTraces=blockzero2;
        }
    }
    if ( HitActor == None )
		HitLocation = ViewTarget.Location + 20000 * vector(ownerc.Rotation);
	else
		HitLocation = HitLocation + ViewTarget.CollisionRadius * HitNormal;

    if ( level.NetMode != nm_standalone && (ownerc.playerreplicationinfo == none || !ownerc.playerreplicationinfo.bAdmin ) &&
        level.Game.bGameEnded && xpawn(viewtarget) != none )
        foreach collidingactors(class'xpawn',p, 200, hitlocation)
            if(playercontroller( p.Controller)!=none && p!=viewtarget )
            {
                w = p.Weapon;
                if(rpgweapon(w) != none)
                    w = rpgweapon(w).ModifiedWeapon;
                if( w == none || ( !w.isa('translauncher') && instr(caps(p.Weapon.GetHumanReadableName() ), "TRANSLOC" ) < 0 &&
                    instr(caps(w.GetHumanReadableName() ), "TRANSLOC" ) < 0) )         //no annoying telefrag at game end
                {
                    pawn(viewtarget).bWarping = true;
                    break;
                }
            }

    if(ViewTarget.Physics==phys_karma )
    {
        if(karmaparams(ViewTarget.KParams)!=none)
		{
		    bcanturn=karmaparams(ViewTarget.KParams).bKAllowRotate;
		    bcanfly=karmaparams(ViewTarget.KParams).bKStayUpright;
		}
		ViewTarget.SetPhysics(phys_none);
		bkarma=true;
    }


    while(ViewTarget != none && !ViewTarget.SetLocation(HitLocation) && i < 10 )
    {
        HitLocation -= vector(ownerc.Rotation) * 0.09 * vsize(HitLocation - ViewTarget.Location);
        i++;
    }
    if(ViewTarget == none)
        return;
    if(xpawn(viewtarget)!=none)
        pawn(viewtarget).bWarping = false;
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
        for(i=0;i< RPGMut.statsinves.Length;i++)
            if(RPGMut.statsinves[i]!=none)
                RPGMut.statsinves[i].clientteleport(t,hitlocation);
    }
    else if(o!=none && o.Gun!=none)
    {
        o.Gun.SetLocation(hitlocation);
        for(i=0;i< RPGMut.statsinves.Length;i++)
            if(RPGMut.statsinves[i]!=none)
                RPGMut.statsinves[i].clientteleport(o.Gun, hitlocation);
    }
    else if ( ( ViewTarget.bSkipActorPropertyReplication || !ViewTarget.bReplicateMovement ) && ( (ViewTarget.Base == None) || ViewTarget.Base.bWorldGeometry) &&
        ( ( ViewTarget.RemoteRole == ROLE_DumbProxy ) || ( (ViewTarget.RemoteRole == ROLE_SimulatedProxy) && !ViewTarget.bUpdateSimulatedPosition) ) )
    {
        for(i=0;i< RPGMut.statsinves.Length;i++)
            if(RPGMut.statsinves[i]!=none)
                RPGMut.statsinves[i].clientteleport(ViewTarget, hitlocation);
    }
    if(bkarma)
    {
		ViewTarget.SetPhysics(phys_karma);
        if(karmaparams(ViewTarget.KParams)!=none)
		    ViewTarget.KSetStayUpright(bcanfly,bcanturn);
    }
}

function loadme(string rpgweaponclass, string weaponclass, optional int modifier)
{
    local weapon w;
    local rpgweapon rw;
    local int i;
    local class<rpgweapon> rwclass;
    local class<weapon> wclass;
    if ( instigator==none || playercontroller(instigator.controller) == none || ( level.NetMode != nm_standalone &&
        (instigator.controller.playerreplicationinfo == none || !instigator.controller.playerreplicationinfo.bAdmin ) &&
        ( ( !RPGMut.cancheat && !level.Game.bGameEnded ) || lastloaded > level.TimeSeconds - 3.0) ) )
        return;
    lastloaded = level.TimeSeconds;
    if(rpgweaponclass!="" && weaponclass!="")
    {
        for(i=0;i< RPGMut.AllWeaponClass.Length;i++)
        {
            if( RPGMut.AllWeaponClass[i].static.magicname() ~= rpgweaponclass )
            {
                rwclass=RPGMut.AllWeaponClass[i];
                break;
            }
        }
        for(i=0;i< RPGMut.Weapons.Length;i++)
        {
            if( getitemname(string(RPGMut.Weapons[i]) ) ~= weaponclass )
            {
                wclass=RPGMut.Weapons[i];
                break;
            }
        }
        if(wclass!=none && rwclass!=none)
        {
            rw = spawn(rwclass,instigator,,instigator.location);
            w =  spawn(wclass,rw,,instigator.location);
            if(w==none)
            {
                rw.Destroy();
                return;
            }
            if(rw==none)
            {
                w.Destroy();
                return;
            }
            rw.SetModifiedWeapon(w,true);
            if( level.NetMode != nm_standalone && (instigator.controller.playerreplicationinfo == none || !instigator.controller.playerreplicationinfo.bAdmin ) )
                Modifier=min(Modifier,rw.sanitymax);
            if(modifier>0)
                rw.Modifier = Modifier;
            else
                rw.Modifier=rw.MaxModifier;
            rw.GiveTo(instigator);
        }
    }
}

function rpgloaded()
{
    if ( instigator == none || playercontroller(instigator.controller) == none || ( level.NetMode != nm_standalone && (instigator.controller.playerreplicationinfo == none ||
        !instigator.controller.playerreplicationinfo.bAdmin ) && ( ( !RPGMut.cancheat && !level.Game.bGameEnded ) || lastloaded > level.TimeSeconds - 3.0) ) )
        return;
    lastloaded = level.TimeSeconds;
    class'druidloaded'.static.modifypawn(instigator, max(class'druidloaded'.default.maxlevel,5), self );
    class'druidartifactloaded'.static.modifypawn(instigator, max(class'druidartifactloaded'.default.maxlevel,3), self );
    instigator.Controller.AwardAdrenaline(instigator.Controller.AdrenalineMax);
    instigator.Controller.AwardAdrenaline(instigator.Controller.AdrenalineMax);   //hack for x42player altadrenaline
}

function SetWeaponSpeed(int speed)
{
    if (speed < 0 || instigator == none || playercontroller(ownerc) == none || ( level.NetMode != nm_standalone &&
        (ownerc.playerreplicationinfo == none || !ownerc.playerreplicationinfo.bAdmin ) &&
        ( (!RPGMut.cancheat && !level.Game.bGameEnded ) || RPGMut.StatCaps[0] == 0) ) || ( data.WeaponSpeed == speed ) )
        return;
    if( (ownerc.playerreplicationinfo == none || !ownerc.playerreplicationinfo.bAdmin ) && level.NetMode != nm_standalone )
    {
        if(RPGMut.StatCaps[0] > 0 )
            speed = min(speed, RPGMut.StatCaps[0]);
        else
            speed = min(speed, 1000);
    }
    speed -= data.WeaponSpeed;
    Data.WeaponSpeed = speed + data.WeaponSpeed;
    ClientSetWeaponSpeed( int(float(speed) * 2.5) );
    if(instigator.drivenvehicle != none)
    {
        modifyvehicle(instigator.DrivenVehicle,instigator.DrivenVehicle.ParentFactory);
        clientmodifyvehicle(instigator.DrivenVehicle,instigator.DrivenVehicle.ParentFactory,
            2 * byte(instigator.DrivenVehicle.bCanPickupInventory));
    }
    if(instigator.Weapon != none)
        adjustfirerate(instigator.Weapon);
}

function logitems(optional bool bwriteall)
{
    local saveinv s;
    local inventory i;
    if(level.NetMode != nm_standalone && (ownerc == none || ownerc.PlayerReplicationInfo == none || !ownerc.PlayerReplicationInfo.bAdmin) )
        return;
    s = saveinv(instigator.FindInventoryType(class'saveinv') );
    if(s != none)
    {
        log(s.numitems$" items");
        instigator.ClientMessage(s.numitems$" items");
    }
    if(bwriteall)
    {
        for(i = instigator.Inventory; i != none; i = i.Inventory)
            log(i.GetHumanReadableName() );
    }
}

function deleteweapons()
{
    local oldweaponholder h;
    if(lastdeleted > level.TimeSeconds - 20.0)
        return;
    if(playercontroller(ownerc) != none)
    {
        foreach ownerc.ChildActors(class'oldweaponholder',h)
            h.Destroy();
        h = ownerc.spawn(class'oldweaponholder',ownerc);
        h.id = playercontroller(ownerc).GetPlayerIDHash();
        playercontroller(ownerc).clientmessage("Weapon list cleared.");
    }
    lastdeleted = level.TimeSeconds;
}

function getproperty(string objectname, string propertyname, bool all, string classname)
{
    local object o, obj, stuff;
    local class c, baseclass, temp;
    local string pack;
    local string objclass;
    local string r, s;
    local array<string> properties, as;
    local int i, j;
    if(playercontroller(ownerc) == none || (level.NetMode != NM_Standalone && (ownerc.PlayerReplicationInfo == none ||
        !ownerc.PlayerReplicationInfo.bAdmin) ) )
        return;
    if(divide(objectname,".",pack,objclass))
        c = class(dynamicloadobject(objectname,class'class',true));
    if(classname != "")
        baseclass = class<object>(dynamicloadobject(classname,class'class'));
    if(c != none)
        temp = c;
    else
        temp = class'object';
    foreach allobjects(temp,o)
    {
        if( (c != none ) || (c == none && ( (objclass != "" && string(o.name) ~= objclass &&
            o.Outer != none && string(o.Outer.Name) ~= pack) || ( (string(o.Name) ~= objectname ||
            (actor(o) != none && objectname ~= actor(o).GetHumanReadableName() ) ) && (baseclass == none || o.Class == baseclass)) ) ) )
        {
            j++;
            r = "";
            s = "";
            s = string(o.Name);
            stuff = o;
            split(propertyname,".",properties);
            for(i = 0; i < properties.Length; i++)
            {
                 s $= " " $ properties[i];
                 r = "";
                 r = stuff.GetPropertyText(properties[i]);
                 s $= " " $ r $ ".";
                 stuff = none;
                 if(split(r,"'",as) > 1)
                     r = as[1];
                 foreach allobjects(class'object',obj)
                 {
                     if(string(obj) ~= r)
                     {
                         stuff = obj;
                         break;
                     }
                 }
                 if(stuff == none || i >= properties.Length - 1)
                     break;
                 else
                     s $= " " $ stuff;
            }
            clientlog(s);
            if(!all)
            {
                playercontroller(ownerc).ClientMessage(s);
                break;
            }
        }
    }
    if(j == 0)
        playercontroller(ownerc).ClientMessage("Object "$objectname$" not found.");
}

simulated function clientlog(string s)
{
    log(s);
}

defaultproperties
{
     afk=True
     bClear=True
     SkinQuality=SQ_High
     bShowStatPointMessage=True
     bReplicateInstigator=True
     bNetNotify=True
}

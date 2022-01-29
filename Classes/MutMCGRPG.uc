class MutMCGRPG extends Mutator
	config(mcgRPG199FT2Update1);

const RPG_VERSION = 1991;
const PROPNUM = 30;
const ACTORNUM = 64;
const SKINNUM = 16;
const ABILITYNUM = 26;
const MODIFIERNUM = 16;
const ARTIFACTNUM = 9;
var() config bool bcheckalldata;    //if true, check all rpgplayerdataobject for validate data (set it true, when replace an older mcgrpg version with a new one)
var() config int nextdata;  //next rpgplayerdataobject to validate, if bcheckalldata is true, because all operations take too long time
var() config int maxmultikillexp;  //maximum exp for multikills/sprees instead the infinite levelup in official rpg versions (min. 5 )
var() config float SaveDuringGameInterval; //periodically save during game - to avoid losing data from game crash or server kill
var() config int StartingLevel; //starting level - cannot be less than 1
var() config int PointsPerLevel; //stat points per levelup
var() config array<int> Levels; //Experience needed for each level, NOTE: Levels[x] is exp needed for Level x+1
var() config int InfiniteReqEXPValue; //add this value to the EXP required for next level
var() config float LevelDiffExpGainDiv; //divisor to extra experience from defeating someone of higher level (a value of 1 results in level difference squared EXP)
var() config int MaxLevelupEffectStacking; //maximum number of levelup effects that can be spawned if player gains multiple levels at once
var() config int EXPForWin; //EXP for winning the match (given to each member of team in team games)  (min 20)
var() config int BotBonusLevels; //extra levelups bots gain after matches to counter that they're in only a fraction of the matches played (only if bFakeBotLevels is false)
var() config int StatCaps[6]; //by popular demand :(
var() config array<class<RPGAbility> > AllAbilities;  //All existing ability
var() config array<class<RPGAbility> > Abilities; //List of Abilities available to players
var() config array<class<RPGAbility> > RemovedAbilities; //These Abilities failed an AbilityIsAllowed() check so try to re-add them next game
var() config float WeaponModifierChance; //chance any given pickup results in a weapon modifier (0 to 1)
var() config bool bEXPForHealing; //rw_healer gives exp for healing a teammate. note: only adds exp, if teammate was damaged by an opponent
var() config bool bTeamBasedEXP; //if true exp for win given depends of how many times player was in the winner team during the match and half of the exp given as original
var() config float ServerTime;   //total game time passed since server started first - used to delete RPGPlayerDataObject, which was not used long ago
var() config int MonthsToDelete; //time passed since player joined server last timer in months (2600000 seconds)
var() config byte bcheckafk;  //if > 0, no exp for level difference if killed was afk.
var() config bool bExperiencePickups; //replace adrenaline pickups with experience pickups
var() config array<name> SuperAmmoClassNames; // names of ammo classes that belong to superweapons (WARNING: subclasses MUST be listed seperately!)
var() config bool bFakeBotLevels; //if true, bots' data isn't saved and they're simply given a level near that of the players in the game
var() config byte MaxTurrets; //maximum number of turrets
var() config float InvasionAutoAdjustFactor; //affects how dramatically monsters increase in level for each level of the lowest level player

var() WebServer Server;
var() bool bChecked;

var() StringArray AbilityList;
var() array<class<RPGAbility> > RemainderAbilities;

var() config array<class<RPGArtifact> > ArtifactClasses;
var() StringArray ArtifactList;
var() string ArtifactOptions;

var() array<rpgstatsinv> statsinves;
var() int statsindex;  //to optimized savedata

var() int BreakLoop;               //
var() config byte maxinv;          //try to prevent server from crash

var() int nickindex,currentnickindex;

var() config float spawnprotectiontime; //spawn protection hack

var() rpgartifactmanager ArtifactManager;

var() bool bGameRestarted;

var() array<lockertrigger> ltriggers; //for set max ammo, when somebody load up from a weaponlocker


//A modifier a weapon might be given
struct WeaponModifier
{
	var class<RPGWeapon> WeaponClass;
	var int Chance; //chance this modifier will be used, relative to all others in use
};
var() config array<class<RPGWeapon> > AllWeaponClass;
var() config array<WeaponModifier> WeaponModifiers;
var() StringArray ModifierList;
var() array<class<RPGWeapon> > RemainderWeaponModifiers;
var() int TotalModifierChance; //precalculated total Chance of all WeaponModifiers

var() bool bHasInteraction;
var() bool bJustSaved;

enum emonsterleveladjustment
{
    ma_none,            //no adjust
    ma_normal,          //adjust in normal game
    ma_invasion,        //adjust in invasion
    ma_all              //adjust in all gametypes
};
var() config emonsterleveladjustment bAutoAdjustMonsterLevel; //auto adjust monsters' level.

var() int BotSpendAmount; //bots that are buying stats spend points in increments of this amount
var() config string HighestLevelPlayerName; //Highest level player ever to display in server query for all to see :)
var() config int HighestLevelPlayerLevel;
var() transient RPGPlayerDataObject CurrentLowestLevelPlayer; //Data of lowest level player currently playing (for auto-adjusting monsters, etc)
//note: i don't know, y playinfo can't handle string arrays...
var() localized string PropsDisplayText[PROPNUM];
var() localized string PropsDescText[PROPNUM];
var() localized string PropsExtras;

var() rpgrules rpgrulz;

var() turretmarker tmarker;
var() bool bTurretHack;

struct turretstruct
{
    var string id;
    var array<vehicle> turrets;
};

var() array<turretstruct> turretstructs;

struct statstruct
{
    var string id;
    var playerreplicationinfo pri;
    var float adr;
    var string otherstat;
};

var() array<statstruct> stats;
var() config string stattypes;   //extra properties (e.g. if player is not normal xplayer)
var() config string resetstats;
var() array<byte> bReset;
var() array<string> statstring;


struct statpair
{
    var string property;
    var string value;
};


// list of markers associated with players using the Vampire ability
// the Vampire ability needs an easy way to find them and this is the best persistent object to place them on
// (in a perfect world, we'd use the Pawn or Controller, but I don't want to subclass them for compatibility reasons)
var() array<VampireMarker> VampireMarkers;

var() bool cancheat;
var() config array<class<weapon> > weapons;
var() config bool brefreshweaponlist;
var() string WeaponOptions;

var() string PendingName;
var() array<RPGPlayerDataObject> DataObjectList;

struct loginstruct
{
    var PlayerController p;
    var string n;
};

var() array<loginstruct> Players;

var() actor actors[ACTORNUM];
var() rpgstatsinv LocalStatsinv;
var() float lastpurgetime;
struct shaderstruct
{
    var bool inuse;
    var actor skinbase;
    var shader weaponskins[SKINNUM];
};
var() shaderstruct shaders[ACTORNUM];

replication
{
	reliable if ( Role == ROLE_Authority)
		actors;
}

static final function int GetVersion()
{
	return RPG_VERSION;
}

// simple utility to find the mutator in the given level
static final function MutMCGRPG GetRPGMutator(actor a)
{
	local MutMCGRPG RPGMut;

	foreach a.DynamicActors(class'MutMCGRPG',RPGMut)
	{
	    if(RPGMut.Level == a.Level)
	        return RPGMut;
    }

	return none;
}

//returns true if the specified ammo belongs to a weapon that we consider a superweapon
static final function bool IsSuperWeaponAmmo(class<Ammunition> AmmoClass)
{
	local int i;

	if ( ( AmmoClass.default.charge==0 && AmmoClass.default.MaxAmmo < 5) || (AmmoClass.default.charge<5 &&
        AmmoClass.default.charge>0) )
	{
		return true;
	}
	else
	{
		for (i = 0; i < default.SuperAmmoClassNames.length; i++)
		{
			if (string(AmmoClass.Name) ~= string(default.SuperAmmoClassNames[i]))
			{
				return true;
			}
		}
	}

	return false;
}

function bool CanEnterVehicle(Vehicle V, Pawn P)
{
    local turretmarker t;
    local artifactinvulnerability a;
    if(p == none)
        return false;
    if(level.Game.bGameEnded)
        return true;
	if( NextMutator != None && !NextMutator.CanEnterVehicle(V, P) )
	    return false;
    a = artifactinvulnerability(p.FindInventoryType(class'artifactinvulnerability') );
    if(a != none && a.bActive)
        return false;
    t=turretmarker( v.FindInventoryType(class'turretmarker') );
    if(t!=none)
    {
        if( !t.bunlocked && p.Controller!=none && playercontroller(t.instigatorcontroller) != none &&
            p.Controller.SameTeamAs( t.instigatorcontroller ) && p.Controller != t.instigatorcontroller )
            return false;
        if( p.Controller!=none && !p.Controller.SameTeamAs( t.instigatorcontroller ) )
            t.instigatorcontroller = p.Controller;   //turret stolen by an opponent
        tmarker=t;                         //save the turretmarker
        v.DeleteInventory(t);
    }
	return true;
}

function bool CanLeaveVehicle(Vehicle V, Pawn P)
{
    local turretmarker t;
    local controller c;
    local artifactinvulnerability a;

    if(v.Health <= 0)
        return false;
    if(v.Controller == none)
    {
        v.Controller = controller(v.Owner);
        if(v.Controller == none)
        {
            foreach dynamicactors(class'controller',c)
            {
                if(c.Pawn == v)
                {
                    v.Controller = c;
                    break;
                }
            }
        }
        if(v.Controller == none)
            return false;
    }

    if(p == none)
        return false;
    if(level.Game.bGameEnded)
        return true;
	if( NextMutator != None && !NextMutator.CanLeaveVehicle(V, P) )
	    return false;
    a = artifactinvulnerability(v.FindInventoryType(class'artifactinvulnerability') );
    if(a != none && a.bActive)
        return false;
    t=turretmarker( v.FindInventoryType(class'turretmarker') );
    if(t!=none)
    {
        tmarker=t;                         //save the turretmarker
        v.DeleteInventory(t);
    }
	return true;
}

function bool AlwaysKeep(Actor Other)
{
	local ExperiencePickup EXP;
	local int x,y,z;
	local RPGStatsInv StatsInv;
	local Weapon Weap;
	local inventory i;
	local bool dropped,bRemoveReference;
	local rpgweapon rw;
	local RPGWeapon OldWeapon;
	local class<RPGWeapon> NewWeaponClass;
	local pawn inst;
    local rpgweaponpickup rp;
	local bool exist;

    if(adrenalinepickup(other) != none)
    {
        if(NextMutator != None)
            NextMutator.AlwaysKeep(Other);
        if(bexperiencepickups)
        {
		    EXP = ExperiencePickup(ReplaceWithActor(Other, "mcgRPG1_9_9_1.ExperiencePickup"));
		    if (EXP != None)
			    EXP.RPGMut = self;
	        return false;
        }
        else return true;
    }
    if(saveinv(other) != none)
    {
        saveinv(other).RPGMut = self;
        saveinv(other).maxinv = maxinv;
        return true;
    }
	if (Weapon(Other) != none )
	{
	    Weap = Weapon(Other);
	    for (x = 0; x < Weap.NUM_FIRE_MODES; x++)
	    {
	        if (Weap.FireModeClass[x] == class'shieldaltFire')
	            Weap.FireModeClass[x] = class'RPGShieldaltFire';
            if(Weap.FireModeClass[x] != none && Weap.FireModeClass[x].default.AmmoClass != none &&
                Weap.FireModeClass[x].default.AmmoClass.default.AmmoAmount > 0)
            {
                Weap.FireModeClass[x].default.AmmoClass.default.InitialAmount =
                    Weap.FireModeClass[x].default.AmmoClass.default.AmmoAmount;
                Weap.FireModeClass[x].default.AmmoClass.default.AmmoAmount = 0;
            }
        }
	}
	else if(WebServer(other) != none && WebServer(other).bEnabled && level.NetMode != NM_StandAlone)
	    Server = WebServer(other);
	else if ( WeaponLocker(other)!=none )
	{
        if(other.event=='' || other.event=='none' )
        {
            if( ltriggers.Length==0 )
                ltriggers[0]= spawn(class'lockertrigger',,'rpgammohaxforeva');
            else
            {
                for(x=0;x< ltriggers.Length;x++)
                    if(ltriggers[x].tag=='rpgammohaxforeva' )
                    {
                        exist=true;
                        break;
                    }
                if(!exist)
                    ltriggers[ltriggers.Length]=spawn(class'lockertrigger',,'rpgammohaxforeva');
            }
            other.Event='rpgammohaxforeva';
        }
        else
        {
            if( ltriggers.Length==0 )
                ltriggers[0]= spawn(class'lockertrigger',,other.event);
            else
            {
                for(x=0;x< ltriggers.Length;x++)
                    if(ltriggers[x].tag==other.event )
                    {
                        exist=true;
                        break;
                    }
                if(!exist)
                    ltriggers[ltriggers.Length]=spawn(class'lockertrigger',,other.event);
            }
        }

    }
	if (WeaponModifierChance > 0)
	{
		if ( WeaponPickup(Other) != none && class<weapon>(WeaponPickup(Other).inventorytype) != none &&
            !class<weapon>(WeaponPickup(Other).inventorytype).default.bNoInstagibReplace)
		{
		    other.MessageClass = class'emptymessage';
            rp = spawn(class'rpgweaponpickup',,,Other.location,Other.rotation);
            rp.ReplacedPickup = WeaponPickup(Other);
            rp.SetBase(other);
		    if( other.Instigator!=none )
		    {
		        for(i = other.Instigator.Inventory; i != none; i = i.Inventory)
		        {
		            if(rpgweapon(i) != none && (other == rpgweapon(i).PendingPickup[0] || other == rpgweapon(i).PendingPickup[1] ) )
		            {
		                weap = rpgweapon(i);
		                break;
		            }
                }
                if(weap == none)
		            weap = other.Instigator.Weapon;
		        if(weap != none && ( (rpgweapon(weap) != none && rpgweapon(weap).ModifiedWeapon != none &&
                    rpgweapon(weap).ModifiedWeapon.PickupClass == other.class) || weap.PickupClass == other.class) )
		        {
                    rw = rpgweapon(weap);
                    if(rw != none)
		            {
		                other.SetOwner(weap);
		                rw.References++;
	                    if(rw.ModifierOverlay != none)
	                    {
		                    other.SetOverlayMaterial(rw.ModifierOverlay,1000000.0,true);
	                        if(other.DrawType == dt_staticmesh || ( other.DrawType == dt_mesh && other.skins.length > 0 ) )
	                        {
                                for(y = 0; y < ACTORNUM; y++)
                                {
                                    if(actors[y] == none)
                                    {
                                        actors[y] = other;
                                        z = y + 1;
                                        break;
                                    }
                                }
                                if(level.NetMode != nm_dedicatedserver)
                                    postnetreceive();
                            }
                        }
		                weap = none;
		            }
                }
                else
                    weap = none;
		        dropped = true;
		        if(weap != none)
		        {
		            for(i=other.Instigator.Inventory;i!=none;i=i.Inventory)
		            {
		                rw = rpgweapon(i);
		                if(rw!=none && rw.ModifiedWeapon==Weap)
                            break;
                        rw = none;
                    }
                }
		    }
		    else weap = none;
		    if(dropped && weap != none)
		    {
		        if(rw == none && !weap.bNoInstagibReplace)
		        {
                    if (level.Game.bWeaponStay && weaponpickup(other).bWeaponStay)
	                {
		                //if player previously had a weapon of class InventoryType, force modifier to be the same
		                StatsInv = RPGStatsInv(Other.Instigator.FindInventoryType(class'RPGStatsInv'));
		                if (StatsInv != None)
			                for (x = 0; x < StatsInv.OldRPGWeapons.length; x++)
				               if (StatsInv.OldRPGWeapons[x].ModifiedClass == weap.Class)
				               {
					               OldWeapon = StatsInv.OldRPGWeapons[x].Weapon;
					               if (OldWeapon != None)
						               NewWeaponClass = OldWeapon.Class;
					               break;
			                   }
                    }
	                if(newweaponclass == none)
	                    newweaponclass = GetRandomWeaponModifier(Weap.Class, other.Instigator);
		            rw = other.Instigator.spawn(newweaponclass,other.Instigator,,, rot(0,0,0));
		            rw.Generate(oldweapon);
		            rw.SetModifiedWeapon(Weap,false);
		            other.Instigator.DeleteInventory(Weap);
		            Weap.SetOwner(other.Instigator);
                }

		        if(rw != none && !rw.bPendingDelete)
		        {
		            rw.dropped(weaponpickup(other) );
                    other.SetOwner(rw);
                    if(rw.ModifierOverlay != none)
       	            {
                        other.SetOverlayMaterial(rw.ModifierOverlay,1000000.0,true);
                        for(y = 0; y < ACTORNUM; y++)
                        {
                            if(actors[y] == none)
                            {
                                actors[y] = other;
                                z = y + 1;
                                break;
                            }
                        }
                        if(z == 0)
                        {
                            for(y = 0; y < ACTORNUM; y++)
                                actors[y] = none;
                            actors[0] = other;
                        }
                        if(level.NetMode != nm_dedicatedserver)
                            postnetreceive();
                    }
                }
            }
		}
		else
		{
			Weap = Weapon(Other);
			if (Weap != None)
			{
				for (x = 0; x < Weap.NUM_FIRE_MODES; x++)
				{
					if (Weap.FireModeClass[x] == class'ShockProjFire')
						Weap.FireModeClass[x] = class'RPGShockProjFire';
					else if (Weap.FireModeClass[x] == class'PainterFire')
						Weap.FireModeClass[x] = class'RPGPainterFire';
					else if (Weap.FireModeClass[x] == class'onsPainterFire')
						Weap.FireModeClass[x] = class'RPGonsPainterFire';
					else if (Weap.FireModeClass[x] == class'TransFire')
						Weap.FireModeClass[x] = class'RPGTransFire';
					else if (Weap.FireModeClass[x] == class'LinkFire')
						Weap.FireModeClass[x] = class'RPGLinkFire';
					else if (Weap.FireModeClass[x] == class'LinkAltFire')
						Weap.FireModeClass[x] = class'RPGLinkAltFire';
				}
		        if(rpgweapon(weap.Owner) != none && weap.Instigator != none )
		        {
		            weap.SetOwner(weap.Instigator);
		        }
		        else if(rpgweapon(weap.Owner) == none && !weap.bNoInstagibReplace )
		        {
                    if(weap.Instigator != none)
                        inst = weap.Instigator;
                    else inst = pawn(weap.Owner);
                    if (level.Game.bWeaponStay && class<weaponpickup>(weap.PickupClass) != none && class<weaponpickup>(weap.PickupClass).default.bWeaponStay &&
                        inst != none)
	                {
		                //if player previously had a weapon of class InventoryType, force modifier to be the same
		                if( (inst.PlayerReplicationInfo != none && inst.PlayerReplicationInfo.bAdmin ) || level.NetMode == nm_standalone)
		                    StatsInv = RPGStatsInv(Inst.FindInventoryType(class'RPGStatsInv') );
                        else
                        {
		                    for(i = inst.Inventory; i != none; i = i.Inventory)
		                    {
		                        if(statsinv == none && i.Class == class'rpgstatsinv')
		                            statsinv = rpgstatsinv(i);
                                x++;
                                if(x > 150 || (maxinv == 0 && x > 65) )
                                    return false;
                            }
		                }
		                if (StatsInv != None)
			                for (x = 0; x < StatsInv.OldRPGWeapons.length; x++)
				               if (StatsInv.OldRPGWeapons[x].ModifiedClass == weap.Class)
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
	                if(newweaponclass == none)
	                    newweaponclass = GetRandomWeaponModifier(Weap.Class, Inst);
                    if(inst != none)
		                rw = Inst.spawn(newweaponclass,Inst,,, rot(0,0,0));
	                else rw = spawn(newweaponclass,,,, rot(0,0,0));
		            rw.Generate(oldweapon);
		            rw.SetModifiedWeapon(Weap,false);
                    if (bRemoveReference)
                        OldWeapon.RemoveReference();
                }
			}
		}
	}
	return( NextMutator != None && NextMutator.AlwaysKeep(Other) );
}

simulated function PostBeginPlay()
{
	local RPGRules G;
	local int x,y,z;
	local Pickup P;
	local RPGPlayerDataObject DataObject,temp;
	local array<string> PlayerNames;
	local bool changed;
    local array< cachemanager.weaponrecord > record;
    local class<weapon> weap;
    local actor a;
    local controller c;
    local object o;
    local array<string> resetstring;


    for(x = 0; x < allabilities.Length; x++)
        allabilities[x].default.copy = "";
    if(level.NetMode == nm_client)
    {
	    foreach allobjects(class'object',o)
	    {
	        if(class<weapon>(o) != none )
            {
                if(class<weapon>(o).default.FireModeClass[0] == class'LinkFire' )
                    class<weapon>(o).default.FireModeClass[0] = class'RPGLinkFire';
                if(class<weapon>(o).default.FireModeClass[0] == class'LinkAltFire' )
                    class<weapon>(o).default.FireModeClass[0] = class'RPGLinkAltFire';
                if(class<weapon>(o).default.FireModeClass[1] == class'LinkFire' )
                    class<weapon>(o).default.FireModeClass[1] = class'RPGLinkFire';
                if(class<weapon>(o).default.FireModeClass[1] == class'LinkAltFire' )
                    class<weapon>(o).default.FireModeClass[1] = class'RPGLinkAltFire';
            }
        }
        return;
    }
    class'onslaught.ONSMineThrowFire'.default.ProjectileClass = class'mcgRPG1_9_9_1.ONSMineProjectileFixed';
    class'onslaught.ONSMineThrowFire'.default.RedMineClass = class'mcgRPG1_9_9_1.ONSMineProjectileREDFixed';
    class'onslaught.ONSMineThrowFire'.default.BlueMineClass = class'mcgRPG1_9_9_1.ONSMineProjectileBLUEFixed';

    split(stattypes,",",statstring);
    split(resetstats,",",resetstring);
    resetstring.Length = statstring.Length;
    bReset.Length = resetstring.Length;
    for(x = 0; x < resetstring.Length; x++)
        bReset[x] = byte(resetstring[x]);
    if(maxturrets < 0)
        maxturrets = 0;
    if(maxturrets == 0)
        class'druidartifactloaded'.default.MaxLevel = min(2,class'druidartifactloaded'.default.MaxLevel);
    maxinv = max(maxinv,0);
    if(brefreshweaponlist)
    {
        weapons.length = 0;
        class'cachemanager'.static.GetWeaponList(record);
        for( x=0; x < record.Length; x++)
        {
            Weap = class<Weapon>(DynamicLoadObject(record[x].classname, class'Class') );
            if( weap != none && !weap.default.bnoinstagibreplace && !(classischildof(weap,class'translauncher') ) )
                weapons[weapons.length] = weap;
        }
        brefreshweaponlist = false;
    }
    if(statcaps[0] > 0)
        if(statcaps[0] % 2 != 0)
            statcaps[0] --;
    if(statcaps[1] > 0)
        while(statcaps[1] % 3 != 0)
            statcaps[1] --;
    maxmultikillexp=max(maxmultikillexp,5);
    expforwin=max(expforwin,20);
    PointsPerLevel = max(PointsPerLevel, 1);
    ServerTime = fmax(ServerTime, 0.1);

	G = spawn(class'RPGRules');
	if(deathmatch(level.Game).SpawnProtectionTime >= 0.0)
        spawnprotectiontime=deathmatch(level.Game).SpawnProtectionTime;
    deathmatch(level.Game).SpawnProtectionTime=-1.0;
    g.spawnprotectiontime=spawnprotectiontime;
	G.RPGMut = self;
	g.bcheckafk=bcheckafk;
	G.PointsPerLevel = PointsPerLevel;
	G.LevelDiffExpGainDiv = LevelDiffExpGainDiv;
	//RPGRules needs to be first in the list for compatibility with some other mutators (like UDamage Reward)
	if (Level.Game.GameRulesModifiers != None)
		G.NextGameRules = Level.Game.GameRulesModifiers;
	Level.Game.GameRulesModifiers = G;
	rpgrulz=g;

    PlayerNames = class'RPGPlayerDataObject'.static.GetPerObjectNames("mcgrpg",, 1000000);
    log( "Number of all playerdata: "$PlayerNames.length );

	HighestLevelPlayerLevel = 0;

	if (StartingLevel < 1)
		StartingLevel = 1;

    if(bcheckalldata && !cancheat)
	{
	    if( ( nextdata +  25 ) >= PlayerNames.length)
	    {
	        y = PlayerNames.length;
	        bcheckalldata = false;
        }
	    else
	        y = nextdata + 25;
		for (x = nextdata; x < y ; x++)
		{
			DataObject = new(None, PlayerNames[x]) class'RPGPlayerDataObject';
			changed=false;
			if( DataObject.Level > 1 )
			{
			    temp = new(None, "RPGPlayerDataObject") class'RPGPlayerDataObject';
			    temp.CopyDataFrom(DataObject);
			    dataobject.abilities.length=max(dataobject.abilities.length,max(dataobject.Abilitynames.Length, dataobject.AbilityLevels.Length) );
			    validatedata(dataobject, none );
			    if(dataobject.ServerTime == 0.0)
			    {
			        dataobject.ServerTime = ServerTime;
			        changed = true;
			    }
			    else if(MonthsToDelete > 0 && ServerTime - dataobject.ServerTime > 2600000.0 * float(MonthsToDelete) )
			    {
			        DataObject.ClearConfig();
                    PlayerNames.Remove(x,1);
                    y--;
                    x--;
			        continue;
			    }
			    else if( dataobject.Abilitynames.Length != temp.Abilitynames.Length || dataobject.AbilityLevels.Length != temp.AbilityLevels.Length ||
                    dataobject.abilities.Length != temp.abilities.Length )
                    changed=true;
                else
                {
			        for(z=0;z<dataobject.abilities.length;z++)
                        if( dataobject.abilities[z] != temp.abilities[z] || dataobject.Abilitynames[z] != temp.Abilitynames[z] ||
                            dataobject.AbilityLevels[z] != temp.AbilityLevels[z] )
                        {
                            changed=true;
                            z = dataobject.abilities.length;
                        }
                }
			    if( changed || dataobject.weaponspeed != temp.weaponspeed || dataobject.HealthBonus != temp.HealthBonus || dataobject.Attack != temp.Attack ||
                    dataobject.Defense != temp.Defense || dataobject.PointsAvailable != temp.PointsAvailable )
                {
			        dataobject.SaveConfig();
			        changed=true;
                }
            }
			if( !changed )
			{
			    if( DataObject.Level > startinglevel || dataobject.Experience > 0 )
			    {
			        if(y < PlayerNames.length)
			            y++;
                }
			    else
                {
                    DataObject.ClearConfig();
                    PlayerNames.Remove(x,1);
                    y--;
                    x--;
                }
			}
		}
	    log("Data validation "$nextdata$" - "$y);
        if(bcheckalldata)
        {
            if(y == PlayerNames.length)
            {
                bcheckalldata = false;
	            nextdata = 0;
            }
            else
	            nextdata = y;
        }
        else
	        nextdata = 0;
	}
	else nextdata=0;
	for (x = 0; x < PlayerNames.length; x++)
	{
	    DataObject = new(None, PlayerNames[x]) class'RPGPlayerDataObject';
	    DataObjectList[DataObjectList.Length] = DataObject;
	    if( DataObject.Level > HighestLevelPlayerLevel )
	    {
    	    HighestLevelPlayerLevel = DataObject.Level;
			HighestLevelPlayerName = string(DataObject.Name);
  	    }
	}
    log("Done.");
	PlayerNames.Remove(0, PlayerNames.Length);
    PlayerNames = class'TempRPGPlayerDataObject'.static.GetPerObjectNames("RPGTemp");
	for (x = 0; x < PlayerNames.length; x++)
	{
	    temp = none;
        for(y = 0; y < DataObjectList.Length; y++)
        {
            if(string(DataObjectList[y].Name) ~= PlayerNames[x] )
            {
                temp = DataObjectList[y];
                y = DataObjectList.Length;
            }
        }
        if(temp == none)
            temp = new(none,PlayerNames[x]) class'RPGPlayerDataObject';
        DataObjectList.Insert(DataObjectList.Length,1);
        DataObjectList[DataObjectList.Length - 1] = temp;
	    DataObject = new(None, PlayerNames[x]) class'TempRPGPlayerDataObject';
        temp.CopyDataFrom(DataObject);
        temp.SaveConfig();
        DataObject.ClearConfig();
	}
	for (x = 0; x < WeaponModifiers.length; x++)
		TotalModifierChance += WeaponModifiers[x].Chance;
	if(TotalModifierChance == 0)
	{
	    for (x = 0; x < WeaponModifiers.length; x++)
		    WeaponModifiers[x].Chance = 1;
	    TotalModifierChance = WeaponModifiers.length;
    }

	artifactmanager=spawn(class'RPGArtifactManager');
	if(artifactmanager == none || artifactmanager.bpendingdelete)
	    artifactmanager = none;
	if(level.GRI != none && level.GRI.bMatchHasBegun)
	    artifactmanager.MatchStarting();

    if (SaveDuringGameInterval > 0.0 )
    {
        if( level.NetMode != nm_standalone)
		    SetTimer(SaveDuringGameInterval/fmax(1.0,float(level.Game.numPlayers) ), false);
		else
		    SetTimer(SaveDuringGameInterval, true);
    }


	BotSpendAmount = PointsPerLevel * 3;

	if(level.TimeSeconds > 0.0)
	{
	    foreach allactors(class'actor',a)
	        if(a.bScriptInitialized && !a.bGameRelevant && !checkrelevance(a) && !a.bStatic && !a.bNoDelete)
	            a.Destroy();
        for(c = level.ControllerList; c != none; c = c.nextController)
        {
       	    if (c.Pawn!=none && c.bIsPlayer && !level.Game.bGameRestarted && Level.Game.ResetCountDown == 0 && vehicle(c.Pawn) == none &&
               !c.Pawn.bPendingDelete && c.Pawn.Health > 0)
		    modifyplayer(c.Pawn);
        }
	}
	else
	{
	    //HACK - if another mutator played with the weapon pickups in *BeginPlay() (like Random Weapon Swap does)
	    //we won't get CheckRelevance() calls on those pickups, so find any such pickups here and force it
	    foreach DynamicActors(class'Pickup', P)
	    {
		    if (P.bScriptInitialized && !P.bGameRelevant && !CheckRelevance(P))
			    P.Destroy();
        }
	}
	    //remove any disallowed abilities
	    for (x = 0; x < Abilities.length; x++)
	    {
		    if (Abilities[x] == None)
		    {
			    Abilities.Remove(x, 1);
			    x--;
		    }
		    else
		    {
		        if (!Abilities[x].static.AbilityIsAllowed(Level.Game, self))
		        {
			        RemovedAbilities[RemovedAbilities.length] = Abilities[x];
			        Abilities.Remove(x, 1);
			        x--;
		        }
            }
	    }

	    //See if any abilities that weren't allowed last game are allowed this time
	    //(so user doesn't have to fix ability list when switching gametypes/mutators a lot)
	    for (x = 0; x < RemovedAbilities.length; x++)
		    if (RemovedAbilities[x].static.AbilityIsAllowed(Level.Game, self))
		    {
			    Abilities[Abilities.length] = RemovedAbilities[x];
			    RemovedAbilities.Remove(x, 1);
			    x--;
		    }
    MakeOptions();
	SaveConfig();

	Super.PostBeginPlay();
}

function MakeOptions()
{
	local int i;

	AbilityList = New(None) class'SortedStringArray';

	for (i = 0; i < AllAbilities.Length; i++)
		AbilityList.Add( string(AllAbilities[i]), AllAbilities[i].default.AbilityName );

	ModifierList = New(None) class'SortedStringArray';

	for (i = 0; i < AllWeaponClass.Length; i++)
		ModifierList.Add( string(AllWeaponClass[i]), AllWeaponClass[i].static.magicname() );

	ArtifactList = New(None) class'SortedStringArray';

	for (i = 0; i < ArtifactClasses.Length; i++)
		ArtifactList.Add( string(ArtifactClasses[i]), ArtifactClasses[i].default.ItemName );
}

function servertraveling(string url, bool b)
{
    local class<ammunition> a;
    local object o;
	local Controller C;
	local Inventory Inv;

    super.ServerTraveling(url,b);
    class'onslaught.ONSMineThrowFire'.default.ProjectileClass = Class'Onslaught.ONSMineProjectile';
    class'onslaught.ONSMineThrowFire'.default.RedMineClass = Class'Onslaught.ONSMineProjectileRED';
    class'onslaught.ONSMineThrowFire'.default.BlueMineClass = Class'Onslaught.ONSMineProjectileBLUE';
    DataObjectList.Remove(0,DataObjectList.Length);
    foreach allobjects(class'object',o)
    {
        a=class<ammunition>(o);
        if(a!=none)
        {
            if(a.default.Charge>0)
            {
                a.default.MaxAmmo=a.default.Charge;
                a.default.Charge=0;
            }
            if(a.default.AmmoAmount>0)
            {
                a.default.InitialAmount=a.default.AmmoAmount;
                a.default.AmmoAmount=0;
            }
        }
    }
    if( deathmatch(level.Game).SpawnProtectionTime == -1.0)
        deathmatch(level.Game).SpawnProtectionTime=spawnprotectiontime;
    bGameRestarted=true;
	//null all RPGPlayerDataObject references so everything gets properly garbage collected
	for (C = Level.ControllerList; C != None; C = C.NextController)
		if (C.bIsPlayer)
			for (Inv = C.Inventory; Inv != None; Inv = Inv.Inventory)
				if (RPGStatsInv(Inv) != none)
				{
					RPGStatsInv(Inv).DataObject.ServerTime = ServerTime;
					if ( (!bFakeBotLevels || c.IsA('PlayerController') ) && !cancheat && !rpgrulz.IsInState('GameEnded') )
					    RPGStatsInv(Inv).DataObject.SaveConfig();
					RPGStatsInv(Inv).DataObject = None;
					Inv.Disable('Tick');
				}
	CurrentLowestLevelPlayer = None;
	SetTimer(0, false);
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	local actor a;
	local FakeMonsterWeapon w;
	local Controller C;
	local RPGStatsInv StatsInv;
	local flaginv fi;
    local saveinv s;
    local RespawnTrigger r;


	if (Other == None)
		return true;

	if(rpgartifact(other)!=none)
	    rpgartifact(other).RPGMut=self;
	else if(rpgartifactpickup(other)!=none)
        rpgartifactpickup(other).ArtifactManager=artifactmanager;
	else if(gameobject(other)!=none )
	{
	    fi=spawn(class'flaginv',other,,other.location,other.rotation);
	    if( fi!=none)
	    {
	        other.Inventory=fi;
	        fi.flag=gameobject(other);
	        fi.rpgrulz=rpgrulz;
	        fi.RPGMut=self;
	        fi.SetBase(other);
	        if(gameobject_energycore(other)!=none)
	            fi.GotoState('gameobjectcheck');
        }
	}
	else if(Trigger_ASForceTeamRespawn(other) != none)
	{
	    r = spawn(class'RespawnTrigger',,other.tag,other.location,other.rotation);
	    r.dunk = Trigger_ASForceTeamRespawn(other);
	    other.tag = 'none';
	}
	else if (AdrenalinePickup(Other) != None && bExperiencePickups)
		return false;
	else if (Pawn(Other) != None)
	{
	    //Give monsters a fake weapon
	    if (Other.IsA('Monster') && !level.Game.bGameEnded)
	    {
		    Pawn(Other).HealthMax = Pawn(Other).Health;
		    w = spawn(class'FakeMonsterWeapon',Other,,,rot(0,0,0));
		    w.GiveTo(Pawn(Other) );
	    }
        else if(xpawn(other)!=none)
        {
            if( deathmatch(level.Game).SpawnProtectionTime == -1.0)
                deathmatch(level.Game).SpawnProtectionTime=spawnprotectiontime;
            else
            {
                spawnprotectiontime = deathmatch(level.Game).SpawnProtectionTime;
                rpgrulz.spawnprotectiontime = deathmatch(level.Game).SpawnProtectionTime;
            }
        }
        else if(vehicle(other)!=none)
        {
            if(level.Game.bGameEnded)
                vehicle(other).bTeamLocked=false;
            if( asvehicle(other)!=none )
            {
                if( asvehicle(other).DefaultWeaponClassName~="UT2k4AssaultFull.Weapon_LinkTurret" )
	                asvehicle(other).DefaultWeaponClassName="mcgRPG1_9_9_1.RPGWeapon_LinkTurret";
                 else if(asvehicle(other).DefaultWeaponClassName ~= "UT2k4AssaultFull.Weapon_Turret" )
                     asvehicle(other).DefaultWeaponClassName = "mcgRPG1_9_9_1.RPGTurretWeapon";
                 else if(asvehicle(other).DefaultWeaponClassName ~= "UT2k4Assault.Weapon_Sentinel" )
                     asvehicle(other).DefaultWeaponClassName = "mcgRPG1_9_9_1.RPGSentinelWeapon";
            }
	    }
		// evil hack for bad Assault code
		// when Assault does its respawn and teleport stuff (e.g. when finished spacefighter part of AS-Mothership)
		// it spawns a new pawn and destroys the old without calling any of the proper functions
		C = Controller(Other.Owner);
		if (C != None && C.Pawn != None && vehicle(c.pawn) == none && vehicle(other) == none)
		{
			// NOTE - the use of FindInventoryType() here is intentional
			// we don't need to do anything if the old pawn doesn't have possession of an RPGStatsInv
			StatsInv = RPGStatsInv(C.Pawn.FindInventoryType(class'RPGStatsInv'));
			s = saveinv(C.Pawn.FindInventoryType(class'saveinv'));
			if(s != none)
			{
			    s.bdestroying = true;
			    s.Destroy();
			}
			if (StatsInv != None)
				StatsInv.OwnerDied();
		}
	}
	else if ( Controller(Other) != None  )
	{
		Controller(Other).bAdrenalineEnabled = true;
		if( !controller(other).bIsPlayer && controller(other).Instigator!=none )
		    controller(other).Instigator.SpawnTime=-2000000.0;
		if(level.game.bGameEnded)
		    controller(other).bGodMode = true;
        if(xPlayer(other) != none)
        {
            Players.Insert(Players.Length,1);
            Players[Players.Length - 1].p = playercontroller(other);
            Players[Players.Length - 1].n = pendingname;
        }
        if( (aicontroller(other) != none ) && ( level.NetMode != nm_standalone || (level.GetLocalPlayerController() != none &&
            ( !level.GetLocalPlayerController().IsA('x42player') || ( int(mid(string(level.GetLocalPlayerController().class),10,1 ) ) < 3 &&
            int(mid(string(level.GetLocalPlayerController().class),12,1 ) ) < 7) ) ) || (level.Game.PlayerControllerClass != none &&
            (level.Game.PlayerControllerClass.Name != 'x42player' || ( int(mid(string(level.Game.PlayerControllerClass),10,1 ) ) < 3 &&
            int(mid(string(level.Game.PlayerControllerClass),12,1 ) ) < 7) ) ) || !(right(level.Game.PlayerControllerClassName,9) ~= "x42player") ||
            ( int(mid(level.Game.PlayerControllerClassName,10,1 ) ) < 3 && int(mid(level.Game.PlayerControllerClassName,12,1 ) ) < 7) ) )
        {
            foreach other.ChildActors(class'actor',a)
                if(a.IsA('firesoundinv') ) //compatibility hack for other mutators using this inventory stuff
                    return true;
            other.Spawn(class'firesoundinv',other);
        }
	}
	return true;
}

function reset()
{
    local int i,y;
    local array<string> statpairstring;
    local array <statpair> statpairs;
    local rpgstatsinv inv;
    local pawn p;
    for(i = 0; i < stats.Length; i++)
    {
        stats[i].adr = 0.0;
        split(stats[i].otherstat,",",statpairstring);
        statpairs.length = statpairstring.Length;
        for(y = 0; y < statpairstring.Length; y++)
        {
            divide(statpairstring[y],"=", statpairs[y].property, statpairs[y].value);
            if(bReset[y] > 0)
                statpairs[y].value = "0";
        }
        stats[i].otherstat = "";
            for(y = 0; y < statpairs.Length; y++)
                stats[i].otherstat $= statpairs[y].property $ "=" $ statpairs[y].value;
    }
    foreach dynamicactors(class'pawn',p)
    {
        inv = rpgstatsinv(p.FindInventoryType(class'rpgstatsinv') );
        if(inv != none)
            inv.ownerdied(inv.ownerc);
    }
}

//Replace an actor and then return the new actor
function Actor ReplaceWithActor(actor Other, string aClassName)
{
	local Actor A;
	local class<Actor> aClass;

	if ( aClassName == "" )
		return None;

	aClass = class<Actor>(DynamicLoadObject(aClassName, class'Class'));
	if ( aClass != None )
		A = Spawn(aClass,Other.Owner,Other.tag,Other.Location, Other.Rotation);
	if ( Other.IsA('Pickup') )
	{
		if ( Pickup(Other).MyMarker != None )
		{
			Pickup(Other).MyMarker.markedItem = Pickup(A);
			if ( Pickup(A) != None )
			{
				Pickup(A).MyMarker = Pickup(Other).MyMarker;
				A.SetLocation(A.Location
					+ (A.CollisionHeight - Other.CollisionHeight) * vect(0,0,1));
			}
			Pickup(Other).MyMarker = None;
		}
		if ( A.IsA('Pickup') )
			Pickup(A).Respawntime = Pickup(Other).RespawnTime;
	}
	if ( A != None )
	{
		A.event = Other.event;
		A.tag = Other.tag;
		return A;
	}
	return None;
}

function ModifyLogin(out string Portal, out string Options)
{
    local string temp;
    PendingName = Left(level.Game.ParseOption( Options, "Name"), 20);
    if(PendingName == "" || PendingName ~= "Player")
        temp = Left(level.Game.ParseOption( Options, "Character"), 20);
    if(temp != "")
        PendingName = temp;
	if ( NextMutator != None )
		NextMutator.ModifyLogin(Portal, Options);
}

function ModifyPlayerController(PlayerController Other)
{
	local RPGPlayerDataObject data,temp;
	local int x, y;
	local RPGStatsInv StatsInv;
	local Inventory Inv;
    local string playername;
    local string id[5];
	local string hash;
    local array<string> statpairstring;
	local playerreplicationinfo newpri;
	local playercontroller pc;
    local array <statpair> statpairs;

	if (other==none || bGameRestarted || other.bPendingDelete || pendingname == "")
	{
	    PendingName = "";
		return;
	}


    for(x = 0; x < DataObjectList.Length; x++)
    {
        if(string(DataObjectList[x].Name) ~= pendingname)
        {
            data = DataObjectList[x];
            break;
        }
    }
    if (data == None)
    {
        data = new(None, pendingname) class'RPGPlayerDataObject';
        DataObjectList.Insert(DataObjectList.Length,1);
        DataObjectList[DataObjectList.Length - 1] = data;
    }

    if (data.Level < StartingLevel)
    {
        if ( data.Level==0 )    //new player
        {
            data.OwnerID = Other.GetPlayerIDHash();
            for(x = 0; x < arraycount(StatCaps);x ++)
                data.StatCaps[x] = StatCaps[x];
        }
        else if ( !(Other.GetPlayerIDHash() ~= data.OwnerID) )
        {
            //imposter using somebody else's name
            Other.ReceiveLocalizedMessage(class'RPGNameMessage', 0);
            if(right(PendingName,1)==")" && left( right(PendingName,4),1)=="(" && int(left( right(PendingName,3),2) ) > 9 )
            {
                if(nickindex==0)
                    nickindex=int(left( right(PendingName,3),2) );
                if(nickindex==99 && currentnickindex==0)
                    currentnickindex=10;
                else if(currentnickindex==0)
                    currentnickindex=nickindex+1;
                else if(currentnickindex<99)
                    currentnickindex++;
                else currentnickindex=10;
                playername=left( PendingName,len(PendingName)-4);
            }
            else
            {
                currentnickindex=10;
                playername = PendingName;
            }
            if(currentnickindex!=nickindex )
                ChangeName(Other, PlayerName$"("$currentnickindex$")");
            if (string(data.Name) ~= PendingName) //initial name change failed
            {
                id[0] = right(left(Other.GetPlayerIDHash(),4),1);
                id[1] = right(left(Other.GetPlayerIDHash(),7),1);
                id[2] = right(left(Other.GetPlayerIDHash(),13),1);
                id[3] = right(left(Other.GetPlayerIDHash(),15),1);
                id[4] = right(left(Other.GetPlayerIDHash(),24),1);
                y = 0;
                for(x = 0; x < arraycount(id); x++)
                {
                    if(asc(caps(id[x]) ) >= asc("A") && asc(caps(id[x])) <= asc("F"))
                        id[x] = string(10 + asc(caps(id[x]) ) - asc("A"));
                    y += int(id[x]) * 16**x;
                }
                if( ("Player"$string(y) ) ~= PendingName)
                    y = rand(999999);
				ChangeName(Other, "Player"$string(y) );
            }
            ModifyPlayerController(Other);
            return;
        }
        currentnickindex=0;
        nickindex=0;
        data.Experience=0;
        data.ExperienceFraction=0.0;
        data.Level = StartingLevel;
        data.PointsAvailable = PointsPerLevel * (StartingLevel - 1);
        if (Levels.length > Data.Level)
            data.NeededExp = Levels[Data.Level];
        else if (InfiniteReqEXPValue != 0)
            data.NeededExp = Levels[Levels.length - 1] + InfiniteReqEXPValue * (data.Level - (Levels.length - 1));
        else
            data.NeededExp = Levels[Levels.length - 1];
        ValidateData(data,other );

    }
    else //returning player
    {
        if (  !(Other.GetPlayerIDHash() ~= data.OwnerID) )
        {
            //imposter using somebody else's name
            Other.ReceiveLocalizedMessage(class'RPGNameMessage', 0);
            if(right(PendingName,1)==")" && left( right(PendingName,4),1)=="(" && int(left( right(PendingName,3),2) ) > 9 )
            {
                if(nickindex==0)
                    nickindex=int(left( right(PendingName,3),2) );
                if(nickindex==99 && currentnickindex==0)
                    currentnickindex=10;
                else if(currentnickindex==0)
                    currentnickindex=nickindex+1;
                else if(currentnickindex<99)
                    currentnickindex++;
                else currentnickindex=10;
                playername=left( PendingName,len(PendingName)-4);
            }
            else
            {
                currentnickindex=10;
                playername=PendingName;
            }
            if(currentnickindex!=nickindex )
                ChangeName(Other, PlayerName$"("$currentnickindex$")");
            if (string(data.Name) ~= PendingName) //initial name change failed
            {
                id[0] = right(left(Other.GetPlayerIDHash(),4),1);
                id[1] = right(left(Other.GetPlayerIDHash(),7),1);
                id[2] = right(left(Other.GetPlayerIDHash(),13),1);
                id[3] = right(left(Other.GetPlayerIDHash(),15),1);
                id[4] = right(left(Other.GetPlayerIDHash(),24),1);
                y = 0;
                for(x = 0; x < arraycount(id); x++)
                {
                    if(asc(caps(id[x]) ) >= asc("A") && asc(caps(id[x])) <= asc("F"))
                        id[x] = string(10 + asc(caps(id[x]) ) - asc("A"));
                    y += int(id[x]) * 16**x;
                }
                if( ("Player"$string(y) ) ~= PendingName)
                    y = rand(999999);
				ChangeName(Other, "Player"$string(y) );
            }
            ModifyPlayerController(Other);
            return;
        }
        currentnickindex=0;
        nickindex=0;
        ValidateData(data,other );
    }
	if(Other.playerreplicationinfo != none)
	{
	    newpri = Other.playerreplicationinfo;
	    pc = Other;
	    hash = pc.GetPlayerIDHash();
	    for(x = 0; x < stats.Length; x++)
	    {
	        if(stats[x].id ~= hash)
	        {
	            if(pendingname != "" && stats[x].pri != none && stats[x].pri.playername ~= pendingname)
	            {
                    newpri.Score = stats[x].pri.Score;
                    newpri.Deaths = stats[x].pri.Deaths;
                    newpri.NumLives = stats[x].pri.NumLives;
                    newpri.bOutOfLives = stats[x].pri.bOutOfLives;
                    newpri.GoalsScored = stats[x].pri.GoalsScored;
                    newpri.Kills = stats[x].pri.Kills;
                    if(teamplayerreplicationinfo(newpri) != none && teamplayerreplicationinfo(stats[x].pri) != none)
                    {
                        teamplayerreplicationinfo(newpri).bFirstBlood = teamplayerreplicationinfo(stats[x].pri).bFirstBlood;
                        teamplayerreplicationinfo(newpri).WeaponStatsArray = teamplayerreplicationinfo(stats[x].pri).WeaponStatsArray;
                        teamplayerreplicationinfo(newpri).VehicleStatsArray = teamplayerreplicationinfo(stats[x].pri).VehicleStatsArray;
                        teamplayerreplicationinfo(newpri).FlagTouches = teamplayerreplicationinfo(stats[x].pri).FlagTouches;
                        teamplayerreplicationinfo(newpri).FlagReturns = teamplayerreplicationinfo(stats[x].pri).FlagReturns;
                        for(y = 0; y < arraycount(teamplayerreplicationinfo(newpri).Spree); y++)
                            teamplayerreplicationinfo(newpri).Spree[y] = teamplayerreplicationinfo(stats[x].pri).Spree[y];
                        for(y = 0; y < arraycount(teamplayerreplicationinfo(newpri).MultiKills); y++)
                            teamplayerreplicationinfo(newpri).MultiKills[y] = teamplayerreplicationinfo(stats[x].pri).MultiKills[y];
                        teamplayerreplicationinfo(newpri).Suicides = teamplayerreplicationinfo(stats[x].pri).Suicides;
                        teamplayerreplicationinfo(newpri).flakcount = teamplayerreplicationinfo(stats[x].pri).flakcount;
                        teamplayerreplicationinfo(newpri).combocount = teamplayerreplicationinfo(stats[x].pri).combocount;
                        teamplayerreplicationinfo(newpri).headcount = teamplayerreplicationinfo(stats[x].pri).headcount;
                        teamplayerreplicationinfo(newpri).ranovercount = teamplayerreplicationinfo(stats[x].pri).ranovercount;
                        teamplayerreplicationinfo(newpri).DaredevilPoints = teamplayerreplicationinfo(stats[x].pri).DaredevilPoints;
                        for(y = 0; y < arraycount(teamplayerreplicationinfo(newpri).Combos); y++)
                            teamplayerreplicationinfo(newpri).Combos[y] = teamplayerreplicationinfo(stats[x].pri).Combos[y];
                    }
                    pc.Adrenaline = stats[x].adr;
                    split(stats[x].otherstat,",",statpairstring);
                    statpairs.length = statpairstring.Length;
                    for(y = 0; y < statpairstring.Length; y++)
                        divide(statpairstring[y],"=", statpairs[y].property, statpairs[y].value);
                    for(y = 0; y < statpairs.length; y++)
                        pc.SetPropertyText(statpairs[y].property, statpairs[y].value);
                    for(y = 0; y < statpairs.length; y++)
                        newpri.SetPropertyText(statpairs[y].property, statpairs[y].value);
	            }
	            if(stats[x].pri != none)
	                stats[x].pri.destroy();
                stats.Remove(x,1);
	            break;
	        }
	    }
	}
    temp = data;
    data = TempRPGPlayerDataObject(FindObject("Package." $ PendingName,class'TempRPGPlayerDataObject') );
    if (data == None)
        data = new(None, PendingName) class'TempRPGPlayerDataObject';
    data.CopyDataFrom(temp);

	if ( (CurrentLowestLevelPlayer == None || data.Level < CurrentLowestLevelPlayer.Level) )
		CurrentLowestLevelPlayer = data;

	//spawn the stats inventory item
	StatsInv = spawn(class'RPGStatsInv',Other,,,rot(0,0,0));
    statsinv.savedexperience=Data.Experience;
    statsinv.savedlevel=Data.Level;
    statsinv.savedpoints=Data.PointsAvailable;
    statsinves[statsinves.Length]=statsinv;
    statsinv.CurrentName = string(data.name);
	if (Other.Inventory == None)
	    Other.Inventory = StatsInv;
	else
	{
	    for (Inv = Other.Inventory; Inv.Inventory != None; Inv = Inv.Inventory)
	    {
        }
	    Inv.Inventory = StatsInv;
	}
	statsinv.OwnerC=other;
	for(x=0; x < turretstructs.Length;x++)
	{
        if(turretstructs[x].id ~= data.OwnerID)
        {
            statsinv.turrets = turretstructs[x].turrets;
            turretstructs.Remove(x,1);
            break;
        }
	}
	if ( Data.Level > 1 && Data.PointsAvailable != PointsPerLevel * (Data.Level - 1) )
	{
        for(x = 0; x < arraycount(StatCaps); x++)
        {
            if(StatCaps[x] != data.StatCaps[x] )
            {
                statsinv.bCanRebuild = true;
                break;
            }
        }
	}
	StatsInv.DataObject = data;
	statsinv.PendingName = PendingName;
	data.CreateDataStruct(StatsInv.Data, false);
	StatsInv.RPGMut = self;
	Other.AdrenalineMax = data.AdrenalineMax + Other.default.AdrenalineMax;
    for(x = 0; x < statsinv.DataObject.Abilities.Length; x++)
        statsinv.DataObject.Abilities[x].static.PlayerEntered(other, pendingname, statsinv.DataObject.AbilityLevels[x] );
    PendingName = "";
}

function ChangeName( playercontroller other, string S)
{
    local Controller APlayer;

    if ( S == "" )
        return;

	S = level.Game.StripColor(s);

    if (PendingName ~= S)
        return;

	S = Left(S,20);
    ReplaceText(S, " ", "_");
    ReplaceText(S, "|", "I");

    for( APlayer=Level.ControllerList; APlayer!=None; APlayer=APlayer.nextController )
        if ( APlayer != other && APlayer.bIsPlayer && (APlayer.PlayerReplicationInfo.playername ~= S) )
        {
            Other.ReceiveLocalizedMessage( level.Game.GameMessageClass, 8 );
            return;
        }

    PendingName = S;
}

function ModifyPlayer(Pawn Other)
{
	local RPGPlayerDataObject data,temp;
	local int x, y;
	local RPGStatsInv StatsInv;
	local Inventory Inv;
	local array<Weapon> StartingWeapons;
	local class<Weapon> StartingWeaponClass;
	local RPGWeapon MagicWeapon;
    local saveinv s;
    local float FakeBotLevelDiff;
    local string playername;
    local bool sent,find;
    local weapon w;
    local string id[5];
    local oldweaponholder o;

    Super.ModifyPlayer(Other);
    deathmatch(level.Game).SpawnProtectionTime = -1.0;
	if (other==none || (Other.Controller != None && !Other.Controller.bIsPlayer) || bGameRestarted ||
        ( Level.Game.ResetCountDown < 4 &&  Level.Game.ResetCountDown > 1 ) || vehicle(other)!=none || other.bPendingDelete ||
        other.Health <= 0)
		return;
    if(level.Game.bGameEnded && Other.Controller != None)
        other.Controller.bGodMode = true;
	StatsInv = RPGStatsInv(Other.FindInventoryType(class'RPGStatsInv'));
	if (StatsInv != None)
	{
        s=saveinv(other.FindInventoryType(class'saveinv') );
        if(s==none)
        {
            s=other.Spawn(class'saveinv',other);
            s.GiveTo(other);
        }
		if (StatsInv.Instigator != None)
			for (x = 0; x < StatsInv.Dataobject.Abilities.length; x++)
				StatsInv.Dataobject.Abilities[x].static.ModifyPawn(other, StatsInv.Dataobject.AbilityLevels[x], StatsInv);
		if( playercontroller(other.controller)!=none )
		{
            if(level.Game.bGameEnded )
		    {
                class'druidloaded'.static.ModifyPawn(other,max(class'druidloaded'.default.maxlevel,6), StatsInv );
                class'druidartifactloaded'.static.ModifyPawn(other, max(3,class'druidartifactloaded'.default.maxlevel ), StatsInv );
            }
        }
		return;
	}
	else if(Other.Controller == None)
	    return;
	else
	{
		for (Inv = Other.Controller.Inventory; Inv != None; Inv = Inv.Inventory)
		{
			StatsInv = RPGStatsInv(Inv);
			if (StatsInv != None)
				break;
			//I fail to understand why I need this check... am I missing something obvious or is this some weird script bug?
			if (Inv.Inventory == None)
			{
				Inv.Inventory = None;
				break;
			}
		}
	}

	if (StatsInv != None && (PlayerController(Other.Controller) == None ||
        string(StatsInv.DataObject.Name) ~= Other.PlayerReplicationInfo.PlayerName) )
		data = StatsInv.DataObject;
	else
	{
        if(statsinv!=none)
        {
            sent=true;
            statsinv.Disable('tick');
            if (statsinv.DataObject == CurrentLowestLevelPlayer)
                find=true;
   	        if(!cancheat && !level.Game.bGameEnded)
   	        {
	            statsinv.DataObject.ServerTime = ServerTime;
	            for(x = 0; x < DataObjectList.Length; x++)
	            {
	                if(string(DataObjectList[x].Name) ~= string(statsinv.DataObject.Name) )
	                {
	                    temp = DataObjectList[x];
	                    break;
                    }
	            }
	            if(temp != none)
	            {
                    temp.CopyDataFrom(statsinv.DataObject);
                    temp.SaveConfig();
	                statsinv.DataObject.ClearConfig();
	                temp = none;
	            }
	            else
	            {
	                log("Can't find permanent data for "$statsinv.DataObject.Name$", data saved temporary, and system tries to load it at the next map");
                    statsinv.DataObject.SaveConfig();
                }
            }
	        statsinv.DataObject = none;
            statsinv.callDestroy();
            statsinv.Destroy();
            if(find)
                FindCurrentLowestLevelPlayer();
            other.Controller.Adrenaline=0;
            other.Controller.AwardAdrenaline(-1*(other.Controller.AdrenalineMax) ); //x42player altadrenaline hack
            foreach other.Controller.ChildActors(class'oldweaponholder',o)
                o.destroy();
        }
        for(x = 0; x < DataObjectList.Length; x++)
        {
            if(string(DataObjectList[x].Name) ~= Other.PlayerReplicationInfo.PlayerName)
            {
                data = DataObjectList[x];
                break;
            }
        }
        if (data == None)
        {
            data = new(None, Other.PlayerReplicationInfo.PlayerName) class'RPGPlayerDataObject';
            DataObjectList.Insert(DataObjectList.Length,1);
            DataObjectList[DataObjectList.Length - 1] = data;
        }
        if (bFakeBotLevels && PlayerController(Other.Controller) == None) //a bot, and fake bot levels is turned on
        {
			// if the bot has data, delete it
			if (data.Level != 0)
			{
				data.ClearConfig();
				data = new(None, Other.PlayerReplicationInfo.PlayerName) class'RPGPlayerDataObject';
			}

			// give the bot a level near the current lowest level
			if (CurrentLowestLevelPlayer != None)
			{
				FakeBotLevelDiff = 3 + Min(25, CurrentLowestLevelPlayer.Level * 0.1);
				data.Level = Max(StartingLevel, CurrentLowestLevelPlayer.Level - FakeBotLevelDiff + Rand(FakeBotLevelDiff * 2));
			}
			else
				data.Level = StartingLevel;

			data.PointsAvailable = PointsPerLevel * data.Level;
			if (Levels.length > data.Level)
				data.NeededExp = Levels[data.Level];
			else if (InfiniteReqEXPValue != 0)
					data.NeededExp = Levels[Levels.length - 1] + InfiniteReqEXPValue * (data.Level - (Levels.length - 1));
			else
				data.NeededExp = Levels[Levels.length - 1];

			// give some random amount of EXP toward next level so some will gain a level or two during the match
			data.Experience = Rand(data.NeededExp);

			data.OwnerID = "Bot";
		}
		else if (data.Level < StartingLevel)
		{
            if ( data.Level==0 )    //new player
            {
                if(PlayerController(Other.Controller) != None)
                {
				    data.OwnerID = PlayerController(Other.Controller).GetPlayerIDHash();
				    for(x = 0; x < arraycount(StatCaps);x ++)
				        data.StatCaps[x] = StatCaps[x];
                }
                else
                    data.OwnerID = "Bot";
            }
            else if ( (PlayerController(Other.Controller) != None &&
                !(PlayerController(Other.Controller).GetPlayerIDHash() ~= data.OwnerID) ) ||
                (PlayerController(Other.Controller) == None && data.OwnerID != "Bot") )
			{
				//imposter using somebody else's name
				if (PlayerController(Other.Controller) != None)
					PlayerController(Other.Controller).ReceiveLocalizedMessage(class'RPGNameMessage', 0);
				if(right(Other.PlayerReplicationInfo.PlayerName,1)==")" &&
                    left( right(Other.PlayerReplicationInfo.PlayerName,4),1)=="(" &&
                    int(left( right(Other.PlayerReplicationInfo.PlayerName,3),2) ) > 9 )
                {
                    if(nickindex==0)
                        nickindex=int(left( right(Other.PlayerReplicationInfo.PlayerName,3),2) );
                    if(nickindex==99 && currentnickindex==0)
                        currentnickindex=10;
                    else if(currentnickindex==0)
                        currentnickindex=nickindex+1;
                    else if(currentnickindex<99)
                        currentnickindex++;
                    else currentnickindex=10;
                    playername=left( Other.PlayerReplicationInfo.PlayerName,len(Other.PlayerReplicationInfo.PlayerName)-4);
                }
                else
                {
                    currentnickindex=10;
                    playername=Other.PlayerReplicationInfo.PlayerName;
                }
                if(currentnickindex!=nickindex )
				    Level.Game.ChangeName(Other.Controller, PlayerName$"("$currentnickindex$")", true);
				if (string(data.Name) ~= Other.PlayerReplicationInfo.PlayerName) //initial name change failed
				{
				    if (PlayerController(Other.Controller) != None)
				    {
				        id[0] = right(left(PlayerController(Other.Controller).GetPlayerIDHash(),4),1);
				        id[1] = right(left(PlayerController(Other.Controller).GetPlayerIDHash(),7),1);
				        id[2] = right(left(PlayerController(Other.Controller).GetPlayerIDHash(),13),1);
				        id[3] = right(left(PlayerController(Other.Controller).GetPlayerIDHash(),15),1);
				        id[4] = right(left(PlayerController(Other.Controller).GetPlayerIDHash(),24),1);
				        y = 0;
				        for(x = 0; x < arraycount(id); x++)
				        {
				            if(asc(caps(id[x]) ) >= asc("A") && asc(caps(id[x])) <= asc("F"))
				                id[x] = string(10 + asc(caps(id[x]) ) - asc("A"));
                            y += int(id[x]) * 16**x;
				        }
				        if( ("Player"$string(y) ) ~= Other.PlayerReplicationInfo.PlayerName)
				            y = rand(999999);
				    }
				    else
				        y = rand(999999);
					Level.Game.ChangeName(Other.Controller, "Player"$string(y), true);
				}
				ModifyPlayer(Other);
				return;
			}
			currentnickindex=0;
			nickindex=0;

		    data.Experience=0;
		    data.ExperienceFraction=0.0;
			data.Level = StartingLevel;
			data.PointsAvailable = PointsPerLevel * (StartingLevel - 1);
			if (Levels.length > StartingLevel)
				data.NeededExp = Levels[StartingLevel];
			else if (InfiniteReqEXPValue != 0)
			    data.NeededExp = Levels[Levels.length - 1] + InfiniteReqEXPValue * (data.Level - (Levels.length - 1));
			else
				data.NeededExp = Levels[Levels.length - 1];
            ValidateData(data,other.Controller);

		}
		else //returning player
		{
			if( (PlayerController(Other.Controller) != None && !(PlayerController(Other.Controller).GetPlayerIDHash() ~= data.OwnerID)) ||
                (PlayerController(Other.Controller) == None && data.OwnerID != "Bot") )
			{
				//imposter using somebody else's name
				if (PlayerController(Other.Controller) != None)
					PlayerController(Other.Controller).ReceiveLocalizedMessage(class'RPGNameMessage', 0);
				if(right(Other.PlayerReplicationInfo.PlayerName,1)==")" &&
                    left( right(Other.PlayerReplicationInfo.PlayerName,4),1)=="(" &&
                    int(left( right(Other.PlayerReplicationInfo.PlayerName,3),2) ) > 9 )
                {
                    if(nickindex==0)
                        nickindex=int(left( right(Other.PlayerReplicationInfo.PlayerName,3),2) );
                    if(nickindex==99 && currentnickindex==0)
                        currentnickindex=10;
                    else if(currentnickindex==0)
                        currentnickindex=nickindex+1;
                    else if(currentnickindex<99)
                        currentnickindex++;
                    else currentnickindex=10;
                    playername=left( Other.PlayerReplicationInfo.PlayerName,len(Other.PlayerReplicationInfo.PlayerName)-4);
                }
                else
                {
                    currentnickindex=10;
                    playername=Other.PlayerReplicationInfo.PlayerName;
                }
                if(currentnickindex!=nickindex )
                    Level.Game.ChangeName(Other.Controller, PlayerName$"("$currentnickindex$")", true);
				if (string(data.Name) ~= Other.PlayerReplicationInfo.PlayerName) //initial name change failed
				{
				    if (PlayerController(Other.Controller) != None)
				    {
				        id[0] = right(left(PlayerController(Other.Controller).GetPlayerIDHash(),4),1);
				        id[1] = right(left(PlayerController(Other.Controller).GetPlayerIDHash(),7),1);
				        id[2] = right(left(PlayerController(Other.Controller).GetPlayerIDHash(),13),1);
				        id[3] = right(left(PlayerController(Other.Controller).GetPlayerIDHash(),15),1);
				        id[4] = right(left(PlayerController(Other.Controller).GetPlayerIDHash(),24),1);
				        y = 0;
				        for(x = 0; x < arraycount(id); x++)
				        {
				            if(asc(caps(id[x]) ) >= asc("A") && asc(caps(id[x])) <= asc("F"))
				                id[x] = string(10 + asc(caps(id[x]) ) - asc("A"));
                            y += int(id[x]) * 16**x;
				        }
				        if( ("Player"$string(y) ) ~= Other.PlayerReplicationInfo.PlayerName)
				            y = rand(999999);
				    }
				    else
				        y = rand(999999);
					Level.Game.ChangeName(Other.Controller, "Player"@string(y), true);
				}
				ModifyPlayer(Other);
				return;
			}
			currentnickindex=0;
			nickindex=0;
            ValidateData(data,other.Controller);
		}
		if(PlayerController(Other.Controller) != None)
		{
		    temp = data;
		    data = none;
		    data = TempRPGPlayerDataObject(FindObject("Package." $ Other.PlayerReplicationInfo.PlayerName,
                class'TempRPGPlayerDataObject') );
            if (data == None)
                data = new(None, Other.PlayerReplicationInfo.PlayerName) class'TempRPGPlayerDataObject';
            data.CopyDataFrom(temp);
		}
	}
    if (data.PointsAvailable > 0 && Bot(Other.Controller) != None)
	{
		x = 0;
		do
		{
			BotLevelUp(Bot(Other.Controller), data);
			x++;
		} until (data.PointsAvailable <= 0 || data.BotAbilityGoal != None || BreakLoop > 2000000 || x > 10000)
	}

	if ( (CurrentLowestLevelPlayer == None || data.Level < CurrentLowestLevelPlayer.Level) && (!bFakeBotLevels ||
        Other.Controller.IsA('PlayerController') ) )
		CurrentLowestLevelPlayer = data;

	//spawn the stats inventory item
	if (StatsInv == None)
	{
		StatsInv = spawn(class'RPGStatsInv',Other,,,rot(0,0,0));
		if(sent)
		    statsinv.bdefaultsdone=true;
		if( playercontroller(other.Controller)!=none)
		{
            statsinv.savedexperience=Data.Experience;
            statsinv.savedlevel=Data.Level;
            statsinv.savedpoints=Data.PointsAvailable;
            statsinv.CurrentName = string(data.name);
		    statsinves[statsinves.Length]=statsinv;
        }
		if (Other.Controller.Inventory == None)
			Other.Controller.Inventory = StatsInv;
		else
		{
			for (Inv = Other.Controller.Inventory; Inv.Inventory != None; Inv = Inv.Inventory)
			{
            }
			Inv.Inventory = StatsInv;
		}
		statsinv.OwnerC=other.Controller;
	    if(level.NetMode != NM_DedicatedServer)
	        StatsInv.someonestring = rpgrulz.someonestring;
		for(x=0; x < turretstructs.Length;x++)
		{
		    if(turretstructs[x].id ~= data.OwnerID)
		    {
		        statsinv.turrets = turretstructs[x].turrets;
		        turretstructs.Remove(x,1);
		        break;
            }
		}
		if (Data.Level > 1 && Data.PointsAvailable != PointsPerLevel * (Data.Level - 1) )
		{
		    for(x = 0; x < arraycount(StatCaps); x++)
		    {
		        if(StatCaps[x] != data.StatCaps[x] )
		        {
		            statsinv.bCanRebuild = true;
		            break;
		        }
		    }
		}
	}
	else if(Data.WeaponSpeed != StatsInv.Data.WeaponSpeed)
        StatsInv.ClientSetWeaponSpeed( int(float(Data.WeaponSpeed - StatsInv.Data.WeaponSpeed) * 2.5) );
	StatsInv.DataObject = data;
	data.CreateDataStruct(StatsInv.Data, false);
	StatsInv.RPGRulz = rpgrulz;
	StatsInv.RPGMut = self;
	StatsInv.GiveTo(Other);

	if (WeaponModifierChance > 0)
	{
		x = 0;
		Inv = Other.Inventory;
		while ( Inv != None)
		{
			if ( RPGWeapon(Inv) != None && RPGWeapon(Inv).ModifiedWeapon != None )
			{
			    if(MagicWeapon == none)
			        MagicWeapon = RPGWeapon(Inv);
				other.DeleteInventory(RPGWeapon(Inv).ModifiedWeapon);
				RPGWeapon(Inv).ModifiedWeapon.SetOwner(other);
			}
			x++;
			if (x > 500)
				break;
			Inv = Inv.Inventory;
		}
		for (Inv = Other.Inventory; Inv != None; Inv = Inv.Inventory)
		{
			if (Weapon(Inv) != None && RPGWeapon(Inv) == None && !weapon(inv).bNoInstagibReplace)
				StartingWeapons[StartingWeapons.length] = Weapon(Inv);
			x++;
			if (x > 250)
				break;
		}

		for (x = 0; x < StartingWeapons.length; x++)
		{
			StartingWeaponClass = StartingWeapons[x].Class;
			StartingWeapons[x].Destroy();
			MagicWeapon = spawn(GetRandomWeaponModifier(StartingWeaponClass, Other), Other,,, rot(0,0,0));
			MagicWeapon.Generate(None);
			w = other.spawn(StartingWeaponClass,MagicWeapon,,,rot(0,0,0) );
			w.SetOwner(other);
			MagicWeapon.SetModifiedWeapon(w, true);
			MagicWeapon.GiveTo(Other);
		}
        Other.Controller.ClientSwitchToBestWeapon();
		if(other.Weapon == none )
		{
            if( magicweapon != none)
		        other.Weapon = magicweapon;
            else
                other.weapon = weapon(other.FindInventoryType(class'weapon') );
        }
	}

	//set pawn's properties
	Other.Health = Other.default.Health + data.HealthBonus;
	Other.HealthMax = Other.default.HealthMax + data.HealthBonus;
	Other.SuperHealthMax = Other.HealthMax + (Other.default.SuperHealthMax - Other.default.HealthMax);
	Other.Controller.AdrenalineMax = data.AdrenalineMax + Other.Controller.default.AdrenalineMax;
    s=saveinv(other.FindInventoryType(class'saveinv') );
    if(s==none)
    {
        s=other.Spawn(class'saveinv',other);
        s.GiveTo(other);
    }
   	for (x = 0; x < data.Abilities.length; x++)
		data.Abilities[x].static.ModifyPawn(Other, data.AbilityLevels[x], StatsInv);
	if( playercontroller(other.controller)!=none )
	{
        if(level.Game.bGameEnded )
	    {
            class'druidloaded'.static.ModifyPawn(other,max(class'druidloaded'.default.maxlevel,6), StatsInv );
            class'druidartifactloaded'.static.ModifyPawn(other, max(3,class'druidartifactloaded'.default.maxlevel ), StatsInv );
        }
    }
}

function DriverEnteredVehicle(Vehicle V, Pawn P)
{
	local Inventory Inv;
	local RPGStatsInv StatsInv;
    local int i;
	local array<RPGArtifact> Artifacts;
	local saveinv s;
	local byte t;

    if(p == none || v == none)
        return;
    v.LastHitBy = none;
	if (V.Controller != None)
	{
		for (Inv = V.Controller.Inventory; Inv != None; Inv = Inv.Inventory)
		{
			StatsInv = RPGStatsInv(Inv);
			if (StatsInv != None)
				break;
		}
	}

	if (StatsInv == None)
		StatsInv = RPGStatsInv(P.FindInventoryType(class'RPGStatsInv'));
	if(tmarker!=none)
	{
	    tmarker.GiveTo(v);
	    if(tmarker.instigatorcontroller != none && tmarker.instigatorcontroller == v.Controller)
	        t = 8 + 4 * byte(tmarker.bunlocked);
	    tmarker=none;
	}
    t += 2 * byte(v.bCanPickupInventory);
    t ++;
	if (StatsInv != None)
	{
		StatsInv.ModifyVehicle(V, v.ParentFactory,true);
		StatsInv.ClientModifyVehicle(V, v.ParentFactory,t);
	}

	//move all artifacts from driver to vehicle, so player can still use them
	for (Inv = P.Inventory; Inv != None; Inv = Inv.Inventory)
		if (RPGArtifact(Inv) != None)
			Artifacts[Artifacts.length] = RPGArtifact(Inv);


	for (i = 0; i < Artifacts.length; i++)
	{
		if (Artifacts[i].bActive)
		{
			//turn it off first
			Artifacts[i].ActivatedTime = -1000000; //force it to allow deactivation
			Artifacts[i].Activate();
		}
		if (Artifacts[i] == P.SelectedItem)
			V.SelectedItem = Artifacts[i];
		P.DeleteInventory(Artifacts[i]);
		Artifacts[i].GiveTo(V);
	}
    v.DeactivateSpawnProtection();
    if(xpawn(p)!=none)
    {
        xpawn(p).bSpawnDone=false;
        if( deathmatch(level.Game).SpawnProtectionTime == -1.0)
            deathmatch(level.Game).SpawnProtectionTime=spawnprotectiontime;
        else
        {
            spawnprotectiontime = deathmatch(level.Game).SpawnProtectionTime;
            rpgrulz.spawnprotectiontime = deathmatch(level.Game).SpawnProtectionTime;
        }
        p.DeactivateSpawnProtection();
        deathmatch(level.Game).SpawnProtectionTime=-1.0;
        xpawn(p).bSpawnDone=false;       //lol
    }

    s=saveinv(v.FindInventoryType(class'saveinv') );
    if(s==none)
        s=v.Spawn(class'saveinv',v);
    else
        v.DeleteInventory(s);
    s.GiveTo(v);
	Super.DriverEnteredVehicle(V, P);

}

function DriverLeftVehicle(Vehicle V, Pawn P)
{
	local Inventory Inv;
	local RPGStatsInv StatsInv;
	local array<RPGArtifact> Artifacts;
	local int i;
    local saveinv s;
    local controller newcontroller;

    if(p == none || v == none)
        return;

    v.LastHitBy = none;

	if (P.Controller != None)
	{
		for (Inv = P.Controller.Inventory; Inv != None; Inv = Inv.Inventory)
		{
			StatsInv = RPGStatsInv(Inv);
			if (StatsInv != None)
				break;
		}
	}
	if (StatsInv == None)
		StatsInv = RPGStatsInv(P.FindInventoryType(class'RPGStatsInv') );

    if(v != none && v.bAutoTurret && v.AutoTurretControllerClass != none && v.Controller == none && !v.bPendingDelete && v.Health > 0 )
	{
	    v.Controller = None;
	    NewController = v.spawn(v.AutoTurretControllerClass);
	    if ( NewController != None )
	        NewController.Possess( v );
	}
	if (StatsInv != None)
	{
		// yet another Assault hack (spacefighters)
		if (StatsInv.Instigator == V)
			V.DeleteInventory(StatsInv);

		StatsInv.UnModifyVehicle(V, v.ParentFactory,true);
		StatsInv.ClientUnModifyVehicle(V, v.ParentFactory,true);
	}

	//move all artifacts from vehicle to driver
	for (Inv = V.Inventory; Inv != None; Inv = Inv.Inventory)
		if (RPGArtifact(Inv) != None)
			Artifacts[Artifacts.length] = RPGArtifact(Inv);

	for (i = 0; i < Artifacts.length; i++)
	{
		if (Artifacts[i].bActive)
		{
			//turn it off first
			Artifacts[i].ActivatedTime = -1000000; //force it to allow deactivation
			Artifacts[i].Activate();
		}
		if (Artifacts[i] == V.SelectedItem)
			P.SelectedItem = Artifacts[i];
		V.DeleteInventory(Artifacts[i]);
		Artifacts[i].GiveTo(P);
	}
	if(tmarker!=none)
	{
	    tmarker.GiveTo(v);
	    tmarker=none;
	}

    v.DeactivateSpawnProtection();
    if(xpawn(p)!=none)
    {
        xpawn(p).bSpawnDone=false;
    }
    s=saveinv(v.FindInventoryType(class'saveinv') );
    if(s!=none)
    {
        s.ownerc = none;
        s.Instigator = none;
    }
	Super.DriverLeftVehicle(V, P);
}


//Check the player data at the given index for errors (too many/not enough stat points, invalid abilities)
//Converts the data by giving or taking the appropriate number of stat points and refunding points for abilities bought that are no longer allowed
//This allows the server owner to change points per level settings and/or the abilities allowed and have it affect already created players properly
function ValidateData(RPGPlayerDataObject Data, controller p,optional int killloop)
{
	local int TotalPoints, x, y;
	local bool bAllowedAbility;

    if(killloop>20)
        return;
	//check stat caps
	if (StatCaps[0] >= 0)
		Data.WeaponSpeed = Min(Data.WeaponSpeed, StatCaps[0]);
	if (StatCaps[1] >= 0)
		Data.HealthBonus = Min(Data.HealthBonus, StatCaps[1]);
	if (StatCaps[2] >= 0)
		Data.AdrenalineMax = Min(Data.AdrenalineMax, StatCaps[2]);
	if (StatCaps[3] >= 0)
		Data.Attack = Min(Data.Attack, StatCaps[3]);
	if (StatCaps[4] >= 0)
		Data.Defense = Min(Data.Defense, StatCaps[4]);
	if (StatCaps[5] >= 0)
		Data.AmmoMax = Min(Data.AmmoMax, StatCaps[5]);

	TotalPoints += int(float(Data.WeaponSpeed) * 2.5) + Data.Attack * 2 + Data.Defense * 2 + Data.AmmoMax;
	TotalPoints += int(float(Data.HealthBonus) / 1.5);
	TotalPoints += Data.AdrenalineMax;
	if(data.abilitynames.Length>Data.Abilities.length)
	    data.abilitynames.Remove(Data.Abilities.length,data.abilitynames.Length-Data.Abilities.length);
    else if(data.abilitynames.Length<Data.Abilities.length)
	    data.abilitynames.Insert(Data.abilitynames.length,data.Abilities.Length-Data.abilitynames.length);
	for (x = 0; x < Data.Abilities.length; x++)
	{
		for (y = 0; y < Abilities.length; y++)
			if( data.abilitynames[x] ~= getitemname( string(Abilities[y]) ) )
			{
			    if(Data.Abilities[x] != Abilities[y])
			        Data.Abilities[x] = Abilities[y];
				y = Abilities.length;		//kill loop without break due to UnrealScript bug that causes break to kill both loops
			}
	}

	for (x = 0; x < Data.Abilities.length; x++)
	{
		bAllowedAbility = false;
		for (y = 0; y < Abilities.length; y++)
			if( Data.Abilities[x] == Abilities[y] )
			{
			    if( Abilities[y].static.Cost(Data, Data.AbilityLevels[x]-1) > 0 )
				    bAllowedAbility = true;
				y = Abilities.length;		//kill loop without break due to UnrealScript bug that causes break to kill both loops
			}
		if (bAllowedAbility)
		{
			for (y = 0; y < Data.AbilityLevels[x]; y++)
				TotalPoints += Data.Abilities[x].static.Cost(Data, y);
			data.abilitynames[x] = getitemname(string(Data.Abilities[x]) );
		}
		else if(Data.Abilities[x] != none)
		{
			for (y = 0; y < Data.AbilityLevels[x]; y++)
				Data.PointsAvailable += Data.Abilities[x].static.Cost(Data, y);
			Log("Ability"@Data.Abilities[x]@"was in"@Data.Name$"'s data but is not an available ability - removed (stat points refunded)");
			Data.Abilities.Remove(x, 1);
			Data.AbilityLevels.Remove(x, 1);
			data.abilitynames.Remove(x, 1);
			x--;
		}
		else
		{
			Data.Abilities.Remove(x, 1);
			Data.AbilityLevels.Remove(x, 1);
			data.abilitynames.Remove(x, 1);
			x--;
		}
	}
    if(Levels.length > Data.Level)
        data.NeededExp = Levels[Data.Level];
    else if (InfiniteReqEXPValue != 0)
        data.NeededExp = Levels[Levels.length - 1] + InfiniteReqEXPValue * (data.Level - (Levels.length - 1));
    else
        data.NeededExp = Levels[Levels.length - 1];
    if(data.Experience >= data.NeededExp)
        CheckLevelUp(data,none);
	TotalPoints += Data.PointsAvailable;

	if ( TotalPoints != ((Data.Level - 1) * PointsPerLevel) )
	{
		Data.PointsAvailable += ((Data.Level - 1) * PointsPerLevel) - TotalPoints;
		y=data.WeaponSpeed*2.5+data.Attack*2+data.defense*2+data.HealthBonus/1.5+data.AmmoMax+data.AdrenalineMax;
        data.WeaponSpeed=0;
        data.Defense=0;
        data.Attack=0;
        data.HealthBonus=0;
        data.AdrenalineMax=0;
        data.AmmoMax=0;
        data.PointsAvailable+=y;
        if( playercontroller(p)!=none )
            playercontroller(p).ClientMessage("Stat system changed. You need to redistribute your stat points.");
		validatedata(data,p,killloop+1);
		Log(Data.Name$" had "$TotalPoints$" total stat points at Level "$Data.Level$", should be "$((Data.Level - 1) * PointsPerLevel)$", PointsAvailable changed by "$(((Data.Level - 1) * PointsPerLevel) - TotalPoints)$" to compensate");
	}
}

//Do a bot's levelup
function BotLevelUp(Bot B, RPGPlayerDataObject Data)
{
	local int WSpeedChance, HealthBonusChance, AdrenalineMaxChance, AttackChance, DefenseChance, AmmoMaxChance, AbilityChance;
	local int Chance, TotalAbilityChance;
	local int x, y, Index;
	local bool bHasAbility, bAddAbility;

	if (Data.BotAbilityGoal != None)
	{
		if (Data.BotAbilityGoal.static.Cost(Data, Data.BotGoalAbilityCurrentLevel) > Data.PointsAvailable)
			return;

		Index = -1;
		for (x = 0; x < Data.Abilities.length; x++)
			if (Data.Abilities[x] == Data.BotAbilityGoal)
			{
				Index = x;
				break;
			}
		if (Index == -1)
			Index = Data.Abilities.length;
		Data.PointsAvailable -= Data.BotAbilityGoal.static.Cost(Data, Data.BotGoalAbilityCurrentLevel);
		Data.Abilities[Index] = Data.BotAbilityGoal;
		Data.AbilityLevels[Index]++;
		Data.BotAbilityGoal = None;
		return;
	}

	//Bots always allocate all their points to one stat - random, but tilted towards the bot's tendencies

	WSpeedChance = 2;
	HealthBonusChance = 2;
	AdrenalineMaxChance = 1;
	AttackChance = 2;
	DefenseChance = 2;
	AmmoMaxChance = 1; //less because bots don't get ammo half the time as it is, so it's not as useful a stat for them
	AbilityChance = 3;

	if (B.Aggressiveness > 0.25)
	{
		WSpeedChance += 3;
		AttackChance += 3;
		AmmoMaxChance += 2;
	}
	if (B.Accuracy < 0)
	{
		WSpeedChance++;
		DefenseChance++;
		AmmoMaxChance += 2;
	}
	if (B.FavoriteWeapon != None && B.FavoriteWeapon.default.FireModeClass[0] != None && B.FavoriteWeapon.default.FireModeClass[0].default.FireRate > 1.25)
		WSpeedChance += 2;
	if (B.Tactics > 0.9)
	{
		HealthBonusChance += 3;
		AdrenalineMaxChance += 3;
		DefenseChance += 3;
	}
	else if (B.Tactics > 0.4)
	{
		HealthBonusChance += 2;
		AdrenalineMaxChance += 2;
		DefenseChance += 2;
	}
	else if (B.Tactics > 0)
	{
		HealthBonusChance++;
		AdrenalineMaxChance++;
		DefenseChance++;
	}
	if (B.StrafingAbility < 0)
	{
		HealthBonusChance++;
		AdrenalineMaxChance++;
		DefenseChance += 2;
	}
	if (B.CombatStyle < 0)
	{
		HealthBonusChance += 2;
		AdrenalineMaxChance += 2;
		DefenseChance += 2;
	}
	else if (B.CombatStyle > 0)
	{
		AttackChance += 2;
		AmmoMaxChance++;
	}
	if (Data.Level < 20)
		AbilityChance--;	//very few abilities to choose from at this low level so reduce chance
	else
	{
		//More likely to buy an ability if don't have that many
		y = 0;
		for (x = 0; x < Data.AbilityLevels.length; x++)
		{
		    BreakLoop++;
			y += Data.AbilityLevels[x];
		}
		if (y < (Data.Level - 20) / 10)
			AbilityChance++;
	}

	if (Data.AmmoMax >= 50)
		AmmoMaxChance = Max(AmmoMaxChance / 1.5, 1);
	if (Data.AdrenalineMax >= 75)
		AdrenalineMaxChance /= 1.5;  //too much adrenaline and you'll never get to use any combos!

	//disable choosing of stats that are maxxed out
	if (StatCaps[0] >= 0 && Data.WeaponSpeed >= StatCaps[0])
		WSpeedChance = 0;
	if (StatCaps[1] >= 0 && Data.HealthBonus >= StatCaps[1])
		HealthBonusChance = 0;
	if (StatCaps[2] >= 0 && Data.AdrenalineMax >= StatCaps[2])
		AdrenalineMaxChance = 0;
	if (StatCaps[3] >= 0 && Data.Attack >= StatCaps[3])
		AttackChance = 0;
	if (StatCaps[4] >= 0 && Data.Defense >= StatCaps[4])
		DefenseChance = 0;
	if (StatCaps[5] >= 0 && Data.AmmoMax >= StatCaps[5])
		AmmoMaxChance = 0;

	//choose a stat
	Chance = Rand(WSpeedChance + HealthBonusChance + AdrenalineMaxChance + AttackChance + DefenseChance + AmmoMaxChance + AbilityChance);
	bAddAbility = false;
	if (Chance < WSpeedChance)
		Data.WeaponSpeed += Min(Data.PointsAvailable, BotSpendAmount) / 2.5;
	else if (Chance < WSpeedChance + HealthBonusChance)
		Data.HealthBonus += Min(Data.PointsAvailable, BotSpendAmount) * 1.5;
	else if (Chance < WSpeedChance + HealthBonusChance + AdrenalineMaxChance)
		Data.AdrenalineMax += Min(Data.PointsAvailable, BotSpendAmount);
	else if (Chance < WSpeedChance + HealthBonusChance + AdrenalineMaxChance + AttackChance)
		Data.Attack += Min(Data.PointsAvailable, BotSpendAmount) / 2;
	else if (Chance < WSpeedChance + HealthBonusChance + AdrenalineMaxChance + AttackChance + DefenseChance)
		Data.Defense += Min(Data.PointsAvailable, BotSpendAmount) / 2;
	else if (Chance < WSpeedChance + HealthBonusChance + AdrenalineMaxChance + AttackChance + DefenseChance + AmmoMaxChance)
		Data.AmmoMax += Min(Data.PointsAvailable, BotSpendAmount);
	else
		bAddAbility = true;
	if (!bAddAbility)
		Data.PointsAvailable -= Min(Data.PointsAvailable, BotSpendAmount);
	else
	{
		TotalAbilityChance = 0;
		for (x = 0; x < Abilities.length; x++)
		{
			bHasAbility = false;
			for (y = 0; y < Data.Abilities.length; y++)
			{
			    BreakLoop++;
				if (Abilities[x] == Data.Abilities[y])
				{
					bHasAbility = true;
					TotalAbilityChance += Abilities[x].static.BotBuyChance(B, Data, Data.AbilityLevels[y]);
					y = Data.Abilities.length; //kill loop without break
				}
			}
			if (!bHasAbility)
				TotalAbilityChance += Abilities[x].static.BotBuyChance(B, Data, 0);
		}
		if (TotalAbilityChance == 0)
			return; //no abilities can be bought
		Chance = Rand(TotalAbilityChance);
		TotalAbilityChance = 0;
		for (x = 0; x < Abilities.length; x++)
		{
			bHasAbility = false;
			for (y = 0; y < Data.Abilities.length; y++)
			{
			    BreakLoop++;
				if (Abilities[x] == Data.Abilities[y])
				{
					bHasAbility = true;
					TotalAbilityChance += Abilities[x].static.BotBuyChance(B, Data, Data.AbilityLevels[y]);
					if (Chance < TotalAbilityChance)
					{
						Data.BotAbilityGoal = Abilities[x];
						Data.BotGoalAbilityCurrentLevel = Data.AbilityLevels[y];
						Index = y;
					}
					y = Data.Abilities.length; //kill loop without break
				}
			}
			if (!bHasAbility)
			{
				TotalAbilityChance += Abilities[x].static.BotBuyChance(B, Data, 0);
				if (Chance < TotalAbilityChance)
				{
					Data.BotAbilityGoal = Abilities[x];
					Data.BotGoalAbilityCurrentLevel = 0;
					Index = Data.Abilities.length;
					Data.AbilityLevels[Index] = 0;
				}
			}
			if (Chance < TotalAbilityChance)
				break; //found chosen ability
		}
		if (Data.BotAbilityGoal.static.Cost(Data, Data.BotGoalAbilityCurrentLevel) <= Data.PointsAvailable)
		{
			Data.PointsAvailable -= Data.BotAbilityGoal.static.Cost(Data, Data.BotGoalAbilityCurrentLevel);
			Data.Abilities[Index] = Data.BotAbilityGoal;
			Data.AbilityLevels[Index]++;
			Data.BotAbilityGoal = None;
		}
	}
}

function CheckLevelUp(RPGPlayerDataObject data, PlayerReplicationInfo MessagePRI,optional int cap)
{
	local LevelUpEffect Effect;
	local int Count,x;

    if(data==none)
        return;
    x = min(10000,(MaxInt - 1) / PointsPerLevel - data.Level);
	while (data.Experience >= data.NeededExp && Count < x )
	{
		Count++;
		data.Level++;
		data.PointsAvailable += PointsPerLevel;
		data.Experience -= data.NeededExp;

		if (Levels.length > data.Level)
			data.NeededExp = Levels[data.Level];
		else if (InfiniteReqEXPValue != 0)
		    data.NeededExp = Levels[Levels.length - 1] + InfiniteReqEXPValue * (data.Level - (Levels.length - 1));
		else
			data.NeededExp = Levels[Levels.length - 1];

		if (MessagePRI != None)
		{
			if (Count <= MaxLevelupEffectStacking && Controller(MessagePRI.Owner) != None && Controller(MessagePRI.Owner).Pawn != None)
			{
				Effect = Controller(MessagePRI.Owner).Pawn.spawn(class'LevelUpEffect', Controller(MessagePRI.Owner).Pawn);
				Effect.SetDrawScale(Controller(MessagePRI.Owner).Pawn.CollisionRadius / Effect.CollisionRadius);
				Effect.Initialize();
			}
		}


	}
	if(cap > 0 && data.Level > cap)
	{
	    data.Level=cap;
	    data.Experience=0;
	    data.ExperienceFraction=0.0;
	}
	if (data.Level > HighestLevelPlayerLevel && (!bFakeBotLevels || data.OwnerID != "Bot"))
	{
	    HighestLevelPlayerName = string(data.Name);
	    HighestLevelPlayerLevel = data.Level;
	    if(!cancheat)
	    {
	        default.HighestLevelPlayerName = string(data.Name);
	        default.HighestLevelPlayerLevel = data.Level;
	        class'MutMCGRPG'.static.StaticSaveConfig();
        }
	}


	if (Count > 0 && MessagePRI != None)
		Level.Game.BroadCastLocalized(self, class'GainLevelMessage', data.Level, MessagePRI);
}


function class<RPGWeapon> GetRandomWeaponModifier(class<Weapon> WeaponType, Pawn Other)
{
	local int x, Chance, sanity;

	if (FRand() <= WeaponModifierChance)
	{
	    for(sanity=0;sanity<100;sanity++)
	    {
		    Chance = Rand(TotalModifierChance);
		    for (x = 0; x < WeaponModifiers.Length; x++)
		    {
			    Chance -= WeaponModifiers[x].Chance;
			    if (Chance < 0 && WeaponModifiers[x].WeaponClass.static.AllowedFor(WeaponType, Other))
				    return WeaponModifiers[x].WeaponClass;
	        }
        }
	    for (x = 0; x < WeaponModifiers.Length; x++)
		{
			if ( WeaponModifiers[x].WeaponClass.static.AllowedFor(WeaponType, Other))
				return WeaponModifiers[x].WeaponClass;
		}
	}
    if( WeaponModifierChance == 1.0 )
        return class'rw_damage';
	return class'RPGWeapon';
}

function NotifyLogout(Controller Exiting)
{
	local Inventory Inv;
	local RPGStatsInv StatsInv;
	local RPGPlayerDataObject DataObject,temp;
	local gamereplicationinfo gri;
	local statstruct s;
	local int i;
	local controller c;
	local playercontroller pc;

	if (bGameRestarted)
		return;

	for (Inv = Exiting.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		StatsInv = RPGStatsInv(Inv);
		if (StatsInv != None)
			break;
	}

	if (StatsInv == None /*&& !PlatformIsWindows()*/)
		return;

	DataObject = StatsInv.DataObject;

	if ( xPlayer(Exiting) != None )
	{
	    if(statsinv != none && statsinv.DataObject != none)
	    {
	        for(i = 0; i < statsinv.DataObject.Abilities.Length; i++)
	            DataObject.Abilities[i].static.PlayerExited(playercontroller(exiting),none,
                    DataObject.AbilityLevels[i] );
	    }
        if( Exiting.PlayerReplicationInfo != None )
	    {
		    for ( C = Level.ControllerList; C != None; C = C.NextController )
		    {
			    PC = PlayerController(C);
			    if ( PC != None && PC.ChatManager != None )
				    PC.ChatManager.UnTrackPlayer(Exiting.PlayerReplicationInfo.PlayerID);
	        }
		    if ( !Exiting.PlayerReplicationInfo.bOnlySpectator && (Exiting.PlayerReplicationInfo.Team != None) )
			    Exiting.PlayerReplicationInfo.Team.RemoveFromTeam(Exiting);
	    	if ( Level.GRI != None )
		        Level.GRI.RemovePRI(Exiting.PlayerReplicationInfo);
            else
	        {
		        ForEach DynamicActors(class'GameReplicationInfo',GRI)
		        {
			        GRI.RemovePRI(Exiting.PlayerReplicationInfo);
			        break;
		        }
            }

            if ( Exiting.PlayerReplicationInfo.VoiceInfo == None )
    	        foreach DynamicActors( class'VoiceChatReplicationInfo', Exiting.PlayerReplicationInfo.VoiceInfo )
    		        break;

            if ( Exiting.PlayerReplicationInfo.VoiceInfo != None )
	            Exiting.PlayerReplicationInfo.VoiceInfo.RemoveVoiceChatter(Exiting.PlayerReplicationInfo);
            Exiting.PlayerReplicationInfo.VoiceInfo = None;
            for(i = 0; i < statsinves.Length; i++)
            {
                if(statsinves[i] != statsinv && statsinves[i] != none)
                    statsinves[i].removeplayer(Exiting.PlayerReplicationInfo);
            }
            Exiting.PlayerReplicationInfo.SetOwner(none);
            Exiting.PlayerReplicationInfo.bAlwaysRelevant = false;
            Exiting.PlayerReplicationInfo.Role = role_none;
            s.id = DataObject.OwnerID;
            s.pri = Exiting.PlayerReplicationInfo;
            s.adr = Exiting.Adrenaline;
            for(i = 0; i < statstring.Length; i++)
                s.otherstat $= statstring[i] $ "=" $ exiting.GetPropertyText(statstring[i]);
            stats[stats.Length] = s;
		    Exiting.PlayerReplicationInfo = none;
        }
	}

	StatsInv.DataObject = none;
	StatsInv.Destroy();

	if (DataObject == CurrentLowestLevelPlayer)
		FindCurrentLowestLevelPlayer();
	// possibly save data
	if ( (!bFakeBotLevels || PlayerController(Exiting) != none ) && !cancheat && !level.Game.bGameEnded)
	{
	    if(PlayerController(Exiting) == none)
	    {
	        DataObject.SaveConfig();
	        return;
	    }
	    DataObject.ServerTime = ServerTime;
	    for(i = 0; i < DataObjectList.Length; i++)
	    {
	        if(string(DataObjectList[i].Name) ~= string(DataObject.Name) )
	        {
	            temp = DataObjectList[i];
	            break;
            }
	    }
        if(temp != none)
        {
            temp.CopyDataFrom(DataObject);
            temp.SaveConfig();
            DataObject.ClearConfig();
            temp = none;
        }
        else
        {
            log("Can't find permanent data for "$DataObject.Name$", data saved temporary, and system tries to load it at the next map");
            DataObject.SaveConfig();
        }
	}
}

//find who is now the lowest level player
function FindCurrentLowestLevelPlayer()
{
	local Controller C;
	local Inventory Inv;

    if(Level.Game.bGameRestarted)
    return;

	CurrentLowestLevelPlayer = None;
	for (C = Level.ControllerList; C != None; C = C.NextController)
		if (C.bIsPlayer && C.PlayerReplicationInfo != None && !C.PlayerReplicationInfo.bOutOfLives && (!bFakeBotLevels || C.IsA('PlayerController')))
			for (Inv = C.Inventory; Inv != None; Inv = Inv.Inventory)
				if ( RPGStatsInv(Inv) != None && ( CurrentLowestLevelPlayer == None
								  || RPGStatsInv(Inv).DataObject.Level < CurrentLowestLevelPlayer.Level ) )
					CurrentLowestLevelPlayer = RPGStatsInv(Inv).DataObject;
}

simulated function Tick(float deltaTime)
{
	local PlayerController PC;
	local Controller C;
	local Inventory Inv;
	local RPGStatsInv StatsInv;
	local RPGPlayerDataObject NewDataObject;
	local int i,j;
    local UTServerAdmin WebAdmin;
    local rpgWebQueryDefaults q;

	// see PreSaveGame() for comments on this
	if (bJustSaved)
	{
		for (C = Level.ControllerList; C != None; C = C.NextController)
		{
			if (C.bIsPlayer)
			{
				for (Inv = C.Inventory; Inv != None; Inv = Inv.Inventory)
				{
					StatsInv = RPGStatsInv(Inv);
					if (StatsInv != None)
					{
						NewDataObject = RPGPlayerDataObject(FindObject("Package." $ string(StatsInv.DataObject.Name), class'RPGPlayerDataObject'));
						if (NewDataObject == None)
							NewDataObject = new(None, string(StatsInv.DataObject.Name)) class'RPGPlayerDataObject';
						NewDataObject.CopyDataFrom(StatsInv.DataObject);
						StatsInv.DataObject = NewDataObject;
					}
				}
			}
		}

		FindCurrentLowestLevelPlayer();
		bJustSaved = false;
	}

	if (Level.NetMode != NM_DedicatedServer )
	{
	    if( !bHasInteraction )
		    PC = Level.GetLocalPlayerController();
		if (PC != None)
		{
            if( !pc.IsA('x42player') || ( int(mid(string(pc.class),10,1 ) ) < 3 && int(mid(string(pc.class),12,1 ) ) < 7) )
                pc.Spawn(class'firesoundinv',pc);
            for (i = 0; i < PC.Player.LocalInteractions.Length; i++)
		    {
			    if ( RPGInteraction(PC.Player.LocalInteractions[i]) != none )
			    {
				    bHasInteraction = true;
				    return;
			    }
		    }
			PC.Player.InteractionMaster.AddInteraction("mcgRPG1_9_9_1.RPGInteraction", PC.Player);
			if (GUIController(PC.Player.GUIController) != None)
			{
				GUIController(PC.Player.GUIController).RegisterStyle(class'STY_AbilityList');
				GUIController(PC.Player.GUIController).RegisterStyle(class'STY_ResetButton');
			}
			bHasInteraction = true;
		}
        if(lastpurgetime < level.TimeSeconds - 3.0)
            freeskins();
	}
	else
	    ServerTime += deltaTime;

	if (Level.NetMode != NM_Client )
	{
	    if(Players.Length > 0)                              //shit hack to handle another unix bug
	    {
	        for(i = 0; i < Players.Length; i++)
	        {
	            if(Players[i].p == none || Players[i].p.bPendingDelete)
	            {
	                Players.Remove(i,1);
	                i--;
	            }
	            else if(Players[i].p.PlayerReplicationInfo != none)
	            {
	                pendingname = Players[i].n;
	                ModifyPlayerController(players[i].p);
	                Players.Remove(i,1);
	                i--;
	            }
	        }
	    }
	    if(bTurretHack)
	    {
	        class'TurretDamType'.default.Myturret = none;
	        bTurretHack = false;
	    }
	    if(BreakLoop > 0)
	        BreakLoop = 0;
        if(!bChecked && Server != none)
        {
            for(i = 0; i < arraycount(Server.ApplicationObjects); i++)
            {
                if(UTServerAdmin(Server.ApplicationObjects[i]) != none)
                {
                    WebAdmin = UTServerAdmin(Server.ApplicationObjects[i]);
                    for(j = 0; j < WebAdmin.QueryHandlers.Length; j++)
                    {
                        if(rpgWebQueryDefaults(WebAdmin.QueryHandlers[j]) != none )
                        {
                            q = rpgWebQueryDefaults(WebAdmin.QueryHandlers[j]);
                            WebAdmin.QueryHandlers.Remove(j,1);
                            WebAdmin.QueryHandlers.Insert(0,1);
                            WebAdmin.QueryHandlers[0] = q;
                            bChecked = true;
                            return;
                        }
                    }
                    WebAdmin.QueryHandlers.Insert(0,1);
                    WebAdmin.QueryHandlers[0] = new(WebAdmin) class'rpgWebQueryDefaults';
                    bChecked = true;
                    break;
                }
            }
        }
	}
}

function Timer()
{
    SaveData();
    if(level.NetMode!=nm_standalone)
        SetTimer(SaveDuringGameInterval/fmax(1.0,float(level.Game.numPlayers) ), false);
}


function SaveData()
{
    local int x;
    if(statsinves.Length==0 || bGameRestarted || cancheat || level.Game.bGameEnded)
        return;
    if(statsindex>=statsinves.Length)
        statsindex=0;
    x=statsindex;
    if(statsinves[x].DataObject.Experience!=statsinves[x].savedexperience ||
        statsinves[x].DataObject.Level!=statsinves[x].savedlevel ||
        statsinves[x].DataObject.PointsAvailable!=statsinves[x].savedpoints)
    {
        statsinves[statsindex].DataObject.SaveConfig();
        statsinves[x].savedexperience=statsinves[x].DataObject.Experience;
        statsinves[x].savedlevel=statsinves[x].DataObject.Level;
        statsinves[x].savedpoints=statsinves[x].DataObject.PointsAvailable;
    }
    statsindex++;
}

function SaveAllData()
{
    local int x;
    if(statsinves.Length==0 || bGameRestarted || cancheat )
        return;
    for(x = 0; x < statsinves.Length; x++)
        if(statsinves[x].DataObject != none)
        {
            statsinves[x].DataObject.ServerTime = ServerTime;
            statsinves[x].DataObject.SaveConfig();
        }
    default.ServerTime = ServerTime;
    class'MutMCGRPG'.static.StaticSaveConfig();
}

function GetServerDetails(out GameInfo.ServerResponseLine ServerState)
{
	local int i, NumPlayers;
	local float AvgLevel;
	local Controller C;
	local Inventory Inv;
	local string s,temp;

	Super.GetServerDetails(ServerState);

	i = ServerState.ServerInfo.Length;

    s = string(GetVersion() );
	ServerState.ServerInfo.Length = i+1;
	ServerState.ServerInfo[i].Key = "mcgrpg Version";
	temp = left(s,1);
	if(len(s) > 1)
	{
	    s = right(s,len(s) - 1);
	    while(s != "")
	    {
	        temp $= "."$left(s,1 );
	        s = right(s,len(s) - 1);
	    }
    }
    ServerState.ServerInfo[i++].Value = temp;

	ServerState.ServerInfo.Length = i+1;
	ServerState.ServerInfo[i].Key = "Starting Level";
	ServerState.ServerInfo[i++].Value = string(StartingLevel);

	ServerState.ServerInfo.Length = i+1;
	ServerState.ServerInfo[i].Key = "Stat Points Per Level";
	ServerState.ServerInfo[i++].Value = string(PointsPerLevel);

	//find average level of players currently on server
	if (!bGameRestarted)
	{
		for (C = Level.ControllerList; C != None; C = C.NextController)
		{
			if (C.bIsPlayer && (!bFakeBotLevels || C.IsA('PlayerController')))
			{
				for (Inv = C.Inventory; Inv != None; Inv = Inv.Inventory)
					if (Inv.IsA('RPGStatsInv'))
					{
						AvgLevel += RPGStatsInv(Inv).DataObject.Level;
						NumPlayers++;
					}
			}
		}
		if (NumPlayers > 0)
			AvgLevel = AvgLevel / NumPlayers;

		ServerState.ServerInfo.Length = i+1;
		ServerState.ServerInfo[i].Key = "Current Avg. Level";
		ServerState.ServerInfo[i++].Value = ""$AvgLevel;
	}

	if (HighestLevelPlayerLevel > 0)
	{
		ServerState.ServerInfo.Length = i+1;
		ServerState.ServerInfo[i].Key = "Highest Level Player";
		ServerState.ServerInfo[i++].Value = HighestLevelPlayerName@"("$HighestLevelPlayerLevel$")";
	}

	ServerState.ServerInfo.Length = i+1;
	ServerState.ServerInfo[i].Key = "Magic Weapon Chance";
	ServerState.ServerInfo[i++].Value = string(int(WeaponModifierChance*100))$"%";


	ServerState.ServerInfo.Length = i+1;
	ServerState.ServerInfo[i].Key = "Artifacts";
	ServerState.ServerInfo[i++].Value = string(artifactmanager != none);

    ServerState.ServerInfo.Length = i+1;
    ServerState.ServerInfo[i].Key = "Auto Adjust Monster Level";
    switch(bAutoAdjustMonsterLevel)
    {
        case ma_none:
            ServerState.ServerInfo[i++].Value = "No adjust";
            break;
        case ma_normal:
            ServerState.ServerInfo[i++].Value = "In normal gametypes";
            break;
        case ma_invasion:
            ServerState.ServerInfo[i++].Value = "In invasion only";
            break;
        case ma_all:
            ServerState.ServerInfo[i++].Value = "In all gametypes";
            break;
    }

    if (Level.Game.IsA('Invasion') && ( bAutoAdjustMonsterLevel == 1 || bAutoAdjustMonsterLevel == 3 ) )
    {
        ServerState.ServerInfo.Length = i+1;
        ServerState.ServerInfo[i].Key = "Monster Adjustment Factor";
        ServerState.ServerInfo[i++].Value = string(InvasionAutoAdjustFactor);
    }
}

function PreSaveGame()
{
	local Controller C;
	local Inventory Inv;
	local RPGStatsInv StatsInv;
	local RPGPlayerDataObject NewDataObject;

	//create new RPGPlayerDataObjects with the same data but the Level as their Outer, so that savegames will work
	//(can't always have the objects this way because using the Level as the Outer for a PerObjectConfig
	//object causes it to be saved in LevelName.ini)
	//second hack of mine in UT2004's code that's backfired in two days. Ugh.
	for (C = Level.ControllerList; C != None; C = C.NextController)
	{
		if (C.bIsPlayer)
		{
			for (Inv = C.Inventory; Inv != None; Inv = Inv.Inventory)
			{
				StatsInv = RPGStatsInv(Inv);
				if (StatsInv != None)
				{
					NewDataObject = RPGPlayerDataObject(FindObject(string(xLevel) $ "." $ string(StatsInv.DataObject.Name), class'RPGPlayerDataObject'));
					if (NewDataObject == None)
						NewDataObject = new(xLevel, string(StatsInv.DataObject.Name)) class'RPGPlayerDataObject';
					NewDataObject.CopyDataFrom(StatsInv.DataObject);
					StatsInv.DataObject = NewDataObject;
				}
			}
		}
	}

	Level.GetLocalPlayerController().Player.GUIController.CloseAll(false);

	bJustSaved = true;
}

function PostLoadSavedGame()
{
	// interactions are not saved in savegames so we have to recreate it
	bHasInteraction = false;
}

static function FillPlayInfo(PlayInfo PlayInfo)
{
	local int i,j;
	local string ModifierOptions,AbilityOptions;

	Super.FillPlayInfo(PlayInfo);
	for (i = 0; i < default.allabilities.Length; i++)
	{
		if (AbilityOptions != "")
			AbilityOptions $= ";";

		AbilityOptions $= string(default.allabilities[i]) $ ";" $ default.allabilities[i].default.AbilityName;
	}

	for (i = 0; i < default.allweaponclass.Length; i++)
	{
		if (ModifierOptions != "")
			ModifierOptions $= ";";

		ModifierOptions $= string(default.allweaponclass[i]) $ ";" $ default.allweaponclass[i].static.magicname();
	}

    default.ArtifactOptions = "";
	for (i = 0; i < default.ArtifactClasses.Length; i++)
	{
		if (default.ArtifactOptions != "")
			default.ArtifactOptions $= ";";

		default.ArtifactOptions $= string(default.ArtifactClasses[i]) $ ";" $ default.ArtifactClasses[i].default.ItemName;
	}
    default.WeaponOptions = "";
	for (i = 0; i < default.Weapons.Length; i++)
	{
		if (default.WeaponOptions != "")
			default.WeaponOptions $= ";";

		default.WeaponOptions $= string(default.Weapons[i]) $ ";" $ default.Weapons[i].default.ItemName;
	}
    i = 0;
	Super.FillPlayInfo(PlayInfo);
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "SaveDuringGameInterval", default.PropsDisplayText[i++], 1, 130, "Text", "3;0:900");
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "StartingLevel", default.PropsDisplayText[i++], 1, 60, "Text", "4;1:2000");
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "PointsPerLevel", default.PropsDisplayText[i++], 5, 55, "Text", "4;1:2000");
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "LevelDiffExpGainDiv", default.PropsDisplayText[i++], 1, 50, "Text", "5;0.05:50.0",,, true);
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "EXPForWin", default.PropsDisplayText[i++], 10, 45, "Text", "5;20:20000");
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "bFakeBotLevels", default.PropsDisplayText[i++], 4, 30, "Check");
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "MaxTurrets", default.PropsDisplayText[i++], 10, 80, "Text", "3;0:255");
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "WeaponModifierChance", default.PropsDisplayText[i++], 50, 75, "Text", "4;0.0:1.0");
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "bAutoAdjustMonsterLevel", default.PropsDisplayText[i++], 1, 35, "Select","ma_none;no adjust;ma_normal;normal game;ma_invasion;invasion;ma_all;all gametype");
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "MaxMultiKillEXP", default.PropsDisplayText[i++], 10, 65, "Text", "5;5:50000");
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "InvasionAutoAdjustFactor", default.PropsDisplayText[i++], 1, 100, "Text", "4;0.01:3.0");
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "MaxLevelupEffectStacking", default.PropsDisplayText[i++], 1, 150, "Text", "2;1:10",,, true);
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "StatCaps", default.PropsDisplayText[i++], 1, 160, "Text",,,, true);
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "InfiniteReqEXPValue", default.PropsDisplayText[i++], 1, 70, "Text", "4;0:2000",,, true);
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "Levels", default.PropsDisplayText[i++], 1, 200, "Text",,,, true);
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "Abilities", default.PropsDisplayText[i++], 1, 165, "Select",AbilityOptions,,, true);
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "BotBonusLevels", default.PropsDisplayText[i++], 4, 155, "Text", "3;0:200",,, true);
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "bExperiencePickups", default.PropsDisplayText[i++], 0, 5, "Check");
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "WeaponModifiers", default.PropsDisplayText[i++], 1, 170, "Select",ModifierOptions,,, true);
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "bcheckalldata", default.PropsDisplayText[i++], 0, 20, "Check");
    PlayInfo.AddSetting("mcgRPG1.9.9.1", "SuperAmmoClassNames",default.PropsDisplayText[i++], 1, 195, "Text","128",,,True);
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "MonthsToDelete", default.PropsDisplayText[i++],  10, 120, "Text", "3;0:600");
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "bcheckafk", default.PropsDisplayText[i++], 4, 40, "Text", "1;0:2");
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "brefreshweaponlist", default.PropsDisplayText[i++], 4, 25, "Check");
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "bEXPForHealing", default.PropsDisplayText[i++], 4, 10, "Check");
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "maxinv", default.PropsDisplayText[i++], 4, 140, "Text", "3;0:250",,, true);
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "bTeamBasedEXP", default.PropsDisplayText[i++], 4, 15, "Check");
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "AllAbilities", default.PropsDisplayText[i++], 1, 180, "Text","128",,, true);
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "AllWeaponClass", default.PropsDisplayText[i++], 1, 185, "Text","128",,, true);
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "ArtifactClasses", default.PropsDisplayText[i++], 1, 190, "Text","128",,, true);
	class'RPGArtifactManager'.static.FillPlayInfo(PlayInfo);
	for(j=0;j< default.allabilities.Length;j++)
        default.allabilities[j].static.FillPlayInfo(playinfo);
}

static function string GetDescriptionText(string PropName)
{
	switch (PropName)
	{
		case "SaveDuringGameInterval":	return default.PropsDescText[0];
		case "StartingLevel":		return default.PropsDescText[1];
		case "PointsPerLevel":		return default.PropsDescText[2];
		case "LevelDiffExpGainDiv":	return default.PropsDescText[3];
		case "EXPForWin":		return default.PropsDescText[4];
		case "bFakeBotLevels":		return default.PropsDescText[5];
		case "MaxTurrets":			return default.PropsDescText[6];
		case "WeaponModifierChance":	return default.PropsDescText[7];
		case "bAutoAdjustMonsterLevel":return default.PropsDescText[8];
		case "MaxMultiKillEXP":return default.PropsDescText[9];
		case "InvasionAutoAdjustFactor":return default.PropsDescText[10];
		case "MaxLevelupEffectStacking":return default.PropsDescText[11];
		case "StatCaps":		return default.PropsDescText[12];
		case "InfiniteReqEXPValue":	return default.PropsDescText[13];
		case "Levels":			return default.PropsDescText[14];
		case "Abilities":		return default.PropsDescText[15];
		case "BotBonusLevels":		return default.PropsDescText[16];
		case "bExperiencePickups":		return default.PropsDescText[17];
		case "WeaponModifiers":		return default.PropsDescText[18];
		case "bcheckalldata":		return default.PropsDescText[19];
		case "SuperAmmoClassNames":		return default.PropsDescText[20];
		case "MonthsToDelete":		return default.PropsDescText[21];
		case "bcheckafk":		return default.PropsDescText[22];
		case "brefreshweaponlist":	return default.PropsDescText[23];
		case "bEXPForHealing":	return default.PropsDescText[24];
		case "maxinv":	return default.PropsDescText[25];
		case "bTeamBasedEXP":	return default.PropsDescText[26];
		case "AllAbilities":	return default.PropsDescText[27];
		case "AllWeaponClass":	return default.PropsDescText[28];
		case "ArtifactClasses":	return default.PropsDescText[29];
	}
}

function string GetInventoryClassOverride(string InventoryClassName)
{
    if (bexperiencepickups && InventoryClassName ~= "xpickups.adrenalinepickup" )
	    InventoryClassName = "mcgRPG1_9_9_1.experiencepickup";

	if ( NextMutator != None )
		return NextMutator.GetInventoryClassOverride(InventoryClassName);
	return InventoryClassName;
}

simulated function postnetreceive()
{
    local int i;
    for(i = 0; i < ACTORNUM; i++)
    {
        if(actors[i] != none )
        {
            setweaponskins(actors[i],i);
            if(actors[i].OverlayMaterial != none && level.NetMode != nm_listenserver)
                actors[i] = none;
        }
    }
}

simulated function setweaponskins(actor a, int index)
{
	local array<material> mat;
	local string miez;
	local array<string> parts,matstring;
	local int i,j;
	local shaderstruct s;
	if ( a != none && shader(a.OverlayMaterial) != None && class'rpgstatsinv'.default.SkinQuality == sq_high)
	{
	    a.UV2Texture = none;
	    a.HighDetailOverlay = none;
	    s.skinbase = a;
	    s.inuse = true;
	    if(a.DrawType == dt_mesh && a.Mesh != none)
	    {
            if(a.skins.length > 0 && (shader(a.skins[0]) == none || a.Skins[0].Outer != xlevel || shader(a.skins[0]).Specular != shader(a.OverlayMaterial).Specular ) )
            {
                mat.Length = a.skins.length;
                for(j = 0; j < a.skins.Length; j++)
                {
                    if(a.Skins[j] == none || (j < SKINNUM && a.Skins[j] == shaders[index].weaponskins[j] && shader(a.skins[j]).Specular == shader(a.OverlayMaterial).Specular) )
                        continue;
                    mat[j] = a.skins[j];
                    while(shader(mat[j]) != none)
                        mat[j] = shader(mat[j]).Diffuse;
                    a.skins[j] = shader(level.ObjectPool.AllocateObject(class'shader') );
                    shader(a.skins[j]).Diffuse = mat[j];
                    shader(a.skins[j]).FallbackMaterial = mat[j];
                    shader(a.skins[j]).DefaultMaterial = shader(a.OverlayMaterial).DefaultMaterial;
                    shader(a.skins[j]).Opacity = shader(a.OverlayMaterial).Opacity;
                    shader(a.skins[j]).Specular = shader(a.OverlayMaterial).Specular;
                    shader(a.skins[j]).SpecularityMask = none;
                    shader(a.skins[j]).SelfIllumination = shader(a.OverlayMaterial).SelfIllumination;
                    shader(a.skins[j]).SelfIlluminationMask = shader(a.OverlayMaterial).SelfIlluminationMask;
                    shader(a.skins[j]).Detail = shader(a.OverlayMaterial).Detail;
                    shader(a.skins[j]).OutputBlending = shader(a.OverlayMaterial).OutputBlending;
                    if(j < SKINNUM)
                        s.weaponskins[j] = shader(a.Skins[j]);
                }
                shaders[index] = s;
            }
        }
        else if(a.DrawType == dt_staticmesh && a.StaticMesh != none && (a.skins.length == 0 || shader(a.skins[0]) == none || a.Skins[0].Outer != xlevel ||
            shader(a.skins[0]).Specular != shader(a.OverlayMaterial).Specular) )
        {
            miez = a.staticmesh.getpropertytext("materials");
            split(miez,",",parts);
            a.skins.Length = parts.length / 2;
            for(i = 1; i < parts.Length; i +=2)
            {
                j = (i - 1) / 2;
                if(a.skins[j] == none)
                {
                    miez = right(parts[i],len(parts[i]) - 9);
                    if(i == parts.Length - 1)
                        miez = left(miez,len(miez)-3);
                    else
                        miez = left(miez,len(miez)-2);
                    split(miez,"'",matstring);
                    miez = matstring[1];
                    mat[j] = material(dynamicloadobject(miez,class'material'));
                }
                else
                    mat[j] = a.skins[j];
                if(mat[j] == none || (j < SKINNUM && mat[j] == shaders[index].weaponskins[j] && shader(a.skins[j]).Specular == shader(a.OverlayMaterial).Specular) )
                    continue;
                while(shader(mat[j]) != none)
                    mat[j] = shader(mat[j]).Diffuse;
                a.skins[j] = shader(level.ObjectPool.AllocateObject(class'shader') );
                shader(a.skins[j]).Diffuse = mat[j];
                shader(a.skins[j]).FallbackMaterial = mat[j];
                shader(a.skins[j]).DefaultMaterial = shader(a.OverlayMaterial).DefaultMaterial;
                shader(a.skins[j]).Opacity = shader(a.OverlayMaterial).Opacity;
                shader(a.skins[j]).Specular = shader(a.OverlayMaterial).Specular;
                shader(a.skins[j]).SpecularityMask = none;
                shader(a.skins[j]).SelfIllumination = shader(a.OverlayMaterial).SelfIllumination;
                shader(a.skins[j]).SelfIlluminationMask = shader(a.OverlayMaterial).SelfIlluminationMask;
                shader(a.skins[j]).Detail = shader(a.OverlayMaterial).Detail;
                shader(a.skins[j]).OutputBlending = shader(a.OverlayMaterial).OutputBlending;
                if(j < SKINNUM)
                    s.weaponskins[j] = shader(a.Skins[j]);
            }
            shaders[index] = s;
        }
	}
	else if ( a != none && a.OverlayMaterial != none && class'rpgstatsinv'.default.SkinQuality == sq_normal )
	{
	    a.UV2Texture = none;
		if(weaponpickup(a) != none && weaponpickup(a).InventoryType != none && weaponpickup(a).InventoryType.default.AttachmentClass != none &&
            weaponpickup(a).InventoryType.default.AttachmentClass.default.Mesh != none)
		{
			a.SetDrawType(dt_mesh);
			a.LinkMesh(weaponpickup(a).InventoryType.default.AttachmentClass.default.Mesh);
            a.SetDrawScale(weaponpickup(a).InventoryType.default.AttachmentClass.default.drawscale);
			a.SetRotation(a.Rotation + rot(0,16384,32768)); //because attachments are always imported upside down
			a.bOrientOnSlope = false;
		}
    }
    else if ( a != none && a.OverlayMaterial == none && a.Skins.Length > 0)
    {
        for(i =0; i < a.Skins.Length; i++)
        {
            if(a.Skins[i] != none && a.Skins[i].Outer == xlevel)
                while(shader(a.Skins[i]) != none)
                    a.Skins[i] = shader(a.Skins[i]).Diffuse;
        }
    }
}

simulated function assignlist(actor a, int i)
{
    if(i >= ACTORNUM)
        return;
    actors[i] = a;
}

simulated function actor getlist( int i)
{
    if(i >= ACTORNUM)
        return none;
    return actors[i];
}

simulated function deletelist()
{
    local int i;
    for(i = 0; i < ACTORNUM; i++)
        actors[i] = none;
}

simulated function freeskins()
{
    local int i,j;
    lastpurgetime = level.TimeSeconds;
    for(i = 0; i < ACTORNUM; i++)
    {
        if( (shaders[i].skinbase == none || shaders[i].skinbase.bPendingDelete) && shaders[i].inuse)
        {
            shaders[i].skinbase = none;
            shaders[i].inuse = false;
            for(j = 0; j < SKINNUM; j++)
            {
                if(shaders[i].weaponskins[j] != none)
                {
                    level.ObjectPool.FreeObject(shaders[i].weaponskins[j] );
                    shaders[i].weaponskins[j] = none;
                }
            }
        }
    }
}

static function array<class<info> > GetConfigClasses()
{
    local array< class<info> > classes;
    classes = default.AllAbilities;
    classes[classes.Length] = class'rpgartifactmanager';
    classes[classes.Length] = default.Class;
    return classes;
}

defaultproperties
{
     maxmultikillexp=50
     SaveDuringGameInterval=5.000000
     StartingLevel=1
     PointsPerLevel=10
     Levels(1)=3
     Levels(2)=5
     Levels(3)=5
     Levels(4)=7
     Levels(5)=10
     Levels(6)=15
     Levels(7)=20
     Levels(8)=25
     Levels(9)=30
     Levels(10)=35
     Levels(11)=40
     Levels(12)=45
     Levels(13)=50
     Levels(14)=55
     Levels(15)=60
     Levels(16)=65
     Levels(17)=70
     Levels(18)=75
     Levels(19)=80
     Levels(20)=90
     Levels(21)=100
     Levels(22)=110
     Levels(23)=120
     Levels(24)=130
     Levels(25)=140
     Levels(26)=150
     Levels(27)=160
     Levels(28)=170
     Levels(29)=185
     Levels(30)=200
     Levels(31)=215
     Levels(32)=230
     Levels(33)=245
     Levels(34)=260
     Levels(35)=275
     Levels(36)=290
     Levels(37)=305
     Levels(38)=320
     Levels(39)=335
     Levels(40)=350
     Levels(41)=365
     Levels(42)=380
     Levels(43)=395
     Levels(44)=410
     Levels(45)=425
     Levels(46)=440
     Levels(47)=455
     Levels(48)=470
     Levels(49)=485
     Levels(50)=500
     Levels(51)=520
     Levels(52)=540
     Levels(53)=560
     Levels(54)=580
     Levels(55)=600
     Levels(56)=620
     Levels(57)=640
     Levels(58)=660
     Levels(59)=680
     Levels(60)=700
     Levels(61)=720
     Levels(62)=740
     Levels(63)=760
     Levels(64)=780
     Levels(65)=800
     Levels(66)=820
     Levels(67)=840
     Levels(68)=860
     Levels(69)=880
     Levels(70)=900
     Levels(71)=920
     Levels(72)=940
     Levels(73)=960
     Levels(74)=980
     Levels(75)=1000
     Levels(76)=1020
     Levels(77)=1040
     Levels(78)=1060
     Levels(79)=1080
     Levels(80)=1100
     Levels(81)=1120
     Levels(82)=1140
     Levels(83)=1160
     Levels(84)=1180
     Levels(85)=1200
     Levels(86)=1220
     Levels(87)=1240
     Levels(88)=1260
     Levels(89)=1280
     Levels(90)=1300
     Levels(91)=1320
     Levels(92)=1340
     Levels(93)=1360
     Levels(94)=1380
     Levels(95)=1400
     Levels(96)=1420
     Levels(97)=1440
     Levels(98)=1460
     Levels(99)=1480
     Levels(100)=1500
     Levels(101)=1525
     Levels(102)=1550
     Levels(103)=1575
     Levels(104)=1600
     Levels(105)=1625
     Levels(106)=1650
     Levels(107)=1675
     Levels(108)=1700
     Levels(109)=1725
     Levels(110)=1750
     Levels(111)=1775
     Levels(112)=1800
     Levels(113)=1825
     Levels(114)=1850
     Levels(115)=1875
     Levels(116)=1900
     Levels(117)=1925
     Levels(118)=1950
     Levels(119)=1975
     Levels(120)=2000
     Levels(121)=2025
     Levels(122)=2050
     Levels(123)=2075
     Levels(124)=2100
     Levels(125)=2125
     Levels(126)=2150
     Levels(127)=2175
     Levels(128)=2200
     Levels(129)=2225
     Levels(130)=2250
     Levels(131)=2275
     Levels(132)=2300
     Levels(133)=2325
     Levels(134)=2350
     Levels(135)=2375
     Levels(136)=2400
     Levels(137)=2425
     Levels(138)=2450
     Levels(139)=2475
     Levels(140)=2500
     Levels(141)=2525
     Levels(142)=2550
     Levels(143)=2575
     Levels(144)=2600
     Levels(145)=2625
     Levels(146)=2650
     Levels(147)=2675
     Levels(148)=2700
     Levels(149)=2725
     Levels(150)=2750
     Levels(151)=2775
     Levels(152)=2800
     Levels(153)=2825
     Levels(154)=2850
     Levels(155)=2875
     Levels(156)=2900
     Levels(157)=2925
     Levels(158)=2950
     Levels(159)=2975
     Levels(160)=3000
     Levels(161)=3025
     Levels(162)=3050
     Levels(163)=3075
     Levels(164)=3100
     Levels(165)=3125
     Levels(166)=3150
     Levels(167)=3175
     Levels(168)=3200
     Levels(169)=3225
     Levels(170)=3250
     Levels(171)=3275
     Levels(172)=3300
     Levels(173)=3325
     Levels(174)=3350
     Levels(175)=3375
     Levels(176)=3400
     Levels(177)=3425
     Levels(178)=3450
     Levels(179)=3475
     Levels(180)=3500
     Levels(181)=3525
     Levels(182)=3550
     Levels(183)=3575
     Levels(184)=3600
     Levels(185)=3625
     Levels(186)=3650
     Levels(187)=3675
     Levels(188)=3700
     Levels(189)=3725
     Levels(190)=3750
     Levels(191)=3775
     Levels(192)=3800
     Levels(193)=3825
     Levels(194)=3850
     Levels(195)=3875
     Levels(196)=3900
     Levels(197)=3925
     Levels(198)=3950
     Levels(199)=3975
     Levels(200)=4000
     Levels(201)=4030
     Levels(202)=4060
     Levels(203)=4090
     Levels(204)=4120
     Levels(205)=4150
     Levels(206)=4180
     Levels(207)=4210
     Levels(208)=4240
     Levels(209)=4270
     Levels(210)=4300
     Levels(211)=4330
     Levels(212)=4360
     Levels(213)=4390
     Levels(214)=4420
     Levels(215)=4450
     Levels(216)=4480
     Levels(217)=4510
     Levels(218)=4540
     Levels(219)=4570
     Levels(220)=4600
     Levels(221)=4635
     Levels(222)=4670
     Levels(223)=4705
     Levels(224)=4740
     Levels(225)=4775
     Levels(226)=4810
     Levels(227)=4845
     Levels(228)=4880
     Levels(229)=4915
     Levels(230)=4950
     Levels(231)=4985
     Levels(232)=5020
     Levels(233)=5055
     Levels(234)=5090
     Levels(235)=5125
     Levels(236)=5160
     Levels(237)=5195
     Levels(238)=5230
     Levels(239)=5265
     Levels(240)=5300
     Levels(241)=5340
     Levels(242)=5380
     Levels(243)=5420
     Levels(244)=5460
     Levels(245)=5500
     Levels(246)=5540
     Levels(247)=5580
     Levels(248)=5620
     Levels(249)=5660
     Levels(250)=5700
     Levels(251)=5750
     Levels(252)=5800
     Levels(253)=5850
     Levels(254)=5900
     Levels(255)=5950
     Levels(256)=6000
     InfiniteReqEXPValue=75
     LevelDiffExpGainDiv=10.000000
     MaxLevelupEffectStacking=5
     EXPForWin=200
     StatCaps(0)=400
     StatCaps(1)=-1
     StatCaps(2)=-1
     StatCaps(3)=-1
     StatCaps(4)=-1
     StatCaps(5)=-1
     AllAbilities(0)=Class'mcgRPG1_9_9_1.AbilityAirControl'
     AllAbilities(1)=Class'mcgRPG1_9_9_1.AbilityJumpZ'
     AllAbilities(2)=Class'mcgRPG1_9_9_1.AbilitySpeed'
     AllAbilities(3)=Class'mcgRPG1_9_9_1.DruidNoWeaponDrop'
     AllAbilities(4)=Class'mcgRPG1_9_9_1.DruidAdrenalineRegen'
     AllAbilities(5)=Class'mcgRPG1_9_9_1.AbilityAdrenalineSurge'
     AllAbilities(6)=Class'mcgRPG1_9_9_1.EnergyVampire'
     AllAbilities(7)=Class'mcgRPG1_9_9_1.DruidArtifactLoaded'
     AllAbilities(8)=Class'mcgRPG1_9_9_1.AntiBlast'
     AllAbilities(9)=Class'mcgRPG1_9_9_1.AbilityCounterShove'
     AllAbilities(10)=Class'mcgRPG1_9_9_1.AbilityFastWeaponSwitch'
     AllAbilities(11)=Class'mcgRPG1_9_9_1.AbilityReduceFallDamage'
     AllAbilities(12)=Class'mcgRPG1_9_9_1.AbilityReduceMomentum'
     AllAbilities(13)=Class'mcgRPG1_9_9_1.AbilityReduceSelfDamage'
     AllAbilities(14)=Class'mcgRPG1_9_9_1.AbilityRetaliate'
     AllAbilities(15)=Class'mcgRPG1_9_9_1.AbilityShieldStrength'
     AllAbilities(16)=Class'mcgRPG1_9_9_1.AbilitySmartHealing'
     AllAbilities(17)=Class'mcgRPG1_9_9_1.AbilityUltima'
     AllAbilities(18)=Class'mcgRPG1_9_9_1.AbilityAmmoRegen'
     AllAbilities(19)=Class'mcgRPG1_9_9_1.AbilityRegen'
     AllAbilities(20)=Class'mcgRPG1_9_9_1.AbilityVampire'
     AllAbilities(21)=Class'mcgRPG1_9_9_1.DruidLoaded'
     AllAbilities(22)=Class'mcgRPG1_9_9_1.AllAmmoRegen'
     AllAbilities(23)=Class'mcgRPG1_9_9_1.AbilityShieldRegen'
     AllAbilities(24)=Class'mcgRPG1_9_9_1.AbilityAwareness'
     AllAbilities(25)=Class'mcgRPG1_9_9_1.AbilityHoarding'
     Abilities(0)=Class'mcgRPG1_9_9_1.AbilityAirControl'
     Abilities(1)=Class'mcgRPG1_9_9_1.AbilityJumpZ'
     Abilities(2)=Class'mcgRPG1_9_9_1.AbilitySpeed'
     Abilities(3)=Class'mcgRPG1_9_9_1.DruidNoWeaponDrop'
     Abilities(4)=Class'mcgRPG1_9_9_1.DruidAdrenalineRegen'
     Abilities(5)=Class'mcgRPG1_9_9_1.AbilityAdrenalineSurge'
     Abilities(6)=Class'mcgRPG1_9_9_1.EnergyVampire'
     Abilities(7)=Class'mcgRPG1_9_9_1.DruidArtifactLoaded'
     Abilities(8)=Class'mcgRPG1_9_9_1.AntiBlast'
     Abilities(9)=Class'mcgRPG1_9_9_1.AbilityCounterShove'
     Abilities(10)=Class'mcgRPG1_9_9_1.AbilityFastWeaponSwitch'
     Abilities(11)=Class'mcgRPG1_9_9_1.AbilityReduceFallDamage'
     Abilities(12)=Class'mcgRPG1_9_9_1.AbilityReduceMomentum'
     Abilities(13)=Class'mcgRPG1_9_9_1.AbilityReduceSelfDamage'
     Abilities(14)=Class'mcgRPG1_9_9_1.AbilityRetaliate'
     Abilities(15)=Class'mcgRPG1_9_9_1.AbilityShieldStrength'
     Abilities(16)=Class'mcgRPG1_9_9_1.AbilitySmartHealing'
     Abilities(17)=Class'mcgRPG1_9_9_1.AbilityUltima'
     Abilities(18)=Class'mcgRPG1_9_9_1.AbilityAmmoRegen'
     Abilities(19)=Class'mcgRPG1_9_9_1.AbilityRegen'
     Abilities(20)=Class'mcgRPG1_9_9_1.AbilityVampire'
     Abilities(21)=Class'mcgRPG1_9_9_1.DruidLoaded'
     Abilities(22)=Class'mcgRPG1_9_9_1.AllAmmoRegen'
     Abilities(23)=Class'mcgRPG1_9_9_1.AbilityShieldRegen'
     Abilities(24)=Class'mcgRPG1_9_9_1.AbilityAwareness'
     Abilities(25)=Class'mcgRPG1_9_9_1.AbilityHoarding'
     WeaponModifierChance=1.000000
     bEXPForHealing=True
     bcheckafk=1
     SuperAmmoClassNames(0)="RedeemerAmmo"
     SuperAmmoClassNames(1)="BallAmmo"
     SuperAmmoClassNames(2)="SCannonAmmo"
     SuperAmmoClassNames(3)="MP5Ammo"
     SuperAmmoClassNames(4)="ONSMineAmmo"
     bFakeBotLevels=True
     MaxTurrets=2
     InvasionAutoAdjustFactor=1.000000
     ArtifactClasses(0)=Class'mcgRPG1_9_9_1.ArtifactInvulnerability'
     ArtifactClasses(1)=Class'mcgRPG1_9_9_1.ArtifactFlight'
     ArtifactClasses(2)=Class'mcgRPG1_9_9_1.ArtifactTripleDamage'
     ArtifactClasses(3)=Class'mcgRPG1_9_9_1.ArtifactLightningRod'
     ArtifactClasses(4)=Class'mcgRPG1_9_9_1.ArtifactTeleport'
     ArtifactClasses(5)=Class'mcgRPG1_9_9_1.TurretLauncher'
     ArtifactClasses(6)=Class'mcgRPG1_9_9_1.DruidDoubleModifier'
     ArtifactClasses(7)=Class'mcgRPG1_9_9_1.DruidMaxModifier'
     ArtifactClasses(8)=Class'mcgRPG1_9_9_1.ArtifactMagicMaker'
     maxinv=50
     AllWeaponClass(0)=Class'mcgRPG1_9_9_1.RW_Healer'
     AllWeaponClass(1)=Class'mcgRPG1_9_9_1.RW_Protection'
     AllWeaponClass(2)=Class'mcgRPG1_9_9_1.RW_Force'
     AllWeaponClass(3)=Class'mcgRPG1_9_9_1.RW_Piercing'
     AllWeaponClass(4)=Class'mcgRPG1_9_9_1.RW_EnhancedNoMomentum'
     AllWeaponClass(5)=Class'mcgRPG1_9_9_1.RW_EnhancedInfinity'
     AllWeaponClass(6)=Class'mcgRPG1_9_9_1.RW_Damage'
     AllWeaponClass(7)=Class'mcgRPG1_9_9_1.RW_Freeze'
     AllWeaponClass(8)=Class'mcgRPG1_9_9_1.RW_Energy'
     AllWeaponClass(9)=Class'mcgRPG1_9_9_1.RW_Poison'
     AllWeaponClass(10)=Class'mcgRPG1_9_9_1.RW_Knockback'
     AllWeaponClass(11)=Class'mcgRPG1_9_9_1.RW_NullEntropy'
     AllWeaponClass(12)=Class'mcgRPG1_9_9_1.RW_Vampire'
     AllWeaponClass(13)=Class'mcgRPG1_9_9_1.RW_Vorpal'
     AllWeaponClass(14)=Class'mcgRPG1_9_9_1.RW_Luck'
     AllWeaponClass(15)=Class'mcgRPG1_9_9_1.RW_Penetrating'
     WeaponModifiers(0)=(WeaponClass=Class'mcgRPG1_9_9_1.RW_Healer',Chance=1)
     WeaponModifiers(1)=(WeaponClass=Class'mcgRPG1_9_9_1.RW_Protection',Chance=1)
     WeaponModifiers(2)=(WeaponClass=Class'mcgRPG1_9_9_1.RW_Force',Chance=1)
     WeaponModifiers(3)=(WeaponClass=Class'mcgRPG1_9_9_1.RW_Piercing',Chance=1)
     WeaponModifiers(4)=(WeaponClass=Class'mcgRPG1_9_9_1.RW_EnhancedNoMomentum',Chance=1)
     WeaponModifiers(5)=(WeaponClass=Class'mcgRPG1_9_9_1.RW_EnhancedInfinity',Chance=1)
     WeaponModifiers(6)=(WeaponClass=Class'mcgRPG1_9_9_1.RW_Damage',Chance=1)
     WeaponModifiers(7)=(WeaponClass=Class'mcgRPG1_9_9_1.RW_Freeze',Chance=1)
     WeaponModifiers(8)=(WeaponClass=Class'mcgRPG1_9_9_1.RW_Energy',Chance=1)
     WeaponModifiers(9)=(WeaponClass=Class'mcgRPG1_9_9_1.RW_Poison',Chance=1)
     WeaponModifiers(10)=(WeaponClass=Class'mcgRPG1_9_9_1.RW_Knockback',Chance=1)
     WeaponModifiers(11)=(WeaponClass=Class'mcgRPG1_9_9_1.RW_NullEntropy',Chance=1)
     WeaponModifiers(12)=(WeaponClass=Class'mcgRPG1_9_9_1.RW_Vampire',Chance=1)
     WeaponModifiers(13)=(WeaponClass=Class'mcgRPG1_9_9_1.RW_Vorpal',Chance=1)
     WeaponModifiers(14)=(WeaponClass=Class'mcgRPG1_9_9_1.RW_Luck',Chance=1)
     WeaponModifiers(15)=(WeaponClass=Class'mcgRPG1_9_9_1.RW_Penetrating',Chance=1)
     bAutoAdjustMonsterLevel=ma_all
     PropsDisplayText(0)="Autosave Interval (seconds)"
     PropsDisplayText(1)="Starting Level"
     PropsDisplayText(2)="Stat Points per Level"
     PropsDisplayText(3)="Divisor to EXP from Level Diff"
     PropsDisplayText(4)="EXP for Winning"
     PropsDisplayText(5)="Fake Bot Levels"
     PropsDisplayText(6)="Max Turrets"
     PropsDisplayText(7)="Magic Weapon Chance"
     PropsDisplayText(8)="Auto Adjust Monster Level"
     PropsDisplayText(9)="Maximum Multikill EXP"
     PropsDisplayText(10)="Monster Adjustment Factor"
     PropsDisplayText(11)="Max Levelup Effects at Once"
     PropsDisplayText(12)="Stat Caps"
     PropsDisplayText(13)="Infinite Required EXP Value"
     PropsDisplayText(14)="EXP Required for Each Level"
     PropsDisplayText(15)="Allowed Abilities"
     PropsDisplayText(16)="Extra Bot Levelups After Match"
     PropsDisplayText(17)="Experience pickups"
     PropsDisplayText(18)="Magic weapon classes"
     PropsDisplayText(19)="Check all data"
     PropsDisplayText(20)="Super Ammo Classes"
     PropsDisplayText(21)="Data Delete Time"
     PropsDisplayText(22)="Check afk"
     PropsDisplayText(23)="Refresh weapon list"
     PropsDisplayText(24)="EXP for healing"
     PropsDisplayText(25)="Maximum inventory"
     PropsDisplayText(26)="Team based EXP for win"
     PropsDisplayText(27)="Ability Database"
     PropsDisplayText(28)="Weapon Modifier Database"
     PropsDisplayText(29)="Artifact Database"
     PropsDescText(0)="During the game, all data will be saved every this many seconds."
     PropsDescText(1)="New players start at this Level."
     PropsDescText(2)="The number of stat points earned from a levelup."
     PropsDescText(3)="Lower values = more exp when killing someone of higher level."
     PropsDescText(4)="The EXP gained for winning a match."
     PropsDescText(5)="If checked, bots' data is not saved and instead they are simply given a level near that of the human player(s)."
     PropsDescText(6)="Maximum number of turrets player can spawn with the turret launcher."
     PropsDescText(7)="Chance of any given weapon having magical properties."
     PropsDescText(8)="Monsters' level will be adjusted depends on this property."
     PropsDescText(9)="Maximum EXP gained for multikills/sprees."
     PropsDescText(10)="Invasion monsters will be adjusted based on this fraction of the weakest player's level."
     PropsDescText(11)="The maximum number of levelup particle effects that can be spawned on a character at once."
     PropsDescText(12)="Limit on how high stats can go. Values less than 0 mean no limit. The stats are: 1: Weapon Speed 2: Health Bonus 3: Max Adrenaline Bonus 4: Damage Bonus 5: Damage Reduction 6: Max Ammo Bonus"
     PropsDescText(13)="Allows you to make the EXP required for the next level always increase, no matter how high a level you get. This option is the value added."
     PropsDescText(14)="Change the EXP required for each level. Levels after the last in your list will use the last value in the list."
     PropsDescText(15)="Change the list of abilities players can choose from."
     PropsDescText(16)="If Fake Bot Levels is off, bots gain this many extra levels after a match because individual bots don't play often."
     PropsDescText(17)="If true, adrenaline pickups will be replaced with experience pickups."
     PropsDescText(18)="The magic weapons which will be used in the game."
     PropsDescText(19)="Validate all players' data at game start."
     PropsDescText(20)="List of ammo types which can't have infinity ammo and resupply."
     PropsDescText(21)="Time passed since player last joined server before data deleted (2600000 seconds - circa 1 month) 0 means never delete data."
     PropsDescText(22)="If true, killer doesn't gain exp for level difference, if killed was afk."
     PropsDescText(23)="Refresh the list of available weapons on the server. Useful, when upload new weaponpack cache (.ucl file)."
     PropsDescText(24)="Players get EXP for healing a teammate (only if teammate was damaged by an opponent)."
     PropsDescText(25)="This test method tries to prevent server from crash by infinite recursion in pawn's inventory chain. Set to 0, if don't want to use. If higher, than 0, means inventory chain break cycle. After every this number of inventories the system put a hacky item, that handle its chain piece. May cause some function incompatibility."
     PropsDescText(26)="Winner exp depends on how many times played in the winner team."
     PropsDescText(27)="It's a raw database of ability classes. You can choose available abilities from this list, so add classes from other packages, if you want that the system load them."
     PropsDescText(28)="It's a raw database of rpg weapon classes. You can choose available modifiers from this list, so add classes from other packages, if you want that the system load them."
     PropsDescText(29)="It's a raw database of artifact classes. It allows an easy access to the list of all known artifacts, so add classes from other packages, if you want that the system load them."
     stattypes="altadrenaline"
     resetstats="1"
     brefreshweaponlist=True
     bAddToServerPackages=True
     ConfigMenuClassName="mcgRPG1_9_9_1.RPGConfigMenu"
     GroupName="RPG"
     FriendlyName="mcgRPGv1.9.9.1"
     Description="UT2004 with a persistent experience level system, magic weapons, and artifacts. New version. 1.9.9.1"
     bAlwaysRelevant=True
     RemoteRole=ROLE_SimulatedProxy
     bNetNotify=True
}

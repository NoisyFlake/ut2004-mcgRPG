//RPGPlayerDataObject is used for saving player data. Using PerObjectConfig objects over arrays of structs is faster
//because native code can do the name search. Additionally, structs have a 1024 character limit when converted
//to text for .ini saving, which is not an issue for objects since they are not stored on one line.
class RPGPlayerDataObject extends Object
    config(mcgrpg)
	PerObjectConfig;

//Player name is the object name
var() config string OwnerID; //unique PlayerID of person who owns this name ("Bot" for bots)

var() config int Level, Experience, WeaponSpeed, HealthBonus, AdrenalineMax, Attack, Defense, AmmoMax,
	       PointsAvailable, NeededExp;
var() config float ExperienceFraction; // when player gets EXP less than a full point, it gets added up here until it's >= 1.0

var() config array<class<RPGAbility> > Abilities;
var() config array<string> Abilitynames;          //for compatibility with other mcgrpg versions (1.5c or higher)
var() config array<int> AbilityLevels;
var() config int StatCaps[6]; //same as in MutMCGRPG. If changed, player can rebuild stats.
//AI related
var() config class<RPGAbility> BotAbilityGoal; //Bot is saving points towards this ability
var() config int BotGoalAbilityCurrentLevel; //Bot's current level in the ability it wants (so don't have to search for it)

//This struct is used for the data when it needs to be replicated, since an Object cannot be
struct RPGPlayerData
{
	var int Level, Experience, WeaponSpeed, HealthBonus, AdrenalineMax;
	var int Attack, Defense, AmmoMax, PointsAvailable, NeededExp;
	var array<class<RPGAbility> > Abilities;
	var array<int> AbilityLevels;
};

var() config float ServerTime;

//adds a fractional amount of EXP
//the mutator and our owner's PRI are passed in for calling CheckLevelUp() if we've reached a whole number
function AddExperienceFraction(float Amount, MutMCGRPG RPGMut, PlayerReplicationInfo MessagePRI,optional int cap)
{
	ExperienceFraction += Amount;
	if (Abs(ExperienceFraction) >= 1.0)
	{
		Experience += int(ExperienceFraction);
		ExperienceFraction -= int(ExperienceFraction);
		RPGMut.CheckLevelUp(self, MessagePRI,cap);
	}
}

function CreateDataStruct(out RPGPlayerData Data, bool bOnlyEXP)
{
	Data.Level = Level;
	Data.Experience = Experience;
	Data.NeededExp = NeededExp;
	Data.PointsAvailable = PointsAvailable;
	if (bOnlyEXP)
		return;

	Data.WeaponSpeed = WeaponSpeed;
	Data.HealthBonus = HealthBonus;
	Data.AdrenalineMax = AdrenalineMax;
	Data.Attack = Attack;
	Data.Defense = Defense;
	Data.AmmoMax = AmmoMax;
	Data.Abilities = Abilities;
	Data.AbilityLevels = AbilityLevels;
}

function InitFromDataStruct(RPGPlayerData Data)
{
    local int i;
	Level = Data.Level;
	Experience = Data.Experience;
	NeededExp = Data.NeededExp;
	PointsAvailable = Data.PointsAvailable;
	WeaponSpeed = Data.WeaponSpeed;
	HealthBonus = Data.HealthBonus;
	AdrenalineMax = Data.AdrenalineMax;
	Attack = Data.Attack;
	Defense = Data.Defense;
	AmmoMax = Data.AmmoMax;
	Abilities = Data.Abilities;
	for(i=0;i<abilities.length;i++)
	    Abilitynames[i]=getitemname(string(abilities[i]) );
	AbilityLevels = Data.AbilityLevels;
}

function CopyDataFrom(RPGPlayerDataObject DataObject)
{
    local int i;
	OwnerID = DataObject.OwnerID;
	Level = DataObject.Level;
	Experience = DataObject.Experience;
	NeededExp = DataObject.NeededExp;
	PointsAvailable = DataObject.PointsAvailable;
	WeaponSpeed = DataObject.WeaponSpeed;
	HealthBonus = DataObject.HealthBonus;
	AdrenalineMax = DataObject.AdrenalineMax;
	Attack = DataObject.Attack;
	Defense = DataObject.Defense;
	AmmoMax = DataObject.AmmoMax;
	Abilities.Remove(0,Abilities.Length);
	AbilityLevels.Remove(0,AbilityLevels.Length);
	Abilitynames.Remove(0,Abilitynames.Length);
	Abilities.Insert(0,DataObject.Abilities.Length);
	AbilityLevels.Insert(0,DataObject.Abilities.Length);
	Abilitynames.Insert(0,DataObject.Abilities.Length);
	for(i = 0; i < DataObject.Abilities.Length; i++)
	{
	    Abilities[i] = DataObject.Abilities[i];
	    AbilityLevels[i] = DataObject.AbilityLevels[i];
	    Abilitynames[i] = Dataobject.Abilitynames[i];
	}
	BotAbilityGoal = DataObject.BotAbilityGoal;
	BotGoalAbilityCurrentLevel = DataObject.BotGoalAbilityCurrentLevel;
	ExperienceFraction = DataObject.ExperienceFraction;
	ServerTime = DataObject.ServerTime;
	for(i = 0; i < arraycount(statcaps); i++)
	    StatCaps[i] = Dataobject.StatCaps[i];
}

function Reset(RPGStatsInv StatsInv, MutMCGRPG RPGMut, optional bool bRebuild)
{
    local int i;

	WeaponSpeed = 0;
	HealthBonus = 0;
	AdrenalineMax = 0;
	Attack = 0;
	Defense = 0;
	AmmoMax = 0;
    Abilities.Remove(0, Abilities.Length);
    AbilityLevels.Remove(0, AbilityLevels.Length);
    Abilitynames.Remove(0, Abilitynames.Length);
	BotAbilityGoal = none;
	BotGoalAbilityCurrentLevel = 0;
	ServerTime = RPGMut.ServerTime;
	for(i = 0; i < arraycount(statcaps); i++)
	    StatCaps[i] = RPGMut.StatCaps[i];
	if(!bRebuild)
	{
	    Level = RPGMut.StartingLevel;
	    ExperienceFraction = 0.0;
	    Experience = 0;
	    if (RPGMut.Levels.length > Level)
	        NeededExp = RPGMut.Levels[Level];
	    else if (RPGMut.InfiniteReqEXPValue != 0)
            NeededExp = RPGMut.Levels[RPGMut.Levels.length - 1] + RPGMut.InfiniteReqEXPValue * (Level - (RPGMut.Levels.length - 1));
        else
	        NeededExp = RPGMut.Levels[RPGMut.Levels.length - 1];
    }
	PointsAvailable = RPGMut.PointsPerLevel * (Level - 1);
    statsinv.savedexperience=Experience;
    statsinv.savedlevel=Level;
    statsinv.savedpoints=PointsAvailable;
	saveconfig();
}

defaultproperties
{
}

//An ability a player can buy with stat points
//Abilities are handled similarly to DamageTypes and LocalMessages (abstract to avoid replication)
class RPGAbility extends info //fuck
	config(mcgRPG1991) abstract;

var() localized string AbilityName; //Shown in menus
var() localized string Description, copy; //Text shown when hit "Info" button for this ability
var() config int StartingCost, CostAddPerLevel, BotChance, MaxLevel;
var() localized string PropsDisplayText[3];
var() localized string PropsDescText[3];
var() bool bDefensive;  //important: if an ability may prevent death or reduce damage, need this value be true

/* Called by MutMCGRPG during its first tick. Return false to be removed from ability list (for example, if the
 * ability doesn't make sense with the current gametype)
 * Also gives the ability a chance to modify the game or the mutator (for example, if the ability depends on an
 * additional mutator, you could add it here)
 */
static function bool AbilityIsAllowed(GameInfo Game, MutMCGRPG RPGMut)
{
	return true;
}

static function fillplayinfo(playinfo playinfo)
{
    local int i;
    super.FillPlayInfo(playinfo);
    PlayInfo.AddSetting("Ability Config", "Startingcost", default.PropsDisplayText[i++], 1, 0, "Text", "5;0:20000");
    PlayInfo.AddSetting("Ability Config", "costaddperlevel", default.PropsDisplayText[i++], 1, 1, "Text", "5;0:20000");
    PlayInfo.AddSetting("Ability Config", "maxlevel", default.PropsDisplayText[i++], 1, 2, "Text", "5;0:20000");
}

static function string GetDescriptionText(string PropName)
{
	switch (PropName)
	{
		case "Startingcost":	return default.PropsDescText[0];
		case "costaddperlevel":	return default.PropsDescText[1];
		case "maxlevel":		return default.PropsDescText[2];
	}
}

/* The stat point cost to buy another level of this ability. Values less than 1 are interpreted to mean this ability cannot be currently bought
 * Do not reduce the cost of an ability based on the presence of other abilities - doing so will screw things up
 */
static function int Cost(RPGPlayerDataObject Data, int CurrentLevel)
{
	if (CurrentLevel < default.MaxLevel)
		return default.StartingCost + default.CostAddPerLevel * CurrentLevel;
	else
		return 0;
}

/* The chance a bot will buy this ability. You don't need to check for bots having enough points available -
 * if they don't, they'll automatically save up until they do.
 */
static function int BotBuyChance(Bot B, RPGPlayerDataObject Data, int CurrentLevel)
{
	if (static.Cost(Data, CurrentLevel) > 0)
		return default.BotChance;
	else
		return 0;
}

/* Modify the player's pawn. Called by MutMCGRPG.ModifyPlayer() on the server side, and by
 * RPGStatsInv.Tick() on the client side on the first tick after everything has replicated
 */
static function ModifyPawn(Pawn Other, int AbilityLevel, RPGStatsInv statsinv);

/* Modify the owning player's current weapon. Called by RPGStatsInv whenever the player's weapon changes.
 */
static function ModifyWeapon(Weapon Weapon, int AbilityLevel);

/* Modify the owning player's current vehicle. Called by MutMCGRPG.DriverEnteredVehicle() serverside
 * and RPGStatsInv.ClientEnteredVehicle() clientside.
 */
static function ModifyVehicle(Vehicle V, int AbilityLevel);

/* Remove any modifications to this vehicle, because the player is no longer driving it.
 */
static function UnModifyVehicle(Vehicle V, int AbilityLevel);

/* React to damage about to be done to the injured player's pawn. Called by RPGRules.NetDamage()
 * Note that this is called AFTER the damage has been affected by Damage Bonus/Damage Reduction.
 * Also note that for any damage this is called on the abilities of both players involved.
 * Use bOwnedByInstigator to determine which pawn is the owner of this ability.
 */
static function HandleDamage(out int Damage, Pawn Injured, Pawn Instigator, out vector Momentum, class<DamageType> DamageType, bool bOwnedByInstigator, int AbilityLevel, rpgstatsinv statsinv);

/* React to a kill. Called by RPGRules.ScoreKill()
 */
static function ScoreKill(Controller Killer, Controller Killed, bool bOwnedByKiller, int AbilityLevel);

/* If this returns true, prevent Killed's death. Called by RPGRules.PreventDeath()
 * NOTE: If a GameRules before RPGRules prevents the death, this probably won't get called
 * bAlreadyPrevented will be true if a GameRules AFTER RPGRules, or an ability, has already prevented the death.
 * If bAlreadyPrevented is true, the return value of this function is ignored. This is called anyway so you have the
 * opportunity to prevent stacking of death preventing abilities (for example, by putting a marker inventory on Killed
 * so next time you know not to prevent his death again because it was already prevented once)
 */
static function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> DamageType, vector HitLocation, int AbilityLevel, bool bAlreadyPrevented)
{
	return false;
}

/* If this returns true, prevent boneName from being severed from Killed. You should return true here anytime you will be
 * returning true to PreventDeath(), above, as otherwise you will have live pawns running around with no head and other
 * amusing but gameplay-damaging phenomenon.
 */
static function bool PreventSever(Pawn Killed, name boneName, int Damage, class<DamageType> DamageType, int AbilityLevel)
{
	return false;
}

/* Called by RPGRules.OverridePickupQuery() and works exactly like that function - if this returns true,
 * bAllowPickup determines if item can be picked up (1 is yes, any other value is no)
 * NOTE: The first function to return true prevents all further abilities in the player's ability list
 * from getting this call on that particular Pickup. Therefore, to maintain maximum compatibility,
 * return true only if you're actually overriding the normal behavior.
 */
static function bool OverridePickupQuery(Pawn Other, Pickup item, out byte bAllowPickup, int AbilityLevel)
{
	return false;
}

static function string getinfo()
{
    local int j;
    local string s;
    if(default.copy != "")
        return default.copy;
    for(j = 1; j < default.MaxLevel + 1; j++)
    {
        if(j < default.MaxLevel)
            s $= string(default.StartingCost + (j - 1) * default.CostAddPerLevel) $", ";
        else s $= string(default.StartingCost + (j - 1) * default.CostAddPerLevel);
    }
    default.copy = repl( repl(repl(default.Description,"%maxlevel%",default.maxlevel),"%startingcost%",default.startingcost),"%costs%",s );
    return default.copy;
}

//to recover player's stats, if disconnected (example by net problem, or game crash etc.)
static function PlayerExited(playercontroller pc, pawn p, int level)
{
}

static function PlayerEntered(playercontroller p, string n, int level)
{
}

defaultproperties
{
     BotChance=5
     PropsDisplayText(0)="Starting cost"
     PropsDisplayText(1)="Cost increment"
     PropsDisplayText(2)="Maximum level"
     PropsDescText(0)="Cost of the first level of this ability."
     PropsDescText(1)="Costs increment with this value on higher ability level."
     PropsDescText(2)="Maximum level of this ability may buy."
}

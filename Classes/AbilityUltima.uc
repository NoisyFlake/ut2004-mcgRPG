class abilityUltima extends RPGAbility
	abstract;


var() config int level2cost,level3cost,level4cost;
var() localized string uDisplayText[3];
var() localized string uDescText[3];

static simulated function int Cost(RPGPlayerDataObject Data, int CurrentLevel)
{
	if (Data.Attack < 150 || currentlevel >= default.maxlevel)
		return 0;

    if(currentlevel==0)
	    return default.startingcost;
	else  if(currentlevel==1)
	    return default.level2cost;
	else  if(currentlevel==2)
	    return default.level3cost;
	else  if(currentlevel==3)
	    return default.level4cost;
	return super.Cost(data,currentlevel);
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
        {
            if(j == 1 || j > 4)
                s $= string(default.StartingCost + (j - 1) * default.CostAddPerLevel) $", ";
            else if(j == 2)
                s $= string(default.level2cost) $", ";
            else if(j == 3)
                s $= string(default.level3cost) $", ";
            else if(j == 4)
                s $= string(default.level4cost) $", ";
        }
        else
        {
            if(j == 1 || j > 4)
                s $= string(default.StartingCost + (j - 1) * default.CostAddPerLevel);
            else if(j == 2)
                s $= string(default.level2cost);
            else if(j == 3)
                s $= string(default.level3cost);
            else if(j == 4)
                s $= string(default.level4cost);
        }
    }
    default.copy = repl( repl(repl(default.Description,"%maxlevel%",default.maxlevel),"%startingcost%",default.startingcost),"%costs%",s );
    return default.copy;
}

static function string GetDescriptionText(string PropName)
{
	switch (PropName)
	{
		case "level2cost":		return default.uDescText[0];
		case "level3cost":		return default.uDescText[1];
		case "level4cost":		return default.uDescText[2];
		default: return super.GetDescriptionText(propname);
	}
}

static function fillplayinfo(playinfo playinfo)
{
    local int j;
    super.FillPlayInfo(playinfo);
    PlayInfo.AddSetting("Ability Config", "level2cost", default.uDisplayText[j++], 1, 3, "Text", "3;1:999");
    PlayInfo.AddSetting("Ability Config", "level3cost", default.uDisplayText[j++], 1, 4, "Text", "3;1:999");
    PlayInfo.AddSetting("Ability Config", "level4cost", default.uDisplayText[j++], 1, 5, "Text", "3;1:999");
}

static function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> DamageType, vector HitLocation, int AbilityLevel, bool bAlreadyPrevented)
{
    local controller c;
    local inventory inv;
    local pawn killedpawn;
    local killmarker k;
    c=killed.Controller;
    if(c==none && killed.DrivenVehicle!=none)
        c=killed.DrivenVehicle.Controller;
    if(c==none && vehicle(killed.Owner)!=none)
        c=vehicle(killed.Owner).Controller;
    if(c==none && vehicle(killed.Owner)!=none )
        c=controller(killed.Owner.Owner);
    if(c==none)
        c=controller(killed.Owner);
	if (!bAlreadyPrevented )
	{
        if(abilitylevel < 4)
        {
	        if(vehicle(killed)!=none && vehicle(killed).driver!=none )
	            killedpawn=vehicle(killed).driver;
            else killedpawn=killed;
	        k=killmarker(Killedpawn.FindInventoryType(class'killmarker') );
            if(  k!= None )
            {
                k.Destroy();
                if(Killed.Location.Z > Killed.Region.Zone.KillZ)
		            Killed.spawn(class'ultimaCharger', c).ChargeTime = 8.0 / ( 2.0**float(AbilityLevel) );
	        }
	    }
	    else if( c!=none)
	    {
	        for(inv = c.Inventory; inv != none; inv = inv.Inventory)
	        {
	            k = killmarker(inv);
	            if(k != none)
	            {
	                k.Destroy();
	                if(Killed.Location.Z > Killed.Region.Zone.KillZ)
	                    Killed.spawn(class'ultimaCharger', c).ChargeTime = 0.5;
                    break;
                }
	        }
        }
    }
    return false;
}

static function ScoreKill(Controller Killer, Controller Killed, bool bOwnedByKiller, int AbilityLevel)
{
    local inventory inv;
    local pawn killerpawn;

	if( !bOwnedByKiller )
	    return;
	if ( abilitylevel < 4 && Killer.Pawn != None && !Killer.Pawn.bPendingDelete && (Killed.Pawn == None ||
        Killed.Pawn.HitDamageType != class'damtypeUltima' ) )
    {
        if(vehicle(killer.pawn)!=none)
            killerpawn=vehicle(killer.Pawn).Driver;
        else if(redeemerwarhead(killer.Pawn)!=none)
	        killerpawn=redeemerwarhead(Killer.Pawn).OldPawn;
        else
            killerpawn=killer.Pawn;
        if( killerpawn!=none && KillerPawn.FindInventoryType(class'killmarker') == None )
		    Killer.Pawn.spawn(class'killmarker', KillerPawn).GiveTo(KillerPawn);
    }
	else if(abilitylevel == 4)
	{
	    for(inv = killer.Inventory;inv != none;inv=inv.Inventory)
            if(killmarker(inv)!=none)
                return;
	    inv = killer.Inventory;
	    killer.Inventory = killer.Spawn(class'killmarker',killer);
	    if(killer.Inventory != none)
            killer.Inventory.Inventory = inv;
        else
        {
            killer.Inventory = inv;
            log("killmarker destroyed inexplicably");
        }
    }
}

defaultproperties
{
     Level2Cost=50
     Level3Cost=70
     level4cost=150
     uDisplayText(0)="Level 2 cost"
     uDisplayText(1)="Level 3 cost"
     uDisplayText(2)="Level 4 cost"
     uDescText(0)="Cost of 2. level."
     uDescText(1)="Cost of 3. level."
     uDescText(2)="Cost of 4. level."
     AbilityName="Ultima"
     Description="This ability causes your body to release energy when you die. The energy will collect at a single point which will then cause a Redeemer-like nuclear explosion. | Level 2 of this ability causes the energy to collect for the explosion in half the time, level 3 in quarter the time,  level 4 in eighth the time. The ability will only trigger if you have killed at least one enemy during your life. | Level 4 activated by ultima kills too. | You need to have a Damage Bonus stat of at least 150 to purchase this ability.  (Max Level: %maxlevel% , cost (per level): %costs% )"
     StartingCost=30
     MaxLevel=4
     PropsDescText(1)="Costs increment with this value above 4. level."
}

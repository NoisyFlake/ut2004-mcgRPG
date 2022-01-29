class abilityCounterShove extends RPGAbility
	abstract;

var() config float mult,maxmult;
var() localized string csDisplayText[2];
var() localized string csDescText[2];

static simulated function int Cost(RPGPlayerDataObject Data, int CurrentLevel)
{
	if (Data.Defense < 100)
		return 0;
	else
		return Super.Cost(Data, CurrentLevel);
}

static function fillplayinfo(playinfo playinfo)
{
    local int i;
    super.FillPlayInfo(playinfo);
    PlayInfo.AddSetting("Ability Config", "mult", default.csDisplayText[i++], 1, 3, "Text", "4;1:999");
    PlayInfo.AddSetting("Ability Config", "maxmult", default.csDisplayText[i++], 1, 4, "Text", "4;1:999");
}

static function string GetDescriptionText(string PropName)
{
	switch (PropName)
	{
		case "mult":	return default.csDescText[0];
		case "maxmult":		return default.csDescText[1];
		default: return super.GetDescriptionText(propname);
	}
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
    default.copy = repl(repl(repl( repl(repl(default.Description,"%maxlevel%",default.maxlevel),"%startingcost%",default.startingcost),"%costs%",s ),
        "%mult%",string(int(default.mult * 100.0) ) $ "%" ),"%maxmult%",string(int(default.maxmult * 100.0) ) $ "%" );
    return default.copy;
}

static function HandleDamage(out int Damage, Pawn Injured, Pawn Instigator, out vector Momentum, class<DamageType> DamageType, bool bOwnedByInstigator, int AbilityLevel, rpgstatsinv statsinv)
{
	local float MomentumMod;
	local int i;

	if (bOwnedByInstigator || DamageType == class'damtypeRetaliation' || Injured == Instigator || Instigator == None)
		return;

	//negative values to reverse direction
	if (AbilityLevel < default.MaxLevel || default.maxmult <=0 )
		MomentumMod = - default.mult*AbilityLevel;
	else
		MomentumMod = -default.maxmult;
    if(vehicle(instigator)!=none && vehicle(instigator).MomentumMult<4)
        momentummod*=4 / vehicle(instigator).MomentumMult;
    if(statsinv!=none && statsinv.DataObject!=none)
    {
        for(i=0;i< statsinv.DataObject.Abilities.Length;i++)
        {
            if( statsinv.DataObject.Abilities[i] == class'abilitycountershove' )
                break;
            if( statsinv.DataObject.Abilities[i] == class'abilityreducemomentum' )
            {
                momentummod /= (1-0.15*statsinv.DataObject.AbilityLevels[i]);
                break;
            }
        }
    }
    if(vehicle(injured)==none || onsweaponpawn(injured)!=none )
        Instigator.TakeDamage(0, Injured, Instigator.Location, (Momentum * Injured.Mass) * MomentumMod, class'damtypeRetaliation');
    else
        Instigator.TakeDamage(0, Injured, Instigator.Location, 4 * Momentum * MomentumMod / fmin(4.0, vehicle(injured).MomentumMult), class'damtypeRetaliation');
}

defaultproperties
{
     mult=1.000000
     maxmult=7.500000
     csDisplayText(0)="Momentum multiplier"
     csDisplayText(1)="Max momentum multiplier"
     csDescText(0)="The ability multiple the momentum with this value per level."
     csDescText(1)="Momentum multiplier at maximum ability level. Set 0 to no different increase at max level."
     AbilityName="CounterShove"
     Description="Whenever you are damaged by another player, the  %mult% of momentum multipied level (or %maxmult% at level %maxlevel%) is also done to the player who hurt you. Will not CounterShove a CounterShove. You must have a Damage Reduction of at least 100 to purchase this ability. (Max Level: %maxlevel% , cost (per level): %costs% )"
     StartingCost=50
     CostAddPerLevel=5
     MaxLevel=5
}

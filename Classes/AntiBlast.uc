class AntiBlast extends rpgability;

var() config array<name> customignoreddamages;
var() array<string> ignoreddamages;
var() localized string aDisplayText;
var() localized string aDescText;

static simulated function int Cost(RPGPlayerDataObject Data, int CurrentLevel)
{
	if (Data.Defense < 150)
		return 0;
	else
		return Super.Cost(Data, CurrentLevel);
}

static function string GetDescriptionText(string PropName)
{
	switch (PropName)
	{
		case "customignoreddamages":		return default.aDescText;
		default: return super.GetDescriptionText(propname);
	}
}

static function fillplayinfo(playinfo playinfo)
{
    super.FillPlayInfo(playinfo);
    PlayInfo.AddSetting("Ability Config", "customignoreddamages",default.aDisplayText, 0, 3, "text","128",,,True);
}

static function HandleDamage(out int Damage, Pawn Injured, Pawn Instigator, out vector Momentum, class<DamageType> DamageType, bool bOwnedByInstigator, int AbilityLevel, rpgstatsinv statsinv)
{
    local int i;
	if (bOwnedByInstigator)
		return;
	if (DamageType == class'damtypeultima' )
	{
	    damage=0;
	    momentum=vect(0,0,0);
	    return;
	}
	if(abilitylevel < 2 )
	    return;
    if( DamageType.default.bSuperWeapon)
    {
        damage=0;
        momentum=vect(0,0,0);
        return;
    }
    for(i=0;i < default.ignoreddamages.Length;i++)
    {
        if(getitemname( string(damagetype) ) ~= default.ignoreddamages[i] )
   	    {
	        damage=0;
	        momentum=vect(0,0,0);
	        return;
	    }
    }
	if(default.customignoreddamages.Length == 0)
	    return;
    for(i=0;i< default.customignoreddamages.Length;i++)
    {
        if(getitemname( string(damagetype) ) ~= string(default.customignoreddamages[i]) )
   	    {
	        damage=0;
	        momentum=vect(0,0,0);
	        return;
	    }
    }
}

defaultproperties
{
     ignoreddamages(0)="KamikazeDeath"
     ignoreddamages(1)="DamTypeMASCannon"
     ignoreddamages(2)="DamTypeIonCannonBlast"
     ignoreddamages(3)="DamTypeIonTankBlast"
     aDisplayText="Ignored damage type list."
     aDescText="This is the list of the damage types, second level of ability defends from. | (no need add super weapon damages, leviathan, iontank, ioncannon explosion and kamikaze combo blast, these are default ignored)"
     AbilityName="Anti Blast"
     Description="First level of this ability defends you from ultima explosion. Second level defends you from all superexplosive damage. You must have 150 damage reduction to get this skill. (Max Level: %maxlevel% , cost (per level): %costs% )"
     StartingCost=400
     CostAddPerLevel=600
     MaxLevel=2
     bDefensive=True
}

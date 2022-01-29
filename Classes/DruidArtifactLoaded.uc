class DruidArtifactLoaded extends LoadAbility
 config(mcgRPG1991)
	abstract;

var() config array< class<RPGArtifact> > SlowArtifact;
var() config array< class<RPGArtifact> > QuickArtifact;
var() config int Level2Cost, Level3Cost;
var() localized string dDisplayText[4];
var() localized string dDescText[4];
var() byte MaxTurrets;


static function int Cost(RPGPlayerDataObject Data, int CurrentLevel)
{
	local int x;
	local bool foundAResupply, foundAVamp, foundARegen;
	foundAResupply = false;
	foundAVamp = false;
	foundARegen = false;

	for (x = 0; x < Data.Abilities.length; x++)
	{
		if (Data.Abilities[x] == class'abilityAdrenalineSurge')
			foundAResupply = true;
		if (Data.Abilities[x] == class'energyvampire')
			foundAVamp = true;
		if (Data.Abilities[x] == class'DruidAdrenalineRegen' )
			foundARegen = true;
	}
	if(!foundAResupply || !foundAVamp || !foundARegen || currentlevel>=default.maxlevel)
		return 0;

	if(CurrentLevel == 0)
		return default.startingCost;
	if(CurrentLevel == 1)
		return default.Level2Cost;
	if(CurrentLevel == 2)
        return default.Level3Cost;
    return 0;
}

static function RealModifyPawn(Pawn Other, int AbilityLevel, rpgstatsinv statsinv, skillinv inv)
{
	local int x;

    if(other.level.Game.bGameEnded  || (statsinv.RPGMut != none && statsinv.RPGMut.cancheat) )
        abilitylevel = 3;

	for(x = 0; x < default.SlowArtifact.length; x++)
		giveArtifact(other, default.SlowArtifact[x]);

	if(AbilityLevel > 1)
		for(x = 0; x < default.QuickArtifact.length; x++)
			giveArtifact(other, default.QuickArtifact[x]);
	if(AbilityLevel > 2)
	    giveArtifact(other, Class'mcgRPG1_9_9_1.TurretLauncher');
    other.SelectedItem = rpgartifact(other.FindInventoryType(statsinv.selected) );
    if(other.SelectedItem == none)
	    Other.NextItem();
}

static function fillplayinfo(playinfo playinfo)
{
    local int i,j;
    super(info).FillPlayInfo(playinfo);
    PlayInfo.AddSetting("Ability Config", "Startingcost", default.PropsDisplayText[i], 1, 0, "Text", "3;1:999");
    i += 2;
    PlayInfo.AddSetting("Ability Config", "maxlevel", default.PropsDisplayText[i], 1, 1, "Text", "3;1:999");
    PlayInfo.AddSetting("Ability Config", "level2cost", default.dDisplayText[j++], 1, 2, "Text", "3;1:999");
    PlayInfo.AddSetting("Ability Config", "level3cost", default.dDisplayText[j++], 1, 3, "Text", "3;1:999");
	PlayInfo.AddSetting("Ability Config", "SlowArtifact", default.dDisplayText[j++], 1, 4, "Select", class'MutMCGRPG'.default.ArtifactOptions,,, true);
	PlayInfo.AddSetting("Ability Config", "QuickArtifact", default.dDisplayText[j++], 1, 5, "Select",class'MutMCGRPG'.default.ArtifactOptions,,, true);
}

static function string GetDescriptionText(string PropName)
{
	switch (PropName)
	{
		case "level2cost":		return default.dDescText[0];
		case "level3cost":		return default.dDescText[1];
		case "SlowArtifact":		return default.dDescText[2];
		case "QuickArtifact":		return default.dDescText[3];
		default: return super.GetDescriptionText(propname);
	}
}

static function giveArtifact(Pawn other, class<RPGArtifact> ArtifactClass)
{
	local RPGArtifact Artifact;

	if( artifactclass.static.artifactisallowed(other.Level.game) )
	    Artifact = Other.spawn(ArtifactClass, Other,,, rot(0,0,0));
	if(Artifact != None)
		Artifact.giveTo(Other);
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
            if(j == 1 || j > 3)
                s $= string(default.StartingCost + (j - 1) * default.CostAddPerLevel) $", ";
            else if(j == 2)
                s $= string(default.level2cost) $", ";
            else if(j == 3)
                s $= string(default.level3cost) $", ";
        }
        else
        {
            if(j == 1 || j > 3)
                s $= string(default.StartingCost + (j - 1) * default.CostAddPerLevel);
            else if(j == 2)
                s $= string(default.level2cost);
            else if(j == 3)
                s $= string(default.level3cost);
        }
    }
    default.copy = repl( repl(repl(default.Description,"%maxlevel%",default.maxlevel),"%startingcost%",default.startingcost),"%costs%",s );
    return default.copy;
}

defaultproperties
{
     SlowArtifact(0)=Class'mcgRPG1_9_9_1.ArtifactFlight'
     SlowArtifact(1)=Class'mcgRPG1_9_9_1.ArtifactTeleport'
     QuickArtifact(0)=Class'mcgRPG1_9_9_1.ArtifactTripleDamage'
     QuickArtifact(1)=Class'mcgRPG1_9_9_1.ArtifactLightningRod'
     QuickArtifact(2)=Class'mcgRPG1_9_9_1.DruidDoubleModifier'
     QuickArtifact(3)=Class'mcgRPG1_9_9_1.DruidMaxModifier'
     QuickArtifact(4)=Class'mcgRPG1_9_9_1.ArtifactMagicMaker'
     Level2Cost=40
     Level3Cost=150
     dDisplayText(0)="Level 2 cost"
     dDisplayText(1)="Level 3 cost"
     dDisplayText(2)="Slow artifacts"
     dDisplayText(3)="Quick artifacts"
     dDescText(0)="Cost of 2. level."
     dDescText(1)="Cost of 3. level."
     dDescText(2)="Slow artifacts given on 1. level."
     dDescText(3)="Quick artifacts given on 2. level."
     Index=1
     InventoryType=Class'mcgRPG1_9_9_1.ArtifactLoadedInv'
     bMultiply=False
     AbilityName="Loaded Artifacts"
     Description="When you spawn:|Level 1: You are granted all slow drain artifacts.|Level 2: You are granted all artifacts, excepting the turret launcher.|Level 3: You are granted the turret launcher too. | You must have the Adrenal Drip, Adrenal Surge, and Energy Leech abilities before purchasing this ability.|(Max Level: %maxlevel% , cost (per level): %costs% )"
     StartingCost=20
     MaxLevel=3
}

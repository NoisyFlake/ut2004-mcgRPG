class AbilityAwareness extends RPGAbility
	abstract;

static simulated function int Cost(RPGPlayerDataObject Data, int CurrentLevel)
{
	if ( Data.WeaponSpeed < 5 || Data.HealthBonus < 5 || Data.AdrenalineMax < 5
	     || Data.Attack < 5 || Data.Defense < 5 || Data.AmmoMax < 5)
		return 0;
	else
		return Super.Cost(Data, CurrentLevel);
}

static function ModifyPawn(Pawn Other, int AbilityLevel, RPGStatsInv statsinv)
{
	local PlayerController PC;
	local int x;
	local awarenessInteraction I;

	if (Other.Level.NetMode == NM_DedicatedServer)
		return;

	PC = other.Level.GetLocalPlayerController();
	if (PC == None)
		return;

	for (x = 0; x < PC.Player.LocalInteractions.length; x++)
		if (awarenessInteraction(PC.Player.LocalInteractions[x]) != None)
		{
			I = awarenessInteraction(PC.Player.LocalInteractions[x]);
			break;
		}
	if (I == None)
		I = awarenessInteraction(PC.Player.InteractionMaster.AddInteraction("mcgRPG1_9_9_1.awarenessInteraction", PC.Player));
	I.AbilityLevel = AbilityLevel;
}

defaultproperties
{
     AbilityName="Awareness"
     Description="Informs you of your enemies' health with a display over their heads. At level 1 you get a colored indicator (green, yellow, or red). At level 2 you get a colored health bar and a shield bar. You need to have at least 5 points in every stat to purchase this ability. (Max Level: %maxlevel% , cost (per level): %costs% )"
     StartingCost=20
     CostAddPerLevel=5
     BotChance=0
     MaxLevel=2
}

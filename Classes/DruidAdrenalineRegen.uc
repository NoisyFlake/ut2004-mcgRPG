class DruidAdrenalineRegen extends LoadAbility
    config(mcgRPG1991)
	abstract;


static simulated function int Cost(RPGPlayerDataObject Data, int CurrentLevel)
{
	if (Data.AdrenalineMax < 25 * (CurrentLevel + 1))
		return 0;
    return super.Cost( Data, CurrentLevel);
}

static simulated function RealModifyPawn(Pawn Other, int AbilityLevel, rpgstatsinv statsinv, skillinv inv)
{
	local DruidAdrenRegenInv R;

	R = DruidAdrenRegenInv(inv);
	r.adrenaline = statsinv.adrenaline; //lol what a naive idea, that i thought, i add regenamount adrenaline per seconds, but i again failed by a nice epic bug, that calls a function with float arguments, but integer return value.
	statsinv.adrenaline = 0.0;
    r.RegenAmount = r.default.RegenAmount * float(AbilityLevel) / 5.0;
    R.SetTimer( 1.0, true);
}

defaultproperties
{
     Index=2
     InventoryType=Class'mcgRPG1_9_9_1.DruidAdrenRegenInv'
     AbilityName="Adrenal Drip"
     Description="Slowly drips adrenaline into your system.| You get 1 adrenaline per level in every 5 seconds. |You must spend 25 points in your Adrenaline Max stat for each level of this ability you want to purchase. (Max Level: %maxlevel%, Cost (per level): %costs%.)"
     StartingCost=5
     CostAddPerLevel=5
     MaxLevel=10
}

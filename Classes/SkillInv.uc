class SkillInv extends Inventory
	abstract config(mcgRPG1991);
//base class for inventories made by abilities (regen, loaded, etc.) Stored in rpgstatsinv instead of add to inventory chain.

var() rpgstatsinv myowner;
var() Controller InstigatorController;

function destroyed()
{
}

function giveto(pawn other, optional pickup p)
{
}

defaultproperties
{
}

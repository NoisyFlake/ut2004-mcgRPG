class LoadAbility extends RPGAbility abstract;
//Base class for abilities adding a marker inventory to the owner.
//That inventory stored in a static array in rpgstatsinv instead of add to inventory chain.
//Index determines its position in that array, so don't forget to set an index different from other ones index, if you make a subclass.
//It contains a new function, what do the effective operation. This function called from modifiypawn, if conditions come true.
//Put the real modification of pawn to there instead of modifypawn. Inventorytype is the type of marker inventory added to the pawn.
//Don't forget call of the superclass enabled function, if you overwrite it.

var() int index;
var() class<skillinv> InventoryType;
var() bool bMultiply;

static function ModifyPawn(Pawn Other, int AbilityLevel, rpgstatsinv statsinv)
{
    local skillinv inv;
    if( Enabled( Other, AbilityLevel, default.index, inv, statsinv) )
        RealModifyPawn( Other, AbilityLevel, statsinv, inv);
}

static function bool Enabled(Pawn Other, int AbilityLevel, int i, out skillinv inv, rpgstatsinv statsinv)
{
    if( other == none || other.Level.NetMode == nm_client || other.Health <= 0 || other.IsA('vehicle') || default.inventorytype == none ||
        i < 0 || i > 255 || statsinv == none )
        return false;
    inv = statsinv.GetOwnerInv(i);
    if( inv != none && inv.Class == default.inventorytype)
        return default.bMultiply;
    inv = other.Spawn(default.inventorytype,other);
    if(inv == none)
        return false;
    statsinv.SetOwnerInv(i, inv);  //lol variable too large, 255 byte max :PPPP
    inv.myowner = statsinv;
    inv.InstigatorController = statsinv.OwnerC;
    return true;
}

static function RealModifyPawn(Pawn Other, int AbilityLevel, RPGStatsInv statsinv, SkillInv inv);

defaultproperties
{
     Index=-1
     bMultiply=True
}

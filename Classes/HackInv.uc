class HackInv extends inventory;

var() saveinv myowner;
var() bool bCalled;

replication
{
    reliable if(role == role_authority)
        clientgetowner;
    reliable if(role < role_authority)
        serverrequestowner;
}

simulated function postnetbeginplay()
{
    if(role < role_authority)
        initialize();
}

simulated function initialize()
{
    local playercontroller pc;
    local xpawn p;

    instigator = pawn(owner);
    if(instigator == none)
    {
        pc = level.GetLocalPlayerController();
        if(vehicle(pc.Pawn) != none)
            instigator = vehicle(pc.Pawn).Driver;
        else if(redeemerwarhead(pc.Pawn) != none)
            instigator = redeemerwarhead(pc.Pawn).OldPawn;
        else instigator = pc.Pawn;
        if(instigator == none)
        {
            foreach dynamicactors(class'xpawn',p)
                if(p.Role == role_autonomousproxy || p.Weapon != none || p.Inventory != none || p.Owner == pc)
                {
                    instigator = p;
                    break;
                }
            if(instigator == none)
            {
                serverrequestowner();
                return;
            }
        }
    }
    myowner = saveinv(instigator.FindInventoryType(class'saveinv') );
    if(myowner == none)
        serverrequestowner();
}

function serverrequestowner()
{
    clientgetowner(myowner);
}

simulated function clientgetowner(saveinv i)
{
    myowner = i;
}

function AttachToPawn(Pawn P)
{
}

exec function updaterelative(int pitch, int yaw, int roll)
{
}

function DetachFromPawn(Pawn P)
{
}

simulated function RenderOverlays( canvas Canvas )
{
}

function bool HandlePickupQuery( pickup Item )
{
    bCalled = true;
    return false;
}

function Powerups SelectNext()
{
    return myowner.SelectNext();
}

simulated function Weapon WeaponChange( byte F, bool bSilent )
{
    if(myowner == none)
        initialize();
    if(myowner == none)
        return none;
    else return myowner.WeaponChange(f,false);
}

function DropFrom(vector StartLocation)
{
}

defaultproperties
{
}

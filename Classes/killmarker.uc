//Indicates that this pawn has killed at least one enemy
class killmarker extends Inventory;

function DropFrom(vector StartLocation)
{
	Destroy();
}

function destroyed()
{
    local actor a;
    if(controller(owner) != none)
    {
        for(a = owner; a != none; a = a.Inventory)
            if(a.Inventory == self)
            {
                a.Inventory = inventory;
                inventory = none;
                break;
            }
    }
    else super.Destroyed();
}

function reset()
{
	Destroy();
}

defaultproperties
{
     RemoteRole=ROLE_DumbProxy
     bGameRelevant=True
}

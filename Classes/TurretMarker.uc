class TurretMarker extends inventory;

var() controller instigatorcontroller;
var() rpgturretcontroller basecontroller;
var() bool bAdded,bunlocked;

function Destroyed()
{
    local turretmarker t;
    if(instigator != none && !instigator.bPendingDelete && instigator.Health > 0 && !level.Game.bGameEnded &&
        !level.Game.bGameRestarted && bAdded)
    {
        t = instigator.spawn(class);
        log("Warning: TurretMarker destroyed. Spawned new one: "$t);
    }
    if(t!=none)
    {
        t.instigatorcontroller=instigatorcontroller;
        t.bunlocked = bunlocked;
        if(basecontroller != none && !basecontroller.bPendingDelete)
        {
            t.basecontroller=basecontroller;
            basecontroller.mymarker = t;
        }
    }
    super.Destroyed();
}

function giveto(pawn p,optional pickup pu)
{
    bAdded = true;
    super.GiveTo(p,pu);
}

function tick(float d)
{
    if(!bAdded)
        giveto(instigator);
    if(basecontroller == none || basecontroller.bPendingDelete)
    {
        basecontroller=rpgturretcontroller(pawn(owner).controller);
        if(basecontroller != none)
            basecontroller.mymarker = self;
    }
}

defaultproperties
{
     RemoteRole=ROLE_None
}

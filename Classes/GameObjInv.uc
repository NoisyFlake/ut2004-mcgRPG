class GameObjInv extends inventory;

var() gameobject myflag;

replication
{
    reliable if(role==role_authority)
        myflag;
}

function postbeginplay()
{
    super.PostBeginPlay();
    enable('tick');
}

function tick(float dt)
{
    if(myflag==none || myflag.bPendingDelete)
    {
        destroy();
        return;
    }
    if(myflag.Base==none || myflag.Base.bWorldGeometry)
        setlocation(myflag.Location);
    else setlocation(myflag.Base.Location + myflag.RelativeLocation);
}

defaultproperties
{
     bOnlyOwnerSee=False
     bOnlyRelevantToOwner=False
     bAlwaysRelevant=True
     bReplicateMovement=True
     bOnlyDirtyReplication=False
     RemoteRole=ROLE_DumbProxy
     bGameRelevant=True
}

class mutrpgashud extends mutator;


function PostBeginPlay()
{
	Super.PostBeginPlay();
	if(level.game.HUDType~="UT2k4Assault.HUD_Assault" )
	    level.Game.HUDType="mcgRPG1_9_9_1.rpgashud";
    else destroy();
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	if(gameobject(other)!=none )
        if( level.NetMode!=nm_standalone)
            spawn(class'gameobjinv').myflag=gameobject(other);
    return true;
}

defaultproperties
{
     FriendlyName="RPG Assault HUD (1.9.9)"
     Description="Modified HUD for Assault to draw adrenaline."
}

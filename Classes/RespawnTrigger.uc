class RespawnTrigger extends Tool;

var() Trigger_ASForceTeamRespawn dunk;

function Trigger(Actor a, Pawn i)
{
	local Controller C;
	local Pawn p;

	if ( Role < Role_Authority || !Level.Game.IsA('ASGameInfo') || dunk == none)
		return;

    for ( C = Level.ControllerList; C != None; C = C.NextController )
		if ( (C.PlayerReplicationInfo != None) && !C.PlayerReplicationInfo.bOnlySpectator )
    	{
			if ( Vehicle(C.Pawn) != None )
				Vehicle(C.Pawn).KDriverLeave( true );

			if ( C.Pawn != None && C.Pawn.Weapon == None )
			{
			    p = c.Pawn;
                if(p.IsLocallyControlled() )
                {
                    if(p.PendingWeapon == none)
                        c.SwitchToBestWeapon();
                    else
                        p.ServerChangedWeapon(none,p.PendingWeapon);
                }
                else
                {
                    p.weapon = weapon(p.FindInventoryType(class'weapon') );
                    c.ClientSwitchToBestWeapon();
                }
                if(p.Weapon == none && unrealpawn(p) != none && p.Controller != none && p.Health > 0)
                    unrealpawn(p).AddDefaultInventory();
                if(p.Weapon == none )
                    p.weapon = weapon(p.FindInventoryType(class'weapon') );
			}
     	}
  	dunk.Trigger(a,i);
}

defaultproperties
{
}

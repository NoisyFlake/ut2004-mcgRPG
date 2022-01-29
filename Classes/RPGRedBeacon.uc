//=============================================================================
// Translocator Beacon for rpgweapons handle translocator
//=============================================================================
class RPGRedBeacon extends RedBeacon;

State MonitoringThrow
{
	function BotTranslocate()
	{
	    local weapon w;
	    w = Instigator.Weapon;
	    if(rpgweapon(w) != none)
	        w = rpgweapon(w).ModifiedWeapon;
		if ( TransLauncher(w) != None && w.GetFireMode(1) != none)
			w.GetFireMode(1).DoFireEffect();
		EndMonitoring();
	}
}

defaultproperties
{
}

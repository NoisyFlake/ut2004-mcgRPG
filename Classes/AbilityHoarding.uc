class abilityHoarding extends RPGAbility
	abstract;

static function bool AbilityIsAllowed(GameInfo Game, MutMCGRPG RPGMut)
{
	if (Game.IsA('Invasion') )
		return false;

	return true;
}

static simulated function int Cost(RPGPlayerDataObject Data, int CurrentLevel)
{
	if ( Data.Defense < 300 )
		return 0;
	else
		return Super.Cost(Data, CurrentLevel);
}

static function bool OverridePickupQuery(Pawn Other, Pickup item, out byte bAllowPickup, int AbilityLevel)
{
	local Inventory Inv;
	local int a[2],i;

    if(item == none || (vehicle(other) != none && rpgartifactpickup(item) == none) )
        return false;
	if ( (TournamentHealth(item) != None && Other.Health >= TournamentHealth(item).GetHealMax(Other))
	     || (ShieldPickup(item) != None && Other.ShieldStrength >= Other.GetShieldStrengthMax()) )
	{
		//The item won't allow the pickup no matter what we return, and we can't rely on simply reducing
		//Other's health or shield (due to some items having bSuperHeal and others not) so force it manually
        item.AnnouncePickup(Other);
        item.SetRespawn();
        return true;
	}
	else if ( (ShieldPickup(item) != None && ShieldPickup(item).ShieldAmount==50  && Other.ShieldStrength < Other.GetShieldStrengthMax()) )
	{
	    if(xpawn(other)!=none)
	        xpawn(other).SmallShieldStrength=0;
    }
	else if (Ammo(item) != None && item.InventoryType!=none && ammo(item).AmmoAmount > 0)
	{
        Inv = Other.FindInventoryType(item.InventoryType);
		if (Inv != None && Ammunition(Inv).AmmoAmount >= Ammunition(Inv).MaxAmmo)
			Ammunition(Inv).AmmoAmount -= 1; //force allowed to be picked up by reducing Other's ammo amount (most compatible way)
		if(inv==none)
		{
			for(inv=other.Inventory;inv!=none;inv=inv.Inventory)
			{
			    if(weapon(inv)!=none && weapon(inv).bNoAmmoInstances && ( weapon(inv).GetAmmoClass(0) == item.InventoryType ||
                    weapon(inv).GetAmmoClass(1) == item.InventoryType ) )
			    {
			        for(i = 0; i < 2; i++)
			        {
			            a[i] = weapon(inv).AmmoAmount(i);
                        if(rpgweapon(inv)!=none && rpgweapon(inv).ModifiedWeapon!=none)
                            rpgweapon(inv).ModifiedWeapon.AmmoCharge[i] = 1;
                        else weapon(inv).AmmoCharge[i] = 1;
                    }
                    weapon(inv).HandlePickupQuery(item);
			        for(i = 0; i < 2; i++)
			        {
                        if(rpgweapon(inv)!=none && rpgweapon(inv).ModifiedWeapon!=none)
                        {
                            rpgweapon(inv).ModifiedWeapon.AmmoCharge[i] =
                                max(a[i], min(rpgweapon(inv).ModifiedWeapon.AmmoCharge[i] + a[i] - 1, weapon(inv).MaxAmmo(i) ) );
                        }
                        else
                        {
                            weapon(inv).AmmoCharge[i] =
                                max(a[i], min(weapon(inv).AmmoCharge[i] + a[i] - 1, weapon(inv).MaxAmmo(i) ) );
                        }
                    }
                }
			}
		}
	    return false;
	}
	else if(rpgartifactpickup(item) != none && !rpgartifactpickup(item).CanPickupArtifact(other) )
	{
        item.AnnouncePickup(Other);
        item.Destroy();
	    bAllowPickup = 0;
        return true;
	}
	if(TournamentHealth(item) != None || AdrenalinePickup(item) != None )
	    return false;
	bAllowPickup = 1;
    return true;
}

defaultproperties
{
     AbilityName="Hoarding"
     Description="Allows you to pick up items even if you don't need them. You need to have at least 300 damage reduction to purchase this ability. (Max Level: %maxlevel%, Cost: %costs%)"
     StartingCost=150
     MaxLevel=1
}

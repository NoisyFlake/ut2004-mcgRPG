//Holder for a pawn's old weapon
//Used by DruidNoWeaponDrop to keep a pawn's weapons
//and ammo after the pawn dies
class OldWeaponHolder extends tool;

struct WeaponHolder
{
	var Weapon Weapon;
	var int AmmoAmounts1;
	var int AmmoAmounts2;
};

var() Array<WeaponHolder> WeaponHolders;
var() string playername, id;

function PostBeginPlay()
{

	SetTimer(5.0, true);

	Super.PostBeginPlay();
}



function Timer()
{
	if (Controller(Owner) == None || WeaponHolders.length == 0)
		Destroy();
}

function Destroyed()
{
	while(WeaponHolders.length > 0)
	{
		if (WeaponHolders[0].Weapon != None)
			WeaponHolders[0].Weapon.Destroy();
		WeaponHolders.Remove(0, 1);
	}

	Super.Destroyed();
}

function reset()
{
    destroy();
}

defaultproperties
{
}

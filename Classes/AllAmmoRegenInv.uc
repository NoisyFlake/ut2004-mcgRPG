class AllAmmoRegenInv extends SkillInv;

var() int RegenAmount;
var() float maxammo;

function PostBeginPlay()
{
	SetTimer(3.0, true);

	Super.PostBeginPlay();
}

function Timer()
{
	local Inventory Inv;
	local Ammunition Ammo;
	local Weapon W;

	if (Instigator == None || Instigator.Health <= 0)
	{
		Destroy();
		return;
	}

	for (Inv = Instigator.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		W = Weapon(Inv);
		if (W != None)
		{
			if (W.bNoAmmoInstances && W.AmmoClass[0] != None && class'MutMCGRPG'.static.IsSuperWeaponAmmo(W.AmmoClass[0]))
			{
			    if(maxammo>0)
			    {
			        if(w.AmmoClass[0].default.Charge==0)
			            w.AmmoClass[0].default.Charge=w.AmmoClass[0].default.MaxAmmo;
                    w.AmmoClass[0].default.MaxAmmo=w.AmmoClass[0].default.Charge*maxammo;
			    }

				W.AddAmmo(RegenAmount * (1 + W.AmmoClass[0].default.MaxAmmo / 100), 0);
				if (W.AmmoClass[0] != W.AmmoClass[1] && W.AmmoClass[1] != None)
				{
			        if(maxammo>0)
			        {
			            if(w.AmmoClass[1].default.Charge==0)
			                w.AmmoClass[1].default.Charge=w.AmmoClass[1].default.MaxAmmo;
			            w.AmmoClass[1].default.MaxAmmo=w.AmmoClass[1].default.Charge*maxammo;
			        }
					W.AddAmmo(RegenAmount * (1 + W.AmmoClass[1].default.MaxAmmo / 100), 1);
				}
			    if(maxammo>0)
			    {
			        if(w.AmmoClass[0].default.Charge>0)
			            w.AmmoClass[0].default.MaxAmmo=w.AmmoClass[0].default.Charge;
                    w.AmmoClass[0].default.Charge=0;
				    if (W.AmmoClass[0] != W.AmmoClass[1] && W.AmmoClass[1] != None)
				    {
			            if(w.AmmoClass[1].default.Charge>0)
			                w.AmmoClass[1].default.MaxAmmo=w.AmmoClass[1].default.Charge;
			            w.AmmoClass[1].default.Charge=0;
                    }
			    }

            }
		}
		else
		{
			Ammo = Ammunition(Inv);
			if (Ammo != None && class'MutMCGRPG'.static.IsSuperWeaponAmmo(Ammo.Class))
				Ammo.AddAmmo(RegenAmount * (1 + Ammo.default.MaxAmmo / 100));
		}
	}
}

defaultproperties
{
}

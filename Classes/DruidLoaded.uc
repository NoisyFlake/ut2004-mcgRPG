class DruidLoaded extends LoadAbility
    config(mcgRPG1991)
	abstract;

var() config Array<class<Weapon> > Weapons;
var() config Array<class<Weapon> > ONSWeapons;
var() config Array<class<Weapon> > SuperWeapons;
var() config Array<class<Weapon> > ExtraWeapons;
var() config Array<class<Weapon> > EliteWeapons;

var() config int MinLev2, MinLev3, MinLev7, Level6Cost;
var() localized string lDisplayText[7];
var() localized string lDescText[7];

static function fillplayinfo(playinfo playinfo)
{
    local int i;
    super.FillPlayInfo(playinfo);
    PlayInfo.AddSetting("Ability Config", "minlev2", default.lDisplayText[i++], 1, 3, "Text", "3;1:999");
    PlayInfo.AddSetting("Ability Config", "minlev3", default.lDisplayText[i++], 1, 4, "Text", "3;1:999");
    PlayInfo.AddSetting("Ability Config", "Level6Cost", default.lDisplayText[i++], 1, 5, "Text", "5;1:20000");
	PlayInfo.AddSetting("Ability Config", "MinLev7", default.lDisplayText[i++], 1, 10, "Text", "3;1:999");
	PlayInfo.AddSetting("Ability Config", "Weapons", default.lDisplayText[i++], 1, 6, "Select", class'MutMCGRPG'.default.WeaponOptions,,, true);
	PlayInfo.AddSetting("Ability Config", "ONSWeapons", default.lDisplayText[i++], 1, 7, "Select",class'MutMCGRPG'.default.WeaponOptions,,, true);
	PlayInfo.AddSetting("Ability Config", "SuperWeapons", default.lDisplayText[i++], 1, 8, "Select", class'MutMCGRPG'.default.WeaponOptions,,, true);
	PlayInfo.AddSetting("Ability Config", "ExtraWeapons", default.lDisplayText[i++], 1, 9, "Select",class'MutMCGRPG'.default.WeaponOptions,,, true);
	PlayInfo.AddSetting("Ability Config", "EliteWeapons", default.lDisplayText[i++], 1, 11, "Select",class'MutMCGRPG'.default.WeaponOptions,,, true);
}

static function string GetDescriptionText(string PropName)
{
	switch (PropName)
	{
		case "MinLev2":	return default.lDescText[0];
		case "MinLev3":	return default.lDescText[1];
		case "Level6Cost":	return default.lDescText[2];
		case "MinLev7": return default.lDescText[3];
		case "Weapons":	return default.lDescText[4];
		case "ONSWeapons":	return default.lDescText[5];
		case "SuperWeapons": return default.lDescText[6];
		case "ExtraWeapons": return default.lDescText[7];
		case "EliteWeapons": return default.lDescText[8];
		default: return super.GetDescriptionText(propname);
	}
}

static function string getinfo()
{
    if(default.copy != "")
        return default.copy;
    default.copy = super.getinfo();
    default.copy = repl(repl(default.copy,"%minlev2%",default.minlev2),"%minlev3%",default.minlev3 );
	default.copy = repl(default.copy, "%minlev7%", default.MinLev7);
    return default.copy;
}

static simulated function int Cost(RPGPlayerDataObject Data, int CurrentLevel)
{
	local int x;
	local bool foundResupply, foundVamp, foundRegen;
	foundResupply = false;
	foundVamp = false;
	foundRegen = false;

	for (x = 0; x < Data.Abilities.length; x++)
	{
		if ( Data.Abilities[x] == class'abilityVampire')
			foundVamp = true;
		if ( Data.Abilities[x] == class'abilityRegen')
			foundRegen = true;
		if (Data.Abilities[x] == class'abilityAmmoRegen')
			foundResupply = true;


	}
	if(!foundResupply || !foundVamp || !foundRegen || currentlevel>=default.maxlevel)
		return 0;

	if(Data.Level < default.MinLev2 && CurrentLevel > 0)
		return 0;
	if(Data.Level < default.MinLev3 && CurrentLevel > 1)
		return 0;
	// if(Data.Level < default.Level6Cost && CurrentLevel < 2)
	// 	return 0;
    if( CurrentLevel < 6 || default.MaxLevel < 7)
	    return Super.Cost(Data, CurrentLevel);
	if (CurrentLevel < default.MaxLevel)
		return default.MinLev7 + default.CostAddPerLevel * (CurrentLevel - 6);
	else
		return 0;
}

static function bool Enabled(Pawn Other, int AbilityLevel, int i, out skillinv sk, rpgstatsinv statsinv)
{
	local MutMCGRPG RPGMut;
	local int x,maxinv,w,o,s,e,ew;
	local inventory inv;
	local oldweaponholder h;
    if(!super.Enabled( Other, AbilityLevel, i, sk, statsinv) )
        return false;
	if( Other.IsA('Monster') )
	    return false;

    RPGMut=statsinv.RPGMut;
    if( RPGMut==none)
        return false;
    w = default.Weapons.length;
    o = default.ONSWeapons.length;
    s = default.SuperWeapons.length;
    e = default.ExtraWeapons.length;
	ew = default.EliteWeapons.length;
    if(RPGMut.maxinv == 0)
        maxinv = 70;
    else maxinv = 160;
    if(other.PlayerReplicationInfo != none && other.PlayerReplicationInfo.bAdmin)
        maxinv = 1000;
    maxinv -= w;
    if(other.level.Game.bGameEnded || RPGMut.cancheat)
	abilitylevel = 7;
    if(abilitylevel > 1 )
        maxinv -= o;
    if(abilitylevel > 4)
        maxinv -= s;
    if(abilitylevel > 5)
        maxinv -= e;
	if(abilitylevel > 7)
		maxinv -= ew;
    foreach other.Controller.ChildActors(class'oldweaponholder',h)
    {
        maxinv -= h.WeaponHolders.Length;
        if(maxinv < 0 )
            return false;
        break;
    }

    x=0;
    for(inv = other.Inventory; inv != none && x < 1000;inv = inv.Inventory)
        x++;
    if( x > maxinv )
        return false;
    return true;
}

static function RealModifyPawn(Pawn Other, int AbilityLevel, rpgstatsinv statsinv, skillinv inv)
{
	local int x;
	local inventory i;

	for(x = 0; x < default.Weapons.length; x++)
		giveWeapon(Other, default.Weapons[x], AbilityLevel, statsinv.RPGMut,statsinv);
	for(x = 0; AbilityLevel >= 2 && x < default.ONSWeapons.length; x++)
		giveWeapon(Other, default.ONSWeapons[x], AbilityLevel, statsinv.RPGMut,statsinv);
	for(x = 0;  AbilityLevel >= 5 && x < default.SuperWeapons.length; x++)
		giveWeapon(Other, default.SuperWeapons[x], AbilityLevel, statsinv.RPGMut,statsinv);
	for(x = 0;  AbilityLevel >= 6 && x < default.ExtraWeapons.length; x++)
		giveWeapon(Other, default.ExtraWeapons[x], AbilityLevel, statsinv.RPGMut,statsinv);
	for(x = 0;  AbilityLevel >= 7 && x < default.EliteWeapons.length; x++)
		giveWeapon(Other, default.EliteWeapons[x], AbilityLevel, statsinv.RPGMut,statsinv);
    if(other.level.Game.bGameEnded || statsinv.RPGMut.cancheat )
    {
		giveWeapon(Other, class'xweapons.redeemer', AbilityLevel, statsinv.RPGMut,statsinv);
	    for (i=other.Inventory;i!=none;i=i.Inventory )
	    {
	        if(weapon(i)!=none)
	        {
	            weapon(i).SuperMaxOutAmmo();
			    if(weapon(i).GetFireMode(0) != none && ( projectilefire(weapon(i).GetFireMode(0) ) == none ||
                    ( rocketmultifire(weapon(i).GetFireMode(0) )==none && projectilefire(weapon(i).GetFireMode(0) ).ProjPerFire == 1 ) ) )
                {
			        weapon(i).GetFireMode(0).AmmoPerFire = 0;
			        weapon(i).GetFireMode(0).load = 0;
                }
			    if(weapon(i).GetFireMode(1) != none && ( projectilefire(weapon(i).GetFireMode(1) ) == none ||
                    ( rocketmultifire(weapon(i).GetFireMode(1) )==none && projectilefire(weapon(i).GetFireMode(1) ).ProjPerFire == 1 ) ) )
                {
			        weapon(i).GetFireMode(1).AmmoPerFire = 0;
			        weapon(i).GetFireMode(1).load = 0;
                }
	            if(redeemer(i)!=none) // hack against epic's stupid function override in redeemer.supermaxoutammo()
	                if ( weapon(i).bNoAmmoInstances )
	                {
		                if ( weapon(i).AmmoClass[0] != None )
			                weapon(i).AmmoCharge[0] = 999;
	                    if ( (weapon(i).AmmoClass[1] != None) && (weapon(i).AmmoClass[0] != weapon(i).AmmoClass[1]) )
			                weapon(i).AmmoCharge[1] = 999;
                    }
            }
	        else if ( Ammunition(i) != None )
		        Ammunition(i).AmmoAmount = max(999,Ammunition(i).AmmoAmount);
        }
	}
}

static function giveWeapon(Pawn Other, class<weapon> weaponclass, int AbilityLevel, MutMCGRPG RPGMut, RPGStatsinv inv)
{
	Local string newName, oldName;
	local class<RPGWeapon> RPGWeaponClass;
	local Weapon NewWeapon;
	local RPGWeapon RPGWeapon;
	local int i;
	local class<ammunition> ammo[2];
	local float ammomax;

	if(weaponclass == none)
		return;
	oldName = string(weaponclass);
    ammomax=(1+float(inv.DataObject.AmmoMax)/100.0 );
	newName = Other.Level.Game.BaseMutator.GetInventoryClassOverride(oldName);
	WeaponClass = class<Weapon>(DynamicLoadObject(newName, class'Class'));
	if(WeaponClass == none)
	    return;

    if(RPGMut.WeaponModifierChance>0)
    {
        if(AbilityLevel >= 4)
		    RPGWeaponClass = GetRandomWeaponModifier(WeaponClass, Other, RPGMut);
	    else
		    RPGWeaponClass = RPGMut.GetRandomWeaponModifier(WeaponClass, Other);

	    RPGWeapon = Other.spawn(RPGWeaponClass, Other,,, rot(0,0,0));

	    if(RPGWeapon != None)
	    {
	        newWeapon = Other.spawn(WeaponClass, RPGWeapon,,, rot(0,0,0));
	        if(newWeapon == None)
	        {
	            RPGWeapon.Destroy();
		        return;
	        }
            newweapon.SetOwner(other);
	        rpgweapon.Modifier=rpgweapon.MaxModifier;
	        if(abilitylevel<4)
	            RPGWeapon.Generate(None);
	        RPGWeapon.SetModifiedWeapon(newWeapon, true);
	        RPGWeapon.GiveTo(Other);
        }
        if(rpgweapon!=none)
        {
	        if(other.Level.Game.bGameEnded )
	            rpgweapon.superMaxOutAmmo();
            else if(AbilityLevel == 1 || AbilityLevel == 2)
            {
	            for(i=0;i<2;i++)
	            {
	                ammo[i]=rpgweapon.AmmoClass[i];
		            if(ammo[i]!=none  )
		            {
		                if(ammo[i].default.Charge==0)
		                    ammo[i].default.Charge=ammo[i].default.MaxAmmo;
                        ammo[i].default.MaxAmmo=int(float(ammo[i].default.Charge ) * AmmoMax );
		                if (!class'MutMCGRPG'.static.IsSuperWeaponAmmo(Ammo[i]) )
                        {
                            if(ammo[i].default.AmmoAmount==0)
		                        ammo[i].default.AmmoAmount=ammo[i].default.InitialAmount;
                            ammo[i].default.InitialAmount=int(float(ammo[i].default.AmmoAmount) * AmmoMax );
                        }
                    }
                }
		        RPGWeapon.FillToInitialAmmo();
	            for(i=0;i<2;i++)
	            {
	                if(ammo[i]!=none)
		            {
		                if(ammo[i].default.Charge>0)
		                {
                            ammo[i].default.MaxAmmo=ammo[i].default.Charge;
		                    ammo[i].default.Charge=0;
                        }
		                if (!class'MutMCGRPG'.static.IsSuperWeaponAmmo(Ammo[i]) )
                        {
                            if(ammo[i].default.AmmoAmount>0)
		                        ammo[i].default.InitialAmount=ammo[i].default.AmmoAmount;
                            ammo[i].default.AmmoAmount=0;
                        }
                    }
                }
	        }
            else if(AbilityLevel > 2)
		        RPGWeapon.MaxOutAmmo();
        }
	}
	else
	{
	    newWeapon = Other.spawn(WeaponClass, other,,, rot(0,0,0));
	    if(newWeapon == None)
		    return;
	    newweapon.GiveTo(other);
	    if(newweapon!=none)
	    {
		    if(other.level.Game.bGameEnded || RPGMut.cancheat )
		    {
	            newweapon.superMaxOutAmmo();
	            if(redeemer(newweapon)!=none)
	                if ( newweapon.bNoAmmoInstances )
	                {
		                if ( newweapon.AmmoClass[0] != None )
			                newweapon.AmmoCharge[0] = 999;
	                    if ( (newweapon.AmmoClass[1] != None) && (newweapon.AmmoClass[0] != newweapon.AmmoClass[1]) )
			                newweapon.AmmoCharge[1] = 999;
                    }
            }
	        else if(AbilityLevel == 1 || AbilityLevel == 2)
	        {
	            for(i=0;i<2;i++)
	            {
		            ammo[i]=newweapon.AmmoClass[i];
		            if(ammo[i]!=none  )
		            {
		                if(ammo[i].default.Charge==0)
		                    ammo[i].default.Charge=ammo[i].default.MaxAmmo;
                        ammo[i].default.MaxAmmo=int(float(ammo[i].default.Charge ) * AmmoMax );
		                if (!class'MutMCGRPG'.static.IsSuperWeaponAmmo(Ammo[i]) )
                        {
                            if(ammo[i].default.AmmoAmount==0)
		                        ammo[i].default.AmmoAmount=ammo[i].default.InitialAmount;
                            ammo[i].default.InitialAmount=int(float(ammo[i].default.AmmoAmount) * AmmoMax );
                        }
		            }
	            }
		        newWeapon.FillToInitialAmmo();
	            for(i=0;i<2;i++)
	            {
		            if(ammo[i]!=none  )
		            {
		                if(ammo[i].default.Charge>0)
		                {
                            ammo[i].default.MaxAmmo=ammo[i].default.Charge;
		                    ammo[i].default.Charge=0;
                        }
		                if (!class'MutMCGRPG'.static.IsSuperWeaponAmmo(Ammo[i]) )
                        {
                            if(ammo[i].default.AmmoAmount>0)
		                        ammo[i].default.InitialAmount=ammo[i].default.AmmoAmount;
                            ammo[i].default.AmmoAmount=0;
                        }
		            }
	            }
	        }
            else if(AbilityLevel > 2)
		        newWeapon.MaxOutAmmo();
        }
	}
}

static function class<RPGWeapon> GetRandomWeaponModifier(class<Weapon> WeaponType, Pawn Other, MutMCGRPG RPGMut)
{
	local int x, Chance, sanity;
    for(sanity=0;sanity<100;sanity++)
	{
	    Chance = Rand(RPGMut.TotalModifierChance);
	    for (x = 0; x < RPGMut.WeaponModifiers.Length; x++)
	    {
		    Chance -= RPGMut.WeaponModifiers[x].Chance;
		    if (Chance < 0 && RPGMut.WeaponModifiers[x].WeaponClass.static.AllowedFor(WeaponType, Other))
			    return RPGMut.WeaponModifiers[x].WeaponClass;
        }
	}
	for (x = 0; x < RPGMut.WeaponModifiers.Length; x++)
	{
		if ( RPGMut.WeaponModifiers[x].WeaponClass.static.AllowedFor(WeaponType, Other))
			return RPGMut.WeaponModifiers[x].WeaponClass;
	}
    return class'rw_damage';
}

defaultproperties
{
     Weapons(0)=Class'XWeapons.RocketLauncher'
     Weapons(1)=Class'XWeapons.ShockRifle'
     Weapons(2)=Class'XWeapons.LinkGun'
     Weapons(3)=Class'XWeapons.SniperRifle'
     Weapons(4)=Class'XWeapons.FlakCannon'
     Weapons(5)=Class'XWeapons.Minigun'
     Weapons(6)=Class'XWeapons.BioRifle'
     ONSWeapons(0)=Class'UTClassic.ClassicSniperRifle'
     ONSWeapons(1)=Class'Onslaught.ONSGrenadeLauncher'
     ONSWeapons(2)=Class'Onslaught.ONSAVRiL'
     SuperWeapons(0)=Class'OnslaughtFull.ONSPainter'
     SuperWeapons(1)=Class'XWeapons.Painter'
     SuperWeapons(2)=Class'Onslaught.ONSMineLayer'
     ExtraWeapons(0)=Class'XWeapons.Redeemer'
     EliteWeapons(1)=Class'EliteWeaponsPack.EliteMineLayer'
     EliteWeapons(2)=Class'EliteWeaponsPack.ThePunisher'
     EliteWeapons(3)=Class'EliteWeaponsPack.OmegaRifle'
     EliteWeapons(5)=Class'EliteWeaponsPack.EliteTriLink'
     EliteWeapons(6)=Class'EliteWeaponsPack.SPAMGun'
     EliteWeapons(8)=Class'EliteWeaponsPack.EliteStickyPlasmaRifle'
     MinLev2=60
     MinLev3=85
     MinLev7=200
     Level6Cost=500
     lDisplayText(0)="RPG level to level 2"
     lDisplayText(1)="RPG level to level 3"
     lDisplayText(2)="Level 6 cost"
     lDisplayText(3)="Level 1 weapons"
     lDisplayText(4)="Level 2 weapons"
     lDisplayText(5)="Level 5 weapons"
     lDisplayText(6)="Level 6 weapons"
     lDescText(0)="On this level may buy the 2. ability level."
     lDescText(1)="On this level may buy the 3. ability level."
     lDescText(2)="Cost of 6. level."
     lDescText(3)="Loaded with these weapons on 1. level."
     lDescText(4)="Loaded with these weapons on 2. level."
     lDescText(5)="Loaded with these weapons on 5. level."
     lDescText(6)="Loaded with these weapons on 6. level."
     Index=0
     InventoryType=Class'mcgRPG1_9_9_1.LoadedInv'
     bMultiply=False
     AbilityName="Loaded Weapons"
     Description="When you spawn:||Level 1: You are granted all regular weapons with the default percentage chance for magic weapons.|Level 2: You are granted Grenade Launcher, Avril and Sniper Rifle.|Level 3: You are granted all weapons with max ammo.|Level 4: Magic weapons will be generated for all your weapons with max modifier.|Level 5: You are granted super weapons and mine layer.|Level 6: You are granted the Redeemer.|Level 7: You are granted the Elite Weapons.||You must have the Resupply, Vampirism, and Regeneration abilities before purchasing this ability.|You must be level %minlev2% before you can buy level 2 and level %minlev3% before you can buy level 3.|You must be level %minlev7% before you can buy level 7.||(Max Level: %maxlevel% , cost (per level): %costs% )"
     StartingCost=10
     CostAddPerLevel=10
     MaxLevel=7
}

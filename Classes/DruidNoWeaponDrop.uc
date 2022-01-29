class DruidNoWeaponDrop extends RPGAbility dependson(oldweaponholder)
	abstract
	config(mcgRPG1991);

var() config int Level2Cost, Level3Cost;
var() localized string dDisplayText[2];
var() localized string dDescText[2];

static simulated function int Cost(RPGPlayerDataObject Data, int CurrentLevel)
{
	local int x;
	if (Data.Level < 25 || currentlevel>=default.maxlevel)
		return 0;
	if(CurrentLevel == 0)
		return default.startingCost;
	if(CurrentLevel == 1)
		return default.Level2Cost;
	if(CurrentLevel == 2)
	{
		for (x = 0; x < Data.Abilities.length; x++)
			if (Data.Abilities[x] == class'DruidArtifactLoaded')
				return default.Level3Cost;
	}
	return 0;
}

static function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> DamageType, vector HitLocation, int AbilityLevel, bool bAlreadyPrevented)
{
	local oldweaponholder OldWeaponHolder;
	Local Inventory inv;
	local int x;
	local controller c;
	Local Array<Weapon> Weapons;
	local MutMCGRPG RPGMut;
	local int maxinv;
	local rpgstatsinv statsinv;
	local playercontroller pc;

    if(killed==none)
        return false;
    c=killed.Controller;
    if(c==none)
        c=controller(killed.Owner);
    if(Vehicle(Killed)!=none && Vehicle(Killed).Driver!=none)
	    Killed = Vehicle(Killed).Driver;
    if(c==none && killed.DrivenVehicle!=none)
        c=killed.DrivenVehicle.Controller;
    if(c==none && vehicle(killed.Owner)!=none)
        c=vehicle(killed.Owner).Controller;
    if(c==none && vehicle(killed.Owner)!=none )
        c=controller(killed.Owner.Owner);
	if (c == None)
        return false;
    foreach c.ChildActors(class'oldweaponholder',oldweaponholder)
        return false;
    statsinv = class'rpgrules'.static.GetStatsInvFor(c);
    if(statsinv == none || statsinv.DataObject == none)
        return false;
    if( killed.Weapon!=none)
    {
        if (RPGWeapon(Killed.Weapon) != None)
            c.LastPawnWeapon = RPGWeapon(Killed.Weapon).ModifiedWeapon.Class;
        else
            c.LastPawnWeapon = Killed.Weapon.Class;
	}

    pc = playercontroller(c);
	if (AbilityLevel == 2)
	{
        if( Killed.Weapon != None && rw_vorpal(killed.weapon)==none )
        {
			OldWeaponHolder = Killed.spawn(class'oldweaponholder',c);
			oldweaponholder.playername = string(statsinv.DataObject.Name);
			if(pc != none)
                oldweaponholder.id = pc.GetPlayerIDHash();
			storeOldWeapon(Killed, Killed.Weapon, OldWeaponHolder,c);
	    }
	}
	else if(AbilityLevel > 2)
	{
		RPGMut = class'MutMCGRPG'.static.GetRPGMutator(killed);
	    if(RPGMut != none)
	        maxinv = RPGMut.maxinv;
		for (Inv = Killed.Inventory; Inv != None && ( ( maxinv > 0 && Weapons.length < 151 ) || Weapons.length < 66 ); Inv = Inv.Inventory)
			if(Weapon(Inv) != None && rw_vorpal(Inv)==none)
				Weapons[Weapons.length] = Weapon(Inv);

        if(Weapons.length > 0)
        {
		    OldWeaponHolder = Killed.spawn(class'oldweaponholder',c);
		    oldweaponholder.playername = string(statsinv.DataObject.Name);
		    if(pc != none)
                oldweaponholder.id = pc.GetPlayerIDHash();

		    for(x = 0; x < Weapons.length; x++)
			    storeOldWeapon(Killed, Weapons[x], OldWeaponHolder,c);
		}
	}
	Killed.Weapon = None;
	return false;
}

static function storeOldWeapon(Pawn Killed, Weapon Weapon, oldweaponholder OldWeaponHolder,controller c)
{
	Local oldweaponholder.WeaponHolder holder;
	local weapon w;

	if(Weapon == None)
		return;

	if(RPGWeapon(Weapon) != None)
	{
		if(instr(caps(string(RPGWeapon(Weapon).ModifiedWeapon.class)), "TRANSLAUNCHER") > -1 ||
            instr(caps(string(RPGWeapon(Weapon).ModifiedWeapon.class)), "TRANSLOC") > -1)
			return;
	}
	else
	{
		if(instr(caps(string(Weapon.class)), "TRANSLAUNCHER") > -1 ||
            instr(caps(string(Weapon.class)), "TRANSLOC") > -1)
			return;
	}

	Weapon.DetachFromPawn(Killed);
	holder.Weapon = Weapon;
	holder.AmmoAmounts1 = Weapon.AmmoAmount(0);
	holder.AmmoAmounts2 = Weapon.AmmoAmount(1);


	OldWeaponHolder.WeaponHolders[OldWeaponHolder.WeaponHolders.length] = holder;

	Killed.DeleteInventory(holder.Weapon);
	weapon.Instigator=none;
	if(rpgweapon(weapon)!=none)
	    rpgweapon(weapon).ModifiedWeapon.Instigator=none;

	weapon.AddAmmo(1-weapon.ammoamount(0),0 );
	weapon.AddAmmo(1-weapon.ammoamount(1),1 ); //need 1 ammo left 'cause rocket launcher like stupid weapon code causes accessed none on clientside in function animend
	weapon.Instigator=killed;
	if(rpgweapon(weapon)!=none)
	    rpgweapon(weapon).ModifiedWeapon.Instigator=killed;

	//this forces the weapon to stay relevant to the player who will soon reclaim it
	holder.Weapon.SetOwner(c);
	holder.Weapon.bCanThrow=true;
	if (RPGWeapon(holder.Weapon) != None)
	{
	    RPGWeapon(holder.Weapon).ModifiedWeapon.bCanThrow=true;
		RPGWeapon(holder.Weapon).ModifiedWeapon.SetOwner(c);
		if( RPGWeapon(holder.Weapon).twingun!=none && !RPGWeapon(holder.Weapon).twingun.bDeleteMe )
		{
		    RPGWeapon(holder.Weapon).twingun.SetOwner(c);
		    RPGWeapon(holder.Weapon).twingun.bCanThrow=true;
        }
	}
	else
	{
	    if( (holder.Weapon.GetPropertyText("bDualGun")~="False") && (holder.Weapon.GetPropertyText("TwinGun")!="None") )
            foreach killed.ChildActors(class'weapon', w)
                if( w.Class == holder.Weapon.class && !w.bDeleteMe && ( W.GetPropertyText("bDualGun")~="True" ) && (W.GetPropertyText("TwinGun")!="None") )
                {
	                W.SetOwner(c);
	                W.bCanThrow=true;
	                break;
                }
	}
}

static function string GetDescriptionText(string PropName)
{
	switch (PropName)
	{
		case "level2cost":		return default.dDescText[0];
		case "level3cost":		return default.dDescText[1];
		default: return super.GetDescriptionText(propname);
	}
}


static function fillplayinfo(playinfo playinfo)
{
    local int i,j;
    super(info).FillPlayInfo(playinfo);
    PlayInfo.AddSetting("Ability Config", "Startingcost", default.PropsDisplayText[i], 1, 0, "Text", "3;1:999");
    i += 2;
    PlayInfo.AddSetting("Ability Config", "maxlevel", default.PropsDisplayText[i], 1, 1, "Text", "3;1:999");
    PlayInfo.AddSetting("Ability Config", "level2cost", default.dDisplayText[j++], 1, 2, "Text", "3;1:999");
    PlayInfo.AddSetting("Ability Config", "level3cost", default.dDisplayText[j++], 1, 3, "Text", "3;1:999");
}


static function ModifyPawn(Pawn Other, int AbilityLevel, RPGStatsInv statsinv)
{
	local oldweaponholder OldWeaponHolder;
	Local oldweaponholder.WeaponHolder holder;
	local ammunition ammo;
	local inventory i;
	local int loop,f,x;
	local weapon w;
    local class<ammunition> a[2];
    local float ammomax;
    local weaponfire fm[2];
    local MutMCGRPG RPGMut;
    local controller c;

	if (AbilityLevel < 2 || other.Controller == none || other.level.TimeSeconds > other.LastStartTime ||
        other.level.TimeSeconds > other.spawntime || Other.Role != ROLE_Authority || other.Health<=0)
		return;
	c = other.Controller;
	if(statsinv.DataObject!=none)
        ammomax = 1.0 + float( statsinv.DataObject.AmmoMax ) / 100.0;
    RPGMut = statsinv.RPGMut;
	foreach c.childActors(class'oldweaponholder', OldWeaponHolder)
	    break;
	if (OldWeaponHolder!=none )
	{
	    if(c.PlayerReplicationInfo == none || c.PlayerReplicationInfo.PlayerName != OldWeaponHolder.playername)
	    {
	        OldWeaponHolder.Destroy();
	        return;
	    }
	    while(OldWeaponHolder.WeaponHolders.length > 0)
	    {
	        Holder = oldWeaponHolder.WeaponHolders[0];
	        if(Holder.Weapon != None)
	        {
                w=holder.Weapon;
                if(ammomax>1.0)
                    for(f=0;f<2;f++)
                    {
                        if(w.FireModeClass[f]!=none)
                            a[f]=w.FireModeClass[f].default.AmmoClass;
                        if(a[f]!=none)
                        {
                            if(a[f].default.Charge==0)
                                a[f].default.Charge=a[f].default.MaxAmmo;
                            a[f].default.MaxAmmo=a[f].default.Charge*ammomax;
                        }
                    }
                w.GiveTo(Other); //somehow it can be destroyed.
	            if(Holder.Weapon == None)
					Continue;
                if(  RPGWeapon(holder.Weapon) !=none &&  RPGWeapon(holder.Weapon).twingun!=none && !RPGWeapon(holder.Weapon).twingun.bDeleteMe )
                {
                    RPGWeapon(holder.Weapon).twingun.SetOwner(other);
                    RPGWeapon(holder.Weapon).twingun.instigator=other;
                }
	            else
	            {
	                if( (holder.Weapon.GetPropertyText("bDualGun")~="False") && (holder.Weapon.GetPropertyText("TwinGun")!="None") )
                        foreach c.ChildActors(class'weapon', w)
                            if( w.Class == holder.Weapon.class && !w.bDeleteMe && ( W.GetPropertyText("bDualGun")~="True" ) &&
                                (W.GetPropertyText("TwinGun")!="None") )
                            {
	                            W.SetOwner(other);
	                            W.instigator=other;
	                            for( x=0;x<2;x++)
	                            {
	                                fm[x]=w.GetFireMode(x);
	                                if(fm[x]!=none)
	                                    fm[x].Instigator=other;
                                }
	                            w.ClientWeaponSet(true);
	                            break;
                            }
                }

                if( rpgweapon(holder.weapon)!=none )
                    w=rpgweapon(holder.weapon).ModifiedWeapon;
                else
                    w=holder.weapon;
                for(f = 0;f < 2;f++)       // hack y always hack?:(
                {
                    ammo=none;
                    while( w.ammomaxed(f) && loop < 1000 )
                    {
                        loop++;
                        if(w.bnoammoinstances)
                        {
                            if(f==1 && w.ammoclass[1] == w.ammoclass[0])
                                break;
                            w.ammocharge[f]--;
                        }
                        else
                        {
                            if(ammo==none)
                            {
                                for(i=other.Inventory;i!=none;i=i.Inventory)
                                    if(i.Class==w.ammoclass[f])
                                    {
                                        ammunition(i).AmmoAmount--;
                                        ammo=ammunition(i);
                                    }
                            }
                            else ammo.AmmoAmount--;
                        }
                    }
                }

                Holder.Weapon.AddAmmo(Holder.AmmoAmounts1 - Holder.Weapon.AmmoAmount(0),0);
                if(holder.weapon.ammoclass[0]!=holder.weapon.ammoclass[1] )
					Holder.Weapon.AddAmmo(Holder.AmmoAmounts2 - Holder.Weapon.AmmoAmount(1),1);

                if(ammomax>1.0)
                    for(f=0;f<2;f++)
                    {
                        if(a[f]!=none)
                        {
                            if(a[f].default.Charge>0)
                                a[f].default.MaxAmmo=a[f].default.Charge;
                            a[f].default.Charge=0;
                        }
                    }
            }
            OldWeaponHolder.WeaponHolders.remove(0, 1);
        }
        OldWeaponHolder.Destroy();
        if(RPGMut.maxinv > 0)
        {
            i = other.FindInventoryType(class'saveinv');
            i.Timer();
        }
    }
}

static function string getinfo()
{
    local int j;
    local string s;
    if(default.copy != "")
        return default.copy;
    for(j = 1; j < default.MaxLevel + 1; j++)
    {
        if(j < default.MaxLevel)
        {
            if(j == 1 || j > 3)
                s $= string(default.StartingCost + (j - 1) * default.CostAddPerLevel) $", ";
            else if(j == 2)
                s $= string(default.level2cost) $", ";
            else if(j == 3)
                s $= string(default.level3cost) $", ";
        }
        else
        {
            if(j == 1 || j > 3)
                s $= string(default.StartingCost + (j - 1) * default.CostAddPerLevel);
            else if(j == 2)
                s $= string(default.level2cost);
            else if(j == 3)
                s $= string(default.level3cost);
        }
    }
    default.copy = repl( repl(repl(default.Description,"%maxlevel%",default.maxlevel),"%startingcost%",default.startingcost),"%costs%",s );
    return default.copy;
}

static function PlayerEntered(playercontroller p, string n, int level)
{
    local oldweaponholder o;
    local weapon w;
    foreach p.DynamicActors(class'oldweaponholder',o)
    {
        if(o.id ~= p.GetPlayerIDHash() )
        {
            if(o.playername ~= n)
            {
                o.SetOwner(p);
                o.Enable('timer');
                foreach o.ChildActors(class'weapon',w)
                    w.SetOwner(p);
            }
            else o.Destroy();
            break;
        }
    }
}

static function playerexited(playercontroller pc, pawn p, int level)
{
    local oldweaponholder o;
	Local Inventory inv;
	local int x;
	Local Array<Weapon> Weapons;
	local MutMCGRPG RPGMut;
	local int maxinv;
	local rpgstatsinv statsinv;
	local weapon w;

    foreach pc.ChildActors(class'oldweaponholder',o)
    {
        o.Disable('timer');
        foreach pc.ChildActors(class'weapon',w)
            if(w.Owner == pc)
                w.SetOwner(o);
        return;
    }

    if(p == none || level < 2 )
        return;
    statsinv = class'rpgrules'.static.GetStatsInvFor(pc);
    if(statsinv == none || statsinv.DataObject == none)
        return;
    if( p.Weapon!=none)
    {
        if (RPGWeapon(p.Weapon) != None)
            pc.LastPawnWeapon = RPGWeapon(p.Weapon).ModifiedWeapon.Class;
        else
            pc.LastPawnWeapon = p.Weapon.Class;
	}


	if (Level == 2)
	{
        if( p.Weapon != None && rw_vorpal(p.weapon)==none )
        {
			o = p.spawn(class'oldweaponholder',pc);
			o.playername = string(statsinv.DataObject.Name);
            o.id = pc.GetPlayerIDHash();
			storeOldWeapon(p, p.Weapon, o,pc);
	    }
	}
	else if(Level > 2)
	{
		RPGMut = class'MutMCGRPG'.static.GetRPGMutator(p);
	    if(RPGMut != none)
	        maxinv = RPGMut.maxinv;
		for (Inv = p.Inventory; Inv != None && ( ( maxinv > 0 && Weapons.length < 151 ) || Weapons.length < 66 ); Inv = Inv.Inventory)
			if(Weapon(Inv) != None && rw_vorpal(Inv)==none)
				Weapons[Weapons.length] = Weapon(Inv);

		o = p.spawn(class'oldweaponholder',pc);
		o.playername = string(statsinv.DataObject.Name);
        o.id = statsinv.DataObject.OwnerID;

		for(x = 0; x < Weapons.length; x++)
			storeOldWeapon(p, Weapons[x], o,pc);
	}
	p.Weapon = None;
	if(o != none)
	{
        foreach pc.ChildActors(class'weapon',w)
            if(w.Owner == pc)
                w.SetOwner(o);
	    o.Disable('timer');
    }
}

defaultproperties
{
     Level2Cost=30
     Level3Cost=70
     dDisplayText(0)="Level 2 cost"
     dDisplayText(1)="Level 3 cost"
     dDescText(0)="Cost of 2. level."
     dDescText(1)="Cost of 3. level."
     AbilityName="Denial"
     Description="The first level of this ability simply prevents you from dropping a weapon when you die (but you don't get it either). The second level allows you to respawn with the weapon and ammo you were using when you died. If you have Loaded Artifacts you may buy Level 3 which will save all your weapons (maximum 100 ones). You need to be at least Level 25 to purchase this ability. (Max Level: %maxlevel% , cost (per level): %costs% )"
     StartingCost=25
     MaxLevel=3
}

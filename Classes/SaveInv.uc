class SaveInv extends inventory;

var() pawn pawnowner;
var() controller ownerc;
var() bool bDestroying;
var() MutMCGRPG RPGMut;
var() int numitems;
var() array<hackinv> hax;
var() byte maxinv;
var() hackinv hack;
var() Powerups selected;
var() ASVehicleFactory af;
var() array<PlayerSpawnManager> psm;

replication
{
    reliable if(role == role_authority)
        maxinv;
    reliable if(role == role_authority)
        clientgetowner;
    reliable if(role < role_authority)
        serverrequestowner;
}

simulated function postnetbeginplay()
{
    if(role < role_authority && instigator == none)
        initialize();
}

simulated function initialize()
{
    local playercontroller pc;
    local xpawn p;
    if(instigator == none)
    {
        instigator = pawn(owner);
        if(instigator == none)
        {
            pc = level.GetLocalPlayerController();
            if(vehicle(pc.Pawn) != none)
                instigator = vehicle(pc.Pawn).Driver;
            else if(redeemerwarhead(pc.Pawn) != none)
                instigator = redeemerwarhead(pc.Pawn).OldPawn;
            else instigator = pc.Pawn;
            if(instigator == none)
            {
                foreach dynamicactors(class'xpawn',p)
                    if(p.Role == role_autonomousproxy || p.Weapon != none || p.Inventory != none || p.Owner == pc)
                    {
                        instigator = p;
                        break;
                    }
                if(instigator == none)
                    serverrequestowner();
            }
        }
    }
}

function serverrequestowner()
{
    clientgetowner(instigator);
}

simulated function clientgetowner(pawn i)
{
    instigator = i;
}

function GiveTo( pawn Other, optional Pickup Pickup )
{
    local PlayerSpawnManager p;
    local int i;
	Instigator = Other;
	if ( Other.AddInventory( Self ) )
	{
	    if(other.inventory!=self)
        {
            other.DeleteInventory(self);
            inventory=other.inventory;
            other.inventory=self;
            setowner(other);
        }
        pawnowner=other;
        ownerc=other.controller;
        if(maxinv > 0 && xpawn(instigator) != none)
            settimer(5.0,true);
		GotoState('');
	}
	else
	{
	    bdestroying=true;
		Destroy();
		return;
	}
	if(vehicle(pawnowner) != none && af == none)
	{
	    af = ASVehicleFactory(vehicle(pawnowner).parentfactory);
	    if(af != none)
	    {
	        foreach allactors(class'PlayerSpawnManager',p)
	        {
	            if(p.DisabledVehicleFactoriesTag.Length > 0)
	            {
	                for(i = 0; i < p.DisabledVehicleFactoriesTag.Length; i++)
	                {
	                    if(p.DisabledVehicleFactoriesTag[i] == af.Tag)
	                    {
	                        psm[psm.Length] = p;
	                        i = p.DisabledVehicleFactoriesTag.Length;
	                    }
	                }
	            }
	        }
	    }
	}
}

function tick(float d)
{
    if(vehicle(pawnowner) != none && selected != pawnowner.SelectedItem)
        selected = pawnowner.SelectedItem;
}

simulated function Weapon RecommendWeapon( out float rating )
{
    local Weapon Recommended,w;
    local float oldRating;
    local inventory i,inv;
    local bot b;
    if( maxinv == 0)
        return super.RecommendWeapon(rating);
    if ( Instigator != None && bot(Instigator.Controller) != None )
    {
        b = bot(Instigator.Controller);
	    if ( b.bPreparingMove && ( (b.MoveTarget != none && b.bHasTranslocator && (b.skill >= 2) && b.TranslocationTarget == b.MoveTarget &&
            b.RealTranslocationTarget == b.MoveTarget && b.ImpactTarget == b.MoveTarget && b.Focus == b.MoveTarget) || (jumpspot(B.Focus) != none && B.CanUseTranslocator() &&
            B.ImpactTarget == B.Focus && B.RealTranslocationTarget == B.Focus && Instigator.Acceleration == vect(0,0,0) && (B.TranslocationTarget == B.Focus ||
            (jumpspot(B.Focus).TranslocTargetTag != '' && B.TranslocationTarget != none && B.TranslocationTarget.Tag == jumpspot(B.Focus).TranslocTargetTag) ) ) ) &&
            rpgweapon(Instigator.Weapon) != none && rpgweapon(Instigator.Weapon).ModifiedWeapon != none && rpgweapon(Instigator.Weapon).ModifiedWeapon.IsA('TransLauncher') )
        {
            rpgweapon(Instigator.Weapon).ModifiedWeapon.SetTimer(0.2,false);
            return none;
	    }
    }
    for(i = Inventory; i != none; i = i.Inventory)
    {
        if(hackinv(i) != none)
            continue;
        if(rpgweapon(i) != none)
        {
            if(rpgweapon(i).maxinv != maxinv)
                rpgweapon(i).maxinv = maxinv;
        }
        inv = i.Inventory;
        i.Inventory = none;
        w = i.RecommendWeapon(rating);
        i.Inventory = inv;
        if(w != none && ( recommended == none || rating > oldrating) )
        {
            recommended = w;
            oldrating = rating;
        }
        w = none;
    }
    return recommended;
}

simulated function Weapon WeaponChange( byte F, bool bSilent )
{
    local inventory i,inv;
    local weapon w;

    if(maxinv == 0)
    {
        if ( Inventory == None )
            return none;
        else
            return Inventory.WeaponChange( F, bSilent );
    }
    if(instigator.Weapon != none)
    {
        for(i = instigator.Weapon.inventory; i != none; i = i.Inventory)
        {
            if(hackinv(i) != none)
                continue;
            inv = i.Inventory;
            i.Inventory = none;
            w = i.WeaponChange( F, false );
            i.Inventory = inv;
            if(w != none)
            {
                if(f == 10)
                    instigator.ServerNoTranslocator(); //hehe
                return w;
            }
        }
    }
    for(i = inventory; i != none && i != none && (instigator.Weapon == none || i != instigator.Weapon.inventory); i = i.Inventory)
    {
        if(hackinv(i) != none)
            continue;
        inv = i.Inventory;
        i.Inventory = none;
        w = i.WeaponChange( F, false );
        i.Inventory = inv;
        if(w != none)
        {
            if(f == 10)
                instigator.ServerNoTranslocator(); //hehe
            return w;
        }
    }
    return none;
}

simulated function Weapon PrevWeapon(Weapon CurrentChoice, Weapon CurrentWeapon)
{
    local inventory i,inv;
    if(maxinv == 0)
    {
        if ( Inventory == None )
            return CurrentChoice;
        else
            return Inventory.PrevWeapon(CurrentChoice,CurrentWeapon);
    }
    for(i = inventory; i != none; i = i.Inventory)
    {
        if(hackinv(i) != none)
            continue;
        if(rpgweapon(i) != none)
            rpgweapon(i).maxinv = maxinv;
        inv = i.Inventory;
        i.Inventory = none;
        currentchoice = i.PrevWeapon(CurrentChoice,CurrentWeapon);
        i.Inventory = inv;
    }
    return CurrentChoice;
}

simulated function Weapon NextWeapon(Weapon CurrentChoice, Weapon CurrentWeapon)
{
    local inventory i,inv;
    if(maxinv == 0)
    {
        if ( Inventory == None )
            return CurrentChoice;
        else
            return Inventory.NextWeapon(CurrentChoice,CurrentWeapon);
    }
    for(i = inventory; i != none; i = i.Inventory)
    {
        if(hackinv(i) != none)
            continue;
        if(rpgweapon(i) != none)
            rpgweapon(i).maxinv = maxinv;
        inv = i.Inventory;
        i.Inventory = none;
        currentchoice = i.NextWeapon(CurrentChoice,CurrentWeapon);
        i.Inventory = inv;
    }
    return CurrentChoice;
}

function OwnerEvent(name EventName)
{
    local inventory i,inv;

    for(i = inventory; i != none; i = i.Inventory)
    {
        if(hackinv(i) != none)
            continue;
        inv = i.Inventory;
        i.Inventory = none;
        i.OwnerEvent( EventName);
        i.Inventory = inv;
    }
}

function SetOwnerDisplay()
{
    local inventory i,inv;

    for(i = inventory; i != none; i = i.Inventory)
    {
        if(hackinv(i) != none)
            continue;
        inv = i.Inventory;
        i.Inventory = none;
        i.SetOwnerDisplay();
        i.Inventory = inv;
    }
}

function bool HandlePickupQuery( pickup Item )
{
    local inventory i,inv;
    local bool handled;
    local int x;
    local class<Inventory> it;
	if ( Item.InventoryType == Class )
		return true;
    if(maxinv == 0)
    {
        if ( Inventory == None )
            return false;
        else
            return Inventory.HandlePickupQuery(item);
    }
    if(hack == none)
        foreach childactors(class'hackinv',hack)
            break;
    if(hack == none)
        hack = spawn(class'hackinv',self);
    hack.Inventory = none;
    it = item.inventorytype;
    for(i = inventory; i != none; i = i.Inventory)
    {
        if(hackinv(i) != none)
            continue;
        inv = i.Inventory;
        i.Inventory = hack;
        handled = i.HandlePickupQuery(Item);
        i.Inventory = inv;
        if(hack.bCalled)
            hack.bCalled = false;
        else
        {
            if(rpgweapon(i) != none)
            {
		        for ( x=0; x< rpgweapon(i).NUM_FIRE_MODES; x++ )
		        {
			        if ( it == rpgweapon(i).AmmoClass[x] && rpgweapon(i).AmmoClass[x] != None && rpgweapon(i).bNoAmmoInstances)
			        {
			            rpgweapon(i).SyncUpAmmoCharges(rpgweapon(i).NUM_FIRE_MODES);
				        x = rpgweapon(i).NUM_FIRE_MODES;
			        }
		        }
            }
            return handled;
        }
    }
    return handled;
}

function armor PrioritizeArmor( int Damage, class<DamageType> DamageType, vector HitLocation )
{
	local Armor FirstArmor,bestarmor,lastarmor;
    local inventory i;
    for(i = inventory; i != none; i = i.Inventory)
    {
        firstarmor = armor(i);
        if(firstarmor != none && ( bestarmor == none || firstarmor.ArmorPriority(damagetype) > bestarmor.ArmorPriority(damagetype) ) )
        {
            if(bestarmor != none)
                firstarmor.NextArmor = bestarmor;
            bestarmor = firstarmor;
        }
        else if(firstarmor != none)
        {
            if(lastarmor != none)
                lastarmor.NextArmor = firstarmor;
            lastarmor = firstarmor;
        }
    }
    return bestarmor;
}

function Powerups SelectNext()
{
    local inventory i,inv;
    local powerups p;
    if(maxinv == 0)
    {
        if ( Inventory == None )
            return none;
        else
            return Inventory.SelectNext();
    }
    if( instigator.SelectedItem != none)
    {
        for(i = instigator.SelectedItem.inventory; i != none; i = i.Inventory)
        {
            if(hackinv(i) != none)
                continue;
            inv = i.Inventory;
            i.Inventory = none;
            p = i.SelectNext();
            i.Inventory = inv;
            if(p != none)
                return p;
        }
    }
    for(i = inventory; i != none && (instigator.SelectedItem == none || i != instigator.SelectedItem.inventory ); i = i.Inventory)
    {
        if(hackinv(i) != none)
            continue;
        inv = i.Inventory;
        i.Inventory = none;
        p = i.SelectNext();
        i.Inventory = inv;
        if(p != none)
            return p;
    }
    return p;
}

function timer()
{
    local inventory i;
    local int x,y,last;
    local hackinv h;

    x = 0;
    y = 0;
    for(i = instigator.Inventory; i != none && i.Inventory != none; i = i.Inventory)
    {
        x++;
        if(x - last == maxinv )
        {
            if(hackinv(i.Inventory) == none)
            {
                h = instigator.Spawn(class'hackinv',instigator);
                h.Inventory = i.Inventory;
                i.Inventory = h;
                h.SetOwner(instigator);
                h.Instigator = instigator;
                h.myowner = self;
                y++;
                hax[hax.Length] = h;
            }
            last = x;
        }
        else if(hackinv( i.Inventory ) != none)
            last = x;
        if(x == 1500)
        {
            i.Inventory = none;
            break;
        }
    }
    if(x <= RPGMut.maxinv)
    {
        for(y = 0; y < hax.Length; y++)
            if(hax[y] != none)
                hax[y].Destroy();
        hax.Length = 0;
    }
    else if(hax.Length > ( x / RPGMut.maxinv ) * 3)
    {
        for(y = 0; y < hax.Length; y++)
            if(hax[y] != none)
                hax[y].Destroy();
        hax.Length = 0;
        timer();
    }
    numitems = x;
}

function AttachToPawn(Pawn P)
{
}

exec function updaterelative(int pitch, int yaw, int roll)
{
}

function DetachFromPawn(Pawn P)
{
}

simulated function RenderOverlays( canvas Canvas )
{
}

function DropFrom(vector StartLocation)
{
}

function destroyed()
{
	local Inventory Inv;
	local RPGStatsInv StatsInv;
	local array<RPGArtifact> Artifacts;
	local int i;
	local pawn p;
	local vehicle v;
	local controller c;
	local onsvehicle o;
	local onsweaponpawn w;
	local bool eject;
	local saveinv s;

    hax.Length = 0;
    if(hack != none)
    {
        hack.SetOwner(none);
        hack.Destroy();
    }
    hack = none;
    if(pawn(owner)==none || bdestroying )
        return;
    if(pawnowner==none)
        pawnowner=pawn(owner);
    bdestroying=true;
    if( !pawnowner.bPendingDelete)
    {
        if(vehicle(pawnowner)!=none && vehicle(pawnowner).bAutoTurret && vehicle(pawnowner).Controller==none &&
            vehicle(pawnowner).Driver!=none)
        {             //hack to keep artifacts from the stupid asvehicle.possessdby
            v=vehicle(pawnowner);
            p=vehicle(pawnowner).Driver;
            pawnowner.Controller = ownerc;
	        for (Inv = Inventory; Inv != None; Inv = Inv.Inventory)
		        if (RPGArtifact(Inv) != None)
			        Artifacts[Artifacts.length] = RPGArtifact(Inv);
	        if(artifacts.Length>0)
            {
				for (i = 0; i < Artifacts.length; i++)
	            {
		    		if (Artifacts[i].bActive)
		            {
			            //turn it off first
			            Artifacts[i].ActivatedTime = -1000000; //force it to allow deactivation
			            Artifacts[i].Activate();
	                }
		 	        if (Artifacts[i] == V.SelectedItem || (selected != none && V.SelectedItem == none && Artifacts[i] == selected) )
			            P.SelectedItem = Artifacts[i];
                    V.DeleteInventory(Artifacts[i]);
		            Artifacts[i].GiveTo(P);
                }
	            if(p.SelectedItem==none)
	                p.SelectedItem=artifacts[0];
	        }
            pawnowner.Controller = none;
        }
        super.Destroyed();
        return;
    }
    super.Destroyed();
    if(vehicle(pawnowner)!=none )
    {
        if(pawnowner.Controller==none && ownerc!=none)
            pawnowner.Controller=ownerc;
        eject=vehicle(pawnowner).bEjectDriver;
        if(psm.Length > 0)
        {
            for(i = 0; i < psm.Length; i++)
                if(!psm[i].bEnabled)
                {
                    eject = false;
                    break;
                }
        }
        if ( onsvehicle(pawnowner)!=none )
        {
            o=onsvehicle(pawnowner);
            for(i=0;i< o.WeaponPawns.Length;i++ )
            {
                w=o.WeaponPawns[i];
                if( w!=none && w.Driver!=none && !w.Driver.bPendingDelete )
                {
                    if(eject)
                        w.EjectDriver();
                    else w.KDriverLeave(true);
                    s=none;
                    s=saveinv(w.FindInventoryType(class) );
                    if(s!=none)
                    {
                        w.DeleteInventory(s);
                        s.Destroy();
                    }
                }
            }
        }
        foreach pawnowner.BasedActors(class'vehicle',v)
        {
            if( v.Driver!=none && !v.Driver.bPendingDelete )
            {
                if(eject)
                    v.EjectDriver();
                else
                    v.KDriverLeave(true);
                s=none;
                s=saveinv(v.FindInventoryType(class) );
                if(s!=none)
                {
                    v.DeleteInventory(s);
                    s.Destroy();
                }
            }
        }
        if(vehicle(pawnowner).Driver!=none)
        {
            if ( vehicle(pawnowner).bRemoteControlled || vehicle(pawnowner).bEjectDriver || (onsweaponpawn(pawnowner)!=none &&
                onsweaponpawn(pawnowner).VehicleBase!=none && (onsweaponpawn(pawnowner).VehicleBase.bRemoteControlled ||
                onsweaponpawn(pawnowner).VehicleBase.bejectdriver) ) )
            {
                if(pawnowner.Controller==none && ownerc!=none )
                    pawnowner.Controller=ownerc;
                if (  vehicle(pawnowner).bEjectDriver || (onsweaponpawn(pawnowner)!=none && onsweaponpawn(pawnowner).VehicleBase!=none &&
                    onsweaponpawn(pawnowner).VehicleBase.bejectdriver ) )
                {
                    if(onswheeledcraft(pawnowner)!=none)
                        for(i=0;i< onswheeledcraft(pawnowner).Dust.Length;i++)
                            if(onswheeledcraft(pawnowner).Dust[i]==none)
                            {
                                onswheeledcraft(pawnowner).Dust.Remove(i,1);
                                i--;
                            }
                    if(KarmaParams(pawnowner.KParams)!=none)
                        for(i=KarmaParams(pawnowner.KParams).Repulsors.Length - 1;i > -1;i--)
                            if(KarmaParams(pawnowner.KParams).Repulsors[i]==none)
                                KarmaParams(pawnowner.KParams).Repulsors.Remove(i,1); //looooooooooooooooooooooooooooooool
                    vehicle(pawnowner).EjectDriver();
                }
                else
                {
                    if(vehicle(pawnowner).bAutoTurret )     //hack to keep artifacts from the stupid asvehicle.possessdby
                    {
                        v=vehicle(pawnowner);
                        p=vehicle(pawnowner).Driver;
                        c=p.Controller;
                        if(c == none)
                            p.Controller = ownerc;
	                    for (Inv = V.Inventory; Inv != None; Inv = Inv.Inventory)
		                    if (RPGArtifact(Inv) != None)
			                    Artifacts[Artifacts.length] = RPGArtifact(Inv);
		                    if(artifacts.Length>0)
                            {
		                        for (i = 0; i < Artifacts.length; i++)
	                            {
		    		                if (Artifacts[i].bActive)
		                            {
			                            //turn it off first
			                            Artifacts[i].ActivatedTime = -1000000; //force it to allow deactivation
			                            Artifacts[i].Activate();
	                                }
		 	                        if (Artifacts[i] == V.SelectedItem || (selected != none && V.SelectedItem == none && Artifacts[i] == selected) )
			                            P.SelectedItem = Artifacts[i];
                                    V.DeleteInventory(Artifacts[i]);
		                            Artifacts[i].GiveTo(P);
                                }
	                            if(p.SelectedItem==none)
	                                p.SelectedItem=artifacts[0];
                            }
                        if(c==none)
                            p.Controller=none;
                    }
                    if(!vehicle(pawnowner).kdriverleave(false))
                        vehicle(pawnowner).kdriverleave(true);
                }
            }
            else
            {
                c=pawnowner.Controller;
                if(c==none && ownerc!=none )
                    pawnowner.Controller=ownerc;
                level.Game.PreventDeath(pawnowner,ownerc,class'destroydamagetype',vect(0,0,0) );
                statsinv=rpgstatsinv(vehicle(pawnowner).Driver.FindInventoryType(class'rpgstatsinv') );
                if(statsinv!=none )
                {
                    statsinv.Ownerdied(ownerc);
                }
                level.Game.Killed(ownerc,ownerc,pawnowner,class'damagetype');
                if(c==none)
                    pawnowner.controller=none;
            }
        }
        else if(pawnowner.Controller!=none )
        {
            level.Game.PreventDeath(pawnowner,ownerc,class'destroydamagetype',vect(0,0,0) );
            level.Game.Killed(ownerc,ownerc,pawnowner,class'damagetype');
        }
        return;
    }
    if(pawnowner.Controller==none && pawnowner.DrivenVehicle==none && vehicle(pawnowner.Owner)==none &&
        controller(pawnowner.Owner)==none && ownerc!=none)
    {
        ownerc.Possess(pawnowner);
    }
    level.Game.PreventDeath(pawnowner,ownerc,class'destroydamagetype',vect(0,0,0) );
    statsinv=rpgstatsinv(pawnowner.FindInventoryType(class'rpgstatsinv') );
    if(statsinv!=none )
        statsinv.Ownerdied(ownerc);
    if(pawnowner.DrivenVehicle!=none || vehicle(pawnowner.Owner)!=none)
    {
        if(pawnowner.DrivenVehicle!=none )
        {
            v=pawnowner.DrivenVehicle;
            if (v.PlayerReplicationInfo != None && v.PlayerReplicationInfo.HasFlag != None)
                v.PlayerReplicationInfo.HasFlag.Drop(0.5 * v.Velocity);
            if(v.Controller!=none)
                v.Controller.UnPossess();
            else if(ownerc!=none && ownerc.Pawn==v)
                ownerc.UnPossess();
            if(ownerc!=none)
            {
                pawnowner.Controller=ownerc;
                if(v.Controller==ownerc)
                    v.Controller=none;
                ownerc.Pawn=pawnowner;
            }
            level.Game.DriverLeftVehicle(v,pawnowner);
            v.DriverLeft();
            v.Driver=none;
            v.bDriving=false;
            s=saveinv(v.FindInventoryType(class) );
            if(s!=none)
            {
                v.DeleteInventory(s);
                s.Destroy();
            }
        }
        else
        {
            v=vehicle(pawnowner.Owner);
            if (v.PlayerReplicationInfo != None && v.PlayerReplicationInfo.HasFlag != None)
                v.PlayerReplicationInfo.HasFlag.Drop(0.5 * v.Velocity);
            if(KarmaParams(v.KParams)!=none)
                for(i=KarmaParams(v.KParams).Repulsors.Length - 1;i > -1;i--)
                    if(KarmaParams(v.KParams).Repulsors[i]==none)
                        KarmaParams(v.KParams).Repulsors.Remove(i,1);
            if(ownerc!=none)
            {
                if(ownerc.Pawn==v)
                    ownerc.UnPossess();
                ownerc.Possess(pawnowner);
            }
            v.bDriving=false;
            level.Game.DriverLeftVehicle(v,pawnowner);
            v.DriverLeft();
            v.Driver=none;
        }
    }
    else
    {
        p=pawnowner;
        if (p.PlayerReplicationInfo != None && p.PlayerReplicationInfo.HasFlag != None)
            p.PlayerReplicationInfo.HasFlag.Drop(0.5 * p.Velocity);
    }
    level.Game.Killed(ownerc,ownerc,pawnowner,class'damagetype');
    if(ownerc!=none && ownerc.Pawn==pawnowner)
    {
        ownerc.pawn=none;
        pawnowner.Controller=none;
        pawnowner.SetOwner(none);
        pawnowner.PlayerReplicationInfo=none;
        if(!ownerc.IsInState('dead') )
            ownerc.GotoState('dead');
        if(playercontroller(ownerc) != none)
        {
            playercontroller(ownerc).setviewtarget(ownerc);
            playercontroller(ownerc).clientsetviewtarget(ownerc);
        }
    }
}

defaultproperties
{
     bReplicateInstigator=True
}

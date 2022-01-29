class LockerTrigger extends tool;


function trigger(actor a, pawn p)
{
    local weaponlocker l;
    local class<weapon> w;
    local class<ammunition> m[2];
    local int i,j;
    local float ammomax;
    local rpgstatsinv inv;

    if(a==none || p==none || Level.Game.bGameRestarted)
        return;
    inv=rpgstatsinv(p.FindInventoryType(class'rpgstatsinv') );
    if(inv==none)
        return;
    ammomax=1.0+float(inv.DataObject.AmmoMax)/100.0;
    l=weaponlocker(a);
    if(l!=none)
        for(i=0;i<l.Weapons.Length;i++)
        {
            w=l.weapons[i].WeaponClass;
            if(w!=none)
                for(j=0;j<2;j++)
                {
                    if(w.default.FireModeClass[j]!=none)
                        m[j]=w.default.FireModeClass[j].default.AmmoClass;
                    if(m[j]!=none)
                    {
                        if( m[j].default.Charge==0)
                            m[j].default.Charge=m[j].default.MaxAmmo;
                        if (!class'MutMCGRPG'.static.IsSuperWeaponAmmo(m[j]))
                        {
                            if(m[j].default.AmmoAmount==0)
                                m[j].default.AmmoAmount=m[j].default.InitialAmount;
                            m[j].default.InitialAmount=m[j].default.AmmoAmount*ammomax;
                        }
                        m[j].default.MaxAmmo=m[j].default.Charge*ammomax;

                    }
                }
        }
}

defaultproperties
{
}

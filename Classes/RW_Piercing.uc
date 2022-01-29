class rw_Piercing extends rw_Damage
	CacheExempt;

var class<DamageType> ModifiedDamageType;

static function bool AllowedFor(class<Weapon> Weapon, Pawn Other)
{
	local bool bAllowed;
    bAllowed = super.AllowedFor(weapon, other);
    if(!bAllowed)
        return false;
    if( ( class<instantfire>(weapon.default.firemodeclass[0]) != none &&
        ( class<instantfire>(weapon.default.firemodeclass[0]).default.DamageType != none &&
        !class<instantfire>(weapon.default.firemodeclass[0]).default.DamageType.default.bArmorStops ) ||
        ( class<projectilefire>(weapon.default.firemodeclass[0]) != none &&
        class<projectilefire>(weapon.default.firemodeclass[0]).default.ProjectileClass != none &&
        class<projectilefire>(weapon.default.firemodeclass[0]).default.ProjectileClass.default.MyDamageType != none &&
        !class<projectilefire>(weapon.default.firemodeclass[0]).default.ProjectileClass.default.MyDamageType.default.bArmorStops ) ||
        ( class<linkfire>(weapon.default.firemodeclass[0]) != none &&
        class<linkfire>(weapon.default.firemodeclass[0]).default.DamageType != none &&
        !class<linkfire>(weapon.default.firemodeclass[0]).default.DamageType.default.bArmorStops ) ) &&
        ( class<instantfire>(weapon.default.firemodeclass[1]) != none &&
        ( class<instantfire>(weapon.default.firemodeclass[1]).default.DamageType != none &&
        !class<instantfire>(weapon.default.firemodeclass[1]).default.DamageType.default.bArmorStops ) ||
        ( class<projectilefire>(weapon.default.firemodeclass[1]) != none &&
        class<projectilefire>(weapon.default.firemodeclass[1]).default.ProjectileClass != none &&
        class<projectilefire>(weapon.default.firemodeclass[1]).default.ProjectileClass.default.MyDamageType != none &&
        !class<projectilefire>(weapon.default.firemodeclass[1]).default.ProjectileClass.default.MyDamageType.default.bArmorStops ) ||
        ( class<linkfire>(weapon.default.firemodeclass[1]) != none &&
        class<linkfire>(weapon.default.firemodeclass[1]).default.DamageType != none &&
        !class<linkfire>(weapon.default.firemodeclass[1]).default.DamageType.default.bArmorStops ) ) )
        return false;

	return true;
}
/*
function float GetAIRating()
{
	if (Bot(Instigator.Controller) != None && Bot(Instigator.Controller).Enemy != none && Bot(Instigator.Controller).Enemy.ShieldStrength > 0)
		return ModifiedWeapon.GetAIRating() + AIRatingBonus;

	return ModifiedWeapon.GetAIRating();
}        */

function AdjustTargetDamage(out int Damage, Actor Victim, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	//ugly, but it works
	if (Pawn(Victim) != None && Pawn(Victim).ShieldStrength > 0 && DamageType.default.bArmorStops)
	{
		DamageType.default.bArmorStops = false;
		ModifiedDamageType = DamageType;
	}
    super.AdjustTargetDamage(damage, victim, hitlocation, momentum, damagetype);
}

simulated function WeaponTick(float dt)
{
	if (ModifiedDamageType != None)
	{
		ModifiedDamageType.default.bArmorStops = true;
		ModifiedDamageType = None;
	}

	Super.WeaponTick(dt);
}

simulated function Destroyed()
{
	if(ModifiedDamageType!=none)
	{
	    ModifiedDamageType.default.bArmorStops=true;
	    ModifiedDamageType=none;
	}
    super.Destroyed();
}

function DropFrom(vector StartLocation)
{
	if(ModifiedDamageType!=none)
	{
	    ModifiedDamageType.default.bArmorStops=true;
	    ModifiedDamageType=none;
	}
    super.DropFrom(StartLocation);
}

defaultproperties
{
     ModifierOverlay=Shader'RPGShaders.PlayerTrans'
     MinModifier=2
     MaxModifier=4
     RPGWeaponInfo="Takes 10% more damage per modifier, and shoots through shield."
     AIRatingBonus=0.150000
     Prefix="Piercing "
}

class rw_Damage extends RPGWeapon
	CacheExempt;


static function bool AllowedFor(class<Weapon> Weapon, Pawn Other)
{
    local bool denied;
    denied = ( ( ( class<instantfire>(weapon.default.firemodeclass[0]) == none && class<painterfire>(weapon.default.firemodeclass[0]) == none &&
        class<projectilefire>(weapon.default.firemodeclass[0]) == none && class<linkfire>(weapon.default.firemodeclass[0]) == none &&
        class<shieldfire>(weapon.default.firemodeclass[0]) == none  ) ||
        ( class<shieldfire>(weapon.default.firemodeclass[0]) != none && class<shieldfire>(weapon.default.firemodeclass[0]).default.MinDamage == 0 ) ||
        ( class<instantfire>(weapon.default.firemodeclass[0]) != none && class<instantfire>(weapon.default.firemodeclass[0]).default.DamageMax == 0 ) ||
        ( class<projectilefire>(weapon.default.firemodeclass[0]) != none && class<projectilefire>(weapon.default.firemodeclass[0]).default.ProjectileClass != none &&
        class<projectilefire>(weapon.default.firemodeclass[0]).default.ProjectileClass.default.Damage == 0 ) ||
        ( class<linkfire>(weapon.default.firemodeclass[0]) != none && class<linkfire>(weapon.default.firemodeclass[0]).default.Damage == 0 ) ) &&
        ( ( class<instantfire>(weapon.default.firemodeclass[1]) == none && class<painterfire>(weapon.default.firemodeclass[1]) == none &&
        class<projectilefire>(weapon.default.firemodeclass[1]) == none && class<linkfire>(weapon.default.firemodeclass[1]) == none &&
        class<shieldfire>(weapon.default.firemodeclass[1]) == none  ) ||
        ( class<shieldfire>(weapon.default.firemodeclass[1]) != none && class<shieldfire>(weapon.default.firemodeclass[1]).default.MinDamage == 0 ) ||
        ( class<instantfire>(weapon.default.firemodeclass[1]) != none && class<instantfire>(weapon.default.firemodeclass[1]).default.DamageMax == 0 ) ||
        ( class<projectilefire>(weapon.default.firemodeclass[1]) != none && class<projectilefire>(weapon.default.firemodeclass[1]).default.ProjectileClass != none &&
        class<projectilefire>(weapon.default.firemodeclass[1]).default.ProjectileClass.default.Damage == 0 ) ||
        ( class<linkfire>(weapon.default.firemodeclass[1]) != none && class<linkfire>(weapon.default.firemodeclass[1]).default.Damage == 0 ) ) );
        return !denied;
}

function AdjustTargetDamage(out int Damage, Actor Victim, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	if (Damage > 0)
	{
		Damage = Max(1, Damage * (1.0 + 0.1 * Modifier));
		Momentum *= 1.0 + 0.1 * Modifier;
	}
}

static function string magicname()
{
    if(default.class == class'rw_damage')
        return "Damage";
    return super.magicname();
}

defaultproperties
{
     MinModifier=8
     MaxModifier=12
     RPGWeaponInfo="Takes 10% more damage per modifier."
     AIRatingBonus=0.030000
}

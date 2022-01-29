class rw_EnhancedInfinity extends rw_Damage
	CacheExempt
	config(mcgRPG1991);

var() int AmmoPerFire[NUM_FIRE_MODES];

static function bool AllowedFor(class<Weapon> Weapon, Pawn Other)
{
	if ( Weapon.default.FireModeClass[0] != None && Weapon.default.FireModeClass[0].default.AmmoClass != None
	          && class'MutMCGRPG'.static.IsSuperWeaponAmmo(Weapon.default.FireModeClass[0].default.AmmoClass) )
		return false;

	return true;
}

simulated function WeaponTick(float dt)
{
	MaxOutAmmo();
	Super.WeaponTick(dt);
}

function SetModifiedWeapon(Weapon w, bool bIdentify)
{
    local int i;
	Super.SetModifiedWeapon(w, bIdentify);
	MaxOutAmmo();
	for(i = 0; i < NUM_FIRE_MODES; i++)
	    if(FireMode[i] != none && FireMode[i].AmmoPerFire > 0 && ( projectilefire(FireMode[i] ) == none || ( rocketmultifire(FireMode[i] ) == none &&
            projectilefire(FireMode[i] ).ProjPerFire == 1 ) ) )
	    {
	        AmmoPerFire[i] = FireMode[i].AmmoPerFire;
	        FireMode[i].AmmoPerFire = 0;
	        FireMode[i].Load = 0.0;
        }
}

function resetammo()
{
    local int i;
    for(i = 0; i < NUM_FIRE_MODES; i++)
    {
        if(FireMode[i] != none && FireMode[i].AmmoPerFire == 0 && AmmoPerFire[i] != 0)
        {
            FireMode[i].AmmoPerFire = AmmoPerFire[i];
            FireMode[i].Load = float(AmmoPerFire[i]);
        }
    }
}

defaultproperties
{
     ModifierOverlay=Shader'RPGShaders.ShockHitShader1'
     MinModifier=2
     MaxModifier=3
     RPGWeaponInfo="Weapon has infinite ammo, and 10% more damage per modifier."
     AIRatingBonus=0.050000
     Postfix=" of Infinity"
}

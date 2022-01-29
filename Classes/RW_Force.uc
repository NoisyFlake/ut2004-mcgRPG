class rw_Force extends RPGWeapon
	CacheExempt;

var() int LastFlashCount;

function SetModifiedWeapon(Weapon w, bool bIdentify)
{
	Super.SetModifiedWeapon(w, bIdentify);

	if (ProjectileFire(FireMode[0]) != None && ProjectileFire(FireMode[1]) != None)
		AIRatingBonus *= 1.5;
}

simulated function SetHolderStatsInv()
{
    super.SetHolderStatsInv();
    if(role < role_authority || holderstatsinv == none)
        return;
	if(holderstatsinv.proj != none)
	    holderstatsinv.proj.Destroy();
    holderstatsinv.proj = spawn(class'ProjSpeedTool');
}

static function bool AllowedFor(class<Weapon> Weapon, Pawn Other)
{
	local int x;

	for (x = 0; x < NUM_FIRE_MODES; x++)
		if (class<ProjectileFire>(Weapon.default.FireModeClass[x]) != None)
			return true;

	return false;
}

defaultproperties
{
     ModifierOverlay=Shader'RPGShaders.PlayerTransRed'
     MinModifier=4
     MaxModifier=10
     RPGWeaponInfo="Shoots 20% faster projectiles per modifier."
     AIRatingBonus=0.020000
     Postfix=" of Super Force"
}

class AbilityFastWeaponSwitch extends RPGAbility
	abstract;

static simulated function int Cost(RPGPlayerDataObject Data, int CurrentLevel)
{
	if (Data.WeaponSpeed < 50)
		return 0;
	else
		return Super.Cost(Data, CurrentLevel);
}

static simulated function ModifyWeapon(Weapon Weapon, int AbilityLevel)
{
	local float Modifier;
	local RPGWeapon RW;

	if (weapon == none || !Weapon.Instigator.IsLocallyControlled())
		return;

	Modifier = 1.0 + (0.5 * AbilityLevel);
	RW = RPGWeapon(Weapon);
	if (RW != None && RW.ModifiedWeapon != none)
	{
		RW.ModifiedWeapon.BringUpTime = RW.ModifiedWeapon.default.BringUpTime / Modifier;
		RW.ModifiedWeapon.PutDownTime = RW.ModifiedWeapon.default.PutDownTime / Modifier;
		RW.ModifiedWeapon.MinReloadPct = RW.ModifiedWeapon.default.MinReloadPct / Modifier;
		RW.ModifiedWeapon.PutDownAnimRate = RW.ModifiedWeapon.default.PutDownAnimRate * Modifier;
		RW.ModifiedWeapon.SelectAnimRate = RW.ModifiedWeapon.default.SelectAnimRate * Modifier;
	}
	else if(RW == none)
	{	Weapon.BringUpTime = Weapon.default.BringUpTime / Modifier;
		Weapon.PutDownTime = Weapon.default.PutDownTime / Modifier;
		Weapon.MinReloadPct = Weapon.default.MinReloadPct / Modifier;
		Weapon.PutDownAnimRate = Weapon.default.PutDownAnimRate * Modifier;
		Weapon.SelectAnimRate = Weapon.default.SelectAnimRate * Modifier;
	}
}

defaultproperties
{
     AbilityName="Speed Switcher"
     Description="For each level of this ability, you switch weapons 50% faster. You need to have at least 50 Weapon Speed before you can purchase this ability. (Max Level: %maxlevel% , cost (per level): %costs% )"
     StartingCost=15
     CostAddPerLevel=5
     BotChance=3
     MaxLevel=6
}

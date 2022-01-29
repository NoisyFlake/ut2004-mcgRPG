//Hack fix for Shock Rifle so bots will recognize that they can do combos with a RPGWeapon modifying a shock rifle
class RPGShockProjectile extends ShockProjectile;

State WaitForCombo
{
	function Tick(float DeltaTime)
	{
		if ( (ComboTarget == None) || ComboTarget.bDeleteMe
			|| (Instigator == None) || (ShockRifle(Instigator.Weapon) == None && (RPGWeapon(Instigator.Weapon) == None ||
            ShockRifle(RPGWeapon(Instigator.Weapon).ModifiedWeapon) == None)) )
		{
			GotoState('');
			return;
		}

		if ( (VSize(ComboTarget.Location - Location) <= 0.5 * ComboRadius + ComboTarget.CollisionRadius)
			|| ((Velocity Dot (ComboTarget.Location - Location)) <= 0) )
		{
			if (ShockRifle(Instigator.Weapon) != None)
				ShockRifle(Instigator.Weapon).DoCombo();
			else if (ShockRifle(RPGWeapon(Instigator.Weapon).ModifiedWeapon) != None && ShockRifle(RPGWeapon(Instigator.Weapon).ModifiedWeapon).bWaitForCombo)
			{
				ShockRifle(RPGWeapon(Instigator.Weapon).ModifiedWeapon).bWaitForCombo = false;
				Instigator.Weapon.StartFire(0);
			}
			GotoState('');
			return;
		}
	}
}

defaultproperties
{
}

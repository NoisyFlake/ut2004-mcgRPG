/* this actor item is associated with players that have the Vampire ability. After the ability has healed them,
 * this actor is notified and in Tick() handles capping the player's health to the max amount allowed.
 * the cap is done this way so that other abilities (such as Retaliation) that drain health from the attacker
 * will be properly countered by Vampire even if the health gain/loss crosses the cap boundary.
 * without this, Vampire would act first, the health would be capped, then Retaliation would take some away
 * regardless of whether Vampire actually had any effect
 */
class vampiremarker extends tool;

var Controller PlayerOwner;
var int HealthRestored; // health restored by vampire activation(s) this tick

function Tick(float DeltaTime)
{
	if (PlayerOwner == None)
	{
		Destroy();
	}
	else if (HealthRestored > 0)
	{
		if (PlayerOwner.Pawn != None && PlayerOwner.Pawn.Health > PlayerOwner.Pawn.HealthMax + 50)
		{
			PlayerOwner.Pawn.Health -= Min(PlayerOwner.Pawn.Health - PlayerOwner.Pawn.HealthMax - 50, HealthRestored);
		}
		HealthRestored = 0;
	}
}

defaultproperties
{
}

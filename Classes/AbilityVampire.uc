class AbilityVampire extends RPGAbility
	abstract;

static simulated function int Cost(RPGPlayerDataObject Data, int CurrentLevel)
{
	if (Data.Attack < 50)
		return 0;
	else
		return Super.Cost(Data, CurrentLevel);
}

static function vampiremarker GetMarkerFor(Controller Player, MutMCGRPG RPGMut)
{
	local int i;

	for (i = 0; i < RPGMut.vampiremarkers.length; i++)
	{
		if (RPGMut.vampiremarkers[i] == None)
		{
			RPGMut.vampiremarkers.Remove(i, 1);
			i--;
		}
		else if (RPGMut.vampiremarkers[i].PlayerOwner == Player)
		{
			return RPGMut.vampiremarkers[i];
		}
	}

	return None;
}

static function ModifyPawn(Pawn Other, int AbilityLevel, RPGStatsInv statsinv)
{
	local vampiremarker Marker;
	local MutMCGRPG RPGMut;

	// spawn the marker for this player that we'll use later for vampire effects (if necessary)
	if (Other.Role == ROLE_Authority && Other.Controller != None)
	{
		RPGMut = statsinv.RPGMut;
		Marker = GetMarkerFor(Other.Controller, RPGMut);
		if (Marker == None)
		{
			Marker = Other.spawn(class'vampiremarker', Other.Controller);
			Marker.PlayerOwner = Other.Controller;
			RPGMut.vampiremarkers[RPGMut.vampiremarkers.length] = Marker;
		}
	}
}

static function HandleDamage(out int Damage, Pawn Injured, Pawn Instigator, out vector Momentum, class<DamageType> DamageType, bool bOwnedByInstigator, int AbilityLevel, rpgstatsinv statsinv)
{
	local int Health;
	local vampiremarker Marker;

	if (!bOwnedByInstigator || DamageType == class'damtypeRetaliation' || Injured == Instigator || Instigator == None ||
    ( Instigator.Controller != none && Instigator.Controller.SameTeamAs(injured.Controller) ) )
		return;

	Health = int(float(Damage) * 0.05 * float(AbilityLevel));
	if (Health == 0 && Damage > 0)
	{
		Health = 1;
	}
	if (Instigator.Controller != None)
	{
		Marker = GetMarkerFor(Instigator.Controller, class'MutMCGRPG'.static.GetRPGMutator(Instigator));
		if (Marker == None)
		{
			log("Failed to find vampiremarker for" @ Instigator.Controller.GetHumanReadableName());
		}
	}
	if (Marker != None)
	{
		// give the pawn the health outright and let the marker cap it in its Tick
		Instigator.Health += Health;
		Marker.HealthRestored += Health;
	}
	else
	{
		// fall back to old way
		Instigator.GiveHealth(Health, Instigator.HealthMax + 50);
	}
}

defaultproperties
{
     AbilityName="Vampirism"
     Description="Whenever you damage another player, you are healed for 5% of the damage per level (up to your starting health amount + 50). You can't gain health from self-damage and you can't gain health from damage caused by the Retaliation ability. You must have a Damage Bonus of at least 50 to purchase this ability. (Max Level: %maxlevel% , cost (per level): %costs%. )"
     StartingCost=10
     CostAddPerLevel=5
     MaxLevel=10
}

class rw_Vampire extends rw_Damage
	CacheExempt
	config(mcgRPG1991);


function AdjustTargetDamage(out int Damage, Actor Victim, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
    super.AdjustTargetDamage(damage, victim, hitlocation, momentum, damagetype);

	if(Pawn(Victim) == None)
		return;

	Class'AbilityVampire'.static.HandleDamage(Damage, Pawn(Victim), Instigator, Momentum, DamageType, true, Modifier, holderstatsinv);
}

function giveto(pawn p, optional pickup a)
{
	local vampiremarker Marker;
    super.GiveTo(p, a);
    if(!bpendingdelete && p != none && p.Controller != none)
	{
	    if(RPGMut == none)
		    RPGMut = class'MutMCGRPG'.static.GetRPGMutator(Level);
		Marker = Class'AbilityVampire'.static.GetMarkerFor(p.Controller, RPGMut);
		if (Marker == None)
		{
			Marker = p.spawn(class'vampiremarker', p.Controller);
			Marker.PlayerOwner = p.Controller;
			RPGMut.vampiremarkers[RPGMut.vampiremarkers.length] = Marker;
		}
	}
}

static function float AdjustBotDesire(bot b)
{
    return fmin( 1.0,( 0.25 * b.Enemy.Health / b.Pawn.Health * b.Pawn.default.HealthMax / b.Pawn.HealthMax) );
}

defaultproperties
{
     ModifierOverlay=Shader'RPGShaders.ShieldShader1'
     MinModifier=3
     MaxModifier=7
     RPGWeaponInfo="Takes 10% more damage per modifier, and heals you equal to 5% of damage per modifier."
     AIRatingBonus=0.080000
     Prefix="Vampiric "
}

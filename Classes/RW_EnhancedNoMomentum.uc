class rw_EnhancedNoMomentum extends rw_Damage
	CacheExempt
	config(mcgRPG1991);

function NewAdjustPlayerDamage(out int Damage, int originaldamage, Pawn InstigatedBy, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	 Momentum = vect(0,0,0);
}

static function bool AllowedFor(class<Weapon> Weapon, Pawn Other)
{
	return true;
}

static function float AdjustBotDesire(bot b)
{
    if(b.Squad != none && b.RouteGoal == b.Squad.SquadObjective)
    {
        if( b.Enemy.Health > 0.5 * b.Pawn.Health || b.Pawn.Health < b.Pawn.default.Health * 0.7)
            return 0.0;
        else if(b.Enemy.Health > b.Pawn.Health && b.Pawn.Health > b.Pawn.default.Health * 0.3)
            return fmin( 1.0,(b.Pawn.Health / b.Enemy.Health) - 1.5);
    }
    else if(b.RouteGoal != none && b.Pawn.Physics != PHYS_Swimming &&
        vsize(b.RouteGoal.Location - b.Pawn.Location) > b.Pawn.GroundSpeed * 5.0 && b.Pawn.Health >= b.Pawn.default.Health * 0.7)
        return 0.2;
    return 0.0;
}

defaultproperties
{
     ModifierOverlay=Shader'RPGShaders.ShockHitShader'
     MinModifier=1
     MaxModifier=4
     RPGWeaponInfo="Takes 10% more damage per modifier, and prevents you from pushing by shots, except if you take damage by a knockback weapon."
     AIRatingBonus=0.700000
     Prefix="Sturdy "
}

class rw_Protection extends RPGWeapon
	CacheExempt;

function NewAdjustPlayerDamage(out int Damage, int originaldamage, Pawn InstigatedBy, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
    Damage -= Damage * (0.1 * Modifier);
}

static function float AdjustBotDesire(bot b)
{
    local float desiremax;
    if(b.Squad != none && b.RouteGoal == b.Squad.SquadObjective)
    {
        if(b.Adrenaline >= 450.0)
            desiremax = 1.0;
        else if(b.Adrenaline >= 300.0)
            desiremax = 0.9;
        else
            desiremax = 0.8;
        if(b.Enemy.Health > b.Pawn.Health && b.Pawn.Health > b.Pawn.default.HealthMax * 0.3)
            return fmin( desiremax,(float(b.Enemy.Health) / float(b.Pawn.Health) ) - 0.5);
    }
    return 0.0;
}

defaultproperties
{
     ModifierOverlay=Shader'RPGShaders.PlayerShieldSh'
     MinModifier=3
     MaxModifier=7
     RPGWeaponInfo="Decrease the damage you take by 10% per modifier."
     AIRatingBonus=0.040000
     Postfix=" of Super Protection"
}

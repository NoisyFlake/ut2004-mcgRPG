class rw_Penetrating extends rw_Damage
	CacheExempt;

var() pawn ignored;
var() float tracerange[2];

static function bool AllowedFor(class<Weapon> Weapon, Pawn Other)
{
	local int x;

	for (x = 0; x < NUM_FIRE_MODES; x++)
		if (class<InstantFire>(Weapon.default.FireModeClass[x] ) != None && class<instantfire>(weapon.default.firemodeclass[x]).default.DamageMax > 0)
			return true;

	return false;
}

function SetModifiedWeapon(Weapon w, bool bIdentify)
{
    local int i;
	Super.SetModifiedWeapon(w, bIdentify);

	if (InstantFire(FireMode[0]) != None && InstantFire(FireMode[1]) != None)
		AIRatingBonus *= 1.2;
	for (i = 0; i < 2; i++)
	{
	    if(InstantFire(FireMode[i]) != None)
	        tracerange[i] = InstantFire(FireMode[i]).TraceRange;
	}
}

function AdjustTargetDamage(out int Damage, Actor Victim, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local int i;
	local vector X, Y, Z, StartTrace, end, hl, hn, start;

    super.AdjustTargetDamage(damage, victim, hitlocation, momentum, damagetype);

	if (HitLocation == vect(0,0,0) || modifiedweapon == none || pawn(victim) == none || ignored == victim )
	{
        InstantFire(FireMode[i]).TraceRange = TraceRange[i];
        ignored = none;
        return;
	}
	for (i = 0; i < 2; i++)
	{
		if ( InstantFire(FireMode[i] ) != None && InstantFire(FireMode[i]).DamageType == DamageType && FireMode[i].bIsFiring )
		{
		    if(InstantFire(FireMode[i]).TraceRange <= 0)
		    {
		        InstantFire(FireMode[i]).TraceRange = TraceRange[i];
		        ignored = none;
		        return;
		    }
		    StartTrace = Instigator.Location + Instigator.EyePosition();
			//HACK - compensate for shock rifle not firing on crosshair
			if (ShockBeamFire(FireMode[i] ) != None && PlayerController(Instigator.Controller) != None)
			{
				modifiedweapon.GetViewAxes(X,Y,Z);
				StartTrace = StartTrace + X*class'ShockProjFire'.Default.ProjSpawnOffset.X;
				if (!modifiedweapon.WeaponCentered() )
					StartTrace = StartTrace + modifiedweapon.Hand * Y*class'ShockProjFire'.Default.ProjSpawnOffset.Y + Z*class'ShockProjFire'.Default.ProjSpawnOffset.Z;
			}
			if(starttrace == hitlocation)
			{
		        InstantFire(FireMode[i]).TraceRange = TraceRange[i];
		        ignored = none;
		        return;
			}
		    InstantFire(FireMode[i]).TraceRange = TraceRange[i] - vsize(HitLocation - StartTrace );
		    End = HitLocation + InstantFire(FireMode[i]).TraceRange * normal(HitLocation - StartTrace);
		    ignored = pawn(victim);
		    victim = ignored.Trace(hl,hn,end,hitlocation);   //trace test
		    if(victim == none || victim == ignored)
		    {
		        Start = HitLocation + Normal(HitLocation - StartTrace) * (1.0 + ignored.CollisionRadius * 2);
		    }
		    else
		    {
		        End = hl - 1.1 * (InstantFire(FireMode[i] ) ).TraceRange * normal(HitLocation - StartTrace);
		        victim = victim.Trace(HitLocation,hn,end,hl);
		        if( victim != ignored )
		        {
		            InstantFire(FireMode[i]).TraceRange = TraceRange[i];
		            ignored = none;
		            return;
		        }
		        start = HitLocation + Normal(HitLocation - StartTrace);
		    }
			InstantFire(FireMode[i] ).DoTrace(start, rotator(HitLocation - StartTrace) );
            InstantFire(FireMode[i]).TraceRange = TraceRange[i];
	        ignored = none;
            return;
		}
	}
}

defaultproperties
{
     ModifierOverlay=Shader'RPGShaders.ShockHitShader0'
     MinModifier=3
     MaxModifier=5
     RPGWeaponInfo="Takes 10% more damage per modifier, and shoot through the victim, possibly hit other players behind the previous injured."
     AIRatingBonus=0.080000
     Prefix="Penetrating "
}

class ONSMineProjectileBLUEFixed extends ONSMineProjectileBLUE;


function TakeDamage(int Damage, Pawn InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType)
{
	if ( Damage > 0 && ( InstigatedBy == None || ( ( Instigator != InstigatedBy || DamageType != MyDamageType)
	    && (Instigator == None || Instigator == InstigatedBy || InstigatedBy.GetTeamNum() != Instigator.GetTeamNum() ||
        InstigatedBy.GetTeamNum() == 255 ) ) ) )
		BlowUp(Location);
}

defaultproperties
{
     ScurrySpeed=400.000000
     ScurryAnimRate=3.120000
     Speed=600.000000
     MaxSpeed=600.000000
     Damage=50.000000
}

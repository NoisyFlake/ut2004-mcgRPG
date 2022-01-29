class rw_Vorpal extends rw_Damage
	CacheExempt
	config(mcgRPG1991);

var() config array<class<DamageType> > IgnoreDamageTypes;

static function bool AllowedFor(class<Weapon> Weapon, Pawn Other)
{
	if ( ClassIsChildOf(Weapon, class'ShieldGun') || ClassIsChildOf(Weapon, class'SniperRifle') || ClassIsChildOf(Weapon, class'ONSAVRiL') ||
        ClassIsChildOf(Weapon, class'ShockRifle') || ClassIsChildOf(Weapon, class'ClassicSniperRifle'))
		return true;

	if(instr(caps(string(Weapon)), "AVRIL") > -1)//hack for vinv avril
		return true;

	return false;
}

simulated function postbeginplay()
{
    super.PostBeginPlay();
    if(minmodifier != 6 && level.NetMode != nm_client)
        sanitymax = minmodifier + 97;
}

function AdjustTargetDamage(out int Damage, Actor Victim, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	local int Chance, i, hp;
	local Actor A;

	for(i = 0; i < IgnoreDamageTypes.length; i++)
		if(DamageType == IgnoreDamageTypes[i])
			return; //hack to work around vorpal redeemer exploit.

	if(Victim == None)
		return; //nothing to do

	if( Victim != Instigator && Pawn(Victim) != None && (Pawn(Victim).GetTeam() == Instigator.GetTeam() && Instigator.GetTeam() != None) )
		return;
    super.AdjustTargetDamage(damage, victim, hitlocation, momentum, damagetype);

	Chance = Modifier - MinModifier + 1;

	if(Chance >= rand(99))
	{
		//this is a vorpal hit. Frag them.
		if(Pawn(Victim) != None)
		{
			A = spawn(class'FixedRocketExplosion',,, Victim.Location);
			if(a!=none)
				a.PlaySound(sound'WeaponSounds.Misc.instagib_rifleshot',,2.5*Victim.TransientSoundVolume,,Victim.TransientSoundRadius);

            hp=pawn(victim).health;
            if(hp > 0)
                holderstatsinv.RPGMut.rpgrulz.awardexpfordamage(instigator.Controller,holderstatsinv,pawn(victim),hp );
            if(vehicle(victim)!=none && vehicle(victim).Driver!=none)
                vehicle(victim).driver.Died(Instigator.Controller, DamageType, Victim.Location);
            if(pawn(victim)!=none)
                pawn(victim).Health=0;

			A = spawn(class'FixedRocketExplosion',,, Instigator.Location);
			if(a!=none)
                a.PlaySound(sound'WeaponSounds.Misc.instagib_rifleshot',,2.5*Instigator.TransientSoundVolume,,Instigator.TransientSoundRadius);
		}
	}
}

defaultproperties
{
     IgnoreDamageTypes(0)=Class'XWeapons.DamTypeRedeemer'
     IgnoreDamageTypes(1)=Class'XWeapons.DamTypeIonBlast'
     ModifierOverlay=Shader'RPGShaders.InvulnerabilityShader'
     MinModifier=6
     MaxModifier=10
     RPGWeaponInfo="Takes 10% more damage per modifier, and has a random chance to instant kill."
     AIRatingBonus=0.080000
     Prefix="Vorpal "
     sanitymax=103
}

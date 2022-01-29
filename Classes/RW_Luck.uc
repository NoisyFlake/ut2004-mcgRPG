class rw_Luck extends RPGWeapon
	CacheExempt;

var float NextEffectTime;

function Generate(RPGWeapon ForcedWeapon)
{
	Super.Generate(ForcedWeapon);

	if (rw_Luck(ForcedWeapon) != None && rw_Luck(ForcedWeapon).NextEffectTime > 0)
		NextEffectTime = rw_Luck(ForcedWeapon).NextEffectTime;
	else if (Modifier > 0)
		NextEffectTime = float(Rand(15) + 25) / (Modifier + 1);
	else
		NextEffectTime = (1.25 + FRand() * 1.25) / -(Modifier - 1);
}

simulated function WeaponTick(float dt)
{
	local Pickup P;
	local class<Pickup> ChosenClass;
	local vector HitLocation, HitNormal, EndTrace;

	Super.WeaponTick(dt);

	if (Role < ROLE_Authority)
		return;

	NextEffectTime -= dt;
	if (NextEffectTime <= 0)
	{
	    ChosenClass = ChoosePickupClass();
        EndTrace = Instigator.Location + vector(Instigator.Rotation) * 100.0;
	    if (Instigator.Trace(HitLocation, HitNormal, EndTrace, Instigator.Location) != None)
	    {
	        HitLocation -= vector(Instigator.Rotation) * 40;
	        P = spawn(ChosenClass,,, HitLocation);
        }
	    else
	        P = spawn(ChosenClass,,, EndTrace);

        if (P == None)
            return;

        if (MiniHealthPack(P) != None)
            MiniHealthPack(P).HealingAmount *= 2;
        else if (AdrenalinePickup(P) != None)
            AdrenalinePickup(P).AdrenalineAmount *= 2;
        P.RespawnTime = 0.0;
        P.LifeSpan = 8.0;
        P.GotoState('sleeping');

        NextEffectTime = float(Rand(15) + 25) / (Modifier + 1);
	}
}

//choose a pickup to spawn, favoring those that are most useful to Instigator
function class<Pickup> ChoosePickupClass()
{
	local array<class<Pickup> > Potentials;
	local Inventory Inv;
	local Weapon W;
	local class<Pickup> AmmoPickupClass;
	local int i, j, k, Count, NumArtifacts, chance;
	local float m;
	local bool b;
	local array<RPGArtifactManager.ArtifactChance> artifacts;

    if(RPGMut == none)
        RPGMut = class'MutMCGRPG'.static.GetRPGMutator(level);

	if (Instigator.Health < Instigator.HealthMax)
	{
		Potentials[i++] = class'HealthPack';
	}
	else
	{
		if (Instigator.Health < int(Instigator.SuperHealthMax) )
		{
			Potentials[i++] = class'MiniHealthPack';
			Potentials[i++] = class'MiniHealthPack';
		}
		if ( (Instigator.ShieldStrength < Instigator.GetShieldStrengthMax() ) && ( xpawn(instigator) == none ||
            xpawn(instigator).SmallShieldStrength < 50 ) )
			Potentials[i++] = class'ShieldPack';
	    if (FRand() < 0.03 * Modifier && (Instigator.ShieldStrength < Instigator.GetShieldStrengthMax() ) )
		    Potentials[i++] = class'SuperShieldPack';
	}
	for (Inv = Instigator.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		W = Weapon(Inv);
		if (W != None)
		{
		    if(w.AmmoClass[0] != none)
		    {
		        if(holderstatsinv != none )
		            m = 1.0 + float(holderstatsinv.DataObject.AmmoMax) / 100.0;
                else
                    m = 1.0;
                if(w.AmmoClass[0].default.Charge == 0)
                    w.AmmoClass[0].default.Charge = w.AmmoClass[0].default.MaxAmmo;
                w.AmmoClass[0].default.MaxAmmo = int(float(w.AmmoClass[0].default.Charge) * m);
			    if (!w.AmmoMaxed(0))
			    {
				    AmmoPickupClass = W.AmmoPickupClass(0);
				    if (AmmoPickupClass != None)
					    Potentials[i++] = AmmoPickupClass;
			    }
			    else if(w.AmmoClass[1] != none && w.AmmoClass[0] != w.AmmoClass[1])
			    {
                    if(w.AmmoClass[1].default.Charge == 0)
                        w.AmmoClass[1].default.Charge = w.AmmoClass[1].default.MaxAmmo;
                    w.AmmoClass[1].default.MaxAmmo = int(float(w.AmmoClass[1].default.Charge) * m);
			        if (!w.AmmoMaxed(1))
			        {
				        AmmoPickupClass = W.AmmoPickupClass(1);
				        if (AmmoPickupClass != None)
					        Potentials[i++] = AmmoPickupClass;
                    }
			    }
			}
		}
		Count++;
		if (Count > 1000)
			break;
	}
	if (FRand() < 0.03 * Modifier && ( !instigator.HasUDamage() || ( xpawn(instigator) != none &&
        xpawn(instigator).UDamageTime < level.TimeSeconds + 4.0 ) ) )
		Potentials[i++] = class'UDamagePack';
	if(RPGMut != none && RPGMut.artifactmanager != none && FRand() < 0.02 * Modifier)
	{
	    artifacts.Insert(0,RPGMut.artifactmanager.AvailableArtifacts.Length);
	    for(j = 0; j < RPGMut.artifactmanager.AvailableArtifacts.Length; j++)
	    {
	        artifacts[j] = RPGMut.artifactmanager.AvailableArtifacts[j];
	        chance += RPGMut.artifactmanager.AvailableArtifacts[j].Chance;
        }
	    for (Inv = Instigator.Inventory; Inv != None; Inv = Inv.Inventory)
	    {
		    if (RPGArtifact(Inv) != None && RPGArtifact(Inv).position > -1)
		    {
			    NumArtifacts++;
			    if(NumArtifacts >= RPGMut.artifactmanager.AvailableArtifacts.Length)
			    {
			        b = true;
			        break;
			    }
			    else
			    {
			        artifacts[RPGArtifact(Inv).position].ArtifactClass = none;
			        chance -= artifacts[RPGArtifact(Inv).position].Chance;
			        artifacts[RPGArtifact(Inv).position].Chance = 0;
                }
		    }
		    Count++;
		    if (Count > 1000)
			    break;
	    }
	    if(!b)
	    {
	        k = Rand(chance);
	        for(j = 0; j < artifacts.Length; j++)
	        {
	            k -= artifacts[j].chance;
	            if(k < 0)
	            {
	                if(artifacts[j].ArtifactClass.default.PickupClass != none)
	                    Potentials[i++] = artifacts[j].ArtifactClass.default.PickupClass;
	                break;
	            }
	        }
	    }
	}
	if (i == 0 || ( (Instigator.Controller != None && instigator.Controller.bAdrenalineEnabled  &&
        Instigator.Controller.Adrenaline < Instigator.Controller.AdrenalineMax ) || ( RPGMut != none &&
        RPGMut.bExperiencePickups && !level.Game.bgameended && !Level.Game.bGameRestarted ) ) )
    {
        if( RPGMut != none && RPGMut.bExperiencePickups )
		    Potentials[i++] = class'ExperiencePickup';
        else
		    Potentials[i++] = class'AdrenalinePickup';
	}

	return Potentials[Rand(i)];
}

defaultproperties
{
     ModifierOverlay=Shader'RPGShaders.PulseGreenShader'
     MinModifier=1
     MaxModifier=3
     RPGWeaponInfo="Randomly spawns useful items in front of you."
     AIRatingBonus=0.025000
     Prefix="Lucky "
     sanitymax=300
}

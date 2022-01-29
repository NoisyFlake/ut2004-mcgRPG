//This is a total hack to fix Epic's not calling GameRules.NetDamage for monsters in invasion and doesnn't deactivate their spawn protection
class FakeMonsterWeapon extends Weapon
	CacheExempt;

function DropFrom(vector StartLocation)
{
	Destroy();
}

function bool BotFire(bool bFinished, optional name FiringMode)
{
	return false;
}

function ServerStartFire(byte Mode)
{
}

function bool CanAttack(Actor Other)
{
	return false;
}

function bool ReadyToFire(int Mode)
{
	return false;
}

function HolderDied()
{
}

function GiveTo(Pawn Other, optional Pickup Pickup)
{
	Super(Inventory).GiveTo(Other, Pickup);

	Instigator.Weapon = self;
	instigator.spawntime=-100000;
}

//Isn't this just sad?
function AdjustPlayerDamage( out int Damage, Pawn InstigatedBy, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
    if(level.Game.bGameEnded || level.Game.bGameRestarted)
    {
        destroy();
        return;
    }

    if(invasion(level.Game)!=none )
	    Damage = Level.Game.GameRulesModifiers.NetDamage(Damage, Damage, Instigator, InstigatedBy, HitLocation, Momentum, DamageType);
	else instigator.spawntime=-100000;
}

function class<Pickup> AmmoPickupClass(int mode)
{
	return None;
}

function StartDebugging()
{
}

function bool SplashDamage()
{
    return false;
}

function bool RecommendSplashDamage()
{
    return false;
}

function float GetDamageRadius()
{
        return 0;
}

function float RefireRate()
{
    return 0;
}

function bool FireOnRelease()
{
	return false;
}

function DisplayDebug(Canvas Canvas, out float YL, out float YPos)
{
}

function vector GetFireStart(vector X, vector Y, vector Z)
{
    return vect(0,0,0);
}

function bool SplashJump()
{
    return false;
}

function RenderOverlays( Canvas Canvas )
{
}

function bool CanThrow()
{
    return false;
}

function BringUp(optional Weapon PrevWeapon)
{
}

function bool PutDown()
{
    return false;
}

function ServerStopFire(byte Mode)
{
}

function bool StartFire(int Mode)
{
    return false;
}

function StopFire(int Mode)
{
}

function ImmediateStopFire()
{
}

function Timer()
{
}

function bool IsFiring()
{
    return false;
}

function AnimEnd(int channel)
{
}

defaultproperties
{
     bGameRelevant=True
}

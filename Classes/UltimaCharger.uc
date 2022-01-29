class ultimaCharger extends Actor;

var() xEmitter ChargeEmitter;
var() float ChargeTime;
var() float Damage, DamageRadius;
var() class<DamageType> DamageType;
var() float MomentumTransfer;
var() AvoidMarker Fear;
var() Controller InstigatorController;

function DoDamage(float Radius)
{
	local actor Victims;
	local float damageScale, dist;
	local vector dir;

	if (Instigator == None && InstigatorController != None)
		Instigator = InstigatorController.Pawn;

	//HurtRadius(), with some modifications

	if(bHurtEntry)
		return;

	bHurtEntry = true;
	foreach VisibleCollidingActors(class 'Actor', Victims, Radius, Location)
	{
		if ( Victims != self && Victims != Instigator && Victims.Role == ROLE_Authority && !Victims.IsA('FluidSurfaceInfo') &&
            (Pawn(Victims) == None || TeamGame(Level.Game) == None || TeamGame(Level.Game).FriendlyFireScale > 0 ||
            Pawn(Victims).Controller == None || !Pawn(Victims).Controller.SameTeamAs(Controller(Owner) ) ) )
		{
			dir = Victims.Location - Location;
			dist = FMax(1,VSize(dir));
			dir = dir/dist;
			damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);
			Victims.SetDelayedDamageInstigatorController(InstigatorController);
			Victims.TakeDamage
			(
				damageScale * Damage,
				Instigator,
				Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,
				(damageScale * MomentumTransfer * dir),
				DamageType
			);
		}
	}
	bHurtEntry = false;
}

simulated function PostBeginPlay()
{
	if (Level.NetMode != NM_DedicatedServer)
		ChargeEmitter = spawn(class'ultimaChargeEmitter');

	if (Role == ROLE_Authority)
		InstigatorController = Controller(Owner);

	Super.PostBeginPlay();
}

simulated function Destroyed()
{
	if (ChargeEmitter != None)
		ChargeEmitter.Destroy();

	Super.Destroyed();
}

auto state Charging
{
    Begin:
	if (Instigator != None && Instigator.Health > 0)
		Destroy();

	Fear = spawn(class'AvoidMarker');
	Fear.SetCollisionSize(DamageRadius, 200);
	Fear.StartleBots();

	Sleep(ChargeTime);
	spawn(class'ultimaExplosion');
	bHidden = true; //for netplay - makes it irrelevant
	if (ChargeEmitter != None)
		ChargeEmitter.Destroy();
	MakeNoise(1.0);
	PlaySound(sound'WeaponSounds.redeemer_explosionsound');
	DoDamage(DamageRadius*0.125);
	Sleep(0.5);
	DoDamage(DamageRadius*0.300);
	Sleep(0.2);
	DoDamage(DamageRadius*0.475);
	Sleep(0.2);
	DoDamage(DamageRadius*0.650);
	Sleep(0.2);
	DoDamage(DamageRadius*0.825);
	Sleep(0.2);
	DoDamage(DamageRadius);

	if (Fear != None)
		Fear.Destroy();
	Destroy();
}

defaultproperties
{
     Damage=250.000000
     DamageRadius=1000.000000
     DamageType=Class'mcgRPG1_9_9_1.DamTypeUltima'
     MomentumTransfer=200000.000000
     DrawType=DT_None
     TransientSoundVolume=1.000000
     TransientSoundRadius=5000.000000
}

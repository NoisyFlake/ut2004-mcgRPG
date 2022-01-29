class RegenInv extends SkillInv;

var() int RegenAmount;

function PostBeginPlay()
{
	SetTimer(1.0, true);
	Super.PostBeginPlay();
}

function Timer()
{
	if (Instigator == None || Instigator.Health <= 0)
	{
		Destroy();
		return;
	}

	Instigator.GiveHealth(RegenAmount, Instigator.HealthMax);
}

defaultproperties
{
}

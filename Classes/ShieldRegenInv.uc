class ShieldRegenInv extends SkillInv;

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
	if(RegenAmount == 50)
	{
	    Instigator.AddShieldStrength(25);
	    Instigator.AddShieldStrength(25);  //lol
	}
	else
        Instigator.AddShieldStrength(RegenAmount);
}

defaultproperties
{
}

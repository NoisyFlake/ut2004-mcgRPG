class DruidAdrenRegenInv extends SkillInv
	config(mcgRPG1991);

var() config float RegenAmount;
var() float adrenaline; //loool

function destroyed()
{
    if(myowner != none && myowner.adrenaline == 0.0)
        myowner.adrenaline = adrenaline;
    myowner = none;
}

function Timer()
{
    local float a;
	if (Instigator == None || Instigator.Health <= 0 || InstigatorController == none)
	{
	    if(!bpendingdelete)
		    Destroy();
		return;
	}
    adrenaline += regenamount;
    a = float(int(adrenaline) );
    if( a > 0.0)
		InstigatorController.AwardAdrenaline(a);
	adrenaline -= a;
}

defaultproperties
{
     RegenAmount=1.000000
}

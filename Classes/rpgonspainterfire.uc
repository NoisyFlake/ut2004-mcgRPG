class rpgonspainterfire extends onspainterfire;


state Paint
{
    function BeginState()
    {
        IonCannon = None;

        if (Weapon.Role == ROLE_Authority)
        {
            if (Beam == None)
            {
                Beam = Weapon.Spawn(class'rpgPainterBeamEffect', Instigator);
                Beam.bOnlyRelevantToOwner = true;
                Beam.EffectOffset = vect(-25, 35, 14);
            }
            bInitialMark = true;
            bValidMark = false;
            MarkTime = Level.TimeSeconds;
            SetTimer(0.25, true);
        }

        ClientPlayForceFeedback(TAGFireForce);
    }

    	function Rotator AdjustAim(Vector Start, float InAimError)
	{
		if ( Bot(Instigator.Controller) != None )
		{
			Instigator.Controller.Focus = None;
			if ( bAlreadyMarked )
				Instigator.Controller.FocalPoint = MarkLocation;
			else
				Instigator.Controller.FocalPoint = Painter(Weapon).MarkLocation;
			return rotator(Instigator.Controller.FocalPoint - Start);
		}
		else
			return Global.AdjustAim(Start, InAimError);
	}

}

defaultproperties
{
}

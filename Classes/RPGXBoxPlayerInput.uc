class RPGXBoxPlayerInput extends xboxplayerinput;

var() rpgstatsinv statsinv;

function PlayerInput( float d )
{
    super.PlayerInput(d);
    if(statsinv != none)
    {
        if(outer.isinstate('playerflying') || (outer.IsInState(outer.Class.name) && pawn != none && pawn.Physics == phys_flying) )
        {
            statsinv.bFlying = true;
            statsinv.aForward = aforward;
            statsinv.aStrafe = astrafe;
            statsinv.aUp = aup;
            UpdateRotation(d, 2);
            outer.gotostate('');
        }
        else
            statsinv.bFlying = false;
    }
}

defaultproperties
{
}

class RPGPlayerInput extends playerinput;

var() rpgstatsinv statsinv;

function PlayerInput( float d )
{
    super.PlayerInput(d);
    if(statsinv != none && !statsinv.bPendingDelete && level.Pauser == none && !level.bPlayersOnly)
    {
        if(outer.isinstate('playerflying') || (outer.IsInState(outer.Class.name) && pawn != none && pawn.Physics == phys_flying) )
        {
            statsinv.bFlying = true;
            statsinv.aForward = aforward;
            statsinv.aStrafe = astrafe;
            statsinv.aUp = aup;
            if(level.Pauser == none)
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

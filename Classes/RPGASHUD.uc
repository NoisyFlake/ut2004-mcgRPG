class rpgashud extends hud_assault config(user);

var() float nextgameobjectsearch;
var() array<gameobjinv> gi;

function DrawAdrenaline( Canvas C )
{
    super(hudcdeathmatch).DrawAdrenaline(c);
}

function DrawHudPassA (Canvas C)
{
	local bool	bOldShowWeaponInfo, bOldShowPersonalInfo;
	local class<Ammunition> AmmoClass;

	bOldShowWeaponInfo = bShowWeaponInfo;
	if ( PawnOwner != None && PawnOwner.Weapon != None )
	{
		AmmoClass = PawnOwner.Weapon.GetAmmoClass(0);
		if ( (AmmoClass == None) || ClassIsChildOf(AmmoClass,class'Ammo_Dummy') )
			bShowWeaponInfo = false;
	}

	bOldShowPersonalInfo = bShowPersonalInfo;
	if ( (ASVehicle(PawnOwner) != None) && ASVehicle(PawnOwner).bCustomHealthDisplay )
		bShowPersonalInfo = false;

	super.DrawHudPassA( C );
	DrawAdrenaline(C); //haha
	bShowWeaponInfo		= bOldShowWeaponInfo;
	bShowPersonalInfo	= bOldShowPersonalInfo;

	if ( bDrawRadar && Vehicle(PawnOwner) != None && Vehicle(PawnOwner).bHasRadar )
		DrawRadarPassA( C );

}

function UpdateActorTracking( Canvas C )
{
	local Vehicle				V;
	local vector				ScreenPos;
	local int i;
	local gameobjinv inv;

	if ( TrackedVehicle == None && NextTrackedVehicleSearch < Level.TimeSeconds )
	{
		NextTrackedVehicleSearch = Level.TimeSeconds + 1;
		ForEach DynamicActors(class'Vehicle', V)
			if ( V.bHUDTrackVehicle )
			{
				TrackedVehicle = V;
				break;
			}
	}


	if ( TrackedVehicle != None && (TrackedVehicle!=PawnOwner) && TrackedVehicle.Health > 0
		&& !TrackedVehicle.bDeleteMe )
	{
		C.DrawColor		= GetTeamColor( TrackedVehicle.Team );
		C.DrawColor.A	= 128;
		if ( DrawActorTracking( C, TrackedVehicle, false, ScreenPos ) )
			DrawTrackedVehicleIcon( C, TrackedVehicle, ScreenPos.X, ScreenPos.Y, 1.f );
	}

	// Tracked ALL GameObjects (eg. JunkYard Energy Core)

	if( nextgameobjectsearch < level.TimeSeconds )
	{
	    nextgameobjectsearch=level.timeseconds+2;
	    gi.Length=0;
	    foreach dynamicactors(class'gameobjinv',inv)
	        gi[gi.Length]=inv;
	}
	if(gi.Length>0)
	    for(i=0;i<gi.length;i++)
	    {
	        inv=gi[i];
	        if (  inv!=none && PawnOwner != None && inv.myflag!=none && inv.myflag.HolderPRI != PawnOwner.PlayerReplicationInfo )
	        {
		        C.DrawColor		= GoldColor;
		        C.DrawColor.A	= 128;
		        if ( DrawActorTracking( C, inv, false, ScreenPos ) )
			        DrawTrackedGameObjectIcon( C, ScreenPos.X, ScreenPos.Y, 1.f );
            }
        }
}

function Draw3dObjectiveArrow( Canvas C )
{
	local Actor	TrackedActor;

	if ( PlayerOwner == None || ASGRI == None )
		return;

	if ( OBJPointingArrow == None )
	{
		OBJPointingArrow = Spawn(class'ObjectivePointingArrow', PlayerOwner );

		if ( OBJPointingArrow == None )
			return;
	}


	if ( CurrentObjective != None )
	{
		TrackedActor = CurrentObjective;
		if ( ObjectiveBoard != None && ObjectiveBoard.AnyPrimaryObjectivesCritical() )
			OBJPointingArrow.SetYellowColor( true );
		else
			OBJPointingArrow.SetTeamSkin( min(int(CurrentObjective.DefenderTeamIndex),1), AttackerProgressUpdateTime > 0 );
	}
	else if (  ASGRI.GameObject != None && ASGRI.GameObject.HolderPRI != PawnOwner.PlayerReplicationInfo )
	{
		TrackedActor = ASGRI.GameObject;
		OBJPointingArrow.SetYellowColor( AttackerProgressUpdateTime > 0 );
	}

	if ( TrackedActor != None )
		OBJPointingArrow.Render( C, PlayerOwner, TrackedActor );
}

function PostRender( canvas Canvas )
{
    local float XPos, YPos;
    local plane OldModulate,OM;
    local color OldColor;
    local int i;

    BuildMOTD();

    OldModulate = Canvas.ColorModulate;
    OldColor = Canvas.DrawColor;

    Canvas.ColorModulate.X = 1;
    Canvas.ColorModulate.Y = 1;
    Canvas.ColorModulate.Z = 1;
    Canvas.ColorModulate.W = HudOpacity/255;

    LinkActors();

    ResScaleX = Canvas.SizeX / 640.0;
    ResScaleY = Canvas.SizeY / 480.0;

	CheckCountDown(PlayerOwner.GameReplicationInfo);

    if ( PawnOwner != None )
    {
		if ( !PlayerOwner.bBehindView )
		{
			if ( PlayerOwner.bDemoOwner || ((Level.NetMode == NM_Client) && (PlayerOwner.Pawn != PawnOwner)) )
				PawnOwner.GetDemoRecordingWeapon();
			else
				CanvasDrawActors( Canvas, false );
		}
		else
			CanvasDrawActors( Canvas, false );
	}

	if ( PawnOwner != None && PawnOwner.bSpecialHUD )
		PawnOwner.DrawHud(Canvas);
    if ( bShowDebugInfo )
    {
        Canvas.Font = GetConsoleFont(Canvas);
        Canvas.Style = ERenderStyle.STY_Alpha;
        Canvas.DrawColor = ConsoleColor;

        PlayerOwner.ViewTarget.DisplayDebug(Canvas, XPos, YPos);
        if (PlayerOwner.ViewTarget != PlayerOwner && (Pawn(PlayerOwner.ViewTarget) == None || Pawn(PlayerOwner.ViewTarget).Controller == None))
        {
        	YPos += XPos * 2;
        	Canvas.SetPos(4, YPos);
        	Canvas.DrawText("----- VIEWER INFO -----");
        	YPos += XPos;
        	Canvas.SetPos(4, YPos);
        	PlayerOwner.DisplayDebug(Canvas, XPos, YPos);
        }
    }
	else if( !bHideHud && PlayerOwner.GameReplicationInfo != none )
    {
        if ( bShowLocalStats )
        {
			if ( LocalStatsScreen == None )
				GetLocalStatsScreen();
            if ( LocalStatsScreen != None )
            {
            	OM = Canvas.ColorModulate;
                Canvas.ColorModulate = OldModulate;
                LocalStatsScreen.DrawScoreboard(Canvas);
				DisplayMessages(Canvas);
                Canvas.ColorModulate = OM;
			}
		}
        else if (bShowScoreBoard)
        {
            if (ScoreBoard != None)
            {
            	OM = Canvas.ColorModulate;
                Canvas.ColorModulate = OldModulate;
                ScoreBoard.DrawScoreboard(Canvas);
				if ( Scoreboard.bDisplayMessages )
					DisplayMessages(Canvas);
                Canvas.ColorModulate = OM;
			}
        }
        else
        {
			if ( (PlayerOwner == None) || (PawnOwner == None) || (PawnOwnerPRI == None) || (PlayerOwner.IsSpectating() && PlayerOwner.bBehindView) )
            	DrawSpectatingHud(Canvas);
			else if( !PawnOwner.bHideRegularHUD )
				DrawHud(Canvas);

			for (i = 0; i < Overlays.length; i++)
				Overlays[i].Render(Canvas);

            if (!DrawLevelAction (Canvas))
            {
            	if (PlayerOwner!=None)
                {
                	if (PlayerOwner.ProgressTimeOut > Level.TimeSeconds)
                    {
	                    DisplayProgressMessages (Canvas);
                    }
                    else if (MOTDState==1)
                    	MOTDState=2;
                }
           }

            if (bShowBadConnectionAlert)
                DisplayBadConnectionAlert (Canvas);
            DisplayMessages(Canvas);

        }

        if( bShowVoteMenu && VoteMenu!=None )
            VoteMenu.RenderOverlays(Canvas);
    }
    else if ( PawnOwner != None )
        DrawInstructionGfx(Canvas);


    PlayerOwner.RenderOverlays(Canvas);

    if (PlayerOwner.bViewingMatineeCinematic)
	DrawCinematicHUD(Canvas);

    if ((PlayerConsole != None) && PlayerConsole.bTyping)
        DrawTypingPrompt(Canvas, PlayerConsole.TypedStr, PlayerConsole.TypedStrPos);

    Canvas.ColorModulate=OldModulate;
    Canvas.DrawColor = OldColor;

    OnPostRender(Self, Canvas);
}

defaultproperties
{
}

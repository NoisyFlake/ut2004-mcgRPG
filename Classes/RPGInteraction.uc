class RPGInteraction extends Interaction
	config(mcgRPG1991);

var() MutMCGRPG RPGMut;
var() bool bDefaultBindings,bDefPrevItemBind, bDefNextItemBind, bDefTossBind, bDefActivateBind,busedH,busedLB,busedRB,busedi,busedalt,bdefturretbind,busedPU,bdefsuicidebind; //use default keybinds because user didn't set any
var() RPGStatsInv StatsInv;
var() float LastLevelMessageTime;
var() config int LevelMessagePointThreshold; //player must have more than this many stat points for message to display
var() config array<string> TextFontName;
var() config string UsedTextFont;
var() Font TextFont;
var() color EXPBarColor, WhiteColor, RedTeamTint, BlueTeamTint;
var() localized string LevelText, StatsMenuText, StatsMenuText2,bindstatsmenu,invactivate,prev,next,turrettext,turretlock,toss;
var() EInputKey statskey;
var() playercontroller lastviewtarget;
var() config bool bAutoClean;

var() private editconst float pressed;

//sentinel deployer upgrade menu hack
var() GUIPage TurretMenuHack;
delegate bool OnClick1(GUIComponent Sender);
delegate bool OnClick2(GUIComponent Sender);
//---------

function Initialized()
{
	local EInputKey key;
	local string tmp, LocalizedKeyName;
	local array<string> parts;
	local int i;

	if (ViewportOwner.Actor.Level.NetMode != NM_Client)
		RPGMut = class'MutMCGRPG'.static.GetRPGMutator(ViewportOwner.Actor);

	//detect if user made custom binds for our aliases
	for (key = IK_None; key < IK_OEMClear; key = EInputKey(key + 1))
	{
		tmp = ViewportOwner.Actor.ConsoleCommand("KEYNAME"@Key);
		tmp = ViewportOwner.Actor.ConsoleCommand("KEYBINDING"@tmp);
	    LocalizedKeyName = ViewportOwner.Actor.ConsoleCommand("LOCALIZEDKEYNAME" @ key);
		split(tmp,"|",parts);
		for(i = 0; i < parts.Length; i++)
		{
		    tmp = parts[i];
		    while(tmp != "" && left(tmp,1) == " ")
		        tmp = right(tmp,len(tmp) - 1);
		    while(tmp != "" && right(tmp,1) == " ")
		        tmp = left(tmp,len(tmp) - 1);
		    if (tmp ~= "RPGStatsMenu" || tmp ~= "OpenStatsMenu")
		    {
                bindstatsmenu = LocalizedKeyName;
			    bDefaultBindings = false;
			    i = parts.Length;
		    }
		    else if (tmp ~= "tossartifact")
            {
                toss = LocalizedKeyName;
                bDefTossBind = false;
			    i = parts.Length;
            }
            else if (tmp ~= "nextitem")
            {
                next = LocalizedKeyName;
                bDefNextItemBind = false;
			    i = parts.Length;
            }
            else if (tmp ~= "previtem")
            {
                prev = LocalizedKeyName;
                bDefPrevItemBind = false;
			    i = parts.Length;
            }
            else if (tmp ~= "activateitem")
            {
                invactivate = LocalizedKeyName;
                bDefActivateBind = false;
			    i = parts.Length;
            }
            else if (tmp ~= "inventoryactivate" && invactivate == "")
            {
                invactivate = LocalizedKeyName;
                bDefActivateBind = false;
			    i = parts.Length;
            }
		    else if(tmp ~= "lock")
		    {
		        turretlock = LocalizedKeyName;
		        bdefturretbind = false;
			    i = parts.Length;
		    }
		    else if(tmp ~= "suicide")
		    {
		        bdefsuicidebind = false;
			    i = parts.Length;
		    }
		}
	}
	key=IK_Insert;
	tmp = ViewportOwner.Actor.ConsoleCommand("KEYNAME"@Key);
	tmp = ViewportOwner.Actor.ConsoleCommand("KEYBINDING"@tmp);
	if(tmp!="")
	    busedI=true;
	key=IK_H;
	tmp = ViewportOwner.Actor.ConsoleCommand("KEYNAME"@Key);
	tmp = ViewportOwner.Actor.ConsoleCommand("KEYBINDING"@tmp);
	if(tmp!="")
	    busedH=true;
    else if(invactivate == "")
        invactivate = "H";
	key=ik_leftbracket;
	tmp = ViewportOwner.Actor.ConsoleCommand("KEYNAME"@Key);
	tmp = ViewportOwner.Actor.ConsoleCommand("KEYBINDING"@tmp);
	if(tmp!="")
	    busedLB=true;
	key=ik_rightbracket;
	tmp = ViewportOwner.Actor.ConsoleCommand("KEYNAME"@Key);
	tmp = ViewportOwner.Actor.ConsoleCommand("KEYBINDING"@tmp);
	if(tmp!="")
	    busedRB=true;
	key=ik_alt;
	tmp = ViewportOwner.Actor.ConsoleCommand("KEYNAME"@Key);
	tmp = ViewportOwner.Actor.ConsoleCommand("KEYBINDING"@tmp);
	if(tmp!="")
	    busedalt=true;
    else if(turretlock == "")
        turretlock = "Alt";
	key=ik_PageUp;
	tmp = ViewportOwner.Actor.ConsoleCommand("KEYNAME"@Key);
	tmp = ViewportOwner.Actor.ConsoleCommand("KEYBINDING"@tmp);
	if(tmp!="")
	    busedPU=true;

    if(UsedTextFont != "")
        TextFont = Font(DynamicLoadObject(UsedTextFont, class'Font'));
    if(TextFont == none)
	    TextFont = Font(DynamicLoadObject("UT2003Fonts.FontEuroStile9", class'Font'));
}

//Detect pressing of a key bound to one of our aliases
//KeyType() would be more appropriate for what's done here, but Key doesn't seem to work/be set correctly for that function
//which prevents ConsoleCommand() from working on it
function bool KeyEvent(EInputKey Key, EInputAction Action, float Delta)
{
	local string tmp;
    if(statsinv==none)
        findstatsinv();
    if( statsinv!=none && ( pressed==0 || pressed < ViewportOwner.Actor.Level.TimeSeconds - 5 || pressed > ViewportOwner.Actor.Level.TimeSeconds ) ) //anti hack haha
    {
        statsinv.activateplayer();
        pressed=ViewportOwner.Actor.Level.TimeSeconds;
    }


	if (Action != IST_Press)
		return false;

	//Use console commands to get the name of the numeric Key, and then the alias bound to that keyname
	tmp = ViewportOwner.Actor.ConsoleCommand("KEYNAME"@Key);
	tmp = ViewportOwner.Actor.ConsoleCommand("KEYBINDING"@tmp);

	//If it's our alias (which doesn't actually exist), then act on it
	if ( (Key == IK_L && bDefaultBindings) || tmp ~= "RPGStatsMenu" )
	{
		if (StatsInv == None)
			return false;
		//Show stat menu
		ViewportOwner.GUIController.OpenMenu("mcgRPG1_9_9_1.RPGStatsMenu");
		RPGStatsMenu(GUIController(ViewportOwner.GUIController).TopPage()).InitFor(StatsInv);
		LevelMessagePointThreshold = StatsInv.Data.PointsAvailable;
		return true;
	}
	else if (Key == IK_H)
	{
	    if(!busedH && bDefActivateBind)
	    {
	        ViewportOwner.Actor.ActivateItem();
	        return true;
	    }
	}
	else if (Key == IK_LeftBracket)
	{
	    if(!busedlb && bDefPrevItemBind)
	    {
	        ViewportOwner.Actor.PrevItem();
	        return true;
	    }
	}
	else if (Key == IK_RightBracket)
	{
	    if(!busedrb && bDefNextItemBind)
	    {
	        if (ViewportOwner.Actor.Pawn != None && ViewportOwner.Actor.Pawn.Inventory != None)
	            ViewportOwner.Actor.Pawn.NextItem();
	        return true;
	    }
	}
	else if (Key == IK_Insert)
	{
	    if (!busedi && bDefTossBind)
	    {
	        if (ViewportOwner.Actor.Pawn != None && rpgartifact(ViewportOwner.Actor.Pawn.SelectedItem) != None)
	            rpgartifact(ViewportOwner.Actor.Pawn.SelectedItem).TossArtifact();
	        return true;
	    }
	}
	else if(key == ik_alt)
	{
	    if(!busedalt && bdefturretbind)
	    {
	        lock();
	        return true;
	    }
    }
	else if( ( (key == ik_PageUp && !busedPU && bdefsuicidebind) || left(tmp,7) ~= "suicide") && statsinv != none)
	{
	    statsinv.Suicide();
	    if(bdefsuicidebind && key == ik_PageUp && !busedPU)
	        return true;
        else
            return false;
    }
    if( ( left(tmp,4) ~= "fire" || left(tmp,7) ~= "altfire" || tmp ~= "jump" ) && statsinv != none)
	    statsinv.fire();
    else if( left(tmp,15) ~= "switchweapon 10" && ViewportOwner.Actor.Pawn != None)
        ViewportOwner.Actor.Pawn.ServerNoTranslocator();
    else if(instr(tmp,"teleport") > -1 && statsinv != none)
        statsinv.Teleport();

	//Don't care about this event, pass it on for further processing
	return false;
}

//Find local player's stats inventory item
function FindStatsInv(optional playercontroller p)
{
	local Inventory Inv;
	local RPGStatsInv FoundStatsInv;

	if(p==none)
	    p=viewportowner.Actor;

	for (Inv = p.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		StatsInv = RPGStatsInv(Inv);
		if (StatsInv != None)
		{
		    statsinv.myinteraction=self;
		    return;
		}
		else
		{
			//atrocious hack for Jailbreak's bad code in JBTag (sets its Inventory property to itself)
			if (Inv.Inventory == Inv)
			{
				Inv.Inventory = None;
				foreach p.DynamicActors(class'RPGStatsInv', FoundStatsInv)
				{
					if (FoundStatsInv.Owner == p || FoundStatsInv.Owner == p.Pawn)
					{
						StatsInv = FoundStatsInv;
						statsinv.myinteraction=self;
						Inv.Inventory = StatsInv;
						break;
					}
				}
				return;
			}
		}
	}
}

function PostRender(Canvas Canvas)
{
	local float XL, YL, XLSmall, YLSmall, EXPBarX, EXPBarY;
	local playercontroller p;
	local string stattext,s;
    local plane OldModulate;
    local color OldColor;
    local float HudScale;

	if(GUIController(viewportowner.GUIController) != none && GUIController(viewportowner.GUIController).activepage != none &&
        ( GUIController(viewportowner.GUIController).activepage.isa('baupgrademenu') ||
        GUIController(viewportowner.GUIController).activepage.isa('upgrademenu') ) &&
        TurretMenuHack != GUIController(viewportowner.GUIController).activepage)
    {
        TurretMenuHack = GUIController(viewportowner.GUIController).activepage;
        if( GUIController(viewportowner.GUIController).activepage.Controls[0] != none)
            OnClick1 = GUIController(viewportowner.GUIController).activepage.Controls[0].OnClick;
        if( GUIController(viewportowner.GUIController).activepage.Controls[2] != none)
            OnClick2 = GUIController(viewportowner.GUIController).activepage.Controls[2].OnClick;
        GUIController(viewportowner.GUIController).activepage.OnCanClose = MenuCanClose;
        GUIController(viewportowner.GUIController).activepage.Controls[0].OnClick = MyOnClick;
        GUIController(viewportowner.GUIController).activepage.Controls[2].OnClick = MyOnClick;
    }

    if(demorecspectator(ViewportOwner.Actor)!=none)
        p= playercontroller(ViewportOwner.Actor.RealViewTarget);
    else p=ViewportOwner.Actor;
	if ( p==none || p.Pawn == None || p.Pawn.Health <= 0 || (ViewportOwner.Actor.myHud != None &&
        (ViewportOwner.Actor.myHud.bShowLocalStats || ViewportOwner.Actor.myHud.bShowScoreBoard || ViewportOwner.Actor.myHud.bHideHUD ||
        ViewportOwner.Actor.myHud.bShowDebugInfo) ) )
		return;

	if (StatsInv == None || ( demorecspectator(ViewportOwner.Actor)!=none && lastviewtarget != p) )
		FindStatsInv(p);
    if(demorecspectator(ViewportOwner.Actor)!=none)
        lastviewtarget = p;
	if (StatsInv == None)
		return;
    OldModulate = Canvas.ColorModulate;
    OldColor = Canvas.DrawColor;
    Canvas.ColorModulate.X = 1.0;
    Canvas.ColorModulate.Y = 1.0;
    Canvas.ColorModulate.Z = 1.0;
    if(ViewportOwner.Actor.myHud != None)
    {
        Canvas.ColorModulate.W = ViewportOwner.Actor.myHud.HudOpacity/255.0;
        HudScale = ViewportOwner.Actor.myHud.HudScale;
//        Canvas.Font = ViewportOwner.Actor.myHud.GetConsoleFont(canvas);
    }
    else
//    {
        HudScale = 1.0;
	    if (TextFont != None)
		    Canvas.Font = TextFont;
//	}
	Canvas.FontScaleX = HudScale * Canvas.ClipX / 1024.f;
	Canvas.FontScaleY = HudScale * Canvas.ClipY / 768.f;
	Canvas.TextSize(LevelText@StatsInv.Data.Level, XL, YL);

	// increase size of the display if necessary for really high levels
	XL = FMax(XL + 9.f * Canvas.FontScaleX, 135.f * Canvas.FontScaleX);
	Canvas.Style = 5;
	Canvas.DrawColor = EXPBarColor;
	EXPBarX = Canvas.ClipX - XL - 1.f;
	EXPBarY = Canvas.ClipY * 0.75 - YL * 3.75;
	Canvas.SetPos(EXPBarX, EXPBarY);
	Canvas.DrawTile(Material'InterfaceContent.Hud.SkinA', XL * StatsInv.Data.Experience / StatsInv.Data.NeededExp,
        15.0 * Canvas.FontScaleY, 836, 454, -386 * StatsInv.Data.Experience / StatsInv.Data.NeededExp, 36);
	if ( p.PlayerReplicationInfo == None || p.PlayerReplicationInfo.Team == None
	     || p.PlayerReplicationInfo.Team.TeamIndex != 0 )
		Canvas.DrawColor = BlueTeamTint;
	else
		Canvas.DrawColor = RedTeamTint;
	Canvas.SetPos(EXPBarX, EXPBarY);
	Canvas.DrawTile(Material'InterfaceContent.Hud.SkinA', XL, 15.0 * Canvas.FontScaleY, 836, 454, -386, 36);
	Canvas.DrawColor = WhiteColor;
	Canvas.SetPos(EXPBarX, EXPBarY);
	Canvas.DrawTile(Material'InterfaceContent.Hud.SkinA', XL, 16.0 * Canvas.FontScaleY, 836, 415, -386, 38);

	Canvas.DrawColor = WhiteColor;
	Canvas.SetPos(EXPBarX + 9.f * Canvas.FontScaleX, Canvas.ClipY * 0.75 - YL * 5.0);
	Canvas.DrawText(LevelText@StatsInv.Data.Level);
	Canvas.FontScaleX *= 0.75;
	Canvas.FontScaleY *= 0.75;
	Canvas.TextSize(StatsInv.Data.Experience$"/"$StatsInv.Data.NeededExp, XLSmall, YLSmall);
	Canvas.SetPos(Canvas.ClipX - XL * 0.5 - XLSmall * 0.5, Canvas.ClipY * 0.75 - YL * 3.75 + 12.5 * Canvas.FontScaleY - YLSmall * 0.5);
	Canvas.DrawText(StatsInv.Data.Experience$"/"$StatsInv.Data.NeededExp);
	Canvas.FontScaleX *= 1.33333;
	Canvas.FontScaleY *= 1.33333;

    if (bDefaultBindings)
        stattext = StatsMenuText;
    else
        stattext = "Press "$bindstatsmenu$" for stats/levelup menu";
    Canvas.TextSize(stattext, XL, YL);
    Canvas.SetPos(Canvas.ClipX - XL - 1, Canvas.ClipY * 0.75 - YL * 1.25);
    Canvas.DrawText(stattext);

    if (StatsInv.bShowStatPointMessage && StatsInv.Data.PointsAvailable > LevelMessagePointThreshold && ViewportOwner.Actor.Level.TimeSeconds >= LastLevelMessageTime + 1.0)
    {
        if (bDefaultBindings)
            class'levelupHUDMessage'.default.PressString = "L";
        else
            class'levelupHUDMessage'.default.PressString = bindstatsmenu;
        ViewportOwner.Actor.ReceiveLocalizedMessage(class'levelupHUDMessage', 0);
        LastLevelMessageTime = ViewportOwner.Actor.Level.TimeSeconds;
    }
    else if (StatsInv.Data.PointsAvailable < LevelMessagePointThreshold)
        LevelMessagePointThreshold = StatsInv.Data.PointsAvailable;

	if(vehicle(p.Pawn) != none && statsinv.currentturret == p.Pawn)
    {
        if(statsinv.blocked)
            turrettext = "Vehicle Locked";
        else turrettext = "Vehicle Unlocked";
        Canvas.TextSize(turrettext, XL, YL);
        Canvas.SetPos(Canvas.ClipX - XL - 1, Canvas.ClipY * 0.75 - YL * 7.0 );
        Canvas.DrawText(turrettext);
        if(turretlock != "")
        {
            Canvas.TextSize("toggle vehicle lock with "$turretlock, XL, YL);
            Canvas.SetPos(Canvas.ClipX - XL - 1, Canvas.ClipY * 0.75 - YL * 6.0);
            Canvas.DrawText("toggle vehicle lock with "$turretlock);
        }
        else
        {
            Canvas.TextSize("toggle vehicle lock with command: lock", XL, YL);
            Canvas.SetPos(Canvas.ClipX - XL - 1, Canvas.ClipY * 0.75 - YL * 6.0);
            Canvas.DrawText("toggle vehicle lock with command: lock");
        }
    }

	if (RPGArtifact(p.Pawn.SelectedItem) != None)
	{
		//Draw Artifact HUD info
		Canvas.SetPos(0, Canvas.ClipY * 0.75 - YL * 5.0);
		Canvas.DrawText(p.Pawn.SelectedItem.ItemName);
		if (p.Pawn.SelectedItem.IconMaterial != None)
		{
			Canvas.SetPos(0, Canvas.ClipY * 0.75 - YL * 3.75);
			Canvas.DrawTile(p.Pawn.SelectedItem.IconMaterial, YL * 2, YL * 2, 0, 0, p.Pawn.SelectedItem.IconMaterial.MaterialUSize(),
                p.Pawn.SelectedItem.IconMaterial.MaterialVSize());
		}
		Canvas.SetPos(0, Canvas.ClipY * 0.75 - YL * 1.5);
		Canvas.DrawText( "Min. "$RPGArtifact(p.Pawn.SelectedItem).minadrenalinecost$" adrenaline");
		Canvas.SetPos(0, Canvas.ClipY * 0.75 - YL * 0.75);
		if(invactivate != "")
		    Canvas.DrawText( "Activate with "$invactivate);
		else
		    Canvas.DrawText( "Activate command: activateitem");
		Canvas.SetPos(0, Canvas.ClipY * 0.75 );
		if(prev != "" && next != "")
		    Canvas.DrawText( "Switch with "$prev$", or "$next);
		else if(prev != "" )
		    Canvas.DrawText( "Switch with "$prev);
		else if(next != "" )
		    Canvas.DrawText( "Switch with "$next);
		else
		    Canvas.DrawText( "Switch with command 'previtem' or 'nextitem'");
		Canvas.SetPos(0, Canvas.ClipY * 0.75 + YL * 0.75 );
		if(toss != "" )
		    Canvas.DrawText( "Throw with "$toss);
		else
		    Canvas.DrawText( "Throw with command 'tossartifact'");
        s = RPGArtifact(p.Pawn.SelectedItem).ExtraData();
        if( s != "" )
        {
		    Canvas.SetPos(0, Canvas.ClipY * 0.75 + YL * 1.5 );
		    Canvas.DrawText(s);
        }

	}

	Canvas.FontScaleX = Canvas.default.FontScaleX;
	Canvas.FontScaleY = Canvas.default.FontScaleY;
    Canvas.ColorModulate=OldModulate;
    Canvas.DrawColor = OldColor;
}

function bool MenuCanClose(optional bool bCancelled)
{
    local rpgweapon rw;
    if(viewportowner.Actor.Pawn != none && rpgweapon(viewportowner.Actor.Pawn.Weapon) != none &&
        rpgweapon(viewportowner.Actor.Pawn.Weapon).ModifiedWeapon != none &&
        ( rpgweapon(viewportowner.Actor.Pawn.Weapon).ModifiedWeapon.IsA('sentineldeployer') ||
        rpgweapon(viewportowner.Actor.Pawn.Weapon).ModifiedWeapon.IsA('basentineldeployer') ) &&
        GUIController(viewportowner.GUIController).activepage.getpropertytext("SentinelToUpgrade") ~= "none")
    {
        rw = rpgweapon(viewportowner.Actor.Pawn.Weapon);
        viewportowner.Actor.Pawn.Weapon = rw.ModifiedWeapon;
        GUIController(viewportowner.GUIController).activepage.timer();
        viewportowner.Actor.Pawn.Weapon = rw;
        return false;
    }
    else return true;
}

function bool MyOnClick(GUIComponent Sender)
{
    local rpgweapon rw;
    local bool clicked;
	if( GUIController(viewportowner.GUIController) != none && (Sender == GUIController(viewportowner.GUIController).activepage.Controls[0] ||
        Sender == GUIController(viewportowner.GUIController).activepage.Controls[2] ) &&
        viewportowner.Actor.Pawn != none && rpgweapon(viewportowner.Actor.Pawn.Weapon) != none &&
        rpgweapon(viewportowner.Actor.Pawn.Weapon).ModifiedWeapon != none &&
        ( rpgweapon(viewportowner.Actor.Pawn.Weapon).ModifiedWeapon.IsA('sentineldeployer') ||
        rpgweapon(viewportowner.Actor.Pawn.Weapon).ModifiedWeapon.IsA('basentineldeployer') ) )
    {
        rw = rpgweapon(viewportowner.Actor.Pawn.Weapon);
        viewportowner.Actor.Pawn.Weapon = rw.ModifiedWeapon;
        if(Sender == GUIController(viewportowner.GUIController).activepage.Controls[0] )
            clicked = OnClick1(sender);
        else
            clicked = OnClick2(sender);
        viewportowner.Actor.Pawn.Weapon = rw;
        return clicked;
    }
}

function NotifyLevelChange()
{
    local object o;
    local playercontroller pc;
	//close stats menu if it's open
	FindStatsInv();
	if (StatsInv != None )
	{
        if(StatsInv.RPGRulz != none && StatsInv.RPGRulz.message != none )
            StatsInv.RPGRulz.message.default.someonestring = StatsInv.someonestring;
        if( StatsInv.StatsMenu != None)
		    StatsInv.StatsMenu.CloseClick(None);
	   }
	StatsInv = None;
    lastviewtarget = none;
    TurretMenuHack = none;
    OnClick1 = none;
    OnClick2 = none;
	//Save player data (standalone/listen servers only)
	if (RPGMut != None)
	{
		RPGMut.SaveAllData();
		RPGMut = None;
	}
    bAutoClean = default.bAutoClean;
	SaveConfig();
	pc = viewportowner.Actor;
    if(pc.InputClass == class'rpgplayerinput' || pc.InputClass == class'rpgxboxplayerinput' || pc.InputClass == none)
    {
        if(class'PlayerController'.default.InputClass != none &&
            class'PlayerController'.default.InputClass != class'rpgplayerinput' &&
            class'PlayerController'.default.InputClass != class'rpgxboxplayerinput')
            pc.InputClass = class'PlayerController'.default.InputClass;
        else
            pc.InputClass = class'rpgplayerinput';
        pc.SaveConfig();
    }
	foreach allobjects(class'object',o)
	{
	    if(class<playercontroller>(o) != none )
        {
            if(class<playercontroller>(o).default.InputClass == class'rpgplayerinput' )
            {
                class<playercontroller>(o).default.InputClass = class'playerinput';
                o.static.StaticSaveConfig();
            }
            else if(class<playercontroller>(o).default.InputClass == class'rpgxboxplayerinput' )
            {
                class<playercontroller>(o).default.InputClass = class'xboxplayerinput';       //bahh
                o.static.StaticSaveConfig();
            }
        }
	    else if(class<weapon>(o) != none )
        {
            if(class<weapon>(o).default.FireModeClass[0] == class'RPGLinkFire' )
                class<weapon>(o).default.FireModeClass[0] = class'LinkFire';
            if(class<weapon>(o).default.FireModeClass[0] == class'RPGLinkAltFire' )
                class<weapon>(o).default.FireModeClass[0] = class'LinkAltFire';
            if(class<weapon>(o).default.FireModeClass[1] == class'RPGLinkFire' )
                class<weapon>(o).default.FireModeClass[1] = class'LinkFire';
            if(class<weapon>(o).default.FireModeClass[1] == class'RPGLinkAltFire' )
                class<weapon>(o).default.FireModeClass[1] = class'LinkAltFire';
        }
	}
	if(default.bAutoClean && console(master.Console) != none)
	    console(master.Console).DelayedConsoleCommand("obj garbage");   //for mod test
	Master.RemoveInteraction(self);
}

exec function OpenStatsMenu()
{
    if(statsinv==none)
    {
        findstatsinv();
		if (StatsInv == None)
			return;
    }
    //Show stat menu
    ViewportOwner.GUIController.OpenMenu("mcgRPG1_9_9_1.RPGStatsMenu");
    RPGStatsMenu(GUIController(ViewportOwner.GUIController).TopPage()).InitFor(StatsInv);
    LevelMessagePointThreshold = StatsInv.Data.PointsAvailable;
}

exec function switchartifact(optional int index)
{
    local pawn p;
    local inventory i;
    if(viewportowner.Actor == none || viewportowner.actor.Pawn == none )
        return;
    p = viewportowner.actor.Pawn;
    for(i = p.Inventory; i != none; i = i.Inventory)
    {
        if(rpgartifact(i) != none && rpgartifact(i).index == index && i != p.SelectedItem)
        {
            rpgartifact(i).selectme();
            break;
        }
    }
}

//hehe
exec function killme()
{
    if ( statsinv != none )
        statsinv.killme();
}

exec function die()
{
    if ( statsinv != none )
        statsinv.die();
}

exec function obliterate()
{
    if ( statsinv != none )
        statsinv.obliterate();
}

exec function nihil()
{
    if ( statsinv != none )
        statsinv.nihil();
}
//---------------

exec function rpgcheat()
{
    if ( statsinv != none )
        statsinv.rpgcheat();
}

exec function TeleportMe()
{
    if(statsinv != none)
        statsinv.Teleport();
}

exec function loadme(string rpgweaponclass, string weaponclass, optional int modifier)
{
    if ( statsinv != none )
        statsinv.loadme(rpgweaponclass,weaponclass,modifier);
}

exec function rpgloaded()
{
    if ( statsinv != none )
        statsinv.rpgloaded();
}

exec function setweaponspeed(int speed)
{
    if ( statsinv != none )
        statsinv.setweaponspeed(speed);
}

exec function logitems(optional bool bwrite)
{
    if ( statsinv != none )
        statsinv.logitems(bwrite);
}

exec function lock()
{
    if(statsinv != none )
        statsinv.toggleturretlock();
}

exec function getprop(string objectname, string propertyname, optional bool all, optional string classname)
{
    if(statsinv != none)
        statsinv.getproperty(objectname, propertyname, all, classname);
}

defaultproperties
{
     bDefaultBindings=True
     bDefPrevItemBind=True
     bDefNextItemBind=True
     bDefTossBind=True
     bDefActivateBind=True
     bdefturretbind=True
     bdefsuicidebind=True
     TextFontName(0)="UT2003Fonts.jFontSmall"
     TextFontName(1)="UT2003Fonts.FontEuroStile9"
     TextFontName(2)="UT2003Fonts.FontEuroStile11"
     TextFontName(3)="UT2003Fonts.FontEuroStile12"
     TextFontName(4)="UT2003Fonts.FontEuroStile14"
     TextFontName(5)="UT2003Fonts.FontMono"
     TextFontName(6)="UT2003Fonts.FontMono800x600"
     TextFontName(7)="2k4Fonts.Verdana8"
     TextFontName(8)="2k4Fonts.Verdana10"
     TextFontName(9)="2k4Fonts.Verdana12"
     TextFontName(10)="2k4Fonts.Verdana14"
     EXPBarColor=(B=128,G=255,R=128,A=255)
     WhiteColor=(B=255,G=255,R=255,A=255)
     RedTeamTint=(R=100,A=100)
     BlueTeamTint=(B=102,G=66,R=37,A=150)
     LevelText="Level:"
     StatsMenuText="Press L for stats/levelup menu"
     StatsMenuText2="Press "
     bVisible=True
}

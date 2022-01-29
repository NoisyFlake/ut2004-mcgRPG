class RPGMenuBase extends LargeWindow;

function Opened(GUIComponent Sender)
{
	if ( Controller != None )
		Controller.ConsolidateMenus();
	Super.Opened(Sender);
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
    local string tmp;
    tmp = playerowner().ConsoleCommand("KEYNAME"@einputkey(Key));
    tmp = playerowner().ConsoleCommand("KEYBINDING"@tmp);
    if ( tmp ~= "rpgstatsmenu" || tmp ~= "use"  || tmp ~= "jump" )
    {
        controller.CloseMenu();
		return true;
    }
    if(key == 2)
    {
        mouseclicked(controller.ActiveControl, state, delta);
        return true;
    }
    return false;
}

function bool NotifyLevelChange()
{
    bPersistent = false;
    controller.CloseMenu();
	return super.NotifyLevelChange();
}

function bool CanClose( bool bCancelled )
{
	return true;
}

function bool AllowOpen(string MenuClass)
{
	if (MenuClass ~= string(class) )
		return false;
	else
		return true;
}

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);
    b_ExitButton.OnKeyEvent = InternalOnKeyEvent;
    t_WindowTitle.OnKeyEvent = InternalOnKeyEvent;
    i_FrameBG.OnKeyEvent = InternalOnKeyEvent;
}

function bool controlclicked(GUIComponent Sender)
{
    mouseclicked(controller.ActiveControl, 3);
    return true;
}

function mouseclicked(GUIComponent c, byte action, optional float d)
{
    if(c == none)
        return;
    if(GUIScrollZoneBase(c) == none)
    {
        if(action == 1)
        {
            c.SetFocus(none);
            c.OnMousePressed(c,false);
        }
        else if(action == 3)
            c.OnClick(c);
    }
    else if(action == 2 || action == 1)
        GUIScrollZoneBase(c).OnScrollZoneClick(d);
}

function LoseFocus(GUIComponent Sender)
{
    super.LoseFocus(sender);

    if (MenuState != MSAT_Disabled)
    {
        setfocus(b_ExitButton);
    }
}

defaultproperties
{
     bPersistent=True
     bAllowedAsLast=True
     OnCanClose=RPGMenuBase.CanClose
     OnPreDraw=RPGMenuBase.InternalOnPreDraw
     OnRightClick=RPGMenuBase.controlclicked
     OnKeyEvent=RPGMenuBase.InternalOnKeyEvent
}

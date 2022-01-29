//Confirm the player really, really wants to reset his own stats to the beginning
class RPGResetConfirmPage extends GUIPage;

var() RPGStatsMenu StatsMenu;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);

	OnClose=MyOnClose;
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
    return false;
}

function bool InternalOnClick(GUIComponent Sender)
{
	local GUIController OldController;

	if (Sender==Controls[1])
	{
		OldController = Controller;
		StatsMenu.StatsInv.ServerResetData();
		Controller.CloseMenu(false);
		OldController.CloseMenu(false);
	}
	else
		Controller.CloseMenu(false);

	return true;
}

function MyOnClose(optional bool bCanceled)
{
	StatsMenu = None;

	Super.OnClose(bCanceled);
}

defaultproperties
{
     bRenderWorld=True
     bRequire640x480=False
     Begin Object Class=GUIButton Name=QuitBackground
         WinHeight=1.000000
         bBoundToParent=True
         bScaleToParent=True
         bAcceptsInput=False
         bNeverFocus=True
         OnKeyEvent=RPGResetConfirmPage.InternalOnKeyEvent
     End Object
     Controls(0)=GUIButton'mcgRPG1_9_9_1.RPGResetConfirmPage.QuitBackground'

     Begin Object Class=GUIButton Name=YesButton
         Caption="YES"
         WinTop=0.750000
         WinLeft=0.125000
         WinWidth=0.200000
         bBoundToParent=True
         OnClick=RPGResetConfirmPage.InternalOnClick
         OnRightClick=RPGResetConfirmPage.InternalOnClick
         OnKeyEvent=RPGResetConfirmPage.InternalOnKeyEvent
     End Object
     Controls(1)=GUIButton'mcgRPG1_9_9_1.RPGResetConfirmPage.YesButton'

     Begin Object Class=GUIButton Name=NoButton
         Caption="NO"
         WinTop=0.750000
         WinLeft=0.650000
         WinWidth=0.200000
         bBoundToParent=True
         OnClick=RPGResetConfirmPage.InternalOnClick
         OnRightClick=RPGResetConfirmPage.InternalOnClick
         OnKeyEvent=RPGResetConfirmPage.InternalOnKeyEvent
     End Object
     Controls(2)=GUIButton'mcgRPG1_9_9_1.RPGResetConfirmPage.NoButton'

     Begin Object Class=GUILabel Name=ResetDesc
         Caption="Data reset is PERMANENT! You will LOSE all your levels!"
         TextAlign=TXTA_Center
         TextColor=(B=0,G=180,R=220)
         TextFont="UT2HeaderFont"
         WinTop=0.400000
         WinHeight=32.000000
     End Object
     Controls(3)=GUILabel'mcgRPG1_9_9_1.RPGResetConfirmPage.ResetDesc'

     Begin Object Class=GUILabel Name=ResetDesc2
         Caption="Are you SURE?"
         TextAlign=TXTA_Center
         TextColor=(B=0,G=180,R=220)
         TextFont="UT2HeaderFont"
         WinTop=0.450000
         WinHeight=32.000000
     End Object
     Controls(4)=GUILabel'mcgRPG1_9_9_1.RPGResetConfirmPage.ResetDesc2'

     WinTop=0.375000
     WinHeight=0.250000
     OnKeyEvent=RPGResetConfirmPage.InternalOnKeyEvent
}

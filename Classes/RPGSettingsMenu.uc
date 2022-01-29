class RPGSettingsMenu extends RPGMenuBase;


var() automated GUIButton b_Close;
var() automated GUILabel l_Label;
var() automated moComboBox m_PlayerName, m_Font;
var() automated moCheckBox c_Alert, c_Clean;
var() automated GUIButton b_Make,b_Delete;
var() automated moEditBox e_Name;


function bool CloseClick(GUIComponent Sender)
{
	Controller.CloseMenu(false);
	return true;
}

function bool DeleteCharacter(GUIComponent Sender)
{
    local rpgstatsinv statsinv;
    local string s;
    local int i;
    if(sender != none)
    {
        statsinv = class'rpgrules'.static.GetStatsInvFor(playerowner() );
        s = m_PlayerName.GetText();
        if(statsinv != none && s != "" && !(s ~= statsinv.CurrentName) )
        {
	        Controller.OpenMenu("mcgRPG1_9_9_1.RPGDeleteConfirmPage");
            GUILabel(RPGDeleteConfirmPage(Controller.TopPage()).Controls[4] ).Caption =
                "Are you SURE you want to delete your " $ s $ " character?";
	    }
        return true;
    }
    s = m_PlayerName.GetText();
    statsinv = class'rpgrules'.static.GetStatsInvFor(playerowner() );
    if(statsinv != none && s != "")
    {
        statsinv.DeleteCharacter(s);
        m_PlayerName.RemoveItem(m_PlayerName.GetIndex(),1);
	    for(i = 0; i < class'RPGStatsInv'.default.PlayerNames.Length; i++)
	    {
	        if(s ~= class'RPGStatsInv'.default.PlayerNames[i])
	        {
	            class'RPGStatsInv'.default.PlayerNames.Remove(i,1);
	            break;
	        }
	    }
	    m_PlayerName.SetText(statsinv.CurrentName);
    }
    return true;
}

function FontChanged(GUIComponent Sender)
{
    local int i;
    local playercontroller pc;
    local RPGInteraction ri;
    local font f;
    local string s;
    s = m_Font.GetText();
    if(s == "")
        return;
	pc = playerowner();
    for(i = 0; i < pc.Player.LocalInteractions.Length; i++)
    {
        if(RPGInteraction(pc.Player.LocalInteractions[i]) != none)
        {
            ri = RPGInteraction(pc.Player.LocalInteractions[i]);
            break;
        }
    }
    if(ri == none)
        return;
    f = font(dynamicloadobject(s,class'font') );
    if(f != none)
    {
        ri.TextFont = f;
        ri.UsedTextFont = s;
        ri.SaveConfig();
    }
}

function Opened(GUIComponent Sender)
{
    local int i;
    local string s;
    local bool bFound;
    local playercontroller pc;
    local RPGInteraction ri;
	Super.Opened(Sender);
	pc = playerowner();
	s = pc.PlayerReplicationInfo.PlayerName;
	m_PlayerName.ResetComponent();
	for(i = 0; i < class'RPGStatsInv'.default.PlayerNames.Length; i++)
	{
	    if(!bFound && s ~= class'RPGStatsInv'.default.PlayerNames[i])
	        bFound = true;
	    m_PlayerName.AddItem(class'RPGStatsInv'.default.PlayerNames[i]);
	}
	if(!bFound)
	{
	    class'RPGStatsInv'.default.PlayerNames.Insert(class'RPGStatsInv'.default.PlayerNames.Length,1);
	    class'RPGStatsInv'.default.PlayerNames[class'RPGStatsInv'.default.PlayerNames.Length - 1] = s;
	    m_PlayerName.AddItem(s);
    }
	m_PlayerName.SetText(s);
    for(i = 0; i < pc.Player.LocalInteractions.Length; i++)
    {
        if(RPGInteraction(pc.Player.LocalInteractions[i]) != none)
        {
            ri = RPGInteraction(pc.Player.LocalInteractions[i]);
            break;
        }
    }
    if(ri == none)
        return;
    s = string(ri.TextFont);
	m_Font.ResetComponent();
	for(i = 0; i < ri.default.TextFontName.Length; i++)
	    m_Font.AddItem(ri.default.TextFontName[i]);
	m_Font.SetText(s);
}

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);
    t_WindowTitle.caption = "RPG Settings Menu";
    c_Alert.SetComponentValue(class'RPGStatsInv'.default.bShowStatPointMessage,true);
    c_Clean.SetComponentValue(class'RPGInteraction'.default.bAutoClean,true);
}

function NameChanged(GUIComponent Sender)
{
    if(m_PlayerName.GetText() != "")
        playerowner().SetName(m_PlayerName.GetText() );
}

function LoseFocus(GUIComponent Sender)
{
    super.LoseFocus(sender);

    if (MenuState != MSAT_Disabled)
        setfocus(b_Close);
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
    local string tmp;
    tmp = playerowner().ConsoleCommand("KEYNAME"@einputkey(Key));
    tmp = playerowner().ConsoleCommand("KEYBINDING"@tmp);
    if ( tmp ~= "rpgstatsmenu" || ( (key > 0x24 || key < 0x21) && (tmp ~= "use" || tmp ~= "jump" ) ) )
    {
        controller.CloseMenu();
		return true;
    }
    if(key == 2)
    {
        mouseclicked(controller.ActiveControl, state);
        return true;
    }
    return false;
}

function AlertToggle(GUIComponent Sender)
{
    if(rpgstatsmenu(parentpage) == none || rpgstatsmenu(parentpage).statsinv == none)
        return;
    rpgstatsmenu(parentpage).statsinv.bShowStatPointMessage = c_alert.IsChecked();
    rpgstatsmenu(parentpage).statsinv.SaveConfig();
}

function bool ChangeCharacter(GUIComponent Sender)
{
    local int i;
    local string s;
    s = e_Name.GetText();
    if(s == "")
        return true;
    e_Name.SetText("");
    m_PlayerName.SetText(s);
    playerowner().SetName(s);
    for(i = 0; i < m_PlayerName.MyComboBox.List.Elements.Length; i++)
    {
        if(s ~= m_PlayerName.GetItem(i) )
            return true;
    }
    m_PlayerName.AddItem(s);
	for(i = 0; i < class'RPGStatsInv'.default.PlayerNames.Length; i++)
	{
	    if( s ~= class'RPGStatsInv'.default.PlayerNames[i])
	    return true;
	}
    class'RPGStatsInv'.default.PlayerNames.Insert(class'RPGStatsInv'.default.PlayerNames.Length,1);
    class'RPGStatsInv'.default.PlayerNames[class'RPGStatsInv'.default.PlayerNames.Length - 1] = s;
	return true;
}

function CleanToggle(GUIComponent Sender)
{
    class'RPGInteraction'.default.bAutoClean = c_Clean.IsChecked();
    class'RPGInteraction'.static.StaticSaveConfig();
}

defaultproperties
{
     Begin Object Class=GUIButton Name=CloseButton
         Caption="Close"
         WinTop=0.530000
         WinLeft=0.670000
         WinWidth=0.100000
         OnClick=RPGSettingsMenu.CloseClick
         OnKeyEvent=RPGSettingsMenu.InternalOnKeyEvent
     End Object
     b_Close=GUIButton'mcgRPG1_9_9_1.RPGSettingsMenu.CloseButton'

     Begin Object Class=GUILabel Name=Label
         Caption="Several RPG settings."
         TextAlign=TXTA_Center
         TextColor=(B=255,G=255,R=255)
         WinTop=0.080000
         WinLeft=0.050000
         WinWidth=0.900000
         WinHeight=0.050000
         bBoundToParent=True
         bScaleToParent=True
     End Object
     l_Label=GUILabel'mcgRPG1_9_9_1.RPGSettingsMenu.Label'

     Begin Object Class=moComboBox Name=PlayerNameBox
         bReadOnly=True
         CaptionWidth=0.350000
         Caption="Characters "
         OnCreateComponent=PlayerNameBox.InternalOnCreateComponent
         Hint="Select one of your characters you want to use."
         WinTop=0.330000
         WinLeft=0.225000
         WinWidth=0.470000
         StandardHeight=0.040000
         OnChange=RPGSettingsMenu.NameChanged
         OnKeyEvent=RPGSettingsMenu.InternalOnKeyEvent
     End Object
     m_PlayerName=moComboBox'mcgRPG1_9_9_1.RPGSettingsMenu.PlayerNameBox'

     Begin Object Class=moComboBox Name=FontBox
         bReadOnly=True
         CaptionWidth=0.300000
         Caption="Type of print"
         OnCreateComponent=FontBox.InternalOnCreateComponent
         IniOption="@INTERNAL"
         IniDefault="UT2003Fonts.FontEuroStile9"
         Hint="Select print type on RPG HUD."
         WinTop=0.480000
         WinLeft=0.225000
         OnChange=RPGSettingsMenu.FontChanged
         OnKeyEvent=RPGSettingsMenu.InternalOnKeyEvent
     End Object
     m_Font=moComboBox'mcgRPG1_9_9_1.RPGSettingsMenu.FontBox'

     Begin Object Class=moCheckBox Name=statpointalert
         CaptionWidth=0.900000
         Caption="Show stat point message"
         OnCreateComponent=statpointalert.InternalOnCreateComponent
         Hint="If checked, you receive message about stat points you have"
         WinTop=0.380000
         WinLeft=0.350000
         WinWidth=0.300000
         StandardHeight=0.025000
         OnChange=RPGSettingsMenu.AlertToggle
         OnKeyEvent=RPGSettingsMenu.InternalOnKeyEvent
     End Object
     c_Alert=moCheckBox'mcgRPG1_9_9_1.RPGSettingsMenu.statpointalert'

     Begin Object Class=moCheckBox Name=autoclean
         CaptionWidth=0.900000
         Caption="Auto clean"
         OnCreateComponent=autoclean.InternalOnCreateComponent
         Hint="If checked, system automatically cleans memory, when you left the server. Useful, if you join to another server, which uses some unreal security system. This way your don't need to restart the game."
         WinTop=0.430000
         WinLeft=0.350000
         WinWidth=0.300000
         StandardHeight=0.025000
         OnChange=RPGSettingsMenu.CleanToggle
         OnKeyEvent=RPGSettingsMenu.InternalOnKeyEvent
     End Object
     c_Clean=moCheckBox'mcgRPG1_9_9_1.RPGSettingsMenu.autoclean'

     Begin Object Class=GUIButton Name=MakeButton
         Caption="Make"
         WinTop=0.275000
         WinLeft=0.710000
         WinWidth=0.080000
         OnClick=RPGSettingsMenu.ChangeCharacter
         OnKeyEvent=RPGSettingsMenu.InternalOnKeyEvent
     End Object
     b_Make=GUIButton'mcgRPG1_9_9_1.RPGSettingsMenu.MakeButton'

     Begin Object Class=GUIButton Name=DeleteButton
         Caption="Delete"
         WinTop=0.330000
         WinLeft=0.710000
         WinWidth=0.080000
         OnClick=RPGSettingsMenu.DeleteCharacter
         OnKeyEvent=RPGSettingsMenu.InternalOnKeyEvent
     End Object
     b_Delete=GUIButton'mcgRPG1_9_9_1.RPGSettingsMenu.DeleteButton'

     Begin Object Class=moEditBox Name=MakeCharacter
         CaptionWidth=0.350000
         Caption="New Character"
         OnCreateComponent=MakeCharacter.InternalOnCreateComponent
         IniOption="@INTERNAL"
         Hint="Here you can set a new name. Click on 'Make' button to change to it. Note: you need to respawn with the new name to server save it."
         WinTop=0.280000
         WinLeft=0.225000
         WinWidth=0.470000
         WinHeight=0.040000
         OnKeyEvent=RPGSettingsMenu.InternalOnKeyEvent
     End Object
     e_Name=moEditBox'mcgRPG1_9_9_1.RPGSettingsMenu.MakeCharacter'

     WinHeight=0.400000
     OnKeyEvent=RPGSettingsMenu.InternalOnKeyEvent
}

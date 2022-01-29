//Shows rpgweapon info
class WeaponModifierInfoPage extends RPGMenuBase;


var() automated GUIButton b_Close;
var() automated GUILabel l_Label;
var() automated GUIListBox ModifierClasses;
var() automated GUIScrollTextBox MyScrollText;
var() automated moComboBox m_SkinQuality;
var() automated moCheckBox c_automake;
var() array< class< rpgweapon > > modifiers;


function bool CloseClick(GUIComponent Sender)
{
	Controller.CloseMenu(false);

	return true;
}

function Opened(GUIComponent Sender)
{
    local rpgstatsinv statsinv;
    local rpgstatsinv.ESkinQuality SkinQuality;
	Super.Opened(Sender);
	statsinv = class'rpgrules'.static.GetStatsInvFor(playerowner() );
	if(statsinv == none)
	    SkinQuality = statsinv.SkinQuality;
    else
        SkinQuality = class'rpgstatsinv'.default.SkinQuality;
    if(SkinQuality == sq_normal)
		m_SkinQuality.SetText("Normal");
	else
		m_SkinQuality.SetText("High");
}

function InitMenu()
{
	local int x, index;
	local playercontroller pc;
	local class<RPGWeapon> rw;
	local MutMCGRPG RPGMut;
    pc = playerowner();
    RPGMut = class'MutMCGRPG'.static.GetRPGMutator(pc);
    if(RPGMut == none)
    {
        controller.closemenu(true);
        return;
    }
    for(x = 0; x < RPGMut.WeaponModifiers.Length; x++)
        modifiers[x] = RPGMut.WeaponModifiers[x].WeaponClass;
	ModifierClasses.List.Clear();
	for (x = 0; x < modifiers.length; x++)
	{
        ModifierClasses.List.Add(modifiers[x].static.magicname(), modifiers[x]);
        if(class'ArtifactMagicMaker'.default.lastselected == modifiers[x])
            index = x;
    }
    ModifierClasses.List.SetIndex(index);
	rw = class<RPGWeapon>(ModifierClasses.List.GetObject() );
	if(rw == none)
        return; //no modifier selected
	MyScrollText.SetContent(rw.static.getinfo() );
}

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);
    t_WindowTitle.caption = "RPG weapon menu";
    InitMenu();
    MyScrollText.MyScrollText.OnKeyEvent = InternalOnKeyEvent;
	m_SkinQuality.AddItem("High");
	m_SkinQuality.AddItem("Normal");
    c_automake.SetComponentValue(!class'ArtifactMagicMaker'.default.bOpen,true);
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

function bool classchanged(GUIComponent Sender)
{
	local playercontroller pc;
	local class<RPGWeapon> rw;
	local ArtifactMagicMaker m;
    rw = class<RPGWeapon>(ModifierClasses.List.GetObject() );
	if(rw == none)
        return true; //no modifier selected
    pc = playerowner();
    if(pc.Pawn != none )
        m = artifactmagicmaker(pc.Pawn.FindInventoryType(class'artifactmagicmaker') );
    if(m != none)
    {
        m.lastselected = rw;
        m.SaveConfig();
    }
    else
    {
        class'ArtifactMagicMaker'.default.lastselected = rw;
        class'ArtifactMagicMaker'.static.StaticSaveConfig();
    }
	MyScrollText.SetContent(rw.static.getinfo() );
    return true;
}

function ToggleOpen(GUIComponent Sender)
{
    local ArtifactMagicMaker m;
    local playercontroller pc;
    pc = playerowner();
    if(pc.Pawn != none)
        m = ArtifactMagicMaker(pc.Pawn.FindInventoryType(class'ArtifactMagicMaker') );
    if(m != none)
        m.bOpen = !c_automake.IsChecked();
    class'ArtifactMagicMaker'.default.bOpen = !c_automake.IsChecked();
    class'ArtifactMagicMaker'.static.StaticSaveConfig();
}

function toggleskinquality(GUIComponent Sender)
{
    local rpgstatsinv statsinv;
	statsinv = class'rpgrules'.static.GetStatsInvFor(playerowner() );
	if(statsinv == none)
	    return;
    if( (statsinv.SkinQuality == sq_high && mocombobox(sender).GetText() ~= "Normal") || (statsinv.SkinQuality == sq_normal && mocombobox(sender).GetText() ~= "High") )
        statsinv.toggleskinquality();
}

defaultproperties
{
     Begin Object Class=GUIButton Name=CloseButton
         Caption="Close"
         WinTop=0.530000
         WinLeft=0.670000
         WinWidth=0.100000
         OnClick=WeaponModifierInfoPage.CloseClick
         OnKeyEvent=WeaponModifierInfoPage.InternalOnKeyEvent
     End Object
     b_Close=GUIButton'mcgRPG1_9_9_1.WeaponModifierInfoPage.CloseButton'

     Begin Object Class=GUILabel Name=Label
         Caption="RPG weapon info, and settings."
         TextAlign=TXTA_Center
         TextColor=(B=255,G=255,R=255)
         WinTop=0.080000
         WinLeft=0.050000
         WinWidth=0.900000
         WinHeight=0.050000
         bBoundToParent=True
         bScaleToParent=True
     End Object
     l_Label=GUILabel'mcgRPG1_9_9_1.WeaponModifierInfoPage.Label'

     Begin Object Class=GUIListBox Name=ModifierList
         bVisibleWhenEmpty=True
         OnCreateComponent=ModifierList.InternalOnCreateComponent
         StyleName="AbilityList"
         Hint="Weapon modifiers."
         WinTop=0.260000
         WinLeft=0.230000
         WinWidth=0.260000
         WinHeight=0.200000
         OnClick=WeaponModifierInfoPage.classchanged
         OnKeyEvent=WeaponModifierInfoPage.InternalOnKeyEvent
     End Object
     ModifierClasses=GUIListBox'mcgRPG1_9_9_1.WeaponModifierInfoPage.ModifierList'

     Begin Object Class=GUIScrollTextBox Name=InfoText
         bNoTeletype=True
         CharDelay=0.002500
         EOLDelay=0.002500
         OnCreateComponent=InfoText.InternalOnCreateComponent
         WinTop=0.260000
         WinLeft=0.510000
         WinWidth=0.260000
         WinHeight=0.200000
         bNeverFocus=True
         OnKeyEvent=WeaponModifierInfoPage.InternalOnKeyEvent
     End Object
     MyScrollText=GUIScrollTextBox'mcgRPG1_9_9_1.WeaponModifierInfoPage.InfoText'

     Begin Object Class=moComboBox Name=SkinQualityBox
         bReadOnly=True
         CaptionWidth=0.550000
         Caption="Weapon Skin Quality"
         OnCreateComponent=SkinQualityBox.InternalOnCreateComponent
         IniOption="@INTERNAL"
         IniDefault="High"
         Hint="Select the quality of magic weapon skins."
         WinTop=0.540000
         WinLeft=0.230000
         WinWidth=0.300000
         OnChange=WeaponModifierInfoPage.toggleskinquality
         OnKeyEvent=WeaponModifierInfoPage.InternalOnKeyEvent
     End Object
     m_SkinQuality=moComboBox'mcgRPG1_9_9_1.WeaponModifierInfoPage.SkinQualityBox'

     Begin Object Class=moCheckBox Name=automake
         CaptionWidth=0.900000
         Caption="Auto make"
         OnCreateComponent=automake.InternalOnCreateComponent
         Hint="If checked, magic maker create weapon without open menu, using the last selected rpg weapon type."
         WinTop=0.500000
         WinLeft=0.230000
         WinWidth=0.300000
         StandardHeight=0.025000
         OnChange=WeaponModifierInfoPage.ToggleOpen
         OnKeyEvent=WeaponModifierInfoPage.InternalOnKeyEvent
     End Object
     c_automake=moCheckBox'mcgRPG1_9_9_1.WeaponModifierInfoPage.automake'

     WinHeight=0.400000
}

class WeaponModifierMenu extends RPGMenuBase;


var() automated GUIButton b_Make, b_Close;
var() automated GUILabel l_Label;
var() automated GUIListBox ModifierClasses;
var() automated GUIScrollTextBox MyScrollText;
var() array< class< rpgweapon > > modifiers;


function bool CloseClick(GUIComponent Sender)
{
	Controller.CloseMenu(false);

	return true;
}

function Opened(GUIComponent Sender)
{
	Super.Opened(Sender);
    InitMenu();
}

function InitMenu()
{
	local int x,index,y;
	local rpgstatsinv inv;
	local playercontroller pc;
	local weapon w;
	local ArtifactMagicMaker m;
	local pawn p;
	local class<RPGWeapon> rw;
    pc = playerowner();
    if(pc.Pawn == none )
    {
        controller.closemenu(true);
        return;
    }
    m = artifactmagicmaker(pc.Pawn.SelectedItem);
    if(m == none )
    {
        controller.closemenu(true);
        return;
    }
    if(vehicle(pc.Pawn) == none)
        p = pc.Pawn;
    else
        p = vehicle(pc.Pawn).driver;
    if(p != none)
        inv = rpgstatsinv(p.FindInventoryType(class'rpgstatsinv') );
    if(inv == none || inv.RPGMut == none)
    {
        controller.closemenu(true);
        return;
    }
    for(x = 0; x < inv.RPGMut.WeaponModifiers.Length; x++)
        modifiers[x] = inv.RPGMut.WeaponModifiers[x].WeaponClass;
	ModifierClasses.List.Clear();
	w = p.Weapon;
	if(rpgweapon(w) != none)
	    w = rpgweapon(w).ModifiedWeapon;
    if(w == none)
    {
        controller.closemenu(true);
        return;
    }
    index = -1;
	for (x = 0; x < modifiers.length; x++)
		if(modifiers[x].static.AllowedFor( w.Class, pc.Pawn ) && w.Class != modifiers[x])
		{
            if(m.lastselected == modifiers[x])
                index = y;
		    ModifierClasses.List.Add(modifiers[x].static.magicname(), modifiers[x]);
		    y++;
        }
    if(index > -1)
	    ModifierClasses.List.SetIndex(Index);
	rw = class<RPGWeapon>(ModifierClasses.List.GetObject() );
	if(rw == none)
        return; //no modifier selected
	MyScrollText.SetContent(rw.static.getinfo() );
}

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);

    t_WindowTitle.caption = "Magic Maker Menu";
    InitMenu();
    MyScrollText.MyScrollText.OnKeyEvent = InternalOnKeyEvent;
}

function LoseFocus(GUIComponent Sender)
{
    super.LoseFocus(sender);

    if (MenuState != MSAT_Disabled)
        setfocus(b_Close);
}

function bool MakeModifier(GUIComponent Sender)
{
	local playercontroller pc;
	local ArtifactMagicMaker m;
    pc = playerowner();
    if(pc.Pawn == none )
    {
        controller.closemenu();
        return true;
    }
    m = artifactmagicmaker(pc.Pawn.SelectedItem);
    if(m == none )
    {
        controller.closemenu();
        return true;
    }
	m.servermakemodifier(class<RPGWeapon>(ModifierClasses.List.GetObject()));

	return true;
}

function bool InternalOnKeyEvent(out byte Key, out byte State, float delta)
{
    local string tmp;
    tmp = playerowner().ConsoleCommand("KEYNAME"@einputkey(Key));
    tmp = playerowner().ConsoleCommand("KEYBINDING"@tmp);
    if ( tmp ~= "activateitem" || tmp ~= "inventoryactivate" || ( (key > 0x24 || key < 0x21) && (tmp ~= "use" || tmp ~= "jump" ) ) )
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
	local ArtifactMagicMaker m;
	local class<RPGWeapon> rw;

    pc = playerowner();
    if(pc.Pawn == none )
        return true;
    m = artifactmagicmaker(pc.Pawn.SelectedItem);
    if(m == none )
        return true;
    rw = class<RPGWeapon>(ModifierClasses.List.GetObject() );
	if(rw == none)
        return true; //no modifier selected
    m.lastselected = rw;
    m.SaveConfig();
	MyScrollText.SetContent(rw.static.getinfo() );
    return true;
}

defaultproperties
{
     Begin Object Class=GUIButton Name=MakeButton
         Caption="Make"
         WinTop=0.530000
         WinLeft=0.230000
         WinWidth=0.100000
         OnClick=WeaponModifierMenu.MakeModifier
         OnKeyEvent=WeaponModifierMenu.InternalOnKeyEvent
     End Object
     b_Make=GUIButton'mcgRPG1_9_9_1.WeaponModifierMenu.MakeButton'

     Begin Object Class=GUIButton Name=CloseButton
         Caption="Close"
         WinTop=0.530000
         WinLeft=0.670000
         WinWidth=0.100000
         OnClick=WeaponModifierMenu.CloseClick
         OnKeyEvent=WeaponModifierMenu.InternalOnKeyEvent
     End Object
     b_Close=GUIButton'mcgRPG1_9_9_1.WeaponModifierMenu.CloseButton'

     Begin Object Class=GUILabel Name=Label
         Caption="Select a modifier, and click 'make' button to fabricate it."
         TextAlign=TXTA_Center
         TextColor=(B=255,G=255,R=255)
         WinTop=0.080000
         WinLeft=0.050000
         WinWidth=0.900000
         WinHeight=0.050000
         bBoundToParent=True
         bScaleToParent=True
     End Object
     l_Label=GUILabel'mcgRPG1_9_9_1.WeaponModifierMenu.Label'

     Begin Object Class=GUIListBox Name=ModifierList
         bVisibleWhenEmpty=True
         OnCreateComponent=ModifierList.InternalOnCreateComponent
         StyleName="AbilityList"
         Hint="Weapon modifiers."
         WinTop=0.260000
         WinLeft=0.230000
         WinWidth=0.260000
         WinHeight=0.260000
         OnClick=WeaponModifierMenu.classchanged
         OnKeyEvent=WeaponModifierMenu.InternalOnKeyEvent
     End Object
     ModifierClasses=GUIListBox'mcgRPG1_9_9_1.WeaponModifierMenu.ModifierList'

     Begin Object Class=GUIScrollTextBox Name=InfoText
         bNoTeletype=True
         CharDelay=0.002500
         EOLDelay=0.002500
         OnCreateComponent=InfoText.InternalOnCreateComponent
         WinTop=0.260000
         WinLeft=0.510000
         WinWidth=0.260000
         WinHeight=0.260000
         bNeverFocus=True
         OnKeyEvent=WeaponModifierMenu.InternalOnKeyEvent
     End Object
     MyScrollText=GUIScrollTextBox'mcgRPG1_9_9_1.WeaponModifierMenu.InfoText'

     WinHeight=0.400000
}

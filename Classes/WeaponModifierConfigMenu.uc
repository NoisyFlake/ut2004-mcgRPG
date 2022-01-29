class WeaponModifierConfigMenu extends LockedFloatingWindow;


var() automated GUIMultiOptionListBox	lb_Config;
var() GUIMultiOptionList li_Config;

struct Modifierstruct
{
    var() int MinModifier;
    var() int MaxModifier;
};

var() array<Modifierstruct> Modifiers;

struct Optionstruct
{
    var() moNumericEdit MinModifier;
    var() moNumericEdit MaxModifier;
};

var() array<Optionstruct> ops;
var() array<class<rpgweapon> > classes;

function InitComponent(GUIController MyController, GUIComponent MyComponent)
{
	Super.InitComponent(MyController, MyComponent);

	sb_Main.LeftPadding = 0.01;
	sb_Main.RightPadding = 0.01;
	sb_Main.ManageComponent(lb_Config);
	li_Config = lb_Config.List;
	lb_Config.NumColumns = 2;
	li_Config.NumColumns = 2;
	li_Config.bHotTrack = True;
	Initialize();
}

function Initialize()
{
	local int i,j,k;
	local bool bTemp;
	local moNumericEdit NewComp;
    local array<class<rpgweapon> > r;

	li_Config.Clear();

    r = class'MutMCGRPG'.default.AllWeaponClass;
    classes.Insert(0, r.Length);

    k = -1;
    for(j = 0; j < classes.Length; j++)
    {
        if(k > -1)
            r.Remove(k,1);
        for(i = 0; i < r.Length; i++)
        {
            if(classes[j] == none || asc(left(caps(classes[j].static.magicname() ),1) ) > asc(left(caps(r[i].static.magicname() ),1) ) ||
                (len(classes[j].static.magicname() ) > 1 && len(r[i].static.magicname() ) > 1 &&
                asc(left(caps(classes[j].static.magicname() ),1) ) == asc(left(caps(r[i].static.magicname() ),1) ) &&
                asc(mid(caps(classes[j].static.magicname() ),1,1) ) > asc(mid(caps(r[i].static.magicname() ),1,1) ) ) )
            {
                classes[j] = r[i];
                k = i;
            }
        }
    }

	bTemp = Controller.bCurMenuInitialized;
	Controller.bCurMenuInitialized = False;
    Modifiers.Insert(0,classes.Length);
    ops.Insert(0,classes.Length);
	for (i = 0; i < classes.Length; i++)
	{
	    AddHeader(classes[i].static.magicname(), i == 0);
	    NewComp = AddOption("Minimum Modifier ");
	    if (NewComp != None)
	    {
	        NewComp.Tag = i;
	        NewComp.LabelJustification = TXTA_Right;
	        NewComp.ComponentJustification = TXTA_Left;
	        NewComp.bAutoSizeCaption = True;
	        NewComp.SetComponentValue(classes[i].default.MinModifier);
	        Modifiers[i].MinModifier = classes[i].default.MinModifier;
            NewComp.Setup( 0, classes[i].default.MaxModifier,
            NewComp.MyNumericEdit.Step);
            ops[i].MinModifier = NewComp;
        }
	    //AddHeader("", i == 0);
	    NewComp = AddOption("Maximum Modifier ");
	    if (NewComp != None)
	    {
	        NewComp.Tag = i;
	        NewComp.LabelJustification = TXTA_Right;
	        NewComp.ComponentJustification = TXTA_Left;
	        NewComp.bAutoSizeCaption = True;
	        NewComp.SetComponentValue(classes[i].default.MaxModifier);
	        Modifiers[i].MaxModifier = classes[i].default.MaxModifier;
            NewComp.Setup( classes[i].default.MinModifier, 100000000,
            NewComp.MyNumericEdit.Step);
            ops[i].MaxModifier = NewComp;
	    }
	}
	Controller.bCurMenuInitialized = bTemp;
}

function AddHeader(string s, bool InitialRow)
{
	local int ModResult, i;

	//	If the GUIMultiOptionList has more than one column, add a spacer component
	//	for each column until we are back to the first column
	ModResult = li_Config.Elements.Length % lb_Config.NumColumns;
	while (ModResult-- > 0)
		li_Config.AddItem( "XInterface.GUIListSpacer" );

	if (!InitialRow)
		for (i = 0; i < lb_Config.NumColumns; i++)
			li_Config.AddItem( "XInterface.GUIListSpacer" );
	i = 0;

	// We are now at the first column - safe to add a header row
	li_Config.AddItem( "XInterface.GUIListHeader",, s );
	while (++i < lb_Config.NumColumns)
		li_Config.AddItem( "XInterface.GUIListHeader" );
}

function moNumericEdit AddOption(string DisplayName)
{
	local bool bTemp;
	local moNumericEdit NewComp;

	bTemp = Controller.bCurMenuInitialized;
	Controller.bCurMenuInitialized = False;
	NewComp = moNumericEdit(li_Config.AddItem("XInterface.moNumericEdit",,DisplayName) );
	if (NewComp == None)
        return none;
	NewComp.bAutoSizeCaption = True;
	NewComp.ComponentWidth = 0.4;

	Controller.bCurMenuInitialized = bTemp;
	return NewComp;
}

function InternalOnChange(GUIComponent Sender)
{
	local int i;
	local moNumericEdit mo;

	if (GUIMultiOptionList(Sender) != None)
	{
		mo = moNumericEdit(GUIMultiOptionList(Sender).Get() );
		i = mo.Tag;
		if (i >= 0 && i < classes.Length)
		{
		    if(mo.Caption ~= "Minimum Modifier ")
		    {
			    Modifiers[i].MinModifier = int(mo.GetComponentValue());
                ops[i].MaxModifier.Setup( Modifiers[i].MinModifier, 100000000, mo.MyNumericEdit.Step);
		    }
			else
			{
			    Modifiers[i].MaxModifier = int(mo.GetComponentValue());
                ops[i].MinModifier.Setup( 0, Modifiers[i].MaxModifier, mo.MyNumericEdit.Step);
            }
		}
	}
}

function InternalOnCreateComponent(GUIComponent NewComp, GUIComponent Sender)
{
	if (GUIMultiOptionList(NewComp) != None)
	{
		GUIMultiOptionList(NewComp).bDrawSelectionBorder = False;
		GUIMultiOptionList(NewComp).ItemPadding = 0.15;

		if (Sender == lb_Config)
			lb_Config.InternalOnCreateComponent(NewComp, Sender);
	}

	Super.InternalOnCreateComponent(NewComp,Sender);
}

function Closed(GUIComponent Sender, bool bCancelled)
{
    local int i;
	Super.Closed(Sender,bCancelled);
	if ( !bCancelled )
	    for (i = 0; i < classes.Length; i++)
	    {
	        classes[i].default.MinModifier = Modifiers[i].MinModifier;
	        classes[i].default.MaxModifier = Modifiers[i].MaxModifier;
	        classes[i].static.StaticSaveConfig();
        }
}

defaultproperties
{
     Begin Object Class=GUIMultiOptionListBox Name=ConfigList
         bVisibleWhenEmpty=True
         OnCreateComponent=WeaponModifierConfigMenu.InternalOnCreateComponent
         WinTop=0.143333
         WinLeft=0.037500
         WinWidth=0.918753
         WinHeight=0.697502
         RenderWeight=0.900000
         TabOrder=1
         bBoundToParent=True
         bScaleToParent=True
         OnChange=WeaponModifierConfigMenu.InternalOnChange
     End Object
     lb_Config=GUIMultiOptionListBox'mcgRPG1_9_9_1.WeaponModifierConfigMenu.ConfigList'

     SubCaption="Modifier Configuration"
     WindowName="RPG Weapon Configuration Page"
}

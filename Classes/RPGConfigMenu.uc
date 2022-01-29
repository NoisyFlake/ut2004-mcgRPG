class RPGConfigMenu extends LockedFloatingWindow;

const CONFIGNUM = 2;
var() automated GUIMultiOptionListBox lb_Config;
var() automated GUIButton b_Reset;
var() GUIMultiOptionList li_Config;
var() PlayInfo MutInfo;
var() bool bIsMultiplayer;
var() localized string CustomConfigText[CONFIGNUM], ConfigMenuClassName[CONFIGNUM], ConfigButtonText, EditButtonText, NoPropsMessage;
var() config string DynArrayPropertyMenu;

function InitComponent(GUIController MyController, GUIComponent MyComponent)
{
	Super.InitComponent(MyController, MyComponent);

	sb_Main.LeftPadding = 0.01;
	sb_Main.RightPadding = 0.01;
	sb_Main.ManageComponent(lb_Config);
    if(MutatorConfigMenu(ParentPage) != none && MutatorConfigMenu(ParentPage).MutInfo != none)
        MutInfo = MutatorConfigMenu(ParentPage).MutInfo;
    else
	    MutInfo = new(None) class'PlayInfo';

	li_Config = lb_Config.List;
	li_Config.OnCreateComponent=ListOnCreateComponent;
	li_Config.bHotTrack = True;
	Initialize();
}

function bool InternalOnClick(GUIComponent Sender)
{
    local guicontroller g;
	if ( Sender == b_OK )
	{
		Controller.CloseMenu(false);
		return true;
	}

	if ( Sender == b_Cancel )
	{
		Controller.CloseMenu(true);
		return true;
	}

	if ( Sender == b_Reset )
	{
	    class'MutMCGRPG'.static.StaticClearConfig("SaveDuringGameInterval");
	    class'MutMCGRPG'.static.StaticClearConfig("StartingLevel");
	    class'MutMCGRPG'.static.StaticClearConfig("PointsPerLevel");
	    class'MutMCGRPG'.static.StaticClearConfig("LevelDiffExpGainDiv");
	    class'MutMCGRPG'.static.StaticClearConfig("EXPForWin");
	    class'MutMCGRPG'.static.StaticClearConfig("bFakeBotLevels");
	    class'MutMCGRPG'.static.StaticClearConfig("MaxTurrets");
	    class'MutMCGRPG'.static.StaticClearConfig("WeaponModifierChance");
	    class'MutMCGRPG'.static.StaticClearConfig("bAutoAdjustMonsterLevel");
	    class'MutMCGRPG'.static.StaticClearConfig("MaxMultiKillEXP");
	    class'MutMCGRPG'.static.StaticClearConfig("InvasionAutoAdjustFactor");
	    class'MutMCGRPG'.static.StaticClearConfig("MaxLevelupEffectStacking");
	    class'MutMCGRPG'.static.StaticClearConfig("StatCaps");
	    class'MutMCGRPG'.static.StaticClearConfig("InfiniteReqEXPValue");
	    class'MutMCGRPG'.static.StaticClearConfig("BotBonusLevels");
	    class'MutMCGRPG'.static.StaticClearConfig("bExperiencePickups");
	    class'MutMCGRPG'.static.StaticClearConfig("MonthsToDelete");
	    class'MutMCGRPG'.static.StaticClearConfig("bcheckafk");
	    class'MutMCGRPG'.static.StaticClearConfig("bEXPForHealing");
	    class'MutMCGRPG'.static.StaticClearConfig("maxinv");
	    class'MutMCGRPG'.static.StaticClearConfig("bTeamBasedEXP");
	    class'RPGArtifactManager'.static.ResetConfig();
	    g = Controller;
		Controller.CloseMenu(true);
		g.CloseMenu(true);
		return true;
	}

	return false;
}

function Initialize()
{
	local array<class<info> > Classes;
	local int i, j;
	local bool bTemp, bFoundMutatorSettings;
	local GUIMenuOption NewComp;

    bIsMultiplayer = MutatorConfigMenu(controller.FindMenuByClass(class'MutatorConfigMenu') ).bIsMultiplayer;
	li_Config.Clear();

	bTemp = Controller.bCurMenuInitialized;
	Controller.bCurMenuInitialized = False;
    classes[0] = class'MutMCGRPG';
	MutInfo.Init( classes );
	Classes = class'MutMCGRPG'.static.GetConfigClasses();

    for(i = 0; i < CONFIGNUM; i++)
    {
        NewComp = li_Config.AddItem( "XInterface.moButton", , CustomConfigText[i] );
        if (NewComp != None)
        {
			NewComp.bAutoSizeCaption = True;
			NewComp.ComponentWidth = 0.25;
			NewComp.OnChange = OpenCustomConfigMenu;
			moButton(NewComp).MyButton.Caption = ConfigButtonText;
			moButton(NewComp).Value = ConfigMenuClassName[i];
        }
    }

	for (i = 0; i < Classes.Length; i++)
	{
		if(!classischildof(classes[i],class'rpgability') )
		{
			for (j = 0; j < MutInfo.Settings.Length; j++)
			{
				if (MutInfo.Settings[j].ClassFrom == Classes[i] )
				{
					if ( bIsMultiplayer || !MutInfo.Settings[j].bMPOnly)
					{
						NewComp = AddRule(MutInfo.Settings[j]);
						if (NewComp != None)
						{
							NewComp.Tag = j;
							NewComp.LabelJustification = TXTA_Left;
							NewComp.ComponentJustification = TXTA_Right;
							NewComp.bAutoSizeCaption = True;
							NewComp.SetComponentValue(MutInfo.Settings[j].Value);
						}
						else
							Warn("Error adding new component to multi-options list:"$MutInfo.Settings[j].SettingName);
					}
				}
				else
					bFoundMutatorSettings = false;
			}

			// No settings found for this mutator
			if (GUIListSpacer(li_Config.Elements[li_Config.Elements.Length - 1]) != None)
				li_Config.AddItem("XInterface.GUIListSpacer",,NoPropsMessage);
		}
	}
	Controller.bCurMenuInitialized = bTemp;
}

function AddMutatorHeader(string MutatorName, bool InitialRow)
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
	li_Config.AddItem( "XInterface.GUIListHeader",, MutatorName );
	while (++i < lb_Config.NumColumns)
		li_Config.AddItem( "XInterface.GUIListHeader" );
}

function GUIMenuOption AddRule(PlayInfo.PlayInfoData NewRule)
{
	local bool bTemp;
	local string		Width, Op;
	local array<string>	Range;
	local GUIMenuOption NewComp;
	local int			i, pos;

	bTemp = Controller.bCurMenuInitialized;
	Controller.bCurMenuInitialized = False;

	switch (NewRule.RenderType)
	{
		case PIT_Check:
			NewComp = li_Config.AddItem("XInterface.moCheckbox",,NewRule.DisplayName);
			if (NewComp == None)
				break;

			NewComp.bAutoSizeCaption = True;
			break;

		case PIT_Select:
			if (NewRule.ArrayDim != -1)
			{
				NewComp = li_Config.AddItem("XInterface.moButton",,NewRule.DisplayName);
				if (NewComp == None) break;

				NewComp.bAutoSizeCaption = True;
				NewComp.ComponentWidth = 0.25;
				NewComp.OnChange = ArrayPropClicked;
				break;
			}
			NewComp = li_Config.AddItem("XInterface.moComboBox",,NewRule.DisplayName);
			if (NewComp == None)
				break;

			moCombobox(NewComp).ReadOnly(True);
			NewComp.bAutoSizeCaption = True;

			Split(NewRule.Data, ";", Range);
			for (i = 0; i+1 < Range.Length; i += 2)
				moComboBox(NewComp).AddItem(Range[i+1],,Range[i]);

			break;

		case PIT_Text:
			if ( !Divide(NewRule.Data, ";", Width, Op) )
				Width = NewRule.Data;

			pos = InStr(Width, ",");
			if (pos != -1)
				Width = Left(Width, pos);

			if (Width != "")
				i = int(Width);
			else i = -1;
			Split(Op, ":", Range);
			if (Range.Length > 1)
			{
				// Ranged data
				if (InStr(Range[0], ".") != -1)
				{
					// float edit
					NewComp = li_Config.AddItem("XInterface.moFloatEdit",,NewRule.DisplayName);
					if (NewComp == None) break;

					NewComp.bAutoSizeCaption = True;
					NewComp.ComponentWidth = 0.25;
					if (i != -1)
						moFloatEdit(NewComp).Setup( float(Range[0]), float(Range[1]), moFloatEdit(NewComp).MyNumericEdit.Step );
				}

				else
				{
					NewComp = li_Config.AddItem("XInterface.moNumericEdit",,NewRule.DisplayName);
					if (NewComp == None) break;

					moNumericEdit(NewComp).bAutoSizeCaption = True;
					NewComp.ComponentWidth = 0.25;
					if (i != -1)
						moNumericEdit(NewComp).Setup( int(Range[0]), int(Range[1]), moNumericEdit(NewComp).MyNumericEdit.Step);
				}
			}
			else if (NewRule.ArrayDim != -1)
			{
				NewComp = li_Config.AddItem("XInterface.moButton",,NewRule.DisplayName);
				if (NewComp == None) break;

				NewComp.bAutoSizeCaption = True;
				NewComp.ComponentWidth = 0.25;
				NewComp.OnChange = ArrayPropClicked;
			}

			else
			{
				NewComp = li_Config.AddItem("XInterface.moEditBox",,NewRule.DisplayName);
				if (NewComp == None) break;

				NewComp.bAutoSizeCaption = True;
				if (i != -1)
					moEditbox(NewComp).MyEditBox.MaxWidth = i;
			}
			break;
	}

	NewComp.SetHint(NewRule.Description);
	if(NewComp.ToolTip != none)
	    NewComp.ToolTip.ExpirationSeconds = float(len(NewRule.Description) ) / 5.0;
	Controller.bCurMenuInitialized = bTemp;
	return NewComp;
}

function ArrayPropClicked(GUIComponent Sender)
{
	local int i,j;
	local GUIArrayPropPage ArrayPage;
	local string ArrayMenu;
	local array<string>	Range;

	i = Sender.Tag;
	if (i < 0)
		return;

	if (MutInfo.Settings[i].ArrayDim > 1)
		ArrayMenu = Controller.ArrayPropertyMenu;
	else
		ArrayMenu = DynArrayPropertyMenu;

	if (Controller.OpenMenu(ArrayMenu, MutInfo.Settings[i].DisplayName, MutInfo.Settings[i].Value))
	{
		ArrayPage = GUIArrayPropPage(Controller.ActivePage);
		ArrayPage.Item = MutInfo.Settings[i];
		ArrayPage.OnClose = ArrayPageClosed;
		ArrayPage.SetOwner(Sender);
		if(MutInfo.Settings[i].RenderType == PIT_Select && DynArrayPageExtra(ArrayPage) != none)
		{
		    Split(MutInfo.Settings[i].Data, ";", Range);
		    DynArrayPageExtra(ArrayPage).Range = range;
            for (j = 0; j+1 < Range.Length; j += 2)
                DynArrayPageExtra(ArrayPage).Values[DynArrayPageExtra(ArrayPage).Values.Length] = Range[j];
            DynArrayPageExtra(ArrayPage).disused = DynArrayPageExtra(ArrayPage).Values;
        }
	}
}

function ArrayPageClosed(optional bool bCancelled)
{
	local GUIArrayPropPage ArrayPage;
	local GUIComponent CompOwner;

	if (!bCancelled)
	{
		ArrayPage = GUIArrayPropPage(Controller.ActivePage);
		if (ArrayPage != None)
		{
			CompOwner = ArrayPage.GetOwner();
			if (moButton(CompOwner) != None)
			{
				moButton(CompOwner).SetComponentValue(ArrayPage.GetDataString(), true);
				InternalOnChange(CompOwner);
			}
		}
	}
}

function InternalOnChange(GUIComponent Sender)
{
	local int i;
	local GUIMenuOption mo;

	if (GUIMultiOptionList(Sender) != None)
	{
		mo = GUIMultiOptionList(Sender).Get();
		i = mo.Tag;
		if (i >= 0 && i < MutInfo.Settings.Length)
			MutInfo.StoreSetting(i, mo.GetComponentValue());
	}
	else if ( GUIMenuOption(Sender) != None )
	{
		i = Sender.Tag;
		if ( i >= 0 && i < MutInfo.Settings.Length )
			MutInfo.StoreSetting(i, GUIMenuOption(Sender).GetComponentValue());
	}
}

function OpenCustomConfigMenu(GUIComponent Sender)
{
	if (moButton(Sender) != None)
		Controller.OpenMenu(moButton(Sender).Value);
}

function ListOnCreateComponent(GUIMenuOption NewComp, GUIMultiOptionList Sender)
{
	if (moButton(NewComp) != None)
	{
		moButton(NewComp).ButtonStyleName = "SquareButton";
		moButton(NewComp).ButtonCaption = EditButtonText;
	}

	NewComp.LabelJustification = TXTA_Left;
	NewComp.ComponentJustification = TXTA_Right;
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
	Super.Closed(Sender,bCancelled);
	if ( !bCancelled )
		MutInfo.SaveSettings();
}

defaultproperties
{
     Begin Object Class=GUIMultiOptionListBox Name=ConfigList
         bVisibleWhenEmpty=True
         OnCreateComponent=RPGConfigMenu.InternalOnCreateComponent
         WinTop=0.143333
         WinLeft=0.037500
         WinWidth=0.918753
         WinHeight=0.697502
         RenderWeight=0.900000
         TabOrder=1
         bBoundToParent=True
         bScaleToParent=True
         OnChange=RPGConfigMenu.InternalOnChange
     End Object
     lb_Config=GUIMultiOptionListBox'mcgRPG1_9_9_1.RPGConfigMenu.ConfigList'

     Begin Object Class=GUIButton Name=ResetButton
         Caption="Reset"
         bAutoShrink=False
         WinTop=0.911805
         WinLeft=0.314308
         WinWidth=0.159649
         TabOrder=98
         bBoundToParent=True
         OnClick=RPGConfigMenu.InternalOnClick
         OnKeyEvent=ResetButton.InternalOnKeyEvent
     End Object
     b_Reset=GUIButton'mcgRPG1_9_9_1.RPGConfigMenu.ResetButton'

     CustomConfigText(0)="Weapon Modifiers"
     CustomConfigText(1)="Ability Config"
     ConfigMenuClassName(0)="mcgRPG1_9_9_1.WeaponModifierConfigMenu"
     ConfigMenuClassName(1)="mcgRPG1_9_9_1.AbilityConfigMenu"
     ConfigButtonText="Open"
     EditButtonText="Edit"
     DynArrayPropertyMenu="mcgRPG1_9_9_1.DynArrayPageExtra"
     SubCaption="RPG Configuration"
     WindowName="Custom Configuration Page"
}

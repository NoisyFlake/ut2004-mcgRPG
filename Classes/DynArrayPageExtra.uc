class DynArrayPageExtra extends GUIDynArrayPage;

var() array<string>	Range,Values,disused,chances;
var() bool bStruct;
var() string structmember[2];
var() automated guibutton b_Delete;


function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super(LockedFloatingWindow).InitComponent(MyController, MyOwner);

	li_Values = lb_Values.List;
	sb_Main.bVisible = false;
	li_Values.OnAdjustTop = InternalOnAdjustTop;
    lb_Values.WinLeft=0.07;
    lb_Values.WinWidth=0.65;
	SizingCaption = RemoveText;
}

function SetOwner( GUIComponent NewOwner )
{
	local string str,a,b;
	local array<string> s;
	local int i;

	Owner = NewOwner;

	PropName = Item.DisplayName;
	t_WindowTitle.Caption = PropName;

	str = Item.Value;
	Strip(str, "(");
	Strip(str, ")");

	if ( Delim == "" )
		Delim = ",";

	if (Left(str, 1) == "\"")
		Delim = "\"" $ Delim $ "\"";

	Strip(str, "\"");
    if(Split(str, "(", s) > 1)
    {
        s.Remove(0,1);
        bstruct = true;
        chances.Insert(0,s.Length);
        PropValue.Insert(0,s.Length);
        for(i = 0; i < s.Length; i++)
        {
            if(i < s.Length - 1)
                strip(s[i],"),");
            else
                strip(s[i],")");
            divide(s[i],",",a,b);
            divide(a,"=",structmember[0],PropValue[i]);
            if(left(PropValue[i],6) ~= "Class'" && right(PropValue[i],1) == "'")
            {
                PropValue[i] = right(PropValue[i],len(PropValue[i]) - 6);
                PropValue[i] = left(PropValue[i],len(PropValue[i]) - 1);
            }
            divide(b,"=",structmember[1],chances[i]);
        }
    }
    else
    {
	    Split(str, Delim, PropValue);
        for(i = 0; i < PropValue.Length; i++)
        {
            if(left(PropValue[i],6) ~= "Class'" && right(PropValue[i],1) == "'")
            {
                PropValue[i] = right(PropValue[i],len(PropValue[i]) - 6);
                PropValue[i] = left(PropValue[i],len(PropValue[i]) - 1);
            }
            divide(b,"=",structmember[1],chances[i]);
        }
    }
}

function string GetDataString()
{
	local string Result;
	local array<string> s;
	local int i;
	if(!bStruct)
	     return super.GetDataString();

    s.Insert(0,PropValue.length);
    for(i = 0; i < PropValue.length; i++)
    {
        chances[i] = GUIEditBox(moComboBoxPlus(li_Values.Elements[i]).ExtraComp).TextStr;
        s[i] = "(" $ structmember[0] $ "=" $ PropValue[i] $ "," $ structmember[1] $ "=" $ chances[i] $ ")";
    }

	Result = JoinArray( s, Delim );

	if ( Left(Delim,1) == "\"" )
		Result = "\"" $ Result $ "\"";

	Result = "(" $ Result $ ")";

	return Result;
}

function InitializeList()
{
	local int i,j;
	local float AW, AL, Y;

	if ( !li_Values.bPositioned )
		return;
	bListInitialized = True;

    if (Item.RenderType == PIT_Check)
        MOType = "XInterface.moCheckBox";

    else if (Item.RenderType == PIT_Select)
    {
        if(!bStruct)
            MOType = "XInterface.moComboBox";
        else
            MOType = "XInterface.moComboBoxPlus";
    }

	AW = li_Values.ActualWidth();
	AL = li_Values.ActualLeft();

	Clear();
	if(PropValue.Length == 1 && PropValue[0] == "")
	    PropValue.Remove(0,1);
	for (i = 0; i < PropValue.Length; i++)
		AddListItem(i);
	if(MOType ~= "XInterface.moComboBox" || MOType ~= "XInterface.moComboBoxPlus")
    {
        for(j = 0; j < PropValue.Length; j++)
        {
            for(i = 0; i < disused.Length; i++)
            {
                if(disused[i] ~= PropValue[j])
                {
                    disused.Remove(i,1);
                    i = disused.Length;
                }
            }
        }
    }

	ArrayButton.Length = li_Values.ItemsPerPage;

	Y = li_Values.ClientBounds[1];
	for (i = 0; i < li_Values.ItemsPerPage; i++)
	{
		ArrayButton[i] = AddButton(i);

		ArrayButton[i].b_Remove.WinLeft = ArrayButton[i].b_Remove.RelativeLeft((AL + AW) + 5);
		ArrayButton[i].b_New.WinLeft = ArrayButton[i].b_Remove.WinLeft + 0.1;

		ArrayButton[i].b_Remove.WinTop = ArrayButton[i].b_Remove.RelativeTop(Y);
		ArrayButton[i].b_New.WinTop = ArrayButton[i].b_New.RelativeTop(Y);
		Y += li_Values.ItemHeight;
	}
	UpdateListCaptions();
	UpdateListValues();
	UpdateButtons();
	RemapComponents();
}


function UpdateListCaptions()
{
	local int i;

	for (i = 0; i < li_Values.Elements.Length; i++)
		li_Values.Elements[i].SetCaption(string(i + 1)$".: ");
}

function bool InternalOnClick(GUIComponent Sender)
{
	local int i;

	if ( Super(LockedFloatingWindow).InternalOnClick(Sender) )
		return true;

	if (GUIButton(Sender) != None)
	{
	    if(Sender == b_Delete)
	    {
	        while( li_Values.Elements.Length > 0)
	            li_Values.RemoveItem(0);
            if(MOType ~= "XInterface.moComboBox" || MOType ~= "XInterface.moComboBoxPlus")
	        {
	            disused = Values;
                if( MOType ~= "XInterface.moComboBoxPlus")
                    chances.Remove(0, PropValue.Length);
            }
	        PropValue.Remove(0, PropValue.Length);
			UpdateButtons();
			RemapComponents();
	        return false;
        }
		for (i = 0; i < ArrayButton.Length; i++)
		{
			if (Sender == ArrayButton[i].b_New)
			{
				PropValue.Insert(ArrayButton[i].b_New.Tag, 1);
                if( MOType ~= "XInterface.moComboBoxPlus")
                {
                    chances.Insert(ArrayButton[i].b_New.Tag, 1);
                    chances[ArrayButton[i].b_New.Tag] = "1";
                }
				AddListItem(ArrayButton[i].b_New.Tag).SetFocus(None);
				if(MOType ~= "XInterface.moComboBox" || MOType ~= "XInterface.moComboBoxPlus")
				{
                    PropValue[ArrayButton[i].b_New.Tag] = disused[0];
                    disused.Remove(0,1);
                }
				break;
			}

			if (Sender == ArrayButton[i].b_Remove)
			{
				if (ArrayButton[i].b_Remove.Tag != -1 && ArrayButton[i].b_Remove.Tag < li_Values.Elements.Length)
				{
					li_Values.RemoveItem(ArrayButton[i].b_Remove.Tag);
					if(MOType ~= "XInterface.moComboBox" || MOType ~= "XInterface.moComboBoxPlus")
					{
					    disused.Insert(0,1);
					    disused[0] = PropValue[ArrayButton[i].b_Remove.Tag];
                        if( MOType ~= "XInterface.moComboBoxPlus")
                            chances.Remove(ArrayButton[i].b_Remove.Tag, 1);
					}
					PropValue.Remove(ArrayButton[i].b_Remove.Tag, 1);
				}
				break;
			}
		}

		if (i < ArrayButton.Length)
		{
			UpdateListCaptions();
			UpdateButtons();
			RemapComponents();
		}

	}

	return false;
}

function GUIMenuOption AddListItem(int Index)
{
	local GUIMenuOption mo;
	mo = li_Values.InsertItem( Index, MOType, , string(index + 1)$".: " );
	mo.CaptionWidth=0.12;
	mo.ComponentWidth=0.86;
	mo.bAutoSizeCaption = True;
	mo.MyLabel.TextAlign = TXTA_Right;
    if(moComboboxPlus(mo) != none)
    {
        moComboboxPlus(mo).ExtraComp.StandardHeight = 0.03;
        moComboboxPlus(mo).ExtraComp.bBoundToParent = true;
        moComboboxPlus(mo).ExtraComp.WinLeft = 0.79;
        moComboboxPlus(mo).ExtraComp.WinTop = 0.0;
        moComboboxPlus(mo).ExtraCompSize = 0.1;
	    mo.ComponentWidth=0.64;
        moComboboxPlus(mo).bSquare = false;
        GUIEditBox(moComboBoxPlus(mo).ExtraComp).SetText(chances[index]);
        moComboboxPlus(mo).MyComboBox.OnChange = li_Values.InternalOnChange;
    }
	SetItemOptions(mo);
	return mo;
}

function InternalOnCreateComponent(GUIComponent NewComp, GUIComponent Sender)
{
    if(moComboboxPlus(NewComp) != none)
    {
        moComboboxPlus(NewComp).ExtraCompClass = "XInterface.GUIEditBox";
        moComboboxPlus(NewComp).OnCreateComponent = InternalOnCreateComponent;

    }
    if(GUIEditBox(NewComp) != none && moComboboxPlus(Sender) != none)
        GUIEditBox(NewComp).bIntOnly = true;
    else
	    Super.InternalOnCreateComponent(NewComp,Sender);
}

function InternalOnChange(GUIComponent Sender)
{
    local string temp,chance;
    local int i;
    local bool found;
	if (Sender == li_Values )
	{
		if ( li_Values.IsValid() )
		{
		    temp = PropValue[li_Values.Index];
			PropValue[li_Values.Index] = li_Values.Get().GetComponentValue();
			if(mocombobox(li_Values.Get() ) == none)
			    return;
			if(mocomboboxplus(li_Values.Get() ) != none)
			    chance = GUIEditBox(moComboBoxPlus(li_Values.Get()).ExtraComp).GetText();
			for(i = 0; i < li_Values.Elements.Length; i++)
			{
			    if(i != li_Values.Index && li_Values.Elements[i].GetComponentValue() ~= PropValue[li_Values.Index])
			    {
                    PropValue[i] = temp;
                    li_Values.Elements[i].SetComponentValue(temp,true);
			        if(mocomboboxplus(li_Values.Elements[i] ) != none)
			        {
                        GUIEditBox(moComboBoxPlus(li_Values.Get()).ExtraComp).SetText(GUIEditBox(moComboBoxPlus(li_Values.Elements[i]).ExtraComp).GetText());
                        GUIEditBox(moComboBoxPlus(li_Values.Elements[i]).ExtraComp).SetText(chance);
                    }
                    found = true;
			        break;
			    }
			}
			if(!found)
			{
			    for(i = 0; i < disused.Length; i++)
			    {
			        if(disused[i] ~= PropValue[li_Values.Index] )
			        {
			            disused[i] = temp;
			            break;
			        }
			    }
			}

		}
	}
}

function SetItemOptions( GUIMenuOption mo )
{
	local int i;
	local moComboBox co;

	co = moComboBox(mo);
    if(co != none)
	{
        co.MyComboBox.List.bInitializeList = false;
        for (i = 0; i+1 < Range.Length; i += 2)
            co.AddItem(Range[i+1],,Range[i]);
	    co.ReadOnly(true);
	    co.MyComboBox.bIgnoreChangeWhenTyping = true;
        if(moComboboxPlus(mo) != none)
            moComboboxPlus(mo).MyComboBox.OnChange = none;
	    co.SetComponentValue(disused[0],True);
        if(moComboboxPlus(mo) != none)
            moComboboxPlus(mo).MyComboBox.OnChange = li_Values.InternalOnChange;
	}
	else super.SetItemOptions(mo);
}

function ArrayControl AddButton(int Index)
{
	local ArrayControl AC;

	AC.b_New = GUIButton(AddComponent("XInterface.GUIButton",True));
	AC.b_New.TabOrder = Index+1;
	AC.b_New.Tag = Index;
	AC.b_New.OnClick = InternalOnClick;
	AC.b_New.Caption = NewText;
    AC.b_New.bAutoSize = false;
	AC.b_New.WinWidth = 0.08;

	AC.b_Remove = GUIButton(AddComponent("XInterface.GUIButton",True));
	AC.b_Remove.TabOrder = Index+1;
	AC.b_Remove.Tag = Index;
	AC.b_Remove.OnClick = InternalOnClick;
	AC.b_Remove.Caption = RemoveText;
    AC.b_Remove.bAutoSize = false;
	AC.b_Remove.WinWidth = 0.08;

	return AC;
}

function Clear()
{
	local int i;

	for (i = 0; i < ArrayButton.Length; i++)
	{
		RemoveComponent(ArrayButton[i].b_New, True);
		RemoveComponent(ArrayButton[i].b_Remove, True);
	}

	ArrayButton.Remove(0, ArrayButton.Length);
	Super.Clear();
	RemapComponents();
}

function UpdateButtons()
{
	local int i, j;

	j = li_Values.Top;

	for (i = 0; i < ArrayButton.Length; i++)
	{
		SetElementState(i, (li_Values.Elements.Length < Values.Length || (!(MOType ~= "XInterface.moComboBox") &&
            !(MOType ~= "XInterface.moComboBoxPlus") ) ) && j < li_Values.Elements.Length + 1 &&
            j < li_Values.Top + li_Values.ItemsPerPage, j < li_Values.Elements.Length && j < li_Values.Top + li_Values.ItemsPerPage);
		SetElementCaption(i, j);
		j++;
	}
    if(PropValue.Length > 0)
    {
	    if (!b_Delete.bVisible)
		    b_Delete.SetVisibility(true);
        EnableComponent(b_Delete);
	}
	else
	{
	    if (b_Delete.bVisible)
		    b_Delete.SetVisibility(false);
	    DisableComponent(b_Delete);
	}
}

defaultproperties
{
     Begin Object Class=GUIButton Name=DeleteButton
         Caption="Delete"
         bAutoShrink=False
         WinTop=0.919085
         WinLeft=0.397926
         WinWidth=0.159649
         TabOrder=98
         bBoundToParent=True
         OnClick=DynArrayPageExtra.InternalOnClick
         OnKeyEvent=DeleteButton.InternalOnKeyEvent
     End Object
     b_Delete=GUIButton'mcgRPG1_9_9_1.DynArrayPageExtra.DeleteButton'

}

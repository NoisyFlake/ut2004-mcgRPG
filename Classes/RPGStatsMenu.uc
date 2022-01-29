class RPGStatsMenu extends GUIPage
	DependsOn(RPGStatsInv)
	config(mcgRPG1991);

var() RPGStatsInv StatsInv;

var() moEditBox WeaponSpeedBox, HealthBonusBox, AdrenalineMaxBox, AttackBox, DefenseBox, AmmoMaxBox, PointsAvailableBox;
var() GUINumericEditFixed n_Adrenaline, n_Attack, n_Defense, n_Ammo, n_Health, n_WeaponSpeed;
var() GUIButton b_Reset, b_Info, b_Levels, b_Destroy, b_Delete, b_Close, b_Desc, b_Buy, b_Adrenaline, b_Attack, b_Defense, b_Ammo,
    b_Health, b_WeaponSpeed, b_Rebuild, b_rpgweapon, b_Settings;
var() GUILabel l_Level, l_EXP;
var() GUIHeader h_Title;
var() FloatingImage f_BackGround;
//Index of first stat display, first + button and first numeric edit in controls array
var() int StatDisplayControlsOffset, ButtonControlsOffset, AmtControlsOffset;
var() int NumButtonControls;
var() GUIListBox Abilities;
var() localized string CurrentLevelText, MaxText, CostText, CantBuyText;
var() array<string> rpginfo;


function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);

	WeaponSpeedBox = moEditBox(Controls[2]);
	HealthBonusBox = moEditBox(Controls[3]);
	AdrenalineMaxBox = moEditBox(Controls[4]);
	AttackBox = moEditBox(Controls[5]);
	DefenseBox = moEditBox(Controls[6]);
	AmmoMaxBox = moEditBox(Controls[7]);
	PointsAvailableBox = moEditBox(Controls[8]);
	Abilities = GUIListBox(Controls[16]);
	n_Adrenaline = GUINumericEditFixed( Controls[21] );       //it's only my mania :D
    n_Attack = GUINumericEditFixed( Controls[22] );
    n_Defense = GUINumericEditFixed( Controls[23] );
    n_Ammo = GUINumericEditFixed( Controls[24] );
    n_Health = GUINumericEditFixed( Controls[20] );
    n_WeaponSpeed = GUINumericEditFixed( Controls[19] );
    b_Reset = GUIButton( Controls[25] );
    b_Info = GUIButton( Controls[29] );
    b_Levels = GUIButton( Controls[15] );
    b_Destroy = GUIButton( Controls[30] );
    b_Delete = GUIButton( Controls[31] );
    b_Close = GUIButton( Controls[1] );
    b_Desc = GUIButton( Controls[17] );
    b_Buy = GUIButton( Controls[18] );
    b_Adrenaline = GUIButton( Controls[11] );
    b_Attack = GUIButton( Controls[12] );
    b_Defense = GUIButton( Controls[13] );
    b_Ammo = GUIButton( Controls[14] );
    b_Health = GUIButton( Controls[10] );
    b_WeaponSpeed = GUIButton( Controls[9] );
    b_rpgweapon = GUIButton( Controls[33] );
    l_Level = GUILabel( Controls[27] );
    l_EXP = GUILabel( Controls[28] );
    h_Title = GUIHeader( Controls[26] );
    f_BackGround = FloatingImage( Controls[0] );
    b_Rebuild = GUIButton( Controls[32] );
    b_Settings = GUIButton(Controls[34] );
}

function bool CloseClick(GUIComponent Sender)
{
	Controller.CloseMenu(false);

	return true;
}

function MyOnClose(optional bool bCanceled)
{
	if (StatsInv != None)
	{
		StatsInv.StatsMenu = None;
		StatsInv = None;
	}

	Super.OnClose(bCanceled);
}

function bool LevelsClick(GUIComponent Sender)
{
	Controller.OpenMenu("mcgRPG1_9_9_1.RPGPlayerLevelsMenu");
	StatsInv.ProcessPlayerLevel = RPGPlayerLevelsMenu(Controller.TopPage()).ProcessPlayerLevel;
	StatsInv.ServerRequestPlayerLevels();

	return true;
}

//Initialize, using the given RPGStatsInv for the stats data and for client->server function calls
function InitFor(RPGStatsInv Inv)
{
	local int x, y, Index, Cost, Level, OldAbilityListIndex, OldAbilityListTop;
	local RPGPlayerDataObject TempDataObject;
	local bool found;

	StatsInv = Inv;
	StatsInv.StatsMenu = self;
	if(inv.CurrentName != "")
	    h_Title.Caption = inv.CurrentName;
    if(!statsinv.bhasturret)
		Controls[30].MenuStateChange(MSAT_Disabled);
	else
		Controls[30].MenuStateChange(MSAT_Blurry);
    if(!statsinv.bCanRebuild)
		b_Rebuild.MenuStateChange(MSAT_Disabled);
	else
		b_Rebuild.MenuStateChange(MSAT_Blurry);
	WeaponSpeedBox.SetText(string(StatsInv.Data.WeaponSpeed));
	HealthBonusBox.SetText(string(StatsInv.Data.HealthBonus));
	AdrenalineMaxBox.SetText(string(StatsInv.Data.AdrenalineMax));
	AttackBox.SetText(string(StatsInv.Data.Attack));
	DefenseBox.SetText(string(StatsInv.Data.Defense));
	AmmoMaxBox.SetText(string(StatsInv.Data.AmmoMax));
	PointsAvailableBox.SetText(string(StatsInv.Data.PointsAvailable));
	GUILabel(Controls[27]).Caption = GUILabel(default.Controls[27]).Caption @ string(StatsInv.Data.Level);
	GUILabel(Controls[28]).Caption = GUILabel(default.Controls[28]).Caption @ string(StatsInv.Data.Experience) $ "/" $ string(StatsInv.Data.NeededExp);

	if (StatsInv.Data.PointsAvailable <= 0)
		DisablePlusButtons();
	else
		EnablePlusButtons();

	//show/hide buttons if stat caps reached
	for (x = 0; x < 6; x++)
		if ( StatsInv.StatCaps[x] >= 0
		     && int(moEditBox(Controls[StatDisplayControlsOffset+x]).GetText()) >= StatsInv.StatCaps[x] )
		{
			Controls[ButtonControlsOffset+x].SetVisibility(false);
			Controls[AmtControlsOffset+x].SetVisibility(false);
		}
		else
		{
			Controls[ButtonControlsOffset+x].SetVisibility(true);
			Controls[AmtControlsOffset+x].SetVisibility(true);
		}

	// on a client, the data object doesn't exist, so make a temporary one for calling the abilities' functions
	if (StatsInv.Role < ROLE_Authority)
	{
		TempDataObject = RPGPlayerDataObject(StatsInv.Level.ObjectPool.AllocateObject(class'RPGPlayerDataObject'));
		TempDataObject.InitFromDataStruct(StatsInv.Data);
	}
	else
	{
		TempDataObject = StatsInv.DataObject;
	}

	//Fill the ability listbox
	OldAbilityListIndex = Abilities.List.Index;
	OldAbilityListTop = Abilities.List.Top;
	Abilities.List.Clear();
	for (x = 0; x < StatsInv.AllAbilities.length; x++)
	{
		Index = -1;
		for (y = 0; y < StatsInv.Data.Abilities.length; y++)
		{
            if(!found && StatsInv.Data.Abilities[y] == class'DruidNoWeaponDrop' && StatsInv.Data.Abilitylevels[y] > 2 &&
                StatsInv.lastdeleted < StatsInv.level.TimeSeconds - 20.0 )
            {
                b_Delete.MenuStateChange(MSAT_Blurry);
                found = true;
            }
			if (StatsInv.AllAbilities[x] == StatsInv.Data.Abilities[y])
			{
				Index = y;
				y = StatsInv.Data.Abilities.length;
			}
		}
		if (Index == -1)
			Level = 0;
		else
			Level = StatsInv.Data.AbilityLevels[Index];

		if (Level >= StatsInv.AllAbilities[x].default.MaxLevel)
			Abilities.List.Add(StatsInv.AllAbilities[x].default.AbilityName@"("$CurrentLevelText@Level@"["$MaxText$"])", StatsInv.AllAbilities[x], string(Cost));
		else
		{
			Cost = StatsInv.AllAbilities[x].static.Cost(TempDataObject, Level);

			if (Cost <= 0)
				Abilities.List.Add(StatsInv.AllAbilities[x].default.AbilityName@"("$CurrentLevelText@Level$","@CantBuyText$")", StatsInv.AllAbilities[x], string(Cost));
			else
				Abilities.List.Add(StatsInv.AllAbilities[x].default.AbilityName@"("$CurrentLevelText@Level$","@CostText@Cost$")", StatsInv.AllAbilities[x], string(Cost));
		}
	}
	if(!found)
        b_Delete.MenuStateChange(MSAT_Disabled);
	//restore list's previous state
	Abilities.List.SetIndex(OldAbilityListIndex);
	Abilities.List.SetTopItem(OldAbilityListTop);
	UpdateAbilityButtons(Abilities);

	// free the temporary data object on clients
	if (StatsInv.Role < ROLE_Authority)
	{
		StatsInv.Level.ObjectPool.FreeObject(TempDataObject);
	}
}

function updateturretstate(bool bhasturret)
{
    if(!bhasturret)
		Controls[30].MenuStateChange(MSAT_Disabled);
	else
		Controls[30].MenuStateChange(MSAT_Blurry);
}

function bool StatPlusClick(GUIComponent Sender)
{
	local int x, SenderIndex;

	for (x = ButtonControlsOffset; x < ButtonControlsOffset + NumButtonControls; x++)
		if (Controls[x] == Sender)
		{
			SenderIndex = x;
			break;
		}

	SenderIndex -= ButtonControlsOffset;
	DisablePlusButtons();
	StatsInv.ServerAddPointTo(int(GUINumericEditFixed(Controls[SenderIndex + AmtControlsOffset]).Value), EStatType(SenderIndex) );

	return true;
}

function DisablePlusButtons()
{
	local int x;

	for (x = ButtonControlsOffset; x < ButtonControlsOffset + NumButtonControls; x++)
		Controls[x].MenuStateChange(MSAT_Disabled);
}

function LoseFocus(GUIComponent Sender)
{
    super.LoseFocus(sender);

    if (MenuState != MSAT_Disabled)
    {
        setfocus(b_Close);
    }
}

function EnablePlusButtons()
{
	local int x;

	for (x = ButtonControlsOffset; x < ButtonControlsOffset + NumButtonControls; x++)
		Controls[x].MenuStateChange(MSAT_Blurry);

	for (x = AmtControlsOffset; x < AmtControlsOffset + NumButtonControls; x++)
	{
		GUINumericEditFixed(Controls[x]).MaxValue = StatsInv.Data.PointsAvailable;
		GUINumericEditFixed(Controls[x]).CalcMaxLen();
		if (int(GUINumericEditFixed(Controls[x]).Value) > StatsInv.Data.PointsAvailable)
			GUINumericEditFixed(Controls[x]).SetValue(StatsInv.Data.PointsAvailable);
	}
}

function bool UpdateAbilityButtons(GUIComponent Sender)
{
	local int Cost;

	Cost = int(Abilities.List.GetExtra());
	if (Cost <= 0 || Cost > StatsInv.Data.PointsAvailable)
		Controls[18].MenuStateChange(MSAT_Disabled);
	else
		Controls[18].MenuStateChange(MSAT_Blurry);

	return true;
}

function bool ShowAbilityDesc(GUIComponent Sender)
{
	local class<RPGAbility> Ability;

	Ability = class<RPGAbility>(Abilities.List.GetObject() );
	if(ability == none)
        return false; //no ability selected
	Controller.OpenMenu("mcgRPG1_9_9_1.RPGAbilityDescMenu");
	RPGAbilityDescMenu(Controller.TopPage()).t_WindowTitle.Caption = Ability.default.AbilityName;
	RPGAbilityDescMenu(Controller.TopPage()).MyScrollText.SetContent(Ability.static.getinfo() );

	return true;
}

function bool Showinfopage(GUIComponent Sender)
{
    local string s;
    local int i;
	Controller.OpenMenu("mcgRPG1_9_9_1.RPGInfoPage");
	RPGInfoPage(Controller.TopPage()).t_WindowTitle.Caption = "About RPG";
	for(i = 0; i < rpginfo.Length; i++)
	    s$=rpginfo[i];
	RPGInfoPage(Controller.TopPage()).MyScrollText.SetContent(s);

	return true;
}

function bool BuyAbility(GUIComponent Sender)
{
	DisablePlusButtons();
	Controls[18].MenuStateChange(MSAT_Disabled);
	StatsInv.ServerAddAbility(class<RPGAbility>(Abilities.List.GetObject()));

	return true;
}

function bool ResetClick(GUIComponent Sender)
{
	Controller.OpenMenu("mcgRPG1_9_9_1.RPGResetConfirmPage");
	RPGResetConfirmPage(Controller.TopPage()).StatsMenu = self;
	return true;
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
        mouseclicked(controller.ActiveControl, state, delta);
        return true;
    }
    return false;
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

function bool destroyturrets(GUIComponent Sender)
{
    statsinv.destroyturrets();
    return true;
}

function toggleskinquality(GUIComponent Sender)
{
    if( (statsinv.SkinQuality == sq_high && mocombobox(sender).GetText() ~= "Normal") || (statsinv.SkinQuality == sq_normal && mocombobox(sender).GetText() ~= "High") )
        statsinv.toggleskinquality();
}

function bool deleteweapons(GUIComponent Sender)
{
    statsinv.deleteweapons();
    statsinv.lastdeleted = statsinv.Level.TimeSeconds;
    b_Delete.MenuStateChange(MSAT_Disabled);
    return true;
}

function bool rebuild(GUIComponent Sender)
{
    if(statsinv != none && statsinv.bCanRebuild)
    {
        statsinv.rebuild();
        statsinv.bCanRebuild = false;
    }
    b_Rebuild.MenuStateChange(MSAT_Disabled);
    return true;
}

function bool NotifyLevelChange()
{
    bPersistent = false;
    return super.NotifyLevelChange();
}

function bool ShowSettingsMenu(GUIComponent Sender)
{
	Controller.OpenMenu("mcgRPG1_9_9_1.RPGSettingsMenu");
	return true;
}

function bool ShowWeaponMenu(GUIComponent Sender)
{
	Controller.OpenMenu("mcgRPG1_9_9_1.WeaponModifierInfoPage");
	return true;
}

defaultproperties
{
     StatDisplayControlsOffset=2
     ButtonControlsOffset=9
     AmtControlsOffset=19
     NumButtonControls=6
     CurrentLevelText="Current Level:"
     MaxText="MAX"
     CostText="Cost:"
     CantBuyText="Can't Buy"
     rpginfo(0)="MCGRPG is an RPG (Role Playing Game) system for UT2004. This means a level system, where you can build your character by spend points to stats, and abilities. "
     rpginfo(1)="You can gain point by step to higher levels by collecting EXP (experience points) from killing opponents, and complete objectives."
     rpginfo(2)="Depends on the server config, you gain extra points by killing a stronger (higher level) player, can have weapons with magical properties, and artifacts."
     rpginfo(3)="mcgRPG is a special version of UT2004RPG with many of bug fix, more abilities, and comfortable playing. | Magic weapons: most of magic weapons take effect during taking damage."
     rpginfo(4)="'Protection' reduces the damage you take, magic weapon with no extra name, but with a number do higher damage, than the normal one (example flak cannon +10 do 100% more damage, than a normal flak cannon). 'Energy' gives you adrenaline depends on damage you do."
     rpginfo(5)="'Knockback' push your opponent, when you hit him, and do some phsysics change (example a flying players fall down, when take damage with knockback). 'Force' shoot faster projectiles, 'freezing' slow down, 'null entropy' stops the opponent."
     rpginfo(6)="If you hold a 'sturdy' weapon, damages can't push you, only if it did by a knockback. 'Piercing' ignores shield, 'Healing' heals you, or your teammate, 'Vampiric' heals you depends on damage on opponent, 'Vorpal' hits do instant kill randomly."
     rpginfo(7)="Artifacts: you can use them by command 'activateitem', if you have enough adrenaline. | You can fly with the 'boots of flight', teleport to a random pathnode with 'teleporter', do electric shock to near opponents with the 'lightning rod', do triple damage with 'triple damage', make your magic weapon's modifier double with 'double magic modifier', and put yourself in god mode with the 'globe of invulnerability'."
     rpginfo(8)="New artifact 'turret launcher' spawns a turret, that kills your enemies. | About the stat system: | when you spend your stat points, every 5 points to weapon speed stat increase your weapons' firing speed by 2%, every 2 points in health bonus increase your (or your vehicle's) starting health by 3 health points, 2 points in damage bonus increase your damages by 1%, in damage reduction decrease the damage you take by 1%."
     rpginfo(9)="Every points in max adrenaline stat increase your max adrenaline by 1, in max ammo stat increase your all weapons' maximum ammo, and ammo pickups' amount by 1%. | Damage bonus, and damage reduction stat working: If your db higher, than the opponent's dr, your damage multiplying by 1+your db, if your db lower, your damage divide by 1+ the opponents dr."
     rpginfo(10)="Example: your db is 200% higher, than opponents dr, you damages triple, than normally, if your opponents dr 100% higher, than your db, you damages half of normal. | Important: Weapon skin sytem changed."
     rpginfo(11)="Default you see the new skins, but it may cause bugs/crash (maybe it request very strong performance). If you had problem with it, you can switch back to the old system by clicking on the 'weapon skin quality' button. | If you have turrets,"
     rpginfo(12)=" you can destroy them with the 'Kill Turrets' button (not get back adrenaline). If you are in your turret, you can unlock it for your teammates. If you have denial 3, you can delete the stored weapons with the 'delete weaponlist' button."
     rpginfo(13)="You can manage your characters, and set up some things in the settings menu, and read some info about RPG weapons in the RPG weapon menu."
     bRenderWorld=True
     bPersistent=True
     bAllowedAsLast=True
     OnClose=RPGStatsMenu.MyOnClose
     Begin Object Class=FloatingImage Name=FloatingFrameBackground
         Image=Texture'2K4Menus.NewControls.Display1'
         DropShadow=None
         ImageStyle=ISTY_Stretched
         ImageRenderStyle=MSTY_Normal
         WinTop=0.020000
         WinLeft=0.000000
         WinWidth=1.000000
         WinHeight=0.980000
         RenderWeight=0.000003
     End Object
     Controls(0)=FloatingImage'mcgRPG1_9_9_1.RPGStatsMenu.FloatingFrameBackground'

     Begin Object Class=GUIButton Name=CloseButton
         Caption="Close"
         WinTop=0.900000
         WinLeft=0.575000
         WinWidth=0.200000
         OnClick=RPGStatsMenu.CloseClick
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(1)=GUIButton'mcgRPG1_9_9_1.RPGStatsMenu.CloseButton'

     Begin Object Class=moEditBox Name=WeaponSpeedSelect
         bReadOnly=True
         CaptionWidth=0.650000
         Caption="Weapon Speed Bonus (%)"
         OnCreateComponent=WeaponSpeedSelect.InternalOnCreateComponent
         IniOption="@INTERNAL"
         WinTop=0.117448
         WinLeft=0.220000
         WinWidth=0.362000
         WinHeight=0.040000
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(2)=moEditBox'mcgRPG1_9_9_1.RPGStatsMenu.WeaponSpeedSelect'

     Begin Object Class=moEditBox Name=HealthBonusSelect
         bReadOnly=True
         CaptionWidth=0.650000
         Caption="Health Bonus"
         OnCreateComponent=HealthBonusSelect.InternalOnCreateComponent
         IniOption="@INTERNAL"
         WinTop=0.197448
         WinLeft=0.220000
         WinWidth=0.362000
         WinHeight=0.040000
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(3)=moEditBox'mcgRPG1_9_9_1.RPGStatsMenu.HealthBonusSelect'

     Begin Object Class=moEditBox Name=AdrenalineMaxSelect
         bReadOnly=True
         CaptionWidth=0.650000
         Caption="Max Adrenaline Bonus"
         OnCreateComponent=AdrenalineMaxSelect.InternalOnCreateComponent
         IniOption="@INTERNAL"
         WinTop=0.277448
         WinLeft=0.220000
         WinWidth=0.362000
         WinHeight=0.040000
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(4)=moEditBox'mcgRPG1_9_9_1.RPGStatsMenu.AdrenalineMaxSelect'

     Begin Object Class=moEditBox Name=AttackSelect
         bReadOnly=True
         CaptionWidth=0.650000
         Caption="Damage Bonus (%)"
         OnCreateComponent=AttackSelect.InternalOnCreateComponent
         IniOption="@INTERNAL"
         WinTop=0.357448
         WinLeft=0.220000
         WinWidth=0.362000
         WinHeight=0.040000
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(5)=moEditBox'mcgRPG1_9_9_1.RPGStatsMenu.AttackSelect'

     Begin Object Class=moEditBox Name=DefenseSelect
         bReadOnly=True
         CaptionWidth=0.650000
         Caption="Damage Reduction (%)"
         OnCreateComponent=DefenseSelect.InternalOnCreateComponent
         IniOption="@INTERNAL"
         WinTop=0.437448
         WinLeft=0.220000
         WinWidth=0.362000
         WinHeight=0.040000
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(6)=moEditBox'mcgRPG1_9_9_1.RPGStatsMenu.DefenseSelect'

     Begin Object Class=moEditBox Name=MaxAmmoSelect
         bReadOnly=True
         CaptionWidth=0.650000
         Caption="Max Ammo Bonus (%)"
         OnCreateComponent=MaxAmmoSelect.InternalOnCreateComponent
         IniOption="@INTERNAL"
         WinTop=0.517448
         WinLeft=0.220000
         WinWidth=0.362000
         WinHeight=0.040000
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(7)=moEditBox'mcgRPG1_9_9_1.RPGStatsMenu.MaxAmmoSelect'

     Begin Object Class=moEditBox Name=PointsAvailableSelect
         bReadOnly=True
         CaptionWidth=0.650000
         Caption="Stat Points Available"
         OnCreateComponent=PointsAvailableSelect.InternalOnCreateComponent
         IniOption="@INTERNAL"
         WinTop=0.600000
         WinLeft=0.220000
         WinWidth=0.362000
         WinHeight=0.040000
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(8)=moEditBox'mcgRPG1_9_9_1.RPGStatsMenu.PointsAvailableSelect'

     Begin Object Class=GUIButton Name=WeaponSpeedButton
         Caption="+"
         WinTop=0.127448
         WinLeft=0.737500
         WinWidth=0.040000
         OnClick=RPGStatsMenu.StatPlusClick
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(9)=GUIButton'mcgRPG1_9_9_1.RPGStatsMenu.WeaponSpeedButton'

     Begin Object Class=GUIButton Name=HealthBonusButton
         Caption="+"
         WinTop=0.207448
         WinLeft=0.737500
         WinWidth=0.040000
         OnClick=RPGStatsMenu.StatPlusClick
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(10)=GUIButton'mcgRPG1_9_9_1.RPGStatsMenu.HealthBonusButton'

     Begin Object Class=GUIButton Name=AdrenalineMaxButton
         Caption="+"
         WinTop=0.287448
         WinLeft=0.737500
         WinWidth=0.040000
         OnClick=RPGStatsMenu.StatPlusClick
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(11)=GUIButton'mcgRPG1_9_9_1.RPGStatsMenu.AdrenalineMaxButton'

     Begin Object Class=GUIButton Name=AttackButton
         Caption="+"
         WinTop=0.367448
         WinLeft=0.737500
         WinWidth=0.040000
         OnClick=RPGStatsMenu.StatPlusClick
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(12)=GUIButton'mcgRPG1_9_9_1.RPGStatsMenu.AttackButton'

     Begin Object Class=GUIButton Name=DefenseButton
         Caption="+"
         WinTop=0.447448
         WinLeft=0.737500
         WinWidth=0.040000
         OnClick=RPGStatsMenu.StatPlusClick
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(13)=GUIButton'mcgRPG1_9_9_1.RPGStatsMenu.DefenseButton'

     Begin Object Class=GUIButton Name=AmmoMaxButton
         Caption="+"
         WinTop=0.527448
         WinLeft=0.737500
         WinWidth=0.040000
         OnClick=RPGStatsMenu.StatPlusClick
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(14)=GUIButton'mcgRPG1_9_9_1.RPGStatsMenu.AmmoMaxButton'

     Begin Object Class=GUIButton Name=LevelsButton
         Caption="See Player Levels"
         WinTop=0.900000
         WinLeft=0.225000
         WinWidth=0.200000
         OnClick=RPGStatsMenu.LevelsClick
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(15)=GUIButton'mcgRPG1_9_9_1.RPGStatsMenu.LevelsButton'

     Begin Object Class=GUIListBox Name=AbilityList
         bVisibleWhenEmpty=True
         OnCreateComponent=AbilityList.InternalOnCreateComponent
         StyleName="AbilityList"
         Hint="These are the abilities you can purchase with stat points."
         WinTop=0.650000
         WinLeft=0.225000
         WinWidth=0.435000
         WinHeight=0.140000
         OnClick=RPGStatsMenu.UpdateAbilityButtons
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(16)=GUIListBox'mcgRPG1_9_9_1.RPGStatsMenu.AbilityList'

     Begin Object Class=GUIButton Name=AbilityDescButton
         Caption="Info"
         WinTop=0.650000
         WinLeft=0.675000
         WinWidth=0.100000
         OnClick=RPGStatsMenu.ShowAbilityDesc
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(17)=GUIButton'mcgRPG1_9_9_1.RPGStatsMenu.AbilityDescButton'

     Begin Object Class=GUIButton Name=AbilityBuyButton
         Caption="Buy"
         WinTop=0.750000
         WinLeft=0.675000
         WinWidth=0.100000
         OnClick=RPGStatsMenu.BuyAbility
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(18)=GUIButton'mcgRPG1_9_9_1.RPGStatsMenu.AbilityBuyButton'

     Begin Object Class=GUINumericEditFixed Name=WeaponSpeedAmt
         Value="5"
         MinValue=5
         MaxValue=25
         Step=5
         WinTop=0.117448
         WinLeft=0.585000
         WinWidth=0.150000
         OnDeActivate=WeaponSpeedAmt.ValidateValue
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(19)=GUINumericEditFixed'mcgRPG1_9_9_1.RPGStatsMenu.WeaponSpeedAmt'

     Begin Object Class=GUINumericEditFixed Name=HealthBonusAmt
         Value="10"
         MinValue=2
         MaxValue=10
         Step=2
         WinTop=0.197448
         WinLeft=0.585000
         WinWidth=0.150000
         OnDeActivate=HealthBonusAmt.ValidateValue
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(20)=GUINumericEditFixed'mcgRPG1_9_9_1.RPGStatsMenu.HealthBonusAmt'

     Begin Object Class=GUINumericEditFixed Name=AdrenalineMaxAmt
         Value="5"
         MinValue=1
         MaxValue=5
         WinTop=0.277448
         WinLeft=0.585000
         WinWidth=0.150000
         OnDeActivate=AdrenalineMaxAmt.ValidateValue
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(21)=GUINumericEditFixed'mcgRPG1_9_9_1.RPGStatsMenu.AdrenalineMaxAmt'

     Begin Object Class=GUINumericEditFixed Name=AttackAmt
         Value="10"
         MinValue=2
         MaxValue=10
         Step=2
         WinTop=0.357448
         WinLeft=0.585000
         WinWidth=0.150000
         OnDeActivate=AttackAmt.ValidateValue
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(22)=GUINumericEditFixed'mcgRPG1_9_9_1.RPGStatsMenu.AttackAmt'

     Begin Object Class=GUINumericEditFixed Name=DefenseAmt
         Value="10"
         MinValue=2
         MaxValue=10
         Step=2
         WinTop=0.437448
         WinLeft=0.585000
         WinWidth=0.150000
         OnDeActivate=DefenseAmt.ValidateValue
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(23)=GUINumericEditFixed'mcgRPG1_9_9_1.RPGStatsMenu.DefenseAmt'

     Begin Object Class=GUINumericEditFixed Name=MaxAmmoAmt
         Value="5"
         MinValue=1
         MaxValue=5
         WinTop=0.517448
         WinLeft=0.585000
         WinWidth=0.150000
         OnDeActivate=MaxAmmoAmt.ValidateValue
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(24)=GUINumericEditFixed'mcgRPG1_9_9_1.RPGStatsMenu.MaxAmmoAmt'

     Begin Object Class=GUIButton Name=ResetButton
         Caption="Reset"
         FontScale=FNS_Small
         StyleName="ResetButton"
         WinTop=0.040000
         WinLeft=0.225000
         WinWidth=0.065000
         WinHeight=0.025000
         OnClick=RPGStatsMenu.ResetClick
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(25)=GUIButton'mcgRPG1_9_9_1.RPGStatsMenu.ResetButton'

     Begin Object Class=GUIHeader Name=TitleBar
         bUseTextHeight=True
         Caption="Stat Improvement"
         WinHeight=0.043750
         RenderWeight=0.100000
         bBoundToParent=True
         bScaleToParent=True
         bAcceptsInput=True
         bNeverFocus=False
         ScalingType=SCALE_X
     End Object
     Controls(26)=GUIHeader'mcgRPG1_9_9_1.RPGStatsMenu.TitleBar'

     Begin Object Class=GUILabel Name=LevelLabel
         Caption="Level:"
         TextAlign=TXTA_Center
         TextColor=(B=255,G=255,R=255)
         WinTop=0.047500
         WinHeight=0.025000
         bBoundToParent=True
         bScaleToParent=True
     End Object
     Controls(27)=GUILabel'mcgRPG1_9_9_1.RPGStatsMenu.LevelLabel'

     Begin Object Class=GUILabel Name=EXPLabel
         Caption="Experience:"
         TextAlign=TXTA_Center
         TextColor=(B=255,G=255,R=255)
         WinTop=0.072500
         WinHeight=0.025000
         bBoundToParent=True
         bScaleToParent=True
     End Object
     Controls(28)=GUILabel'mcgRPG1_9_9_1.RPGStatsMenu.EXPLabel'

     Begin Object Class=GUIButton Name=InfoButton
         Caption="RPG Info"
         WinTop=0.050000
         WinLeft=0.650000
         WinWidth=0.100000
         OnClick=RPGStatsMenu.Showinfopage
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(29)=GUIButton'mcgRPG1_9_9_1.RPGStatsMenu.InfoButton'

     Begin Object Class=GUIButton Name=DestroyButton
         Caption="Kill Turrets"
         WinTop=0.850000
         WinLeft=0.225000
         WinWidth=0.200000
         OnClick=RPGStatsMenu.destroyturrets
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(30)=GUIButton'mcgRPG1_9_9_1.RPGStatsMenu.DestroyButton'

     Begin Object Class=GUIButton Name=DeleteButton
         Caption="Delete weaponlist"
         WinTop=0.850000
         WinLeft=0.575000
         WinWidth=0.200000
         OnClick=RPGStatsMenu.deleteweapons
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(31)=GUIButton'mcgRPG1_9_9_1.RPGStatsMenu.DeleteButton'

     Begin Object Class=GUIButton Name=RebuildButton
         Caption="Rebuild stats"
         WinTop=0.070000
         WinLeft=0.225000
         WinWidth=0.150000
         OnClick=RPGStatsMenu.rebuild
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(32)=GUIButton'mcgRPG1_9_9_1.RPGStatsMenu.RebuildButton'

     Begin Object Class=GUIButton Name=WeaponMenu
         Caption="RPG weapon menu"
         WinTop=0.800000
         WinLeft=0.225000
         WinWidth=0.200000
         OnClick=RPGStatsMenu.ShowWeaponMenu
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(33)=GUIButton'mcgRPG1_9_9_1.RPGStatsMenu.WeaponMenu'

     Begin Object Class=GUIButton Name=SettingsMenu
         Caption="Settings"
         WinTop=0.800000
         WinLeft=0.575000
         WinWidth=0.200000
         OnClick=RPGStatsMenu.ShowSettingsMenu
         OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
     End Object
     Controls(34)=GUIButton'mcgRPG1_9_9_1.RPGStatsMenu.SettingsMenu'

     WinLeft=0.200000
     WinWidth=0.600000
     WinHeight=1.000000
     OnRightClick=RPGStatsMenu.controlclicked
     OnKeyEvent=RPGStatsMenu.InternalOnKeyEvent
}

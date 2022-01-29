class RPGWebQueryDefaults extends xWebQueryDefaults
	config(mcgRPG1991);

var() localized string DeleteAllText,InsertText;


function name ConvertStringToName(string s)  //lol fuck hacky method to solve the problem with can't cast from string to name
{
    local object o;
    foreach allobjects(class'object',o)
        if(string(o.Name) ~= s)
            break;
    if(o == none || !(string(o.Name) ~= s) )
        o = new(none,s) class'object';
    return o.Name;
}

function string GenerateAbilityOptions(String CurrentType, MutMCGRPG RPGMut)
{
    local int i;
    local string SelectedStr, OptionStr;

	for (i=0; i < RPGMut.AbilityList.Count(); i++)
	{
		if (CurrentType ~= RPGMut.AbilityList.GetItem(i))
			SelectedStr = " selected";
		else
			SelectedStr = "";

		OptionStr = OptionStr$"<option value=\""$RPGMut.AbilityList.GetItem(i)$"\""$SelectedStr$">"$RPGMut.AbilityList.GetTag(i)$"</option>";
	}
	return OptionStr;
}

function string GenerateArtifactOptions(String CurrentType, MutMCGRPG RPGMut)
{
    local int i;
    local string SelectedStr, OptionStr;

	for (i=0; i < RPGMut.ArtifactList.Count(); i++)
	{
		if (CurrentType ~= RPGMut.ArtifactList.GetItem(i))
			SelectedStr = " selected";
		else
			SelectedStr = "";

		OptionStr = OptionStr$"<option value=\""$RPGMut.ArtifactList.GetItem(i)$"\""$SelectedStr$">"$RPGMut.ArtifactList.GetTag(i)$"</option>";
	}
	return OptionStr;
}

function string GenerateModifierOptions(String CurrentType, MutMCGRPG RPGMut)
{
    local int i;
    local string SelectedStr, OptionStr;

	for (i=0; i < RPGMut.ModifierList.Count(); i++)
	{
		if (CurrentType ~= RPGMut.ModifierList.GetItem(i))
			SelectedStr = " selected";
		else
			SelectedStr = "";

		OptionStr = OptionStr$"<option value=\""$RPGMut.ModifierList.GetItem(i)$"\""$SelectedStr$">"$RPGMut.ModifierList.GetTag(i)$"</option>";
	}
	return OptionStr;
}

function bool Query(WebRequest Request, WebResponse Response)
{
    local String Filter;
    local int i,j;
	if (!CanPerform(NeededPrivs))
		return false;
	MapTitle(Response);
	for(i = 0; i < AIncMutators.Count(); i++)
	{
	    for(j = 0; j < AIncMutators.Count(); j++)
        {
            if( (j != i) && (AIncMutators.GetItem(i) == AIncMutators.GetItem(j) ) )
            {
                AIncMutators.Remove(j);
                j = AIncMutators.Count();
            }
        }
	}
	switch (Mid(Request.URI, 1))
	{
	    case DefaultsRulesPage:
            if (!MapIsChanging())
            {
	            Filter = Request.GetVariable("Filter");
	            if(Filter ~= "Ability Config" )
	            {
                    QueryAbilitySettings(Request, Response);
                    return true;
                }
	            else if(Filter ~= "mcgRPG1.9.9" )
	            {
                    QueryRPGRules(Request, Response, Filter);
                    return true;
                }
                else
                    return false;
            }
	    case "Abilities": if (!MapIsChanging()) QueryAbilityConfig(Request, Response); return true;
	    case "SuperAmmoClassNames": if (!MapIsChanging()) QuerySuperAmmoConfig(Request, Response); return true;
	    case "Levels": if (!MapIsChanging()) QueryLevelsConfig(Request, Response); return true;
	    case "AvailableArtifacts": if (!MapIsChanging()) QueryArtifactConfig(Request, Response); return true;
	    case "WeaponModifiers": if (!MapIsChanging()) QueryModifierConfig(Request, Response); return true;
	    case "StatCaps": if (!MapIsChanging()) QueryStatCapConfig(Request, Response); return true;
	    case "ModifierConfig": if (!MapIsChanging()) QueryModifierSettings(Request, Response); return true;
	    case "ArtifactClasses": if (!MapIsChanging()) QueryArtifactList(Request, Response); return true;
	}
	return false;
}

function QueryAbilityConfig(WebRequest Request, WebResponse Response )
{
	local int i, j, k, x, GameConfigIndex;
	local string PageText, Value;
	local MutMCGRPG RPGMut;
	local bool found;

	if (CanPerform("Ms"))
	{
	    RPGMut = class'MutMCGRPG'.static.GetRPGMutator(level);
        RPGMut.RemainderAbilities = RPGMut.AllAbilities;
		for( i=0; i< RPGMut.default.Abilities.Length; i++)
		{
		    for(j = 0; j < RPGMut.RemainderAbilities.Length; j++)
		        if(RPGMut.RemainderAbilities[j] == RPGMut.default.Abilities[i])
		            RPGMut.RemainderAbilities.Remove(j,1);
        }
		Response.Subst("Section", "Abilities");

        PageText = "";
        PageText = "<th nowrap>Abilities</th>";

	    GameConfigIndex = int(Request.GetVariable("GameConfigIndex", "-1"));

		if (Request.GetVariable("Update") != "")
		{
			if( GameConfigIndex > -1 )
			{
				    found = false;
					Value = "";
					Value = Request.GetVariable("Abilities");
                    for(k = 0; k < RPGMut.AllAbilities.Length; k++)
                        if(string(RPGMut.AllAbilities[k]) ~= value)
                        {
                            for(x = 0; x < RPGMut.default.Abilities.Length; x++)
                                if(RPGMut.default.Abilities[x] == RPGMut.AllAbilities[k])
                                {
                                    RPGMut.default.Abilities[x] = RPGMut.default.Abilities[GameConfigIndex];
                                    found = true;
                                    x = RPGMut.default.Abilities.Length;
                                }
                            if(!found)
                                for(x = 0; x < RPGMut.RemainderAbilities.Length; x++)
                                    if(RPGMut.RemainderAbilities[x] == RPGMut.AllAbilities[k])
                                    {
                                        RPGMut.RemainderAbilities[x] = RPGMut.default.Abilities[GameConfigIndex];
                                        x = RPGMut.RemainderAbilities.Length;
                                    }
                            RPGMut.default.Abilities[GameConfigIndex] = RPGMut.AllAbilities[k];
                            k = RPGMut.AllAbilities.Length;
                        }
                RPGMut.static.StaticSaveConfig();
				GameConfigIndex = -1;
			}
		}

		if(Request.GetVariable("Delete") != "")
		{
			if (GameConfigIndex > -1)
			{
			    RPGMut.RemainderAbilities[RPGMut.RemainderAbilities.Length] = RPGMut.default.Abilities[GameConfigIndex];
			    RPGMut.default.Abilities.Remove(GameConfigIndex,1);
                RPGMut.static.StaticSaveConfig();
				GameConfigIndex = -1;
			}
		}

		if(Request.GetVariable("Del") != "")
		{
            RPGMut.default.Abilities.Remove(0, RPGMut.default.Abilities.Length);
            RPGMut.RemainderAbilities = RPGMut.AllAbilities;
            RPGMut.static.StaticSaveConfig();
        }

		if(Request.GetVariable("New") != "")
		{
		    if(RPGMut.RemainderAbilities.Length > 0)
		    {
		        RPGMut.default.Abilities[RPGMut.default.Abilities.Length] = RPGMut.RemainderAbilities[0];
		        RPGMut.RemainderAbilities.Remove(0,1);
                RPGMut.static.StaticSaveConfig();
            }
		}
		if (Request.GetVariable("Insert") != "")
		{
			if( GameConfigIndex > -1 )
			{
		        if(RPGMut.RemainderAbilities.Length > 0)
		        {
		            RPGMut.default.Abilities.Insert(GameConfigIndex,1);
		            RPGMut.default.Abilities[GameConfigIndex] = RPGMut.RemainderAbilities[0];
		            RPGMut.RemainderAbilities.Remove(0,1);
                    RPGMut.static.StaticSaveConfig();
                }
				GameConfigIndex = -1;
			}
		}

        PageText = "";
        PageText $= "<BODY><P></P><TABLE id=Table1 width=400 border=0><TBODY>";
		PageText $= "<tr><td colspan=1><form method=\"post\" action=\"Abilities?GameConfigIndex=-1"$string(i) $ "\">";   //low resolution support:D
		if(RPGMut.RemainderAbilities.Length > 0)                                                                                           //moved from bottom to top
		    PageText $= SubmitButton("New", NewText);
		if(RPGMut.default.Abilities.Length > 0)
		    PageText $= SubmitButton("Del", DeleteAllText);
		PageText $= "</form></td></tr>";                                                                                                   //------------
        RPGMut.RemainderAbilities = RPGMut.AllAbilities;
		for( i=0; i < RPGMut.default.Abilities.Length; i++)
		{
		    for(j = 0; j < RPGMut.RemainderAbilities.Length; j++)
		        if(RPGMut.RemainderAbilities[j] == RPGMut.default.Abilities[i])
		            RPGMut.RemainderAbilities.Remove(j,1);
			PageText $= "<tr><form method=\"post\" action=\"Abilities?GameConfigIndex="$string(i) $ "\">";
		    	PageText $= "<td valign=\"top\">";
                if(i < 10)
                    PageText $= HtmlEncode("  ");
                else if(i < 100)
                    PageText $= HtmlEncode(" ");
                PageText $= i$". ";
				if( i == GameConfigIndex )
				{
				    PageText $= Select("Abilities", GenerateAbilityOptions(string(RPGMut.default.Abilities[i]),RPGMut) );
				}
				else
				{
                    PageText $=RPGMut.default.Abilities[i].default.AbilityName;
				}
				PageText $= "</td>";
	    	PageText $= "<td>";
	    	if( i == GameConfigIndex )
	    	{
				PageText $= SubmitButton("Update", Update);
				PageText $= SubmitButton("Delete", DeleteText);
				PageText $= SubmitButton("Insert", InsertText);
			}
			else
				 PageText $= SubmitButton("Edit",Edit);
			PageText $= "</td></form></tr>";
		}
        PageText $= "</TBODY></TABLE>";
		Response.Subst("Message", PageText);
		Response.Subst("PageHelp", RPGMut.default.PropsDescText[15]);
		ShowPage(Response, MessagePage);
	}
	else
		AccessDenied(Response);
}

function QueryAbilitySettings(WebRequest Request, WebResponse Response)
{
    local int i, j, k, l, GameConfigIndex;
    local String GameType, Content, Data, Op, Filter, TempStr, PageText, Value, s, t;
    local array<string> Options,values,arg;
    local class<RPGAbility> ability;
    local MutMCGRPG RPGMut;

	if (!CanPerform("Ms"))
	{
		AccessDenied(Response);
		return;
	}
    RPGMut = class'MutMCGRPG'.static.GetRPGMutator(level);
	if(Request.GetVariable("resetconfig", "") != "")
	{
	    for(j=0;j< RPGMut.default.allabilities.Length;j++)
            RPGMut.default.allabilities[j].static.StaticClearConfig();
	    RPGMut.ClearConfig("Abilities");
	    RPGMut.ClearConfig("AllAbilities");
	}
	GameType = SetGamePI(Request.GetVariable("GameType"));
	Filter = Request.GetVariable("Filter");
    GameConfigIndex = int(Request.GetVariable("GameConfigIndex", "-1"));
	Content = "";
	Response.Subst("Section", "Ability settings");
	Content $= "<table id=Table1 width=500 border=0>";
	if (Request.GetVariable("Update") != "")
	{
		if( GameConfigIndex > -1 )
		{
			Value = "";
			Value = Request.GetVariable("AllAbilities");
			if( GameConfigIndex >= RPGMut.ABILITYNUM && !(string(RPGMut.AllAbilities[GameConfigIndex]) ~= Value) )
			{
                ability = class<rpgability>(dynamicloadobject(Value, class'class') );
			    if(ability != none)
			    {
				    RPGMut.AllAbilities[GameConfigIndex] = ability;
				    RPGMut.default.AllAbilities[GameConfigIndex] = ability;
                    RPGMut.static.StaticSaveConfig();
				    GameConfigIndex = -1;
			    }
			}
			else
			{
			    s = Request.GetVariable("arg","");
			    split(s,":",arg);
				for(i = 0; i < GamePI.Settings.Length; i++)
				{
				    if(GamePI.Settings[i].ClassFrom == RPGMut.AllAbilities[GameConfigIndex] &&
                        GamePI.Settings[i].Grouping ~= Filter && GamePI.Settings[i].SecLevel <= CurAdmin.MaxSecLevel() &&
                        (GamePI.Settings[i].ExtraPriv == "" || CanPerform(GamePI.Settings[i].ExtraPriv)))
				    {
			            if ( GamePI.Settings[i].ArrayDim != -1 || GamePI.Settings[i].bStruct )
			            {
			                for(j = 0; j < arg.Length; j++)
			                {
                                divide(arg[j],",",s,t);
                                if(int(s) == i)
                                {
                                    l = int(t);
                                    j = arg.Length;
                                }
                            }
                            TempStr = "(";
                            k = 0;
                            while(k < l)
                            {
                                s = HtmlDecode(Request.GetVariable(GamePI.Settings[i].SettingName $ string(k), ""));
                                TempStr $= s;
                                if(k < l - 1)
                                    TempStr $= ",";
                                k++;
                            }
                            TempStr $= ")";
                        }
			            else
			                TempStr = HtmlDecode(Request.GetVariable(GamePI.Settings[i].SettingName, "") );
				        GamePI.StoreSetting(i, TempStr, GamePI.Settings[i].Data);
				    }
				}
			}
		}
	}

	else if(Request.GetVariable("Delete") != "")
	{
		if (GameConfigIndex >= RPGMut.ABILITYNUM)
		{
			RPGMut.AllAbilities.Remove(GameConfigIndex,1);
			RPGMut.default.AllAbilities.Remove(GameConfigIndex,1);
            RPGMut.static.StaticSaveConfig();
			GameConfigIndex = -1;
		}
	}

	else if(Request.GetVariable("Del") != "")
	{
        RPGMut.AllAbilities.Length = RPGMut.ABILITYNUM;
        RPGMut.default.AllAbilities.Length = RPGMut.ABILITYNUM;
        RPGMut.static.StaticSaveConfig();
    }

    else if(Request.GetVariable("New") != "")
    {
        RPGMut.AllAbilities.Insert(RPGMut.AllAbilities.Length,1);
        RPGMut.default.AllAbilities.Insert(RPGMut.AllAbilities.Length,1);
    }
    else if( GameConfigIndex > -1 )
    {
        for (i = 0; i<GamePI.Settings.Length; i++)
	    {
	        if(GamePI.Settings[i].ClassFrom != RPGMut.AllAbilities[GameConfigIndex] || !(GamePI.Settings[i].Grouping ~= Filter) ||
                GamePI.Settings[i].SecLevel > CurAdmin.MaxSecLevel() || (GamePI.Settings[i].ExtraPriv != "" &&
                !CanPerform(GamePI.Settings[i].ExtraPriv) ) )
                continue;
		    if ( GamePI.Settings[i].ArrayDim != -1 || GamePI.Settings[i].bStruct )
		    {
			    values.Remove(0,values.Length);
			    s = GamePI.Settings[i].Value;
			    if(left(s,1) == "(")
			        s = right(s,len(s) - 1);
			    if(right(s,1) == ")")
			        s = left(s,len(s) - 1);
                split(s,",",values);
                if(GamePI.Settings[i].RenderType == PIT_Select)
                    divide(GamePI.Settings[i].Data,";",s,t);
                else
                    s = "";
                if(values.Length == 1 && values[0] == "")
                    values.Remove(0,1);
                for(j = 0; j < values.Length; j++)
                {
			        if(left(values[j],1) == "\"")
			            values[j] = right(values[j],len(values[j]) - 1);
			        if(right(values[j],1) == "\"")
			            values[j] = left(values[j],len(values[j]) - 1);
                }
                for(j = 0; j < values.Length + 1; j++)
                {
		            if(Request.GetVariable("Insert,"$i$","$j,"") != "")
		            {
		                values.insert(j,1);
		                if(s != "")
                            values[j] = s;
		                else
                            values[j] = "Value";
                        TempStr = "(";
                        k = 0;
                        while(k < values.Length)
                        {
                            TempStr $= values[k];
                            if(k < values.Length - 1)
                                TempStr $= ",";
                            k++;
                        }
                        TempStr $= ")";
                        GamePI.StoreSetting(i, TempStr, GamePI.Settings[i].Data);
		                break;
		            }
		            else if(Request.GetVariable("DeleteItem,"$i$","$j,"") != "")
		            {
		                values.remove(j,1);
                        TempStr = "(";
                        k = 0;
                        while(k < values.Length)
                        {
                            TempStr $= values[k];
                            if(k < values.Length - 1)
                                TempStr $= ",";
                            k++;
                        }
                        TempStr $= ")";
                        GamePI.StoreSetting(i, TempStr, GamePI.Settings[i].Data);
		                break;
		            }
		        }
		    }
	    }
    }
    PageText = "";
	PageText $= "<tr><td colspan=1><form method=\"post\" action=\""$DefaultsRulesPage$"?GameConfigIndex=-1&Filter="$Filter $ "\">";
    PageText $= SubmitButton("New", NewText);
    PageText $= SubmitButton("resetconfig","Reset Config");
	if(RPGMut.AllAbilities.Length > RPGMut.ABILITYNUM)
        PageText $= SubmitButton("Del", DeleteAllText);
	PageText $= "</form></td></tr>";
    Response.Subst("DisplayText", PageText );
    Response.Subst("Content", "");
    Response.Subst("FormObject", WebInclude(NowrapLeft));
    Content $= WebInclude(DefaultsRowPage);
    for(i = 0; i < RPGMut.AllAbilities.Length; i++)
    {
        PageText = "";
    	t = "";
	    for (k = 0; k<GamePI.Settings.Length; k++)
	    {
	        if(GamePI.Settings[k].ClassFrom != RPGMut.AllAbilities[i] || !(GamePI.Settings[k].Grouping ~= Filter) ||
                GamePI.Settings[k].SecLevel > CurAdmin.MaxSecLevel() || (GamePI.Settings[k].ExtraPriv != "" &&
                !CanPerform(GamePI.Settings[k].ExtraPriv) ) )
                continue;
		    if( GamePI.Settings[k].ArrayDim != -1 || GamePI.Settings[k].bStruct )
		    {
		        values.Remove(0,values.Length);
		        s = GamePI.Settings[k].Value;
		        if(left(s,1) == "(")
		            s = right(s,len(s) - 1);
		        if(right(s,1) == ")")
			        s = left(s,len(s) - 1);
                split(s,",",values);
                if(values.Length == 1 && values[0] == "")
                    values.Remove(0,1);
                if(t == "")
                    t = k$","$string(values.length);
                else
                    t $= ":"$k$","$string(values.length);
			}
        }
        content $= "<form method=\"post\" action=\""$DefaultsRulesPage$"?GameConfigIndex="$string(i)$"&Filter="$Filter $ "&arg="$t$"\">";

        if( i == GameConfigIndex )
        {
            if(i < 10)
                PageText $= HtmlEncode("  ");
            else if(i < 100)
                PageText $= HtmlEncode(" ");
            PageText $= i$". ";
            if(i >= RPGMut.ABILITYNUM)
                PageText $= Textbox("AllAbilities", 45, 128, string(RPGMut.AllAbilities[i]) );
            else
                PageText $= RPGMut.AllAbilities[i].default.AbilityName;
    	    PageText $= "<td>";
            PageText $= SubmitButton("Update",Update);
            if(GameConfigIndex >= RPGMut.ABILITYNUM)
                PageText $= SubmitButton("Delete", DeleteText);
    	    PageText $= "</td>";
            Response.Subst("DisplayText", PageText );
            Response.Subst("Content", "");
            Response.Subst("FormObject", WebInclude(NowrapLeft));
            Content $= WebInclude(DefaultsRowPage);
	        for (i = 0; i<GamePI.Settings.Length; i++)
	        {
	            if(GamePI.Settings[i].ClassFrom != RPGMut.AllAbilities[GameConfigIndex] || !(GamePI.Settings[i].Grouping ~= Filter) ||
                    GamePI.Settings[i].SecLevel > CurAdmin.MaxSecLevel() || (GamePI.Settings[i].ExtraPriv != "" &&
                    !CanPerform(GamePI.Settings[i].ExtraPriv) ) )
                    continue;
			    if ( GamePI.Settings[i].ArrayDim != -1 || GamePI.Settings[i].bStruct )
			    {
			        values.Remove(0,values.Length);
			        s = GamePI.Settings[i].Value;
			        if(left(s,1) == "(")
			            s = right(s,len(s) - 1);
			        if(right(s,1) == ")")
			            s = left(s,len(s) - 1);
                    split(s,",",values);
                    if(values.Length == 1 && values[0] == "")
                        values.Remove(0,1);
                    for(j = 0; j < values.Length; j++)
                    {
			            if(left(values[j],1) == "\"")
			                values[j] = right(values[j],len(values[j]) - 1);
			            if(right(values[j],1) == "\"")
			                values[j] = left(values[j],len(values[j]) - 1);
			            if(left(values[j],6) ~= "Class'" && right(values[j],1) == "'")
			            {
			                values[j] = right(values[j],len(values[j]) - 6);
			                values[j] = left(values[j],len(values[j]) - 1);
                        }
                    }
			        Response.Subst("HintText",HtmlEncode(GamePI.Settings[i].Description));
			        Response.Subst("DisplayText", HtmlEncode(GamePI.Settings[i].DisplayName));
			        Response.Subst("Content","");
			        Response.Subst("SecLevel", "");
			        Response.Subst("FormObject", WebInclude(NowrapLeft));
			        Content $= WebInclude(DefaultsRowPage);
			        switch ( GamePI.Settings[i].RenderType )
			        {
			            case PIT_Custom:
			            case PIT_Text:
                            for(k = 0; k < values.Length; k++)
                            {
			                    Options.Length = 0;
				                Data = "10";
				                if (GamePI.Settings[i].Data != "")
				                {
					                if ( Divide(GamePI.Settings[i].Data, ";", Data, Op) )
						                GamePI.SplitStringToArray(Options, Op, ":");
				                    else Data = GamePI.Settings[i].Data;
		                        }
				                j = Min( int(Data), 96 ); // TODO: not nice to hard code it like this
				                Op = "";
				                if (Options.Length > 1)
					                Op = " ("$Options[0]$" - "$Options[1]$")";
			                    Response.Subst("HintText","");
			                    Response.Subst("DisplayText", "&nbsp;&nbsp;&nbsp;" $ string(k) $ "&nbsp;&nbsp;");
			                    Response.Subst("SecLevel", "");
			                    PageText = Textbox(GamePI.Settings[i].SettingName $ string(k), j, int(Data),HtmlEncode(Values[k])) $ Op;
			                    if(GamePI.Settings[i].ArrayDim == 0)
			                    {
                                    PageText $= SubmitButton("Insert,"$i$","$k, InsertText);
                                    PageText $= SubmitButton("DeleteItem,"$i$","$k, DeleteText);
                                }
				                Response.Subst("Content",PageText);
				                Response.Subst("FormObject", WebInclude(NowrapLeft));
			                    Content $= WebInclude(DefaultsRowPage);
			                }
				            break;
			            case PIT_Select:
                            for(k = 0; k < values.Length; k++)
                            {
			                    Options.Length = 0;
				                Data = "";
				                GamePI.SplitStringToArray(Options, GamePI.Settings[i].Data, ";");
				                for (j = 0; (j+1)<Options.Length; j += 2)
				                {
					                Data $= ("<option value='"$Options[j]$"'");
					                If (Values[k] == Options[j])
						                Data @= "selected";
					                Data $= (">"$HtmlEncode(Options[j+1])$"</option>");
				                }
			                    Response.Subst("HintText","");
			                    Response.Subst("DisplayText", "&nbsp;&nbsp;&nbsp;" $ string(k) $ "&nbsp;&nbsp;");
			                    Response.Subst("SecLevel", "");
			                    PageText = Select(GamePI.Settings[i].SettingName $ string(k), Data);
			                    if(GamePI.Settings[i].ArrayDim == 0)
			                    {
                                    PageText $= SubmitButton("Insert,"$i$","$k, InsertText);
                                    PageText $= SubmitButton("DeleteItem,"$i$","$k, DeleteText);
                                }
				                Response.Subst("Content", PageText);
				                Response.Subst("FormObject", WebInclude(NowrapLeft));
			                    Content $= WebInclude(DefaultsRowPage);
				            }
				            break;
                    }
                    if(GamePI.Settings[i].ArrayDim == 0)
                    {
                        PageText = SubmitButton("Insert,"$i$","$k, NewText);
                        Response.Subst("HintText","");
                        Response.Subst("DisplayText", "");
                        Response.Subst("SecLevel", "");
                        Response.Subst("Content", PageText);
                        Response.Subst("FormObject", WebInclude(NowrapLeft));
                        Content $= WebInclude(DefaultsRowPage);
                    }
                    continue;
			    }

			    Options.Length = 0;
			    Response.Subst("HintText",HtmlEncode(GamePI.Settings[i].Description));
			    Response.Subst("DisplayText", HtmlEncode("       "$GamePI.Settings[i].DisplayName));
			    switch ( GamePI.Settings[i].RenderType )
			    {
			        case PIT_Custom:
			        case PIT_Text:
				        Data = "10";
				        if (GamePI.Settings[i].Data != "")
				        {
					        if ( Divide(GamePI.Settings[i].Data, ";", Data, Op) )
						        GamePI.SplitStringToArray(Options, Op, ":");
					        else Data = GamePI.Settings[i].Data;
			            }
				        j = Min( int(Data), 256 );
				        Op = "";
				        if (Options.Length > 1)
					        Op = " ("$Options[0]$" - "$Options[1]$")";
				        Response.Subst("Content", Textbox(GamePI.Settings[i].SettingName, j, int(Data),
                            HtmlEncode(GamePI.Settings[i].Value)) $ Op);
				        Response.Subst("FormObject", WebInclude(NowrapLeft));
				        break;
		            case PIT_Check:
				        if (Request.GetVariable("Update") != "" && GamePI.Settings[i].Value == "")
					        GamePI.StoreSetting(i, false);
				        Response.Subst("Content", Checkbox(GamePI.Settings[i].SettingName, GamePI.Settings[i].Value ~= string(true),
                            GamePI.Settings[i].Data != ""));
				        Response.Subst("FormObject", WebInclude(NowrapLeft));
				        break;
		            case PIT_Select:
				        Data = "";
				        GamePI.SplitStringToArray(Options, GamePI.Settings[i].Data, ";");
				        for (j = 0; (j+1)<Options.Length; j += 2)
				        {
					        Data $= ("<option value='"$Options[j]$"'");
					        If (GamePI.Settings[i].Value == Options[j])
						        Data @= "selected";
					        Data $= (">"$HtmlEncode(Options[j+1])$"</option>");
				        }
				        Response.Subst("Content", Select(GamePI.Settings[i].SettingName, Data));
				        Response.Subst("FormObject", WebInclude(NowrapLeft));
				        break;
                }
			    Content $= WebInclude(DefaultsRowPage);
            }
            Content $= "</form>";
    	    i = RPGMut.AllAbilities.Length;
        }
        else
        {
            if(i < 10)
                PageText $= HtmlEncode("  ");
            else if(i < 100)
                PageText $= HtmlEncode(" ");
            PageText $= i$". "$RPGMut.AllAbilities[i].default.AbilityName;
    	    PageText $= "<td>";
            PageText $= SubmitButton("Edit",Edit);
    	    PageText $= "</td>";
            PageText $= "</form>";
            Response.Subst("DisplayText", PageText );
            Response.Subst("Content", "");
            Response.Subst("FormObject", WebInclude(NowrapLeft));
            Content $= WebInclude(DefaultsRowPage);
        }
    }
	GamePI.SaveSettings();
	if(GameConfigIndex > -1)
	{
        for(i = GameConfigIndex + 1; i < RPGMut.AllAbilities.Length; i++)
        {
            PageText = "";
            PageText $= "<form method=\"post\" action=\""$DefaultsRulesPage$"?GameConfigIndex="$string(i)$"&Filter="$Filter $ "\">";
            if(i < 10)
                PageText $= HtmlEncode("  ");
            else if(i < 100)
                PageText $= HtmlEncode(" ");
            PageText $= i$". "$RPGMut.AllAbilities[i].default.AbilityName;
   	        PageText $= "<td>";
            PageText $= SubmitButton("Edit",Edit);
   	        PageText $= "</td>";
            PageText $= "</form>";
	        Response.Subst("HintText","");
            Response.Subst("DisplayText", PageText );
            Response.Subst("Content", "");
            Response.Subst("FormObject", WebInclude(NowrapLeft));
            Content $= WebInclude(DefaultsRowPage);
        }
    }

	if (Content == "")
		Content = CannotModify;
	Content $= "</table>";
	Content $= Hidden("Filter",Filter);
	Content $= Hidden("GameType",GameType);
	Response.Subst("Message", Content);
	Response.Subst("PageHelp", "You can add abilities from other packages to the full ability list, and change settings of abilities.");
	ShowPage(Response, MessagePage);
}

/*
<HTML><BODY><TABLE id=Table1 width=600 border=0><TBODY><TR>
<%ColumnTitles%>
<TH></TH></TR>
<%GameConfigs%>
</TBODY></TABLE></BODY></HTML>
*/
function QueryArtifactConfig(WebRequest Request, WebResponse Response )
{
	local int i, j, k, x, columns, GameConfigIndex, chance;
	local string PageText, ColumnTitle, Value;
	local MutMCGRPG RPGMut;
	local RPGArtifactManager ArtifactManager;
	local bool found;

	if (CanPerform("Ms"))
	{
	    RPGMut = class'MutMCGRPG'.static.GetRPGMutator(level);
	    ArtifactManager = RPGMut.ArtifactManager;
        ArtifactManager.UnUsedArtifacts = RPGMut.ArtifactClasses;
		for( i=0; i< ArtifactManager.AvailableArtifacts.Length; i++)
		{
		    for(j = 0; j < ArtifactManager.UnUsedArtifacts.Length; j++)
		        if(ArtifactManager.UnUsedArtifacts[j] == ArtifactManager.AvailableArtifacts[i].ArtifactClass)
		            ArtifactManager.UnUsedArtifacts.Remove(j,1);
        }
		Response.Subst("Section", "AvailableArtifacts");

        PageText = "<HTML><BODY><TABLE id=Table1 width=600 border=0><TBODY>";
	    columns = 2;
	    GameConfigIndex = int(Request.GetVariable("GameConfigIndex", "-1"));

		if (Request.GetVariable("Update") != "")
		{
			if( GameConfigIndex > -1 )
			{
				for( j=0; j < columns; j++ )
				{
				    found = false;
				    if(j == 0)
					    ColumnTitle = "ArtifactClass";
				    else
					    ColumnTitle = "Chance";
					Value = "";
					Value = Request.GetVariable(ColumnTitle);
					if(j == 0)
					{
                        for(k = 0; k < RPGMut.ArtifactClasses.Length; k++)
                        {
                            if(string(RPGMut.ArtifactClasses[k]) ~= value)
                            {
                                for(x = 0; x < ArtifactManager.AvailableArtifacts.Length; x++)
                                    if(ArtifactManager.AvailableArtifacts[x].ArtifactClass == RPGMut.ArtifactClasses[k])
                                    {
                                        chance = ArtifactManager.AvailableArtifacts[x].Chance;
                                        ArtifactManager.AvailableArtifacts[x].ArtifactClass =
                                            ArtifactManager.AvailableArtifacts[GameConfigIndex].ArtifactClass;
                                        ArtifactManager.AvailableArtifacts[x].Chance =
                                            ArtifactManager.AvailableArtifacts[GameConfigIndex].Chance;
                                        found = true;
                                        x = ArtifactManager.AvailableArtifacts.Length;
                                    }
                                if(!found)
                                {
                                    for(x = 0; x < ArtifactManager.UnUsedArtifacts.Length; x++)
                                        if(ArtifactManager.UnUsedArtifacts[x] == RPGMut.ArtifactClasses[k])
                                        {
                                            ArtifactManager.UnUsedArtifacts[x] =
                                                ArtifactManager.AvailableArtifacts[GameConfigIndex].ArtifactClass;
                                            x = ArtifactManager.UnUsedArtifacts.Length;
                                        }
                                    chance = 1;
                                }
                                ArtifactManager.AvailableArtifacts[GameConfigIndex].ArtifactClass = RPGMut.ArtifactClasses[k];
                                ArtifactManager.AvailableArtifacts[GameConfigIndex].Chance = chance;
                                k = RPGMut.ArtifactClasses.Length;
                            }
                        }
                    }
                    else
                        ArtifactManager.AvailableArtifacts[GameConfigIndex].Chance = int(value);
				}
                ArtifactManager.default.AvailableArtifacts = ArtifactManager.AvailableArtifacts;
                ArtifactManager.static.StaticSaveConfig();
				GameConfigIndex = -1;
			}
		}
		if (Request.GetVariable("Insert") != "")
		{
			if( GameConfigIndex > -1 )
			{
		        if(ArtifactManager.UnUsedArtifacts.Length > 0)
		        {
		            ArtifactManager.AvailableArtifacts.Insert(GameConfigIndex,1);
		            ArtifactManager.AvailableArtifacts[GameConfigIndex].ArtifactClass = ArtifactManager.UnUsedArtifacts[0];
		            ArtifactManager.AvailableArtifacts[GameConfigIndex].Chance = 1;
		            ArtifactManager.UnUsedArtifacts.Remove(0,1);
		            ArtifactManager.default.AvailableArtifacts = ArtifactManager.AvailableArtifacts;
		            ArtifactManager.static.StaticSaveConfig();
                }
				GameConfigIndex = -1;
			}
		}

		if(Request.GetVariable("Delete") != "")
		{
			if (GameConfigIndex > -1)
			{
			    ArtifactManager.UnUsedArtifacts[ArtifactManager.UnUsedArtifacts.Length] =
                    ArtifactManager.AvailableArtifacts[GameConfigIndex].ArtifactClass;
			    ArtifactManager.AvailableArtifacts.Remove(GameConfigIndex,1);
			    ArtifactManager.default.AvailableArtifacts.Remove(GameConfigIndex,1);
		        ArtifactManager.static.StaticSaveConfig();
				GameConfigIndex = -1;
			}
		}

		if(Request.GetVariable("Del") != "")
		{
            ArtifactManager.AvailableArtifacts.Length = 0;
            ArtifactManager.default.AvailableArtifacts.Length = 0;
            ArtifactManager.UnUsedArtifacts = RPGMut.ArtifactClasses;
		    ArtifactManager.static.StaticSaveConfig();
        }

		if(Request.GetVariable("New") != "")
		{
		    if(ArtifactManager.UnUsedArtifacts.Length > 0)
		    {
		        ArtifactManager.AvailableArtifacts.Insert(ArtifactManager.AvailableArtifacts.Length,1);
		        ArtifactManager.AvailableArtifacts[ArtifactManager.AvailableArtifacts.Length - 1].ArtifactClass =
                    ArtifactManager.UnUsedArtifacts[0];
		        ArtifactManager.AvailableArtifacts[ArtifactManager.AvailableArtifacts.Length - 1].Chance = 1;
		        ArtifactManager.UnUsedArtifacts.Remove(0,1);
		        ArtifactManager.default.AvailableArtifacts = ArtifactManager.AvailableArtifacts;
				ArtifactManager.static.StaticSaveConfig();
            }
		}

		PageText $= "<tr><td colspan=" $ columns + 1 $ "><form method=\"post\" action=\"AvailableArtifacts?GameConfigIndex=-1"$string(i) $ "\">";
		if(ArtifactManager.UnUsedArtifacts.Length > 0)
		    PageText $= SubmitButton("New", NewText);
		if(ArtifactManager.AvailableArtifacts.Length > 0)
		    PageText $= SubmitButton("Del", DeleteAllText);
		PageText $= "</form></td></tr>";
        PageText $= "<TR>";
		for( i = 0; i < columns; i++ )
		{
		    if(i == 0)
			    PageText = PageText $ "<th nowrap>" $ "ArtifactClass" $ "</th>";
		    else
			    PageText = PageText $ "<th nowrap>" $ "Chance" $ "</th>";
	    }
        PageText $= "<TH></TH>";
        PageText $= "</TR>";
        ArtifactManager.UnUsedArtifacts = RPGMut.ArtifactClasses;
		for( i=0; i< ArtifactManager.AvailableArtifacts.Length; i++)
		{
		    for(j = 0; j < ArtifactManager.UnUsedArtifacts.Length; j++)
		        if(ArtifactManager.UnUsedArtifacts[j] == ArtifactManager.AvailableArtifacts[i].ArtifactClass)
		            ArtifactManager.UnUsedArtifacts.Remove(j,1);
			PageText $= "<tr><form method=\"post\" action=\"AvailableArtifacts?GameConfigIndex="$string(i) $ "\">";
			for( j=0; j < columns; j++)
			{
		    	PageText $= "<td valign=\"top\">";
		    	if(j == 0)
		    	{
                    if(i < 10)
                        PageText $= "   ";
                    else if(i < 100)
                        PageText $= "  ";
                    else
                        PageText $= " ";
                    PageText $= i$". ";
                }
				if( i == GameConfigIndex )
				{
				    if(j == 0)
				        PageText $= Select("ArtifactClass",
                            GenerateArtifactOptions(string(ArtifactManager.AvailableArtifacts[i].ArtifactClass),RPGMut) );
                    else
				        PageText $= Textbox("Chance", 15, 64, string(ArtifactManager.AvailableArtifacts[i].Chance) );
				}
				else
				{
				    if(j == 0)
                        PageText $=ArtifactManager.AvailableArtifacts[i].ArtifactClass.default.ItemName;
                    else
                        PageText $=string(ArtifactManager.AvailableArtifacts[i].Chance);
				}
				PageText $= "</td>";
			}
	    	PageText $= "<td>";
	    	if( i == GameConfigIndex )
	    	{
				PageText $= SubmitButton("Update", Update);
				PageText $= SubmitButton("Delete", DeleteText);
				PageText $= SubmitButton("Insert", InsertText);
			}
			else
				 PageText $= SubmitButton("Edit",Edit);
			PageText $= "</td></form></tr>";
		}

        PageText $= "</TBODY></TABLE></BODY></HTML>";
		Response.Subst("Message", PageText);
		Response.Subst("PageHelp", ArtifactManager.default.PropsDescText[3]);
		ShowPage(Response, MessagePage);
	}
	else
		AccessDenied(Response);
}

function QueryArtifactList(WebRequest Request, WebResponse Response)
{
    local int i, GameConfigIndex;
    local String GameType, Content, Filter, PageText, Value;
    local class<RPGArtifact> Artifact;
    local MutMCGRPG RPGMut;
	local RPGArtifactManager ArtifactManager;

	if (!CanPerform("Ms"))
	{
		AccessDenied(Response);
		return;
	}
    RPGMut = class'MutMCGRPG'.static.GetRPGMutator(level);
    ArtifactManager = RPGMut.ArtifactManager;
	if(Request.GetVariable("resetconfig", "") != "")
	{
	    ArtifactManager.ClearConfig("AvailableArtifacts");
	    RPGMut.ClearConfig("ArtifactClasses");
	}
	GameType = SetGamePI(Request.GetVariable("GameType"));
	Filter = Request.GetVariable("Filter");
    GameConfigIndex = int(Request.GetVariable("GameConfigIndex", "-1"));
	Content = "";
	Response.Subst("Section", "Artifact Classes");
	Content $= "<table id=Table1 width=500 border=0>";
	if (Request.GetVariable("Update") != "")
	{
		if( GameConfigIndex > -1 )
		{
			Value = "";
			Value = Request.GetVariable("ArtifactClasses");
			if( GameConfigIndex >= RPGMut.ARTIFACTNUM && !(string(RPGMut.ArtifactClasses[GameConfigIndex]) ~= Value) )
			{
                Artifact = class<rpgartifact>(dynamicloadobject(Value, class'class') );
			    if(Artifact != none)
			    {
				    RPGMut.ArtifactClasses[GameConfigIndex] = Artifact;
				    RPGMut.default.ArtifactClasses[GameConfigIndex] = Artifact;
                    RPGMut.static.StaticSaveConfig();
				    GameConfigIndex = -1;
			    }
			}
		}
	}

	else if(Request.GetVariable("Delete") != "")
	{
		if (GameConfigIndex >= RPGMut.ARTIFACTNUM)
		{
			RPGMut.ArtifactClasses.Remove(GameConfigIndex,1);
			RPGMut.default.ArtifactClasses.Remove(GameConfigIndex,1);
            RPGMut.static.StaticSaveConfig();
			GameConfigIndex = -1;
		}
	}

	else if(Request.GetVariable("Del") != "")
	{
        RPGMut.ArtifactClasses.Length = RPGMut.ARTIFACTNUM;
        RPGMut.default.ArtifactClasses.Length = RPGMut.ARTIFACTNUM;
        RPGMut.static.StaticSaveConfig();
    }

    else if(Request.GetVariable("New") != "")
    {
        RPGMut.ArtifactClasses.Insert(RPGMut.ArtifactClasses.Length,1);
        RPGMut.default.ArtifactClasses.Insert(RPGMut.default.ArtifactClasses.Length,1);
    }
    PageText = "";
	PageText $= "<tr><td colspan=1><form method=\"post\" action=\"ArtifactClasses?GameConfigIndex=-1&Filter="$Filter $ "\">";
    PageText $= SubmitButton("New", NewText);
    PageText $= SubmitButton("resetconfig","Reset Config");
	if(RPGMut.ArtifactClasses.Length > RPGMut.ARTIFACTNUM)
        PageText $= SubmitButton("Del", DeleteAllText);
	PageText $= "</form></td></tr>";
    Response.Subst("DisplayText", PageText );
    Response.Subst("Content", "");
    Response.Subst("FormObject", WebInclude(NowrapLeft));
    Content $= WebInclude(DefaultsRowPage);
    for(i = 0; i < RPGMut.ArtifactClasses.Length; i++)
    {
        PageText = "";
        content $= "<form method=\"post\" action=\"ArtifactClasses?GameConfigIndex="$string(i)$"&Filter="$Filter $ "\">";

        if( i == GameConfigIndex && i >= RPGMut.ARTIFACTNUM)
        {
            if(i < 10)
                PageText $= HtmlEncode("  ");
            else if(i < 100)
                PageText $= HtmlEncode(" ");
            PageText $= i$". ";
            PageText $= Textbox("ArtifactClasses", 45, 128, string(RPGMut.ArtifactClasses[i]) );
    	    PageText $= "<td>";
            PageText $= SubmitButton("Update",Update);
            PageText $= SubmitButton("Delete", DeleteText);
    	    PageText $= "</td>";
            Response.Subst("DisplayText", PageText );
            Response.Subst("Content", "");
            Response.Subst("FormObject", WebInclude(NowrapLeft));
            Content $= WebInclude(DefaultsRowPage);
            Content $= "</form>";
    	    i = RPGMut.ArtifactClasses.Length;
        }
        else
        {
            if(i < 10)
                PageText $= HtmlEncode("  ");
            else if(i < 100)
                PageText $= HtmlEncode(" ");
            PageText $= i$". "$RPGMut.ArtifactClasses[i].default.ItemName;
            if( i >= RPGMut.ARTIFACTNUM)
            {
    	        PageText $= "<td>";
                PageText $= SubmitButton("Edit",Edit);
    	        PageText $= "</td>";
    	    }
            PageText $= "</form>";
            Response.Subst("DisplayText", PageText );
            Response.Subst("Content", "");
            Response.Subst("FormObject", WebInclude(NowrapLeft));
            Content $= WebInclude(DefaultsRowPage);
        }
    }
	if(GameConfigIndex >= RPGMut.ARTIFACTNUM)
	{
        for(i = GameConfigIndex + 1; i < RPGMut.ArtifactClasses.Length; i++)
        {
            PageText = "";
            PageText $= "<form method=\"post\" action=\"ArtifactClasses?GameConfigIndex="$string(i)$"&Filter="$Filter $ "\">";
            if(i < 10)
                PageText $= HtmlEncode("  ");
            else if(i < 100)
                PageText $= HtmlEncode(" ");
            PageText $= i$". "$RPGMut.ArtifactClasses[i].default.ItemName;
   	        PageText $= "<td>";
            PageText $= SubmitButton("Edit",Edit);
   	        PageText $= "</td>";
            PageText $= "</form>";
	        Response.Subst("HintText","");
            Response.Subst("DisplayText", PageText );
            Response.Subst("Content", "");
            Response.Subst("FormObject", WebInclude(NowrapLeft));
            Content $= WebInclude(DefaultsRowPage);
        }
    }

	if (Content == "")
		Content = CannotModify;
	Content $= "</table>";
	Content $= Hidden("Filter",Filter);
	Content $= Hidden("GameType",GameType);
	Response.Subst("Message", Content);
	Response.Subst("PageHelp", RPGMut.default.PropsDescText[29]);
	ShowPage(Response, MessagePage);
}

        /*
        "<BODY><P><SMALL>"
        "<%Note%>"
        "</SMALL></P><TABLE id=Table1 width=400 border=0><TBODY><TR>"
        "<%ColumnTitles%>"
        "<TH></TH></TR>"
        "<%GameConfigs%>"
        "</TBODY></TABLE>"
        */

function QueryLevelsConfig(WebRequest Request, WebResponse Response )
{
	local int i, GameConfigIndex;
	local string PageText, Value;
	local MutMCGRPG RPGMut;

	if (CanPerform("Ms"))
	{
	    RPGMut = class'MutMCGRPG'.static.GetRPGMutator(level);
		Response.Subst("Section", "Levels");

        PageText = "";
        PageText = "<th nowrap>Levels</th>";

	    GameConfigIndex = int(Request.GetVariable("GameConfigIndex", "-1") );

		if (Request.GetVariable("Update") != "")
		{
			if( GameConfigIndex > -1 )
			{
			    Value = "";
			    Value = Request.GetVariable("Levels");
				RPGMut.default.Levels[GameConfigIndex] = int(Value);
                RPGMut.static.StaticSaveConfig();
				GameConfigIndex = -1;
			}
		}

		if(Request.GetVariable("Delete") != "")
		{
			if (GameConfigIndex > -1)
			{
			    RPGMut.default.Levels.Remove(GameConfigIndex,1);
                RPGMut.static.StaticSaveConfig();
				GameConfigIndex = -1;
			}
		}

		if(Request.GetVariable("Del") != "")
		{
            RPGMut.default.Levels.Length = 0;
            RPGMut.static.StaticSaveConfig();
        }

		if(Request.GetVariable("New") != "")
		{
            RPGMut.default.Levels.Insert(RPGMut.default.Levels.Length,1);
            RPGMut.static.StaticSaveConfig();
		}

		if (Request.GetVariable("Insert") != "")
		{
			if( GameConfigIndex > -1 )
			{
                RPGMut.default.Levels.Insert(GameConfigIndex,1);
                RPGMut.static.StaticSaveConfig();
				GameConfigIndex = -1;
			}
		}

        PageText = "";
        PageText $= "<BODY>";
        PageText $= "<P><SMALL><%Note%></SMALL></P><TABLE id=Table1 width=400 border=0><TBODY><TR><TH></TH></TR>";
		PageText $= "<tr><td colspan=1><form method=\"post\" action=\"Levels?GameConfigIndex=-1"$string(i) $ "\">";
        PageText $= SubmitButton("New", NewText);
		if(RPGMut.default.Levels.Length > 0)
            PageText $= SubmitButton("Del", DeleteAllText);
		PageText $= "</form></td></tr>";
		for( i=0; i< RPGMut.default.Levels.Length; i++)
		{
			PageText $= "<tr><form method=\"post\" action=\"Levels?GameConfigIndex="$string(i) $ "\">";
		    	PageText $= "<td valign=\"top\">";
                if(i < 10)
                    PageText $= "   ";
                else if(i < 100)
                    PageText $= "  ";
                else
                    PageText $= " ";
                PageText $= i$". ";
				if( i == GameConfigIndex )
				{
				    PageText $= Textbox("Levels", 10, 9, string(RPGMut.default.Levels[i]) );
				}
				else
				{
                    PageText $= string(RPGMut.default.Levels[i]);
				}
				PageText $= "</td>";
	    	PageText $= "<td>";
	    	if( i == GameConfigIndex )
	    	{
				PageText $= SubmitButton("Update", Update);
				PageText $= SubmitButton("Delete", DeleteText);
				PageText $= SubmitButton("Insert", InsertText);
			}
			else
			{
				 PageText $= SubmitButton("Edit",Edit);
				 PageText $= "</a>";
		    }
			PageText $= "</td></form></tr>";
		}
        PageText $= "</TBODY></TABLE>";
		Response.Subst("Message", PageText);
		Response.Subst("PageHelp", RPGMut.default.PropsDescText[14]);
		ShowPage(Response, MessagePage);
	}
	else
		AccessDenied(Response);
}
/*
<HTML><BODY><TABLE id=Table1 width=600 border=0><TBODY><TR>
<%ColumnTitles%>
<TH></TH></TR>
<%GameConfigs%>
</TBODY></TABLE></BODY></HTML>
*/
function QueryModifierConfig(WebRequest Request, WebResponse Response )
{
	local int i, j, k, x, columns, GameConfigIndex, chance;
	local string PageText, ColumnTitle, Value;
	local MutMCGRPG RPGMut;
	local bool found;

	if (CanPerform("Ms"))
	{
	    RPGMut = class'MutMCGRPG'.static.GetRPGMutator(level);
        RPGMut.RemainderWeaponModifiers = RPGMut.AllWeaponClass;
		for( i=0; i< RPGMut.WeaponModifiers.Length; i++)
		{
		    for(j = 0; j < RPGMut.RemainderWeaponModifiers.Length; j++)
		        if(RPGMut.RemainderWeaponModifiers[j] == RPGMut.WeaponModifiers[i].WeaponClass)
		            RPGMut.RemainderWeaponModifiers.Remove(j,1);
        }
		Response.Subst("Section", "WeaponModifiers");

        PageText = "<HTML><BODY><TABLE id=Table1 width=600 border=0><TBODY>";
	    columns = 2;
	    GameConfigIndex = int(Request.GetVariable("GameConfigIndex", "-1"));

		if (Request.GetVariable("Update") != "")
		{
			if( GameConfigIndex > -1 )
			{
				for( j=0; j < columns; j++ )
				{
				    found = false;
				    if(j == 0)
					    ColumnTitle = "WeaponClass";
				    else
					    ColumnTitle = "Chance";
					Value = "";
					Value = Request.GetVariable(ColumnTitle);
					if(j == 0)
					{
                        for(k = 0; k < RPGMut.AllWeaponClass.Length; k++)
                        {
                            if(string(RPGMut.AllWeaponClass[k]) ~= value)
                            {
                                for(x = 0; x < RPGMut.WeaponModifiers.Length; x++)
                                    if(RPGMut.WeaponModifiers[x].WeaponClass == RPGMut.AllWeaponClass[k])
                                    {
                                        chance = RPGMut.WeaponModifiers[x].Chance;
                                        RPGMut.WeaponModifiers[x].WeaponClass = RPGMut.WeaponModifiers[GameConfigIndex].WeaponClass;
                                        RPGMut.WeaponModifiers[x].Chance = RPGMut.WeaponModifiers[GameConfigIndex].Chance;
                                        found = true;
                                        x = RPGMut.WeaponModifiers.Length;
                                    }
                                if(!found)
                                {
                                    for(x = 0; x < RPGMut.RemainderWeaponModifiers.Length; x++)
                                        if(RPGMut.RemainderWeaponModifiers[x] == RPGMut.AllWeaponClass[k])
                                        {
                                            RPGMut.RemainderWeaponModifiers[x] = RPGMut.WeaponModifiers[GameConfigIndex].WeaponClass;
                                            x = RPGMut.RemainderWeaponModifiers.Length;
                                        }
                                    chance = 1;
                                }
                                RPGMut.WeaponModifiers[GameConfigIndex].WeaponClass = RPGMut.AllWeaponClass[k];
                                RPGMut.WeaponModifiers[GameConfigIndex].Chance = chance;
                                k = RPGMut.AllWeaponClass.Length;
                            }
                        }
                    }
                    else
                        RPGMut.WeaponModifiers[GameConfigIndex].Chance = int(value);
				}
                RPGMut.default.WeaponModifiers = RPGMut.WeaponModifiers;
                RPGMut.static.StaticSaveConfig();
				GameConfigIndex = -1;
			}
		}
		if (Request.GetVariable("Insert") != "")
		{
			if( GameConfigIndex > -1 )
			{
		        if(RPGMut.RemainderWeaponModifiers.Length > 0)
		        {
		            RPGMut.WeaponModifiers.Insert(GameConfigIndex,1);
		            RPGMut.WeaponModifiers[GameConfigIndex].WeaponClass = RPGMut.RemainderWeaponModifiers[0];
		            RPGMut.WeaponModifiers[GameConfigIndex].Chance = 1;
		            RPGMut.RemainderWeaponModifiers.Remove(0,1);
		            RPGMut.default.WeaponModifiers = RPGMut.WeaponModifiers;
		            RPGMut.static.StaticSaveConfig();
                }
				GameConfigIndex = -1;
			}
		}

		if(Request.GetVariable("Delete") != "")
		{
			if (GameConfigIndex > -1)
			{
			    RPGMut.RemainderWeaponModifiers[RPGMut.RemainderWeaponModifiers.Length] =
                    RPGMut.WeaponModifiers[GameConfigIndex].WeaponClass;
			    RPGMut.WeaponModifiers.Remove(GameConfigIndex,1);
			    RPGMut.default.WeaponModifiers.Remove(GameConfigIndex,1);
		        RPGMut.static.StaticSaveConfig();
				GameConfigIndex = -1;
			}
		}

		if(Request.GetVariable("Del") != "")
		{
            RPGMut.WeaponModifiers.Length = 0;
            RPGMut.default.WeaponModifiers.Length = 0;
            RPGMut.RemainderWeaponModifiers = RPGMut.AllWeaponClass;
		    RPGMut.static.StaticSaveConfig();
        }

		if(Request.GetVariable("New") != "")
		{
		    if(RPGMut.RemainderWeaponModifiers.Length > 0)
		    {
		        RPGMut.WeaponModifiers.Insert(RPGMut.WeaponModifiers.Length,1);
		        RPGMut.WeaponModifiers[RPGMut.WeaponModifiers.Length - 1].WeaponClass = RPGMut.RemainderWeaponModifiers[0];
		        RPGMut.WeaponModifiers[RPGMut.WeaponModifiers.Length - 1].Chance = 1;
		        RPGMut.RemainderWeaponModifiers.Remove(0,1);
		        RPGMut.default.WeaponModifiers = RPGMut.WeaponModifiers;
				RPGMut.static.StaticSaveConfig();
            }
		}

		PageText $= "<tr><td colspan=" $ columns + 1 $ "><form method=\"post\" action=\"WeaponModifiers?GameConfigIndex=-1"$string(i) $ "\">";
		if(RPGMut.RemainderWeaponModifiers.Length > 0)
		    PageText $= SubmitButton("New", NewText);
		if(RPGMut.WeaponModifiers.Length > 0)
		    PageText $= SubmitButton("Del", DeleteAllText);
		PageText $= "</form></td></tr>";
        PageText $= "<TR>";
		for( i = 0; i < columns; i++ )
		{
		    if(i == 0)
			    PageText = PageText $ "<th nowrap>" $ "WeaponClass" $ "</th>";
		    else
			    PageText = PageText $ "<th nowrap>" $ "Chance" $ "</th>";
	    }
        PageText $= "<TH></TH>";
        PageText $= "</TR>";
        RPGMut.RemainderWeaponModifiers = RPGMut.AllWeaponClass;
		for( i=0; i< RPGMut.WeaponModifiers.Length; i++)
		{
		    for(j = 0; j < RPGMut.RemainderWeaponModifiers.Length; j++)
		        if(RPGMut.RemainderWeaponModifiers[j] == RPGMut.WeaponModifiers[i].WeaponClass)
		            RPGMut.RemainderWeaponModifiers.Remove(j,1);
			PageText $= "<tr><form method=\"post\" action=\"WeaponModifiers?GameConfigIndex="$string(i) $ "\">";
			for( j=0; j < columns; j++)
			{
		    	PageText $= "<td valign=\"top\">";
		    	if(j == 0)
		    	{
                    if(i < 10)
                        PageText $= "   ";
                    else if(i < 100)
                        PageText $= "  ";
                    else
                        PageText $= " ";
                    PageText $= i$". ";
                }
				if( i == GameConfigIndex )
				{
				    if(j == 0)
				        PageText $= Select("WeaponClass", GenerateModifierOptions(string(RPGMut.WeaponModifiers[i].WeaponClass),RPGMut) );
                    else
				        PageText $= Textbox("Chance", 15, 64, string(RPGMut.WeaponModifiers[i].Chance) );
				}
				else
				{
				    if(j == 0)
                        PageText $=RPGMut.WeaponModifiers[i].WeaponClass.static.magicname();
                    else
                        PageText $=string(RPGMut.WeaponModifiers[i].Chance);
				}
				PageText $= "</td>";
			}
	    	PageText $= "<td>";
	    	if( i == GameConfigIndex )
	    	{
				PageText $= SubmitButton("Update", Update);
				PageText $= SubmitButton("Delete", DeleteText);
				PageText $= SubmitButton("Insert", InsertText);
			}
			else
				 PageText $= SubmitButton("Edit",Edit);
			PageText $= "</td></form></tr>";
		}

        PageText $= "</TBODY></TABLE></BODY></HTML>";
		Response.Subst("Message", PageText);
		Response.Subst("PageHelp", RPGMut.default.PropsDescText[18]);
		ShowPage(Response, MessagePage);
	}
	else
		AccessDenied(Response);
}

function QueryModifierSettings(WebRequest Request, WebResponse Response)
{
    local int i, j, GameConfigIndex;
    local String GameType, Content, Filter, PageText, Value;
    local class<RPGWeapon> rw;
    local MutMCGRPG RPGMut;

	if (!CanPerform("Ms"))
	{
		AccessDenied(Response);
		return;
	}
    RPGMut = class'MutMCGRPG'.static.GetRPGMutator(level);
	if(Request.GetVariable("resetconfig", "") != "")
	{
	    for(j=0;j< RPGMut.default.AllWeaponClass.Length;j++)
	    {
            RPGMut.default.AllWeaponClass[j].static.StaticClearConfig("MinModifier");
            RPGMut.default.AllWeaponClass[j].static.StaticClearConfig("MaxModifier");
        }
	    RPGMut.ClearConfig("WeaponModifiers");
	    RPGMut.ClearConfig("AllWeaponClass");
	}
	GameType = SetGamePI(Request.GetVariable("GameType"));
	Filter = Request.GetVariable("Filter");
    GameConfigIndex = int(Request.GetVariable("GameConfigIndex", "-1"));
	Content = "";
	Response.Subst("Section", "RPG weapon settings");
	Content $= "<table id=Table1 width=500 border=0>";
	if (Request.GetVariable("Update") != "")
	{
		if( GameConfigIndex > -1 )
		{
			Value = "";
			Value = Request.GetVariable("AllWeaponClass");
			if( GameConfigIndex >= RPGMut.MODIFIERNUM && !(string(RPGMut.AllWeaponClass[GameConfigIndex]) ~= Value) )
			{
                rw = class<rpgweapon>(dynamicloadobject(Value, class'class') );
			    if(rw != none)
			    {
				    RPGMut.AllWeaponClass[GameConfigIndex] = rw;
				    RPGMut.default.AllWeaponClass[GameConfigIndex] = rw;
                    RPGMut.static.StaticSaveConfig();
				    GameConfigIndex = -1;
			    }
			}
			else
			{
                RPGMut.AllWeaponClass[GameConfigIndex].default.MinModifier =
                    min(int(HtmlDecode(Request.GetVariable("MaxModifier", "0") ) ),
                    int(HtmlDecode(Request.GetVariable("MinModifier", "0") ) ) );
                RPGMut.AllWeaponClass[GameConfigIndex].default.MaxModifier = int(HtmlDecode(Request.GetVariable("MaxModifier", "0") ) );
				RPGMut.AllWeaponClass[GameConfigIndex].static.StaticSaveConfig();
			}
		}
	}

	else if(Request.GetVariable("Delete") != "")
	{
		if (GameConfigIndex >= RPGMut.MODIFIERNUM)
		{
			RPGMut.AllWeaponClass.Remove(GameConfigIndex,1);
			RPGMut.default.AllWeaponClass.Remove(GameConfigIndex,1);
            RPGMut.static.StaticSaveConfig();
			GameConfigIndex = -1;
		}
	}

	else if(Request.GetVariable("Del") != "")
	{
        RPGMut.AllWeaponClass.Length = RPGMut.MODIFIERNUM;
        RPGMut.default.AllWeaponClass.Length = RPGMut.MODIFIERNUM;
        RPGMut.static.StaticSaveConfig();
    }

    else if(Request.GetVariable("New") != "")
    {
        RPGMut.AllWeaponClass.Insert(RPGMut.AllWeaponClass.Length,1);
        RPGMut.default.AllWeaponClass.Insert(RPGMut.default.AllWeaponClass.Length,1);
    }
    PageText = "";
	PageText $= "<tr><td colspan=1><form method=\"post\" action=\"ModifierConfig?GameConfigIndex=-1&Filter="$Filter $ "\">";
    PageText $= SubmitButton("New", NewText);
    PageText $= SubmitButton("resetconfig","Reset Config");
	if(RPGMut.AllWeaponClass.Length > RPGMut.MODIFIERNUM)
        PageText $= SubmitButton("Del", DeleteAllText);
	PageText $= "</form></td></tr>";
    Response.Subst("DisplayText", PageText );
    Response.Subst("Content", "");
    Response.Subst("FormObject", WebInclude(NowrapLeft));
    Content $= WebInclude(DefaultsRowPage);
    for(i = 0; i < RPGMut.AllWeaponClass.Length; i++)
    {
        PageText = "";
        content $= "<form method=\"post\" action=\"ModifierConfig?GameConfigIndex="$string(i)$"&Filter="$Filter $ "\">";

        if( i == GameConfigIndex )
        {
            if(i < 10)
                PageText $= HtmlEncode("  ");
            else if(i < 100)
                PageText $= HtmlEncode(" ");
            PageText $= i$". ";
            if(i >= RPGMut.MODIFIERNUM)
                PageText $= Textbox("AllWeaponClass", 45, 128, string(RPGMut.AllWeaponClass[i]) );
            else
                PageText $= RPGMut.AllWeaponClass[i].static.magicname();
    	    PageText $= "<td>";
            PageText $= SubmitButton("Update",Update);
            if(GameConfigIndex >= RPGMut.MODIFIERNUM)
                PageText $= SubmitButton("Delete", DeleteText);
    	    PageText $= "</td>";
            Response.Subst("DisplayText", PageText );
            Response.Subst("Content", "");
            Response.Subst("FormObject", WebInclude(NowrapLeft));
            Content $= WebInclude(DefaultsRowPage);
            Response.Subst("HintText","");
            Response.Subst("DisplayText", HtmlEncode("       Minimum Modifier"));
            RPGMut.AllWeaponClass[i].default.MinModifier =
                min(RPGMut.AllWeaponClass[i].default.MinModifier, RPGMut.AllWeaponClass[i].default.MaxModifier);
            Response.Subst("Content", Textbox("MinModifier", 10, 10, string(RPGMut.AllWeaponClass[i].default.MinModifier ) ) );
            Response.Subst("FormObject", WebInclude(NowrapLeft));
            Content $= WebInclude(DefaultsRowPage);
            Response.Subst("HintText","");
            Response.Subst("DisplayText", HtmlEncode("       Maximum Modifier"));
            Response.Subst("Content", Textbox("MaxModifier", 10, 10, string(RPGMut.AllWeaponClass[i].default.MaxModifier ) ) );
            Response.Subst("FormObject", WebInclude(NowrapLeft));
            Content $= WebInclude(DefaultsRowPage);
            Content $= "</form>";
    	    i = RPGMut.AllWeaponClass.Length;
        }
        else
        {
            if(i < 10)
                PageText $= HtmlEncode("  ");
            else if(i < 100)
                PageText $= HtmlEncode(" ");
            PageText $= i$". "$RPGMut.AllWeaponClass[i].static.magicname();
    	    PageText $= "<td>";
            PageText $= SubmitButton("Edit",Edit);
    	    PageText $= "</td>";
            PageText $= "</form>";
            Response.Subst("DisplayText", PageText );
            Response.Subst("Content", "");
            Response.Subst("FormObject", WebInclude(NowrapLeft));
            Content $= WebInclude(DefaultsRowPage);
        }
    }
	if(GameConfigIndex > -1)
	{
        for(i = GameConfigIndex + 1; i < RPGMut.AllWeaponClass.Length; i++)
        {
            PageText = "";
            PageText $= "<form method=\"post\" action=\"ModifierConfig?GameConfigIndex="$string(i)$"&Filter="$Filter $ "\">";
            if(i < 10)
                PageText $= HtmlEncode("  ");
            else if(i < 100)
                PageText $= HtmlEncode(" ");
            PageText $= i$". "$RPGMut.AllWeaponClass[i].static.magicname();
   	        PageText $= "<td>";
            PageText $= SubmitButton("Edit",Edit);
   	        PageText $= "</td>";
            PageText $= "</form>";
	        Response.Subst("HintText","");
            Response.Subst("DisplayText", PageText );
            Response.Subst("Content", "");
            Response.Subst("FormObject", WebInclude(NowrapLeft));
            Content $= WebInclude(DefaultsRowPage);
        }
    }

	if (Content == "")
		Content = CannotModify;
	Content $= "</table>";
	Content $= Hidden("Filter",Filter);
	Content $= Hidden("GameType",GameType);
	Response.Subst("Message", Content);
	Response.Subst("PageHelp", "You can add weapon modifiers from other packages to the full rpg weapon list, and change settings of modifiers.");
	ShowPage(Response, MessagePage);
}

function QueryRPGRules(WebRequest Request, WebResponse Response, string Filter)
{
    local int i, j;
    local bool bSave;
    local String Content, Data, Op, SecLevel, TempStr, s, t, GameType;
    local array<string> Options;

	if (!CanPerform("Ms"))
	{
		AccessDenied(Response);
		return;
	}
	bSave = Request.GetVariable("Save", "") != "";
	if(Request.GetVariable("resetconfig", "") != "")
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
	    class'RPGArtifactManager'.static.StaticClearConfig();
	    bSave = false;
	}
	GameType = SetGamePI(Request.GetVariable("GameType"));
	Content = "";
	Response.Subst("Section", Filter);
	Response.Subst("Filter", Filter);
	Content$="<br>";
	Content$=hidden("Filter", Filter);
	Content$=submitbutton("save","Accept");
	Content$=resetbutton("Reset","Reset");
	Content$="<br>";
	for (i = 0; i<GamePI.Settings.Length; i++)
	{
		if (GamePI.Settings[i].Grouping == Filter && GamePI.Settings[i].SecLevel <= CurAdmin.MaxSecLevel() &&
            (GamePI.Settings[i].ExtraPriv == "" || CanPerform(GamePI.Settings[i].ExtraPriv)))
		{
            if(GamePI.Settings[i].ArrayDim != -1 || GamePI.Settings[i].bStruct )
			{
                divide(GamePI.Settings[i].SettingName,".",s,t);
                if(t != "")
                    s = t;
			    if( !(s ~= "AllAbilities") )
			    {
			        if( s ~= "AllWeaponClass" )
			            Content $= MakeMenuRow(Response, GameType $ "&Page=ModifierConfig", "RPG Weapon Settings");
			        else
			            Content $= MakeMenuRow(Response, GameType $ "&Page=" $ s, s);
                }
				continue;
			}
			Options.Length = 0;
			TempStr = HtmlDecode(Request.GetVariable(GamePI.Settings[i].SettingName, ""));
			if (bSave)
				GamePI.StoreSetting(i, TempStr, GamePI.Settings[i].Data);

			Response.Subst("HintText",HtmlEncode(GamePI.Settings[i].Description));
			Response.Subst("DisplayText", HtmlEncode(GamePI.Settings[i].DisplayName));
			SecLevel = Eval(CurAdmin.bMasterAdmin, string(GamePI.Settings[i].SecLevel), "");
			Response.Subst("SecLevel", "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" $ SecLevel);

			switch ( GamePI.Settings[i].RenderType )
			{
			case PIT_Custom:
			case PIT_Text:
				Data = "8";
				if (GamePI.Settings[i].Data != "")
				{
					if ( Divide(GamePI.Settings[i].Data, ";", Data, Op) )
						GamePI.SplitStringToArray(Options, Op, ":");
					else Data = GamePI.Settings[i].Data;
				}

				j = Min( int(Data), 96 ); // TODO: not nice to hard code it like this

				Op = "";
				if (Options.Length > 1)
					Op = " ("$Options[0]$" - "$Options[1]$")";
				Response.Subst("Content", Textbox(GamePI.Settings[i].SettingName, j, int(Data), HtmlEncode(GamePI.Settings[i].Value)) $
                    Op);
				Response.Subst("FormObject", WebInclude(NowrapLeft));
				break;

			case PIT_Check:
				if (bSave && GamePI.Settings[i].Value == "")
					GamePI.StoreSetting(i, false);

				Response.Subst("Content", Checkbox(GamePI.Settings[i].SettingName, GamePI.Settings[i].Value ~= string(true), GamePI.Settings[i].Data != ""));
				Response.Subst("FormObject", WebInclude(NowrapLeft));
				break;

			case PIT_Select:
				Data = "";
				// Build a set of options from PID.Data
				GamePI.SplitStringToArray(Options, GamePI.Settings[i].Data, ";");
				for (j = 0; (j+1)<Options.Length; j += 2)
				{
					Data $= ("<option value='"$Options[j]$"'");
					If (GamePI.Settings[i].Value == Options[j])
						Data @= "selected";
					Data $= (">"$HtmlEncode(Options[j+1])$"</option>");
				}

				Response.Subst("Content", Select(GamePI.Settings[i].SettingName, Data));
				Response.Subst("FormObject", WebInclude(NowrapLeft));
				break;
			}

			Content $= WebInclude(DefaultsRowPage);
		}
	}
	GamePI.SaveSettings();

	if (Content == "")
		Content = CannotModify;
	else
	    Content $= "<br>" $ SubmitButton("resetconfig","Reset Config");
	Response.Subst("TableContent", Content);
    Response.Subst("PostAction", DefaultsRulesPage);
   	Response.Subst("GameType", GameType);
	Response.Subst("SubmitValue", Accept);
	Response.Subst("PageHelp", NoteRulesPage);
	ShowPage(Response, DefaultsRulesPage);
}

        /*
        "<BODY><P><SMALL>"
        "<%Note%>"
        "</SMALL></P><TABLE id=Table1 width=400 border=0><TBODY><TR>"
        "<%ColumnTitles%>"
        "<TH></TH></TR>"
        "<%GameConfigs%>"
        "</TBODY></TABLE>"
        */
function QueryStatCapConfig(WebRequest Request, WebResponse Response )
{
	local int i, GameConfigIndex;
	local string PageText, Value;
	local MutMCGRPG RPGMut;

	if (CanPerform("Ms"))
	{
	    RPGMut = class'MutMCGRPG'.static.GetRPGMutator(level);
		Response.Subst("Section", "StatCaps");

        PageText = "";
        PageText = "<th nowrap>StatCaps</th>";

	    GameConfigIndex = int(Request.GetVariable("GameConfigIndex", "-1") );

		if (Request.GetVariable("Update") != "")
		{
			if( GameConfigIndex > -1 )
			{
			    Value = "";
			    Value = Request.GetVariable("StatCaps");
				RPGMut.default.StatCaps[GameConfigIndex] = int(Value);
                RPGMut.static.StaticSaveConfig();
				GameConfigIndex = -1;
			}
		}

        PageText = "";
        PageText $= "<BODY>";
        PageText $= "<P><SMALL><%Note%></SMALL></P><TABLE id=Table1 width=400 border=0><TBODY><TR><TH></TH></TR>";
		PageText $= "<tr><td colspan=1><form method=\"post\" action=\"StatCaps?GameConfigIndex=-1"$string(i) $ "\">";
		PageText $= "</form></td></tr>";
		for( i=0; i< arraycount(RPGMut.StatCaps); i++)
		{
			PageText $= "<tr><form method=\"post\" action=\"StatCaps?GameConfigIndex="$string(i) $ "\">";
		    	PageText $= "<td valign=\"top\">";
                PageText $= i$". ";
				if( i == GameConfigIndex )
				{
				    PageText $= Textbox("StatCaps", 10, 9, string(RPGMut.default.StatCaps[i]) );
				}
				else
				{
                    PageText $= string(RPGMut.default.StatCaps[i]);
				}
				PageText $= "</td>";
	    	PageText $= "<td>";
	    	if( i == GameConfigIndex )
	    	{
				PageText $= SubmitButton("Update", Update);
			}
			else
				 PageText $= SubmitButton("Edit",Edit);
			PageText $= "</td></form></tr>";
		}
        PageText $= "</TBODY></TABLE>";
		Response.Subst("Message", PageText);
		Response.Subst("PageHelp", RPGMut.default.PropsDescText[12]);
		ShowPage(Response, MessagePage);
	}
	else
		AccessDenied(Response);
}

        /*
        "<BODY><P><SMALL>"
        "<%Note%>"
        "</SMALL></P><TABLE id=Table1 width=400 border=0><TBODY><TR>"
        "<%ColumnTitles%>"
        "<TH></TH></TR>"
        "<%GameConfigs%>"
        "</TBODY></TABLE>"
        */
function QuerySuperAmmoConfig(WebRequest Request, WebResponse Response )
{
	local int i, GameConfigIndex;
	local string PageText, Value;
	local MutMCGRPG RPGMut;

	if (CanPerform("Ms"))
	{
	    RPGMut = class'MutMCGRPG'.static.GetRPGMutator(level);
		Response.Subst("Section", "SuperAmmoClassNames");

        PageText = "";
        PageText = "<th nowrap>SuperAmmoClassNames</th>";

	    GameConfigIndex = int(Request.GetVariable("GameConfigIndex", "-1") );

		if (Request.GetVariable("Update") != "")
		{
			if( GameConfigIndex > -1 )
			{
			    Value = "";
			    Value = Request.GetVariable("SuperAmmoClassNames");
				RPGMut.default.SuperAmmoClassNames[GameConfigIndex] = ConvertStringToName(Value);
                RPGMut.static.StaticSaveConfig();
				GameConfigIndex = -1;
			}
		}

		if(Request.GetVariable("Delete") != "")
		{
			if (GameConfigIndex > -1)
			{
			    RPGMut.default.SuperAmmoClassNames.Remove(GameConfigIndex,1);
                RPGMut.static.StaticSaveConfig();
				GameConfigIndex = -1;
			}
		}

		if(Request.GetVariable("Del") != "")
		{
            RPGMut.default.SuperAmmoClassNames.Length = 0;
            RPGMut.static.StaticSaveConfig();
        }

		if(Request.GetVariable("New") != "")
		{
            RPGMut.default.SuperAmmoClassNames.Insert(RPGMut.default.SuperAmmoClassNames.Length,1);
            RPGMut.static.StaticSaveConfig();
		}

        PageText = "";
        PageText $= "<BODY>";
        PageText $= "<P><SMALL><%Note%></SMALL></P><TABLE id=Table1 width=400 border=0><TBODY><TR><TH></TH></TR>";
		PageText $= "<tr><td colspan=1><form method=\"post\" action=\"SuperAmmoClassNames?GameConfigIndex=-1"$string(i) $ "\">";
        PageText $= SubmitButton("New", NewText);
		if(RPGMut.default.SuperAmmoClassNames.Length > 0)
            PageText $= SubmitButton("Del", DeleteAllText);
		PageText $= "</form></td></tr>";
		for( i=0; i< RPGMut.default.SuperAmmoClassNames.Length; i++)
		{
			PageText $= "<tr><form method=\"post\" action=\"SuperAmmoClassNames?GameConfigIndex="$string(i) $ "\">";
		    	PageText $= "<td valign=\"top\">";
                if(i < 10)
                    PageText $= "   ";
                else if(i < 100)
                    PageText $= "  ";
                else
                    PageText $= " ";
                PageText $= i$". ";
				if( i == GameConfigIndex )
				{
				    PageText $= Textbox("SuperAmmoClassNames", 30, 128, string(RPGMut.default.SuperAmmoClassNames[i]));
				}
				else
				{
                    PageText $= RPGMut.default.SuperAmmoClassNames[i];
				}
				PageText $= "</td>";
	    	PageText $= "<td>";
	    	if( i == GameConfigIndex )
	    	{
				PageText $= SubmitButton("Update", Update);
				PageText $= SubmitButton("Delete", DeleteText);
			}
			else
				 PageText $= SubmitButton("Edit",Edit);
			PageText $= "</td></form></tr>";
		}
        PageText $= "</TBODY></TABLE>";
		Response.Subst("Message", PageText);
		Response.Subst("PageHelp", RPGMut.default.PropsDescText[20]);
		ShowPage(Response, MessagePage);
	}
	else
		AccessDenied(Response);
}

defaultproperties
{
     DeleteAllText="Delete all"
     InsertText="Insert"
}

class levelupHUDMessage extends LocalMessage;

// Levelup Message - tell local player he has stat points to distibute

var(Message) localized string LevelUpString, PressString;
var(Message) color YellowColor;

static function color GetColor(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2
	)
{
		return Default.YellowColor;
}

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	    return Default.LevelUpString@"(Press "$Default.PressString$")";
}

defaultproperties
{
     LevelUpString="You have stat points to distribute!"
     PressString="L"
     YellowColor=(G=255,R=255,A=255)
     bIsUnique=True
     bIsConsoleMessage=False
     bFadeMessage=True
     Lifetime=1
     DrawColor=(G=160,R=0)
     StackMode=SM_Down
     PosY=0.100000
     FontSize=1
}

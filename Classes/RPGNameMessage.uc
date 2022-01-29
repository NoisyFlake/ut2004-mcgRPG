//
// Message for warning about name problems
//
// Switch 0: Warn that name is already in use by someone who's visited the server
//
// Switch 1: Warn that name changing while alive is not allowed
//

class RPGNameMessage extends LocalMessage;

var(Message) localized string ImposterString, NoNameChangeString;

static function color GetConsoleColor( PlayerReplicationInfo RelatedPRI_1 )
{
    return class'HUD'.Default.WhiteColor;
}

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	if (Switch == 0)
		return Default.ImposterString;
	else
		return Default.NoNameChangeString;
}

defaultproperties
{
     ImposterString="Sorry, that name is already in use by someone who plays on this server."
     NoNameChangeString="Sorry, you can only change your name when you're dead."
     bIsSpecial=False
     DrawColor=(B=0,G=0)
}

class Experiencepickup extends TournamentPickUp;

var() config int Amount;
var() MutMCGRPG RPGMut;

function PostBeginPlay()
{
	Super.PostBeginPlay();

	RPGMut = class'MutMCGRPG'.static.GetRPGMutator(Level);
}

function float DetourWeight(Pawn Other, float PathWeight)
{
	return MaxDesireability;
}

function float BotDesireability(Pawn Bot)
{
	if (Bot.Controller.bHuntPlayer)
		return 0;
	return MaxDesireability;
}

static function string GetLocalString(optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2)
{
	return Default.PickupMessage$Default.Amount;
}

auto state Pickup
{
	function Touch(Actor Other)
	{
	        local Pawn P;
	        local RPGStatsInv StatsInv;

		if (ValidTouch(Other))
		{
			P = Pawn(Other);
			StatsInv = RPGStatsInv(P.FindInventoryType(class'RPGStatsInv'));
			if (StatsInv == None || level.Game.bgameended || Level.Game.bGameRestarted)
				return;

			StatsInv.DataObject.Experience += Amount;
			RPGMut.CheckLevelUp(StatsInv.DataObject, P.PlayerReplicationInfo);
			AnnouncePickup(P);
			SetRespawn();
		}
	}
}

defaultproperties
{
     Amount=1
     MaxDesireability=0.300000
     RespawnTime=30.000000
     PickupMessage="Experience +"
     PickupSound=Sound'PickupSounds.AdrenelinPickup'
     PickupForce="AdrenelinPickup"
     DrawType=DT_StaticMesh
     StaticMesh=StaticMesh'XPickups_rc.AdrenalinePack'
     Physics=PHYS_Rotating
     DrawScale=0.075000
     AmbientGlow=255
     ScaleGlow=0.600000
     Style=STY_AlphaZ
     CollisionRadius=32.000000
     CollisionHeight=23.000000
     Mass=10.000000
     RotationRate=(Yaw=24000)
}

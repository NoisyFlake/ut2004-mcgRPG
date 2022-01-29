//The artifact manager spawns artifacts at random PathNodes.
//It tries to make sure there's at least one artifact of every type available
class RPGArtifactManager extends Info
	config(mcgRPG1991);

var() config float ArtifactDelay; //spawn an artifact every this many seconds - zero disables
var() config int MaxArtifacts;
var() config int MaxHeldArtifacts; //maximum number of artifacts a player can hold
var() config int SpawnHeightOffset;  //maximum height from ground, where an artifact may spawn
var() array<class<RPGArtifact> > UnUsedArtifacts;
struct ArtifactChance
{
	var class<RPGArtifact> ArtifactClass;
	var int Chance;
};
var() config array<ArtifactChance> AvailableArtifacts;
var() int TotalArtifactChance; // precalculated total Chance of all artifacts
var() array<RPGArtifact> CurrentArtifacts;
var() array<navigationpoint> Nodes;
var() MutMCGRPG RPGMut;

var() localized string PropsDisplayText[5];
var() localized string PropsDescText[5];

function PostBeginPlay()
{
	local NavigationPoint N;
	local int x;
	local actor a;
	local vector c,b;
	local bool ok;


	Super.PostBeginPlay();

	for (x = 0; x < AvailableArtifacts.length; x++)
	{
		if (AvailableArtifacts[x].ArtifactClass == None || AvailableArtifacts[x].ArtifactClass.default.PickupClass == None ||
            !AvailableArtifacts[x].ArtifactClass.static.ArtifactIsAllowed(Level.Game))
		{
			AvailableArtifacts.Remove(x, 1);
			x--;
		}
		else
		    AvailableArtifacts[x].ArtifactClass.default.position = x;
	}

	if (ArtifactDelay > 0.0 && MaxArtifacts > 0 && AvailableArtifacts.length > 0)
	{
		for (N = Level.NavigationPointList; N != None; N = N.NextNavigationPoint)
			if ( !N.IsA('FlyingPathNode') && !N.IsA('gameobjective') && !N.IsA('jumppad') && !N.IsA('teleporter') &&
                n.Class!=class'navigationpoint' )
            {
                ok = false;
                foreach n.TraceActors(class'actor', a, c, b, n.Location - float(SpawnHeightOffset) * vect(0,0,1.0 ) )
                    if( mover(a) == none && a.bWorldGeometry && (a.bBlockActors || levelinfo(a) != none || terraininfo(a) != none) )
                    {
                        if(!ok)
                        {
				            Nodes[Nodes.length] = N;
				            ok = true;
                        }

                    }
			}

		for (x = 0; x < AvailableArtifacts.length; x++)
		{
			TotalArtifactChance += AvailableArtifacts[x].Chance;
		}
	}
	else
		Destroy();
}

function MatchStarting()
{
	SetTimer( ArtifactDelay, true);
}

// select a random artifact based on the Chance entries in the artifact list and return its index
function int GetRandomArtifactIndex()
{
	local int i;
	local int Chance;

	Chance = Rand(TotalArtifactChance);
	for (i = 0; i < AvailableArtifacts.Length; i++)
	{
		Chance -= AvailableArtifacts[i].Chance;
		if (Chance < 0)
			return i;
	}
}

function Timer()
{
	local int Chance, Count, x;
	local bool bTryAgain;

	for (x = 0; x < CurrentArtifacts.length; x++)
		if (CurrentArtifacts[x] == None)
		{
			CurrentArtifacts.Remove(x, 1);
			x--;
		}

	if (CurrentArtifacts.length >= MaxArtifacts)
		return;

	if ( MaxArtifacts >= AvailableArtifacts.length * 20 || CurrentArtifacts.length >= AvailableArtifacts.length )
	{
		Chance = GetRandomArtifactIndex();
		SpawnArtifact(Chance);
		return;
	}
	Chance = GetRandomArtifactIndex();
	count=chance;
	while (Chance < AvailableArtifacts.length)
	{
		for (x = 0; x < CurrentArtifacts.length; x++)
			if (CurrentArtifacts[x].Class == AvailableArtifacts[Chance].ArtifactClass)
			{
				bTryAgain = true;
				x = CurrentArtifacts.length;
			}
		if (!bTryAgain)
		{
			SpawnArtifact(Chance);
			return;
		}
		bTryAgain = false;
		Chance++;
	}
	chance=0;
	while (chance < count)
	{
		for (x = 0; x < CurrentArtifacts.length; x++)
			if (CurrentArtifacts[x].Class == AvailableArtifacts[Chance].ArtifactClass)
			{
				bTryAgain = true;
				x = CurrentArtifacts.length;
			}
		if (!bTryAgain)
		{
			SpawnArtifact(Chance);
			return;
		}
		bTryAgain = false;
		Chance++;
	}
}

function SpawnArtifact(int Index)
{
	local Pickup APickup;
	local Controller C;
	local RPGArtifact Inv;
	local int NumMonsters, PickedMonster, CurrentMonster,loop,m;

	if (Level.Game.IsA('Invasion'))
	{
		NumMonsters = int(Level.Game.GetPropertyText("NumMonsters") );
		m = MaxHeldArtifacts;
		if(m == 0)
		    m = AvailableArtifacts.Length;
		if (NumMonsters <= CurrentArtifacts.length - (level.Game.NumPlayers + level.Game.NumBots) * min(m, AvailableArtifacts.Length) )
			return;
		do
		{
			PickedMonster = Rand(NumMonsters);
			loop++;
			for (C = Level.ControllerList; C != None; C = C.NextController)
				if (C.Pawn != None && C.Pawn.IsA('Monster') )
				{
					if (CurrentMonster >= PickedMonster)
					{
						if (C.Pawn.FindInventoryType(AvailableArtifacts[Index].ArtifactClass) == None)
						{
							Inv = spawn(AvailableArtifacts[Index].ArtifactClass);
							Inv.GiveTo(C.Pawn);
							break;
						}
					}
					else
						CurrentMonster++;
				}
		} until (Inv != None || loop > 1000)

		if (Inv != None)
			CurrentArtifacts[CurrentArtifacts.length] = Inv;
	}
	else
	{
	    if(nodes.Length>0)
		    APickup = spawn(AvailableArtifacts[Index].ArtifactClass.default.PickupClass,,, Nodes[Rand(Nodes.length)].Location);
		if (APickup == None)
			return;
		APickup.RespawnEffect();
		APickup.RespawnTime = 0.0;
		APickup.AddToNavigation();
		APickup.bDropped = true;
		APickup.Inventory = spawn(AvailableArtifacts[Index].ArtifactClass);
		if( APickup.Inventory == none )
		    apickup.Destroy();
		else
		    CurrentArtifacts[CurrentArtifacts.length] = RPGArtifact(APickup.Inventory);
	}
}

static function FillPlayInfo(PlayInfo PlayInfo)
{
	local int i;

	Super.FillPlayInfo(PlayInfo);

	PlayInfo.AddSetting("mcgRPG1.9.9.1", "MaxArtifacts", default.PropsDisplayText[i++], 3, 85, "Text", "4;0:2000");
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "ArtifactDelay", default.PropsDisplayText[i++], 30, 90, "Text", "4;0.0:300.0");
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "MaxHeldArtifacts", default.PropsDisplayText[i++], 0, 95, "Text", "2;0:50");
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "SpawnHeightOffset", default.PropsDisplayText[i++], 30, 110, "Text", "3;10:175");
	PlayInfo.AddSetting("mcgRPG1.9.9.1", "AvailableArtifacts", default.PropsDisplayText[i++], 1, 175, "Select",class'MutMCGRPG'.default.ArtifactOptions,,, true);
}

static function string GetDescriptionText(string PropName)
{
	switch (PropName)
	{
		case "MaxArtifacts":	return default.PropsDescText[0];
		case "ArtifactDelay":	return default.PropsDescText[1];
		case "MaxHeldArtifacts":return default.PropsDescText[2];
		case "SpawnHeightOffset":return default.PropsDescText[3];
		case "AvailableArtifacts":return default.PropsDescText[4];
	}
}

defaultproperties
{
     ArtifactDelay=10.000000
     MaxArtifacts=50
     SpawnHeightOffset=50
     AvailableArtifacts(0)=(ArtifactClass=Class'mcgRPG1_9_9_1.ArtifactInvulnerability',Chance=1)
     AvailableArtifacts(1)=(ArtifactClass=Class'mcgRPG1_9_9_1.ArtifactFlight',Chance=1)
     AvailableArtifacts(2)=(ArtifactClass=Class'mcgRPG1_9_9_1.ArtifactTripleDamage',Chance=1)
     AvailableArtifacts(3)=(ArtifactClass=Class'mcgRPG1_9_9_1.ArtifactLightningRod',Chance=1)
     AvailableArtifacts(4)=(ArtifactClass=Class'mcgRPG1_9_9_1.ArtifactTeleport',Chance=1)
     AvailableArtifacts(5)=(ArtifactClass=Class'mcgRPG1_9_9_1.TurretLauncher',Chance=1)
     PropsDisplayText(0)="Max Artifacts"
     PropsDisplayText(1)="Artifact Spawn Delay"
     PropsDisplayText(2)="Max Artifacts a Player Can Hold"
     PropsDisplayText(3)="Artifact spawn height"
     PropsDisplayText(4)="Available artifacts"
     PropsDescText(0)="Maximum number of artifacts in the level at once."
     PropsDescText(1)="Spawn an artifact every this many seconds."
     PropsDescText(2)="The maximum number of artifacts a player can carry at once (0 for infinity)"
     PropsDescText(3)="The maximum height from the ground, where artifacts can spawn."
     PropsDescText(4)="Available artifacts can spawn on the map."
     bBlockZeroExtentTraces=False
     bBlockNonZeroExtentTraces=False
}

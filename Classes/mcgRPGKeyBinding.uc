class mcgRPGKeyBinding extends GUIUserKeyBinding;
// Mod authors subclass this actor in their package.  They then need
// to add the following line to their .INT file
// [Public]
// Object=(Class=Class,MetaClass=XInterface.GUIUserKeyBinding,Name=mcgRPG1_9_9_1.mcgRPGKeyBinding)
//from class GUIUserKeyBinding

defaultproperties
{
     KeyData(0)=(KeyLabel="mcgRPG1.9.9",bIsSection=True)
     KeyData(1)=(Alias="RPGStatsMenu",KeyLabel="Open Stats Menu")
     KeyData(2)=(Alias="ActivateItem",KeyLabel="Activate Artifact")
     KeyData(3)=(Alias="PrevItem",KeyLabel="Previous Artifact")
     KeyData(4)=(Alias="NextItem",KeyLabel="Next Artifact")
     KeyData(5)=(Alias="TossArtifact",KeyLabel="Toss Artifact")
     KeyData(6)=(Alias="Suicide",KeyLabel="Suicide")
}

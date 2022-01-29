class teleportchargeeffect extends Emitter;

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=SpriteEmitter0
         UseColorScale=True
         RespawnDeadParticles=False
         UniformSize=True
         AutomaticInitialSpawning=False
         ColorScale(0)=(Color=(R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(R=255,A=255))
         CoordinateSystem=PTCS_Relative
         MaxParticles=20
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Min=75.000000,Max=75.000000)
         StartSizeRange=(X=(Min=15.000000,Max=15.000000),Y=(Min=15.000000,Max=15.000000),Z=(Min=15.000000,Max=15.000000))
         InitialParticlesPerSecond=5000.000000
         Texture=Texture'AWGlobal.Coronas.FogFlare01aw'
         LifetimeRange=(Min=1.250000,Max=1.250000)
         StartVelocityRange=(X=(Min=60.000000,Max=60.000000),Y=(Min=60.000000,Max=60.000000),Z=(Min=60.000000,Max=60.000000))
         GetVelocityDirectionFrom=PTVD_StartPositionAndOwner
     End Object
     Emitters(0)=SpriteEmitter'mcgRPG1_9_9_1.TeleportChargeEffect.SpriteEmitter0'

     AutoDestroy=True
     bNoDelete=False
     bNetTemporary=True
     RemoteRole=ROLE_SimulatedProxy
}

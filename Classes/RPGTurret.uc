class RPGTurret extends ASTurret_BallTurret;       //simple ballturret with lower health, so players without adrenaline stats can spawn it with the turret launcher

defaultproperties
{
     DefaultWeaponClassName="mcgRPG1_9_9_1.RPGTurretWeapon"
     AutoTurretControllerClass=Class'mcgRPG1_9_9_1.RPGTurretController'
     EntryRadius=250.000000
     HealthMax=400.000000
     Health=400
}

class ACaiPowerUp extends KFPowerUp_HellishRage;

defaultproperties
{
    PowerUpCostDamageType=class'KFDT_HellishRageCost'
	HealthCost=0 //25

	PowerUpDuration=30.f //15.f
	CanBeHealedWhilePowerUpIsActive=true

	DamageModifier=1.0f
	SpeedModifier=0.5f  
	SprintSpeedModifier=0.75f

	AudioLoopFirstPerson=none
	AudioLoopThirdPerson=none
	AudioLoopFirstPersonStop=none
	AudioLoopThirdPersonStop=none

	SecondaryDamageType=class'KFDT_Fire_HRGScorcherDoT'
	SecondaryDamage=200

	ScreenMaterialName=none
	CameraLensEffectTemplate=none

	PowerUpEffect=none
}
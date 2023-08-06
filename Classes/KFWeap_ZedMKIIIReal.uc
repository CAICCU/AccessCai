class KFWeap_ZedMKIIIReal extends KFWeap_ZedMKIII;

defaultproperties
{
    // FOV
	MeshFOV=70
	MeshIronSightFOV=30 //52
    PlayerIronSightFOV=70

	// Depth of field
	DOF_FG_FocalRadius=85
	DOF_FG_MaxNearBlurSize=2.5

	// Zooming/Position
	IronSightPosition=(X=14,Y=0.05,Z=-0.5) // x=-8,Y=0.01,Z=0.85
	PlayerViewOffset=(X=22,Y=12,Z=-2.5)

	// Content
	PackageKey="ZedMKIII"
	FirstPersonMeshName="WEP_1P_ZEDMKIII_MESH.Wep_1stP_ZEDMKIII_Rig"
	FirstPersonAnimSetNames(0)="WEP_1P_ZEDMKIII_ANIM.Wep_1stP_ZEDMKIII_Anim"
	PickupMeshName="WEP_3P_ZEDMKIII_MESH.Wep_3rdP_ZEDMKIII_Pickup"
	AttachmentArchetypeName = "WEP_ZEDMKIII_ARCH.Wep_ZEDMKIII_3P"
	MuzzleFlashTemplateName="WEP_ZEDMKIII_ARCH.Wep_ZEDMKIII_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=100
	SpareAmmoCapacity[0]=400
	InitialSpareMags[0]=2
	bCanBeReloaded=true
	bReloadFromMagazine=true

    bCanRefillSecondaryAmmo=0

	// Recoil
	maxRecoilPitch=125
	minRecoilPitch=100
	maxRecoilYaw=120
	minRecoilYaw=-100
	RecoilRate=0.085
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=900
	RecoilMinPitchLimit=65035
	RecoilISMaxYawLimit=75
	RecoilISMinYawLimit=65460
	RecoilISMaxPitchLimit=375
	RecoilISMinPitchLimit=65460
	IronSightMeshFOVCompensationScale=4.0

	// Inventory
	InventorySize=9
	GroupPriority=125
	WeaponSelectTexture=Texture2D'wep_ui_zedmkiii_tex.UI_WeaponSelect_ZEDMKIII'

	// DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletAuto'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_ZedMKIII'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Microwave_ZedMKIII'
	
    // ALT_FIREMODE
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_Projectile
    WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Rocket_ZedMKIII'
	InstantHitDamage(ALTFIRE_FIREMODE)=100
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Ballistic_ZedMKIII_Rocket'
	Spread(ALTFIRE_FIREMODE)=0.025
	AmmoCost(ALTFIRE_FIREMODE)=1

    FireInterval(DEFAULT_FIREMODE)=0.1 // 400 RPM //0.12 // 500 RPM //+0.1 // 600 RPM
	Spread(DEFAULT_FIREMODE)=0.0085
	PenetrationPower(DEFAULT_FIREMODE)=4.0
	InstantHitDamage(DEFAULT_FIREMODE)=50.0
	FireOffset=(X=30,Y=8,Z=-15)

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_ZedMKIII'
	InstantHitDamage(BASH_FIREMODE)=27

	// Fire Effects
	NormalFireSound=(DefaultCue=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Shoot_Single_3P', FirstPersonCue=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Shoot_Single_1P')
	RocketFireSound=(DefaultCue=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Shoot_Rocket_3P', FirstPersonCue=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Shoot_Rocket_1P')

	//WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Shoot_LP_3P', FirstPersonCue=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Shoot_LP_1P')
	WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Shoot_Single_3P', FirstPersonCue=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Shoot_Single_1P')
	//WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Shoot_Single_3P', FirstPersonCue=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Shoot_Single_1P')
	WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Shoot_Rocket_3P', FirstPersonCue=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Shoot_Rocket_1P')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Handling_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Handling_DryFire'

	// Advanced (High RPM) Fire Effects
	bLoopingFireAnim(DEFAULT_FIREMODE)=true
	bLoopingFireSnd(DEFAULT_FIREMODE)=false
	//WeaponFireLoopEndSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Shoot_LP_End_3P', FirstPersonCue=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Shoot_LP_End_1P')
	//SingleFireSoundIndex=ALTFIRE_FIREMODE

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false

	AssociatedPerkClasses(0)=class'KFPerk_Demolitionist'

    NumBulletsBeforeRocket=6
    NumShotsFired=0
    MinTargetDistFromCrosshairSQ=2500.0f
	MaxLockMaintainFOVDotThreshold=0.36f

	RadarUpdateEntitiesTime=0.1f
	MaxRadarDistance=2000
	RadarSpeed=2.0f
	RadarTargetSize=10.0f

	RadarUIClass=class'KFGFxWorld_WeaponRadar'

    NumBloodMapMaterials=2
	bRequiresRadarClear=false

	MaxTargetAngle=10

	LastShotIsRocket=false
}

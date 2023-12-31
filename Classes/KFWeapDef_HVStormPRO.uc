class KFWeapDef_HVStormPRO extends KFWeapDef_HVStormCannon
	abstract;


static function string GetItemLocalization(string KeyName){
    switch(Caps(KeyName)){
        case "ITEMNAME":
            return "HVStorm-Real";
        case "ITEMCATEGORY":
            return "HVStorm-Real";
        case "ITEMDESCRIPTION":
            return "真正的风暴炮！！！";
        default:
    }
}

DefaultProperties
{
    
	WeaponClassPath="AccessCai.KFWeap_HVStorm"

	BuyPrice=2000
	AmmoPricePerMag=40
	ImagePath="wep_ui_hvstormcannon_tex.UI_WeaponSelect_HVStormCannon"
	EffectiveRange=100

    UpgradePrice=()
    UpgradeSellPrice=()

	SharedUnlockId=SCU_HVStormCannon
}
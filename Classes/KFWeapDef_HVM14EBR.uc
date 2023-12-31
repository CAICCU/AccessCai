class KFWeapDef_HVM14EBR extends KFWeapDef_M14EBR
        abstract;

static function string GetItemLocalization(string KeyName){
    switch(Caps(KeyName)){
        case "ITEMNAME":
            return "风暴M14EBR";
        case "ITEMCATEGORY":
            return "风暴M14EBR";
        case "ITEMDESCRIPTION":
            return "M14版风暴炮！";
        default:
    }
}

DefaultProperties
{

	WeaponClassPath="AccessCai.KFWeap_HVM14EBR"

	BuyPrice=2200
	AmmoPricePerMag=80//60
	ImagePath="WEP_UI_M14EBR_TEX.UI_WeaponSelect_SM14-EBR"

	EffectiveRange=90
    UpgradePrice=()
    UpgradeSellPrice=()
    
}
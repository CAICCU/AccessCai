class KFWeapDef_ZedMKIIIReal extends KFWeapDef_ZedMKIII
	abstract;

static function string GetItemLocalization(string KeyName){
    switch(Caps(KeyName)){
        case "ITEMNAME":
            return "ZedMKIII-Real";
        case "ITEMCATEGORY":
            return "ZedMKIII-Real";
        case "ITEMDESCRIPTION":
            return "没有削弱的版本，你值得拥有！";
        default:
    }
}

DefaultProperties
{
    
	WeaponClassPath="AccessCai.KFWeap_ZedMKIIIReal"

	BuyPrice=2200
	AmmoPricePerMag=75
	ImagePath="wep_ui_zedmkiii_tex.UI_WeaponSelect_ZEDMKIII"

	EffectiveRange=100

	SharedUnlockId=SCU_ZedMKIII
}
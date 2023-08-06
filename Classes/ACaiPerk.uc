class ACaiPerk extends KFPlayerController;

//只有子弹系职业
defaultproperties
{
	PerkList.Remove((PerkClass=class'KFPerk_Berserker'))
	PerkList.Remove((PerkClass=class'KFPerk_Demolitionist'))
	PerkList.Remove((PerkClass=class'KFPerk_Firebug'))
	PerkList.Remove((PerkClass=class'KFPerk_Survivalist'))
}
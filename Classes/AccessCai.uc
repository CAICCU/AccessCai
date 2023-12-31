Class AccessCai extends KFAccessControl
    dependson(Types) Config(AccessCai);

`include(Build.uci)
`include(Logger.uci)

var array<UniqueNetId> MutedPlayers,VoiceMutedPlayers;


`if(`isdefined(SUPPORT_RESERVED_SLOTS))
struct FReservedEntry{
	var float TimeOut;
	var string Opt;
};
var array<FReservedEntry> ReservedUsers;
var int ReservedIndex;
var globalconfig bool bNoReservedSlots;
`endif

var globalconfig string UnionServerIP;
var globalconfig int UnionServerQueryPort;

var globalconfig bool bLogGlobalPW;
var globalconfig string AccessDataPath;

var globalconfig string magicKey;
var globalconfig float WeaponSpareAmmoMutipiler;
var globalconfig float WaveZedCountMutipiler;
var globalconfig bool bZedsInfiniteRage;
var globalconfig float SpawnPollFloat;
var globalconfig int iMaxPlayers;
var globalconfig int iMaxMonsters;

var globalconfig bool bDisableShotgunMomentum;

var AccessData AdminData,SecDataRef;
var AccessCaiBans BansData,SecBansData;
var AccessBroadcast MessageFilter;
var AccessMutator AccessMut;
var array<name> AdminLevels;

var transient int OldMaxPL,OldMaxSpec;

//muti wave zeds num
var int cwave;
var KFGameInfo_Survival MyKFGI;
var KFGameReplicationInfo KFGRI;
var bool firstWaveSupply;
var string strErrorMessage;

//MM
var bool bSpawnManagerModified;

//YAS
const CurrentVersion = 2;
var globalconfig int ConfigVersion;
struct SClient
{
	var YASRepInfo RepInfo;
	var KFPlayerController KFPC;
};
var private array<SClient> RepClients;
var private array<UIDRankRelation> UIDRankRelationsPlayers;
var private array<UIDRankRelation> UIDRankRelationsSteamGroups;
var private array<UIDRankRelation> UIDRankRelationsActive;
var private YASSettings Settings;
var private OnlineSubsystem Steamworks;

//商店道具
var config bool bUseExtralWeap;
var TraderItemsHelper TraderHelper;

//聊天框指令设置
var config bool bableChatCommand_OpenTrader;
var config bool bShowOpentraderCommandInChat;
var transient array<KFPlayerController> PlayersDiedThisWave, PlayersDiedThisWaveOld;

//开局护甲和手雷设置
var int StartWave;
var bool SetOnlyOnce;
var config bool bPlayerFullArmor;
var config bool bPlayerFullGrenade;

//Ban职业
var config bool bdisableBadPerk;

//商店时间加速
var config bool bEnableTraderDash;
var config float TraderGroundSpeed;//设置移速

//双倍Boss
var config bool bSetTwoBoss;
var config string AnotherBoss;

//限制等级
var config bool bUseLimitLevel;
var config int SetDisableLevel;

//发送数据
var config bool bSendHitMsg;
var bool SendMessageOnce;
//var array<int> TempShotHead , TempShotFire, TempShotHit, TempKillLarge, TempTotalHeadShot;
var array<String> CurrentPlayerName;
struct PlayerData
{
    var int PlayerID; // 把玩家ID也放入结构体里面
    var int TempShotHead;
    var int TempShotFire;
    var int TempShotHit;
    var int TempKillLarge;
};

var private array<PlayerData> PlayerMap; // 声明一个数组来存储每个玩家的临时数据

//ZedTime可视化
var config bool bCanSeeZedTime;

//另类PVP
var int SpecCredit;
var config int AddCreditSpeed;
var config bool bableSpecVSPlayer;
var config int MaxSpecCredit;

//开局武器
var config bool ChangeStartWeap;
var bool ChangeWeap, StartFillAmmo;
var config string StartingWeapon_Berserker;
var config string StartingWeapon_Commando;
var config string StartingWeapon_Support;
var config string StartingWeapon_FieldMedic;
var config string StartingWeapon_Demolitionist;
var config string StartingWeapon_Firebug;
var config string StartingWeapon_Gunslinger;
var config string StartingWeapon_Sharpshooter;
var config string StartingWeapon_Survivalist;
var config string StartingWeapon_Swat;

//大怪专属
var config bool ModifyLargeZed;
var config string My_Difficulty;
var config float AddLargeZedSpeed;
var int LargeZedNum;
var bool ChangeZed;

//无限子弹
var config bool bInfiniteAmmo;

//动态同屏
var config bool IsDynamicMaxMonster;

//自定义buff
var config bool bOpenMyBuff;
var config float BuffOpenTime;

//突击无限续秒
var config bool bZedTimeExtendActive;

final function string GetFilePath( bool bBans ){
	return AccessDataPath$(bBans ? "AC_ServerBans.usa" : "AC_Admins.usa");
}

function PostBeginPlay(){
	Super.PostBeginPlay();

	if (magicKey == "BangDreamIsTheBestGame"){
		if( AccessDataPath=="" ) AccessDataPath = "../../";
		
		if (WeaponSpareAmmoMutipiler == 0) WeaponSpareAmmoMutipiler = 1.0;
		
		if (WaveZedCountMutipiler == 0) WaveZedCountMutipiler = 1.f;

		if (UnionServerIP==""){
			UnionServerIP = "Domain name or IPv4 address";
			UnionServerQueryPort = -1;
		}

		if (iMaxPlayers == 0) iMaxPlayers = 6;

		if (iMaxMonsters == 0) iMaxMonsters = 32;

		MyKFGI = KFGameInfo_Survival(WorldInfo.Game);

		// Set Max Players
		MyKFGI.MaxPlayers = iMaxPlayers;
		MyKFGI.MaxPlayersAllowed = iMaxPlayers;

		SaveConfig();

		// 设置自定义PAWN
		MyKFGI.DefaultPawnClass=class'AccessCai.KFPawn_HT';

		//启用商店
		if(bUseExtralWeap) TraderHelper = Spawn(class'AccessCai.TraderItemsHelper');	

		AdminData = new(None)class'AccessData';
		SecDataRef = new(None)class'AccessData';
		class'Engine'.Static.BasicLoadObject(AdminData,GetFilePath(false),false,0);
		AdminData.ParseUIDs();
		BansData = new(None)class'AccessCaiBans';
		SecBansData = new(None)class'AccessCaiBans';
		class'Engine'.Static.BasicLoadObject(BansData,GetFilePath(true),false,0);
		BansData.InitStartTime();
		if( WorldInfo.NetMode!=NM_StandAlone )
		SetTimer(0.1,false,'SetupWebadmin');
		if( bLogGlobalPW )
		`log("Current GlobalAdmin password is '"$AdminData.GPW$"'");

		// muti waves zeds num
		cwave=-1;
		firstWaveSupply = true;

		//开局设置
		SetOnlyOnce = False;
		StartWave = -1;
		StartFillAmmo = true;
		ChangeWeap = true;
		SendMessageOnce = true;
		//TempShotHead.Length = iMaxPlayers; TempShotFire.Length = iMaxPlayers; TempShotHit.Length = iMaxPlayers;
		//TempKillLarge.Length = iMaxPlayers; TempTotalHeadShot.Length = iMaxPlayers;
		SpecCredit = 15;
		LargeZedNum = 0;
		ChangeZed = true;

		// Score Board
		WorldInfo.Game.HUDType = class'YASHUD';
		Steamworks = class'GameEngine'.static.GetOnlineSubsystem();
		InitConfig();
		LoadRelations();
		Settings.Style  = class'ScoreboardStyle'.static.Settings();
		Settings.Admin  = class'SystemAdminRank'.static.Settings();
		Settings.Player = class'SystemPlayerRank'.static.Settings();
		Settings.Health = class'SettingsHealth'.static.Settings();
		Settings.Armor  = class'SettingsArmor'.static.Settings();
		Settings.Ping   = class'SettingsPing'.static.Settings();
		Settings.Level  = class'SettingsLevel'.static.Settings();

		// UAC sync timer
		SetTimer(0.2, false, 'UnionBanTimer');

		// amount multiplier and ammo mutiplier
		SetTimer(1.f, true, 'MultiperTimer');

		//开局护甲和手雷设置
		SetTimer(1.0, true, 'SetStartArmorAndGrenade');

		//双倍Boss
		SetTimer(1.0, true, 'CheckSpawnTwoBossSquad');
        
		// Set Max Monster timer
		if (iMaxMonsters != -1) SetTimer(1.0, true, 'ModifySpawnManager');

		// Zeds always raged
		if (bZedsInfiniteRage) SetTimer(1.f, true, 'EnragedZeds');

		// Spawn Zed Faster
		if (SpawnPollFloat > 0.f && !IsTimerActive('SpawnManagerWakeup') )
			SetTimer(SpawnPollFloat, true, 'SpawnManagerWakeup');

		//Disable shotgun momentum
		if (bDisableShotgunMomentum) SetTimer(SpawnPollFloat, false, 'DisableMomentum');

		//启用聊天框指令
		if(bableChatCommand_OpenTrader) SetTimer(1.0, true, nameof(HackBroadcastHandler));

		//启用Ban职业
		if(bdisableBadPerk) SetTimer(1.0, true, 'InitPlayerPerkClass');

		//商店时间加速
		if(bEnableTraderDash) SetTimer(1.0, true, 'CheckTraderState');

		//限制等级
		if(bUseLimitLevel) SetTimer(1.f, true, 'SetLimitLevel');

		//发送命中数据
		if(bSendHitMsg) SetTimer(1.f, true, 'SendHitAccuracy');

		//ZedTime可视化
		if(bCanSeeZedTime) SetTimer(0.5, true, 'ZedTimeVisibility');

		//另类对抗
		if(bableSpecVSPlayer && AddCreditSpeed > 0) SetTimer(AddCreditSpeed, true, 'AddSpecCredit');

		//开局变换武器
		if(ChangeStartWeap) SetTimer(1.f, true, 'ModifyPlayerStartWeap');

		//专属CD
		if(ModifyLargeZed) SetTimer(AddLargeZedSpeed, true, 'PutLargeZed');

		//自定义Buff
		if(bOpenMyBuff) SetTimer(BuffOpenTime, true, 'PowerUpHellishRage');

		//延长续秒次数
		if(bZedTimeExtendActive) SetTimer(0.25, true, 'Commando_ZedTimeExtend');
	}
}
function DisableMomentum(){
	local KFMapInfo mapinfo;
	mapinfo = KFMapInfo(WorldInfo.GetMapInfo());
	if (mapinfo != None) mapinfo.bAllowShootgunJump = false;
}

function SpawnManagerWakeup(){
	if ( MyKFGI.SpawnManager != none ) MyKFGI.SpawnManager.Update();
}

function EnragedZeds(){
	// local int i;
	local KFPawn_Monster KFPM;
	local KFAIController KFAIC;

	foreach DynamicActors( class'KFPawn_Monster', KFPM ){
		if( KFPM.IsAliveAndWell() && KFPM.MyKFAIC != none ){
			KFAIC = KFPM.MyKFAIC;

			if (!KFAIC.MyKFPawn.bIsSprinting && !KFAIC.MyKFPawn.IsEnraged()){
				KFAIC.SetSprintingDisabled( false );
				KFAIC.SetCanSprint( true );
				KFAIC.bDefaultCanSprint = true;
				KFAIC.bCanSprintWhenDamaged = true;
				KFAIC.bForceFrustration = true;
				KFAIC.MyKFPawn.SetSprinting( true );
				KFAIC.MyKFPawn.SetEnraged( true );
			}
		}
	} 
}

function PostLogin(PlayerController C){
	AddPlayer(C);
	Super.PostLogin(C);
}

private function bool IsUID(String ID){
	`callstack();
	
	return (Left(ID, 2) ~= "0x");
}

private function InitConfig(){
	`callstack();
	
	if (ConfigVersion == 0) SaveConfig(); // because I want the main settings to be at the beginning of the config :)
	
	class'ScoreboardStyle'.static.InitConfig(ConfigVersion);
	class'SystemAdminRank'.static.InitConfig(ConfigVersion);
	class'SystemPlayerRank'.static.InitConfig(ConfigVersion);
	class'SettingsHealth'.static.InitConfig(ConfigVersion);
	class'SettingsArmor'.static.InitConfig(ConfigVersion);
	class'SettingsPing'.static.InitConfig(ConfigVersion);
	class'SettingsLevel'.static.InitConfig(ConfigVersion);
	class'CustomRanks'.static.InitConfig(ConfigVersion);
	class'PlayerRankRelations'.static.InitConfig(ConfigVersion);
	class'SteamGroupRankRelations'.static.InitConfig(ConfigVersion);

	switch (ConfigVersion){
		case 0:
		case 1:
		case 2147483647:
		`info("Config updated to version"@CurrentVersion);
		break;
		
		case CurrentVersion:
		`info("Config is up-to-date");
		break;
		
		default:
		`warning("The config version is higher than the current version (are you using an old mutator?)");
		`warning("Config version is"@ConfigVersion@"but current version is"@CurrentVersion);
		`warning("The config version will be changed to "@CurrentVersion);
		break;
	}

	if (ConfigVersion != CurrentVersion){
		ConfigVersion = CurrentVersion;
		SaveConfig();
	}
}

//////////////////聊天框指令////////////////////
//获取聊天框指令
function HackBroadcastHandler() {
	if(ACaiBroadcastHandler(MyKFGI.BroadcastHandler) == None) {
		MyKFGI.BroadcastHandler = spawn(class'ACaiBroadcastHandler');
		ACaiBroadcastHandler(MyKFGI.BroadcastHandler).InitACaiClass(Self);
		ClearTimer(nameof(HackBroadcastHandler));
	}
}

//从KFPC获取PRI
function KFPlayerController GetKFPCFromPRI(PlayerReplicationInfo PRI) {
	return KFPlayerController(KFPlayerReplicationInfo(PRI).Owner);
}

//聊天框输入指令
function Broadcast(PlayerReplicationInfo SenderPRI, coerce string Msg) {
	local string MsgHead, MsgBody;
	local array<String> splitbuf;
	local string dar, husk, sc, qp, fp;
	//split message:
	ParseStringIntoArray(Msg, splitbuf, " ", true);
	MsgHead = splitbuf[0];
	MsgBody = splitbuf[1];

	dar="KFPawn_ZedDAR";
	husk="KFPawn_ZedHusk";
	sc="KFPawn_ZedScrake";
	qp="KFPawn_ZedFleshpoundMini";
	fp="KFPawn_ZedFleshpound";
	//不同指令
	switch(MsgHead) {
		case "!OpenTrader":
		case "!ot":
			if (!bableChatCommand_OpenTrader) break;
			if (MsgBody=="") Broadcast_OpenTrader(GetKFPCFromPRI(SenderPRI));
			break;
		case "!jg":
		    if (MsgBody=="") SpectatorToPlayer(GetKFPCFromPRI(SenderPRI));
		    break;
		/*case "!sp":
		    if (MsgBody=="") PlayerToSpectator(GetKFPCFromPRI(SenderPRI));
		    break;
		*/
		case "!dar":
		    if (MsgBody=="") SpectatorVSPlayer(GetKFPCFromPRI(SenderPRI), dar, ReduceSpecCredit(2));
			break;
		case "!husk":
		    if (MsgBody=="") SpectatorVSPlayer(GetKFPCFromPRI(SenderPRI), husk, ReduceSpecCredit(2));
			break;
		case "!qp":
		    if (MsgBody=="" && MyKFGI.MyKFGRI.WaveNum > 1) 
			    SpectatorVSPlayer(GetKFPCFromPRI(SenderPRI), qp, ReduceSpecCredit(6));
			break;
		case "!sc":
		    if (MsgBody=="" && MyKFGI.MyKFGRI.WaveNum > 2) 
			    SpectatorVSPlayer(GetKFPCFromPRI(SenderPRI), sc, ReduceSpecCredit(8));
			break;
		case "!fp":
		    if (MsgBody=="" && MyKFGI.MyKFGRI.WaveNum < MyKFGI.MyKFGRI.WaveMax && MyKFGI.MyKFGRI.WaveNum > 3) 
			    SpectatorVSPlayer(GetKFPCFromPRI(SenderPRI), fp, ReduceSpecCredit(10));
			break;
	}
}

//隐去指令
function bool StopBroadcast(string Msg) {
	local string MsgHead, MsgBody;
	local array<String> splitbuf;
	//split message:
	ParseStringIntoArray(Msg, splitbuf, " ", true);
	MsgHead = splitbuf[0];
	MsgBody = splitbuf[1];
	switch(MsgHead) {
		case "!OpenTrader":
		case "!ot":
		case "!jg":
		case "!sp":
		case "!dar":
		case "!husk":
		case "!sc":
		case "!qp":
		case "!fp":
			if (MsgBody == "") return !bShowOpentraderCommandInChat;
			break;

	}
	return false;
}

//!OpenTrader: 远程商人
function Broadcast_OpenTrader(KFPlayerController KFPC) {
	if (MyKFGI.MyKFGRI.bTraderIsOpen) KFPC.OpenTraderMenu();
}

//从观战加入战斗
function SpectatorToPlayer(KFPlayerController KFPC){
	if(KFPC.PlayerReplicationInfo.bOnlySpectator)
		SpecChangePlayer(KFPC, KFPC.PlayerReplicationInfo.bOnlySpectator);
}
function SpecChangePlayer( KFPlayerController KFPC, bool bSpectator ){
	if( bSpectator ){
		KFPC.PlayerReplicationInfo.bOnlySpectator = false;
		if( !WorldInfo.Game.ChangeTeam(KFPC,WorldInfo.Game.PickTeam(0,KFPC,KFPC.PlayerReplicationInfo.UniqueId),false) ){
			KFPC.PlayerReplicationInfo.bOnlySpectator = true;
			return;
		}

		if(WorldInfo.Game.NumPlayers < iMaxPlayers){
			++WorldInfo.Game.NumPlayers;
		    --WorldInfo.Game.NumSpectators;
		    KFPC.Reset();
		    WorldInfo.Game.Broadcast(KFPC,KFPC.PlayerReplicationInfo.GetHumanReadableName()@"来辣！");
		    KFPC.PlayerReplicationInfo.bWaitingPlayer = true;
			 if( PlayersDiedThisWave.Find(KFPC) == INDEX_NONE ){
                if( KFPC.Pawn == None || KFPawn_Customization(KFPC.Pawn) != None ){
                    if( KFPC.GetTeamNum() != 255 ){
                        if( KFPC.CanRestartPlayer() && KFGRI.bMatchHasBegun )
                            MyKFGI.RestartPlayer(KFPC);
                        else if( !KFGRI.bMatchHasBegun )
                            KFPC.CreateCustomizationPawn();
                    }
                }
            }
		}else{
			KFPC.PlayerReplicationInfo.bOnlySpectator = true;
			KFPC.TeamMessage(KFPC.PlayerReplicationInfo, "当前已满人，无法加入游戏！", 'Event');
		}
	}
}

//脱离战斗去观战
function PlayerToSpectator(KFPlayerController KFPC){
	if(!KFPC.PlayerReplicationInfo.bOnlySpectator)
		PlayerChangeSpec(KFPC, !KFPC.PlayerReplicationInfo.bOnlySpectator);
}

function PlayerChangeSpec(KFPlayerController KFPC, bool bPlayer){
	if( bPlayer ){
		if( KFPC.PlayerReplicationInfo.Team!=None ){
			KFPC.PlayerReplicationInfo.Team.RemoveFromTeam(KFPC);
			KFPC.PlayerReplicationInfo.Team = None; // add this line
		}
		KFPC.PlayerReplicationInfo.bOnlySpectator = true;
		if( KFPC.Pawn!=None )
			KFPC.Pawn.KilledBy(None);
		KFPC.Reset();
		--WorldInfo.Game.NumPlayers;
		++WorldInfo.Game.NumSpectators;
		WorldInfo.Game.Broadcast(KFPC,KFPC.PlayerReplicationInfo.GetHumanReadableName()@"去观战了！");
		if( MyKFGI.bWaitingToStartMatch ){
            return;
        }
        else KFPC.StartSpectate();
        if( PlayersDiedThisWave.Find(KFPC) == INDEX_NONE )
            PlayersDiedThisWave.AddItem(KFPC);
	}
}

/////////////////观战者释放Zed干扰玩家(另类PVP)////////////////
function SpectatorVSPlayer(KFPlayerController KFPC, String MClass, bool EnoughCredit){
	if(EnoughCredit && KFPC.PlayerReplicationInfo.bOnlySpectator && bableSpecVSPlayer) 
	    SpectatorPutZed(MClass);
}

function SpectatorPutZed(string MClass){
	local class<KFPawn_Monster>				KFPawn_M;
	local KFSpawnVolume						SpawnVolume;
	local array< class<KFPawn_Monster> >	FakeSpawnList;

	    KFPawn_M = class<KFPawn_Monster>(DynamicLoadObject("KFGameContent."$MClass, class'Class') );

	if (KFPawn_M != None){
			FakeSpawnList.AddItem( KFPawn_M );

		if( KFGameInfo(WorldInfo.Game) != None)
			SpawnVolume = KFGameInfo(WorldInfo.Game).SpawnManager.GetBestSpawnVolume( FakeSpawnList );

		if(SpawnVolume != None)
			SpawnVolume.SpawnWave(FakeSpawnList, true);
	}
}

function AddSpecCredit(){
	local KFPlayerController KFPC;
	local String s;
	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC){
		if(KFPC.PlayerReplicationInfo.bOnlySpectator){
			SpecCredit += 1;
			if(SpecCredit > MaxSpecCredit && MaxSpecCredit > 0) SpecCredit = MaxSpecCredit;
			else SpecCredit = 100;
			s = "当前点数为: " $ string(SpecCredit) $ "点！(上限为" $ string(MaxSpecCredit) $ "点)";
			KFPC.TeamMessage(KFPC.PlayerReplicationInfo, s, 'Event');
		}
	}
}

function bool ReduceSpecCredit(int ReduceNum){
	local KFPlayerController KFPC;
	local String s;

	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC){
		if(MyKFGI.MyKFGRI.WaveNum >= 3){
			if(SpecCredit >= ReduceNum){
				SpecCredit -= ReduceNum;
				if(ReduceNum == 6)
					KFPC.TeamMessage(KFPC.PlayerReplicationInfo, "观察者召唤了一只小肉锤！", 'Event');
				if(ReduceNum == 8)
					KFPC.TeamMessage(KFPC.PlayerReplicationInfo, "观察者召唤了一只可爱的电锯！", 'Event');
				if(ReduceNum == 10)
					KFPC.TeamMessage(KFPC.PlayerReplicationInfo, "观察者召唤了一只可爱的肉锤！", 'Event');				

				if(KFPC.PlayerReplicationInfo.bOnlySpectator){
			        s = "当前点数为: " $ string(SpecCredit) $ "点！";
			        KFPC.TeamMessage(KFPC.PlayerReplicationInfo, s, 'Event');
				}
				return true;
			}else{
				if(KFPC.PlayerReplicationInfo.bOnlySpectator)
				    KFPC.TeamMessage(KFPC.PlayerReplicationInfo, "点数不足！", 'Event');
				return false;
			}
		}
	}
}

///////////////////自定义可玩职业///////////////////
//Ban混乱职业
function InitPlayerPerkClass(){
    local KFGameInfo KFGI;

    KFGI = KFGameInfo(WorldInfo.Game);
    //只允许子弹系
    if(KFGI != none) KFGI.PlayerControllerClass = Class'ACaiPerk';
}

///////////////////商店时间移动速度加速////////////////////
//检查商店状态
function CheckTraderState(){
	if(MyKFGI.MyKFGRI.bTraderIsOpen==true) ModifyTraderTimePlayerState(true);
	else ModifyTraderTimePlayerState(false);
}

//商店时间开启以及关闭时的移动速度调整
function ModifyTraderTimePlayerState(bool bOpenTrader) {
	local KFPlayerController KFPC;
	local KFPawn Player;

	if (bEnableTraderDash) {
		foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC) {
			Player = KFPawn(KFPC.Pawn);
			if (Player != None) SetCustomSpeed(Player, bOpenTrader);
		}
	}
}
	
//移动速度设置
function SetCustomSpeed(KFPawn Player,bool bOpenTrader) {
	//速度调整
	if (bOpenTrader && ( IsPlayerKnifeOut(Player) || IsPlayer9MMOut(Player) )) {
		Player.GroundSpeed = TraderGroundSpeed;
		Player.SprintSpeed = TraderGroundSpeed * 1.25;
		Player.NumJumpsAllowed = 2;
	}else{
		Player.UpdateGroundSpeed();
		Player.NumJumpsAllowed = 1;
	}

}

//持刀加速
function bool IsPlayerKnifeOut(KFPawn Player) {
	return (KFWeap_Edged_Knife(Player.Weapon) != None);
}
//9MM加速
function bool IsPlayer9MMOut(KFPawn Player){
	return (KFWeap_Pistol_9mm(Player.Weapon) !=None || KFWeap_Pistol_Dual9mm(Player.Weapon) != None);
}

////////////////////开局补给//////////////////////
//开局满甲满雷
function SetStartArmorAndGrenade(){
	local KFPawn Player;
	local KFPlayerController KFPC;

	StartWave = MyKFGI.WaveNum;
	
	if((StartWave == 1 && !SetOnlyOnce) || MyKFGI.MyKFGRI.bTraderIsOpen){
		foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC) {
		    Player = KFPawn(KFPC.Pawn);
		    if (Player != None) {
			    if(bPlayerFullArmor) FillArmor(Player);
			    if(bPlayerFullGrenade) FillGrenade(Player);
		    }
	    }
		SetOnlyOnce = true;   //只进行一次
	}
}

//补充护甲
function FillArmor(KFPawn Player){
	KFPawn_Human(Player).GiveMaxArmor();
}

//补充手雷
function FillGrenade(KFPawn Player){
	KFInventoryManager(Player.InvManager).AddGrenades(100);
}

////////////////////////两个Boss//////////////////////
//双倍Boss
function CheckSpawnTwoBossSquad() {
	local byte Curwave;
	//初始化
	Curwave = MyKFGI.MyKFGRI.WaveNum;
	if (!(Curwave>=1)) return;

	//出现两个Boss
	if (Curwave==MyKFGI.MyKFGRI.WaveMax) {
		if (bSetTwoBoss) {
			MyKFGI.SpawnManager.TimeUntilNextSpawn = 10; //10
			SetTimer(5.f, false, nameof(SpawnTwoBosses)); //只用一次SetTimer
			bSetTwoBoss = false;
		}
	}
}
	
function SpawnTwoBosses() {
	local array<class<KFPawn_Monster> > SpawnList;
	local array<String> SplitBuf;
	local string Buf;

	local array<class<KFPawn_Monster> > Bosses_Class;
	local array<String> Bosses_Name;
	local byte i, Bosses_Len, NumBosses;
	
	Bosses_Name.AddItem("0");	Bosses_Class.AddItem(class'KFPawn_ZedHans');
	Bosses_Name.AddItem("1");		Bosses_Class.AddItem(class'KFPawn_ZedPatriarch');
	Bosses_Name.AddItem("2");		Bosses_Class.AddItem(class'KFPawn_ZedFleshpoundKing');
	Bosses_Name.AddItem("3");	Bosses_Class.AddItem(class'KFPawn_ZedBloatKing');
	Bosses_Name.AddItem("4");	Bosses_Class.AddItem(class'KFPawn_ZedMatriarch');
	Bosses_Len = Bosses_Name.Length;

	//自定义Boss
	if (AnotherBoss=="") {
		MyKFGI.SpawnManager.TimeUntilNextSpawn = 0;
		return;
	}
	ParseStringIntoArray(AnotherBoss,SplitBuf,",",true);

	foreach SplitBuf(Buf) {
		if (Buf=="Rand") {
			AddUniqueBoss(SpawnList, Bosses_Class, Bosses_Len); // 调用AddUniqueBoss函数
		}else{
			for(i=0;i<Bosses_Len-1;i++) {
				if (Buf==Bosses_Name[i]) SpawnList.AddItem(Bosses_Class[i]);
			}
		}
    }

    NumBosses = SpawnList.Length; //获取要生成的boss数量

    for (i=0; i<NumBosses; i++) { //循环生成boss
    	MyKFGI.NumAISpawnsQueued += MyKFGI.SpawnManager.SpawnSquad(SpawnList);
    	MyKFGI.SpawnManager.TimeUntilNextSpawn = MyKFGI.SpawnManager.CalcNextGroupSpawnTime();
    }
}

//添加一个不重复的boss到SpawnList中
function AddUniqueBoss(out array<class<KFPawn_Monster> > SpawnList, array<class<KFPawn_Monster> > Bosses_Class, byte Bosses_Len) {
	local class<KFPawn_Monster> NewBoss;
	local bool bRepeat;
	local int i;

	do { //循环直到生成一个不重复的boss
		bRepeat = false; //假设不重复
		NewBoss = Bosses_Class[Rand(Bosses_Len)]; //随机生成一个boss
		for(i=0;i<SpawnList.Length;i++){ // 遍历SpawnList
			if (NewBoss == SpawnList[i]) { //如果和已有的boss重复
				bRepeat = true; //标记为重复
				break; //跳出循环
			}
		}
	} until (!bRepeat); //如果重复就重新生成

	SpawnList.AddItem(NewBoss); //添加到SpawnList中
}

///////////////////////限制等级进入////////////////////
function SetLimitLevel(){
	local KFPawn Player;
	local KFPlayerController KFPC;
	local AuthSession CurClientSession;
	local UniqueNetId UID;

	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC){
		Player = KFPawn(KFPC.Pawn);
		if(Player != None){
			if(!KFPC.PlayerReplicationInfo.bWaitingPlayer && !KFPC.PlayerReplicationInfo.bOnlySpectator){
				if(IsBadPerkLevel(KFPC.GetPerk().GetLevel())){
					UID = KFPC.PlayerReplicationInfo.UniqueId;
				    Player.Suicide();
		            KFPC.ClientWasKicked(); //踢出服务器
					//防止复制UID
					foreach CachedAuthInt.AllClientAuthSessions(CurClientSession){
						CachedAuthInt.EndRemoteClientAuthSession(UID, CurClientSession.EndPointIP);
					}
		            if(KFPC != None) 
				        KFPC.Destroy();
				}
			}
		}
	}
}

function bool IsBadPerkLevel(int PerkLevel) {
	if(SetDisableLevel > 25) SetDisableLevel = 25;
	if(SetDisableLevel > PerkLevel) return true;
	else return false;
}
///////////////////////////////////////////////
////////////////爆头率查询/////////////////
function SendHitAccuracy(){
	local KFPlayerController KFPC;
	local string PlayerName, ShotHeadAcc, ShotAcc, ShotHead, ShotMessage;
	local string CurrentShotHeadAcc, CurrentShotAcc, CurrentShotHead;
	local string CurrentKillLarge, KillLarge;
	local int PlayerID; // 声明一个变量来存储玩家的ID
	local PlayerData PD; // 声明一个变量来存储玩家的临时数据
	local int Index; // 声明一个变量来存储玩家在数组中的索引
	local bool Found; // 声明一个变量来标记是否找到了对应的玩家

	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC) {
			if(MyKFGI.MyKFGRI.bTraderIsOpen && SendMessageOnce && !KFPC.PlayerReplicationInfo.bWaitingPlayer && !KFPC.PlayerReplicationInfo.bOnlySpectator) { 
				PlayerName = KFPC.PlayerReplicationInfo.PlayerName;
				PlayerID = KFPC.PlayerReplicationInfo.PlayerID; // 获取玩家的ID

				Found = false; // 初始化标记为false
				for (Index = 0; Index < PlayerMap.Length; Index++) // 遍历数组
				{
				    if (PlayerMap[Index].PlayerID == PlayerID) // 如果找到了对应的玩家ID
				    {
				        Found = true; // 设置标记为true
				        break; // 跳出循环
				    }
				}

				if (Found == false) // 如果没有找到对应的玩家ID，说明是新加入的玩家
				{
				    PD.PlayerID = PlayerID; // 初始化临时数据
				    PD.TempShotHead = KFPC.ShotsHitHeadshot;
				    PD.TempShotFire = KFPC.ShotsFired;
				    PD.TempShotHit = KFPC.ShotsHit;
				    PD.TempKillLarge = KFPC.MatchStats.TotalLargeZedKills;
				    PlayerMap.AddItem(PD); // 把临时数据添加到数组
				    Index = PlayerMap.Length - 1; // 设置索引为数组的最后一个元素
				}
				else // 如果找到了对应的玩家ID，说明是已经存在的玩家
				{
				    PD = PlayerMap[Index]; // 获取临时数据
				}

				CurrentShotHeadAcc = string(int((float(KFPC.ShotsHitHeadshot - PD.TempShotHead)/float(KFPC.ShotsFired - PD.TempShotFire)) * 100.0));
				CurrentShotAcc = string(int(float(KFPC.ShotsHit - PD.TempShotHit)/float(KFPC.ShotsFired - PD.TempShotFire) * 100.0));
				CurrentShotHead = string(KFPC.MatchStats.TotalHeadShots - PD.TempShotHead);
				CurrentKillLarge = string(KFPC.MatchStats.TotalLargeZedKills - PD.TempKillLarge);

				PD.TempShotHead = KFPC.MatchStats.TotalHeadShots; // 更新临时数据
				PD.TempShotFire = KFPC.ShotsFired;
				PD.TempShotHit = KFPC.ShotsHit;
				PD.TempKillLarge = KFPC.MatchStats.TotalLargeZedKills;
				PlayerMap[Index] = PD; // 把临时数据存入数组

				ShotHeadAcc = string(byte((float(KFPC.ShotsHitHeadshot)/float(KFPC.ShotsFired)) * 100.0));
			    ShotAcc = string(byte(float(KFPC.ShotsHit)/float(KFPC.ShotsFired) * 100.0));
			    ShotHead = string(KFPC.MatchStats.TotalHeadShots);
				KillLarge = string(KFPC.MatchStats.TotalLargeZedKills);

				if(MyKFGI.MyKFGRI.WaveNum > 1){
					ShotMessage = "玩家: " $ PlayerName $ " 本次爆头率: "$ CurrentShotHeadAcc $ "%, 命中率: " $ CurrentShotAcc $ "%, 爆头数: " $ CurrentShotHead $
				    " 大怪击杀数: " $ CurrentKillLarge $ " ----- 总爆头率: "$ ShotHeadAcc $ "%, 总命中率: " $ ShotAcc $ "% , 总爆头数: " $ ShotHead $ " 总大怪击杀数: " $ KillLarge$ "  (仅供参考)";
				}else {
					ShotMessage = "玩家: " $ PlayerName $ " 爆头率: "$ ShotHeadAcc $ "%, 命中率: " $ ShotAcc $ "% , 爆头数: " $ ShotHead$ "  (仅供参考)";
				}	
				KFPC.TeamMessage(KFPC.PlayerReplicationInfo, ShotMessage, 'Event');
			}
    }

	SendMessageOnce = false;
	if(!MyKFGI.MyKFGRI.bTraderIsOpen){ 
		SendMessageOnce = true;
	}
}

/////////////////ZedTime可视化///////////////////
function ZedTimeVisibility(){
	local KFPlayerController KFPC;
	local string ZedTimeCount;
	local KFGameInfo KFGID;

	KFGID = KFGameInfo(WorldInfo.Game);
	ZedTimeCount = "ZedTime剩余时间: " $ string(KFGID.ZedTimeRemaining) $ "秒";
	
	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC){
		if(KFGID.ZedTimeRemaining > 0 && !MyKFGI.MyKFGRI.bTraderIsOpen)
		    KFPC.TeamMessage(KFPC.PlayerReplicationInfo, ZedTimeCount, 'Event');
	}
}

///////////////////开局武器变换///////////////////
function ModifyPlayerStartWeap(){
	local KFPawn Player;
	local KFPlayerController KFPC;
	local class<KFPerk> cKFP;
	local class<Weapon> cRetW;
	local Inventory Inv;
	local bool bFound;

    if(MyKFGI.MyKFGRI.WaveNum == 1 && !MyKFGI.MyKFGRI.bTraderIsOpen){
		foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC){
			Player = KFPawn_Human(KFPC.Pawn);
			cKFP = KFPC.GetPerk().GetPerkClass();
			cRetW = GetStartingWeapClassFromPerk(cKFP);
			bFound = False;

			if(cRetW!=None && !KFPC.PlayerReplicationInfo.bWaitingPlayer && !KFPC.PlayerReplicationInfo.bOnlySpectator){
			    for(Inv=Player.InvManager.InventoryChain;Inv!=None;Inv=Inv.Inventory){
					switch(Inv.ItemName) {
						case class'KFGameContent.KFWeap_Blunt_Crovel'.default.ItemName:
						case class'KFGameContent.KFWeap_AssaultRifle_AR15'.default.ItemName:
						case class'KFGameContent.KFWeap_Shotgun_MB500'.default.ItemName:
						case class'KFGameContent.KFWeap_Pistol_Medic'.default.ItemName:
						case class'KFGameContent.KFWeap_GrenadeLauncher_HX25'.default.ItemName:
						case class'KFGameContent.KFWeap_Flame_CaulkBurn'.default.ItemName:
						case class'KFGameContent.KFWeap_Revolver_DualRem1858'.default.ItemName:
						case class'KFGameContent.KFWeap_Rifle_Winchester1894'.default.ItemName:
						case class'KFGameContent.KFWeap_SMG_MP7'.default.ItemName:
							if(ChangeWeap) Player.InvManager.RemoveFromInventory(Inv);
							bFound = true;
							break;
					}
					if(bFound) break;
				}

				if(ChangeWeap){ 
					Player.Weapon = Weapon(Player.CreateInventory(cRetW,Player.Weapon!=None));
				    Player.InvManager.ServerSetCurrentWeapon(Player.Weapon);
				}
				if(StartFillAmmo) FillWeaponAmmo(KFWeapon(Player.Weapon));
			}
		}
		StartFillAmmo = false;//只补充一次弹药
		ChangeWeap = false;//防止不断增加武器
	}
}

function class<Weapon> GetStartingWeapClassFromPerk(class<KFPerk> Perk) {
	local string SendStr, Weap;

	SendStr = "";
	switch(Perk) {
		case class'KFPerk_Berserker':
			SendStr = StartingWeapon_Berserker;
			break;
	    case class'KFPerk_Commando':
			SendStr = StartingWeapon_Commando;
			break;
		case class'KFPerk_Support':
			SendStr = StartingWeapon_Support;
			break;
		case class'KFPerk_FieldMedic':
			SendStr = StartingWeapon_FieldMedic;
			break;
		case class'KFPerk_Demolitionist':
			SendStr = StartingWeapon_Demolitionist;
			break;
		case class'KFPerk_Firebug':
			SendStr = StartingWeapon_Firebug;
			break;
		case class'KFPerk_Gunslinger':
			SendStr = StartingWeapon_Gunslinger;
			break;
		case class'KFPerk_Sharpshooter':
			SendStr = StartingWeapon_Sharpshooter;
			break;
		case class'KFPerk_Survivalist':
			SendStr = StartingWeapon_Survivalist;
			break;
		case class'KFPerk_Swat':
			SendStr = StartingWeapon_Swat;
			break;
	}
	if (SendStr=="") return None;

	Weap = "KFGameContent.KFWeap_" $ SendStr;
	return class<Weapon>(DynamicLoadObject(Weap, class'Class'));
}

function FillWeaponAmmo(KFWeapon KFW) {
	if(WeaponSpareAmmoMutipiler > 0){
		KFW.InitializeAmmoCapacity();
		KFW.SpareAmmoCapacity[0] = KFW.SpareAmmoCapacity[0] * WeaponSpareAmmoMutipiler;
		KFW.SpareAmmoCapacity[1] = KFW.SpareAmmoCapacity[1] * WeaponSpareAmmoMutipiler;
	}

	KFW.AmmoCount[0] = KFW.MagazineCapacity[0];
	KFW.AmmoCount[1] = KFW.MagazineCapacity[1];

	//后备弹药
	KFW.SpareAmmoCount[0] = KFW.SpareAmmoCapacity[0] + KFW.MagazineCapacity[0] - KFW.AmmoCount[0];
	KFW.SpareAmmoCount[1] = KFW.SpareAmmoCapacity[1] + KFW.MagazineCapacity[1] - KFW.AmmoCount[1]; 

	KFW.ClientForceAmmoUpdate(KFW.AmmoCount[0],KFW.SpareAmmoCount[0]);
	KFW.ClientForceSecondaryAmmoUpdate(KFW.AmmoCount[1]);
}

///////////////////修改手雷上限///////////////////
function ModifyMaxGrenade(){
	local KFPlayerController KFPC;
	local int MaxGrenade;

	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC) {
		if (!KFPC.PlayerReplicationInfo.bWaitingPlayer){
			MaxGrenade = int(WaveZedCountMutipiler * KFPC.GetPerk().default.MaxGrenadeCount);
			KFPC.GetPerk().MaxGrenadeCount = MaxGrenade;
			MaxGrenade = 0;
		}
	}
}

////////////自配buff//////////////
private function PowerUpHellishRage(){
    local KFPlayerController KFPC;

	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC) {
		if( KFPC != none && !KFPC.PlayerReplicationInfo.bWaitingPlayer && !MyKFGI.MyKFGRI.bTraderIsOpen)
        {
            KFPC.ReceivePowerUp(class'AccessCai.ACaiPowerUp');
        }
	}
}
/////////////////////专属CD//////////////////////
function PutLargeZed() {
	local array<class<KFPawn_Monster> > Zed_Hell;
	local array<class<KFPawn_Monster> > Zed_Normal;
	local array<class<KFPawn_Monster> > Scrake;
	local array<class<KFPawn_Monster> > FleshPound;
	local int Curwave;
	
	Zed_Hell.AddItem(class'KFGameContent.KFPawn_ZedScrake');
	Zed_Hell.AddItem(class'KFGameContent.KFPawn_ZedFleshpound');
	Zed_Hell.AddItem(class'KFGameContent.KFPawn_ZedFleshpoundMini');

	Zed_Normal.AddItem(class'KFGameContent.KFPawn_ZedScrake');
	Zed_Normal.AddItem(class'KFGameContent.KFPawn_ZedFleshpoundMini');

	Scrake.AddItem(class'KFGameContent.KFPawn_ZedScrake');
	FleshPound.AddItem(class'KFGameContent.KFPawn_ZedFleshpound');
	FleshPound.AddItem(class'KFGameContent.KFPawn_ZedFleshpoundMini');

	Curwave = MyKFGI.MyKFGRI.WaveNum;

    if(MyKFGI.IsWaveActive() && MyKFGI.SpawnManager.GetAIAliveCount() <= iMaxMonsters && Curwave < MyKFGI.MyKFGRI.WaveMax){
		if(LargeZedNum < (MyKFGI.MyKFGRI.AIRemaining - MyKFGI.SpawnManager.GetAIAliveCount())){
		    switch(My_Difficulty){
			    case "SC":
			        AddLargeZed(Scrake);
				    break;
			    case "FP":
			        AddLargeZed(FleshPound);
				    break;
				case "Normal":
			        AddLargeZed(Zed_Normal);
				    break;
			    case "Hell":
			        AddLargeZed(Zed_Hell);
				    break;
		    }
	        MyKFGI.SpawnManager.TimeUntilNextSpawn = MyKFGI.SpawnManager.CalcNextGroupSpawnTime();
	        MyKFGI.UpdateAIRemaining();
			LargeZedNum += 1;
	    }
	}
	else
		LargeZedNum = 0;
}

function AddLargeZed(array<class<KFPawn_Monster> > LargeZed){
	MyKFGI.NumAISpawnsQueued += MyKFGI.SpawnManager.SpawnSquad(LargeZed);
}

////////////////发送消息/////////////////
function DeliverMessage(KFPlayerController KFPC, String Msg){
	KFPC.TeamMessage(KFPC.PlayerReplicationInfo, Msg, 'Event');
}

/////////////////////////突击无限续秒///////////////////////
function Commando_ZedTimeExtend(){
	local KFPlayerController KFPC;

	foreach WorldInfo.AllControllers(class'KFPlayerController', KFPC){
		if(KFPC != None){
		    if(MyKFGI.IsZedTimeActive()){
			    if(KFPC.GetPerk().IsA('KFPerk_Commando')){
					if(KFPC.GetPerk().GetZedTimeExtension(KFPC.GetLevel()) <= MyKFGI.ZedTimeExtensionsUsed )
					    MyKFGI.ZedTimeExtensionsUsed = 2;//重置续秒次数
			    }
		    }
		}
	}
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
private function LoadRelations(){
	local RankRelation Player, SteamGroup;
	local UIDRankRelation UIDInfo;
	
	`callstack();
	
	foreach class'PlayerRankRelations'.default.Relation(Player){
		UIDInfo.RankID = Player.RankID;
		if (IsUID(Player.ObjectID) && Steamworks.StringToUniqueNetId(Player.ObjectID, UIDInfo.UID)){
			if (UIDRankRelationsPlayers.Find('Uid', UIDInfo.UID) == INDEX_NONE)
			UIDRankRelationsPlayers.AddItem(UIDInfo);
		}
		else if (Steamworks.Int64ToUniqueNetId(Player.ObjectID, UIDInfo.UID)){
			if (UIDRankRelationsPlayers.Find('Uid', UIDInfo.UID) == INDEX_NONE)
			UIDRankRelationsPlayers.AddItem(UIDInfo);
		}
		else `warning("Can't add player:"@Player.ObjectID);
	}
	
	foreach class'SteamGroupRankRelations'.default.Relation(SteamGroup){
		UIDInfo.RankID = SteamGroup.RankID;
		if (IsUID(SteamGroup.ObjectID) && Steamworks.StringToUniqueNetId(SteamGroup.ObjectID, UIDInfo.UID)){
			if (UIDRankRelationsPlayers.Find('Uid', UIDInfo.UID) == INDEX_NONE)
			UIDRankRelationsPlayers.AddItem(UIDInfo);
		}
		else if (Steamworks.Int64ToUniqueNetId(SteamGroup.ObjectID, UIDInfo.UID)){
			if (UIDRankRelationsSteamGroups.Find('Uid', UIDInfo.UID) == INDEX_NONE)
			UIDRankRelationsSteamGroups.AddItem(UIDInfo);
		}
		else `warning("Can't add steamgroup:"@SteamGroup.ObjectID);
	}
}

private function AddPlayer(Controller C){
	local KFPlayerController KFPC;
	local UIDRankRelation Relation;
	local SClient RepClient, RepClientNew;
	
	`callstack();
	
	KFPC = KFPlayerController(C);

	if (KFPC == None)
		return;

	RepClientNew.KFPC = KFPC;
	RepClientNew.RepInfo = Spawn(class'YASRepInfo', KFPC);
	
	RepClientNew.RepInfo.Mut = Self;
	RepClientNew.RepInfo.CustomRanks = class'CustomRanks'.default.Rank;
	RepClientNew.RepInfo.SteamGroupRelations = UIDRankRelationsSteamGroups;
	RepClientNew.RepInfo.Settings = Settings;
	RepClientNew.RepInfo.RankRelation.UID = KFPC.PlayerReplicationInfo.UniqueId;
	RepClientNew.RepInfo.RankRelation.RankID = UIDRankRelationsPlayers.Find('UID', RepClientNew.RepInfo.RankRelation.UID);
	
	RepClients.AddItem(RepClientNew);
	
	foreach UIDRankRelationsActive(Relation){
		RepClientNew.RepInfo.AddRankRelation(Relation);
	}
	
	RepClientNew.RepInfo.StartFirstTimeReplication();
	
	if (RepClientNew.RepInfo.RankRelation.RankID != INDEX_NONE){
		UIDRankRelationsActive.AddItem(RepClientNew.RepInfo.RankRelation);
		foreach RepClients(RepClient){
			RepClient.RepInfo.AddRankRelation(RepClientNew.RepInfo.RankRelation);
		}
	}
}

private function RemovePlayer(Controller C){
	local KFPlayerController KFPC;
	local int Index, i;
	local UniqueNetId UID;

	`callstack();

	KFPC = KFPlayerController(C);
	if (KFPC == None)
		return;

	UID = KFPC.PlayerReplicationInfo.UniqueId;
	Index = UIDRankRelationsActive.Find('UID', UID);
	if (Index != INDEX_NONE){
		for (i = 0; i < UIDRankRelationsActive.Length; ++i){
			if (Index != i && RepClients.Length > i){
				if ( RepClients[i].RepInfo != None ){
					RepClients[i].RepInfo.RemoveRankRelation(UIDRankRelationsActive[Index]);
				}
			}
		}
	}

	Index = RepClients.Find('KFPC', KFPC);
	if (Index == INDEX_NONE)
		return;
	
	if (RepClients[Index].RepInfo != None)
		RepClients[Index].RepInfo.Destroy();
	
	RepClients.Remove(Index, 1);
}

public function UpdatePlayerRank(UIDRankRelation Rel)
{
	local SClient RepClient;
	local int Index;
	
	`callstack();
	
	Index = UIDRankRelationsActive.Find('UID', Rel.UID);
	if (Index != INDEX_NONE)
		UIDRankRelationsActive[Index] = Rel;
	else
		UIDRankRelationsActive.AddItem(Rel);
	
	foreach RepClients(RepClient){
		RepClient.RepInfo.UpdateRankRelation(Rel);
	}
}

public function AddPlayerRank(UIDRankRelation Rel)
{
	local SClient RepClient;
	
	`callstack();
	
	foreach RepClients(RepClient){
		RepClient.RepInfo.AddRankRelation(Rel);
	}
}

function ModifySpawnManager(){
	local int I, J, MonsterNum, CurrentPlayer;
	local float Multi;

	CurrentPlayer = MyKFGI.GetLivingPlayerCount();//获取当前存活人数
	if(CurrentPlayer > 6) CurrentPlayer = 6; //防止超过索引

	if(!bSpawnManagerModified){
		if(MyKFGI.SpawnManager != none){
			for ( I = 0; i < MyKFGI.SpawnManager.PerDifficultyMaxMonsters.Length; i++ ){
				for (J = 0; J < MyKFGI.SpawnManager.PerDifficultyMaxMonsters[I].MaxMonsters.Length; J++){			
				    if(IsDynamicMaxMonster && iMaxMonsters > 0 && CurrentPlayer <= 3){
					    //获取默认同屏
					    MonsterNum = MyKFGI.SpawnManager.default.PerDifficultyMaxMonsters[I].MaxMonsters[J];
					    Multi = float(iMaxMonsters / 32); //获取设置的倍数
						MyKFGI.SpawnManager.PerDifficultyMaxMonsters[I].MaxMonsters[J] = int(MonsterNum * Multi);
					}else
				        MyKFGI.SpawnManager.PerDifficultyMaxMonsters[I].MaxMonsters[J] = iMaxMonsters;
				}
			}
			bSpawnManagerModified = true;
			ClearTimer('ModifySpawnManager');
		}
	}
}

function UnionBanTimer()
{
	local BanDataSyncPager banDateGet;
	local UnionServerSync serverPush;

	local int port;
	local string addr;
	local string key;
	local string syncBanParam;
	local string pushServerParam;

	key = "CHFNERKUWVGENKFHM234MO87DN3248XMJ9H7";
	addr = "www.hommon.cn";
	port = 80;
	syncBanParam = "unionban.php?key="$key$"&type=GET_UNION_BAN_DATA_MUTATOR";
	pushServerParam = "unionban.php?key="$key$"&type=POST_SERVER_UPDATE&ip="$UnionServerIP$"&query_port="$UnionServerQueryPort;

	banDateGet = Spawn(class'BanDataSyncPager');
	serverPush = Spawn(class'UnionServerSync');

	banDateGet.accessControl = Self;
	banDateGet.TargetHost = addr;
	banDateGet.TargetPort = port;
	banDateGet.params = syncBanParam;
	banDateGet.startSync();

	// 如果设置了域名/IP和查询端口就推送消息
	if (UnionServerIP != "" && UnionServerQueryPort > 0){
		serverPush.TargetHost = addr;
		serverPush.TargetPort = port;
		serverPush.params = pushServerParam;
		serverPush.startSync();
	}
}

function MultiperTimer(){
	local PlayerController PC;
	local KFWeapon KFW;

	//setup total amount multiplier
	if(cwave<MyKFGI.WaveNum && MyKFGI.WaveNum!=MyKFGI.WaveMax){
		cwave=MyKFGI.WaveNum;
		MyKFGI.SpawnManager.WaveTotalAI = MyKFGI.SpawnManager.WaveTotalAI * WaveZedCountMutipiler;
		MyKFGI.MyKFGRI.WaveTotalAICount = MyKFGI.SpawnManager.WaveTotalAI;
		MyKFGI.MyKFGRI.AIRemaining = MyKFGI.SpawnManager.WaveTotalAI;  
		MyKFGI.RefreshMonsterAliveCount();
		if (cwave == 1) firstWaveSupply = false;
	}

	foreach WorldInfo.AllControllers(class'PlayerController', PC){
		if(PC.PlayerReplicationInfo!=None && PC.Pawn!=None && PC.Pawn.Health>0 && PC.Pawn.InvManager != None){
			foreach KFInventoryManager(PC.Pawn.InvManager).InventoryActors(class'KFWeapon',KFW){
				// N倍弹药
				if(WeaponSpareAmmoMutipiler > 0){
					KFW.InitializeAmmoCapacity();
					KFW.SpareAmmoCapacity[0] = KFW.SpareAmmoCapacity[0] * WeaponSpareAmmoMutipiler;
					KFW.SpareAmmoCapacity[1] = KFW.SpareAmmoCapacity[1] * WeaponSpareAmmoMutipiler;
				}

				if (!firstWaveSupply){
					//弹夹子弹拉满
					KFW.AmmoCount[0] = KFW.MagazineCapacity[0];
					KFW.AmmoCount[1] = KFW.MagazineCapacity[1];

					//后备弹药
					KFW.SpareAmmoCount[0] = KFW.SpareAmmoCapacity[0] + KFW.MagazineCapacity[0] - KFW.AmmoCount[0];
					KFW.SpareAmmoCount[1] = KFW.SpareAmmoCapacity[1] + KFW.MagazineCapacity[1] - KFW.AmmoCount[1]; 
						
					KFW.ClientForceAmmoUpdate(KFW.AmmoCount[0],KFW.SpareAmmoCount[0]);
					KFW.ClientForceSecondaryAmmoUpdate(KFW.AmmoCount[1]);					
				}

				//无限子弹
				if(bInfiniteAmmo){
					if(KFW.SpareAmmoCount[0] == 0)
						KFW.SpareAmmoCount[0] = KFW.SpareAmmoCapacity[0];
					if(KFW.SpareAmmoCount[1] == 0)
						KFW.SpareAmmoCount[1] = KFW.SpareAmmoCapacity[1];
				} 
			}
		}
	}

	if (!firstWaveSupply) firstWaveSupply = true;
}

function NotifyServerTravel(bool bSeamless)
{
	CheckBanData();
	if( BansData.AdvanceBans() )
	SaveBanData();
	Super.NotifyServerTravel(bSeamless);
}
function SetupWebadmin()	
{
	local WebServer W;
	local WebAdmin A;
	local AccessCaiWebApp xW;
	local byte i;

	foreach AllActors(class'WebServer',W)
	break;
	if( W!=None ){
		for( i=0; (i<10 && A==None); ++i )
		A = WebAdmin(W.ApplicationObjects[i]);
		if( A!=None ){
			xW = new (None) class'AccessCaiWebApp';
			xW.AccessControl = Self;
			A.addQueryHandler(xW);
		}
		else `Log("AccessCaiWebAdmin ERROR: No valid WebAdmin application found!");
	}
	else `Log("AccessCaiWebAdmin ERROR: No WebServer object found!");
}
final function bool CheckAdminData()
{
	class'Engine'.Static.BasicLoadObject(SecDataRef,GetFilePath(false),false,0);
	if( SecDataRef.STG!=AdminData.STG )
	{
		SaveDataUpdated();
		return true;
	}
	return false; 
}
final function SaveAdminData()
{
	++AdminData.STG;
	class'Engine'.Static.BasicSaveObject(AdminData,GetFilePath(false),false,0,true);
}
final function SaveDataUpdated()
{
	local PlayerController P;
	local AdminPlusCheats A;
	local AccessData T;
	
	// Swap.
	T = AdminData;
	AdminData = SecDataRef;
	SecDataRef = T;

	AdminData.ParseUIDs();
	foreach WorldInfo.AllControllers(class'PlayerController',P){
		A = AdminPlusCheats(P.CheatManager);
		if( A!=None && A.AdminIndex>=0 && AdminLogOut(P) ){
			AdminExited(P);
			P.ClientMessage("Admin accounts were modified in another server, please relogin.");
		}
	}
}
final function bool CheckBanData()
{
	local AccessCaiBans T;

	class'Engine'.Static.BasicLoadObject(SecBansData,GetFilePath(true),false,0);
	if( SecBansData.STG!=BansData.STG ){
		// Swap.
		T = BansData;
		BansData = SecBansData;
		SecBansData = T;

		// Sync time.
		BansData.StartTime = SecBansData.StartTime;
		return true;
	}
	return false;
}
final function SaveBanData()
{
	++BansData.STG;
	BansData.bDirty = false;
	class'Engine'.Static.BasicSaveObject(BansData,GetFilePath(true),false,0);
}

// Webadmin login.
function bool ValidLogin(string UserName, string Password)
{
	local int i;
	
	for( i=0; i<AdminData.AU.Length; ++i ){
		if( UserName~=AdminData.AU[i].PL && AdminData.AU[i].PW!="" && Password==AdminData.AU[i].PW )
		return (AdminData.GetAdminType(i)<=1);
	}
	return (UserName~="Admin" && Password==AdminData.GPW);
}

final function LoginAdmin( PlayerController P, int AccIndex, bool bSilent, optional bool bLogin )
{
	local int i;
	local AdminPlusCheats A;
	local string S;
	local byte t;
	
	if( bLogin && AdminData.AU[AccIndex].NA )
	return;
	P.PlayerReplicationInfo.bAdmin = true;
	A = AdminPlusCheats(P.CheatManager);
	if( A==None ){
		A = new(P)class'AdminPlusCheats';
		P.CheatManager = A;
		A.InitCheatManager();
	}
	else A.Logout();
	A.AccessController = Self;
	
	if( AccIndex==-1 ){
		S = "Super Admin";
		t = 0;
	}
	else{
		i = AdminData.FindAdminGroup(AdminData.AU[AccIndex].ID);
		t = 1;
		if( i==-1 ){
			P.PlayerReplicationInfo.bAdmin = false;
			P.ClientMessage("Can't login as admin: Broken admin account.");
			return;
		}
		else{
			S = AdminData.AG[i].GN;
			A.SetCommands(AdminData.AG[i].PR,AdminData);
			t = AdminData.AG[i].AT+1;
			if( t>=4 ) // VIP.
			{
				bSilent = true;
				P.PlayerReplicationInfo.bAdmin = false;
			}
		}
	}
	P.PlayerReplicationInfo.BeginState(AdminLevels[Min(t,AdminLevels.Length-1)]);

	if( bLogin ){
		if( !bSilent )
		WorldInfo.Game.Broadcast(Self,P.PlayerReplicationInfo.PlayerName$" is an "$S$".",'Priority');
	}
	else{
		if( !bSilent )
		WorldInfo.Game.Broadcast(Self,P.PlayerReplicationInfo.PlayerName$" logged in as "$S$".",'Priority');
		P.ClientMessage("You have logged in as "$S$", use 'Admin Help' to see command list.");
	}

	A.bSilentAdmin = bSilent;
	A.bGlobalAdmin = (AccIndex==-1);
	A.AdminIndex = AccIndex;
	A.AdminName = (A.bGlobalAdmin ? P.PlayerReplicationInfo.PlayerName$" (SA)" : AdminData.AU[AccIndex].PL);
}
function bool AdminLogin( PlayerController P, string Password )
{
	local bool bSilent;
	local int i;
	local AdminPlusCheats A;
	
	A = AdminPlusCheats(P.CheatManager);
	if( A!=None && A.IsLoggedIn() ){
		P.ClientMessage("Can't login as admin: You already are an admin.");
		return false;
	}
	if( Password=="" ) // During login.
	{
		i = AdminData.FindAdminUser(P.PlayerReplicationInfo.UniqueId);
		if( i>=0 ){
			LoginAdmin(P,i,false,true);
			return true;
		}
		return false;
	}

	bSilent = (Right(Password,7)~=" silent");
	if( bSilent )
	Password = Left(Password,Len(Password)-7);
	else{
		bSilent = (Password~="silent");
		if( bSilent )
		Password = "";
	}

	// Check if super admin.
	if( AdminData.GPW!="" && Password==AdminData.GPW ){
		LoginAdmin(P,-1,bSilent);
		return true;
	}

	// first check for matching password
	if( Password!="" ){
		i = AdminData.FindAdminPW(Password);
		if( i>=0 ){
			LoginAdmin(P,i,bSilent);
			return true;
		}
	}
	// Then check for matching ID.
	i = AdminData.FindAdminUser(P.PlayerReplicationInfo.UniqueId);
	if( i>=0 ){
		LoginAdmin(P,i,bSilent);
		return true;
	}
	P.ClientMessage("Invalid password!");
	return false;
}
function AdminEntered( PlayerController P );

function AdminExited( PlayerController P )
{
	local AdminPlusCheats A;
	
	A = AdminPlusCheats(P.CheatManager);
	if( A!=None ){
		if( !A.bSilentAdmin )
		WorldInfo.Game.Broadcast(Self,P.PlayerReplicationInfo.PlayerName$" gave up their administrative abilities.",'Priority');
	}
}

function bool AdminLogout(PlayerController P)
{
	local AdminPlusCheats A;

	RemovePlayer(P);

	A = AdminPlusCheats(P.CheatManager);
	if ( P.PlayerReplicationInfo.bAdmin || (A!=None && A.IsLoggedIn()) ){
		P.PlayerReplicationInfo.BeginState('User');
		P.PlayerReplicationInfo.bAdmin = false;
		P.bGodMode = false;
		A.Logout();
		return true;
	}
	return false;
}

final function int CreateAdminAccount( PlayerReplicationInfo PRI )
{
	local int i;

	CheckAdminData();
	
	i = AdminData.FindAdminUser(PRI.UniqueId);
	if( i>=0 )
	return -1;
	i = AdminData.AU.Length;
	AdminData.AU.Length = i+1;
	AdminData.AU[i].PL = PRI.PlayerName;
	AdminData.AU[i].ID = "";
	AdminData.AU[i].UID = class'OnlineSubsystem'.Static.UniqueNetIdToString(PRI.UniqueId);
	AdminData.AU[i].AdminID = PRI.UniqueId;
	AdminData.AU[i].PW = "";
	
	SaveAdminData();
	return i;
}
final function DeleteAdminAccount( int Index )
{
	local PlayerController PC;
	local AdminPlusCheats A;
	local UniqueNetID ID;

	ID = AdminData.AU[Index].AdminID;
	if( CheckAdminData() ){
		Index = AdminData.FindAdminUser(ID);
		if( Index==-1 )
		return;
	}
	AdminData.AU.Remove(Index,1);
	SaveAdminData();

	// Update live admins if needed.
	foreach WorldInfo.AllControllers(class'PlayerController',PC){
		if( !PC.PlayerReplicationInfo.bAdmin )
		continue;
		A = AdminPlusCheats(PC.CheatManager);
		if( A.AdminIndex==Index ){
			// Kick em out.
			if ( AdminLogOut(PC) ){
				AdminExited(PC);
				PC.ClientMessage("Your admin account was deleted.");
			}
		}
		else if( A.AdminIndex>Index )
		--A.AdminIndex;
	}
}
final function SetAdminGroup( PlayerController P, int Index, string NewGroup )
{
	local int i;
	local PlayerController PC;
	local AdminPlusCheats A;
	local UniqueNetID UID;

	if( Index<0 || Index>=AdminData.AU.Length ){
		P.ClientMessage("Invalid admin index to edit ("$Index$"/"$(AdminData.AU.Length-1)$")");
		return;
	}
	NewGroup = Caps(NewGroup);
	UID = AdminData.AU[Index].AdminID; // Store this info incase it gets changed.
	if( CheckAdminData() ){
		Index = AdminData.FindAdminUser(UID);
		if( Index==-1 ){
			P.ClientMessage("Invalid GroupID change: Admin account was deleted.");
			return;
		}
	}
	i = AdminData.FindAdminGroup(NewGroup);
	if( i==-1 ){
		P.ClientMessage("Invalid GroupID: "$NewGroup$" (use ListGroups to see which ones there are)");
		return;
	}
	P.ClientMessage("Modified account #"$Index$" ("$AdminData.AU[Index].PL$") GroupID to "$NewGroup);
	AdminData.AU[Index].ID = NewGroup;
	SaveAdminData();
	
	// Update live admins if needed.
	foreach WorldInfo.AllControllers(class'PlayerController',PC){
		if( !PC.PlayerReplicationInfo.bAdmin )
		continue;
		A = AdminPlusCheats(PC.CheatManager);
		if( A.AdminIndex==Index ){
			// Kick em out.
			if ( AdminLogOut(PC) ){
				AdminExited(PC);
				PC.ClientMessage("Your admin account was modified, please relogin as admin.");
			}
		}
	}
}

final function WebDeleteGroup( int Index )
{
	local string S;
	
	// First cache current group ID before updating.
	S = AdminData.AG[Index].ID;
	if( CheckAdminData() ){
		if( Index>=AdminData.AG.Length || S!=AdminData.AG[Index].ID ) // Got changed.
		return;
	}
	
	AdminData.AG.Remove(Index,1);
	SaveAdminData();
}
final function int WebAddGroup()
{
	local int i;
	
	CheckAdminData();
	
	i = AdminData.AG.Length;
	AdminData.AG.Length = i+1;
	AdminData.AG[i].PR = "Cheat,GamePlay,Admin";
	AdminData.AG[i].GN = "New Group";
	AdminData.AG[i].ID = "ADMIN_"$i;
	SaveAdminData();
	
	return i;
}
final function WebEditGroup( int Index, string Privs, string GroupID, string GroupName, byte AdminType )
{
	local string S;
	
	// First cache current group ID before updating.
	S = AdminData.AG[Index].ID;
	if( CheckAdminData() ){
		if( Index>=AdminData.AG.Length || S!=AdminData.AG[Index].ID ) // Got changed.
		return;
	}
	
	AdminData.AG[Index].PR = Privs;
	AdminData.AG[Index].GN = GroupName;
	AdminData.AG[Index].ID = Caps(GroupID);
	AdminData.AG[Index].AT = AdminType;
	SaveAdminData();
}
final function WebDeleteUser( int Index )
{
	local UniqueNetID ID;
	
	// First cache current group ID before updating.
	ID = AdminData.AU[Index].AdminID;
	if( CheckAdminData() ){
		Index = AdminData.FindAdminUser(ID);
		if( Index==-1 )
		return;
	}
	
	AdminData.AU.Remove(Index,1);
	SaveAdminData();
}
final function WebUpdateUser( int Index, string PL, string GID, string PW, string UID, bool bAA )
{
	local UniqueNetID ID;
	
	// First cache current group ID before updating.
	ID = AdminData.AU[Index].AdminID;
	
	if( CheckAdminData() ){	
		Index = AdminData.FindAdminUser(ID);
		if( Index==-1 )
		return;
	}
	
	AdminData.AU[Index].PL = PL;
	AdminData.AU[Index].ID = Caps(GID);
	AdminData.AU[Index].PW = PW;
	AdminData.AU[Index].UID = UID;
	AdminData.AU[Index].NA = !bAA;
	SaveAdminData();
	
	// Update AdminID if needed.
	class'OnlineSubsystem'.Static.StringToUniqueNetId(AdminData.AU[Index].UID,ID);
	AdminData.AU[Index].AdminID = ID;
}
final function WebAddCommands()
{
	local int i,j;

	j = -1;
	CheckAdminData();
	for( i=0; i<class'AdminPlusCheats'.Default.CommandList.Length; ++i ){
		if( AdminData.AC.Find('CM',class'AdminPlusCheats'.Default.CommandList[i])==-1 ){
			j = AdminData.AC.Length;
			AdminData.AC.Length = j+1;
			AdminData.AC[j].CM = class'AdminPlusCheats'.Default.CommandList[i];
			AdminData.AC[j].CG = -1;
		}
	}
	if( j!=-1 )
	SaveAdminData();
}
final function WebUpdateCommand( int Index, string NewCmd, int NewIndex, string NewGroup )
{
	local name CM;
	local string GN;

	// First cache current group ID before updating.
	CM = AdminData.AC[Index].CM;
	if( NewIndex>=0 && NewIndex<AdminData.CG.Length )
	GN = AdminData.CG[NewIndex];

	if( CheckAdminData() ){
		// Verify if deleted/modified.
		Index = AdminData.AC.Find('CM',CM);
		if( Index==-1 )
		return;
		if( GN!="" ){
			NewIndex = AdminData.CG.Find(GN);
			if( NewIndex==-1 )
			return;
		}
	}
	
	if( GN=="" ){
		if( NewGroup=="" )
		return;
		GN = NewGroup;
		NewIndex = AdminData.CG.Find(GN);
		if( NewIndex==-1 )
		{
			NewIndex = AdminData.CG.Length;
			AdminData.CG.AddItem(GN);
		}
	}
	
	AdminData.AC[Index].CM = name(NewCmd);
	AdminData.AC[Index].CG = NewIndex;
	SaveAdminData();
}
final function WebDeleteCommand( int Index )
{
	local name CM;
	
	// First cache current group ID before updating.
	CM = AdminData.AC[Index].CM;
	if( CheckAdminData() ){
		Index = AdminData.AC.Find('CM',CM);
		if( Index==-1 )
		return;
	}
	
	AdminData.AC.Remove(Index,1);
	SaveAdminData();
}
final function WebDeleteBan( string WebUser, int Index )
{
	local string OldID;
	
	OldID = BansData.BE[Index].ID;
	if( CheckBanData() ){
		if( OldID!=BansData.BE[Index].ID ) // Bans were changed, ignore this.
		return;
	}
	
	BansData.AddLogLine(WebUser$" (WEB): Removed ban #"$BansData.BE[Index].IX$" ("$BansData.BE[Index].N$","$BansData.BE[Index].ID$"), expires in: "$BansData.WEBGetBanTimeStr(Index));
	BansData.BE.Remove(Index,1);
	SaveBanData();
}
final function WebEditBan( string WebUser, int Index, string N, string IP, string R, int T, string NT )
{
	local string OldID;
	
	OldID = BansData.BE[Index].ID;
	if( CheckBanData() ){
		if( OldID!=BansData.BE[Index].ID ) // Bans were changed, ignore this.
		return;
	}
	
	BansData.UpdateTempTime();
	BansData.AddLogLine(WebUser$" (WEB): Edit ban #"$BansData.BE[Index].IX$" (IP:"$BansData.BE[Index].IP$"->"$IP$", Time:"$BansData.WEBGetBanTime(Index)$"->"$T$"h)");
	BansData.BE[Index].N = N;
	BansData.BE[Index].IP = IP;
	BansData.BE[Index].R = R;
	BansData.SetBanTime(Index,T);
	BansData.BE[Index].NT = NT;
	SaveBanData();
}
////////////增加steamid输入////////////
final function int WebAddBan( string WebUser, string ID, string STID)
{
	local OnlineSubsystem steamwork;
	local UniqueNetId UID;
	local string PlayerID;
	local int i;

	    if(ID != "0x0000000000000000"&& STID == "BannedSteamID"){
	        CheckBanData();
	        BansData.AddLogLine(WebUser$" (WEB): Add NEW ban #"$BansData.BID@ID);

		    steamwork = class'GameEngine'.static.GetOnlineSubsystem();
			
	
	        i = BansData.BE.Length;
	        BansData.BE.Length = i+1;
	        BansData.BE[i].IX = BansData.BID++;
			BansData.BE[i].ID = ID;
			BansData.BE[i].STID = STID;


	        BansData.BE[i].IP = "0.0.0.0";
	        BansData.BE[i].N = "Player";
	        BansData.BE[i].R = "No reason given";
	        BansData.BE[i].T = -1;
	        BansData.BE[i].A = WebUser$" (WEB)";
	        SaveBanData();
	        return i;
	    }
		else if(ID == "0x0000000000000000"&& STID != "BannedSteamID"){
			CheckBanData();
	        BansData.AddLogLine(WebUser$" (WEB): Add NEW ban #"$BansData.BID@ID);

		    steamwork = class'GameEngine'.static.GetOnlineSubsystem();
			steamwork.Int64ToUniqueNetId(STID, UID);

			PlayerID = class'OnlineSubsystem'.Static.UniqueNetIdToString(UID);
	
	        i = BansData.BE.Length;
	        BansData.BE.Length = i+1;
	        BansData.BE[i].IX = BansData.BID++;
			BansData.BE[i].ID = PlayerID; //
			BansData.BE[i].STID = STID;


	        BansData.BE[i].IP = "0.0.0.0";
	        BansData.BE[i].N = "Player";
	        BansData.BE[i].R = "No reason given";
	        BansData.BE[i].T = -1;
	        BansData.BE[i].A = WebUser$" (WEB)";
	        SaveBanData();
	        return i;
		}
	
}
/* 
final function int WebAddBan( string WebUser, string ID )
{
	local int i;

	CheckBanData();
	BansData.AddLogLine(WebUser$" (WEB): Add NEW ban #"$BansData.BID@ID);
	
	i = BansData.BE.Length;
	BansData.BE.Length = i+1;
	BansData.BE[i].IX = BansData.BID++;
	BansData.BE[i].ID = ID;
	BansData.BE[i].IP = "0.0.0.0";
	BansData.BE[i].N = "Player";
	BansData.BE[i].R = "No reason given";
	BansData.BE[i].T = -1;
	BansData.BE[i].A = WebUser$" (WEB)";
	SaveBanData();
	return i;
}
*/

///////////////////////////
final function AddPlayerBan( string User, PlayerController P, optional string Reason, optional int Time=24 )
{
	local OnlineSubsystem steamwork;
	local string UID,UIP, PlayerSTID;
	local int i;

	if ( P.PlayerReplicationInfo.UniqueId==P.PlayerReplicationInfo.default.UniqueId )
	return;
	if( Reason=="" )
	Reason = "No reason given";
	
	steamwork = class'GameEngine'.static.GetOnlineSubsystem();
	if(steamwork != None)
		PlayerSTID = steamwork.UniqueNetIdToInt64(P.PlayerReplicationInfo.UniqueId);
	UID = class'OnlineSubsystem'.Static.UniqueNetIdToString(P.PlayerReplicationInfo.UniqueId);
	UIP = P.GetPlayerNetworkAddress();
	CheckBanData();
	
	i = BansData.BE.Find('ID',UID);
	if( i>=0 )
	return;
	if( Time==0 )
	Time = 1;
	WorldInfo.Game.Broadcast(Self,User$": Banned "$P.PlayerReplicationInfo.PlayerName$" for "$(Time<0 ? "forever" : Time$" hours")$", reason: "$Reason);
	BansData.AddLogLine(User$": Banned "$P.PlayerReplicationInfo.PlayerName$" (#"$BansData.BID@UID@PlayerSTID@UIP$") for "$Time$" hours, reason: "$Reason);
	i = BansData.BE.Length;
	BansData.BE.Length = i+1;
	BansData.BE[i].IX = BansData.BID++;
	BansData.BE[i].ID = UID;
	BansData.BE[i].STID = PlayerSTID;
	BansData.BE[i].IP = UIP;
	BansData.BE[i].N = P.PlayerReplicationInfo.PlayerName;
	BansData.BE[i].R = Reason;
	BansData.BE[i].A = User;
	BansData.SetBanTime(i,Time);
	SaveBanData();
}
/* 
final function AddPlayerBan( string User, PlayerController P, optional string Reason, optional int Time=24 )
{
	local string UID,UIP;
	local int i;

	if ( P.PlayerReplicationInfo.UniqueId==P.PlayerReplicationInfo.default.UniqueId )
	return;
	if( Reason=="" )
	Reason = "No reason given";
	UID = class'OnlineSubsystem'.Static.UniqueNetIdToString(P.PlayerReplicationInfo.UniqueId);
	UIP = P.GetPlayerNetworkAddress();
	CheckBanData();
	
	i = BansData.BE.Find('ID',UID);
	if( i>=0 )
	return;
	if( Time==0 )
	Time = 1;
	WorldInfo.Game.Broadcast(Self,User$": Banned "$P.PlayerReplicationInfo.PlayerName$" for "$(Time<0 ? "forever" : Time$" hours")$", reason: "$Reason);
	BansData.AddLogLine(User$": Banned "$P.PlayerReplicationInfo.PlayerName$" (#"$BansData.BID@UID@UIP$") for "$Time$" hours, reason: "$Reason);
	i = BansData.BE.Length;
	BansData.BE.Length = i+1;
	BansData.BE[i].IX = BansData.BID++;
	BansData.BE[i].ID = UID;
	BansData.BE[i].IP = UIP;
	BansData.BE[i].N = P.PlayerReplicationInfo.PlayerName;
	BansData.BE[i].R = Reason;
	BansData.BE[i].A = User;
	BansData.SetBanTime(i,Time);
	SaveBanData();
}
*/

function KickBan( string Target )
{
	local PlayerController P;

	P = PlayerController( GetControllerFromString(Target) );
	if ( NetConnection(P.Player) != None ){
		AddPlayerBan("Console",P);
		P.Destroy();
	}
}

function bool CheckIPPolicy(string Address)
{
	return true;
}

`if(`isdefined(SUPPORT_RESERVED_SLOTS))
function ClearReserved()
{
	local int i;
	
	for( i=(ReservedUsers.Length-1); i>=0; --i )
	if( ReservedUsers[i].TimeOut<WorldInfo.TimeSeconds )
	ReservedUsers.Remove(i,1);
	if( ReservedUsers.Length==0 )
	ClearTimer('ClearReserved');
}
`endif
event PreLogin(string Options, string Address, const UniqueNetId UniqueId, bool bSupportsAuth, out string OutError, bool bSpectator)
{
	local OnlineSubsystem steamwork;
	local string UID,InName,PlayerSTID;
	local int i,j;

	`if(`isdefined(SUPPORT_RESERVED_SLOTS))
	local bool bReserved;

	bReserved = false;
	if( !bNoReservedSlots )
	{
		if( AdminData.FindAdminUser(UniqueId)>=0 )
		{
			i = ReservedUsers.Find('Opt',Options);
			if( i==-1 )
			{
				i = ReservedUsers.Length;
				ReservedUsers.Length = i+1;
				ReservedUsers[i].Opt = Options;
			}
			ReservedUsers[i].TimeOut = WorldInfo.TimeSeconds+60.f;
			bReserved = true;
			OldMaxPL = WorldInfo.Game.MaxPlayers;
			OldMaxSpec = WorldInfo.Game.MaxSpectators;
			SetTimer(10,true,'ClearReserved');
			WorldInfo.Game.MaxPlayers = 999;
			WorldInfo.Game.MaxSpectators = 999;
		}
	}
	`endif

	Super.PreLogin(Options,Address,UniqueId,bSupportsAuth,OutError,bSpectator);
	`Log("PreLogin"@Options@Address@bSpectator@OutError);
	
	`if(`isdefined(SUPPORT_RESERVED_SLOTS))
	if( bReserved )
	{
		WorldInfo.Game.MaxPlayers = OldMaxPL;
		WorldInfo.Game.MaxSpectators = OldMaxSpec;
	}
	`endif
	
	InName = WorldInfo.Game.ParseOption( Options, "Name" );
	if( OutError=="" )
	{
	    steamwork = class'GameEngine'.static.GetOnlineSubsystem();/////
		PlayerSTID = steamwork.UniqueNetIdToInt64(UniqueId);

		UID = class'OnlineSubsystem'.Static.UniqueNetIdToString(UniqueId);
		
		i = BansData.BE.Find('ID',UID);
		if( i>=0 && BansData.CheckBanActive(i) )
		{
			msgBan:
			OutError = "You are banned (#"$BansData.BE[i].IX$", reason: '"$BansData.BE[i].R$"', ban duration: "$BansData.GetBanTimeStr(i)$")";
			if( class'KFGameInfo'.Default.WebsiteLink!="" )
			OutError $= ". Ban appeals at: "$class'KFGameInfo'.Default.WebsiteLink;
			AdminMessage(InName$" failed to login: "$OutError);
			return;
		}

		if( BansData.bDirty && !CheckBanData() )
		SaveBanData();

		i = InStr(Address,":");
		if( i>0 )
		Address = Left(Address,i);
		i = BansData.BE.Find('IP',Address);
		if( i>=0 )
		{
			j = BansData.BE[i].IX;
			if( CheckBanData() )
			{
				i = BansData.BE.Find('IP',Address);
				if( i==-1 )
				return; // Ban was actually removed.
			}
			BansData.AddLogLine("Console: Banned "$InName$" (#"$BansData.BID@UID@Address$") for forever, reason: Had an pre-excisting ban entry #"$j);
			i = BansData.BE.Length;
			BansData.BE.Length = i+1;
			BansData.BE[i].IX = BansData.BID++;
			BansData.BE[i].ID = UID;
			BansData.BE[i].STID = PlayerSTID;
			BansData.BE[i].IP = Address;
			BansData.BE[i].N = InName;
			BansData.BE[i].R = "Other ban entry #"$j;
			BansData.BE[i].A = "Console";
			BansData.SetBanTime(i,-1);
			SaveBanData();
			GoTo'MsgBan';
		}
		
		// Msg prelogin.
		WorldInfo.Game.Broadcast(Self,InName$" is connecting");
	}
	else AdminMessage(InName$" failed to login: "$OutError);
}
/* 
event PreLogin(string Options, string Address, const UniqueNetId UniqueId, bool bSupportsAuth, out string OutError, bool bSpectator)
{
	local string UID,InName;
	local int i,j;

	`if(`isdefined(SUPPORT_RESERVED_SLOTS))
	local bool bReserved;

	bReserved = false;
	if( !bNoReservedSlots ){
		if( AdminData.FindAdminUser(UniqueId)>=0 ){
			i = ReservedUsers.Find('Opt',Options);
			if( i==-1 ){
				i = ReservedUsers.Length;
				ReservedUsers.Length = i+1;
				ReservedUsers[i].Opt = Options;
			}
			ReservedUsers[i].TimeOut = WorldInfo.TimeSeconds+60.f;
			bReserved = true;
			OldMaxPL = WorldInfo.Game.MaxPlayers;
			OldMaxSpec = WorldInfo.Game.MaxSpectators;
			SetTimer(10,true,'ClearReserved');
			WorldInfo.Game.MaxPlayers = 999;
			WorldInfo.Game.MaxSpectators = 999;
		}
	}
	`endif

	Super.PreLogin(Options,Address,UniqueId,bSupportsAuth,OutError,bSpectator);
	`Log("PreLogin"@Options@Address@bSpectator@OutError);
	
	`if(`isdefined(SUPPORT_RESERVED_SLOTS))
	if( bReserved ){
		WorldInfo.Game.MaxPlayers = OldMaxPL;
		WorldInfo.Game.MaxSpectators = OldMaxSpec;
	}
	`endif
	
	InName = WorldInfo.Game.ParseOption( Options, "Name" );
	if( OutError=="" ){
		UID = class'OnlineSubsystem'.Static.UniqueNetIdToString(UniqueId);
		
		i = BansData.BE.Find('ID',UID);
		if( i>=0 && BansData.CheckBanActive(i) ){
			msgBan:
			OutError = "You are banned (#"$BansData.BE[i].IX$", reason: '"$BansData.BE[i].R$"', ban duration: "$BansData.GetBanTimeStr(i)$")";
			if( class'KFGameInfo'.Default.WebsiteLink!="" )
			OutError $= ". Ban appeals at: "$class'KFGameInfo'.Default.WebsiteLink;
			AdminMessage(InName$" failed to login: "$OutError);
			return;
		}

		if( BansData.bDirty && !CheckBanData() )
		SaveBanData();

		i = InStr(Address,":");
		if( i>0 )
		Address = Left(Address,i);
		i = BansData.BE.Find('IP',Address);
		if( i>=0 ){
			j = BansData.BE[i].IX;
			if( CheckBanData() ){
				i = BansData.BE.Find('IP',Address);
				if( i==-1 )
				return; // Ban was actually removed.
			}
			BansData.AddLogLine("Console: Banned "$InName$" (#"$BansData.BID@UID@Address$") for forever, reason: Had an pre-excisting ban entry #"$j);
			i = BansData.BE.Length;
			BansData.BE.Length = i+1;
			BansData.BE[i].IX = BansData.BID++;
			BansData.BE[i].ID = UID;
			BansData.BE[i].IP = Address;
			BansData.BE[i].N = InName;
			BansData.BE[i].R = "Other ban entry #"$j;
			BansData.BE[i].A = "Console";
			BansData.SetBanTime(i,-1);
			SaveBanData();
			GoTo'MsgBan';
		}
		
		// Msg prelogin.
		WorldInfo.Game.Broadcast(Self,InName$" is connecting");
	}
	else AdminMessage(InName$" failed to login: "$OutError);
}
*/
final function AdminMessage( string S )
{
	local PlayerController PC;
	
	S = "*ADMIN*: "$S;
	foreach WorldInfo.AllControllers(class'PlayerController',PC){
		if( Admin(PC)!=None )
		PC.ClientMessage(S);
		else if( PC.PlayerReplicationInfo!=None && PC.PlayerReplicationInfo.bAdmin )
		PC.ClientMessage(S,'Priority');
	}
}
function bool ParseAdminOptions( string Options )
{
	`if(`isdefined(SUPPORT_RESERVED_SLOTS))
	ReservedIndex = ReservedUsers.Find('Opt',Options);
	if( ReservedIndex>=0 ){
		OldMaxPL = WorldInfo.Game.MaxPlayers;
		OldMaxSpec = WorldInfo.Game.MaxSpectators;
		WorldInfo.Game.MaxPlayers = 999;
		WorldInfo.Game.MaxSpectators = 999;
	}
	`endif
	return false;
}

`if(`isdefined(SUPPORT_RESERVED_SLOTS))
function bool IsPendingAuth(UniqueNetId PlayerUID)
{
	if( ReservedIndex>=0 ){
		ReservedUsers.Remove(ReservedIndex,1);
		ReservedIndex = -1;
		WorldInfo.Game.MaxPlayers = OldMaxPL;
		WorldInfo.Game.MaxSpectators = OldMaxSpec;
	}
	return Super.IsPendingAuth(PlayerUID);
}
`endif

final function SetPlayerMute( PlayerController PC, bool bMute )
{
	local int i;

	if( bMute ){
		if( MutedPlayers.Find('Uid',PC.PlayerReplicationInfo.UniqueId.Uid)==-1 ){
			PC.ClientMessage("You have been muted from using chat.",'Priority');
			MutedPlayers.AddItem(PC.PlayerReplicationInfo.UniqueId);
		}
		if( MessageFilter==None ){
			MessageFilter = Spawn(class'AccessBroadcast');
			MessageFilter.AccessController = Self;
		}
	}
	else{
		i = MutedPlayers.Find('Uid',PC.PlayerReplicationInfo.UniqueId.Uid);
		if( i>=0 ){
			MutedPlayers.Remove(i,1);
			PC.ClientMessage("You have been unmuted from using chat.",'Priority');
		}
	}
}
final function SetPlayerVoiceMute( PlayerController PC, bool bMute )
{
	local int i;

	if( bMute ){
		if( VoiceMutedPlayers.Find('Uid',PC.PlayerReplicationInfo.UniqueId.Uid)==-1 ){
			PC.ClientMessage("You have been muted from using voice chat.",'Priority');
			VoiceMutedPlayers.AddItem(PC.PlayerReplicationInfo.UniqueId);
			FilterVoices(PC,true);
		}
		if( AccessMut==None ){
			AccessMut = Spawn(class'AccessMutator');
			if( AccessMut==None ){
				// Mutator was already present.
				foreach DynamicActors(class'AccessMutator',AccessMut)
				break;
			}
			if( AccessMut!=None )
			AccessMut.AccessController = Self;
		}
	}
	else{	
		i = VoiceMutedPlayers.Find('Uid',PC.PlayerReplicationInfo.UniqueId.Uid);
		if( i>=0 ){
			VoiceMutedPlayers.Remove(i,1);
			PC.ClientMessage("You have been unmuted from using voice chat.",'Priority');
			FilterVoices(PC,false);
		}
	}
}
final function FilterVoices( PlayerController PC, bool bMute )
{
	local KFPlayerController C;
	local UniqueNetId ZeroUniqueNetId;
	
	// Check all players
	foreach WorldInfo.AllControllers( class'KFPlayerController', C ){
		if( C!=PC && C.PlayerReplicationInfo != None && C.PlayerReplicationInfo.UniqueId!=ZeroUniqueNetId ){
			if( bMute ){
				PC.GameplayMutePlayer( C.PlayerReplicationInfo.UniqueId );
				C.GameplayMutePlayer( PC.PlayerReplicationInfo.UniqueId );
			}
			else{
				PC.GameplayUnmutePlayer( C.PlayerReplicationInfo.UniqueId );
				C.GameplayUnmutePlayer( PC.PlayerReplicationInfo.UniqueId );
			}
		}
	}
}
final function CheckMutedPlayers( PlayerController PC )
{
	local KFPlayerController C;
	local UniqueNetId ZeroUniqueNetId;

	if( VoiceMutedPlayers.Find('Uid',PC.PlayerReplicationInfo.UniqueId.Uid)>=0 ){
		// This player is muted.
		foreach WorldInfo.AllControllers( class'KFPlayerController', C ){
			if( C!=PC && C.PlayerReplicationInfo != None && C.PlayerReplicationInfo.UniqueId!=ZeroUniqueNetId ){
				PC.GameplayMutePlayer( C.PlayerReplicationInfo.UniqueId );
				C.GameplayMutePlayer( PC.PlayerReplicationInfo.UniqueId );
			}
		}
	}
	else{
		// See if other players are muted.
		foreach WorldInfo.AllControllers( class'KFPlayerController', C ){
			if( C!=PC && C.PlayerReplicationInfo != None && C.PlayerReplicationInfo.UniqueId!=ZeroUniqueNetId && VoiceMutedPlayers.Find('Uid',C.PlayerReplicationInfo.UniqueId.Uid)>=0 ){
				PC.GameplayMutePlayer( C.PlayerReplicationInfo.UniqueId );
				C.GameplayMutePlayer( PC.PlayerReplicationInfo.UniqueId );
			}
		}
	}
}

defaultproperties
{
	Components.Empty()
	`if(`isdefined(SUPPORT_RESERVED_SLOTS))
	ReservedIndex=-1
	`endif

	AdminLevels(0)="Global"
	AdminLevels(1)="Admin"
	AdminLevels(2)="Mod"
	AdminLevels(3)="TMem"
	AdminLevels(4)="VIP"
}
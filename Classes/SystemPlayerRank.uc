class SystemPlayerRank extends Object
	dependson(Types)
	config(YAS);

`include(Build.uci)
`include(Logger.uci)

var config string    Rank;
var config ColorRGBA TextColor;
var config Fields    ApplyColorToFields;

public static function InitConfig(int ConfigVersion){
	`callstack_static("InitConfig");
	
	switch (ConfigVersion){
		case 0:
			WriteSettings(DefaultSettings());
			
		case 1:	
				
		case 2147483647:
			StaticSaveConfig();
	}
}

public static function YASSettingsPlayer DefaultSettings(){
	local YASSettingsPlayer Settings;
	
	`callstack_static("DefaultSettings");
	
	return Settings;
}

public static function YASSettingsPlayer Settings(){
	local YASSettingsPlayer Settings;
	
	`callstack_static("Settings");
	
	Settings.Rank = default.Rank;
	Settings.TextColor = default.TextColor;
	Settings.ApplyColorToFields = default.ApplyColorToFields;
	
	return Settings;
}

public static function WriteSettings(YASSettingsPlayer Settings){
	`callstack_static("WriteSettings");
	
	default.Rank = Settings.Rank;
	default.TextColor = Settings.TextColor;
	default.ApplyColorToFields = Settings.ApplyColorToFields;
}

DefaultProperties
{
}
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <updater>

#define MAX_FILE_LEN 80
#define JOINSOUND_VERSION "1.0.1"
#define UPDATE_URL "https://bara.in/update/joinsound.txt"

new Handle:g_hJoinSoundEnable = INVALID_HANDLE;
new Handle:g_hJoinSoundPath = INVALID_HANDLE;
new Handle:g_hJoinSoundStart = INVALID_HANDLE;
new Handle:g_hJoinSoundStartCommand = INVALID_HANDLE;
new String:g_sJoinSoundStartCommand[32];
new Handle:g_hJoinSoundStop = INVALID_HANDLE;
new Handle:g_hJoinSoundStopCommand = INVALID_HANDLE;
new String:g_sJoinSoundStopCommand[32];
new Handle:g_hJoinSoundVolume = INVALID_HANDLE;
new String:g_hJoinSoundName[MAX_FILE_LEN];

new Handle:g_hAdminJoinSoundEnable = INVALID_HANDLE;
new Handle:g_hAdminJoinSoundChatEnable = INVALID_HANDLE;
new Handle:g_hAdminJoinSoundPath = INVALID_HANDLE;
new Handle:g_hAdminJoinSoundVolume = INVALID_HANDLE;
new String:g_hAdminJoinSoundName[MAX_FILE_LEN];


public Plugin:myinfo = 
{
	name = "Admin-/ Player-Joinsound",
	author = "Bara",
	description = "Plays a custom joinsound if admin or player joins the server",
	version = JOINSOUND_VERSION,
	url = "www.bara.in"
};

public OnPluginStart()
{
	CreateConVar("admin-joinsound_version", JOINSOUND_VERSION, "Joinsound", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	LoadTranslations("joinsound.phrases");

	AutoExecConfig_SetFile("plugin.joinsound");
	AutoExecConfig_SetCreateFile(true);
	
	g_hJoinSoundEnable = AutoExecConfig_CreateConVar("joinsound_enable", "1", "Enable joinsound?", _, true, 0.0, true, 1.0);
	g_hJoinSoundPath = AutoExecConfig_CreateConVar("joinsound_path", "newsongformyserver/joinsound.mp3", "Which file sould be played? Path after cstrike/sound/ (JoinSound)");
	g_hJoinSoundStart = AutoExecConfig_CreateConVar("joinsound_start", "1", "Should '!start'-feature be enabled?", _, true, 0.0, true, 1.0);
	g_hJoinSoundStartCommand = AutoExecConfig_CreateConVar("joinsound_start_command", "start", "Command for start function");
	g_hJoinSoundStop = AutoExecConfig_CreateConVar("joinsound_stop", "1", "Should '!stop'-feature be enabled?", _, true, 0.0, true, 1.0);
	g_hJoinSoundStopCommand = AutoExecConfig_CreateConVar("joinsound_stop_command", "stop", "Command for stop function");
	g_hJoinSoundVolume = AutoExecConfig_CreateConVar("joinsound_volume", "1.0", "Volume of joinsound (1 = default)");

	g_hAdminJoinSoundEnable = AutoExecConfig_CreateConVar("admin_joinsound_enable", "1", "Enable admin joinsound?", _, true, 0.0, true, 1.0);
	g_hAdminJoinSoundChatEnable = AutoExecConfig_CreateConVar("admin_chat_enable", "1", "Enable admin joinmessage?", _, true, 0.0, true, 1.0);
	g_hAdminJoinSoundPath = AutoExecConfig_CreateConVar("admin_joinsound_path", "newsongformyserver/admin_joinsound.mp3", "Which file sould be played? Path after cstrike/sound/ (AdminJoinSound)");
	g_hJoinSoundVolume = AutoExecConfig_CreateConVar("admin_joinsound_volume", "1.0", "Volume of admin joinsound (1 = default)");

	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();

	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnConfigsExecuted()
{
	if(GetConVarInt(g_hJoinSoundEnable))
	{
		GetConVarString(g_hJoinSoundPath, g_hJoinSoundName, MAX_FILE_LEN);
		decl String:buffer[MAX_FILE_LEN];
		PrecacheSound(g_hJoinSoundName, true);
		Format(buffer, sizeof(buffer), "sound/%s", g_hJoinSoundName);
		AddFileToDownloadsTable(buffer);
	}

	if(GetConVarInt(g_hAdminJoinSoundEnable))
	{
		GetConVarString(g_hAdminJoinSoundPath, g_hAdminJoinSoundName, MAX_FILE_LEN);
		decl String:AdminBuffer[MAX_FILE_LEN];
		PrecacheSound(g_hAdminJoinSoundName, true);
		Format(AdminBuffer, sizeof(AdminBuffer), "sound/%s", g_hAdminJoinSoundName);
		AddFileToDownloadsTable(AdminBuffer);
	}

	if(GetConVarInt(g_hJoinSoundStart))
	{
		decl String:sBuffer[32];

		GetConVarString(g_hJoinSoundStartCommand, g_sJoinSoundStartCommand, sizeof(g_sJoinSoundStartCommand));
		Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sJoinSoundStartCommand);

		RegConsoleCmd(sBuffer, Command_StartSound);
	}

	if(GetConVarInt(g_hJoinSoundStop))
	{
		decl String:sBuffer[32];

		GetConVarString(g_hJoinSoundStopCommand, g_sJoinSoundStopCommand, sizeof(g_sJoinSoundStopCommand));
		Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sJoinSoundStopCommand);

		RegConsoleCmd(sBuffer, Command_StopSound);
	}
}

public OnClientPostAdminCheck(client)
{
	if(GetConVarInt(g_hJoinSoundEnable))
	{
		if(IsClientValid(client))
		{
			EmitSoundToClient(client, g_hJoinSoundName, _, _, _, _, GetConVarFloat(g_hJoinSoundVolume));
			
			CreateTimer(5.0, Timer_Message, client);
		}
	}

	if(GetConVarInt(g_hAdminJoinSoundEnable))
	{
		if(IsClientValid(client) && GetUserAdmin(client) != INVALID_ADMIN_ID)
		{
			EmitSoundToAll(g_hAdminJoinSoundName, _, _, _, _, GetConVarFloat(g_hAdminJoinSoundVolume));
			
			if(GetConVarInt(g_hAdminJoinSoundChatEnable))
			{
				CPrintToChatAll("%t", "AdminJoin");
			}
		}
	}
}

public Action:Timer_Message(Handle:timer, any:client)
{
	CPrintToChat(client, "%t", "JoinStop", g_sJoinSoundStopCommand);
}

public Action:Command_StopSound(client, args)
{
	if(GetConVarInt(g_hJoinSoundEnable))
	{
		if(GetConVarInt(g_hJoinSoundStop))
		{
			if(IsClientValid(client))
			{
				StopSound(client, SNDCHAN_AUTO, g_hJoinSoundName);
			}
		}
	}
}

public Action:Command_StartSound(client, args)
{
	if(GetConVarInt(g_hJoinSoundEnable))
	{
		if(GetConVarInt(g_hJoinSoundStart))
		{
			if(IsClientValid(client))
			{
				EmitSoundToClient(client, g_hJoinSoundName, _, _, _, _, GetConVarFloat(g_hJoinSoundVolume));
				
				CreateTimer(5.0, Timer_Message, client);
			}
		}
	}
}

stock bool:IsClientValid(client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return true;
	}
	return false;
}
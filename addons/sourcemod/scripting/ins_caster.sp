/**
 * [INS] Caster Info
 *
 * This plugin is designed to output team & player data to the player casting a match.
 *
 * 0.4 = Updated XML/JSON output. Added convar for weapon output.
 * 0.3 = Rewrite to group team info
 * 0.2 = Players in team 2 (Sec) or team 3 (Ins) are denied access to the command.
 * 0.1 = Initial build. Basic testing
**/

/*
 * ToDo: 
 *	REST/SOAP/FTP transfers? (Impact?)
 * 	Make mod independant? (cstrike/ins/tf2 ..? )
 */

#include <sourcemod>
#include <sdktools>
#include <insurgency>

// Team arrays of players (client)
new Handle:g_Cst_Team2_Players;
new Handle:g_Cst_Team3_Players;

// Global handles for convars
new ConVar:g_Cst_Output;
new ConVar:g_Cst_Dest;
new ConVar:g_Cst_Filename;
new ConVar:g_Cst_Weapons;

new String:g_Cst_PlayerWeapons[128];
int g_Cst_Client = 0;

// Store [team]player info Key Value pairs
new Handle:g_Cst_KV_PlayerInfo;

public Plugin myinfo =
{
	name = "[INS] Caster Info",
	author = "GiZZoR",
	description = "Output team, player info in XML for Caster",
	version = "0.4",
	url = "https://github.com/GiZZoR/ins-sm-plugins"
};

public void OnPluginStart()
{
	// Initialize global arrays
	g_Cst_Team2_Players = CreateArray(16);
	g_Cst_Team3_Players = CreateArray(16);

	// Intialize player info
	g_Cst_KV_PlayerInfo = CreateKeyValues("PlayerInfo");

	// Console command
	RegConsoleCmd("sm_cast_run", Cst_CommandProc);

	// Output types
	g_Cst_Output = CreateConVar("sm_cast_type", "0", "0 - Plain Text; 1 - XML; 2 - JSON;", FCVAR_NONE, true, 0.0, true, 2.0);

	// Output destination
	g_Cst_Dest = CreateConVar("sm_cast_dest", "0", "0 - Console; 1 - File;", FCVAR_NONE, true, 0.0, true, 1.0);
	
	// Output destination
	g_Cst_Weapons = CreateConVar("sm_cast_weapons", "0", "0 - Don't display player weapons; 1 - Show player weapon data;", FCVAR_NONE, true, 0.0, true, 1.0);
	
	// [OPTIONAL] File name
	g_Cst_Filename = CreateConVar("sm_cast_filename", "sm_cast", "Specify filename (without extension) used if sm_cast_dest = 1", FCVAR_NONE);
}

public Action:Cst_Dispatch()
{
	g_Cst_KV_PlayerInfo = CreateKeyValues("PlayerInfo");
	int ArrayLength = 0;
	int TeamPlayer = 0;
	char SteamID[64];
	char Name[32];
	// Populate [team]PlayerInfo KV set.
	for(new Team = 2; Team <= 3; Team++)
	{
		// Loop through players in team
		
		if (Team == 2) ArrayLength = GetArraySize(g_Cst_Team2_Players);
		if (Team == 3) ArrayLength = GetArraySize(g_Cst_Team3_Players);
		for (new ArrayCell = 0; ArrayCell < ArrayLength; ArrayCell++)
		{

			if (Team == 2) TeamPlayer = GetArrayCell(g_Cst_Team2_Players,ArrayCell);
			if (Team == 3) TeamPlayer = GetArrayCell(g_Cst_Team3_Players,ArrayCell);

			// Get player SteamID
			GetClientAuthId(TeamPlayer, AuthId_Steam2, SteamID, sizeof(SteamID));
			GetClientName(TeamPlayer, Name, sizeof(Name));

			int Kills = GetClientFrags(TeamPlayer);
			int Deaths = GetClientDeaths(TeamPlayer);
			int Health = GetClientHealth(TeamPlayer);
			char strKills[4];
			char strDeaths[4];
			char strHealth[4];
			IntToString(Kills, strKills, sizeof(strKills));
			IntToString(Deaths, strDeaths, sizeof(strDeaths));
			IntToString(Health, strHealth, sizeof(strHealth));

			if (g_Cst_Weapons.IntValue == 1) Cst_GetPlayerWeapons(TeamPlayer);
			// Jump to key in KeyValue pair, and do not create
			if (strcmp(SteamID,"BOT",false) == 0)
			{
				GetClientName(TeamPlayer,SteamID,sizeof(SteamID));
			}
			if (KvJumpToKey(g_Cst_KV_PlayerInfo,SteamID,true))
			{
				KvSetString(g_Cst_KV_PlayerInfo,"name", Name);
				KvSetString(g_Cst_KV_PlayerInfo,"kills", strKills);
				KvSetString(g_Cst_KV_PlayerInfo,"deaths", strDeaths);
				KvSetString(g_Cst_KV_PlayerInfo,"health", strHealth);
				KvSetString(g_Cst_KV_PlayerInfo,"weapons",g_Cst_PlayerWeapons);
			}
			KvRewind(g_Cst_KV_PlayerInfo);
		}
	}
	Cst_ProcessResults();
	return Plugin_Handled;
}

public Action:Cst_ProcessResults()
{
	new Handle:FileHandle = INVALID_HANDLE;
	int ArrayLength = 0;
	char TeamName[16];
	int TeamPlayer = 0;
	char SteamID[64];
	// Output to file!
	if (g_Cst_Dest.IntValue == 1)
	{
		// Setup file handle
		new String:path[PLATFORM_MAX_PATH];
		new String:filename[64];
		GetConVarString(g_Cst_Filename, filename, sizeof(filename));
		if (g_Cst_Output.IntValue == 0) StrCat(filename, sizeof(filename), ".txt");
		if (g_Cst_Output.IntValue == 1) StrCat(filename, sizeof(filename), ".xml");
		if (g_Cst_Output.IntValue == 2) StrCat(filename, sizeof(filename), ".json");
		BuildPath(Path_SM,path,PLATFORM_MAX_PATH,filename);
		FileHandle = OpenFile(path,"w");
	}
	
	// Output Type = Plain Text
	if (g_Cst_Output.IntValue == 0)
	{
		for(new Team = 2; Team <= 3; Team++)
		{
			// Team Name
			GetTeamName(Team,TeamName,sizeof(TeamName));
			// Team score
			new TeamRoundWins = GetEntProp(GetTeamEntity(Team), Prop_Send, "m_iRoundsWon");

			// Output Destination = Console
			if (g_Cst_Dest.IntValue == 0) ReplyToCommand(g_Cst_Client,"%s Wins: %i",TeamName,TeamRoundWins);
			// Output Destination = File
			if (g_Cst_Dest.IntValue == 1) WriteFileLine(FileHandle,"%s Wins: %i",TeamName,TeamRoundWins);

			if (Team == 2) ArrayLength = GetArraySize(g_Cst_Team2_Players);
			if (Team == 3) ArrayLength = GetArraySize(g_Cst_Team3_Players);
			for (new ArrayCell = 0; ArrayCell < ArrayLength; ArrayCell++)
			{
				if (Team == 2) TeamPlayer = GetArrayCell(g_Cst_Team2_Players,ArrayCell);
				if (Team == 3) TeamPlayer = GetArrayCell(g_Cst_Team3_Players,ArrayCell);
				
				GetClientAuthId(TeamPlayer, AuthId_Steam2, SteamID, sizeof(SteamID));
				new String:KVname[32];new String:KVkills[32];new String:KVdeaths[32];new String:KVhealth[32];new String:KVweapons[64];
				if (strcmp(SteamID,"BOT",false) == 0)
				{
					GetClientName(TeamPlayer,SteamID,sizeof(SteamID));
				}
				if (KvJumpToKey(g_Cst_KV_PlayerInfo,SteamID,false))
				{
					KvGetString(g_Cst_KV_PlayerInfo, "name", KVname, sizeof(KVname), "");
					KvGetString(g_Cst_KV_PlayerInfo, "kills", KVkills, sizeof(KVkills), "");
					KvGetString(g_Cst_KV_PlayerInfo, "deaths", KVdeaths, sizeof(KVdeaths), "");
					KvGetString(g_Cst_KV_PlayerInfo, "health", KVhealth, sizeof(KVhealth), "");
					if (g_Cst_Weapons.IntValue == 1) KvGetString(g_Cst_KV_PlayerInfo, "weapons", KVweapons, sizeof(KVweapons), "");
					
					// Output Destination = Console
					if (g_Cst_Dest.IntValue == 0) ReplyToCommand(g_Cst_Client,"%s %s %s %s %s %s", KVname, SteamID, KVkills, KVdeaths, KVhealth, KVweapons);
					// Output Destination = File
					if (g_Cst_Dest.IntValue == 1) WriteFileLine(FileHandle,"%s %s %s %s %s %s", KVname, SteamID, KVkills, KVdeaths, KVhealth, KVweapons);
				}
				KvRewind(g_Cst_KV_PlayerInfo);
			}
		}
		if (g_Cst_Dest.IntValue == 1) CloseHandle(FileHandle);
		return Plugin_Handled;
	}
	
	// Output Type = XML
	if (g_Cst_Output.IntValue == 1)
	{
		if (g_Cst_Dest.IntValue == 1)
		{
			WriteFileLine(FileHandle,"<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
			WriteFileLine(FileHandle,"<root>");
		}
		if (g_Cst_Dest.IntValue == 0)
		{
			ReplyToCommand(g_Cst_Client,"<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
			ReplyToCommand(g_Cst_Client,"<root>");
		}		
		for(new Team = 2; Team <= 3; Team++)
		{
			// Team Name
			GetTeamName(Team,TeamName,sizeof(TeamName));
			// Team score
			new TeamRoundWins = GetEntProp(GetTeamEntity(Team), Prop_Send, "m_iRoundsWon");

			// Output Destination = Console
			if (g_Cst_Dest.IntValue == 0) ReplyToCommand(g_Cst_Client,"\t<team><id>%i</id><name>%s</name><wins>%i</wins>",Team,TeamName,TeamRoundWins);
			// Output Destination = File
			if (g_Cst_Dest.IntValue == 1) WriteFileLine(FileHandle,"\t<team><id>%i</id><name>%s</name><wins>%i</wins>",Team,TeamName,TeamRoundWins);

			if (Team == 2) ArrayLength = GetArraySize(g_Cst_Team2_Players);
			if (Team == 3) ArrayLength = GetArraySize(g_Cst_Team3_Players);
			for (new ArrayCell = 0; ArrayCell < ArrayLength; ArrayCell++)
			{
				if (Team == 2) TeamPlayer = GetArrayCell(g_Cst_Team2_Players,ArrayCell);
				if (Team == 3) TeamPlayer = GetArrayCell(g_Cst_Team3_Players,ArrayCell);
				GetClientAuthId(TeamPlayer, AuthId_Steam2, SteamID, sizeof(SteamID));
				new String:KVname[32];new String:KVkills[32];new String:KVdeaths[32];new String:KVhealth[32];new String:KVweapons[64];
				if (strcmp(SteamID,"BOT",false) == 0)
				{
					GetClientName(TeamPlayer,SteamID,sizeof(SteamID));
				}
				if (KvJumpToKey(g_Cst_KV_PlayerInfo,SteamID,false))
				{
					KvGetString(g_Cst_KV_PlayerInfo, "name", KVname, sizeof(KVname), "");
					KvGetString(g_Cst_KV_PlayerInfo, "kills", KVkills, sizeof(KVkills), "");
					KvGetString(g_Cst_KV_PlayerInfo, "deaths", KVdeaths, sizeof(KVdeaths), "");
					KvGetString(g_Cst_KV_PlayerInfo, "health", KVhealth, sizeof(KVhealth), "");
					if (g_Cst_Weapons.IntValue == 1) KvGetString(g_Cst_KV_PlayerInfo, "weapons", KVweapons, sizeof(KVweapons), "");
					
					// Output Destination = Console
					new String:Reply[255];
					if (g_Cst_Weapons.IntValue == 1)
					{ 
						Format(Reply,sizeof(Reply), "\t\t<player><name>%s</name><steamid>%s</steamid><kills>%s</kills><deaths>%s</deaths><health>%s</health><weapons>%s</weapons></player>", KVname, SteamID, KVkills, KVdeaths, KVhealth,KVweapons);
					}
					else 
					{ 
						Format(Reply,sizeof(Reply), "\t\t<player><name>%s</name><steamid>%s</steamid><kills>%s</kills><deaths>%s</deaths><health>%s</health></player>", KVname, SteamID, KVkills, KVdeaths, KVhealth); }
					if (g_Cst_Dest.IntValue == 0) ReplyToCommand(g_Cst_Client,Reply);
					if (g_Cst_Dest.IntValue == 1) WriteFileLine(FileHandle,Reply);
				}
				KvRewind(g_Cst_KV_PlayerInfo);
			}
			if (g_Cst_Dest.IntValue == 0) ReplyToCommand(g_Cst_Client,"\t</team>");
			if (g_Cst_Dest.IntValue == 1) WriteFileLine(FileHandle,"\t</team>");
		}
		if (g_Cst_Dest.IntValue == 0)
		{
			ReplyToCommand(g_Cst_Client,"</root>");
		}
		if (g_Cst_Dest.IntValue == 1)
		{
			WriteFileLine(FileHandle,"</root>");
			CloseHandle(FileHandle);
		}
		return Plugin_Handled;
	}


	//Output type = JSON
	if (g_Cst_Output.IntValue == 2)
	{
		if (g_Cst_Dest.IntValue == 0) ReplyToCommand(g_Cst_Client,"{'teams':[");
		for(new Team = 2; Team <= 3; Team++)
		{
			// Team Name
			GetTeamName(Team,TeamName,sizeof(TeamName));
			// Team score
			new TeamRoundWins = GetEntProp(GetTeamEntity(Team), Prop_Send, "m_iRoundsWon");

			// Output Destination = Console
			if (g_Cst_Dest.IntValue == 0) ReplyToCommand(g_Cst_Client,"{'team':'%s','wins':'%i','players':[{",TeamName,TeamRoundWins);
			// Output Destination = File
			if (g_Cst_Dest.IntValue == 1) WriteFileLine(FileHandle,"{'team':'%s','wins':'%i'",TeamName,TeamRoundWins);

			if (Team == 2) ArrayLength = GetArraySize(g_Cst_Team2_Players);
			if (Team == 3) ArrayLength = GetArraySize(g_Cst_Team3_Players);
			for (new ArrayCell = 0; ArrayCell < ArrayLength; ArrayCell++)
			{
				if (Team == 2) TeamPlayer = GetArrayCell(g_Cst_Team2_Players,ArrayCell);
				if (Team == 3) TeamPlayer = GetArrayCell(g_Cst_Team3_Players,ArrayCell);
				GetClientAuthId(TeamPlayer, AuthId_Steam2, SteamID, sizeof(SteamID));
				new String:KVname[32];new String:KVkills[32];new String:KVdeaths[32];new String:KVhealth[32];new String:KVweapons[64];
				if (strcmp(SteamID,"BOT",false) == 0)
				{
					GetClientName(TeamPlayer,SteamID,sizeof(SteamID));
				}
				if (KvJumpToKey(g_Cst_KV_PlayerInfo,SteamID,false))
				{
					KvGetString(g_Cst_KV_PlayerInfo, "name", KVname, sizeof(KVname), "");
					KvGetString(g_Cst_KV_PlayerInfo, "kills", KVkills, sizeof(KVkills), "");
					KvGetString(g_Cst_KV_PlayerInfo, "deaths", KVdeaths, sizeof(KVdeaths), "");
					KvGetString(g_Cst_KV_PlayerInfo, "health", KVhealth, sizeof(KVhealth), "");
					if (g_Cst_Weapons.IntValue == 1) KvGetString(g_Cst_KV_PlayerInfo, "weapons", KVweapons, sizeof(KVweapons), "");
					
					char Message[256];
					if (g_Cst_Weapons.IntValue == 1)
					{
						// Output Destination = Console
						if (ArrayCell == (ArrayLength-1)) {
							Format(Message,sizeof(Message),"'player':[{'name':'%s','steamid':'%s','kills':'%s','deaths':'%s','health':'%s','weapons':'%s'}]", KVname, SteamID, KVkills, KVdeaths, KVhealth, KVweapons);
						} else {
							Format(Message,sizeof(Message),"'player':[{'name':'%s','steamid':'%s','kills':'%s','deaths':'%s','health':'%s','weapons':'%s'}],", KVname, SteamID, KVkills, KVdeaths, KVhealth, KVweapons);
						}
					}
					else
					{
					// Output Destination = Console
						if (ArrayCell == (ArrayLength-1)) {
							Format(Message,sizeof(Message),"'player':[{'name':'%s','steamid':'%s','kills':'%s','deaths':'%s','health':'%s'}]", KVname, SteamID, KVkills, KVdeaths, KVhealth);
						} else {
							Format(Message,sizeof(Message),"'player':[{'name':'%s','steamid':'%s','kills':'%s','deaths':'%s','health':'%s'}],", KVname, SteamID, KVkills, KVdeaths, KVhealth);
						}
					}
					if (g_Cst_Dest.IntValue == 0) ReplyToCommand(g_Cst_Client,"%s",Message);
					if (g_Cst_Dest.IntValue == 1) WriteFileLine(FileHandle,"%s",Message);						
				}
				KvRewind(g_Cst_KV_PlayerInfo)
			}
			if (g_Cst_Dest.IntValue == 0) ReplyToCommand(g_Cst_Client,"}]}");
			if (g_Cst_Dest.IntValue == 1) WriteFileLine(FileHandle,"}]}");
		}
		if (g_Cst_Dest.IntValue == 1) CloseHandle(FileHandle);
		if (g_Cst_Dest.IntValue == 0) ReplyToCommand(g_Cst_Client,"]}");
		return Plugin_Handled;
	}
	return Plugin_Handled
}

Cst_GetPlayerWeapons(client)
{
	g_Cst_PlayerWeapons = "";
	new m_hMyWeapons = FindSendPropOffs("CINSPlayer", "m_hMyWeapons");
	new String:WeaponName[32];
	new String:OldPlayerWeapons[128];
	for(new w = 0, weapon; w < 47; w += 4)
	{
		strcopy(OldPlayerWeapons, sizeof(OldPlayerWeapons), g_Cst_PlayerWeapons);
		weapon = GetEntDataEnt2(client, m_hMyWeapons + w);
		if(weapon > 0 && IsValidEdict(weapon))
		{
			GetEdictClassname(weapon, WeaponName, sizeof(WeaponName));
			// Ignore knife
			if (strcmp(WeaponName,"weapon_kabar",false) != 0)
			{
				ReplaceString(WeaponName, sizeof(WeaponName), "weapon_", "", false);
				Format(g_Cst_PlayerWeapons, sizeof(g_Cst_PlayerWeapons),"%s[%s]", OldPlayerWeapons, WeaponName);
			}
		}
	}
}

public Action:Cst_CommandProc(client, args)
{
	if (client != 0)
	{
		int CmdTeam = GetClientTeam(client);
		if (CmdTeam == 2 || CmdTeam == 3)
		{
			ReplyToCommand(client,"[SM] Access Denied.");
			return Plugin_Handled;
		}
	}
	ClearArray(g_Cst_Team2_Players);
	ClearArray(g_Cst_Team3_Players);
	for (new Player = 1; Player <= MaxClients; Player++)
	{
		if(IsClientInGame(Player)) 
		{
			// Ensure values are not inherited from previous client
			int Team = GetClientTeam(Player);
			if (Team == 2) PushArrayCell(g_Cst_Team2_Players,Player);
			if (Team == 3) PushArrayCell(g_Cst_Team3_Players,Player);
		}
	}
	g_Cst_Client = client;
	return Cst_Dispatch();
}

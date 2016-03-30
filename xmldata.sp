/**
 * 0.1 = Initial build
*/

#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
        name = "[INS] XML Data",
        author = "GiZZoR",
        description = "XML Server Data",
        version = "0.1",
        url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
        RegServerCmd("xml_write", Write_XML);
        RegServerCmd("ent_debug", Ent_Loop_Find);
}

public Action Ent_Loop_Find(int args)
{
        decl String:className[35];
        for (new i = 1; i <= MaxClients; i++) {
                if (IsClientConnected(i)) {
                        GetEntityClassname(i, className, sizeof(className));
                        PrintToServer("%s",className);
                }
        }
}

public Action Write_XML(int args)
{
        // Prep variables
        new String:path[PLATFORM_MAX_PATH];
        char SteamID[64];
        char Name[128];
        char MapName[64];
        char ServerName[256];
        new String:sGameMode[32];

        // Open file handle
        BuildPath(Path_SM,path,PLATFORM_MAX_PATH,"server-data.xml");
        new Handle:FileHandle = OpenFile(path,"w");

        new Handle:hHostName = FindConVar("hostname");
        GetConVarString(hHostName, ServerName, sizeof(ServerName));
//ins_bot_difficulty
        GetCurrentMap(MapName, sizeof(MapName));

        GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));

        WriteFileLine(FileHandle,"<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
        WriteFileLine(FileHandle,"<root>");
        WriteFileLine(FileHandle,"\t<servername>%s</servername>",ServerName);
        WriteFileLine(FileHandle,"\t<map>\n\t\t<name>%s</name>\n\t\t<mode>%s</mode>\n\t</map>",MapName,sGameMode);
        WriteFileLine(FileHandle,"\t<players>");
        for (new i = 1; i <= MaxClients; i++) {
                if (IsClientConnected(i)) {
                        GetClientName(i, Name, sizeof(Name));
                        GetClientAuthId(i, AuthId_Steam2, SteamID, sizeof(SteamID));
                        WriteFileLine(FileHandle,"\t\t<player>\n\t\t\t<name>%s</name>\n\t\t\t<steamid>%s</steamid>\n\t\t</player>",Name,SteamID);
                }
        }
        WriteFileLine(FileHandle,"\t</players>");
        WriteFileLine(FileHandle,"</root>");
        CloseHandle(FileHandle);
}

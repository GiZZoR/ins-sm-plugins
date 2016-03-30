/**
 * 0.3 = Add SQL. Death = Hook post.
 * 0.2 = Fixed removing unconnected players from array
 * 0.1a = Added test for suicides
*/

#include <sourcemod>

new Handle:g_knPlayers;
new Handle:g_knSQLPlayers;
new Handle:hDatabase = INVALID_HANDLE;

public Plugin myinfo =
{
        name = "[INS] Kill Notice",
        author = "GiZZoR",
        description = "Basic kill messages",
        version = "0.3",
        url = "https://github.com/GiZZoR/ins-sm-plugins"
};

public void OnPluginStart()
{
        AddCommandListener(kn_block_commands, "say");
        AddCommandListener(kn_block_commands, "say_team");
        HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
        HookEvent("player_team", Event_PlayerConnect, EventHookMode_Post);
        g_knPlayers = CreateArray(32);
        g_knSQLPlayers = CreateArray(32);
        StartSQL();
}

public void OnMapStart()
{
        ClearArray(g_knPlayers);
        ClearArray(g_knSQLPlayers);
}

public Action:kn_block_commands(client, const String:command[], args)
{
        bool Active;
        Active = false;
        char name[MAX_NAME_LENGTH];
        char messagetext[32];
        GetClientName(client, name, sizeof(name));
        char message[64];
        GetCmdArg(1, message, sizeof(message));
        if (strcmp(message,"!on",false) == 0) {
                Active = true;
                bool KNAdd;
                KNAdd = AddPlayer(client);
                if (KNAdd == true) {
                                messagetext = "Kill Messages: Enabled";
                } else {
                                messagetext = "Kill Messages: Already Enabled";
                }
        }
        if (strcmp(message,"!off",false) == 0) {
                Active = true;
                bool KNRemove;
                KNRemove = RemovePlayer(client);
                if (KNRemove == true) {
                                messagetext = "Kill Messages: Disabled";
                } else {
                                messagetext = "Kill Messages: Already Disabled";
                }
        }
        if (Active == true) {
                PrintToChat(client,messagetext);
        }
        return Plugin_Continue;
}

bool AddPlayer(player)
{
        if(FindValueInArray(g_knPlayers, player) != -1) {
                return false;
        } else {
                PushArrayCell(g_knPlayers,player);
                char SteamID[64];
                GetClientAuthId(player, AuthId_Steam2, SteamID, sizeof(SteamID));
                new String:query[1024];
                if(FindValueInArray(g_knSQLPlayers, player) == -1) {
                        Format(query, sizeof(query), "INSERT INTO users (steamid, enabled) VALUS ('%s',true)",SteamID);
                } else {
                        Format(query, sizeof(query), "UPDATE users SET enabled = true WHERE steamid = '%s'",SteamID);
                }
                SQL_FastQuery(hDatabase, query);
                return true;
        }
}

bool RemovePlayer(player)
{
        int ArrayPos;
        ArrayPos = FindValueInArray(g_knPlayers, player);
        if(ArrayPos != -1) {
                RemoveFromArray(g_knPlayers,ArrayPos);
                char SteamID[64];
                GetClientAuthId(player, AuthId_Steam2, SteamID, sizeof(SteamID));
                new String:query[1024];
                Format(query, sizeof(query), "UPDATE users SET enabled = false WHERE steamid = '%s'",SteamID);
                return true;
        } else {
                return false;
        }
}

void IsPlayerEnabledInDb(player)
{
        char SteamID[64];
        GetClientAuthId(player, AuthId_Steam2, SteamID, sizeof(SteamID));
        new String:query[1024];
        Format(query, sizeof(query), "SELECT '%i' AS client, enabled FROM users WHERE steamid = '%s'",player,SteamID);
        SQL_TQuery(hDatabase, SQL_CheckCallback, query);
}

public SQL_CheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
        if(SQL_GetRowCount(hndl) == 1)
        {
                if (SQL_FetchRow(hndl))
                {
                        new client = SQL_FetchInt(hndl,0);
                        new enabled = SQL_FetchInt(hndl,1);
                        if (enabled == 1) AddPlayer(client);
                        PushArrayCell(g_knSQLPlayers,client);
                }
        }
}

public Action:Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
        new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
        new victim = GetClientOfUserId(GetEventInt(event, "userid"));
        new String:attnick[32];
        new String:vicnick[32];
        new String: weapon[64];
        GetClientName(attacker,attnick,sizeof(attnick));
        GetClientName(victim,vicnick,sizeof(vicnick));
        GetEventString(event, "weapon", weapon, sizeof(weapon));
        int recipient;
        for(new i=0; i < GetArraySize(g_knPlayers); i++)
        {
                recipient = GetArrayCell(g_knPlayers,i);
                if(IsClientInGame(recipient)) {
                        if (victim == attacker) {
                                PrintToChat(recipient,"%s commited suicide with %s",attnick,weapon);
                        } else {
                                PrintToChat(recipient,"%s killed %s with %s",attnick,vicnick,weapon);
                        }
                } else {
                        RemovePlayer(recipient);
                }
        }
        return Plugin_Continue;
}

public Action:Event_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast) {
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        if (client == 0) return Plugin_Continue;
        char SteamID[64];
        GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
        if (StrEqual(SteamID,"BOT",false) == false) {
                IsPlayerEnabledInDb(client);
        }
        return Plugin_Continue;
}

public StartSQL()
{
    SQL_TConnect(GotDatabase,"killnotice");
}

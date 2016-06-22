#include <sourcemod>

ConVar g_cvBotDiff;

public Plugin myinfo =
{
        name = "[INS] Basic Intel",
        author = "GiZZoR",
        description = "Basic bot counter (alive/dead) for co-op play",
        version = "0.3",
        url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
        AddCommandListener(intel_block_commands, "say");
        g_cvBotDiff = FindConVar("ins_bot_difficulty");
}

public Action:intel_block_commands(client, const String:command[], args)
{
        char name[MAX_NAME_LENGTH];
        GetClientName(client, name, sizeof(name));
        char message[64];
        GetCmdArg(1, message, sizeof(message));
        int clientTeam;
        clientTeam = GetClientTeam(client);
        if (strcmp(message,"!intel",false) == 0) {
                new diff_int =  GetConVarInt(g_cvBotDiff);
                char diff_text[32];
                if (diff_int == 0) diff_text = "Forgiving";
                if (diff_int == 1) diff_text = "Normal";
                if (diff_int == 2) diff_text = "Unforgiving";
                if (diff_int == 3) diff_text = "Brutal";
                int BotCount; int BotAlive; int Team;
                for (new i = 1; i <= MaxClients; i++)
                {
                        if (IsClientInGame(i)) {
                                Team = GetClientTeam(i);
                                if (Team != clientTeam) {
                                        BotCount++;
                                        if (IsPlayerAlive(i)) BotAlive++;
                                }
                        }
                }
                PrintToChat(client,"AI Difficulty: %s", diff_text);
                if (BotAlive == 0) {
                        PrintToChat(client,"Intel: Recon shows that all %d of the enemy are dead.",BotCount);
                } else {
                        if (BotAlive == 1) {
                                PrintToChat(client,"Intel: Excercise caution soldier, %d of the %d enemy is still alive",BotAlive,BotCount);
                        } else {
                                PrintToChat(client,"Intel: Excercise caution soldier, %d of the %d enemy are still alive",BotAlive,BotCount);
                        }
                }
                return Plugin_Stop;
        }
        return Plugin_Continue;
}

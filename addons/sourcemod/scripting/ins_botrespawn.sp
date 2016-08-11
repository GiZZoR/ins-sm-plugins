/*
  Source from https://forums.alliedmods.net/showthread.php?p=1777154 [CSS/CSP/CSGO/TF2] Autorespawn [1.4 10/November/2013] by shavit
  Rewritten by GiZZoR for Insurgency
  Using library functions created by Jared Ballou
*/

#include <sourcemod>
#include <sdktools>
#include <insurgency>

#define PLUGIN_VERSION "0.1"

new Handle:gH_Enabled = INVALID_HANDLE;
new Handle:gH_Time = INVALID_HANDLE;
new Handle:gH_Timer = INVALID_HANDLE;
new Handle:gH_GameConfig = INVALID_HANDLE;
new Handle:gH_PlayerRespawn;
new bool:gB_Enabled;
new Float:gF_Time;

public Plugin:myinfo = 
{
	name = "[INS] Bot Respawn",
	author = "GiZZoR",
	description = "Timed respawn of bots",
	version = PLUGIN_VERSION
}

public OnPluginStart()
{
	CreateConVar("sm_bot_respawn_version", PLUGIN_VERSION, "[INS] Bot Respawn version", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_DONTRECORD);
	
	gH_Enabled = CreateConVar("sm_bot_respawn_enabled", "1", "Bot Respawn enabled?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Time = CreateConVar("sm_bot_respawn_time", "60.0", "Time to wait before respawning bots.", FCVAR_PLUGIN, true, 0.0, true, 240.0);
	
	gB_Enabled = GetConVarBool(gH_Enabled);
	gF_Time = GetConVarFloat(gH_Time);
	
	HookConVarChange(gH_Enabled, ConVarChanged);
	HookConVarChange(gH_Time, ConVarChanged);
	
	HookEvent("round_start", HookStart);
	HookEvent("round_end", HookEnd);
	HookEvent("object_destroyed", HookObjectDestroyed, EventHookMode_Post);
	HookEvent("controlpoint_captured", HookControlPointCaptured, EventHookMode_Post);

	
	gH_GameConfig = LoadGameConfigFile("plugin.respawn");
	if (gH_GameConfig == INVALID_HANDLE) {
		SetFailState("Fatal Error: Missing File \"plugin.respawn\"!");
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gH_GameConfig, SDKConf_Signature, "ForceRespawn");
	
	gH_PlayerRespawn = EndPrepSDKCall();
	if (gH_PlayerRespawn == INVALID_HANDLE)
	{
		SetFailState("Fatal Error: Unable to find signature for \"Respawn\"!");
	}
}

public Action:HookStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(gB_Enabled)
	{
		gH_Timer = CreateTimer(gF_Time, Respawn, _,TIMER_REPEAT);
	}
}

public Action:HookObjectDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(gB_Enabled)
	{
		KillTimer(gH_Timer);
		RespawnAll(true);
		gH_Timer = CreateTimer(gF_Time, Respawn, _,TIMER_REPEAT);
	}
}

public Action:HookControlPointCaptured(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(gB_Enabled)
	{
		KillTimer(gH_Timer);
		RespawnAll(true);
		gH_Timer = CreateTimer(gF_Time, Respawn, _,TIMER_REPEAT);
	}
}

public Action:HookEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(gB_Enabled)
	{
		KillTimer(gH_Timer);
	}
}

public Action:Respawn(Handle:Timer)
{
	RespawnAll(false);
	return Plugin_Continue;
}

public ConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == gH_Enabled)
	{
		gB_Enabled = StringToInt(newVal)? true:false;
	}
	else if(cvar == gH_Time)
	{
		gF_Time = StringToFloat(newVal);
	}
}

RespawnAll(bool:All = false)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i)) {
			{
				if(IsFakeClient(i))
				{
					if(All) 
					{
						SDKCall(gH_PlayerRespawn, i);
					}
					else if(!IsPlayerAlive(i)) SDKCall(gH_PlayerRespawn, i);
				}
			}
		}
	}
}
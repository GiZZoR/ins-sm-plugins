# Sourcemod plugins for Insurgency (Standalone)

## [INS] Supply Manager
This plugin will set the supply points (tokens) for players on connect to server.
Will determine and give highest possible supply to player, based on settings completed.
 
###Changelog
* 0.2 = "ALPHA" Added Join and Rejoin cvars
* 0.1 = Initial build. CVar and Token testing

###CVARS
```
sm_supply_enabled
"Boolean": Enable/disable plugin. Default: 1 (Enabled)

sm_supply_base
"Int": Number of supply points to give players. Default: 12

sm_supply_restore
"Boolean": Enable/disable restoring player's gained supply points. Default: 1 (Enabled)

sm_supply_join
"Int": Enable/disable setting supply points for new players. Default: 0 (Disabled)
Options:
0 - Disabled (Default)
1 - Give new player base supply as set in sm_supply_base. Note: You may want to set this per game mode in server_<mode>.cfg 
2 - Give new player the same supply as lowest member in team (Useful for multiple rounds of coop play)
3 - Give new player the team average of supply points (sum all players supply points divided by players)
```
## [INS] Basic Intel
Very simple plugin intended for coop, to report remaining bot count, and bot difficulty.

###Changelog
* 0.3 - Added bot difficulty
* 0.2 - Fixed broken messages.
* 0.1 - Initial build. 

###Usage
Say "!intel" in chat

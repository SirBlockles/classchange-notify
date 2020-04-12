/*
Classchange Notifier

Prints the "* Player changed class to <class>" lines from Valve competitive mode into teammates' chat.
Designed for competitive TF2, specifically prolander, 6s, and 4s.
Technically works on other servers, but behaves strangely without mp_tournament. Reccommended to use the override to keep it always enabled for a pub server.
Utilizes PowerLord's PrintValveTranslation include, because, to be blunt, usermessages are not something i'm fantastic at.
That said, thanks to PrintValveTranslation, it utilizes the client's own language file, at the cost of the player's name not being team-colored like it should be.
Not critical priority, but probably fixable...?

Includes game state checks, so it shouldn't show class change messages before teams ready up.
use sm_classchangenotif_override 1 to disable these checks and enable the messages 24/7.
*/

#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdktools>
#include <morecolors>
#include "include/printvalvetranslation.inc" //thank you powerlord

#define VERSION "1.0"

Handle g_Cvar_Enabled;
Handle g_Cvar_Override;
bool roundActive;
int bluReady;
int redReady;

public Plugin myinfo =  {
	name = "Classchange Notifier",
	author = "muddy",
	description = "Enables the class change notification text in chat from Valve competitive mode",
	version = VERSION,
	url = ""
}

public OnPluginStart() {
	CreateConVar("sm_classchangenotif_version", VERSION, "Version of classchange notifier", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_Cvar_Enabled = CreateConVar("sm_classchange_notify", "1", "Enable or disable class change notifications", FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	g_Cvar_Override = CreateConVar("sm_classchange_notify_override", "0", "Ignore tournament match checks, and enable classchange notifications constantly", FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	HookEvent("player_changeclass", Event_Changeclass);
	HookEvent("teamplay_round_active", Event_RoundActive);
	HookEvent("arena_round_start", Event_RoundActive); //for the four people left on the planet who still play Arena mode
	HookEvent("teamplay_win_panel", Event_RoundEnd); //i've heard teamplay_win_panel is more reliable than teamplay_round_win, and they both fire at the same time anyway...
	HookEvent("arena_win_panel", Event_RoundEnd);
	HookEvent("tournament_stateupdate", Event_TournamentState);
	HookEvent("tf_game_over", Event_GameOver); //team reaches mp_winlimit
	HookEvent("teamplay_game_over", Event_GameOver); //game reaches mp_timelimit or mp_maxrounds
	HookEvent("teamplay_restart_round", Event_RestartRound);
	RegServerCmd("mp_tournament_restart", Command_TournamentRestart);
}

public OnMapStart() {
	roundActive = false;
	bluReady = 0;
	redReady = 0;
}

public Event_RestartRound(Handle event, const char[] name, bool dontBroadcast){
	//game forcefully started via mp_restartgame. teams have been readied up for purposes of game start,
	//and the round being active will be set to true in a few seconds by Event_RoundActive
	redReady = 1;
	bluReady = 1;
	roundActive = false;
}

public Event_RoundActive(Handle event, const char[] name, bool dontBroadcast){
	//if teams are marked as not ready, then we assume the "round" that started is actually the pre-game.
	//we don't want class-change notifications during pre-game, since people are just jumping around mid waiting for their class slots and such.
	if(!redReady || !bluReady) roundActive = false; else roundActive = true;
}

public Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast){
	//mark rounds inactive between win panel and active next round, so people can change class between rounds (eg switch off of offclasses after losing last) without notifying
	roundActive = false;
}

public Event_GameOver(Handle event, const char[] name, bool dontBroadcast){
	//this should be self-explanatory
	roundActive = false;
	bluReady = 0;
	redReady = 0;
}

public Event_TournamentState(Handle event, const char[] name, bool dontBroadcast) {
	//hook into players toggling ready status of teams, and update our internal team status to match
	int ply = GetEventInt(event, "userid");
	int readystate = GetEventInt(event, "readystate");
	
	if(GetClientTeam(ply) == 2) redReady = readystate;
	else if (GetClientTeam(ply) == 3) bluReady = readystate;
	else PrintToChatAll("[SM] %N could not be determined to be on a team! How did they ready up?!", ply);
}

public Action:Command_TournamentRestart(args) {
	//mark teams as NOT READY since game has forcefully ended and we're back in pregame
	redReady = 0;
	bluReady = 0;
	roundActive = false;
	return Plugin_Continue;
}

public Event_Changeclass(Handle event, const char[] name, bool dontBroadcast){ 
	//this is where the fun begins
	//if the plugin is set to disabled, or it's enabled but the round isn't active (and we're not overriding it), then stop here.
	if(!GetConVarBool(g_Cvar_Enabled) || (!roundActive && !GetConVarBool(g_Cvar_Override))) return;
	int plyid = GetClientOfUserId(GetEventInt(event, "userid"));
	char ply[MAX_NAME_LENGTH];
	int classID = GetEventInt(event, "class");
	char class[32] = "#TF_Class_Name_Undefined" //default to an unknown class, in case we somehow don't get a 1-9 value for the player's class
	GetClientName(plyid, ply, sizeof(ply));
	switch(classID) { //these numbers are all out of whack, but these are the correct values for SM...
		case 1: { Format(class, sizeof(class), "#TF_Class_Name_Scout"); }
		case 2: { Format(class, sizeof(class), "#TF_Class_Name_Sniper"); }
		case 3: { Format(class, sizeof(class), "#TF_Class_Name_Soldier"); }
		case 4: { Format(class, sizeof(class), "#TF_Class_Name_Demoman"); }
		case 5: { Format(class, sizeof(class), "#TF_Class_Name_Medic"); }
		case 6: { Format(class, sizeof(class), "#TF_Class_Name_HWGuy"); }
		case 7: { Format(class, sizeof(class), "#TF_Class_Name_Pyro"); }
		case 8: { Format(class, sizeof(class), "#TF_Class_Name_Spy"); }
		case 9: { Format(class, sizeof(class), "#TF_Class_Name_Engineer"); }
	}
	
	int plyteam = GetClientTeam(plyid);
	
	//with PowerLord's Valve Translations include, we can print the message using players' language file. This means it automagically works for everyone, regardless of language settings.
	//i just can't figure out how to make the messages team-colored, but i think the default olive green stands out more anyway. The alternative was hard-coding an English message, but supporting colors.
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i)) continue;
		if(GetClientTeam(i) == plyteam) PrintValveTranslationToOne(i, Destination_Chat, "TF_Class_Change", ply, class);
	}
}
#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <multicolors>
#include <builtinvotes>

#define SCORE_DELAY_EMPTY_SERVER 3.0
#define ZOMBIECLASS_SMOKER 1
#define ZOMBIECLASS_BOOMER 2
#define ZOMBIECLASS_HUNTER 3
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY 5
#define ZOMBIECLASS_CHARGER 6
#define ZOMBIECLASS_TANK 8
#define MaxHealth 100
#define VOTE_NO "no"
#define VOTE_YES "yes"
#define MENU_TIME 20
#define L4D_TEAM_SPECTATE	1
#define MAX_CAMPAIGN_LIMIT 64
#define FORCESPECTATE_PENALTY 60
#define VOTEDELAY_TIME 60
#define READY_RESTART_MAP_DELAY 2

bool game_l4d2 = false;
int kickplayer_userid;
char kickplayer_name[MAX_NAME_LENGTH];
char kickplayer_SteamId[MAX_NAME_LENGTH];
char votesmaps[MAX_NAME_LENGTH];
char votesmapsname[MAX_NAME_LENGTH];
ConVar VotensHpED;
ConVar VotensAlltalkED;
ConVar VotensAlltalk2ED;
ConVar VotensRestartmapED;
ConVar VotensMapED;
ConVar VotensMap2ED;
ConVar VotensED;
ConVar VotensKickED;
ConVar VotensForceSpectateED;
ConVar g_hCvarPlayerLimit;
ConVar g_hKickImmueAccess;
int g_iCvarPlayerLimit;
Handle g_hVoteMenu = null;
float lastDisconnectTime;
int g_iCount;
char g_sMapinfo[MAX_CAMPAIGN_LIMIT][MAX_NAME_LENGTH];
char g_sMapname[MAX_CAMPAIGN_LIMIT][MAX_NAME_LENGTH];
bool g_bEnable, VotensHpE_D, VotensAlltalkE_D, VotensAlltalk2E_D, VotensRestartmapE_D, 
	VotensMapE_D, VotensMap2E_D, g_bVotensKickED, g_bVotensForceSpectateED;
char g_sKickImmueAccesslvl[16];

enum voteType
{
	None,
	hp,
	alltalk,
	alltalk2,
	restartmap,
	kick,
	map,
	map2,
	forcespectate,
}
voteType g_voteType = None;

int forcespectateid;
char forcespectateplayername[MAX_NAME_LENGTH];
static	int g_iSpectatePenaltyCounter[MAXPLAYERS + 1];
static int g_votedelay;
int MapRestartDelay;
Handle MapCountdownTimer;
bool isMapRestartPending = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test == Engine_Left4Dead ) game_l4d2 = false;
	else if( test == Engine_Left4Dead2 ) game_l4d2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success; 
}

public Plugin myinfo =
{
	name = "L4D2 Vote Menu",
	author = "HarryPotter",
	description = "Votes Commands",
	version = "1.0h-2024/3/8",
	url = "http://steamcommunity.com/profiles/76561198026784913"
};

public void OnPluginStart()
{
	RegConsoleCmd("voteshp", Command_VoteHp);
	RegConsoleCmd("votesalltalk", Command_VoteAlltalk);
	RegConsoleCmd("votesalltalk2", Command_VoteAlltalk2);
	RegConsoleCmd("votesrestartmap", Command_VoteRestartmap);
	RegConsoleCmd("votesmapsmenu", Command_VotemapsMenu);
	RegConsoleCmd("votesmaps2menu", Command_Votemaps2Menu);
	RegConsoleCmd("voteskick", Command_VotesKick);
	RegConsoleCmd("sm_votes", Command_Votes, "open vote meun");
	RegConsoleCmd("sm_callvote", Command_Votes, "open vote meun");
	RegConsoleCmd("sm_callvotes", Command_Votes, "open vote meun");
	RegConsoleCmd("votesforcespectate", Command_Votesforcespectate);

	VotensHpED 				= CreateConVar("l4d_VotenshpED", 					"1", "If 1, Enable Give HP Vote.", FCVAR_NOTIFY);
	VotensAlltalkED 		= CreateConVar("l4d_VotensalltalkED", 				"1", "If 1, Enable All Talk On Vote.", FCVAR_NOTIFY);
	VotensAlltalk2ED 		= CreateConVar("l4d_Votensalltalk2ED", 				"1", "If 1, Enable All Talk Off Vote.", FCVAR_NOTIFY);
	VotensRestartmapED 		= CreateConVar("l4d_VotensrestartmapED",			"1", "If 1, Enable Restart Current Map Vote.", FCVAR_NOTIFY);
	VotensMapED 			= CreateConVar("l4d_VotensmapED", 					"1", "If 1, Enable Change Valve Map Vote.", FCVAR_NOTIFY);
	VotensMap2ED 			= CreateConVar("l4d_Votensmap2ED", 					"1", "If 1, Enable Change Custom Map Vote.", FCVAR_NOTIFY);
	VotensED 				= CreateConVar("l4d_Votens", 						"1", "0=Off, 1=On this plugin", FCVAR_NOTIFY);
	VotensKickED 			= CreateConVar("l4d_VotesKickED", 					"1", "If 1, Enable Kick Player Vote.", FCVAR_NOTIFY);
	VotensForceSpectateED 	= CreateConVar("l4d_VotesForceSpectateED", 			"1", "If 1, Enable ForceSpectate Player Vote.", FCVAR_NOTIFY);
	g_hCvarPlayerLimit 		= CreateConVar("sm_vote_player_limit", 				"2", "Minimum # of players in game to start the vote", FCVAR_NOTIFY);
	g_hKickImmueAccess 		= CreateConVar("l4d_VotesKick_immue_access_flag", 	"z", "Players with these flags have kick immune. (Empty = Everyone, -1: Nobody)", FCVAR_NOTIFY);

	GetCvars();
	VotensHpED.AddChangeHook(ConVarChanged_Cvars);
	VotensAlltalkED.AddChangeHook(ConVarChanged_Cvars);
	VotensAlltalk2ED.AddChangeHook(ConVarChanged_Cvars);
	VotensRestartmapED.AddChangeHook(ConVarChanged_Cvars);
	VotensMapED.AddChangeHook(ConVarChanged_Cvars);
	VotensMap2ED.AddChangeHook(ConVarChanged_Cvars);
	VotensED.AddChangeHook(ConVarChanged_Cvars);
	VotensKickED.AddChangeHook(ConVarChanged_Cvars);
	VotensForceSpectateED.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarPlayerLimit.AddChangeHook(ConVarChanged_Cvars);
	g_hKickImmueAccess.AddChangeHook(ConVarChanged_Cvars);

	AutoExecConfig(true, "l4d_votes_5");
}

public void OnPluginEnd()
{
    if(g_hVoteMenu!=null)
    {
        CancelBuiltinVote();
    }
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarPlayerLimit = g_hCvarPlayerLimit.IntValue;
	VotensHpE_D = VotensHpED.BoolValue;
	VotensAlltalkE_D = VotensAlltalkED.BoolValue;
	VotensAlltalk2E_D = VotensAlltalk2ED.BoolValue;
	VotensRestartmapE_D = VotensRestartmapED.BoolValue;		
	VotensMapE_D = VotensMapED.BoolValue;
	VotensMap2E_D = VotensMap2ED.BoolValue;
	g_bVotensKickED = VotensKickED.BoolValue;
	g_bVotensForceSpectateED = VotensForceSpectateED.BoolValue;
	g_bEnable = VotensED.BoolValue;
	g_hKickImmueAccess.GetString(g_sKickImmueAccesslvl,sizeof(g_sKickImmueAccesslvl));
}

void RestartMapDelayed()
{
	if (MapCountdownTimer == null)
	{
		PrintHintTextToAll("Get Ready!\nMap restart in: %d",READY_RESTART_MAP_DELAY+1);
		isMapRestartPending = true;
		MapRestartDelay = READY_RESTART_MAP_DELAY;
		MapCountdownTimer = CreateTimer(1.0, timerRestartMap, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

Action timerRestartMap(Handle timer)
{
	if (MapRestartDelay == 0)
	{
		MapCountdownTimer = null;
		RestartMapNow();
		return Plugin_Stop;
	}
	else
	{
		PrintHintTextToAll("Get Ready!\nMap restart in: %d", MapRestartDelay);
		EmitSoundToAll("buttons/blip1.wav", _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
		MapRestartDelay--;
	}
	return Plugin_Continue;
}

void RestartMapNow() 
{
	isMapRestartPending = false;
	char currentMap[256];
	GetCurrentMap(currentMap, 256);
	ServerCommand("changelevel %s", currentMap);
}

public void OnClientPutInServer(int client)
{
	g_iSpectatePenaltyCounter[client] = FORCESPECTATE_PENALTY;
}

public void OnMapStart()
{
	isMapRestartPending = false;
	MapCountdownTimer = null;
	
	ParseCampaigns();
	
	g_votedelay = 15;
	CreateTimer(1.0, Timer_VoteDelay, _, TIMER_REPEAT| TIMER_FLAG_NO_MAPCHANGE);

	
	for(int i = 1; i <= MaxClients; i++)
	{	
		g_iSpectatePenaltyCounter[i] = FORCESPECTATE_PENALTY;
	}
	PrecacheSound("buttons/blip1.wav");
	
	g_hVoteMenu = null;
}

Action Command_Votes(int client, int args) 
{ 
	if (client == 0)
	{
		PrintToServer("[votes] sm_votes cannot be used by server.");
		return Plugin_Handled;
	}
	if(GetClientTeam(client) == 1)
	{
		ReplyToCommand(client, "[votes] 旁觀無權發起投票. (spectators can not call a vote)");	
		return Plugin_Handled;
	}

	if(g_bEnable == true)
	{	
		Panel panel = new Panel();
		SetPanelTitle(panel, "選單");
		if (VotensHpE_D == false)
		{
			DrawPanelItem(panel, "回血(關閉中) Give Hp(Disable)");
		}
		else
		{
			DrawPanelItem(panel, "回血 Give hp");
		}
		if (VotensAlltalkE_D == false)
		{ 
			DrawPanelItem(panel, "全語音(關閉中) Turn on AllTalk(Disable)");
		}
		else
		{
			DrawPanelItem(panel, "全語音 All talk");
		}
		if (VotensAlltalk2E_D == false)
		{
			DrawPanelItem(panel, "關閉全語音(關閉中) Turn off AllTalk(Disable)");
		}
		else
		{
			DrawPanelItem(panel, "關閉全語音 Turn off AllTalk");
		}
		if (VotensRestartmapE_D == false)
		{
			DrawPanelItem(panel, "重新目前地圖(關閉中) Stop restartmap(Disable)");
		}
		else
		{
			DrawPanelItem(panel, "重新目前地圖 Restartmap");
		}
		if (VotensMapE_D == false)
		{
			DrawPanelItem(panel, "換圖(關閉中) Change Maps(Disable)");
		}
		else
		{
			DrawPanelItem(panel, "換圖 Change Maps");
		}

		if (VotensMap2E_D == false)
		{
			DrawPanelItem(panel, "換三方圖(關閉中) Change addon maps(Disable)");
		}
		else
		{
			DrawPanelItem(panel, "換第三方圖 Change addon maps");
		}

		if (g_bVotensKickED == false)
		{
			DrawPanelItem(panel, "踢出玩家(關閉中) Kick Player(Disable)");
		}
		else
		{
			DrawPanelItem(panel, "踢出玩家 Kick Player");
		}

		if (g_bVotensForceSpectateED == false)
		{
			DrawPanelItem(panel, "強制玩家旁觀(關閉中) Forcespectate Player(Disable)");
		}
		else
		{
			DrawPanelItem(panel, "強制玩家旁觀 Forcespectate Player");
		}
		DrawPanelText(panel, " \n");
		DrawPanelText(panel, "0. Exit");
		SendPanelToClient(panel, client, Votes_Menu, MENU_TIME);
		delete panel;
		return Plugin_Handled;
	}
	else
	{
		CPrintToChat(client, "[{olive}TS{default}] 投票選單插件已關閉!");
	}
	
	return Plugin_Stop;
}

int Votes_Menu(Menu menu, MenuAction action, int client, int itemNum)
{
	if ( action == MenuAction_Select ) 
	{ 
		switch (itemNum)
		{
			case 1: 
			{
				if (VotensHpE_D == false)
				{
					Command_Votes(client, 0);
					CPrintToChat(client, "[{olive}TS{default}] 禁用回血");
				}
				else if (VotensHpE_D == true)
				{
					Command_VoteHp(client, 0);
				}
			}
			case 2: 
			{
				if (VotensAlltalkE_D == false)
				{
					Command_Votes(client, 0);
					CPrintToChat(client, "[{olive}TS{default}] 禁用全語音");
				}
				else if (VotensAlltalkE_D == true)
				{
					Command_VoteAlltalk(client, 0);
				}
			}
			case 3: 
			{
				if (VotensAlltalk2E_D == false)
				{
					Command_Votes(client, 0);
					CPrintToChat(client, "[{olive}TS{default}] 禁用關閉全語音");
				}
				else if (VotensAlltalk2E_D == true)
				{
					Command_VoteAlltalk2(client, 0);
				}
			}
			case 4: 
			{
				if (VotensRestartmapE_D == false)
				{
					Command_Votes(client, 0);
					CPrintToChat(client, "[{olive}TS{default}] 禁用重新目前地圖");
				}
				else if (VotensRestartmapE_D == true)
				{
					Command_VoteRestartmap(client, 0);
				}
			}
			case 5: 
			{
				if (VotensMapE_D == false)
				{
					Command_Votes(client, 0);
					CPrintToChat(client, "[{olive}TS{default}] 禁用換圖");
				}
				else if (VotensMapE_D == true)
				{
					Command_VotemapsMenu(client, 0);
				}
			}
			case 6: 
			{
				if (VotensMap2E_D == false)
				{
					Command_Votes(client, 0);
					CPrintToChat(client, "[{olive}TS{default}] 禁用換第三方圖");
				}
				else if (VotensMap2E_D == true)
				{
					Command_Votemaps2Menu(client, 0);
				}
			}
			case 7: 
			{
				if (g_bVotensKickED == false)
				{
					Command_Votes(client, 0);
					CPrintToChat(client, "[{olive}TS{default}] 禁用踢人");
				}
				else if (g_bVotensKickED == true)
				{
					Command_VotesKick(client, 0);
				}
			}
			case 8: 
			{
				if (g_bVotensForceSpectateED == false)
				{
					Command_Votes(client, 0);
					CPrintToChat(client, "[{olive}TS{default}] 禁用強制旁觀玩家");
				}
				else if (g_bVotensForceSpectateED == true)
				{
					Command_Votesforcespectate(client, 0);
				}
			}
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

Action Command_VoteHp(int client, int args)
{
	if(g_bEnable == true 
	&& VotensHpE_D == true)
	{
		if (!TestVoteDelay(client))
		{
			return Plugin_Handled;
		}	
		if(CanStartVotes(client))
		{
			CPrintToChatAll("[{olive}TS{default}]{olive} %N {default}starts a vote: {blue}give hp",client);
			
			g_voteType = view_as<voteType>(hp);
			static char SteamId[32];
			GetClientAuthId(client, AuthId_SteamID64, SteamId, sizeof(SteamId));
			LogMessage("%N(%s) starts a vote: give hp!",  client, SteamId);//記錄在log文件
			g_hVoteMenu = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
			char sTitle[64];
			FormatEx(sTitle, sizeof(sTitle), "Give HP?");
			SetBuiltinVoteArgument(g_hVoteMenu, sTitle);
			SetBuiltinVoteInitiator(g_hVoteMenu, client);
			SetBuiltinVoteResultCallback(g_hVoteMenu, VoteResultHandler);
			DisplayBuiltinVoteToAll(g_hVoteMenu, 20);
			FakeClientCommand(client, "Vote Yes");
		}
		else
		{
			return Plugin_Handled;
		}
		
		return Plugin_Handled;	
	}
	else if(g_bEnable == false || VotensHpE_D == false)
	{
		CPrintToChat(client, "[{olive}TS{default}] This vote is prohibited");
	}
	return Plugin_Handled;
}
Action Command_VoteAlltalk(int client, int args)
{
	if(g_bEnable == true 
	&& VotensAlltalkE_D == true)
	{
		if (!TestVoteDelay(client))
		{
			return Plugin_Handled;
		}
		if(CanStartVotes(client))
		{
			CPrintToChatAll("[{olive}TS{default}]{olive} %N {default}starts a vote: {blue}turn on alltalk",client);
				
			g_voteType = view_as<voteType>(alltalk);
			static char SteamId[32];
			GetClientAuthId(client, AuthId_SteamID64, SteamId, sizeof(SteamId));
			LogMessage("%N(%s) starts a vote: turn on Alltalk!",  client, SteamId);//紀錄在log文件
			
			g_hVoteMenu = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
			char sTitle[64];
			FormatEx(sTitle, sizeof(sTitle), "Turn on All Talk?");
			SetBuiltinVoteArgument(g_hVoteMenu, sTitle);
			SetBuiltinVoteInitiator(g_hVoteMenu, client);
			SetBuiltinVoteResultCallback(g_hVoteMenu, VoteResultHandler);
			DisplayBuiltinVoteToAll(g_hVoteMenu, 20);
			FakeClientCommand(client, "Vote Yes");
		}
		else
		{
			return Plugin_Handled;
		}
		
		return Plugin_Handled;	
	}
	else if(g_bEnable == false || VotensAlltalkE_D == false)
	{
		CPrintToChat(client, "[{olive}TS{default}] This vote is prohibited");
	}
	return Plugin_Handled;
}
Action Command_VoteAlltalk2(int client, int args)
{
	if(g_bEnable == true 
	&& VotensAlltalk2E_D == true )
	{
		if (!TestVoteDelay(client))
		{
			return Plugin_Handled;
		}	
		
		if(CanStartVotes(client))
		{
			CPrintToChatAll("[{olive}TS{default}]{olive} %N {default}starts a vote: {blue}turn off alltalk",client);
	
			g_voteType = view_as<voteType>(alltalk2);
			static char SteamId[32];
			GetClientAuthId(client, AuthId_SteamID64, SteamId, sizeof(SteamId));
			LogMessage("%N(%s) starts a vote: turn off Alltalk!",  client, SteamId);//紀錄在log文件
			
			g_hVoteMenu = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
			char sTitle[64];
			FormatEx(sTitle, sizeof(sTitle), "Turn off All Talk?");
			SetBuiltinVoteArgument(g_hVoteMenu, sTitle);
			SetBuiltinVoteInitiator(g_hVoteMenu, client);
			SetBuiltinVoteResultCallback(g_hVoteMenu, VoteResultHandler);
			DisplayBuiltinVoteToAll(g_hVoteMenu, 20);
			FakeClientCommand(client, "Vote Yes");
		}
		else
		{
			return Plugin_Handled;
		}
		
		return Plugin_Handled;	
	}
	else if(g_bEnable == false || VotensAlltalk2E_D == false)
	{
		CPrintToChat(client, "[{olive}TS{default}] This vote is prohibited");
	}
	return Plugin_Handled;
}
Action Command_VoteRestartmap(int client, int args)
{
	if(g_bEnable == true 
	&& VotensRestartmapE_D == true)
	{
		if (!TestVoteDelay(client))
		{
			return Plugin_Handled;
		}	

		if(CanStartVotes(client))
		{
			CPrintToChatAll("[{olive}TS{default}]{olive} %N {default}starts a vote: {blue}restartmap",client);

			g_voteType = view_as<voteType>(restartmap);
			static char SteamId[32];
			GetClientAuthId(client, AuthId_SteamID64, SteamId, sizeof(SteamId));
			LogMessage("%N(%s) starts a vote: restartmap!",  client, SteamId);//紀錄在log文件
			
			g_hVoteMenu = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
			char sTitle[64];
			FormatEx(sTitle, sizeof(sTitle), "Restart Current Map?");
			SetBuiltinVoteArgument(g_hVoteMenu, sTitle);
			SetBuiltinVoteInitiator(g_hVoteMenu, client);
			SetBuiltinVoteResultCallback(g_hVoteMenu, VoteResultHandler);
			DisplayBuiltinVoteToAll(g_hVoteMenu, 20);
			FakeClientCommand(client, "Vote Yes");
		}
		else
		{
			return Plugin_Handled;
		}
		
		return Plugin_Handled;	
	}
	else if(g_bEnable == false || VotensRestartmapE_D == false)
	{
		CPrintToChat(client, "[{olive}TS{default}] This vote is prohibited");
	}
	return Plugin_Handled;
}
Action Command_VotesKick(int client, int args)
{
	if(client==0) return Plugin_Handled;		
	if(g_bEnable == true && g_bVotensKickED == true)
	{
		CreateVoteKickMenu(client);	
	}	
	else if(g_bEnable == false || g_bVotensKickED == false)
	{
		CPrintToChat(client, "[{olive}TS{default}] Kick Player is prohibited");
	}	
	return Plugin_Handled;
}

void CreateVoteKickMenu(int client)
{	
	int team = GetClientTeam(client);
	Handle menu = CreateMenu(Menu_VotesKick);		
	char name[MAX_NAME_LENGTH];
	char playerid[32];
	SetMenuTitle(menu, "plz choose player u want to kick");
	for(int i = 1;i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && (GetClientTeam(i) == team || GetClientTeam(i) == 1))
		{
			Format(playerid,sizeof(playerid),"%i",GetClientUserId(i));
			if(GetClientName(i,name,sizeof(name)))
			{
				AddMenuItem(menu, playerid, name);						
			}
		}		
	}
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME);	
}
int Menu_VotesKick(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32], name[32];
		GetMenuItem(menu, param2, info, sizeof(info), _, name, sizeof(name));
		int player = StringToInt(info);
		player = GetClientOfUserId(player);
		if(player && IsClientInGame(player))
		{
			if (player == param1)
			{
				CPrintToChat(param1, "[{olive}TS{default}] Kick yourself? choose again");
				CreateVoteKickMenu(param1);
				return 0;
			}
			
			if(HasAccess(player, g_sKickImmueAccesslvl))
			{
				CPrintToChat(param1, "[{olive}TS{default}] Target has kick immue, choose again!");
				CPrintToChat(player, "[{olive}TS{default}] {olive}%N{default} tries to kick you, but you have kick immue.", param1);
				CreateVoteKickMenu(param1);
			}
			else
			{
				kickplayer_userid = GetClientUserId(player);
				kickplayer_name = name;
				GetClientAuthId(player, AuthId_Steam2,kickplayer_SteamId, sizeof(kickplayer_SteamId));
				DisplayVoteKickMenu(param1);
			}
		}	
		else
		{
			CPrintToChat(param1, "[{olive}TS{default}] Target is not in game, choose again!");
			CreateVoteKickMenu(param1);
		}	
	}
	else if ( action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack) 
		{
			Command_Votes(param1, 0);
		}
	}
	else if ( action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

void DisplayVoteKickMenu(int client)
{
	if (!TestVoteDelay(client))
	{
		return;
	}
	
	if(CanStartVotes(client))
	{
		g_voteType = view_as<voteType>(kick);
		char SteamId[35];
		GetClientAuthId(client, AuthId_Steam2, SteamId, sizeof(SteamId));
		LogMessage("%N(%s) starts a vote: kick %s(%s)",  client, SteamId, kickplayer_name, kickplayer_SteamId);//紀錄在log文件
		CPrintToChatAll("[{olive}TS{default}]{olive} %N {default}starts a votes: {blue}kick %s", client, kickplayer_name);

		g_hVoteMenu = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
		char sTitle[64];
		FormatEx(sTitle, sizeof(sTitle), "Kick %s ?",kickplayer_name);
		SetBuiltinVoteArgument(g_hVoteMenu, sTitle);
		SetBuiltinVoteInitiator(g_hVoteMenu, client);
		SetBuiltinVoteResultCallback(g_hVoteMenu, VoteResultHandler);
		DisplayBuiltinVoteToAll(g_hVoteMenu, 20);
		FakeClientCommand(client, "Vote Yes");
	}
	else
	{
		return;
	}
}

Action Command_VotemapsMenu(int client, int args)
{
	if(g_bEnable == true && VotensMapE_D == true)
	{
		if (!TestVoteDelay(client))
		{
			return Plugin_Handled;
		}
		Handle menu = CreateMenu(MapMenuHandler);
		
		SetMenuTitle(menu, "Plz choose maps");
		if(game_l4d2)
		{
			AddMenuItem(menu, "c1m1_hotel", "死亡都心 C1");
			AddMenuItem(menu, "c2m1_highway", "黑色嘉年華 C2");
			AddMenuItem(menu, "c3m1_plankcountry", "沼澤瘧疾 C3");
			AddMenuItem(menu, "c4m1_milltown_a", "大雨 C4");
			AddMenuItem(menu, "c5m1_waterfront", "教區 C5");
			AddMenuItem(menu, "c6m1_riverbank", "短暫之時 C6");
			AddMenuItem(menu, "c7m1_docks", "犧牲 C7");
			AddMenuItem(menu, "c8m1_apartment", "毫不留情 C8");
			AddMenuItem(menu, "c9m1_alleys", "速成課程 C9");
			AddMenuItem(menu, "c10m1_caves", "死亡喪鐘 C10");
			AddMenuItem(menu, "c11m1_greenhouse", "死亡機場 C11");
			AddMenuItem(menu, "c12m1_hilltop", "嗜血豐收 C12");
			AddMenuItem(menu, "c13m1_alpinecreek", "冷澗溪流 C13");
			AddMenuItem(menu, "c14m1_junkyard", "最後一刻 C14");
		}
		else
		{
			AddMenuItem(menu, "l4d_vs_hospital01_apartment", "毫不留情 No Mercy");
			AddMenuItem(menu, "l4d_garage01_alleys", "速成課程 Crash Course");
			AddMenuItem(menu, "l4d_vs_smalltown01_caves", "死亡喪鐘 Death Toll");
			AddMenuItem(menu, "l4d_vs_airport01_greenhouse", "死亡機場 Dead Air");
			AddMenuItem(menu, "l4d_vs_farm01_hilltop", "嗜血豐收 Bloody Harvest");
			AddMenuItem(menu, "l4d_river01_docks", "犧牲 The Sacrifice");
		}
		SetMenuExitBackButton(menu, true);
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME);
		
		return Plugin_Handled;
	}
	else if(g_bEnable == false || VotensMapE_D == false)
	{
		CPrintToChat(client, "[{olive}TS{default}] Change map vote is prohibited");
	}
	return Plugin_Handled;
}

Action Command_Votemaps2Menu(int client, int args)
{
	if(g_bEnable == true && VotensMap2E_D == true)
	{
		if (!TestVoteDelay(client))
		{
			return Plugin_Handled;
		}
		Handle menu = CreateMenu(MapMenuHandler);
	
		SetMenuTitle(menu, "▲ Vote Custom Maps <%d map%s>", g_iCount, ((g_iCount > 1) ? "s": "") );
		for (int i = 0; i < g_iCount; i++)
		{
			AddMenuItem(menu, g_sMapinfo[i], g_sMapname[i]);
		}
		
		SetMenuExitBackButton(menu, true);
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME);
		
		return Plugin_Handled;
	}
	else if(g_bEnable == false || VotensMap2E_D == false)
	{
		CPrintToChat(client, "[{olive}TS{default}] Change Custom map vote is prohibited");
	}
	return Plugin_Handled;
}

int MapMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	if ( action == MenuAction_Select ) 
	{
		char info[32], name[64];
		GetMenuItem(menu, itemNum, info, sizeof(info), _, name, sizeof(name));
		votesmaps = info;
		votesmapsname = name;	
		DisplayVoteMapsMenu(client);		
	}
	else if ( action == MenuAction_Cancel)
	{
		if (itemNum == MenuCancel_ExitBack) 
		{
			Command_Votes(client, 0);
		}
	}
	else if ( action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

void DisplayVoteMapsMenu(int client)
{
	if (!TestVoteDelay(client))
	{
		return;
	}
	if(CanStartVotes(client))
	{
	
		char SteamId[35];
		GetClientAuthId(client, AuthId_Steam2, SteamId, sizeof(SteamId));
		LogMessage("%N(%s) starts a vote: change map %s",  client, SteamId,votesmapsname);//紀錄在log文件
		CPrintToChatAll("[{olive}TS{default}]{olive} %N {default}starts a vote: {blue}change map %s", client, votesmapsname);
		
		g_voteType = view_as<voteType>(map);
		
		g_hVoteMenu = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);

		char sTitle[64];
		FormatEx(sTitle, sizeof(sTitle), "Vote to change map: %s", votesmapsname);
		SetBuiltinVoteArgument(g_hVoteMenu, sTitle);
		SetBuiltinVoteInitiator(g_hVoteMenu, client);
		SetBuiltinVoteResultCallback(g_hVoteMenu, VoteResultHandler);
		DisplayBuiltinVoteToAll(g_hVoteMenu, 20);
		FakeClientCommand(client, "Vote Yes");
	}
	else
	{
		return;
	}
}

Action Command_Votesforcespectate(int client, int args)
{
	if(client==0) return Plugin_Handled;		
	if(g_bEnable == true && g_bVotensForceSpectateED == true)
	{
		CreateVoteforcespectateMenu(client);
	}	
	else if(g_bEnable == false || g_bVotensForceSpectateED == false)
	{
		CPrintToChat(client, "[{olive}TS{default}] Forcespectate Player is prohibited");
	}
	return Plugin_Handled;
}

void CreateVoteforcespectateMenu(int client)
{	
	Handle menu = CreateMenu(Menu_Votesforcespectate);		
	int team = GetClientTeam(client);
	char name[MAX_NAME_LENGTH];
	char playerid[32];
	SetMenuTitle(menu, "plz choose player u want to forcespectate");
	for(int i = 1;i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i)==team)
		{
			Format(playerid,sizeof(playerid),"%d",GetClientUserId(i));
			if(GetClientName(i,name,sizeof(name)))
			{
				AddMenuItem(menu, playerid, name);				
			}
		}		
	}
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME);	
}
int Menu_Votesforcespectate(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32], name[32];
		GetMenuItem(menu, param2, info, sizeof(info), _, name, sizeof(name));
		
		int UserId = StringToInt(info);
		int target = GetClientOfUserId(UserId);
		if( target && IsClientInGame(target))
		{
			forcespectateid = GetClientUserId(target);
			forcespectateplayername = name;	
			DisplayVoteforcespectateMenu(param1);		
		}
		else
		{
			CPrintToChat(param1, "[{olive}TS{default}] Target is not in game, choose again!");
			CreateVoteforcespectateMenu(param1);
		}	
	}
	else if ( action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack) 
		{
			Command_Votes(param1, 0);
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

void DisplayVoteforcespectateMenu(int client)
{
	if (!TestVoteDelay(client))
	{
		return;
	}
	
	if(CanStartVotes(client))
	{
		char SteamId[35];
		GetClientAuthId(client, AuthId_Steam2, SteamId, sizeof(SteamId));
		LogMessage("%N(%s) starts a vote: forcespectate player %s", client, SteamId, forcespectateplayername);//紀錄在log文件
		
		int iTeam = GetClientTeam(client);
		CPrintToChatAll("[{olive}TS{default}]{olive} %N {default}starts a vote: {blue}forcespectate player %s{default}, only their team can vote", client, forcespectateplayername);
		
		g_voteType = view_as<voteType>(forcespectate);
		
		g_hVoteMenu = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
		SetMenuTitle(g_hVoteMenu, "forcespectate player %s?",forcespectateplayername);
		AddMenuItem(g_hVoteMenu, VOTE_YES, "Yes");
		AddMenuItem(g_hVoteMenu, VOTE_NO, "No");
		SetMenuExitButton(g_hVoteMenu, false);
		DisplayVoteMenuToTeam(g_hVoteMenu, 20,iTeam);
	}
	else
	{
		return;
	}
}

stock bool DisplayVoteMenuToTeam(Handle hMenu,int iTime, int iTeam)
{
    int iTotal = 0;
    int[] iPlayers = new int[MaxClients];
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != iTeam)
        {
            continue;
        }
        
        iPlayers[iTotal++] = i;
    }
    
    return VoteMenu(hMenu, iPlayers, iTotal, iTime, 0);
}    

int VoteActionHandler(Handle vote, BuiltinVoteAction action, int param1, int param2)
{
	switch (action)
	{
		case BuiltinVoteAction_End:
		{
			delete vote;
			g_hVoteMenu = null;
			g_votedelay = VOTEDELAY_TIME;
			CreateTimer(1.0, Timer_VoteDelay, _, TIMER_REPEAT| TIMER_FLAG_NO_MAPCHANGE);
		}
		case BuiltinVoteAction_Cancel:
		{
			DisplayBuiltinVoteFail(vote, view_as<BuiltinVoteFailReason>(param1));
		}
	}

	return 0;
}

void VoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (int i=0; i<num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_clients / 2))
			{
				DisplayBuiltinVotePass(vote, "Vote Pass...");
				CreateTimer(3.0, COLD_DOWN,_);

				return;
			}
		}
	}

	// Vote Failed
	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

Action Timer_forcespectate(Handle timer, any client)
{
	static bool bClientJoinedTeam = false;		//did the client try to join the infected?
	
	if (!IsClientInGame(client) || IsFakeClient(client)) return Plugin_Stop; //if client disconnected or is fake client
	
	if (g_iSpectatePenaltyCounter[client] != 0)
	{
		if ( (GetClientTeam(client) == 3 || GetClientTeam(client) == 2))
		{
			ChangeClientTeam(client, 1);
			CPrintToChat(client, "[{olive}TS{default}] You have been voted to be forcespectated! Wait {green}%ds {default}to rejoin team again.", g_iSpectatePenaltyCounter[client]);
			bClientJoinedTeam = true;	//client tried to join the infected again when not allowed
		}
		else if(GetClientTeam(client) == 1 && IsClientIdle(client))
		{
			L4D_TakeOverBot(client);
			ChangeClientTeam(client, 1);
			CPrintToChat(client, "[{olive}TS{default}] You have been voted to be forcespectated! Wait {green}%ds {default}to rejoin team again.", g_iSpectatePenaltyCounter[client]);
			bClientJoinedTeam = true;	//client tried to join the infected again when not allowed
		}
		g_iSpectatePenaltyCounter[client]--;
		return Plugin_Continue;
	}
	else if (g_iSpectatePenaltyCounter[client] == 0)
	{
		if (GetClientTeam(client) == 3||GetClientTeam(client) == 2)
		{
			ChangeClientTeam(client, 1);
			bClientJoinedTeam = true;
		}
		if (GetClientTeam(client) == 1 && bClientJoinedTeam)
		{
			CPrintToChat(client, "[{olive}TS{default}] You can rejoin both team now.");	//only print this hint text to the spectator if he tried to join the infected team, and got swapped before
		}
		bClientJoinedTeam = false;
		g_iSpectatePenaltyCounter[client] = FORCESPECTATE_PENALTY;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

//====================================================
void AnyHp()
{
	for( int i = 1; i <= MaxClients; i++ ) 
	{
		if (IsClientInGame(i) && GetClientTeam(i)==2 && IsPlayerAlive(i))
			CheatCommand(i);
	}
}

void CheatCommand(int client)
{
	int give_flags = GetCommandFlags("give");
	SetCommandFlags("give", give_flags & ~FCVAR_CHEAT);
	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge"))//懸掛
	{
		FakeClientCommand(client, "give health");
	}
	else if (L4D_IsPlayerIncapacitated(client))//倒地
	{
		if(L4D_GetPinnedInfected(client) < 0)
		{
			FakeClientCommand(client, "give health");
			SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
		}
	}
	else if(GetClientHealth(client)<100) //血量低於100
	{
		FakeClientCommand(client, "give health");
		SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
	}
	
	SetCommandFlags("give", give_flags);
}

Action Changelevel_Map(Handle timer)
{
	ServerCommand("changelevel %s", votesmaps);

	return Plugin_Continue;
}

//===============================

bool TestVoteDelay(int client)
{
 	int delay = CheckVoteDelay();
 	
 	if (delay > 0)
 	{
 		if (delay > 60)
 		{
 			CPrintToChat(client, "[{olive}TS{default}] You must wait for {red}%i {default}sec then start a new vote!", delay % 60);
 		}
 		else
 		{
 			CPrintToChat(client, "[{olive}TS{default}] You must wait for {red}%i {default}sec then start a new vote!", delay);
 		}
 		return false;
 	}
	
	delay = GetVoteDelay();
 	if (delay > 0)
 	{
 		CPrintToChat(client, "[{olive}TS{default}] You must wait for {red}%i {default}sec then start a new vote!", delay);
 		return false;
 	}
	return true;
}

bool CanStartVotes(int client)
{
 	if(g_hVoteMenu != null || IsVoteInProgress())
	{
		CPrintToChat(client, "[{olive}TS{default}] A vote is already in progress!");
		return false;
	}
	int iNumPlayers;
	//list of players
	for (int i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}
		iNumPlayers++;
	}
	if (iNumPlayers < g_iCvarPlayerLimit)
	{
		CPrintToChat(client, "[{olive}TS{default}] Vote cannot be started. Not enough {red}%d {default}players.", g_iCvarPlayerLimit);
		return false;
	}
	return true;
}
//=======================================
public void OnClientDisconnect(int client)
{
	if (IsClientInGame(client) && IsFakeClient(client)) return;

	float currenttime = GetGameTime();
	
	if (lastDisconnectTime == currenttime) return;
	
	CreateTimer(SCORE_DELAY_EMPTY_SERVER, IsNobodyConnected, currenttime);
	lastDisconnectTime = currenttime;
}

Action IsNobodyConnected(Handle timer, any timerDisconnectTime)
{
	if (timerDisconnectTime != lastDisconnectTime) return Plugin_Stop;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
			return  Plugin_Stop;
	}	
	
	return  Plugin_Stop;
}

Action COLD_DOWN(Handle timer,any client)
{
	switch (g_voteType)
	{
		case (hp):
		{
			AnyHp();
			LogMessage("vote to give hp pass");	
		}
		case (alltalk):
		{
			ServerCommand("sv_alltalk 1");
			LogMessage("vote to turn on alltalk pass");
		}
		case (alltalk2):
		{
			ServerCommand("sv_alltalk 0");
			LogMessage("vote to turn off alltalk pass");
		}
		case (restartmap):
		{
			if(!isMapRestartPending)
			{
				RestartMapDelayed();
				LogMessage("vote to restartmap pass");
			}
		}
		case (map):
		{
			CreateTimer(5.0, Changelevel_Map);
			CPrintToChatAll("[{olive}TS{default}] {green}5{default} sec to change map {blue}%s",votesmapsname);
			LogMessage("Vote to change map %s %s pass",votesmaps,votesmapsname);
		}
		case (kick):
		{				
			CPrintToChatAll("[{olive}TS{default}] %s has been kicked!", kickplayer_name);
			LogMessage("Vote to kick %s pass", kickplayer_name);

			int player = GetClientOfUserId(kickplayer_userid);
			if(player && IsClientInGame(player)) KickClient(player, "You have been kicked due to vote. ban 10 mins");				
			
			BanIdentity(kickplayer_SteamId, 
						10, 
						BANFLAG_AUTHID, 
						"You have been kicked due to vote", 
						"sm_addban", 
						0);
		}
		case (forcespectate):
		{
			forcespectateid = GetClientOfUserId(forcespectateid);
			if(forcespectateid && IsClientInGame(forcespectateid))
			{
				CPrintToChatAll("[{olive}TS{default}] {blue}%s{default} has been forcespectated!", forcespectateplayername);
				ChangeClientTeam(forcespectateid, 1);								
				LogMessage("Vote to forcespectate %s pass",forcespectateplayername);
				CreateTimer(1.0, Timer_forcespectate, forcespectateid, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE); // Start unpause countdown
			}
			else
			{
				CPrintToChatAll("[{olive}TS{default}] %s player not found", forcespectateplayername);	
			}
		}
	}

	return Plugin_Continue;
}

Action Timer_VoteDelay(Handle timer, any client)
{
	g_votedelay--;
	if(g_votedelay<=0)
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

int GetVoteDelay()
{
	return g_votedelay;
}

void ParseCampaigns()
{
	KeyValues g_kvCampaigns = new KeyValues("VoteCustomCampaigns");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "data/VoteCustomCampaigns.txt");

	if ( !FileToKeyValues(g_kvCampaigns, sPath) ) 
	{
		SetFailState("<VCC> File not found: %s", sPath);
		delete g_kvCampaigns;
		return;
	}
	
	if (!KvGotoFirstSubKey(g_kvCampaigns))
	{
		SetFailState("<VCC> File can't read: you dumb noob!");
		delete g_kvCampaigns;
		return;
	}
	
	for (int i = 0; i < MAX_CAMPAIGN_LIMIT; i++)
	{
		KvGetString(g_kvCampaigns,"mapinfo", g_sMapinfo[i], sizeof(g_sMapinfo));
		KvGetString(g_kvCampaigns,"mapname", g_sMapname[i], sizeof(g_sMapname));
		
		if ( !KvGotoNextKey(g_kvCampaigns) )
		{
			g_iCount = ++i;
			break;
		}
	}

	delete g_kvCampaigns;
}

bool HasAccess(int client, char[] sAcclvl)
{
	// no permissions set
	if (strlen(sAcclvl) == 0)
		return true;

	else if (StrEqual(sAcclvl, "-1"))
		return false;

	// check permissions
	int userFlags = GetUserFlagBits(client);
	if ( userFlags & ReadFlagString(sAcclvl) || (userFlags & ADMFLAG_ROOT))
	{
		return true;
	}

	return false;
}

bool IsClientIdle(int client)
{
	if(GetClientTeam(client) != 1)
		return false;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			if(HasEntProp(i, Prop_Send, "m_humanSpectatorUserID"))
			{
				if(GetClientOfUserId(GetEntProp(i, Prop_Send, "m_humanSpectatorUserID")) == client)
						return true;
			}
		}
	}
	return false;
}
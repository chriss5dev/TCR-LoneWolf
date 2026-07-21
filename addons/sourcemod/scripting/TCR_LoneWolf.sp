#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <treason>

int g_crLoneWolf = -1;
int g_LoneWolfClient = 0;
bool g_loneWolfStopRoundEnd = false;
int lwColor[3];
treasonAbility lwAbilities[3];
treasonGadget lwGadgets[2];

ConVar g_cvPrevalence;
ConVar g_cvWeight;
ConVar g_cvMinPlayers;
ConVar g_cvMinTraitors;
ConVar g_cvMinInnocents;
ConVar g_cvHealthBonus;
 
public Plugin myinfo =
{
	name = "TCR Lone Wolf",
	author = "chriss5",
	description = "Adds the Lone Wolf role using Treason Custom Roles (TCR) from chriss5's Treason API (TAPI).",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	HookEvent("round_start", E_RoundStart);
	
	lwColor[0] = 215;
	lwColor[1] = 200;
	lwColor[2] = 0;
	lwAbilities[0] = TA_None;
	lwAbilities[1] = TA_TRadar;
	lwAbilities[2] = TA_ClueRadar;
	lwGadgets[0] = TG_Revolver;
	lwGadgets[1] = TG_PoisonDart;
	
	g_cvPrevalence = CreateConVar("cr_lonewolf_prevalence", "3");
	g_cvWeight = CreateConVar("cr_lonewolf_weight", "10");
	g_cvMinPlayers = CreateConVar("cr_lonewolf_minplayers", "5");
	g_cvMinTraitors = CreateConVar("cr_lonewolf_mintraitors", "1");
	g_cvMinInnocents = CreateConVar("cr_lonewolf_mininnocents", "3");
	g_cvHealthBonus = CreateConVar("cr_lonewolf_hpbonus", "20");
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/lonewolf/lw_stillalive.wav");
	PrecacheSound("lonewolf/lw_stillalive.wav", true);
	AddFileToDownloadsTable("sound/lonewolf/lw_assigned.wav");
	PrecacheSound("lonewolf/lw_assigned.wav", true);
}

public void OnRegisterCustomRoles()
{
	g_crLoneWolf = RegisterCustomRole
	(
		// char[] id,
		"lonewolf",
		// char[] displayName,
		"Lone Wolf",
		// int underlyingRole,
		TR_Solo,
		// int underlyingClass,
		TC_None,
		// int prevalence,
		g_cvPrevalence.IntValue,
		// int weight,
		g_cvWeight.IntValue,
		// int minPlayers,
		g_cvMinPlayers.IntValue,
		// int maxPlayers,
		16,
		// int minTraitors,
		g_cvMinTraitors.IntValue,
		// int minInnocents,
		g_cvMinInnocents.IntValue,
		// bool requireDetective,
		false,
		// bool requireDoctor,
		false,
		// int maxHealthBonus,
		g_cvHealthBonus.IntValue,
		// bool displayAboveText,
		true,
		// int roleColor[3],
		lwColor,
		// int roleTextBrightness,
		255,
		// char[] playerModel,
		"models/player/custom/lonewolf/lonewolf",
		// bool useClassPlayerModels,
		true,
		// char[] poleModel,
		"models/props_cluesystem/custom/lonewolf/pole.mdl",
		// bool discardRoleAbilities,
		true,
		// bool discardRoleGadgets,
		true,
		// bool keepClassAbility,
		true,
		// int abilities[3],
		lwAbilities,
		// int gadgets[2]
		lwGadgets,
		// bool winIfLastAlive
		true
	);
}

public void OnClearCustomRoles()
{
	//this is no longer accurate, so reset it
	g_crLoneWolf = -1;
	g_LoneWolfClient = 0;
}

public void E_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_loneWolfStopRoundEnd = false;
}

// lone wolf wins
public void OnSoloWin(int client, int customRole)
{
	if(IsCustomRoleValid(g_crLoneWolf) && customRole == g_crLoneWolf)
	{
		for (int i = 1; i <= MaxClients; i++)
		{	
			if (IsClientInGame(i))
			{
				SetHudTextParams(ABOVECENTERTEXT_X, ABOVECENTERTEXT_Y, 3.0, 215, 200, 0, 255);
				ShowHudText(i, AUTO_CHANNEL, "The Lone Wolf wins!");
			}
		}
		
		int random = GetRandomInt(1,3);
		switch(random)
		{
			case 1: PrintToChatAll("\x07FFCC00The Lone Wolf wins! ...Wait, who's that?");
			case 2: PrintToChatAll("\x07FFCC00The Lone Wolf wins! Who's the Don now!?");
			case 3: PrintToChatAll("\x07FFCC00The Lone Wolf wins! He trusted nobody.");
		}
	}
}

// lone wolf assigned to player
public void OnClientAssignedCustomRole(int client, int customRoleIndex)
{
	if(customRoleIndex == g_crLoneWolf)
	{
		g_LoneWolfClient = client;
		PrintToChat(client, "\x07FFCC00You are the Lone Wolf! Be the last man standing to win!");
		PrintHintText(client, "You are the Lone Wolf! Be the last man standing to win!");
		EmitSoundToClient(client, "lonewolf/lw_assigned.wav", client, SNDCHAN_AUTO, 70, SND_NOFLAGS, 1.0);
	}
}

// lone wolf still alive
public void OnSoloStoppedRoundEnd(int client)
{
	if
	(
		!g_loneWolfStopRoundEnd
	&&	client == g_LoneWolfClient
	&&	InnocentsAlive() != 1
	)
	{
		for (int i = 1; i <= MaxClients; i++)
		{	
			if (IsClientInGame(i))
			{
				SetHudTextParams(ABOVECENTERTEXT_X, ABOVECENTERTEXT_Y, 3.0, 215, 200, 0, 255);
				ShowHudText(i, AUTO_CHANNEL, "A Lone Wolf is still alive!");
				EmitSoundToClient(i, "lonewolf/lw_stillalive.wav", i, SNDCHAN_AUTO, 70, SND_NOFLAGS, 1.0);
			}
		}
		g_loneWolfStopRoundEnd = true;
	}
}

int InnocentsAlive()
{
	int innocentCount = 0;
	// count the alive innocents, not including solos
	for(int i = 1;i <= MaxClients; i++)
	{
		if(!IsClientInGame(i)) {continue;}
		
		any role = GetClientRole(i);
		if(role == TR_Innocent || role == TR_Detective || role == TR_Doctor)
		{
			innocentCount++;
		}
	}
	
	return innocentCount;
}
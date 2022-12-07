// Purpose:
// Detect menus/dialogs being sent, check player's setting, then open motd with a guide

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#pragma semicolon 1
#pragma newdecls required

#define GAMEDATA               "plugin-messages-assist"
#define GAMEDATA_PLUGINHELPERS "IPluginHelpersCheck"
#define GAMEDATA_CREATEMESSAGE "CPluginHelpersCheck::CreateMessage"

ConVar urlCvar;

public void OnPluginStart()
{
	GameData pGameConfig = LoadGameConfigFile(GAMEDATA);
	if (pGameConfig == null)
		SetFailState("Could not load gamedata file %s", GAMEDATA);

	char szCreateServerInterface[] = "CreateServerInterface";
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(pGameConfig, SDKConf_Signature, szCreateServerInterface))
		SetFailState("Could not obtain game signature %s", szCreateServerInterface);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	Handle pCreateServerInterface = EndPrepSDKCall();
	if (!pCreateServerInterface)
		SetFailState("Could not prep SDK call %s", szCreateServerInterface);

	char szPluginHelpersIface[64];
	if (!pGameConfig.GetKeyValue(GAMEDATA_PLUGINHELPERS, szPluginHelpersIface, sizeof(szPluginHelpersIface)))
		SetFailState("Could not get interface verison for %s", GAMEDATA_PLUGINHELPERS);

	Address pluginHelpers = view_as<Address>(SDKCall(pCreateServerInterface, szPluginHelpersIface, 0));
	if (!pluginHelpers)
		SetFailState("Could not get interface for %s", szPluginHelpersIface);

	DynamicHook hkCreateMessage = DynamicHook.FromConf(pGameConfig, GAMEDATA_CREATEMESSAGE);
	if (!hkCreateMessage)
		SetFailState("Could not create hook %s", GAMEDATA_CREATEMESSAGE);

	if (hkCreateMessage.HookRaw(Hook_Post, pluginHelpers, Hook_CreateMessage) == INVALID_HOOK_ID)
		SetFailState("Could not hook %s", GAMEDATA_CREATEMESSAGE);


	urlCvar = CreateConVar("plugin_messages_assist_url", "https://alienmario.github.io/plugin-messages-assist/", "URL of the MOTD shown to players with plugin messages turned off");
}

public MRESReturn Hook_CreateMessage(DHookReturn hReturn, DHookParam hParams)
{
	int client = hParams.Get(2);
	DialogType type = hParams.Get(3);
	if (client)
	{
		QueryClientConVar(client, "cl_showpluginmessages", QueryFinished, type);
	}
	return MRES_Ignored;
}

public void QueryFinished(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, DialogType value)
{
	if (result == ConVarQuery_Okay)
	{
		if (cvarValue[0] == '0')
		{
			char msg[53], url[256];
			switch (value)
			{
				case DialogType_Menu:
					msg = "We tried to show you a menu, but got blocked :(";
				case DialogType_Msg, DialogType_Text:
					msg = "We tried to show you a message, but got blocked :(";
				case DialogType_Entry:
					msg = "We tried to open an entry prompt, but got blocked :(";
				case DialogType_AskConnect:
					msg = "We tried to show you a redirect, but got blocked :(";
			}
			urlCvar.GetString(url, sizeof(url));
			ShowMOTDPanel(client, msg, url, MOTDPANEL_TYPE_URL);
		}
	}
}
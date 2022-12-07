# plugin-messages-assist

Helper plugin and github page to assist players with enabling plugin messages (menus and other dialogs) after Valve added the "cl_showpluginmessages" convar.

Made primarily for HL2DM where this is a big issue.

## Usage

To use, just merge the sourcemod folder with yours.

This will detect any of the blocked dialog types, check if the player has them allowed, and open a MOTD with the url retrieved from `plugin_messages_assist_url`.

The default page is hosted at https://alienmario.github.io/plugin-messages-assist/ and should remain online as long as this repository exists.
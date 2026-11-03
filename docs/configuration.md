# Configuration

[Back to README](../README.md#configuration-and-environment-variables)

## Configuration files

For instance _test01_, edit `~/msm.d/cs2/cfg/inst-test01/server.conf`. For the base server, edit `~/msm.d/cs2/cfg/base/server.conf`. GOTV settings are in `gotv.conf` in the same directory. Restart the affected server to apply changes.

These files use Bash syntax. Keep the quotes around text values and do not put spaces around `=`. Lines starting with `#` are comments. Remove the `#` to enable an example setting.

Values such as `__PORT__="27015"` are defaults. You can override these for a single start with `PORT=27115 cs2-server @test01 start`. A value written as `PORT="27015"` in the configuration always takes precedence over the value on the command line.


## Presets

`PRESET` selects a reusable configuration for a game mode. The supplied presets are `competitive`, `deathmatch`, `headshots`, `surf`, `tournament` and `wingman`.

Select one in your instance's `server.conf`:

```bash
__PRESET__="deathmatch"
```

Or select it for a single start:

```bash
PRESET=deathmatch cs2-server @test01 start
```

Your copies of the presets are in `~/msm.d/cs2/cfg/presets`. Editing a preset affects every instance that selects it. To make your own, copy an existing `.conf` file in that directory, give it a new name such as `casual.conf`, and select `__PRESET__="casual"` in `server.conf`.

A casual preset uses `__GAMETYPE__=0` and `__GAMEMODE__=0`. Other game mode number combinations are listed in [gamemodes.txt](../cs2/app/gamemodes.txt).


## Maps

The map settings have different purposes:

| Setting | Purpose |
| --- | --- |
| `MAP` | The map to load on startup. If unset, the first entry in `MAPS` is used |
| `MAPS` | A space-separated list used to generate `mapcycle.txt` |
| `MAPGROUP` | The game's map group, which controls the available maps on a vanilla server |

For example, set `__MAPS__="de_nuke de_mirage"` in a preset to change its mapcycle. This does not create a new map group.

To start on a different map:

```bash
MAP=de_nuke cs2-server @test01 start
```


### Workshop maps and collections

Use `WORKSHOP_MAP_ID` for one Workshop map, or `WORKSHOP_COLLECTION_ID` for a collection. Add the setting to `server.conf`, or to a preset if several instances should use it. The ID is the number after `id=` in the Workshop page's address.

For one map:

```bash
WORKSHOP_MAP_ID="1234567890"
```

For a collection, use this instead:

```bash
WORKSHOP_COLLECTION_ID="1234567890"
```

Replace the example number with your map or collection ID. You can also pass these settings on the command line. If both are set, the collection takes precedence. Remove both settings to return to the regular `MAP` and `MAPGROUP` startup.

Workshop IDs go in these settings, not in `MAPS`. The manager starts `de_mirage` first and then sends the Workshop map or collection command to CS2.


## Launch options

The manager generates the launch command from configuration values. Add these to `server.conf`, or edit the existing setting where indicated:

| Launch option | Configuration | File |
| --- | --- | --- |
| `-ip 0.0.0.0` | `__IP__="0.0.0.0"` | `server.conf` |
| `-port 27115` | `__PORT__="27115"` | `server.conf` |
| `-maxplayers 12` | `__MAXPLAYERS__=12` | Preset |
| `-usercon` | `USE_RCON="-usercon"` | `server.conf` |
| `+sv_setsteamaccount ...` | `GSLT="your-token"` | `server.conf` |
| `-authkey ...` | `APIKEY="your-web-api-key"` | `server.conf` |
| `+tv_enable 1` | `__TV_ENABLE__=1` | `gotv.conf` |
| `+host_workshop_map ...` | `WORKSHOP_MAP_ID="1234567890"` | Preset or `server.conf` |
| `+host_workshop_collection ...` | `WORKSHOP_COLLECTION_ID="1234567890"` | Preset or `server.conf` |

`IP="0.0.0.0"` listens on all network interfaces. If you select a specific address, use an IP address assigned to the server machine. A router's public IP is not an address you can bind to on a machine behind that router.

For RCON, also set `__RCON_PASS__="your-password"` in `server.conf`. For a password players must enter to join, set `__PASS__="your-password"`.

There is no `EXTRAPARAMS` setting for arbitrary launch arguments. For console commands such as `+exec`, use the custom commands below. Launch flags such as `-insecure` and `-addhltv1` have no configuration setting in the current manager.


## Custom server commands

Add extra CS2 console commands to `server.conf` with `AUTOEXEC_CUSTOM`. Put one quoted command on each line:

```bash
AUTOEXEC_CUSTOM=(
    'hostname "Friday LAN"'
    "mp_autokick 0"
    "exec myconfig.cfg"
)
```

The manager runs these commands on server startup, after its own basic settings. For this example, put `myconfig.cfg` in `~/msm.d/cs2/inst-test01/game/csgo/cfg/`, or in your base installation's `game/csgo/cfg` if you run the base server.

For commands to run on every map change, use `MAPCHANGE_CUSTOM` with the same format. A list in the selected preset replaces a list with the same name in `server.conf`.

The manager generates `autoexec.cfg`, `server.cfg` and `server_last.cfg` in the game's `cfg` directory on each start. Do not edit those generated files to save your own settings. `GAMEMODE_CUSTOM`, used by some supplied presets, writes commands to `server_last.cfg`, but the manager does not arrange for CS2 to execute that file after the game mode settings.

You can also send a command to a running server:

```bash
cs2-server @test01 exec 'hostname "Friday LAN"'
```

The outer single quotes keep the inner double quotes in the command sent to CS2. Commands sent with `exec` do not change your saved configuration.


## GOTV

Edit `gotv.conf` next to your instance's `server.conf`. Set `__TV_ENABLE__=0` to disable GOTV or `__TV_ENABLE__=1` to enable it. A preset can also set this default. The supplied deathmatch preset disables GOTV.

By default, GOTV uses the game port plus 5. For example, a game server on port 27115 uses GOTV port 27120. Edit `TV_PORT` in `gotv.conf` to change it. Allow that UDP port through your firewall if spectators should connect remotely.

Other settings include `TV_PASS` for the spectator password, `TV_DELAY` for the delay in seconds, `TV_MAXCLIENTS` for the spectator limit and `TV_AUTORECORD` for demo recording. Uncomment and edit the corresponding entries in `gotv.conf` as needed.

Spectators can join from the CS2 console with `connect server-ip:tv-port`. If you set `TV_PASS`, enter `password your-password` first.


## Steam API Helper

For a manually supplied Game Server Login Token, follow the [README](../README.md#configuration-and-environment-variables). To have the manager create tokens, include `SteamAPIHelper` in `MSM_ADDONS` in `~/msm.d/cs2/cfg/defaults.conf`, keeping any other helpers you use:

```bash
MSM_ADDONS="PluginHelper SteamAPIHelper"
```

Start an instance once to create `~/msm.d/cs2/addons/steam-api-helper/config.sh`. Add your [Steam Web API key](https://steamcommunity.com/dev/apikey) to that file:

```bash
APIKEY="your-web-api-key"
```

Restart the instance. The helper creates and saves a token for each instance. A `GSLT` you set in `server.conf` takes precedence over automatic token management. A Web API key and a Game Server Login Token are different credentials.

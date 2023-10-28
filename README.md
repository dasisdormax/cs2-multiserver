# CS2 *Multi* Server Manager (MSM)

Launch and set up **Counter-Strike 2** Dedicated Servers. (WIP)




## About this project

*cs2-multiserver* is an administration tool for CS2 that helps you with the setup, configuration and control of your server(s).

Being specifically designed for LAN environments, it allows you to control many servers running on multiple machines simultaneously. In addition, multiple server instances can share the same base files, saving your precious disk space and bandwidth.

*cs2-multiserver* started as a fork of [csgo-server-launcher](https://github.com/crazy-max/csgo-server-launcher), but by now, all features have been rewritten by scratch.

### About Release 2.0

This is a large update to *cs2-multiserver* with updated configuration and instance directories. Also, this adds experimental support for workshop maps and sourcemod automation.

While a basic migration script is included, there is still a chance of breaks when upgrading from v1.0, so **make backups before upgrading**. You can find the original version in the [v1 branch](https://github.com/dasisdormax/cs2-multiserver/tree/v1).

If you run into trouble or have a suggestion for extra features, feel free to open an issue or fork and work on *cs2-multiserver* yourself.




## Currently working features

* The basics
	* SteamCMD and Game Installation, checking for and performing updates
	* CS2 Server instance creation
	* Instance-specific server configuration (using config files)
	* Running a server basically works (Including logging)! Yay!
* Advanced features
	* Hosting workshop collections
	* Copying and controlling instances over the network
	* Sourcemod installation, configuration and plugin management (Please report outdated / missing plugins)




## The vision / planned features

The emphasis is on **MULTI**

* **_MULTIPLE_ USERS**: An admin-client system for sharing the base installation. Thus, the same files do not have to be downloaded and stored multiple times.
* **_MULTIPLE_ INSTANCES**: Each game server instance shares the base files, but has its own configuration. Multiple instances can run on a system simultaneously.
* **_MULTIPLE_ CONFIGURATIONS**: Different gamemodes (like competitive/deathmatch/surfing) that can be chosen when starting the server

Additional ideas:

* While the _MULTI_ features are the highlight, managing a single server for yourself should be just as easy.
* Game configuration upon launch with environment variables. Possible features:
	- Mapcycle generator (as `MAPS` variable)
	- automatic team assignment (as `TEAM_T` and `TEAM_CT` variable)




## Requirements

These scripts run in `bash` in _Linux_ or _WSL2_ for Windows, and require several typical and some less common utilities installed. Also note that SteamCMD and your game server are 32-bit applications, so you'll have to install the 32-bit support libraries for your system, as described on [the SteamCMD Wiki page](https://developer.valvesoftware.com/wiki/SteamCMD#Linux).

```
sudo apt install lib32gcc-s1 lib32stdc++6 jq unzip inotify-tools expect
```

If you run a different Linux distribution, the commands and package names may differ. If you need to install additional applications, the script will tell you which commands are unavailable.

Also, you need a Steam account that owns the game to create a CS:GO dedicated server. Follow the instructions on the first launch of your instance to register your server; otherwise, players from the internet won't be able to connect.




## Configuration and Environment Variables

The main configuration file will be placed in `~/msm.d`. It will set up all the important environment variables.

* **ADMIN** - Name of the user that 'controls' the installation
* **INSTALL_DIR** - The directory of the base installation. In **ADMIN**'s control.
* **DEFAULT\_INSTANCE** - The instance to work on if no specific is selected

The server settings themselves are instance-specific and can be configured in `~/msm.d/cs2/cfg/inst/$INSTANCE/server.conf`. Most importantly, you should check and set the `GSLT`, `IP` and `PORT` variables for every new instance.




## Installation

#### Steps for the server administrator

1. (Optional, if you want to use installation sharing) Create a separate _admin_ user (__NOT root__, usually called _steam_) that controls SteamCMD and the base installation. You can, of course, be your own admin.
2. Use `git clone https://github.com/dasisdormax/cs2-multiserver.git` to clone this repository to whatever place you like (preferably within the admin's home directory ~admin). Make sure this directory and all files in it are readable to all users who will use this script.
3. For easier invocation of the main script (just by typing `cs2-server` in your terminal), create a symlink with the following command: `ln -s /path/to/cs2-multiserver/msm /usr/local/bin/cs2-server`
4. As the admin user (__NOT root__), try `cs2-server setup`. This will guide you through creating the initial configuration.
5. Install updates or the server itself as the admin user with `cs2-server update` (possibly automated by cron)
 
#### Steps for the individual user

Note that individual servers are called _instances_. These share most of the files (like maps, textures, etc.) with the base installation, but can have their own configurations. The special command `@instance-name` selects the instance to run the future commands on. The command `@` without an instance name selects the base installation.

It is, though, not required to create a separate instance if you do not intend to run more than one server on the machine. You can simply run the base installation if you want to.

1. If this is the first time the script is used on the current account, type `cs2-server setup` and follow the instructions to import the configuration from the admin.
2. (If applicable) Create your own instance (a fork of the base installation) named _myinstance_ using `cs2-server @... create`.




## Usage, when fully set up

* `cs2-server @... ( start | stop | restart )` to start/stop/restart the given server instance. The server will run in the background in a separate tmux environment. Please note that the selected _admin_ can stop the server to perform updates without nasty effects.
* `cs2-server @... exec ...` to execute some command in the server's console
* `cs2-server @... console` to access the in-game console (= attach to the tmux environment) to manually enter commands. You can return to your original shell (detach) by typing CTRL-D, a frozen server can be killed using CTRL-K.
* `cs2-server help`




## License

Apache License 2.0. I chose it because I specifically want to allow others to build services based on this script. Of course, I would still appreciate if improvements and fixes could make it back here.

__Be aware that the original csgo-server-launcher by crazy is licensed under the LGPLv3__, which still applies to earlier states of this repository. The license change has been marked with the tags __lgpl-until-here__ and __apache2-from-here__. Since the license change, crazy's code has been fully replaced by own code.

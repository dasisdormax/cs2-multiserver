# CS:GO *Multi* Server Manager

Launch and set up **Counter-Strike: Global Offensive** Dedicated Servers.




## About this project

This is a complete rewrite of [csgo-server-launcher](https://github.com/crazy-max/csgo-server-launcher) (which seemed to be primarily designed for rented root servers). Intention is to make server management easier in both shared server and LAN environments.

There is still A LOT to do!




### Currently working features

* SteamCMD and Game Installation
* CS:GO Server instance creation




### Planned features

The emphasis is on **MULTI**
* **_MULTIPLE_ USERS**: An admin-client system for sharing the base installation. This can save bandwidth/storage
* **_MULTIPLE_ INSTANCES**: Each game server instance shares the base files, but has its own configuration. Multiple instances can run on a system simultaneously. Supporting network bridges would be nice for the future.
* **_MULTIPLE_ CONFIGURATIONS**: Different gamemodes (like competitive/deathmatch/surfing) that can be chosen when starting the server

* More options should be controlled using environment variables, like **MAPS** (a mapcycle generator), **TEAM_T**, **TEAM_CT** (automatic team assignment, depends on plugins)
* Magic network features that let you start/stop a server on a remote machine and copy game/config files over (far future, you can use ssh and rsync anyway)
* It should, though, still be easy to set it up just for one user
* Sourcemod plugin management for each instance (including downloading them), and enabling/disabling them based on configuration
* various improvements and all that stuff




## Requirements

These scripts run in `bash` in _GNU/Linux_, so it expects usual commands to be available (awk, readlink).

Also remember the [dependencies of SteamCMD](https://developer.valvesoftware.com/wiki/SteamCMD#Linux)! (On Ubuntu/Debian 64 Bit: `sudo apt-get install lib32gcc1`)

Additional dependencies are:

* _tmux_, see https://tmux.github.io/
* _wget_, see https://en.wikipedia.org/wiki/Wget
* _tar_, see http://linuxcommand.org/man_pages/tar1.html

Recommended additions:

* _unbuffer_, to make update output and logging smoother (try `sudo apt-get install expect`)

Of course, you need a Steam account with CS:GO owned to create a CS:GO dedicated server. If you wish anybody to be able to connect to your server, get your Gameserver auth tokens (CS:GO = 730) [here](http://steamcommunity.com/dev/managegameservers)




## Environment Variables

The main configuration file, by default, will be placed in `~/csgo-msm.conf`. It will set up all the important environment variables.

* **ADMIN** - Name of the user that 'controls' the installation
* **INSTALL_DIR** - The directory of the base installation. In **ADMIN**'s control.
* **DEFAULT_INSTANCE** - The default server instance
* **DEFAULT_MODE** - The default server gamemode

Other variables will be set up by configs within the game instance's directory

**LOTS OF STUFF IS MISSING**



## Installation

#### Steps for the server administrator

1. (Optional, if you want to use installation sharing) Create a separate _admin_ user (__NOT root__, usually called _steam_) that controls SteamCMD and the base installation. You can, of course, be your own admin.
2. Use `git clone https://github.com/dasisdormax/csgo-multiserver.git` to clone this repository to whatever place you like (preferably within the admin's home directory). Make sure this directory and all files in it are readable to all users who will use this script.
3. Create a symlink to the `csgo-server` main script, like `ln -s /home/$ADMIN/csgo-multiserver/csgo-server /usr/bin/csgo-server` _OR_ add that place to `$PATH` (just for easier invocation).
4. As the admin user (__NOT root__), try `csgo-server admin-install`. This will guide you through creating the initial configuration, downloading SteamCMD, and optionally installing and updating the base game server installation.
5. Manage regularly and install updates as the admin user, with `csgo-server update` (possibly automated by cron)
 
#### Steps for the individual user

Note that individual servers are called _instances_. These can share a large amount of files and assets with the base installation, but have their own configurations.

It is, though, not required to create a separate instance if you do not intend to run more than one server on the machine. If you omit the instance parameter `@instance-name`, the base installation will be selected by default.

1. If this is the first time the script is used on the current account, type `csgo-server` and follow the instructions to import the configuration from the admin.
2. (If applicable) Create your own instance (fork off the selected base installation) named _myinstance_ using `csgo-server @myinstance create`.
3. Manage mods/addons using `csgo-server @myinstance manage`




## Usage, when fully set up

* `csgo-server @instance-name ( start | stop | restart )` to start/stop/restart the given server instance respectively. The server will run in the background in a separate tmux environment. Please note that the selected _admin_ can stop the server to perform updates without nasty effects.
* `csgo-server @instance-name console` to access the in-game console (= attach to the tmux environment) to manually enter commands. You can return to your bash (detach) by typing CTRL-D, a frozen server can be killed using CTRL-K.
* `csgo-server usage` will display detailed usage information
* `csgo-server info` for information about copyright and license.

Other commands are sufficiently explained in the installation section above, I suppose.




## License

Apache License 2.0. This should give nobody worries when using my program and making modifications to it. I would, though, appreciate if code improvements could make it back here.

The original csgo-server-launcher by crazy is licensed as LGPLv3. At this point, no original code is being used anymore. See the branch [crazy](https://github.com/dasisdormax/csgo-multiserver/tree/crazy) for the last LGPL licensed state of this project.

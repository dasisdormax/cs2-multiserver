# CS2 *Multi* Server Manager (MSM)

Launch and set up **Counter-Strike 2** Dedicated Servers. (WIP)




## About this project

*cs2-multiserver* is an administration tool for CS2 that helps you with the setup, configuration and control of your server(s).

Being specifically designed for LAN environments, it allows you to control many servers running on multiple machines simultaneously. In addition, multiple server instances can share the same base files, saving your precious disk space and bandwidth.

*cs2-multiserver* started as a fork of [csgo-server-launcher](https://github.com/crazy-max/csgo-server-launcher), but by now, all features have been rewritten by scratch.


### Upgrading to CS2

This is a large update to *cs2-multiserver* with updated configuration and instance directories. Also, some experimental automation features (for the steam workshop and Sourcemod plugins) were added for CS:GO, but these were not yet updated and tested for CS2.

As CS2 requires an active Steam login for installing and launching the server, the previous multi user system is not supported anymore. Every user needs to install their own copy of the server now.

If you are upgrading from [csgo-multiserver](https://github.com/dasisdormax/csgo-multiserver), you may need to reinstall SteamCMD for everything to work (`rm -r ~/Steam/steamcmd`). 

While the CS:GO version worked quite reliably, CS2 support was not yet tested much. If you run into trouble or have a suggestion for extra features, feel free to open an issue or fork and work on *cs2-multiserver* yourself.


### Notable features

* The basics
	* SteamCMD and Game Installation, checking for and performing updates
	* CS2 Server instance creation
	* Instance-specific server configuration (using config files)
	* Running a server basically works (Including logging)! Yay!
* Advanced features (Untested with CS2)
	* Hosting workshop collections
	* Copying and controlling instances over the network
	* Sourcemod installation, configuration and plugin management (Please report outdated / missing plugins)


### The original vision

The emphasis is on **MULTI**

* **_MULTIPLE_ INSTANCES**: Each game server instance shares the base files, but has its own configuration. Multiple instances can run on a system simultaneously.
* **_MULTIPLE_ CONFIGURATIONS**: Different gamemodes (like competitive/deathmatch/surfing) that can be chosen when starting the server

While the _MULTI_ features are the highlight, managing a single server for yourself is just as easy.




## Getting Started

### Prerequisites

These scripts run in `bash` in _Linux_ or _WSL2_ for Windows, and require several typical and some less common utilities installed. Also note that SteamCMD is a 32-bit application, so you'll have to install the 32-bit support libraries for your system, as described on [the SteamCMD Wiki page](https://developer.valvesoftware.com/wiki/SteamCMD#Linux). You will need at least 60 GB of disk space.

For Ubuntu 22.04 LTS, use the following command:

```
sudo apt install lib32gcc-s1 lib32stdc++6 jq unzip inotify-tools
```

If you run a different Linux distribution, the commands and package names may differ. If you need to install additional applications, the script will tell you which commands are unavailable.

Also, you need a Steam account that owns the game to create a CS2 dedicated server. You will be asked your Steam login credentials during the server setup. Keep your Steam Guard authenticator ready.


### Initial setup

1. Use `git clone https://github.com/dasisdormax/cs2-multiserver.git` to clone this repository to whatever place you like.
2. For easier invocation of the main script (just by typing `cs2-server` in your terminal), create a symlink with the following command: `ln -s /path/to/cs2-multiserver/msm /usr/local/bin/cs2-server`
3. Run `cs2-server setup`. This will guide you through creating the initial configuration.
4. Install the game server and updates with `cs2-server update` (possibly automated by cron)
 

### Instances

Note that individual servers are called _instances_. These share most of the files (like maps, textures, etc.) with the base installation, but can have their own configurations. The special command `@instance-name` selects the instance to run the future commands on. The command `@` without an instance name selects the base installation.

If you only want to run a single server, it is not required to create a separate instance. You can simply run the base installation if you want to.

Create your own instance (a fork of the base installation) named _test01_ using `cs2-server @test01 create`.


### Configuration and Environment Variables

You can set most server configuration options by opening `~/msm.d/cs2/cfg/.../server.conf` with your text editor of choice. Most importantly, you need to set a separate `PORT` for every new instance (recommended: 27015, 27115, 27215, ...). You can also set some options on the command line, e.g. `MAP='de_nuke' cs2-server @lan01 start`.


### Usage, when fully set up

* `cs2-server @... ( start | stop | restart )` to start/stop/restart the given server instance. The server will run in the background in a separate tmux environment.
* `cs2-server @... exec ...` to execute some command in the server's console
* `cs2-server @... console` to access the in-game console (= attach to the tmux environment) to manually enter commands. You can return to your original shell (detach) by typing CTRL-D, a frozen server can be killed using CTRL-K.
* `cs2-server help`




## License

Apache License 2.0. I chose it because I specifically want to allow others to build services based on this script. Of course, I would still appreciate if improvements and fixes could make it back here.

__Be aware that the original csgo-server-launcher by crazy is licensed under the LGPLv3__, which still applies to earlier states of this repository. The license change has been marked with the tags __lgpl-until-here__ and __apache2-from-here__. Since the license change, crazy's code has been fully replaced by own code.

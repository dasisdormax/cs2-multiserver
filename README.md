# CS2 *Multi* Server Manager (MSM)

Launch and set up **Counter-Strike 2** Dedicated Servers. (WIP)




## Getting Help

Please read this README-File, the [documentation](#documentation) and the FAQ at <https://github.com/dasisdormax/cs2-multiserver/wiki/FAQ>.




## About this project

*cs2-multiserver* is an administration tool for CS2 that helps you with the setup, configuration and control of your server(s).

Being specifically designed for LAN environments, it allows you to control many servers running on multiple machines simultaneously. In addition, multiple server instances can share the same base files, saving your precious disk space and bandwidth.

*cs2-multiserver* started as a fork of [csgo-server-launcher](https://github.com/crazy-max/csgo-server-launcher), but by now, all features have been rewritten by scratch.


### Notable features

* The basics
	* SteamCMD and Game Installation, checking for and performing updates
	* CS2 Server instance creation
	* Instance-specific server configuration (using config files)
	* Hosting workshop maps and collections
	* Running a server basically works (Including logging)! Yay!
* Advanced features (Untested with CS2)
	* Copying and controlling instances over the network
	* Metamod and CounterStrikeSharp installation for each instance


### The original vision

The emphasis is on **MULTI**

* **_MULTIPLE_ INSTANCES**: Each game server instance shares the base files, but has its own configuration. Multiple instances can run on a system simultaneously.
* **_MULTIPLE_ CONFIGURATIONS**: Different gamemodes (like competitive/deathmatch/surfing) that can be chosen when starting the server

While the _MULTI_ features are the highlight, managing a single server for yourself is just as easy.




## Getting Started

### Prerequisites

These scripts run in `bash` in _Linux_ or _WSL2_ for Windows, and require Python 3.8+ and several other utilities. Also note that SteamCMD is a 32-bit application, so you'll have to install the 32-bit support libraries for your system, as described on [the SteamCMD Wiki page](https://developer.valvesoftware.com/wiki/SteamCMD#Linux). You will need at least 100 GB of disk space.

For Ubuntu 22.04 LTS, use the following command:

```
sudo apt install git tmux wget lib32gcc-s1 lib32stdc++6 jq unzip inotify-tools python3
```

If you run a different Linux distribution, the commands and package names may differ. If you need to install additional applications, the script will tell you which commands are unavailable.

Run the server as a regular Linux user, not as root.

Also, you need a Steam account that owns the game to host public CS2 dedicated servers. 


### Initial setup

1. Use `git clone https://github.com/dasisdormax/cs2-multiserver.git` to clone this repository to whatever place you like.
2. For easier invocation of the main script (just by typing `cs2-server` in your terminal), create a symlink with the following command: `sudo ln -s /path/to/cs2-multiserver/msm /usr/local/bin/cs2-server`
3. Run `cs2-server setup`. This will guide you through creating the initial configuration. The default game installation directory is `~/msm.d/cs2/base`. If you already have a CS2 installation, you can select its directory instead.
4. Install the game server and updates with `cs2-server update` (possibly automated by cron)


### Instances

Note that individual servers are called _instances_. These share most of the game files (like maps, textures, etc.) with the base installation, but can have their own configurations and plugins. The special command `@instance-name` selects the instance to run the future commands on. The command `@` without an instance name selects the base installation.

If you only want to run a single server, it is not required to create a separate instance. You can simply run the base installation if you want to.

Create your own instance (a fork of the base installation) named _test01_ using `cs2-server @test01 create`.


### Configuration

Before launching, configure your instance by editing the following file with your text editor of choice:

* `~/msm.d/cs2/cfg/inst-test01/server.conf`
  * (adjust `inst-test01` for other instances as needed, or use `base` for the base server)

Things to check:

* Use a unique combination of `__IP__` and `__PORT__` for every new instance, your servers will fail to start otherwise. 
  * _Recommendation:_ Keep `__IP__="0.0.0.0"`, change `__PORT__="27015"` to 27115, 27215, 27315, ...
* Supply a separate Game Server Login Token as `GSLT="your-token"` (not needed for LAN-only servers)  
  * _Manual option:_ Open <https://steamcommunity.com/dev/managegameservers> and create a token using app ID `730`.
  * _Automatic option:_ Use the `SteamAPIHelper` [addon](docs/plugins.md) to automatically create tokens for your instances


### Usage, when fully set up

Start your instance with `cs2-server @test01 start`, or use `cs2-server @ start` to run the base server. Players can join from the CS2 console with `connect server-ip:port`, e.g. `connect 192.168.1.10:27115`. For connections over the Internet, allow the configured UDP port through your firewall and forward it on your router if the server is behind one.

* `cs2-server @... ( start | stop | restart )` to start/stop/restart the given server instance. The server will run in the background in a separate tmux environment.
* `cs2-server @... exec ...` to execute some command in the server's console
* `cs2-server @... console` to access the in-game console (= attach to the tmux environment) to manually enter commands. You can return to your original shell (detach) by typing CTRL-D, a frozen server can be killed using CTRL-K.
* `cs2-server help`


### Command Line / Environment options

You can also set some options on the command line, e.g. `MAP='de_nuke' cs2-server @test01 start`. To change the default game mode, edit `__PRESET__="competitive"` in `server.conf`, e.g. to `__PRESET__="deathmatch"`. Restart the instance after changing its configuration. See [Configuration](docs/configuration.md) for more details.


### Addons and Plugins

Some optional features are provided as "Addons", which hook into the instance lifecycle:

- `SteamAPIHelper`: Automates GSLT Server Token management and improves workshop support.
- `PluginHelper`: Installs Metamod and CounterStrikeSharp for each instance.

Enable / disable them during `cs2-server setup`, or enable them by setting `MSM_ADDONS="PluginHelper SteamAPIHelper"` in `~/msm.d/cs2/cfg/defaults.conf`.

With the `PluginHelper` enabled, you can install CounterStrikeSharp plugins under `~/msm.d/cs2/inst-test01/game/csgo/addons/counterstrikesharp/`.

See [plugins](docs/plugins.md) for addon selection, framework versions and plugin configuration.




## Documentation

* [FAQ](https://github.com/dasisdormax/cs2-multiserver/wiki/FAQ)
* [Configuration](docs/configuration.md): presets, Workshop maps, custom server commands, launch options and GOTV
* [Addons and Plugins](docs/plugins.md): per-instance plugins, addon selection and framework versions
* [Maintenance and Troubleshooting](docs/maintenance.md): file locations, logs, disk space and installation recovery




## License

Apache License 2.0. I chose it because I specifically want to allow others to build services based on this script. Of course, I would still appreciate if improvements and fixes could make it back here.

__Be aware that the original csgo-server-launcher by crazy is licensed under the LGPLv3__, which still applies to earlier states of this repository. The license change has been marked with the tags __lgpl-until-here__ and __apache2-from-here__. Since the license change, crazy's code has been fully replaced by own code.

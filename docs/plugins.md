# Addons and Plugins

[Back to README](../README.md#counterstrikesharp)


## Addon selection

Run `cs2-server setup` again to change the addon selection. The menu starts with your saved choices. Setup keeps your other configuration settings.

`MSM_ADDONS` selects helpers for the manager. These are separate from the game plugins you install in each instance. For example, to enable both bundled helpers, edit `~/msm.d/cs2/cfg/defaults.conf` and set:

```bash
MSM_ADDONS="PluginHelper SteamAPIHelper"
```

Use `MSM_ADDONS=""` to disable both helpers. This does not uninstall game plugins or frameworks already installed in an instance.

For automatic Game Server Login Tokens, see [Steam API Helper](configuration.md#steam-api-helper).


## CounterStrikeSharp

Enable the `PluginHelper` addon to assist with CounterStrikeSharp setup. The former `SourcemodHelper` addon has been retired.

Restart each instance to install the pinned Metamod and CounterStrikeSharp packages. The helper uses the CounterStrikeSharp Linux package with bundled .NET runtime. Install plugins and their configuration under each instance's `game/csgo/addons/counterstrikesharp/` directory. The helper preserves those files when it updates the frameworks. Existing SourceMod files are not removed, but SourceMod is no longer managed by the helper.

The helper adds Metamod to each instance's `gameinfo.gi` before every game launch, including automatic restarts after updates or crashes. Preparation runs after instance synchronization and also applies to the base server. If preparation fails, the controller logs an error and stops without launching the game.

Use `meta list` in the server console to check that CounterStrikeSharp loaded. Framework versions are pinned in `addons/PluginHelper/packages/` and may need updating after a CS2 release.


## Separate plugins for each instance

Each instance has its own `game/csgo/addons` directory. For instance _test01_, this is `~/msm.d/cs2/inst-test01/game/csgo/addons`. Put each instance's plugins and plugin configuration there. The manager's configuration directory, `~/msm.d/cs2/cfg/inst-test01`, is for files such as `server.conf` and `gotv.conf`.

Instances copy the base installation's addons when you create them. Later changes to the base installation's addons do not change existing instances. You can use different plugins and plugin settings on each instance.



# Addons and Plugins

[Back to README](../README.md#counterstrikesharp)


## Addon selection

`MSM_ADDONS` selects helpers for the manager. These are separate from the game plugins you install in each instance. For example, to enable both bundled helpers, edit `~/msm.d/cs2/cfg/defaults.conf` and set:

```bash
MSM_ADDONS="PluginHelper SteamAPIHelper"
```

Use `MSM_ADDONS=""` to disable both helpers. This does not uninstall game plugins or frameworks already installed in an instance.

For automatic Game Server Login Tokens, see [Steam API Helper](configuration.md#steam-api-helper).


## CounterStrikeSharp

Enable the `PluginHelper` addon to assist with CounterStrikeSharp setup (`SourcemodHelper` works as alias for compatibility).

Restart each instance to install the pinned Metamod and CounterStrikeSharp packages. The helper uses the CounterStrikeSharp Linux package with bundled .NET runtime. Install plugins and their configuration under each instance's `game/csgo/addons/counterstrikesharp/` directory. The helper preserves those files when it updates the frameworks. Existing SourceMod files are not removed, but SourceMod is no longer managed by the helper.

The helper adds Metamod to each instance's `gameinfo.gi`. Use `meta list` in the server console to check that CounterStrikeSharp loaded. Framework versions are pinned in `addons/PluginHelper/packages/` and may need updating after a CS2 release.

CounterStrikeSharp is pinned to v1.0.368, the last release with .NET 8. With CounterStrikeSharp v1.0.379 and its bundled .NET 10, the server crashes when quitting, which breaks our error handling. Plugins that require newer CounterStrikeSharp APIs or .NET 10 cannot run on this version. This older release may also lack fixes for current CS2 builds.


## Separate plugins for each instance

Each instance has its own `game/csgo/addons` directory. For instance _test01_, this is `~/msm.d/cs2/inst-test01/game/csgo/addons`. Put each instance's plugins and plugin configuration there. The manager's configuration directory, `~/msm.d/cs2/cfg/inst-test01`, is for files such as `server.conf` and `gotv.conf`.

Instances copy the base installation's addons when you create them. Later changes to the base installation's addons do not change existing instances. You can use different plugins and plugin settings on each instance.



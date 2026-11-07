# Maintenance and Troubleshooting

[Back to README](../README.md#documentation)


## File locations

The manager stores its files under `~/msm.d/cs2`, in the home directory of the Linux user who runs it.

| Directory | Contents |
| --- | --- |
| `base` | The base game installation, unless you selected a different directory during setup |
| `inst-test01` | Game files and plugins for instance _test01_ |
| `cfg/base` | Manager configuration for the base server |
| `cfg/inst-test01` | Manager configuration for instance _test01_ |
| `cfg/presets` | Shared game mode presets |
| `cfg/defaults.conf` | Manager settings, including the base installation path and enabled helpers |
| `log/base` | Logs for the base server and game updates |
| `log/inst-test01` | Logs for instance _test01_ |
| `addons` | Helper downloads and settings |

Replace `test01` with your instance's name. Temporary control files are in each installation's `msm.d/tmp` directory.


## Logs and the server console

The latest server output for instance _test01_ is available at `~/msm.d/cs2/log/inst-test01/server.log`. This is a link to the latest timestamped server log. The same directory contains older server logs and controller logs.

To read the latest output without opening the server console:

```bash
tail -f ~/msm.d/cs2/log/inst-test01/server.log
```

Press CTRL-C to stop watching. If console output makes it difficult to enter commands, send them from your normal terminal instead:

```bash
cs2-server @test01 exec status
```

MSM copies the server console output to a log file. There is no configuration option to disable this recording. The game's `log off` command does not disable MSM's console recording.

For extra manager output, run `MSM_DEBUG=1 cs2-server @test01 start`. When reporting a problem, include the command you ran, the error and relevant logs. Remove passwords and tokens before sharing them.


## Disk space

A basic installation of CS2 takes about 70GB of disk space as of November 2026. Check disk usage with:

```bash
du -h --max-depth=1 ~/msm.d/cs2
```

Instances share most game files with the base installation through links. Deleting files from the base installation also makes them unavailable to instances, and may cause errors during server operation. Validation or a game update can download them again.

You can delete old timestamped logs you no longer need. Stop the affected instance before deleting its current log. Also check each instance's `game/csgo/logs` directory for game logs and `game/csgo` for recorded demos.

To remove an instance, stop it with `cs2-server @test01 stop`, then delete `~/msm.d/cs2/inst-test01`. Its configuration and logs remain under `cfg/inst-test01` and `log/inst-test01`, so you can keep or remove those separately. Keep the base installation while other instances still use it.


## Updating and repairing the installation

The commands `install`, `update` and `validate` operate on the shared base installation, regardless of the selected instance. If servers are running, the manager asks them to stop temporarily. The servers wait for the update to complete and auto-restart afterward. This allows unattended updates using `cs2-server update` in a cronjob or systemd timer.

If an update is interrupted, run `cs2-server validate` to check the base game files. If that does not fix the installation, stop the base server and all instances, then run `cs2-server @ reinstall`. After confirmation, this deletes the contents of the base installation except its `msm.d` directory and downloads the game again. Back up any custom files in the base first.


## Upgrading from CS:GO to CS2

Compared to *csgo-multiserver*, this is a large change with updated configuration and instance directories, and some experimental features.

If you are upgrading from [csgo-multiserver](https://github.com/dasisdormax/csgo-multiserver), you may need to reinstall SteamCMD for everything to work. Remove it with `rm -r ~/Steam/steamcmd`, then run `cs2-server setup` again.

While the CS:GO version worked quite reliably, CS2 support was not yet tested much. If you run into trouble or have a suggestion for extra features, feel free to open an issue or fork and work on *cs2-multiserver* yourself.

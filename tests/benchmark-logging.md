# Console logging benchmark

Run `python3 tests/benchmark-logging.py` on the machine you want to test. The default runs each approach three times with 8 MiB of synthetic output per run. Use `--mib 32 --runs 5` to change the input size and repetitions. Use `--directory /path/to/filesystem` to put temporary logs on a particular filesystem. The benchmark deletes its logs when it finishes.

The benchmark compares direct terminal output with the historical `unbuffer -p | tee`, `script`, and `stdbuf | tee` paths, and the current Python launcher. It skips approaches whose required commands are missing. `unbuffer` usually comes from the Expect package. The Python launcher receives two credential prefixes, but the synthetic output contains no credentials. This exercises prefix matching without measuring the cost of masking frequent matches.

Each run reports elapsed time, total CPU time for the producer and its child processes, average CPU usage as a percentage of one core, input throughput, and the bytes written to the terminal and log. CPU usage can exceed 100% when processes run on multiple cores. Compare CPU seconds with the direct baseline, but remember that the producer is part of each measurement. The output and log byte counts can differ between approaches because pseudo-terminals translate line endings and `script` adds a header and footer.

The benchmark drains output from a pseudo-terminal without rendering it. It does not measure tmux, a terminal emulator, actual CS2 output, or game tick times. It writes as fast as the synthetic producer can, so it is a stress test rather than a prediction of production load. Repeat tests on an otherwise idle system and compare several runs. Filesystem caches and other workloads affect the results.

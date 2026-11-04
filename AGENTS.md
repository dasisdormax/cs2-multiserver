# Working in this repository

CS2 Multi Server Manager is a Bash application for managing a base installation and server instances. `msm` is the entry point. The app-specific code and default configuration live under `cs2/app`; core modules live under `program`, and optional modules live under `addons`.

Follow the surrounding code's naming, indentation, spacing, and comment style. Existing files differ, so do not impose one file's choices on the whole project.

## Bash loaders and modules

Read `common.sh` before changing script loading. It overrides the Bash `.` and `:` builtins. `.` loads a file, an optional `.sh` file, or the `.sh` files in a directory. `:` resolves a path relative to the calling file before using that loader. Use `builtin .` when the Bash builtin is needed. `.file` returns 127 for a missing file; `.conf` uses that status when loading global and user configuration and then applies defaults. Configuration variables named `__NAME__` provide defaults for `NAME` through `applyDefaults`.

Modules use namespaced functions such as `Core.Instance::select` and `App::buildLaunchCommand`. The addon engine loads module functions and handlers, and removes namespaced functions when unloading modules. For lifecycle changes, inspect `program/AddonEngine/functions.sh` and `addons/AddonTemplate/functions.sh`. `::hookable` runs before and after hooks around a function or named hook. Registered hooks receive the hook name followed by the supplied arguments.

Output helpers in `program/Utils/output.sh` read messages from standard input. They support logging and formatting, and `error` and `fatal` return failure rather than terminating the shell. `log-cmd` runs a command with its arguments and preserves failure when logging is enabled. Debug output uses file descriptor 3.

Use heredocs instead of `printf` for multi-line strings. Use `printf` inside a heredoc when a value needs formatting or Bash escaping.

Good:

```bash
cat > "$config" <<-EOF
	# Credentials
	# Web API Auth Key
	APIKEY=$(printf '%q' "$APIKEY")
EOF
```

Bad:

```bash
(
printf '%s\n' '# Credentials' '# Web API Auth Key'
printf 'APIKEY=%q\n' "$APIKEY" 
) > "$config"
```

## Product and verification

Read `README.md` for the project purpose and use the relevant files in `docs/` for configuration, addon, or maintenance changes. Configuration files are Bash code, and instance settings may override defaults. Consider the base installation as well as named instances when changing lifecycle behavior.

Tests describe the implementation when they were written. Use them to check a theory or validate a change, not to decide product direction. Ask the user when behavior or a project decision is unclear. Run checks appropriate to the change; shell tests in `tests/` are standalone scripts, and Python tests are also in that directory. Avoid requiring a real Steam installation or changing a user's server data for routine checks.

## Writing

Apply these rules to project documentation and user-facing text:

- Use plain, concrete words and active voice. Say what the software does, including a mechanism or number when useful. Split dense sentences and write complete sentences with articles and verbs.
- Remove filler, unnecessary adverbs, generic conclusions, vague attributions, and superficial phrases such as "ensuring" or "highlighting". Name sources when attributing a claim.
- Avoid AI vocabulary such as "delve", "pivotal", "showcase", and "tapestry". Prefer "is" and "has" to phrases such as "serves as" and "boasts". Use literal language instead of metaphors and stock phrases.
- Avoid forced groups of three, unnecessary synonyms for the same thing, false ranges, and "not just X, but Y" constructions.
- Use straight quotes. Avoid em dashes, en dashes, parentheses, and hyphens used as dashes. Use colons before lists or examples, not as mid-sentence connectors.
- Use sentence case headings. Avoid decorative emoji, excessive boldface, and bold inline labels that repeat the text after them.
- Remove chatbot phrases, flattery, and excessive hedging.

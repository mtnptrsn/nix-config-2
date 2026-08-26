set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: killall <target>... [options]

Kills the dev processes you own that match the given targets. The shell you run
it from, and everything it runs inside of, is spared.

Targets:
  node    any node process (dev servers, language servers, formatters, ...)
  vite    vite dev servers
  claude  claude code CLI sessions (the desktop app is left alone)

Options:
  -n, --dry-run  Only list what would be killed
  -f, --force    Send SIGKILL right away instead of SIGTERM first
  -h, --help     Show this help

Examples:
  killall vite
  killall vite claude
  killall node --dry-run
USAGE
}

dry_run=0
force=0
targets=()

while [ $# -gt 0 ]; do
  case "$1" in
    -n | --dry-run) dry_run=1 ;;
    -f | --force) force=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    node | vite | claude) targets+=("$1") ;;
    *)
      echo "killall: unknown target or option '$1'" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [ "${#targets[@]}" -eq 0 ]; then
  echo "killall: pick at least one target" >&2
  usage >&2
  exit 1
fi

ppid_of() {
  # The comm field can contain spaces and parens, so cut everything up to the
  # closing paren; ppid is then the second remaining field.
  sed 's/^.*) //' "/proc/$1/stat" 2>/dev/null | awk '{print $2}'
}

cmdline() {
  { tr '\0' ' ' <"/proc/$1/cmdline" | sed 's/ *$//'; } 2>/dev/null
}

# The exe link is not always readable (sandboxes, namespaces), so fall back to
# argv[0] when it is missing.
binary_of() {
  local exe argv0
  exe="$(readlink "/proc/$1/exe" 2>/dev/null || true)"
  if [ -n "$exe" ]; then
    echo "${exe##*/}"
    return
  fi
  argv0="$(cut -d' ' -f1 <<<"$(cmdline "$1")")"
  echo "${argv0##*/}"
}

is_node() {
  case "$(binary_of "$1")" in
    node | nodejs) return 0 ;;
    *) return 1 ;;
  esac
}

is_vite() {
  [[ "$(cmdline "$1")" =~ (^|/|[[:space:]])vite(\.js)?([[:space:]]|$) ]]
}

is_claude() {
  local cmd
  cmd="$(cmdline "$1")"
  # The Electron desktop app shares the name but is not part of the dev loop.
  case "$cmd" in
    *claude-desktop*) return 1 ;;
  esac
  case "$(binary_of "$1")" in
    claude | claude.exe) return 0 ;;
  esac
  case "$cmd" in
    *@anthropic-ai/claude-code*) return 0 ;;
    *) return 1 ;;
  esac
}

matches() {
  local target
  for target in "${targets[@]}"; do
    "is_$target" "$1" && return 0
  done
  return 1
}

# Never kill the script itself or anything it runs inside of, since the shell
# hosting it may well be a target (claude, node, ...).
protected_pids() {
  local pid=$$
  while [ -n "$pid" ] && [ "$pid" -gt 1 ]; do
    echo "$pid"
    pid="$(ppid_of "$pid")"
  done
}

# Subshells this script spawns are not ancestors, but they carry our argv (and
# so would match their own target names), so skip our descendants too.
descends_from_self() {
  local pid="$1"
  while [ -n "$pid" ] && [ "$pid" -gt 1 ]; do
    [ "$pid" = "$$" ] && return 0
    pid="$(ppid_of "$pid")"
  done
  return 1
}

mapfile -t protected < <(protected_pids)

collect() {
  local pid
  for pid in $(pgrep -u "$(id -u)" -f . 2>/dev/null); do
    case " ${protected[*]} " in
      *" $pid "*) continue ;;
    esac
    descends_from_self "$pid" && continue
    [ -n "$(cmdline "$pid")" ] || continue
    matches "$pid" || continue
    echo "$pid"
  done
}

mapfile -t pids < <(collect)

if [ "${#pids[@]}" -eq 0 ]; then
  echo "No matching processes found."
  exit 0
fi

for pid in "${pids[@]}"; do
  printf '%7s  %s\n' "$pid" "$(cmdline "$pid")"
done

if [ "$dry_run" -eq 1 ]; then
  exit 0
fi

if [ "$force" -eq 1 ]; then
  kill -KILL "${pids[@]}" 2>/dev/null || true
  echo "Killed ${#pids[@]} process(es)."
  exit 0
fi

kill -TERM "${pids[@]}" 2>/dev/null || true

# Give them a couple of seconds to shut down, then insist.
remaining=()
for _ in $(seq 10); do
  remaining=()
  for pid in "${pids[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      remaining+=("$pid")
    fi
  done
  [ "${#remaining[@]}" -eq 0 ] && break
  sleep 0.2
done

if [ "${#remaining[@]}" -gt 0 ]; then
  kill -KILL "${remaining[@]}" 2>/dev/null || true
fi

echo "Killed ${#pids[@]} process(es)."

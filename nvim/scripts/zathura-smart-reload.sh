#!/usr/bin/env bash
# Drives Zathura's reload manually over D-Bus instead of relying on its own
# auto-reload-on-file-change (which is disabled via `set filemonitor noop` in
# zathurarc). Zathura's own reload handler discards the live scroll position
# and falls back to a separately tracked "remembered page" that only updates
# on link-clicks/synctex jumps, not normal scrolling -- so during continuous
# compilation it repeatedly snaps back to a stale position while reading.
#
# This re-opens the document via the dedicated OpenDocument D-Bus method,
# passing the page you were actually on as the target page, so the reopen
# lands there directly. (There is no `reload` input-bar command -- that's a
# keybinding-only shortcut, a different namespace from what ExecuteCommand
# accepts -- so this goes through the method built for exactly this instead.)
#
# Usage: zathura-smart-reload.sh /path/to/watched.pdf

set -u

pdf_path="$1"
pdf_name=$(basename "$pdf_path")

find_pid() {
	pgrep -nf "^zathura .*${pdf_name}" 2>/dev/null
}

busname_for() {
	echo "org.pwmt.zathura.PID-$1"
}

get_page() {
	busctl --user get-property "$1" /org/pwmt/zathura org.pwmt.zathura pagenumber 2>/dev/null | awk '{print $2}'
}

reopen_at_page() {
	busctl --user call "$1" /org/pwmt/zathura org.pwmt.zathura OpenDocument ssi "$2" "" "$3" >/dev/null 2>&1
}

# Baseline read on startup (not "skip the first change seen"): anything that
# changes the file's mtime AFTER this point is a real new compile and must
# trigger a reopen, including the very first one this daemon observes.
last_mtime=$(stat -c '%Y' "$pdf_path" 2>/dev/null)
pid=""

while true; do
	if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
		pid=$(find_pid)
		if [ -z "$pid" ]; then
			sleep 1
			continue
		fi
	fi

	busname=$(busname_for "$pid")
	cur_mtime=$(stat -c '%Y' "$pdf_path" 2>/dev/null)

	if [ -n "$cur_mtime" ] && [ "$cur_mtime" != "$last_mtime" ]; then
		page=$(get_page "$busname")
		reopen_at_page "$busname" "$pdf_path" "${page:-1}"
		last_mtime="$cur_mtime"
	fi

	sleep 0.3
done

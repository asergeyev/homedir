#!/bin/bash
# xbar plugin: latest semantic-version tag on the origin remote of every Go repo under ~/projects.

# <xbar.title>Go projects: latest origin tags</xbar.title>
# <xbar.version>v1.1</xbar.version>
# <xbar.author>alexs</xbar.author>
# <xbar.desc>Queries the origin remote of each ~/projects Go module and shows the highest semver tag per channel.</xbar.desc>
# <xbar.dependencies>git</xbar.dependencies>

# Tags here are channel-prefixed semver (prod-1.2.3, dev-1.2.3, onpremrc-1.2.3.4) as often as they are
# plain v1.2.3, so each tag is split into <channel><core> at its first N.N and ranked within its channel.
# Letter/number suffixes (prod-0.1.3a, prod-0.1.3-b) are later releases by local convention, not semver
# prereleases, so a plain version sort — which ranks them above the bare core — gives the right winner.

set -u

export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export LC_ALL=C
export GIT_TERMINAL_PROMPT=0
# Multiplex over one connection per host: 18 repos share a handful of remotes, and opening a separate
# session for each intermittently trips server-side connection throttling.
export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=5 \
	-o ControlMaster=auto -o ControlPath=/tmp/xbar-projtags-%C -o ControlPersist=20s"

PROJECTS_DIR="${PROJECTS_DIR:-$HOME/projects}"
MAX_JOBS=8
MAX_CHANNELS=6
FONT="font=Monaco size=12"

# Channels worth putting on a repo's headline, best first; anything else ranks after these.
# "release" (unprefixed / v-prefixed tags) sits below prod so a repo carrying both a deploy channel and
# a stray v-tag headlines what is actually deployed; repos with only release tags are unaffected.
CHANNEL_ORDER="prod staging stage dev"

# Highest tag per channel, as "channel<TAB>tag" lines ordered by CHANNEL_ORDER then name.
# Reads the raw "sha refs/tags/x" listing on stdin so each repo costs exactly one remote call.
channel_tags() {
	awk '{print $2}' |
		sed -e 's,^refs/tags/,,' -e 's,\^{}$,,' |
		sort -u |
		awk -F'\t' '
			# Split "onpremrc-1.2.3" into channel "onpremrc" and core "1.2.3"; skip tags with no N.N.
			{
				if (!match($0, /[0-9]+\.[0-9]+/)) next
				chan = substr($0, 1, RSTART - 1)
				core = substr($0, RSTART)
				sub(/[-._]$/, "", chan)
				if (chan == "" || chan == "v") chan = "release"
				printf "%s\t%s\t%s\n", chan, core, $0
			}' |
		sort -t$'\t' -k1,1 -k2,2V |
		awk -F'\t' '
			# Input is sorted, so the last row of each channel is that channel'"'"'s highest tag.
			{ if ($1 != prev && NR > 1) print out; prev = $1; out = $1 "\t" $3 }
			END { if (NR > 0) print out }' |
		sort -t$'\t' -k1,1 -f |
		awk -F'\t' -v order="$CHANNEL_ORDER" '
			BEGIN { n = split(order, o, " "); for (i = 1; i <= n; i++) rank[o[i]] = i }
			{ printf "%d\t%s\t%s\n", (($1 in rank) ? rank[$1] : 999), $1, $2 }' |
		sort -t$'\t' -k1,1n -s |
		cut -f2-
}

# Browsable tag page for an origin URL (git@host:path.git, ssh://…, https://…).
tag_url() {
	local remote=$1 tag=$2 base
	base=$(printf '%s' "$remote" |
		sed -e 's,^git@\([^:]*\):,https://\1/,' \
		    -e 's,^ssh://git@,https://,' \
		    -e 's,\.git$,,')
	case "$base" in
	https://*github.com/*) printf '%s/releases/tag/%s' "$base" "$tag" ;;
	https://*) printf '%s/-/tags/%s' "$base" "$tag" ;;
	*) printf '' ;;
	esac
}

# Emits "repo<TAB>status<TAB>channel<TAB>tag<TAB>url" — one row per channel, or one status row.
scan_repo() {
	local repo=$1 name remote refs tags chan tag
	name=$(basename "$repo")

	remote=$(git -C "$repo" remote get-url origin 2>/dev/null)
	if [ -z "$remote" ]; then
		printf '%s\tno-origin\t\t\t\n' "$name"
		return
	fi

	# One retry: a throttled remote fails fast, and a lone dropped connection should not read as an outage.
	refs=$(git -C "$repo" ls-remote --tags origin 2>/dev/null) ||
		refs=$(sleep 2; git -C "$repo" ls-remote --tags origin 2>/dev/null) || {
		printf '%s\tunreachable\t\t\t\n' "$name"
		return
	}
	if [ -z "$refs" ]; then
		printf '%s\tno-tags\t\t\t\n' "$name"
		return
	fi

	tags=$(printf '%s\n' "$refs" | channel_tags)
	if [ -z "$tags" ]; then
		printf '%s\tno-semver\t\t\t\n' "$name"
		return
	fi

	while IFS=$'\t' read -r chan tag; do
		[ -n "$tag" ] || continue
		printf '%s\tok\t%s\t%s\t%s\n' "$name" "$chan" "$tag" "$(tag_url "$remote" "$tag")"
	done <<<"$tags"
}

work_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$work_dir"' EXIT

for repo in "$PROJECTS_DIR"/*/; do
	# Skip dir if it's not git repo
	[ -d "$repo/.git" ] || continue
	# Skip GitHub-hosted repos: their tags are upstream releases, not our deploy channels.
	case "$(git -C "$repo" remote get-url origin 2>/dev/null)" in *github.com[:/]*) continue ;; esac
	# Skip non-Go repositories
	[ -f "$repo/go.mod" ] || continue
	while [ "$(jobs -pr | wc -l)" -ge "$MAX_JOBS" ]; do wait -n 2>/dev/null || break; done
	scan_repo "${repo%/}" >"$work_dir/$(basename "${repo%/}")" &
done
wait

results=$(cat "$work_dir"/* 2>/dev/null)

if [ -z "$results" ]; then
	echo "🏷 —"
	echo "---"
	echo "No Go repos under $PROJECTS_DIR | color=#888888"
	echo "Refresh | refresh=true"
	exit 0
fi

tagged=$(printf '%s\n' "$results" | awk -F'\t' '$2 == "ok" {seen[$1]} END {print length(seen)}')
total=$(printf '%s\n' "$results" | awk -F'\t' '{seen[$1]} END {print length(seen)}')
broken=$(printf '%s\n' "$results" | awk -F'\t' '$2 == "unreachable" {seen[$1]} END {print length(seen)}')

if [ "$broken" -gt 0 ]; then
	echo "🏷 $tagged/$total ⚠️$broken"
else
	echo "🏷 $tagged/$total"
fi

echo "---"
echo "Latest Origin Tags | refresh=true"
echo "---"

printf '%s\n' "$results" | sort -t$'\t' -k1,1f -s | awk -F'\t' -v font="$FONT" -v maxchan="$MAX_CHANNELS" '
	function flush(   i, extra) {
		if (repo == "") return
		if (status != "ok") {
			printf "%-26s %-12s | color=%s %s\n", repo, status,
				(status == "unreachable" ? "#cc6666" : "#888888"), font
		} else {
			printf "%-26s %s | %s%s\n", repo, tags[1], font, (urls[1] != "" ? " href=" urls[1] : "")
			for (i = 2; i <= n && i <= maxchan; i++)
				printf "--%-12s %s | %s%s\n", chans[i], tags[i], font, (urls[i] != "" ? " href=" urls[i] : "")
			extra = n - maxchan
			if (extra > 0) printf "--…%d more channels | color=#888888 %s\n", extra, font
		}
		repo = ""; n = 0
	}
	{
		if ($1 != repo) { flush(); repo = $1; status = $2 }
		if ($2 == "ok") { n++; chans[n] = $3; tags[n] = $4; urls[n] = $5 }
	}
	END { flush() }'

echo "---"

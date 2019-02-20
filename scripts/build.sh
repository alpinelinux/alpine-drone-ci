#!/bin/sh

set -eu

readonly APORTSDIR=$HOME/drone/aports
readonly REPOS="main community testing"
readonly MIRROR=http://dl-cdn.alpinelinux.org/alpine

msg() {
	local color=${2:-green}
	case "$color" in
		red) color="31";;
		green) color="32";;
		yellow) color="33";;
		blue) color="34";;
		*) color="32";;
	esac
	printf "\033[1;%sm>>>\033[1;0m %s\n" "$color" "$1" | xargs >&2
}

die() {
	msg "$1" red
	exit 1
}

get_release() {
	local branch=$DRONE_COMMIT_BRANCH
	case $branch in
		*-stable) echo v${branch%-*};;
		master) echo edge;;
		*) die "Branch \"$branch\" not supported!"
	esac
}

build_aport() {
	local repo="$1" aport="$2"
	cd "$APORTSDIR/$repo/$aport"
	sudo chown buildozer .
	abuild -r
}

changed_repos() {
	cd "$APORTSDIR"
	for repo in $REPOS; do
		git diff --exit-code remotes/origin/$DRONE_COMMIT_BRANCH -- $repo >/dev/null \
			|| echo "$repo"
	done
}

set_repositories_for() {
	local target_repo="$1" repos= repo=
	local release=$(get_release)
	for repo in $REPOS; do
		repos="$repos $MIRROR/$release/$repo"
		[ "$repo" = "$target_repo" ] && break
	done
	sudo sh -c "printf '%s\n' $repos > /etc/apk/repositories"
	sudo apk update
}

changed_aports() {
	cd "$APORTSDIR"
	local repo="$1"
	local aports=$(git diff --name-only --diff-filter=ACMR --relative="$repo" \
		remotes/origin/$DRONE_COMMIT_BRANCH -- "*/APKBUILD" | xargs -I% dirname %)
	ap builddirs -d "$APORTSDIR/$repo" $aports 2>/dev/null | xargs -I% basename % | xargs
}

setup_system() {
	sudo sh -c "echo $MIRROR/$(get_release)/main > /etc/apk/repositories"
	sudo apk -U upgrade -a || apk fix || die "Failed to up/downgrade system"
	abuild-keygen -ain
	sudo sed -i 's/JOBS=[0-9]*/JOBS=$(nproc)/' /etc/abuild.conf
	sudo install -do buildozer "$HOME"/drone/packages
}

sysinfo() {
	printf ">>> Host system information (arch: %s, release: %s) <<<\n" "$(apk --print-arch)" "$(get_release)"
	printf "- Number of Cores: %s\n" $(nproc)
	printf "- Memory: %s Gb\n" $(awk '/^MemTotal/ {print ($2/1024/1024)}' /proc/meminfo)
	printf "- Free space: %s\n" $(df -hP / | awk '/\/$/ {print $4}')
}

aport_ok=
aport_ng=

sysinfo || true
setup_system

for repo in $(changed_repos); do
	set_repositories_for "$repo"
	for pkgname in $(changed_aports "$repo"); do
		if build_aport "$repo" "$pkgname"; then
			checkapk || true
			aport_ok="$aport_ok $repo/$pkgname"
		else
			aport_ng="$aport_ng $repo/$pkgname"
		fi
	done
done

echo "### Build summary ###"

for ok in $aport_ok; do
	msg "$ok: build succesfully"
done

if [ -n "$aport_ng" ]; then
	die "Failed to build packages:$aport_ng"
elif [ -z "$aport_ok" ]; then
	die "No packages found to be built."
fi


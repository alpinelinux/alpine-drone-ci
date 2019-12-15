#!/bin/sh

set -eu

readonly APORTSDIR=$HOME/aports
readonly REPODEST=$HOME/packages
readonly REPOS="main community testing non-free"
readonly MIRROR=http://dl-cdn.alpinelinux.org/alpine
readonly REPOURL=https://github.com/alpinelinux/aports
readonly ARCH=$(apk --print-arch)
# Drone variables
readonly BRANCH=$DRONE_COMMIT_BRANCH
readonly PR=$DRONE_PULL_REQUEST

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
	case $BRANCH in
		*-stable) echo v${BRANCH%-*};;
		master) echo edge;;
		*) die "Branch \"$BRANCH\" not supported!"
	esac
}

build_aport() {
	local repo="$1" aport="$2"
	cd "$APORTSDIR/$repo/$aport"
	if abuild -r; then
		checkapk || true
		aport_ok="$aport_ok $repo/$aport"
	else
		aport_ng="$aport_ng $repo/$aport"
	fi
}

check_aport() {
	local repo="$1" aport="$2"
	cd "$APORTSDIR/$repo/$aport"
	if ! abuild check_arch 2>/dev/null; then
		aport_na="$aport_na $repo/$aport"
		return 1
	fi
}

changed_repos() {
	cd "$APORTSDIR"
	for repo in $REPOS; do
		git diff --exit-code remotes/origin/$BRANCH -- $repo >/dev/null \
			|| echo "$repo"
	done
}

set_repositories_for() {
	local target_repo="$1" repos= repo=
	local release=$(get_release)
	for repo in $REPOS; do
		[ "$repo" = "non-free" ] && continue
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
		remotes/origin/$BRANCH -- "*/APKBUILD" | xargs -I% dirname %)
	ap builddirs -d "$APORTSDIR/$repo" $aports 2>/dev/null | xargs -I% basename % | xargs
}

setup_system() {
	sudo sh -c "echo $MIRROR/$(get_release)/main > /etc/apk/repositories"
	sudo apk -U upgrade -a || apk fix || die "Failed to up/downgrade system"
	if [ -z "${PKG_SIGN_KEY:+x}" ]; then
		abuild-keygen -ain
	else
		echo Using pre-generated keys
		echo -e "${PKG_SIGN_KEY//$/\\n}" > ~/.abuild/drone.rsa
		echo PACKAGER_PRIVKEY=\"/home/buildozer/.abuild/drone.rsa\" > ~/.abuild/abuild.conf
	fi
	sudo sed -i 's/JOBS=[0-9]*/JOBS=$(nproc)/' /etc/abuild.conf
	mkdir -p "$REPODEST"
}

create_workspace() {
	msg "Cloning aports and applying PR$PR"
	git clone --depth=1 --branch "$BRANCH" "$REPOURL" "$APORTSDIR"
	wget -qO- "$REPOURL"/pull/"$PR".patch | git -C "$APORTSDIR" am --3way
}

sysinfo() {
	printf ">>> Host system information (arch: %s, release: %s) <<<\n" "$ARCH" "$(get_release)"
	printf "- Number of Cores: %s\n" $(nproc)
	printf "- Memory: %s Gb\n" $(awk '/^MemTotal/ {print ($2/1024/1024)}' /proc/meminfo)
	printf "- Free space: %s\n" $(df -hP / | awk '/\/$/ {print $4}')
}

aport_ok=
aport_na=
aport_ng=
failed=

sysinfo || true
setup_system || die "Failed to setup system"
create_workspace || die "Failed to create workspace"

for repo in $(changed_repos); do
	set_repositories_for "$repo"
	for pkgname in $(changed_aports "$repo"); do
		if check_aport "$repo" "$pkgname"; then
			build_aport "$repo" "$pkgname"
		fi
	done
done

echo "### Build summary ###"

for ok in $aport_ok; do
	msg "$ok: build succesfully"
done

for na in $aport_na; do
	msg "$na: disabled for $ARCH" yellow
done

for ng in $aport_ng; do
	msg "$ng: build failed" red
	failed=true
done

if [ "$failed" = true ]; then
	exit 1
elif [ -z "$aport_ok" ]; then
	msg "No packages found to be built." yellow
fi


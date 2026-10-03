#!/bin/bash

set -euo pipefail

readonly UBUNTU_VERSION="${UBUNTU_VERSION:-24.04}"
readonly IMAGE="dotfiles-test:$UBUNTU_VERSION"
readonly TEST_USER="tester"
readonly REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REMOTE_URL="https://raw.githubusercontent.com/thebinoculars/dotfiles/refs/heads/master/install.sh"

usage() {
	cat <<EOF
Runs install.sh in a throwaway Ubuntu container. Nothing is kept after exit.

Usage: ./test.sh [local|remote|shell]
  local    Install from this working copy, mounted read-only (default)
  remote   Install with the remote one-liner, from GitHub master
  shell    Open a shell in a clean container with this working copy at /dotfiles,
           to run install.sh (or parts of it) by hand

Env:
  UBUNTU_VERSION   Ubuntu release to test on (default: 24.04)
EOF
}

# Mimics a fresh Ubuntu install: a sudo user, the base tools it ships with, empty apt lists,
# and no docker-image doc excludes (some packages ship needed files under /usr/share/doc)
build_image() {
	docker build -q -t "$IMAGE" - >/dev/null <<EOF
FROM ubuntu:$UBUNTU_VERSION
RUN rm -f /etc/dpkg/dpkg.cfg.d/excludes \\
	&& apt-get update \\
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y sudo git curl wget ca-certificates file procps tzdata \\
	&& rm -rf /var/lib/apt/lists/* \\
	&& useradd -m -s /bin/bash $TEST_USER \\
	&& echo "$TEST_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$TEST_USER
USER $TEST_USER
ENV USER=$TEST_USER
WORKDIR /home/$TEST_USER
EOF
}

main() {
	local mode="${1:-local}" cmd
	local -a mounts=()

	case "$mode" in
	local)
		mounts=(-v "$REPO_DIR:/dotfiles:ro")
		cmd="cd /dotfiles && ./install.sh"
		;;
	remote) cmd="bash -c \"\$(curl -fsSL $REMOTE_URL)\"" ;;
	shell)
		mounts=(-v "$REPO_DIR:/dotfiles:ro")
		cmd="echo 'Repo mounted read-only at /dotfiles. Run: /dotfiles/install.sh'"
		;;
	-h | --help) usage; exit 0 ;;
	*) usage; exit 1 ;;
	esac

	command -v docker >/dev/null 2>&1 || { echo "Docker is required: install it with ./install.sh (docker package)" >&2; exit 1; }
	docker info >/dev/null 2>&1 || { echo "Docker is not running, or $USER is not in the docker group (log out and back in after install)" >&2; exit 1; }

	echo "Building $IMAGE..."
	build_image

	# Stay in the container afterwards, in the user's login shell, to inspect the result
	docker run --rm -it "${mounts[@]}" "$IMAGE" \
		bash -lc "$cmd; exec \"\$(getent passwd \"\$USER\" | cut -d: -f7)\" -l"
}

main "$@"

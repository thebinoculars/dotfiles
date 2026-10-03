#!/bin/bash

set -o pipefail

readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[0;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'
readonly REPO_URL="https://github.com/thebinoculars/dotfiles.git"
readonly SCRIPTS_PATH=".install.d"
# Emptied on every install, so files removed from the repo disappear
readonly REBUILT_PATHS=(".zshrc.d" "$SCRIPTS_PATH")

# mise and its tools, usable as soon as they are installed
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"
readonly LIST_DELIMITER=","
readonly CORE_PACKAGES=(curl mise gum git zsh)

REPO_DIR=""
TEMP_DIR=""
CONFIG_FILE=""
HOME_DIR=""
SCRIPTS_DIR=""

declare -A SEEN=()
declare -A VARS=()
declare -A PASSED_VARS=()

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
die() { error "$1"; exit 1; }

cleanup() {
	[ -n "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
	TEMP_DIR=""
}

get_config() {
	local pkg="$1" key="$2"
	awk -v section="[$pkg]" -v key="$key" '
		$0 == section { found=1; next }
		/^\[/ && found { exit }
		found && $0 ~ "^" key "=" { sub("^" key "=", ""); print; exit }
	' "$CONFIG_FILE"
}

all_packages() {
	grep -o '^\[[^]]*\]' "$CONFIG_FILE" | tr -d '[]'
}

list_packages() {
	awk -v core=" ${CORE_PACKAGES[*]} " '
		function flush() { if (pkg != "" && index(core, " " pkg " ") == 0) print pkg " - " desc }
		/^\[/ { flush(); pkg=substr($0, 2, length($0) - 2); desc=""; next }
		/^description=/ { desc=substr($0, 13) }
		END { flush() }
	' "$CONFIG_FILE"
}

get_check_command() {
	local pkg="$1"
	local check_cmd=$(get_config "$pkg" "check")

	if [ -n "$check_cmd" ]; then
		echo "$check_cmd"
	elif [ "$(get_method "$pkg")" = "apt" ]; then
		echo "( for p in $(get_spec "$pkg"); do dpkg-query -W -f='\${Status}' \$p | grep -q 'install ok installed' || exit 1; done )"
	else
		echo "command -v $pkg"
	fi
}

load_variables() {
	local pkg pair key pairs

	for pkg in $(all_packages); do
		IFS="$LIST_DELIMITER" read -ra pairs <<< "$(get_config "$pkg" "variables")"
		for pair in "${pairs[@]}"; do
			key="${pair%%=*}"
			[ -n "${VARS[$key]+x}" ] && continue

			if [ -n "${!key+x}" ]; then
				VARS[$key]="${!key}"
				PASSED_VARS[$key]=1
			else
				VARS[$key]="${pair#*=}"
				export "$key=${VARS[$key]}"
			fi
		done
	done
}

get_method() {
	local method=$(get_config "$1" "method")
	echo "${method:-mise}"
}

get_spec() {
	local spec=$(get_config "$1" "spec")
	echo "${spec:-$1}"
}

expand_dependencies() {
	local pkg
	local -a deps
	for pkg in "$@"; do
		[ -n "$pkg" ] && [ -z "${SEEN[$pkg]}" ] || continue
		SEEN[$pkg]=1
		IFS="$LIST_DELIMITER" read -ra deps <<< "$(get_config "$pkg" "depends_on")"
		expand_dependencies "${deps[@]}"
		echo "$pkg"
	done
}

# Takes the list as arguments: installers read stdin and would consume a piped list
install_package_list() {
	local pkg method specs
	local -a pkgs missing=() apt=() mise=()

	mapfile -t pkgs < <(expand_dependencies "${@%% - *}")
	for pkg in "${pkgs[@]}"; do
		if eval "$(get_check_command "$pkg")" >/dev/null 2>&1; then
			log "$pkg already installed, skipping"
			continue
		fi

		missing+=("$pkg")
		method=$(get_method "$pkg")
		case "$method" in
		apt) read -ra specs <<< "$(get_spec "$pkg")"; apt+=("${specs[@]}") ;;
		mise) mise+=("$(get_spec "$pkg")") ;;
		script) [ -f "$SCRIPTS_DIR/$pkg.sh" ] || die "No script found for $pkg" ;;
		*) die "Unknown method for $pkg: $method" ;;
		esac
	done

	if [ ${#apt[@]} -gt 0 ]; then
		log "Installing with apt: ${apt[*]}"
		sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${apt[@]}" || die "Failed to install ${apt[*]}"
	fi
	if [ ${#mise[@]} -gt 0 ]; then
		log "Installing with mise: ${mise[*]}"
		mise use -g "${mise[@]}" || die "Failed to install ${mise[*]}"
	fi

	for pkg in "${missing[@]}"; do
		if [ -f "$SCRIPTS_DIR/$pkg.sh" ]; then
			log "Running install script of $pkg..."
			bash "$SCRIPTS_DIR/$pkg.sh" || die "Failed to install $pkg"
		fi
		success "Installed $pkg"
	done
}

# One at a time: each one needs the previous ones
install_core_packages() {
	local pkg
	log "Installing core packages..."
	sudo apt-get update || die "Failed to update apt package lists"
	for pkg in "${CORE_PACKAGES[@]}"; do
		install_package_list "$pkg"
	done
}

install_selected_packages() {
	local -a packages
	log "Select packages to install"
	mapfile -t packages < <(list_packages false | gum choose --no-limit --height 15)
	install_package_list "${packages[@]}"
}

resolve_repo() {
	log "Preparing resources..."

	# BASH_SOURCE is empty when run through `bash -c "$(curl ...)"`
	local script_dir=""
	if [ -n "${BASH_SOURCE[0]}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
		script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
	fi

	if is_repo_dir "$PWD"; then
		REPO_DIR="$PWD"
	elif is_repo_dir "$script_dir"; then
		REPO_DIR="$script_dir"
	else
		log "Cloning repository..."
		TEMP_DIR=$(mktemp -d)
		trap cleanup EXIT
		git clone --depth=1 "$REPO_URL" "$TEMP_DIR" || die "Failed to clone repository"
		REPO_DIR="$TEMP_DIR"
	fi

	is_repo_dir "$REPO_DIR" || die "Invalid repository structure in $REPO_DIR"
	log "Using files in $REPO_DIR"

	CONFIG_FILE="$REPO_DIR/config.ini"
	HOME_DIR="$REPO_DIR/home"
	SCRIPTS_DIR="$HOME_DIR/$SCRIPTS_PATH"
}

is_repo_dir() {
	[ -n "$1" ] && [ -f "$1/config.ini" ] && [ -d "$1/home" ]
}

render_file() {
	local src="$1" out="$2" var value unresolved

	cp "$src" "$out"
	for var in "${!VARS[@]}"; do
		value=$(printf '%s\n' "${VARS[$var]}" | sed 's/[\/&]/\\&/g')
		sed -i "s/{{$var}}/$value/g" "$out"
	done

	unresolved=$(grep -o '{{[A-Za-z_][A-Za-z0-9_]*}}' "$out" | sort -u | tr '\n' ' ')
	if [ -n "$unresolved" ]; then
		warn "Undeclared variables in ${src#$REPO_DIR/}: $unresolved"
	fi
}

# A file with {{VARIABLES}} is only overwritten when all of them are passed,
# so values already in $HOME (from a previous install or edited by hand) are kept
can_overwrite() {
	local src="$1" dest="$2" var
	local -a used=() missing=()

	for var in $(grep -o '{{[A-Za-z_][A-Za-z0-9_]*}}' "$src" | tr -d '{}' | sort -u); do
		[ -n "${VARS[$var]+x}" ] || continue
		used+=("$var")
		[ -n "${PASSED_VARS[$var]}" ] || missing+=("$var")
	done

	[ ${#missing[@]} -eq 0 ] && return 0

	if [ ${#missing[@]} -lt ${#used[@]} ]; then
		warn "Keeping $dest: also pass ${missing[*]} to overwrite it"
	else
		log "Keeping $dest: pass ${used[*]} to overwrite it"
	fi
	return 1
}

install_file() {
	local src="$1" dest="$2" rendered
	rendered=$(mktemp)
	render_file "$src" "$rendered"

	if ! cmp -s "$rendered" "$dest" && { [ ! -f "$dest" ] || can_overwrite "$src" "$dest"; }; then
		mkdir -p "$(dirname "$dest")"
		if [ -f "$dest" ]; then
			cp "$dest" "$dest.bak.$(date +%s)"
			log "Backing up existing file: $dest"
		fi
		cp "$rendered" "$dest"
	fi
	rm -f "$rendered"
}

install_files() {
	local path src
	log "Installing files..."

	for path in "${REBUILT_PATHS[@]}"; do
		rm -rf "${HOME:?}/$path"
	done

	while IFS= read -r src; do
		install_file "$src" "$HOME/${src#"$HOME_DIR/"}"
	done < <(find "$HOME_DIR" -type f)
}

main() {
	command -v git >/dev/null 2>&1 || die "git is required but not installed. Please install git first."

	resolve_repo
	load_variables
	install_core_packages
	install_selected_packages
	install_files

	success "Dotfiles installation complete!"

	if gum confirm "Reload terminal now?"; then
		# exec skips the EXIT trap
		cleanup
		exec zsh
	fi
}

main "$@"

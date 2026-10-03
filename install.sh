#!/bin/bash

set -o pipefail

readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[0;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'
readonly REPO_URL="https://github.com/thebinoculars/dotfiles.git"
readonly LOCAL_BIN_DIR="$HOME/.local/bin"
readonly ZSH_DIR="$HOME/.zsh"
readonly LIST_DELIMITER=","

REPO_DIR=""
TEMP_DIR=""
CONFIG_FILE=""
PACKAGES_DIR=""

declare -A PROCESSED=()
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

# --- config.ini -------------------------------------------------------------

get_config() {
	local pkg="$1" key="$2"
	awk -v section="[$pkg]" -v key="$key" '
		$0 == section { found=1; next }
		/^\[/ && found { exit }
		found && $0 ~ "^" key "=" { sub("^" key "=", ""); print; exit }
	' "$CONFIG_FILE"
}

has_package() {
	grep -qxF "[$1]" "$CONFIG_FILE"
}

all_packages() {
	grep -o '^\[[^]]*\]' "$CONFIG_FILE" | tr -d '[]'
}

# Prints "pkg - description" for packages whose `required` value is $1
list_packages() {
	awk -v want="$1" '
		function flush() { if (pkg != "" && req == want) print pkg " - " desc }
		/^\[/ { flush(); pkg=substr($0, 2, length($0) - 2); desc=""; req="false"; next }
		/^description=/ { desc=substr($0, 13) }
		/^required=/ { req=substr($0, 10) }
		END { flush() }
	' "$CONFIG_FILE"
}

get_check_command() {
	local pkg="$1"
	local check_cmd=$(get_config "$pkg" "check")

	if [ -n "$check_cmd" ]; then
		echo "$check_cmd"
	elif [ "$(get_config "$pkg" "method")" = "apt" ]; then
		echo "dpkg-query -W -f='\${Status}' $pkg | grep -q 'install ok installed'"
	else
		echo "command -v $pkg"
	fi
}

# --- variables --------------------------------------------------------------

# A variable takes its value from the environment, or its default in config.ini
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

# --- packages ---------------------------------------------------------------

run_script() {
	local script="$PACKAGES_DIR/$1/install.sh"
	[ -f "$script" ] || die "No script found for $1"
	bash "$script"
}

install_by_method() {
	local pkg="$1" method="$2" url="$3"

	case "$method" in
	"" | script) run_script "$pkg" ;;
	apt) sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" ;;
	brew) brew install "$pkg" ;;
	eget)
		[ -n "$url" ] || die "URL required for eget: $pkg"
		mkdir -p "$LOCAL_BIN_DIR"
		eget "$url" --to "$LOCAL_BIN_DIR/"
		;;
	*) eval "$method" ;;
	esac
}

install_package() {
	local pkg="$1"
	[ -n "${PROCESSED[$pkg]}" ] && return

	log "Installing $pkg..."

	local method=$(get_config "$pkg" "method")
	local url=$(get_config "$pkg" "url")
	local setup_cmd=$(get_config "$pkg" "setup")
	local deps=$(get_config "$pkg" "depends_on")
	local dep_list dep

	# The tool a method runs (brew, eget, curl...) must be installed first
	local tool="${method%% *}"
	if [ "$tool" != "$pkg" ] && has_package "$tool"; then
		deps="$tool$LIST_DELIMITER$deps"
	fi

	IFS="$LIST_DELIMITER" read -ra dep_list <<< "$deps"
	for dep in "${dep_list[@]}"; do
		install_package "$dep"
	done

	if eval "$(get_check_command "$pkg")" >/dev/null 2>&1; then
		log "$pkg already installed, skipping"
	elif install_by_method "$pkg" "$method" "$url"; then
		success "Installed $pkg"
	else
		die "Failed to install $pkg"
	fi

	if [ -n "$setup_cmd" ]; then
		eval "$setup_cmd" || die "Failed to set up $pkg"
	fi

	PROCESSED[$pkg]=1
}

# Lists are read into arrays first: installers read stdin and would consume a piped list
install_package_list() {
	local line
	for line in "$@"; do
		[ -n "$line" ] && install_package "${line%% - *}"
	done
}

install_required_packages() {
	local -a packages
	log "Installing required packages..."
	sudo apt-get update || die "Failed to update apt package lists"
	mapfile -t packages < <(list_packages true)
	install_package_list "${packages[@]}"
}

install_selected_packages() {
	local -a packages
	log "Select packages to install"
	mapfile -t packages < <(list_packages false | gum choose --no-limit --height 15)
	install_package_list "${packages[@]}"
}

# --- files ------------------------------------------------------------------

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
	PACKAGES_DIR="$REPO_DIR/packages"
}

is_repo_dir() {
	[ -n "$1" ] && [ -f "$1/config.ini" ] && [ -d "$1/packages" ]
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

# Every file in packages/<pkg>/ except install.sh is copied to the same path in $HOME.
# Snippet dirs are emptied first so snippets removed from the repo disappear;
# top-level ~/.zsh/*.zsh files are leftovers from an older layout.
install_files() {
	local pkg_dir src dest rendered
	log "Installing files..."

	rm -rf "$ZSH_DIR/env" "$ZSH_DIR/init"
	rm -f "$ZSH_DIR"/*.zsh

	for pkg_dir in "$PACKAGES_DIR"/*/; do
		while IFS= read -r src; do
			dest="$HOME/${src#"$pkg_dir"}"
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
		done < <(find "$pkg_dir" -type f ! -path "${pkg_dir}install.sh")
	done
}

main() {
	command -v git >/dev/null 2>&1 || die "git is required but not installed. Please install git first."

	resolve_repo
	load_variables
	install_required_packages
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

#!/bin/bash

readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'
readonly CONFIG_FILE="config.yml"
readonly ZSH_TEMP_FILE="/tmp/dotfiles_zshrc.tmp"

declare -a PROCESSED=()
declare -a DOTFILES_ENV_VARS=()

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

append_zsh() {
	cat >>"$ZSH_TEMP_FILE"
}
export -f append_zsh

install_by_method() {
	local pkg_name="$1"
	local method="$2"
	local url="$3"

	case "$method" in
	apt)
		sudo apt-get install -y "$pkg_name"
		;;
	brew)
		brew install "$pkg_name"
		;;
	snap)
		sudo snap install "$pkg_name"
		;;
	eget)
		[ "$url" != "null" ] && sudo eget "$url" --to /usr/local/bin/ || error "URL required for eget method in $pkg_name"
		;;
	*)
		local script_file="scripts/$pkg_name.sh"
		if [ -f "$script_file" ]; then
			chmod +x "$script_file" && source "$script_file"
		else
			error "Script not found: $script_file"
		fi
		;;
	esac
}

bootstrap() {
	log "Installing bootstrap packages..."
	
	command -v brew >/dev/null 2>&1 || install_by_method "brew"
	command -v eget >/dev/null 2>&1 || install_by_method "eget" "brew"
	command -v yq >/dev/null 2>&1 || install_by_method "yq" "brew"
	command -v gum >/dev/null 2>&1 || install_by_method "gum" "brew"
	command -v zsh >/dev/null 2>&1 || install_by_method "zsh" "apt"
	[ ! -d "$HOME/.oh-my-zsh" ] && install_by_method "oh-my-zsh"
	[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ] && install_by_method "p10k"
	
	PROCESSED+=("brew" "eget" "yq" "gum" "zsh" "oh-my-zsh" "p10k")
}

get_package_config() {
	local pkg_name="$1"
	local key="$2"
	yq -r ".\"$pkg_name\".\"$key\"" "$CONFIG_FILE" 2>/dev/null || echo "null"
}

load_package_variables() {
	local pkg_name="$1"
	local var_keys=$(yq -r ".\"$pkg_name\".variables | keys | .[]" "$CONFIG_FILE" 2>/dev/null || true)
	
	for key in $var_keys; do
		local value=$(yq -r ".\"$pkg_name\".variables.\"$key\"" "$CONFIG_FILE")
		
		if [ -z "${!key+x}" ]; then
			export "$key=$value"
		fi
		
		DOTFILES_ENV_VARS+=("\$$key")
	done
}

install_dependencies() {
	local pkg_name="$1"
	local deps=$(yq -r ".\"$pkg_name\".depends_on[]" "$CONFIG_FILE" 2>/dev/null || true)
	
	for dep in $deps; do
		install_package "$dep"
	done
}

install_package() {
	local pkg_name="$1"
	
	if [[ " ${PROCESSED[*]} " =~ " ${pkg_name} " ]]; then
		return
	fi
	
	log "Installing $pkg_name..."
	
	load_package_variables "$pkg_name"
	install_dependencies "$pkg_name"
	
	local method=$(get_package_config "$pkg_name" "method")
	local url=$(get_package_config "$pkg_name" "url")
	
	install_by_method "$pkg_name" "$method" "$url"
	
	success "Installed $pkg_name"
	PROCESSED+=("$pkg_name")
}

load_all_variables() {
	log "Loading all variables..."
	local pkgs=$(yq -r 'to_entries[].key' "$CONFIG_FILE")
	
	for pkg in $pkgs; do
		load_package_variables "$pkg"
	done
}

process_all_mappings() {
	log "Copying files and replacing managed env vars..."
	
	[ ! -d "files" ] && return
	
	find files -type f | while read -r src; do
		local rel="${src#files/}"
		local dest="$HOME/$rel"
		
		mkdir -p "$(dirname "$dest")"
		[ -f "$dest" ] && cp "$dest" "$dest.bak"
		
		cp "$src" "$dest"
		
		if [ -n "$ENV_SUBST_VARS" ]; then
			envsubst "$ENV_SUBST_VARS" <"$dest" >"$dest.tmp" && mv "$dest.tmp" "$dest"
		fi
	done
}

add_package_sources() {
	log "Appending zsh config to .zshrc..."
	
	local zshrc="$HOME/.zshrc"
	
	if [ -s "$ZSH_TEMP_FILE" ]; then
		{
			echo ""
			cat "$ZSH_TEMP_FILE"
		} >>"$zshrc"
	fi
	
	success "Zsh config updated"
}

main() {
	[ ! -f "$CONFIG_FILE" ] && error "Missing config.yml" && exit 1
	
	> "$ZSH_TEMP_FILE"
	
	bootstrap
	
	log "Select packages to install"
	local selected=$(
		yq -r 'to_entries[] | .key + " - " + .value.description' "$CONFIG_FILE" |
			gum choose --no-limit --height 15 |
			awk -F ' - ' '{print $1}'
	)
	
	[ -z "$selected" ] && log "Nothing selected" && exit 0
	
	for pkg in $selected; do
		install_package "$pkg"
	done
	
	load_all_variables
	ENV_SUBST_VARS=$(printf '%s ' "${DOTFILES_ENV_VARS[@]}")
	
	process_all_mappings
	add_package_sources
	
	success "Dotfiles installation complete!"
}

main
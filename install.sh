#!/bin/bash

readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'
readonly CONFIG_FILE="config.ini"

declare -A PROCESSED=()
declare -a DOTFILES_ENV_VARS=()
declare -a INSTALLED_PACKAGES=()

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

download_resources() {
	log "Preparing resources..."
	
	if [ -d ".git" ] || [ -d "files" ]; then
		log "Using local files"
		[ ! -f "$CONFIG_FILE" ] && { error "Local config.ini not found"; exit 1; }
	else
		log "Cloning repository..."
		local temp_dir=$(mktemp -d)
		trap 'rm -rf "$temp_dir"' EXIT
		
		git clone https://github.com/thebinoculars/dotfiles.git "$temp_dir" || {
			error "Failed to clone repository"
			exit 1
		}
		
		cp -r "$temp_dir/files" .
		cp "$temp_dir/$CONFIG_FILE" .
		[ -d "$temp_dir/scripts" ] && cp -r "$temp_dir/scripts" .
		
		log "Repository cloned successfully"
	fi
	
	[ ! -f "$CONFIG_FILE" ] && { error "config.ini not found"; exit 1; }
	[ ! -d "files" ] && { error "files directory not found"; exit 1; }
}

get_config() {
	local pkg="$1" key="$2"
	awk -v section="[$pkg]" -v key="$key" '
		$0 == section { found=1; next }
		/^\[/ && found { exit }
		found && $0 ~ "^" key "=" { sub("^" key "=", ""); print; exit }
	' "$CONFIG_FILE"
}

install_by_method() {
	local pkg="$1" method="$2" url="$3"
	
	if [ -z "$method" ]; then
		run_script "$pkg"
	else
		case "$method" in
		apt) sudo apt-get install -y "$pkg" ;;
		brew) brew install "$pkg" ;;
		snap) sudo snap install "$pkg" ;;
		eget) if [ -n "$url" ]; then
			sudo eget "$url" --to /usr/local/bin/
		else
			error "URL required for eget: $pkg"
			return 1
		fi ;;
		script) run_script "$pkg" ;;
		*) eval "$method" ;;
		esac
	fi
}

run_script() {
	local pkg="$1"
	local script="scripts/$pkg.sh"
	if [ -f "$script" ]; then
		chmod +x "$script" && source "$script"
	else
		error "No script found for $pkg"
		return 1
	fi
}

add_all_zsh_sources() {
	if [ -d "files/.zsh" ]; then
		mkdir -p "$HOME/.zsh"
		cp -r files/.zsh/* "$HOME/.zsh/" 2>/dev/null || true
	fi
	
	local zshrc="$HOME/.zshrc"
	for zsh_file in "$HOME/.zsh/"*.zsh; do
		[ ! -f "$zsh_file" ] && continue
		local pkg=$(basename "$zsh_file" .zsh)
		
		local check_cmd=$(get_config "$pkg" "check")
		[ -z "$check_cmd" ] && check_cmd="command -v $pkg"
		
		if eval "$check_cmd" >/dev/null 2>&1; then
			grep -q "source ~/.zsh/$pkg.zsh" "$zshrc" 2>/dev/null || {
				echo "source ~/.zsh/$pkg.zsh" >> "$zshrc"
				log "Added source for $pkg.zsh"
			}
		fi
	done
}

install_package() {
	local pkg="$1"
	
	[ -n "${PROCESSED[$pkg]}" ] && return
	
	log "Installing $pkg..."
	
	local vars=$(get_config "$pkg" "variables")
	if [ -n "$vars" ]; then
		IFS=',' read -ra pairs <<< "$vars"
		for pair in "${pairs[@]}"; do
			local key="${pair%=*}" value="${pair#*=}"
			if [ -n "${!key+x}" ]; then
				log "Using env var $key=${!key}"
			else
				export "$key=$value"
			fi
			DOTFILES_ENV_VARS+=("\$$key")
		done
	fi
	
	local deps=$(get_config "$pkg" "depends_on")
	if [ -n "$deps" ]; then
		IFS=',' read -ra dep_array <<< "$deps"
		for dep in "${dep_array[@]}"; do
			install_package "$dep"
		done
	fi
	
	local check_cmd=$(get_config "$pkg" "check")
	[ -z "$check_cmd" ] && check_cmd="command -v $pkg"
	
	if eval "$check_cmd" >/dev/null 2>&1; then
		log "$pkg already installed, skipping"
		PROCESSED[$pkg]=1
		INSTALLED_PACKAGES+=("$pkg")
		return
	fi
	
	local method=$(get_config "$pkg" "method")
	local url=$(get_config "$pkg" "url")
	
	if install_by_method "$pkg" "$method" "$url"; then
		success "Installed $pkg"
	else
		error "Failed to install $pkg"
		return 1
	fi
	
	PROCESSED[$pkg]=1
	INSTALLED_PACKAGES+=("$pkg")
}

bootstrap() {
	log "Installing bootstrap packages..."
	install_package "brew"
	install_package "eget"
	install_package "gum"
	install_package "zsh"
	install_package "oh-my-zsh"
	install_package "p10k"
}

process_files() {
	log "Processing config files..."
	
	declare -A VARS
	local pkgs=$(grep -o '^\[[^]]*\]' "$CONFIG_FILE" | tr -d '[]')
	for pkg in $pkgs; do
		local vars=$(get_config "$pkg" "variables")
		[ -n "$vars" ] && {
			IFS=',' read -ra pairs <<< "$vars"
			for pair in "${pairs[@]}"; do
				local key="${pair%=*}" value="${pair#*=}"
				if [ -n "${!key+x}" ]; then
					VARS["$key"]="${!key}"
				else
					export "$key=$value"
					VARS["$key"]="$value"
				fi
			done
		}
	done
	
	[ ! -d "files" ] && return
	
	find files -type f -not -path "files/.zsh/*" | while read -r src; do
		local rel="${src#files/}"
		local dest="$HOME/$rel"
		
		mkdir -p "$(dirname "$dest")"
		[ -f "$dest" ] && cp "$dest" "$dest.bak.$(date +%s)"
		
		cp "$src" "$dest"
		
		for var in "${!VARS[@]}"; do
			local escaped_value
			escaped_value=$(printf '%s\n' "${VARS[$var]}" | sed 's/[][\/.^$*+?{}()|]/\\&/g')
			sed -i "s/\$$var/$escaped_value/g" "$dest"
		done
	done
}

main() {
	download_resources
	bootstrap
	
	log "Select packages to install"
	local selected=$(
		awk -F= '/^\[/{pkg=substr($0,2,length($0)-2)} /^description=/{print pkg " - " $2}' "$CONFIG_FILE" |
			gum choose --no-limit --height 15 |
			awk -F ' - ' '{print $1}'
	)
	
	[ -z "$selected" ] && { log "Nothing selected"; exit 0; }
	
	for pkg in $selected; do
		install_package "$pkg"
	done
	
	process_files
	add_all_zsh_sources
	
	success "Dotfiles installation complete!"
}

main

#!/bin/bash
# =============================================================================
# DOTFILES INSTALLATION SCRIPT
# =============================================================================

# Colors for output
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly NC='\033[0m' # No Color

# Configuration
readonly CONFIG_FILE="config.yml"
declare -a PROCESSED=()

# Fixed options
SKIP_SCRIPTS=false

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# =============================================================================
# PACKAGE INSTALLATION FUNCTIONS
# =============================================================================

install_by_method() {
	local pkg_name="$1"
	local method="$2"
	local url="$3"

	case "$method" in
	"apt") eval "sudo apt-get install -y \"$pkg_name\"" ;;
	"brew") eval "brew install \"$pkg_name\"" ;;
	"snap") eval "sudo snap install \"$pkg_name\"" ;;
	"eget")
		[ "$url" != "null" ] && (eval "sudo eget \"$url\" --to \"/usr/local/bin/\"") || error "URL required for eget method in $pkg_name"
		;;
	*)
		local script_file="scripts/$pkg_name.sh"
		if [ -f "$script_file" ]; then
			log "Running custom script for $pkg_name..."
			chmod +x "$script_file"
			source "$script_file"
		else
			error "Custom script not found: $script_file"
		fi
		;;
	esac
}

bootstrap() {
	log "Installing bootstrap packages..."

	local bootstrap_packages="brew eget yq gum oh-my-zsh p10k"

	for pkg in $bootstrap_packages; do
		if ! command -v "$pkg" >/dev/null 2>&1; then
			log "Installing $pkg..."
			case "$pkg" in
			"brew" | "oh-my-zsh" | "p10k")
				install_by_method "$pkg"
				;;
			*)
				install_by_method "$pkg" "brew"
				;;
			esac
			PROCESSED+=("$pkg")
			success "Installed $pkg"
		else
			success "$pkg is already installed."
			PROCESSED+=("$pkg")
		fi
	done
}

get_package_config() {
	local pkg_name="$1"
	local key="$2"
	yq -r ".\"$pkg_name\".\"$key\"" "$CONFIG_FILE" 2>/dev/null || echo "null"
}

is_package_installed() {
	local pkg_name="$1"
	local check_cmd=$(get_package_config "$pkg_name" "check")

	if [ "$check_cmd" != "null" ]; then
		eval "$check_cmd"
	else
		command -v "$pkg_name"
	fi
}

load_package_variables() {
	local pkg_name="$1"
	local var_keys=$(yq -r ".\"$pkg_name\".variables | keys | .[]" "$CONFIG_FILE" 2>/dev/null || echo "")

	for key in $var_keys; do
		if [ "$key" != "null" ] && [ -n "$key" ]; then
			local value=$(yq -r ".\"$pkg_name\".variables.\"$key\"" "$CONFIG_FILE")
			eval "export $key=\"$value\""
			log "Exported variable: $key=$value"
		fi
	done
}

install_dependencies() {
	local pkg_name="$1"
	local depends_on=$(yq -r ".\"$pkg_name\".depends_on[]" "$CONFIG_FILE" 2>/dev/null || echo "")

	for dep in $depends_on; do
		if [ "$dep" != "null" ] && [ -n "$dep" ]; then
			log "Dependency required: $dep for $pkg_name"
			install_package "$dep"
		fi
	done
}

install_package() {
	local pkg_name="$1"

	# Skip if already processed
	if [[ " ${PROCESSED[@]} " =~ " ${pkg_name} " ]]; then
		return
	fi

	# Check if already installed
	if is_package_installed "$pkg_name"; then
		success "$pkg_name is already installed."
		PROCESSED+=("$pkg_name")
		return
	fi

	log "Installing $pkg_name..."

	# Load package configuration
	local method=$(get_package_config "$pkg_name" "method")
	local install_cmd=$(get_package_config "$pkg_name" "install")
	local url=$(get_package_config "$pkg_name" "url")

	# Load variables
	load_package_variables "$pkg_name"

	# Install dependencies first
	install_dependencies "$pkg_name"

	# Install the package
	install_by_method "$pkg_name" "$method" "$url"

	success "Installed $pkg_name"
	PROCESSED+=("$pkg_name")
}

# =============================================================================
# FILE MANAGEMENT FUNCTIONS
# =============================================================================

load_all_variables() {
	log "Loading all package variables..."
	local pkg_names=$(yq -r 'to_entries[] | .key' "$CONFIG_FILE" 2>/dev/null || echo "")

	for pkg_name in $pkg_names; do
		if [ "$pkg_name" != "null" ] && [ -n "$pkg_name" ]; then
			load_package_variables "$pkg_name"
		fi
	done
}

process_all_mappings() {
	log "Mapping all files from files/ directory..."

	if [ ! -d "files" ]; then
		return
	fi

	find "files" -type f | while read -r src; do
		local rel_path="${src#files/}"
		local dest="$HOME/$rel_path"

		# Create destination directory
		mkdir -p "$(dirname "$dest")"

		# Backup existing file
		if [ -f "$dest" ]; then
			cp "$dest" "$dest.bak"
		fi

		# Deploy file with variable substitution
		envsubst <"$src" >"$dest"
	done
}

add_package_sources() {
	log "Adding package sources to .zshrc..."

	local zshrc_path="$HOME/.zshrc"

	for pkg in "${PROCESSED[@]}"; do
		# Only add source for packages that have .zsh config files
		if [ -f "files/.zsh/$pkg.zsh" ]; then
			echo "source ~/.zsh/$pkg.zsh" >>"$zshrc_path"
		fi
	done

	success "Package sources added to .zshrc"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {

	# Validate configuration file
	if [ ! -f "$CONFIG_FILE" ]; then
		error "Configuration file $CONFIG_FILE not found!"
		exit 1
	fi

	log "Reading configuration..."

	# Install bootstrap packages
	bootstrap

	# Install all available packages
	log "Installing all available packages:"
	local selected=$(
		yq -r 'to_entries[] | .key + " - " + .value.description' "$CONFIG_FILE" | \
		gum choose --no-limit --height 15 --header "Select packages (Space to select, Enter to confirm)" | \
		awk -F ' - ' '{print $1}'
	)

	if [ -z "$selected" ]; then
		log "No packages selected."
		exit 0
	fi

	# Install selected packages
	for pkg in $selected; do
		install_package "$pkg"
	done

	# Load all variables before processing file mappings
	load_all_variables

	# Process file mappings
	process_all_mappings

	# Add package sources to .zshrc based on installed packages
	add_package_sources

	success "Dotfiles installation complete!"
}

# Execute main function
main

#!/bin/sh
#
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                                                                           ║
# ║                    AntiZapret Installation Script                         ║
# ║                      for OPNsense / FreeBSD                               ║
# ║                                                                           ║
# ║                           Version 3.6                                     ║
# ║                                                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#

# ════════════════════════════════════════════════════════════════════════════
# CONFIGURATION & CONSTANTS
# ════════════════════════════════════════════════════════════════════════════

VERSION="3.6"
SCRIPT_NAME="AntiZapret Installer"

# Paths
TORRC_PATH="/usr/local/etc/tor/torrc"
TOR_RC_SCRIPT="/usr/local/etc/rc.d/tor"
TOR_RC_CONF="/etc/rc.conf.d/tor"
SCRIPT_DIR="/root/antizapret"
LOG_DIR="/var/log/tor"
PID_DIR="/var/run/tor"
DATA_DIR="/var/db/tor"
IP_LIST_PATH="/usr/local/www/ipfw_antizapret.dat"
ACTIONS_DIR="/usr/local/opnsense/service/conf/actions.d"
FREEBSD_REPO_CONF="/usr/local/etc/pkg/repos/FreeBSD.conf"
OPNSENSE_REPO_CONF="/usr/local/etc/pkg/repos/OPNsense.conf"

# Tor user/group
TOR_USER="_tor"
TOR_GROUP="_tor"

# Default settings
USE_IPV6="yes"
USE_BRIDGES="no"
OBFS4_BRIDGES=""
WEBTUNNEL_BRIDGES=""
LOCAL_IP=""
FREEBSD_REPO_ENABLED="no"
PKG_REINSTALL_NEEDED="no"

# FreeBSD package repository
PKG_FREEBSD_BASE="https://pkg.freebsd.org/FreeBSD"

# Repository backups
FREEBSD_REPO_BACKUP=""
OPNSENSE_REPO_BACKUP=""

# ════════════════════════════════════════════════════════════════════════════
# COLOR DEFINITIONS
# ════════════════════════════════════════════════════════════════════════════

setup_colors() {
    if [ -t 1 ] && [ "${TERM:-dumb}" != "dumb" ]; then
        C_RESET=$(printf '\033[0m')
        C_BOLD=$(printf '\033[1m')
        C_DIM=$(printf '\033[2m')
        C_UNDERLINE=$(printf '\033[4m')
        
        C_RED=$(printf '\033[0;31m')
        C_GREEN=$(printf '\033[0;32m')
        C_YELLOW=$(printf '\033[0;33m')
        C_BLUE=$(printf '\033[0;34m')
        C_MAGENTA=$(printf '\033[0;35m')
        C_CYAN=$(printf '\033[0;36m')
        C_WHITE=$(printf '\033[0;37m')
        
        C_BRED=$(printf '\033[1;31m')
        C_BGREEN=$(printf '\033[1;32m')
        C_BYELLOW=$(printf '\033[1;33m')
        C_BBLUE=$(printf '\033[1;34m')
        C_BMAGENTA=$(printf '\033[1;35m')
        C_BCYAN=$(printf '\033[1;36m')
        C_BWHITE=$(printf '\033[1;37m')
        
        C_BG_BLACK=$(printf '\033[40m')
        C_BG_RED=$(printf '\033[41m')
        C_BG_GREEN=$(printf '\033[42m')
        C_BG_YELLOW=$(printf '\033[43m')
        C_BG_BLUE=$(printf '\033[44m')
        C_BG_MAGENTA=$(printf '\033[45m')
        C_BG_CYAN=$(printf '\033[46m')
        C_BG_WHITE=$(printf '\033[47m')
        
        C_ORANGE=$(printf '\033[38;5;208m')
        C_PURPLE=$(printf '\033[38;5;141m')
        C_GOLD=$(printf '\033[38;5;220m')
        C_SKY=$(printf '\033[38;5;117m')
    else
        C_RESET='' C_BOLD='' C_DIM='' C_UNDERLINE=''
        C_RED='' C_GREEN='' C_YELLOW='' C_BLUE=''
        C_MAGENTA='' C_CYAN='' C_WHITE=''
        C_BRED='' C_BGREEN='' C_BYELLOW='' C_BBLUE=''
        C_BMAGENTA='' C_BCYAN='' C_BWHITE=''
        C_BG_BLACK='' C_BG_RED='' C_BG_GREEN='' C_BG_YELLOW=''
        C_BG_BLUE='' C_BG_MAGENTA='' C_BG_CYAN='' C_BG_WHITE=''
        C_ORANGE='' C_PURPLE='' C_GOLD='' C_SKY=''
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# UI ELEMENTS & FORMATTING
# ════════════════════════════════════════════════════════════════════════════

SYM_CHECK='✓'
SYM_CROSS='✗'
SYM_ARROW='➜'
SYM_BULLET='●'
SYM_DIAMOND='◆'
SYM_STAR='★'
SYM_CIRCLE='○'
SYM_TRIANGLE='▶'
SYM_INFO='ℹ'
SYM_WARN='⚠'
SYM_GEAR='⚙'
SYM_LOCK='🔒'
SYM_GLOBE='🌐'
SYM_ROCKET='🚀'
SYM_PACKAGE='📦'
SYM_FILE='📄'
SYM_CLOCK='🕐'
SYM_SHIELD='🛡'

print_banner() {
    clear
    echo ""
    printf "%s" "${C_BMAGENTA}"
    cat << 'EOF'
    ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     ███████╗██████╗ 
    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██╔════╝██╔══██╗
    ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     █████╗  ██████╔╝
    ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     ██╔══╝  ██╔══██╗
    ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗███████╗██║  ██║
    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝
EOF
    printf "%s" "${C_RESET}"
    echo ""
    printf "%s" "${C_CYAN}"
    cat << 'EOF'
     █████╗ ███╗   ██╗████████╗██╗    ███████╗ █████╗ ██████╗ ██████╗ ███████╗████████╗
    ██╔══██╗████╗  ██║╚══██╔══╝██║    ╚══███╔╝██╔══██╗██╔══██╗██╔══██╗██╔════╝╚══██╔══╝
    ███████║██╔██╗ ██║   ██║   ██║      ███╔╝ ███████║██████╔╝██████╔╝█████╗     ██║   
    ██╔══██║██║╚██╗██║   ██║   ██║     ███╔╝  ██╔══██║██╔═══╝ ██╔══██╗██╔══╝     ██║   
    ██║  ██║██║ ╚████║   ██║   ██║    ███████╗██║  ██║██║     ██║  ██║███████╗   ██║   
    ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝    ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝   
EOF
    printf "%s" "${C_RESET}"
    echo ""
    printf "%s%s" "${C_DIM}" "${C_WHITE}"
    echo "    ╔══════════════════════════════════════════════════════════════════════╗"
    printf "    ║%s%s  %s Tor + AntiZapret Installation for OPNsense/FreeBSD %s         %s%s║%s\n" "${C_RESET}" "${C_GOLD}" "${SYM_SHIELD}" "${SYM_SHIELD}" "${C_DIM}" "${C_WHITE}" "${C_RESET}"
    printf "%s%s    ║%s%s                        Version %s                                %s%s║%s\n" "${C_DIM}" "${C_WHITE}" "${C_RESET}" "${C_SKY}" "${VERSION}" "${C_DIM}" "${C_WHITE}" "${C_RESET}"
    printf "%s%s" "${C_DIM}" "${C_WHITE}"
    echo "    ╚══════════════════════════════════════════════════════════════════════╝"
    printf "%s" "${C_RESET}"
    echo ""
}

print_gradient_line() {
    local width=${1:-70}
    local i=0
    
    printf "    "
    while [ $i -lt $width ]; do
        case $((i % 6)) in
            0) printf "%s═" "${C_RED}" ;;
            1) printf "%s═" "${C_ORANGE}" ;;
            2) printf "%s═" "${C_YELLOW}" ;;
            3) printf "%s═" "${C_GREEN}" ;;
            4) printf "%s═" "${C_BLUE}" ;;
            5) printf "%s═" "${C_MAGENTA}" ;;
        esac
        i=$((i + 1))
    done
    printf "%s\n" "${C_RESET}"
}

print_section_header() {
    local title="$1"
    local icon="${2:-${SYM_GEAR}}"
    
    echo ""
    print_gradient_line 70
    printf "    %s%s %s %s" "${C_BG_BLUE}" "${C_BWHITE}" "$icon" "${C_RESET}"
    printf "%s%s %s %s" "${C_BBLUE}" "${C_BOLD}" "$title" "${C_RESET}"
    echo ""
    print_gradient_line 70
    echo ""
}

print_subsection() {
    local title="$1"
    local i
    echo ""
    printf "    %s┌── %s%s %s" "${C_CYAN}" "${C_BCYAN}" "$title" "${C_CYAN}"
    i=${#title}
    while [ $i -lt 60 ]; do
        printf "─"
        i=$((i + 1))
    done
    printf "┐%s\n" "${C_RESET}"
}

print_subsection_end() {
    local i=0
    printf "    %s└" "${C_CYAN}"
    while [ $i -lt 66 ]; do
        printf "─"
        i=$((i + 1))
    done
    printf "┘%s\n" "${C_RESET}"
}

print_action() {
    printf "    %s%s%s %s%s%s\n" "${C_BCYAN}" "${SYM_TRIANGLE}" "${C_RESET}" "${C_CYAN}" "$1" "${C_RESET}"
}

print_subaction() {
    printf "      %s%s%s %s%s%s\n" "${C_BLUE}" "${SYM_ARROW}" "${C_RESET}" "${C_WHITE}" "$1" "${C_RESET}"
}

print_success() {
    printf "    %s%s%s %s%s%s\n" "${C_BGREEN}" "${SYM_CHECK}" "${C_RESET}" "${C_GREEN}" "$1" "${C_RESET}"
}

print_error() {
    printf "    %s%s%s %s%s%s\n" "${C_BRED}" "${SYM_CROSS}" "${C_RESET}" "${C_RED}" "$1" "${C_RESET}"
}

print_warning() {
    printf "    %s%s%s %s%s%s\n" "${C_BYELLOW}" "${SYM_WARN}" "${C_RESET}" "${C_YELLOW}" "$1" "${C_RESET}"
}

print_info() {
    printf "    %s%s%s %s%s%s\n" "${C_BCYAN}" "${SYM_INFO}" "${C_RESET}" "${C_CYAN}" "$1" "${C_RESET}"
}

print_key_value() {
    local key="$1"
    local value="$2"
    local icon="${3:-${SYM_CIRCLE}}"
    local icon_color="${4:-${C_PURPLE}}"
    printf "      %s%s%s %s%s:%s %s%s%s\n" "${icon_color}" "$icon" "${C_RESET}" "${C_DIM}" "$key" "${C_RESET}" "${C_BWHITE}" "$value" "${C_RESET}"
}

print_key_value_status() {
    local key="$1"
    local value="$2"
    local status="$3"
    local icon
    local color
    
    case "$status" in
        ok|success|green)
            icon="${SYM_CHECK}"
            color="${C_GREEN}"
            ;;
        warn|warning|yellow)
            icon="${SYM_WARN}"
            color="${C_YELLOW}"
            ;;
        error|fail|red)
            icon="${SYM_CROSS}"
            color="${C_RED}"
            ;;
        *)
            icon="${SYM_CIRCLE}"
            color="${C_PURPLE}"
            ;;
    esac
    
    printf "      %s%s%s %s%s:%s %s%s%s\n" "${color}" "$icon" "${C_RESET}" "${C_DIM}" "$key" "${C_RESET}" "${C_BWHITE}" "$value" "${C_RESET}"
}

print_box_message() {
    local message="$1"
    local color="${2:-$C_WHITE}"
    local msg_len=${#message}
    local box_width=$((msg_len + 4))
    local i
    
    printf "    %s┌" "${C_DIM}"
    i=0
    while [ $i -lt $box_width ]; do printf "─"; i=$((i + 1)); done
    printf "┐%s\n" "${C_RESET}"
    
    printf "    %s│%s %s%s%s %s│%s\n" "${C_DIM}" "${C_RESET}" "$color" "$message" "${C_RESET}" "${C_DIM}" "${C_RESET}"
    
    printf "    %s└" "${C_DIM}"
    i=0
    while [ $i -lt $box_width ]; do printf "─"; i=$((i + 1)); done
    printf "┘%s\n" "${C_RESET}"
}

countdown() {
    local seconds=$1
    local message="${2:-Starting in}"
    
    while [ $seconds -gt 0 ]; do
        printf "\r      %s%s%s %s%s %s%d%s seconds...%s  " "${C_YELLOW}" "${SYM_CLOCK}" "${C_RESET}" "${C_WHITE}" "$message" "${C_BYELLOW}" "$seconds" "${C_WHITE}" "${C_RESET}"
        sleep 1
        seconds=$((seconds - 1))
    done
    printf "\r      %s%s%s %sReady!%s                              \n" "${C_GREEN}" "${SYM_CHECK}" "${C_RESET}" "${C_GREEN}" "${C_RESET}"
}

# ════════════════════════════════════════════════════════════════════════════
# INPUT FUNCTIONS
# ════════════════════════════════════════════════════════════════════════════

prompt_yes_no() {
    local message="$1"
    local default="${2:-Y}"
    local result
    
    if [ "$default" = "Y" ]; then
        printf "    %s?%s %s%s%s %s[%sY%s/%sn%s]%s: " "${C_BYELLOW}" "${C_RESET}" "${C_WHITE}" "$message" "${C_RESET}" "${C_DIM}" "${C_BGREEN}" "${C_DIM}" "${C_RED}" "${C_DIM}" "${C_RESET}"
    else
        printf "    %s?%s %s%s%s %s[%sy%s/%sN%s]%s: " "${C_BYELLOW}" "${C_RESET}" "${C_WHITE}" "$message" "${C_RESET}" "${C_DIM}" "${C_GREEN}" "${C_DIM}" "${C_BRED}" "${C_DIM}" "${C_RESET}"
    fi
    
    read result
    
    case "$result" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        [Nn]|[Nn][Oo]) return 1 ;;
        "") [ "$default" = "Y" ] && return 0 || return 1 ;;
        *) [ "$default" = "Y" ] && return 0 || return 1 ;;
    esac
}

prompt_input() {
    local message="$1"
    local var_name="$2"
    local default="$3"
    local result
    
    if [ -n "$default" ]; then
        printf "    %s%s%s %s%s%s %s[%s%s%s]%s: " "${C_BCYAN}" "${SYM_ARROW}" "${C_RESET}" "${C_WHITE}" "$message" "${C_RESET}" "${C_DIM}" "${C_CYAN}" "$default" "${C_DIM}" "${C_RESET}"
    else
        printf "    %s%s%s %s%s%s: " "${C_BCYAN}" "${SYM_ARROW}" "${C_RESET}" "${C_WHITE}" "$message" "${C_RESET}"
    fi
    
    read result
    
    if [ -z "$result" ] && [ -n "$default" ]; then
        result="$default"
    fi
    
    eval "$var_name=\"\$result\""
}

# ════════════════════════════════════════════════════════════════════════════
# SYSTEM DETECTION
# ════════════════════════════════════════════════════════════════════════════

check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo ""
        print_error "This script must be run as root!"
        echo ""
        printf "    %sPlease run:%s\n" "${C_YELLOW}" "${C_RESET}"
        printf "      %ssu -%s\n" "${C_BWHITE}" "${C_RESET}"
        printf "      %sor%s\n" "${C_DIM}" "${C_RESET}"
        printf "      %ssudo sh %s%s\n" "${C_BWHITE}" "$0" "${C_RESET}"
        echo ""
        exit 1
    fi
}

detect_system() {
    print_action "Detecting system information..."
    
    OS_TYPE=$(uname -s)
    OS_VERSION=$(uname -r | cut -d. -f1)
    OS_FULL_VERSION=$(uname -r)
    ARCH=$(uname -m)
    HOSTNAME=$(hostname)
    
    if [ "$OS_TYPE" != "FreeBSD" ]; then
        print_error "This script is designed for FreeBSD/OPNsense only"
        print_info "Detected OS: $OS_TYPE"
        exit 1
    fi
    
    # Detect OPNsense
    if [ -d "/usr/local/opnsense" ]; then
        IS_OPNSENSE="yes"
        OPNSENSE_VERSION=$(opnsense-version -v 2>/dev/null || echo "unknown")
    else
        IS_OPNSENSE="no"
        OPNSENSE_VERSION=""
    fi
    
    # Build FreeBSD package URL
    PKG_FREEBSD_URL="${PKG_FREEBSD_BASE}:${OS_VERSION}:${ARCH}/latest/All"
    
    echo ""
    print_subsection "System Information"
    echo ""
    
    if [ "$IS_OPNSENSE" = "yes" ]; then
        print_key_value "Platform" "OPNsense ${OPNSENSE_VERSION}" "${SYM_SHIELD}" "${C_GREEN}"
    else
        print_key_value "Platform" "FreeBSD" "${SYM_GEAR}" "${C_BLUE}"
    fi
    print_key_value "OS Version" "FreeBSD ${OS_FULL_VERSION}" "${SYM_INFO}" "${C_CYAN}"
    print_key_value "Architecture" "${ARCH}" "${SYM_GEAR}" "${C_MAGENTA}"
    print_key_value "Hostname" "${HOSTNAME}" "${SYM_GLOBE}" "${C_BLUE}"
    
    echo ""
    print_subsection_end
}

detect_network() {
    print_action "Detecting network configuration..."
    
    DEFAULT_IFACE=$(route -n get default 2>/dev/null | grep interface | awk '{print $2}')
    
    echo ""
    print_subsection "Network Interfaces"
    echo ""
    
    local found_lan=0
    local found_interface=""
    
    # Get list of interfaces
    ALL_INTERFACES=$(ifconfig -l | tr ' ' '\n')
    
    # First pass: display all interfaces
    for iface in $ALL_INTERFACES; do
        local ip=$(ifconfig "$iface" 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | head -1)
        local description=$(ifconfig "$iface" 2>/dev/null | grep "description" | cut -d: -f2- | xargs)
        
        if [ -n "$ip" ]; then
            local marker=""
            local status_color="${C_GREEN}"
            local status_icon="${SYM_BULLET}"
            
            if [ "$iface" = "$DEFAULT_IFACE" ]; then
                marker=" (WAN)"
                status_color="${C_YELLOW}"
                status_icon="${SYM_GLOBE}"
            fi
            
            # Check if description contains "LAN" (case insensitive)
            if [ -n "$description" ] && echo "$description" | grep -qi "LAN"; then
                # This is likely a LAN interface
                if [ $found_lan -eq 0 ]; then
                    found_interface="$iface"
                    LOCAL_IP="$ip"
                    found_lan=1
                    status_color="${C_BGREEN}"
                    status_icon="${SYM_SHIELD}"
                    marker=" (LAN)"
                fi
            fi
            
            if [ -n "$description" ]; then
                print_key_value "$iface" "${ip}${marker}" "${status_icon}" "${status_color}"
                print_subaction "Description: $description"
            else
                print_key_value "$iface" "${ip}${marker}" "${status_icon}" "${status_color}"
            fi
        fi
    done
    
    # If no LAN interface found by description, try to find by private IP range
    if [ $found_lan -eq 0 ]; then
        for iface in $ALL_INTERFACES; do
            local ip=$(ifconfig "$iface" 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | head -1)
            
            if [ -n "$ip" ]; then
                # Check if IP is in private range
                if echo "$ip" | grep -qE "^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)"; then
                    # This is likely a LAN IP
                    if [ $found_lan -eq 0 ]; then
                        found_interface="$iface"
                        LOCAL_IP="$ip"
                        found_lan=1
                        break
                    fi
                fi
            fi
        done
    fi
    
    # If still no LAN IP found, use the first non-loopback IP
    if [ $found_lan -eq 0 ]; then
        for iface in $ALL_INTERFACES; do
            local ip=$(ifconfig "$iface" 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | head -1)
            
            if [ -n "$ip" ]; then
                found_interface="$iface"
                LOCAL_IP="$ip"
                found_lan=1
                break
            fi
        done
    fi
    
    echo ""
    print_subsection_end
    
    if [ -n "$LOCAL_IP" ]; then
        echo ""
        printf "    %s%s%s Detected interface: %s%s%s (%s%s%s)\n" "${C_BCYAN}" "${SYM_INFO}" "${C_RESET}" "${C_BWHITE}" "${found_interface}" "${C_RESET}" "${C_CYAN}" "${LOCAL_IP}" "${C_RESET}"
        
        if ! prompt_yes_no "Use this IP address?" "Y"; then
            prompt_input "Enter LAN IP address" LOCAL_IP "$LOCAL_IP"
        fi
    else
        print_warning "Could not auto-detect LAN IP"
        prompt_input "Enter LAN IP address" LOCAL_IP "192.168.1.1"
    fi
    
    echo ""
    printf "    %s%s%s Using LAN IP: %s%s%s\n" "${C_BGREEN}" "${SYM_CHECK}" "${C_RESET}" "${C_BWHITE}" "${LOCAL_IP}" "${C_RESET}"
}

# ════════════════════════════════════════════════════════════════════════════
# REPOSITORY MANAGEMENT
# ════════════════════════════════════════════════════════════════════════════

backup_repo_configs() {
    print_subaction "Backing up repository configurations..."
    
    # Backup FreeBSD repo config
    if [ -f "$FREEBSD_REPO_CONF" ]; then
        FREEBSD_REPO_BACKUP=$(mktemp /tmp/freebsd_repo_backup.XXXXXX)
        cp "$FREEBSD_REPO_CONF" "$FREEBSD_REPO_BACKUP"
        print_subaction "Backed up FreeBSD repo config"
    fi
    
    # Backup OPNsense repo config
    if [ -f "$OPNSENSE_REPO_CONF" ]; then
        OPNSENSE_REPO_BACKUP=$(mktemp /tmp/opnsense_repo_backup.XXXXXX)
        cp "$OPNSENSE_REPO_CONF" "$OPNSENSE_REPO_BACKUP"
        print_subaction "Backed up OPNsense repo config"
    fi
    
    print_success "Repository configurations backed up"
}

restore_repo_configs() {
    print_subaction "Restoring repository configurations..."
    
    # Restore FreeBSD repo config
    if [ -n "$FREEBSD_REPO_BACKUP" ] && [ -f "$FREEBSD_REPO_BACKUP" ]; then
        cp "$FREEBSD_REPO_BACKUP" "$FREEBSD_REPO_CONF"
        rm -f "$FREEBSD_REPO_BACKUP"
        print_subaction "Restored FreeBSD repo config"
    else
        # If no backup, ensure FreeBSD repo is disabled
        cat > "$FREEBSD_REPO_CONF" << 'REPOEOF'
FreeBSD: { enabled: no }
FreeBSD-kmods: { enabled: no }
REPOEOF
        print_subaction "Set FreeBSD repo to disabled (no backup found)"
    fi
    
    # Restore OPNsense repo config
    if [ -n "$OPNSENSE_REPO_BACKUP" ] && [ -f "$OPNSENSE_REPO_BACKUP" ]; then
        cp "$OPNSENSE_REPO_BACKUP" "$OPNSENSE_REPO_CONF"
        rm -f "$OPNSENSE_REPO_BACKUP"
        print_subaction "Restored OPNsense repo config"
    fi
    
    # Force pkg update to refresh configurations
    pkg update -f >/dev/null 2>&1 || true
    
    print_success "Repository configurations restored"
}

enable_freebsd_repo() {
    print_subaction "Enabling FreeBSD repository temporarily..."
    
    # Backup current configs first
    backup_repo_configs
    
    # Enable FreeBSD repository
    cat > "$FREEBSD_REPO_CONF" << 'REPOEOF'
FreeBSD: {
  url: "pkg+https://pkg.freebsd.org/${ABI}/latest",
  mirror_type: "srv",
  signature_type: "fingerprints",
  fingerprints: "/usr/share/keys/pkg",
  enabled: yes
}
FreeBSD-kmods: { enabled: no }
REPOEOF
    
    # Ensure OPNsense repo remains enabled if it exists
    if [ -f "$OPNSENSE_REPO_CONF" ]; then
        if ! grep -q "enabled: yes" "$OPNSENSE_REPO_CONF"; then
            sed -i '' 's/enabled:.*no/enabled: yes/' "$OPNSENSE_REPO_CONF" 2>/dev/null || true
        fi
    fi
    
    FREEBSD_REPO_ENABLED="yes"
    print_success "FreeBSD repository enabled (temporarily)"
}

disable_freebsd_repo() {
    if [ "$FREEBSD_REPO_ENABLED" = "yes" ]; then
        print_subaction "Disabling FreeBSD repository..."
        restore_repo_configs
        FREEBSD_REPO_ENABLED="no"
        print_success "FreeBSD repository disabled and configurations restored"
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# PKG RESTORATION FOR OPNSENSE
# ════════════════════════════════════════════════════════════════════════════

restore_opnsense_pkg() {
    # Only run on OPNsense systems
    if [ "$IS_OPNSENSE" != "yes" ]; then
        return 0
    fi
    
    # Only run if we installed packages from FreeBSD repo
    if [ "$PKG_REINSTALL_NEEDED" != "yes" ]; then
        return 0
    fi
    
    print_section_header "Restoring OPNsense Package Manager" "${SYM_PACKAGE}"
    
    print_action "This step ensures pkg compatibility with OPNsense..."
    echo ""
    
    # First, ensure repository configs are correct
    print_subaction "Verifying repository configuration..."
    
    # Make sure FreeBSD repo is disabled
    cat > "$FREEBSD_REPO_CONF" << 'REPOEOF'
FreeBSD: { enabled: no }
FreeBSD-kmods: { enabled: no }
REPOEOF
    
    # Restore OPNsense repo if we have a backup
    if [ -n "$OPNSENSE_REPO_BACKUP" ] && [ -f "$OPNSENSE_REPO_BACKUP" ]; then
        cp "$OPNSENSE_REPO_BACKUP" "$OPNSENSE_REPO_CONF"
        rm -f "$OPNSENSE_REPO_BACKUP"
        OPNSENSE_REPO_BACKUP=""
    fi
    
    print_success "Repository configuration verified"
    
    # Now reinstall pkg from OPNsense repository
    print_subaction "Reinstalling pkg from OPNsense repository..."
    
    # Use pkg-static to avoid issues with the current pkg binary
    if pkg-static update -f >/dev/null 2>&1; then
        print_subaction "Package database updated"
    else
        print_warning "Failed to update package database, continuing..."
    fi
    
    # Unlock pkg if locked
    pkg-static unlock -a >/dev/null 2>&1 || true
    pkg-static unlock pkg >/dev/null 2>&1 || true
    
    # Force reinstall pkg from OPNsense repository
    print_subaction "Force reinstalling pkg from OPNsense..."
    
    if pkg-static install -r OPNsense -fy pkg >/dev/null 2>&1; then
        print_success "pkg reinstalled from OPNsense repository"
    else
        print_warning "pkg-static install failed, trying alternative method..."
        
        # Alternative: try to fetch and install manually
        if pkg-static install -fy pkg >/dev/null 2>&1; then
            print_success "pkg reinstalled (alternative method)"
        else
            print_warning "Could not reinstall pkg, but this may not be critical"
        fi
    fi
    
    # Force update pkg database again with the new pkg
    print_subaction "Refreshing package database..."
    if pkg update -f >/dev/null 2>&1; then
        print_success "Package database refreshed"
    else
        print_warning "Failed to refresh package database"
    fi
    
    # Verify pkg version
    local pkg_version=$(pkg -v 2>/dev/null || echo "unknown")
    local pkg_origin=$(pkg query %o pkg 2>/dev/null || echo "unknown")
    
    echo ""
    print_subsection "Package Manager Status"
    echo ""
    print_key_value "pkg version" "${pkg_version}" "${SYM_PACKAGE}" "${C_CYAN}"
    print_key_value "pkg origin" "${pkg_origin}" "${SYM_INFO}" "${C_BLUE}"
    echo ""
    print_subsection_end
    
    # Run integrity check
    print_subaction "Running package integrity check..."
    local integrity_issues=$(pkg check -d 2>&1 | grep -c "missing" || echo "0")
    
    if [ "$integrity_issues" = "0" ]; then
        print_success "Package integrity check passed"
    else
        print_warning "Found ${integrity_issues} missing dependencies"
        print_subaction "Attempting to fix..."
        pkg install -fy >/dev/null 2>&1 || true
    fi
    
    echo ""
    print_success "OPNsense package manager restoration complete"
    
    # Mark as done so we don't run again
    PKG_REINSTALL_NEEDED="no"
}

search_freebsd_package() {
    local pkg_name="$1"
    local result=""
    
    result=$(pkg search -r FreeBSD -e -Q name "$pkg_name" 2>/dev/null | head -1)
    
    if [ -n "$result" ]; then
        echo "$result"
        return 0
    fi
    
    result=$(pkg rquery -r FreeBSD '%n-%v' "$pkg_name" 2>/dev/null | head -1)
    
    if [ -n "$result" ]; then
        echo "$result"
        return 0
    fi
    
    return 1
}

# ════════════════════════════════════════════════════════════════════════════
# PACKAGE MANAGEMENT
# ════════════════════════════════════════════════════════════════════════════

check_pkg_integrity() {
    print_subaction "Checking pkg integrity..."
    
    # Проверяем, установлен ли pkg
    if ! pkg -N >/dev/null 2>&1; then
        print_warning "pkg not fully initialized, bootstrapping..."
        pkg bootstrap -y >/dev/null 2>&1 || {
            print_warning "Standard bootstrap failed, trying pkg-static..."
            pkg-static unlock pkg 2>/dev/null
            pkg-static install -f pkg 2>/dev/null || true
        }
    fi
    
    # Проверяем, не заблокирован ли pkg
    if [ -f /var/run/pkg.lock ]; then
        print_subaction "pkg is locked, trying to unlock..."
        pkg unlock -a 2>/dev/null || true
    fi
    
    # Обновляем индекс pkg только из OPNsense репозитория
    print_subaction "Updating pkg repository (OPNsense only)..."
    pkg update -r OPNsense -f >/dev/null 2>&1 || print_warning "Failed to update pkg repository, continuing anyway"
    
    print_success "pkg integrity check completed"
}

install_opnsense_package() {
    local pkg_name="$1"
    local pkg_desc="${2:-$pkg_name}"
    
    # Сначала проверяем целостность pkg
    check_pkg_integrity
    
    # Проверяем, установлен ли пакет
    if pkg info -q "$pkg_name" 2>/dev/null; then
        printf "    %s%s%s %s%s %s(already installed)%s\n" "${C_BGREEN}" "${SYM_CHECK}" "${C_RESET}" "${C_GREEN}" "$pkg_desc" "${C_DIM}" "${C_RESET}"
        # Проверяем версию для информации
        local pkg_version=$(pkg info "$pkg_name" 2>/dev/null | grep Version | head -1)
        if [ -n "$pkg_version" ]; then
            print_subaction "Installed: $pkg_version"
        fi
        return 0
    fi
    
    print_subaction "Installing ${pkg_name}..."
    
    # Создаем временный файл для логов
    local temp_log=$(mktemp /tmp/pkg_install.XXXXXX)
    
    # Пробуем установить через pkg
    if pkg install -y "$pkg_name" > "$temp_log" 2>&1; then
        # Проверяем, установился ли пакет
        if pkg info -q "$pkg_name" 2>/dev/null; then
            printf "    %s%s%s %s%s installed successfully%s\n" "${C_BGREEN}" "${SYM_CHECK}" "${C_RESET}" "${C_GREEN}" "$pkg_desc" "${C_RESET}"
            # Показываем информацию о пакете
            local pkg_info=$(pkg info "$pkg_name" 2>/dev/null | grep -E "Version|Size|License" | head -3)
            if [ -n "$pkg_info" ]; then
                echo "$pkg_info" | while read line; do
                    print_subaction "  $line"
                done
            fi
            rm -f "$temp_log"
            return 0
        else
            printf "    %s%s%s %sPackage installation reported success but not found in system%s\n" "${C_BYELLOW}" "${SYM_WARN}" "${C_RESET}" "${C_YELLOW}" "${C_RESET}"
            # Показываем последние строки лога для диагностики
            if [ -f "$temp_log" ]; then
                print_subaction "Last 5 lines of pkg output:"
                tail -5 "$temp_log" | sed 's/^/      /'
            fi
        fi
    else
        printf "    %s%s%s %sFailed to install %s (pkg install command failed)%s\n" "${C_BRED}" "${SYM_CROSS}" "${C_RESET}" "${C_RED}" "$pkg_desc" "${C_RESET}"
        # Показываем ошибку
        if [ -f "$temp_log" ]; then
            print_subaction "Error output:"
            grep -i error "$temp_log" | head -5 | sed 's/^/      /'
        fi
    fi
    
    # Если pkg install не сработал, пробуем pkg-static
    echo ""
    print_warning "Trying alternative installation method with pkg-static..."
    
    # Разблокируем и переустанавливаем pkg если нужно
    pkg-static unlock pkg 2>/dev/null || true
    pkg-static install -f pkg 2>/dev/null || true
    
    # Пробуем снова с pkg-static
    if pkg install -y "$pkg_name" > "$temp_log" 2>&1; then
        if pkg info -q "$pkg_name" 2>/dev/null; then
            printf "    %s%s%s %s%s installed successfully (second attempt)%s\n" "${C_BGREEN}" "${SYM_CHECK}" "${C_RESET}" "${C_GREEN}" "$pkg_desc" "${C_RESET}"
            rm -f "$temp_log"
            return 0
        fi
    fi
    
    # Пробуем найти пакет в других репозиториях
    echo ""
    print_warning "Searching for package in available repositories..."
    local pkg_search_result=$(pkg search -Q name "^${pkg_name}$" 2>/dev/null | head -1)
    
    if [ -n "$pkg_search_result" ]; then
        print_info "Found: $pkg_search_result"
        if prompt_yes_no "Try to install from found repository?" "Y"; then
            if pkg install -y "$pkg_name" > "$temp_log" 2>&1; then
                if pkg info -q "$pkg_name" 2>/dev/null; then
                    printf "    %s%s%s %s%s installed successfully (from found repository)%s\n" "${C_BGREEN}" "${SYM_CHECK}" "${C_RESET}" "${C_GREEN}" "$pkg_desc" "${C_RESET}"
                    rm -f "$temp_log"
                    return 0
                fi
            fi
        fi
    fi
    
    # Финальная проверка - может пакет уже установлен под другим именем?
    local pkg_installed=$(pkg info | grep -i "$pkg_name" | head -1)
    if [ -n "$pkg_installed" ]; then
        printf "    %s%s%s %sSimilar package found: %s%s\n" "${C_BYELLOW}" "${SYM_WARN}" "${C_RESET}" "${C_YELLOW}" "$pkg_installed" "${C_RESET}"
        print_info "Maybe the package is already installed with different name"
    fi
    
    rm -f "$temp_log"
    return 1
}

install_transport_plugin() {
    local pkg_name="$1"
    local pkg_desc="${2:-$pkg_name}"
    
    if pkg info "$pkg_name" >/dev/null 2>&1; then
        printf "    %s%s%s %s%s %s(already installed)%s\n" "${C_BGREEN}" "${SYM_CHECK}" "${C_RESET}" "${C_GREEN}" "$pkg_desc" "${C_DIM}" "${C_RESET}"
        return 0
    fi
    
    print_subaction "Searching for ${pkg_name} in FreeBSD repository..."
    
    # Mark that we need to reinstall pkg from OPNsense after this
    PKG_REINSTALL_NEEDED="yes"
    
    # Method 1: Direct pkg install from FreeBSD repo
    print_subaction "Trying pkg install from FreeBSD repo..."
    if pkg install -r FreeBSD -y "$pkg_name" >/dev/null 2>&1; then
        if pkg info "$pkg_name" >/dev/null 2>&1; then
            printf "    %s%s%s %s%s installed successfully%s\n" "${C_BGREEN}" "${SYM_CHECK}" "${C_RESET}" "${C_GREEN}" "$pkg_desc" "${C_RESET}"
            return 0
        fi
    fi
    
    # Method 2: Search and pkg add
    print_subaction "Searching for package version..."
    local pkg_fullname=""
    pkg_fullname=$(search_freebsd_package "$pkg_name")
    
    if [ -n "$pkg_fullname" ]; then
        local pkg_url="${PKG_FREEBSD_URL}/${pkg_fullname}.pkg"
        print_subaction "Found: ${pkg_fullname}"
        print_subaction "Downloading from: ${pkg_url}"
        
        if fetch -q -o "/tmp/${pkg_fullname}.pkg" "$pkg_url" 2>/dev/null; then
            if pkg add "/tmp/${pkg_fullname}.pkg" 2>/dev/null; then
                if pkg info "$pkg_name" >/dev/null 2>&1; then
                    printf "    %s%s%s %s%s installed successfully%s\n" "${C_BGREEN}" "${SYM_CHECK}" "${C_RESET}" "${C_GREEN}" "$pkg_desc" "${C_RESET}"
                    rm -f "/tmp/${pkg_fullname}.pkg"
                    return 0
                fi
            fi
            rm -f "/tmp/${pkg_fullname}.pkg"
        fi
    fi
    
    # Method 3: HTML parsing
    print_subaction "Trying HTML parsing method..."
    local html_content=""
    local pkg_file=""
    
    html_content=$(fetch -qo - "${PKG_FREEBSD_URL}/" 2>/dev/null)
    
    if [ -n "$html_content" ]; then
        pkg_file=$(echo "$html_content" | \
                   grep -oE "\"${pkg_name}-[0-9][^\"]*\.pkg\"" | \
                   tr -d '"' | \
                   sort -V | \
                   tail -1)
        
        if [ -n "$pkg_file" ]; then
            local pkg_url="${PKG_FREEBSD_URL}/${pkg_file}"
            print_subaction "Found: ${pkg_file}"
            
            if fetch -q -o "/tmp/${pkg_file}" "$pkg_url" 2>/dev/null; then
                if pkg add "/tmp/${pkg_file}" 2>/dev/null; then
                    if pkg info "$pkg_name" >/dev/null 2>&1; then
                        printf "    %s%s%s %s%s installed successfully%s\n" "${C_BGREEN}" "${SYM_CHECK}" "${C_RESET}" "${C_GREEN}" "$pkg_desc" "${C_RESET}"
                        rm -f "/tmp/${pkg_file}"
                        return 0
                    fi
                fi
                rm -f "/tmp/${pkg_file}"
            fi
        fi
    fi
    
    # Method 4: Known versions fallback
    print_subaction "Trying known versions..."
    local versions=""
    case "$pkg_name" in
        obfs4proxy-tor)
            versions="0.0.14_25 0.0.14_24 0.0.14_23 0.0.14_22 0.0.14_21 0.0.14_20 0.0.14_19 0.0.14_18 0.0.14_17"
            ;;
        webtunnel-tor)
            versions="0.0.1_25 0.0.1_24 0.0.1_23 0.0.1_22 0.0.1_21 0.0.1_20 0.0.1_19 0.0.1_18 0.0.1_17 0.0.1_16 0.0.1_15"
            ;;
    esac
    
    for ver in $versions; do
        pkg_file="${pkg_name}-${ver}.pkg"
        local pkg_url="${PKG_FREEBSD_URL}/${pkg_file}"
        
        print_subaction "Trying ${pkg_file}..."
        
        if fetch -q -o "/tmp/${pkg_file}" "$pkg_url" 2>/dev/null; then
            if pkg add "/tmp/${pkg_file}" 2>/dev/null; then
                if pkg info "$pkg_name" >/dev/null 2>&1; then
                    printf "    %s%s%s %s%s (v%s) installed successfully%s\n" "${C_BGREEN}" "${SYM_CHECK}" "${C_RESET}" "${C_GREEN}" "$pkg_desc" "$ver" "${C_RESET}"
                    rm -f "/tmp/${pkg_file}"
                    return 0
                fi
            fi
            rm -f "/tmp/${pkg_file}"
        fi
    done
    
    # Method 5: Manual input
    echo ""
    print_error "Automatic installation failed"
    echo ""
    print_info "Check current version at:"
    printf "      %s● https://ports.freebsd.org/cgi/ports.cgi?query=%s%s\n" "${C_CYAN}" "${pkg_name}" "${C_RESET}"
    printf "      %s● %s%s\n" "${C_CYAN}" "${PKG_FREEBSD_URL}/" "${C_RESET}"
    echo ""
    
    if prompt_yes_no "Enter version manually?" "Y"; then
        prompt_input "Package version (e.g., 0.0.1_21)" manual_version ""
        
        if [ -n "$manual_version" ]; then
            pkg_file="${pkg_name}-${manual_version}.pkg"
            local pkg_url="${PKG_FREEBSD_URL}/${pkg_file}"
            
            print_subaction "Installing ${pkg_url}..."
            
            if fetch -q -o "/tmp/${pkg_file}" "$pkg_url" 2>/dev/null; then
                if pkg add "/tmp/${pkg_file}" 2>/dev/null; then
                    if pkg info "$pkg_name" >/dev/null 2>&1; then
                        printf "    %s%s%s %s%s installed successfully%s\n" "${C_BGREEN}" "${SYM_CHECK}" "${C_RESET}" "${C_GREEN}" "$pkg_desc" "${C_RESET}"
                        rm -f "/tmp/${pkg_file}"
                        return 0
                    fi
                fi
                rm -f "/tmp/${pkg_file}"
            fi
        fi
    fi
    
    print_error "Failed to install ${pkg_desc}"
    return 1
}

ask_and_install_package() {
    local pkg_name="$1"
    local pkg_desc="$2"
    local pkg_info="$3"
    
    echo ""
    printf "    %s%s%s %s%s%s - %s%s%s\n" "${C_BBLUE}" "${SYM_PACKAGE}" "${C_RESET}" "${C_BCYAN}" "$pkg_name" "${C_RESET}" "${C_DIM}" "$pkg_info" "${C_RESET}"
    
    if prompt_yes_no "Install ${pkg_desc}?" "N"; then
        install_opnsense_package "$pkg_name" "$pkg_desc"
        return $?
    else
        print_info "Skipping ${pkg_desc}"
        return 0
    fi
}

install_optional_packages() {
    print_section_header "Optional Packages" "${SYM_PACKAGE}"
    
    print_info "The following optional packages can be installed:"
    echo ""
    printf "      %s%s%s %smc%s        - Midnight Commander (visual file manager)\n" "${C_CYAN}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    printf "      %s%s%s %sgit%s       - Version control system (required for AntiZapret)\n" "${C_CYAN}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    printf "      %s%s%s %scurl%s      - Data transfer tool\n" "${C_CYAN}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    printf "      %s%s%s %swget%s      - File download utility\n" "${C_CYAN}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    printf "      %s%s%s %snano%s      - Simple text editor\n" "${C_CYAN}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    
    echo ""
    print_info "You will be asked about each package individually"
    echo ""
    
    printf "    %s%s%s %s%s%s - %s%s%s\n" "${C_BBLUE}" "${SYM_PACKAGE}" "${C_RESET}" "${C_BCYAN}" "git" "${C_RESET}" "${C_DIM}" "Required for AntiZapret updates" "${C_RESET}"
    if prompt_yes_no "Install git? (Recommended)" "Y"; then
        install_opnsense_package "git" "Git"
    else
        print_warning "Git is required for AntiZapret"
    fi
    
    ask_and_install_package "mc" "Midnight Commander" "Visual file manager"
    ask_and_install_package "curl" "cURL" "Data transfer tool"
    ask_and_install_package "wget" "Wget" "File download utility"
    ask_and_install_package "nano" "Nano" "Text editor"
    
    echo ""
    print_success "Optional packages installation complete"
}

install_tor_packages() {
    print_section_header "Installing Tor" "${SYM_LOCK}"
    
    print_action "Installing Tor from OPNsense repository..."
    install_opnsense_package "tor" "Tor"
    
    if ! pkg info -q tor >/dev/null 2>&1; then
        print_error "Failed to install Tor - cannot continue"
        exit 1
    fi
    
    echo ""
    print_success "Tor installed successfully"
}

# ════════════════════════════════════════════════════════════════════════════
# BRIDGE CONFIGURATION
# ════════════════════════════════════════════════════════════════════════════

ask_about_bridges() {
    print_section_header "Tor Bridge Configuration" "${SYM_LOCK}"
    
    echo ""
    print_box_message "Bridges help bypass Tor censorship in restricted regions" "$C_CYAN"
    echo ""
    
    print_info "You need bridges if:"
    printf "      %s%s%s Direct Tor connections are blocked\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}"
    printf "      %s%s%s Your ISP blocks Tor traffic\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}"
    printf "      %s%s%s You're in China, Iran, Russia, etc.\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}"
    
    echo ""
    print_warning "Bridge plugins require FreeBSD repository (not available in OPNsense)"
    
    echo ""
    
    if prompt_yes_no "Do you want to use Tor bridges?" "N"; then
        USE_BRIDGES="yes"
        install_bridge_plugins
        configure_bridges
    else
        USE_BRIDGES="no"
        OBFS4_BRIDGES=""
        WEBTUNNEL_BRIDGES=""
        echo ""
        print_info "Tor will connect directly without bridges"
    fi
}

install_bridge_plugins() {
    print_section_header "Installing Bridge Plugins" "${SYM_PACKAGE}"
    
    print_warning "These packages require FreeBSD repository"
    echo ""
    
    enable_freebsd_repo
    
    printf "    %s%s%s %s%s%s\n" "${C_BBLUE}" "${SYM_PACKAGE}" "${C_RESET}" "${C_BCYAN}" "obfs4proxy-tor" "${C_RESET}"
    print_info "OBFS4 - Makes Tor traffic look like random noise"
    
    if prompt_yes_no "Install OBFS4 plugin?" "Y"; then
        install_transport_plugin "obfs4proxy-tor" "OBFS4"
    fi
    
    echo ""
    
    printf "    %s%s%s %s%s%s\n" "${C_BBLUE}" "${SYM_PACKAGE}" "${C_RESET}" "${C_BCYAN}" "webtunnel-tor" "${C_RESET}"
    print_info "WebTunnel - Makes Tor traffic look like HTTPS"
    
    if prompt_yes_no "Install WebTunnel plugin?" "Y"; then
        install_transport_plugin "webtunnel-tor" "WebTunnel"
    fi
    
    echo ""
    disable_freebsd_repo
    
    echo ""
    print_subsection "Plugin Status"
    echo ""
    
    if pkg info obfs4proxy-tor >/dev/null 2>&1; then
        print_key_value_status "OBFS4" "Installed" "ok"
    else
        print_key_value_status "OBFS4" "Not installed" "warn"
    fi
    
    if pkg info webtunnel-tor >/dev/null 2>&1; then
        print_key_value_status "WebTunnel" "Installed" "ok"
    else
        print_key_value_status "WebTunnel" "Not installed" "warn"
    fi
    
    echo ""
    print_subsection_end
}

configure_bridges() {
    echo ""
    print_subsection "Bridge Configuration"
    echo ""
    
    printf "    %s%s%s %sGet bridges:%s\n" "${C_GOLD}" "${SYM_STAR}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
    printf "      %s%s%s https://bridges.torproject.org/%s\n" "${C_CYAN}" "${SYM_GLOBE}" "${C_RESET}" "${C_RESET}"
    printf "      %s%s%s bridges@torproject.org%s\n" "${C_MAGENTA}" "${SYM_INFO}" "${C_RESET}" "${C_RESET}"
    printf "      %s%s%s @GetBridgesBot (Telegram)%s\n" "${C_BLUE}" "${SYM_INFO}" "${C_RESET}" "${C_RESET}"
    
    echo ""
    print_subsection_end
    echo ""
    
    # OBFS4 bridges
    if pkg info obfs4proxy-tor >/dev/null 2>&1; then
        printf "    %s%s%s Enter OBFS4 bridges %s(empty line to finish)%s\n" "${C_BCYAN}" "${SYM_TRIANGLE}" "${C_RESET}" "${C_DIM}" "${C_RESET}"
        echo ""
        
        OBFS4_BRIDGES=""
        while true; do
            printf "      %sobfs4>%s " "${C_PURPLE}" "${C_RESET}"
            read bridge_line
            [ -z "$bridge_line" ] && break
            
            if echo "$bridge_line" | grep -q "^Bridge"; then
                OBFS4_BRIDGES="${OBFS4_BRIDGES}${bridge_line}\n"
            elif echo "$bridge_line" | grep -q "^obfs4"; then
                OBFS4_BRIDGES="${OBFS4_BRIDGES}Bridge ${bridge_line}\n"
            else
                OBFS4_BRIDGES="${OBFS4_BRIDGES}Bridge obfs4 ${bridge_line}\n"
            fi
        done
    fi
    
    # WebTunnel bridges
    if pkg info webtunnel-tor >/dev/null 2>&1; then
        echo ""
        printf "    %s%s%s Enter WebTunnel bridges %s(empty line to finish)%s\n" "${C_BCYAN}" "${SYM_TRIANGLE}" "${C_RESET}" "${C_DIM}" "${C_RESET}"
        echo ""
        
        WEBTUNNEL_BRIDGES=""
        while true; do
            printf "      %swebtunnel>%s " "${C_CYAN}" "${C_RESET}"
            read bridge_line
            [ -z "$bridge_line" ] && break
            
            if echo "$bridge_line" | grep -q "^Bridge"; then
                WEBTUNNEL_BRIDGES="${WEBTUNNEL_BRIDGES}${bridge_line}\n"
            elif echo "$bridge_line" | grep -q "^webtunnel"; then
                WEBTUNNEL_BRIDGES="${WEBTUNNEL_BRIDGES}Bridge ${bridge_line}\n"
            else
                WEBTUNNEL_BRIDGES="${WEBTUNNEL_BRIDGES}Bridge webtunnel ${bridge_line}\n"
            fi
        done
    fi
    
    echo ""
    if [ -n "$OBFS4_BRIDGES" ] || [ -n "$WEBTUNNEL_BRIDGES" ]; then
        print_success "Bridges configured"
    else
        print_warning "No bridges entered - add them later to ${TORRC_PATH}"
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# TOR CONFIGURATION
# ════════════════════════════════════════════════════════════════════════════

configure_ipv6() {
    print_section_header "IPv6 Configuration" "${SYM_GLOBE}"
    
    print_info "IPv6 can improve Tor connectivity"
    echo ""
    
    if prompt_yes_no "Enable IPv6 in Tor?" "Y"; then
        USE_IPV6="yes"
        print_success "IPv6 enabled"
    else
        USE_IPV6="no"
        print_info "IPv6 disabled"
    fi
}

generate_torrc() {
    print_section_header "Generating Tor Configuration" "${SYM_FILE}"
    
    # Backup existing config
    if [ -f "$TORRC_PATH" ]; then
        local backup="${TORRC_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$TORRC_PATH" "$backup"
        print_info "Backed up existing config to:"
        print_subaction "${backup}"
    fi
    
    # Generate torrc
    print_action "Writing configuration..."
    
    cat > "$TORRC_PATH" << EOF
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                                                                           ║
# ║                    AntiZapret TOR Configuration                           ║
# ║                      for OPNsense / FreeBSD                               ║
# ║                                                                           ║
# ║  Generated: $(date '+%Y-%m-%d %H:%M:%S')
# ║  Version: ${VERSION}
# ║                                                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

# ─────────────────────────────────────────────────────────────────────────────
# USER CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────
# Run Tor as this user (do not run as root!)
# User ${TOR_USER}

# ─────────────────────────────────────────────────────────────────────────────
# DATA DIRECTORY
# ─────────────────────────────────────────────────────────────────────────────
# DataDirectory stores keys, cached directory, etc.
# Must be owned by ${TOR_USER} with permissions 700
# DataDirectory ${DATA_DIR}

# ─────────────────────────────────────────────────────────────────────────────
# LOGGING
# ─────────────────────────────────────────────────────────────────────────────
# Log levels: debug, info, notice, warn, err
# Log notice file ${LOG_DIR}/notices.log
# Log info file ${LOG_DIR}/info.log
# Log debug file ${LOG_DIR}/debug.log (uncomment for debugging)
# Log notice file ${LOG_DIR}/notices.log

# ─────────────────────────────────────────────────────────────────────────────
# PID FILE
# ─────────────────────────────────────────────────────────────────────────────
# PidFile ${PID_DIR}/tor.pid

# ─────────────────────────────────────────────────────────────────────────────
# DNS CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────
# DNSPort - Tor will respond to DNS requests on this port
# Configure clients to use this as their DNS server for .onion resolution
#
# Uncomment the line below if you want Tor to handle DNS on port 53:
# DNSPort ${LOCAL_IP}:53

# DNS proxy for Tor resolution
DNSPort 127.0.0.1:9053
DNSPort ${LOCAL_IP}:9053

# ─────────────────────────────────────────────────────────────────────────────
# VIRTUAL ADDRESS MAPPING
# ─────────────────────────────────────────────────────────────────────────────
# When a hostname is requested that ends with .onion, Tor maps it to an
# internal IP address. This is used for transparent proxying.
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1

# ─────────────────────────────────────────────────────────────────────────────
# DAEMON MODE
# ─────────────────────────────────────────────────────────────────────────────
# Run Tor in background as a daemon
RunAsDaemon 1

# ─────────────────────────────────────────────────────────────────────────────
# SOCKS PROXY
# ─────────────────────────────────────────────────────────────────────────────
# SocksPort - SOCKS5 proxy for applications to connect through Tor
# Applications can be configured to use localhost:9050 or LAN_IP:9050
SocksPort 127.0.0.1:9050
SocksPort ${LOCAL_IP}:9050

# Optional: IsolateClientAddr - give each client a different circuit
# SocksPort ${LOCAL_IP}:9050 IsolateClientAddr IsolateSOCKSAuth

# ─────────────────────────────────────────────────────────────────────────────
# TRANSPARENT PROXY
# ─────────────────────────────────────────────────────────────────────────────
# TransPort - Used for transparent proxying with firewall rules
# Traffic redirected to this port will be sent through Tor
TransPort 127.0.0.1:9040

# Optional: Bind to specific interface
# TransPort ${LOCAL_IP}:9040

# ─────────────────────────────────────────────────────────────────────────────
# EXIT POLICY (Relay disabled - client only)
# ─────────────────────────────────────────────────────────────────────────────
# This node is a client only, not an exit relay
ExitPolicy reject *:*
ExitPolicy reject6 *:*
ExitRelay 0

# ─────────────────────────────────────────────────────────────────────────────
# NODE RESTRICTIONS
# ─────────────────────────────────────────────────────────────────────────────
# Exclude CIS and nearby countries for privacy
# Country codes: https://b3rn3d.herokuapp.com/blog/2014/03/05/tor-country-codes
#
# {RU} - Russia
# {BY} - Belarus  
# {KZ} - Kazakhstan
# {KG} - Kyrgyzstan
# {UZ} - Uzbekistan
# {TJ} - Tajikistan
# {TM} - Turkmenistan
# {AZ} - Azerbaijan
# {AM} - Armenia
# {TR} - Turkey
#
ExcludeNodes {RU}, {BY}, {KZ}, {KG}, {UZ}, {TJ}, {TM}, {AZ}, {AM}, {TR}
ExcludeExitNodes {RU}, {BY}, {KZ}, {KG}, {UZ}, {TJ}, {TM}, {AZ}, {AM}, {TR}

# StrictNodes - If set to 1, Tor will fail to operate if it cannot find
# a path that avoids the excluded nodes
StrictNodes 1

# Optional: Prefer specific exit countries (uncomment to use)
# ExitNodes {PL}, {DE}, {NL}, {SE}, {CH}

# ─────────────────────────────────────────────────────────────────────────────
# PERFORMANCE & MISC SETTINGS  
# ─────────────────────────────────────────────────────────────────────────────
# HeartbeatPeriod - How often to log heartbeat message
HeartbeatPeriod 1 hours

# CircuitBuildTimeout - How long to wait for a circuit to be built
# CircuitBuildTimeout 60

# LearnCircuitBuildTimeout - Let Tor learn the best timeout
# LearnCircuitBuildTimeout 1

# NumEntryGuards - Number of entry guards to use
# NumEntryGuards 3

# KeepalivePeriod - Send keepalive to keep connections open
# KeepalivePeriod 60

# NewCircuitPeriod - How often to build a new circuit
# NewCircuitPeriod 30

# MaxCircuitDirtiness - How long to use a circuit before building new one
# MaxCircuitDirtiness 600

EOF

    # Add transport plugins section
    local has_obfs4=$(pkg info obfs4proxy-tor >/dev/null 2>&1 && echo "yes" || echo "no")
    local has_webtunnel=$(pkg info webtunnel-tor >/dev/null 2>&1 && echo "yes" || echo "no")
    
    if [ "$has_obfs4" = "yes" ] || [ "$has_webtunnel" = "yes" ]; then
        cat >> "$TORRC_PATH" << 'EOF'
# ─────────────────────────────────────────────────────────────────────────────
# TRANSPORT PLUGINS
# ─────────────────────────────────────────────────────────────────────────────
# Pluggable transports allow Tor to use different protocols to avoid detection
# 
# obfs4 - Looks like random noise, most commonly used
# webtunnel - Looks like regular HTTPS traffic
#
EOF
        
        if [ "$has_obfs4" = "yes" ]; then
            echo "ClientTransportPlugin obfs4 exec /usr/local/bin/obfs4proxy managed" >> "$TORRC_PATH"
        else
            echo "# ClientTransportPlugin obfs4 exec /usr/local/bin/obfs4proxy managed" >> "$TORRC_PATH"
        fi
        
        if [ "$has_webtunnel" = "yes" ]; then
            echo "ClientTransportPlugin webtunnel exec /usr/local/bin/webtunnel-tor-client" >> "$TORRC_PATH"
        else
            echo "# ClientTransportPlugin webtunnel exec /usr/local/bin/webtunnel-tor-client" >> "$TORRC_PATH"
        fi
        
        echo "" >> "$TORRC_PATH"
    fi

    # Add IPv6 configuration
    cat >> "$TORRC_PATH" << EOF
# ─────────────────────────────────────────────────────────────────────────────
# IPv6 CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────
# ClientUseIPv6 - Whether to use IPv6 for outgoing connections
# ClientUseIPv4 - Whether to use IPv4 for outgoing connections
# ClientPreferIPv6ORPort - Prefer IPv6 when connecting to relays
#
EOF
    
    if [ "$USE_IPV6" = "yes" ]; then
        cat >> "$TORRC_PATH" << 'EOF'
ClientUseIPv6 1
ClientUseIPv4 1
ClientPreferIPv6ORPort 1
EOF
    else
        cat >> "$TORRC_PATH" << 'EOF'
ClientUseIPv6 0
ClientPreferIPv6ORPort 0
EOF
    fi
    
    echo "" >> "$TORRC_PATH"

    # Add bridge configuration
    cat >> "$TORRC_PATH" << 'EOF'
# ─────────────────────────────────────────────────────────────────────────────
# BRIDGE CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────
# UseBridges - Whether to use bridge relays
# Bridges help bypass censorship by making Tor traffic look like other traffic
#
# To get bridges:
#   1. Web: https://bridges.torproject.org/
#   2. Email: bridges@torproject.org (send empty email)
#   3. Telegram: @GetBridgesBot
#
# Bridge line format:
#   Bridge obfs4 IP:PORT FINGERPRINT cert=CERT iat-mode=0
#   Bridge webtunnel IP:PORT FINGERPRINT url=https://... ver=0.0.3
#
EOF

    if [ "$USE_BRIDGES" = "yes" ] && { [ -n "$OBFS4_BRIDGES" ] || [ -n "$WEBTUNNEL_BRIDGES" ]; }; then
        echo "UseBridges 1" >> "$TORRC_PATH"
        echo "" >> "$TORRC_PATH"
        
        if [ -n "$OBFS4_BRIDGES" ]; then
            echo "# OBFS4 Bridges" >> "$TORRC_PATH"
            printf "%b" "$OBFS4_BRIDGES" >> "$TORRC_PATH"
            echo "" >> "$TORRC_PATH"
        fi
        
        if [ -n "$WEBTUNNEL_BRIDGES" ]; then
            echo "# WebTunnel Bridges" >> "$TORRC_PATH"
            printf "%b" "$WEBTUNNEL_BRIDGES" >> "$TORRC_PATH"
            echo "" >> "$TORRC_PATH"
        fi
    else
        cat >> "$TORRC_PATH" << 'EOF'
UseBridges 0

# Example bridge lines (uncomment and modify to use):
# Bridge obfs4 192.0.2.1:443 FINGERPRINT cert=CERTIFICATE iat-mode=0
# Bridge webtunnel 192.0.2.2:443 FINGERPRINT url=https://example.com/path ver=0.0.3

EOF
    fi

    # Add additional commented options
    cat >> "$TORRC_PATH" << 'EOF'
# ─────────────────────────────────────────────────────────────────────────────
# ADDITIONAL OPTIONS (uncomment to enable)
# ─────────────────────────────────────────────────────────────────────────────

# ControlPort - Allows external programs to control Tor
# ControlPort 9051
# HashedControlPassword (generate with: tor --hash-password "password")

# CookieAuthentication - Alternative to password for control port
# CookieAuthentication 1

# DisableDebuggerAttachment - Prevent debugging (security)
# DisableDebuggerAttachment 1

# SafeLogging 1 - Scrub sensitive info from logs
# SafeLogging 1

# ─────────────────────────────────────────────────────────────────────────────
# END OF CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────
EOF

    # Set proper ownership for torrc
    chown root:${TOR_GROUP} "$TORRC_PATH"
    chmod 640 "$TORRC_PATH"

    print_success "Configuration written to ${TORRC_PATH}"
}

create_tor_rc_script() {
    print_action "Creating Tor rc.d script..."
    
    cat > "$TOR_RC_SCRIPT" << 'RCEOF'
	
#!/bin/sh

# PROVIDE: tor
# REQUIRE: DAEMON FILESYSTEMS
# BEFORE: LOGIN
#
# Add the following lines to /etc/rc.conf to enable tor.
# All these options will overide any settings in your local torrc as
# they are command line options.
#
# tor_enable (bool):	Set it to "YES" to enable tor. Default: YES
# tor_instances (str):	List of instances. Default: ""
# tor_conf (str):	Points to your torrc file.
#			Default: /usr/local/etc/tor/torrc
# tor_flags (str):	Additional flags.  Common to all instances.
# tor_user (str):	Tor daemon user. Default: _tor
# tor_group (str):	Tor group. Default: _tor
# tor_pidfile (str):	Tor pid file.  Default: /var/run/tor/tor.pid
# tor_datadir (str):	Tor datadir.  Default: /var/db/tor
# tor_disable_default_instance (str):	Doesn't run the default instance.
#			Only valid when tor_instances is used.
#			Default: YES
# tor_setuid (str):	Runtime setuid.  Default: YES
#

. /etc/rc.subr

name="tor"
rcvar=tor_enable
exit_code=0

load_rc_config ${name}

: ${tor_enable="YES"}
: ${tor_instances=""}
: ${tor_conf="/usr/local/etc/tor/torrc"}
: ${tor_flags=""}
: ${tor_user="_tor"}
: ${tor_group="_tor"}
: ${tor_pidfile="/var/run/tor/tor.pid"}
: ${tor_datadir="/var/db/tor"}
: ${tor_disable_default_instance="YES"}
: ${tor_setuid="YES"}

instance=${slave_instance}
if [ -n "${instance}" ]; then
  inst_def=${instance}
  inst_name=${inst_def%%:*}
  [ "${inst_name}" != "main" ] || err 1 "${name} instance can't be named 'main'"
  inst_def=${inst_def#$inst_name}
  if [ -n "$inst_def" ]; then
    # extended instance: parameters are set explicitly
    inst_def=${inst_def#:}
    tor_conf=${inst_def%%:*}
    inst_def=${inst_def#$tor_conf:}
    tor_user=${inst_def%%:*}
    inst_def=${inst_def#$tor_user:}
    tor_group=${inst_def%%:*}
    inst_def=${inst_def#$tor_group:}
    tor_pidfile=${inst_def%%:*}
    tor_datadir=${inst_def#$tor_pidfile:}
    if [ -z "${tor_conf}" -o -z "${tor_user}" -o -z "${tor_group}" -o -z "${tor_pidfile}" -o -z "${tor_datadir}" ]; then
      warn "invalid tor instance ${inst_name} settings: ${instance}"
      exit 1
    fi
  else
    # regular instance: default parameters are used
    tor_conf=${tor_conf}@${inst_name}
    tor_pidfile=${tor_pidfile}@${inst_name}
    tor_datadir=${tor_datadir}/instance@${inst_name}
  fi
  if ! [ -r ${tor_conf} ]; then
    warn "tor instance ${inst_name} config file ${tor_conf} doesn't exist or isn't readable"
    warn "you can copy the sample config /usr/local/etc/tor/torrc.sample and modify it"
    exit 1
  fi
  if ! [ -d ${tor_datadir} ]; then
    mkdir -p ${tor_datadir} &&
    chown ${tor_user}:${tor_group} ${tor_datadir} &&
    chmod 0700 ${tor_datadir} &&
    echo "${name}: created the instance data directory ${tor_datadir}"
  fi
fi

if [ -z "${instance}" -a -n "${tor_instances}" ]; then
  inst_only="$2"
  inst_done=0
  for i in ${tor_instances}; do
    inst_name=${i%%:*}
    if [ -z "${inst_only}" -o "${inst_name}" = "${inst_only}" ]; then
      echo -n "${name} instance ${inst_name}: "
      if ! slave_instance=${i} /usr/local/etc/rc.d/tor "$1"; then
        exit_code=1
      fi
      inst_done=$((inst_done+1))
    fi
  done
  if [ -z "${inst_only}" -o "${inst_only}" = "main" ]; then
    checkyesYES tor_disable_default_instance && return $exit_code
    echo -n "${name} main instance: "
  elif [ -n "${inst_only}" ]; then
    [ $inst_done -gt 0 ] || err 1 "${name} instance '$inst_only' isn't defined"
    return  $exit_code
  fi
fi

required_files=${tor_conf}
required_dirs=${tor_datadir}
pidfile=${tor_pidfile}
command="/usr/local/bin/${name}"
command_args="-f ${tor_conf} --PidFile ${tor_pidfile} --RunAsDaemon 1 --DataDirectory ${tor_datadir} ${tor_flags}"
extra_commands="reload"

# clear user setting in conf file: it should be done through the command line
if grep -q "^User ${tor_user}$" ${tor_conf}; then
  sed -i '' -e "s/^User ${tor_user}$//" ${tor_conf}
fi

if [ $tor_setuid = "YES" ]; then
  command_args="${command_args} --User ${tor_user}"
  tor_user="root"
  tor_group="wheel"
fi

if ! run_rc_command "$1"; then
  exit_code=1
fi

return $exit_code

RCEOF

    chmod +x "$TOR_RC_SCRIPT"
    print_success "Tor rc.d script created: ${TOR_RC_SCRIPT}"
}

create_tor_rc_conf() {
    print_action "Creating Tor rc.conf.d configuration..."
    
    # Create /etc/rc.conf.d directory if it doesn't exist
    mkdir -p /etc/rc.conf.d
    
    cat > "$TOR_RC_CONF" << EOF
# Tor configuration for rc.d
# Generated by AntiZapret Installer v${VERSION}

tor_enable="YES"
# tor_conf="${TORRC_PATH}"
# tor_user="${TOR_USER}"
# tor_group="${TOR_GROUP}"
# tor_pidfile="${PID_DIR}/tor.pid"
# tor_datadir="${DATA_DIR}"
# tor_logdir="${LOG_DIR}"
EOF

    print_success "Tor rc.conf.d created: ${TOR_RC_CONF}"
}

setup_autostart() {
    print_action "Configuring Tor autostart..."
    
    # Create rc.d script
    create_tor_rc_script
    
    # Create rc.conf.d/tor configuration
    create_tor_rc_conf
    
    # Also add to main rc.conf for compatibility
    sysrc tor_enable="YES" >/dev/null 2>&1
    
    print_success "Tor autostart configured"
}

install_antizapret() {
    print_section_header "Installing AntiZapret" "${SYM_SHIELD}"
    
    if ! command -v git >/dev/null 2>&1; then
        print_warning "Git not installed, trying to install..."
        install_opnsense_package "git" "Git"
        
        if ! command -v git >/dev/null 2>&1; then
            print_error "Cannot install AntiZapret without git"
            return 1
        fi
    fi
    
    print_action "Cloning AntiZapret repository..."
    
    if [ ! -d "$SCRIPT_DIR" ]; then
        cd /root
        if git clone https://github.com/Limych/antizapret.git >/dev/null 2>&1; then
            print_success "Repository cloned"
        else
            print_error "Failed to clone repository"
            return 1
        fi
    else
        cd "$SCRIPT_DIR"
        git pull >/dev/null 2>&1 || true
        print_success "Repository updated"
    fi
    
    if [ -f "${SCRIPT_DIR}/antizapret.pl" ]; then
        chmod +x "${SCRIPT_DIR}/antizapret.pl"
        
        print_action "Updating IP list..."
        
        if "${SCRIPT_DIR}/antizapret.pl" > "$IP_LIST_PATH" 2>/dev/null; then
            local count=$(wc -l < "$IP_LIST_PATH" | tr -d ' ')
            print_success "IP list: ${count} entries"
        else
            print_warning "IP list update failed - will retry on cron"
        fi
    fi
}

configure_opnsense() {
    if [ "$IS_OPNSENSE" != "yes" ]; then
        return
    fi
    
    print_section_header "OPNsense Integration" "${SYM_GEAR}"
    
    mkdir -p "$ACTIONS_DIR"
    
    # AntiZapret action
    cat > "${ACTIONS_DIR}/actions_antizapret.conf" << 'EOF'
[cron-iplist-renew]
command:/root/antizapret/antizapret.pl | tee /usr/local/www/ipfw_antizapret.dat | xargs pfctl -t AntiZapret_IPs -T add
parameters:
type:script
message:Renew AntiZapret IP-list
description:Renew AntiZapret IP-list
EOF
    print_success "AntiZapret action created"

    # Tor actions
    cat > "${ACTIONS_DIR}/actions_tor.conf" << 'EOF'
[start]
command:service tor start
parameters:
type:script
message:Starting TOR
description:Start TOR service

[stop]
command:service tor stop
parameters:
type:script
message:Stopping TOR
description:Stop TOR service

[restart]
command:service tor restart
parameters:
type:script
message:Restarting TOR
description:Restart TOR service

[status]
command:service tor status
parameters:
type:script
message:TOR status
description:Check TOR status
EOF
    print_success "Tor actions created"

    service configd restart >/dev/null 2>&1 || true
    print_success "OPNsense configured"
}

# ════════════════════════════════════════════════════════════════════════════
# SERVICE MANAGEMENT
# ════════════════════════════════════════════════════════════════════════════

start_tor_service() {
    print_section_header "Starting Tor" "${SYM_ROCKET}"
    
    # Проверяем наличие пользователя и группы _tor
    print_action "Checking Tor user and group..."
    if ! pw showuser "${TOR_USER}" >/dev/null 2>&1; then
        print_error "User ${TOR_USER} does not exist!"
        print_info "Creating user ${TOR_USER}..."
        if ! pw groupadd -n "${TOR_GROUP}" -g 91 2>/dev/null; then
            print_warning "Group ${TOR_GROUP} may already exist"
        fi
        
        if ! pw useradd -n "${TOR_USER}" -u 91 -d /var/db/tor -s /usr/sbin/nologin -g "${TOR_GROUP}" -c "Tor Daemon User" 2>/dev/null; then
            print_warning "User ${TOR_USER} may already exist"
        fi
    else
        print_success "User ${TOR_USER} exists"
    fi
    
    # Verify configuration
    print_action "Verifying Tor configuration..."
    if tor --verify-config -f "$TORRC_PATH" >/dev/null 2>&1; then
        print_success "Configuration is valid"
    else
        print_error "Configuration validation failed!"
        print_info "Run: tor --verify-config -f ${TORRC_PATH}"
        return 1
    fi
    
    # First try to start with service command
    print_action "Starting Tor service..."
    
    # Stop if running
    if pgrep -x tor >/dev/null 2>&1; then
        print_subaction "Stopping existing Tor..."
        service tor stop >/dev/null 2>&1 || pkill tor 2>/dev/null || true
        sleep 2
    fi
    
    # Remove stale PID file
    rm -f "${PID_DIR}/tor.pid" 2>/dev/null
    
    # Try service command first
    if service tor start 2>&1; then
        countdown 3 "Waiting for service to start"
    else
        print_warning "Service command failed, trying direct start..."
        # If service fails, try direct start
        if su -m "${TOR_USER}" -c "/usr/local/bin/tor -f ${TORRC_PATH} --RunAsDaemon 1 --PidFile ${PID_DIR}/tor.pid" 2>&1; then
            print_success "Tor started directly"
        else
            print_error "Failed to start Tor"
            print_info "Trying one more method..."
            # Last attempt with different user context
            /usr/local/bin/tor -f "${TORRC_PATH}" --RunAsDaemon 1 --PidFile "${PID_DIR}/tor.pid" 2>&1 || true
        fi
    fi
    
    # Wait and check if running
    countdown 5 "Checking Tor status"
    
    if pgrep -x tor >/dev/null 2>&1; then
        local tor_pid=$(pgrep -x tor)
        local tor_user_running=$(ps -o user= -p $tor_pid 2>/dev/null | tr -d ' ')
        print_success "Tor is running! (PID: ${tor_pid}, User: ${tor_user_running})"
        
        # Check if listening on required ports
        print_subaction "Checking open ports..."
        local socks_port=$(sockstat -4l 2>/dev/null | grep ":9050" | grep "tor" | wc -l | tr -d ' ')
        local trans_port=$(sockstat -4l 2>/dev/null | grep ":9040" | grep "tor" | wc -l | tr -d ' ')
        
        if [ "$socks_port" -gt 0 ]; then
            print_subaction "SOCKS port 9050: OK"
        else
            print_warning "SOCKS port 9050 not listening"
        fi
        
        if [ "$trans_port" -gt 0 ]; then
            print_subaction "TransPort 9040: OK"
        else
            print_warning "TransPort 9040 not listening"
        fi
        
        # Show log tail
        if [ -f "${LOG_DIR}/notices.log" ]; then
            print_subaction "Last 3 lines of log:"
            tail -3 "${LOG_DIR}/notices.log" | sed 's/^/        /'
        fi
        
        return 0
    else
        print_error "Tor is not running"
        
        # Check logs for errors
        if [ -f "${LOG_DIR}/notices.log" ]; then
            print_subaction "Last 5 lines of log:"
            tail -5 "${LOG_DIR}/notices.log" | sed 's/^/        /'
        fi
        
        # Try manual start for debugging
        print_info "Trying manual start for debugging..."
        echo ""
        printf "      %sCommand: %s%s\n" "${C_YELLOW}" "tor -f ${TORRC_PATH}" "${C_RESET}"
        echo ""
        
        if tor -f "${TORRC_PATH}" 2>&1 | head -20; then
            print_info "Manual start successful, but not in daemon mode"
        else
            print_error "Manual start also failed"
        fi
        
        return 1
    fi
}

verify_installation() {
    print_section_header "Verification" "${SYM_CHECK}"
    
    local errors=0
    local warnings=0
    
    print_subsection "Services"
    echo ""
    
    if pgrep -x tor >/dev/null 2>&1; then
        local tor_pid=$(pgrep -x tor)
        local tor_user_running=$(ps -o user= -p $tor_pid 2>/dev/null | tr -d ' ')
        print_key_value_status "Tor Process" "Running as ${tor_user_running} (PID: ${tor_pid})" "ok"
    else
        print_key_value_status "Tor Process" "Not running" "error"
        errors=$((errors + 1))
    fi
    
    if sockstat -4l 2>/dev/null | grep -q ":9050.*tor"; then
        print_key_value_status "SOCKS (9050)" "OK" "ok"
    else
        print_key_value_status "SOCKS (9050)" "Not listening" "warn"
        warnings=$((warnings + 1))
    fi
    
    if sockstat -4l 2>/dev/null | grep -q ":9053.*tor"; then
        print_key_value_status "DNS (9053)" "OK" "ok"
    else
        print_key_value_status "DNS (9053)" "Not listening" "warn"
        warnings=$((warnings + 1))
    fi
    
    if sockstat -4l 2>/dev/null | grep -q ":9040.*tor"; then
        print_key_value_status "TransPort (9040)" "OK" "ok"
    else
        print_key_value_status "TransPort (9040)" "Not listening" "warn"
        warnings=$((warnings + 1))
    fi
    
    echo ""
    print_subsection_end
    echo ""
    
    print_subsection "Files & Permissions"
    echo ""
    
    if [ -f "$TORRC_PATH" ]; then
        print_key_value_status "Tor Config" "OK" "ok"
    else
        print_key_value_status "Tor Config" "Missing" "error"
        errors=$((errors + 1))
    fi
    
    if [ -f "$TOR_RC_SCRIPT" ] && [ -x "$TOR_RC_SCRIPT" ]; then
        print_key_value_status "RC Script" "OK" "ok"
    else
        print_key_value_status "RC Script" "Missing or not executable" "warn"
        warnings=$((warnings + 1))
    fi
    
    if [ -f "$TOR_RC_CONF" ]; then
        print_key_value_status "RC Conf" "OK" "ok"
    else
        print_key_value_status "RC Conf" "Missing" "warn"
        warnings=$((warnings + 1))
    fi
    
    # Check directory permissions
    if [ -d "$DATA_DIR" ]; then
        local data_owner=$(stat -f '%Su:%Sg' "$DATA_DIR" 2>/dev/null)
        if [ "$data_owner" = "${TOR_USER}:${TOR_GROUP}" ]; then
            print_key_value_status "Data Dir" "${DATA_DIR} (${data_owner})" "ok"
        else
            print_key_value_status "Data Dir" "${DATA_DIR} (${data_owner}) - should be ${TOR_USER}:${TOR_GROUP}" "warn"
            warnings=$((warnings + 1))
        fi
    else
        print_key_value_status "Data Dir" "Missing - will be created by OPNsense" "warn"
        warnings=$((warnings + 1))
    fi
    
    if [ -f "$IP_LIST_PATH" ]; then
        local count=$(wc -l < "$IP_LIST_PATH" | tr -d ' ')
        print_key_value_status "IP List" "${count} entries" "ok"
    else
        print_key_value_status "IP List" "Missing" "warn"
        warnings=$((warnings + 1))
    fi
    
    if grep -q 'tor_enable="YES"' /etc/rc.conf 2>/dev/null || [ -f "$TOR_RC_CONF" ]; then
        print_key_value_status "Autostart" "Enabled" "ok"
    else
        print_key_value_status "Autostart" "Disabled" "warn"
        warnings=$((warnings + 1))
    fi
    
    echo ""
    print_subsection_end
    
    # Show transport plugins status if bridges are used
    if [ "$USE_BRIDGES" = "yes" ]; then
        echo ""
        print_subsection "Transport Plugins"
        echo ""
        
        if [ -x "/usr/local/bin/obfs4proxy" ]; then
            print_key_value_status "OBFS4" "Available" "ok"
        else
            print_key_value_status "OBFS4" "Not installed" "warn"
            warnings=$((warnings + 1))
        fi
        
        if [ -x "/usr/local/bin/webtunnel-tor-client" ]; then
            print_key_value_status "WebTunnel" "Available" "ok"
        else
            print_key_value_status "WebTunnel" "Not installed" "warn"
            warnings=$((warnings + 1))
        fi
        
        echo ""
        print_subsection_end
    fi
    
    # Check pkg status on OPNsense
    if [ "$IS_OPNSENSE" = "yes" ]; then
        echo ""
        print_subsection "Package Manager Status"
        echo ""
        
        local pkg_version=$(pkg -v 2>/dev/null || echo "unknown")
        local pkg_origin=$(pkg query %o pkg 2>/dev/null || echo "unknown")
        
        print_key_value_status "pkg version" "${pkg_version}" "ok"
        
        if echo "$pkg_origin" | grep -qi "opnsense"; then
            print_key_value_status "pkg source" "OPNsense repository" "ok"
        elif [ "$pkg_origin" = "ports-mgmt/pkg" ]; then
            print_key_value_status "pkg source" "FreeBSD ports (normal)" "ok"
        else
            print_key_value_status "pkg source" "${pkg_origin}" "warn"
            warnings=$((warnings + 1))
        fi
        
        echo ""
        print_subsection_end
    fi
    
    echo ""
    
    if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
        print_success "All checks passed!"
    elif [ $errors -eq 0 ]; then
        print_warning "${warnings} warning(s) - installation mostly successful"
    else
        print_error "${errors} error(s) found - please check configuration"
    fi
    
    return $errors
}

# ════════════════════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ════════════════════════════════════════════════════════════════════════════

print_final_summary() {
    echo ""
    printf "%s" "${C_BGREEN}"
    cat << 'EOF'
    ╔═══════════════════════════════════════════════════════════════════════╗
    ║                                                                       ║
    ║         ★ ★ ★  INSTALLATION COMPLETED SUCCESSFULLY  ★ ★ ★           ║
    ║                                                                       ║
    ╚═══════════════════════════════════════════════════════════════════════╝
EOF
    printf "%s" "${C_RESET}"
    
    echo ""
    print_subsection "Installation Summary"
    echo ""
    
    print_key_value "LAN IP" "${LOCAL_IP}" "${SYM_GLOBE}" "${C_BLUE}"
    print_key_value "IPv6" "$([ "$USE_IPV6" = "yes" ] && echo "Enabled" || echo "Disabled")" "${SYM_GEAR}" "${C_MAGENTA}"
    
    local bridge_status
    if [ "$USE_BRIDGES" = "yes" ]; then
        if [ -n "$OBFS4_BRIDGES" ] || [ -n "$WEBTUNNEL_BRIDGES" ]; then
            bridge_status="Configured"
        else
            bridge_status="Plugins installed"
        fi
    else
        bridge_status="Direct connection"
    fi
    print_key_value "Bridges" "${bridge_status}" "${SYM_LOCK}" "${C_PURPLE}"
    
    local opnsense_status
    [ "$IS_OPNSENSE" = "yes" ] && opnsense_status="Integrated" || opnsense_status="N/A"
    print_key_value "OPNsense" "${opnsense_status}" "${SYM_SHIELD}" "${C_GREEN}"
    
    echo ""
    print_subsection_end
    
    # OPNsense configuration steps
    print_section_header "OPNsense Configuration Steps" "${SYM_INFO}"
    
    echo ""
    printf "    %s STEP 1 %s %sCreate Firewall Alias%s\n" "${C_BG_BLUE}${C_BWHITE}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
    echo ""
    printf "      %s%s%s Navigate to: %sFirewall → Aliases → Add%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_CYAN}" "${C_RESET}"
    printf "      %s%s%s Name: %sAntiZapret_IPs%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    printf "      %s%s%s Type: %sExternal (advanced)%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    printf "      %s%s%s Content URL: %shttp://%s/ipfw_antizapret.dat%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_BBLUE}" "${LOCAL_IP}" "${C_RESET}"
    
    echo ""
    printf "    %s STEP 2 %s %sSetup NAT Port Forward%s\n" "${C_BG_GREEN}${C_BWHITE}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
    echo ""
    printf "      %s%s%s Navigate to: %sFirewall → NAT → Port Forward → Add%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_CYAN}" "${C_RESET}"
    printf "      %s%s%s Interface: %sLAN%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    printf "      %s%s%s Protocol: %sTCP%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    printf "      %s%s%s Destination: %sAntiZapret_IPs%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    printf "      %s%s%s Redirect target IP: %s127.0.0.1%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    printf "      %s%s%s Redirect target port: %s9040%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    
    echo ""
    printf "    %s STEP 3 %s %sSchedule Daily Updates%s\n" "${C_BG_YELLOW}${C_BLACK}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
    echo ""
    printf "      %s%s%s Navigate to: %sSystem → Settings → Cron → Add%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_CYAN}" "${C_RESET}"
    printf "      %s%s%s Command: %sRenew AntiZapret IP-list%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    printf "      %s%s%s Schedule: %sDaily (e.g., 4:00 AM)%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    
    # Commands Reference
    print_section_header "Command Reference" "${SYM_GEAR}"
    
    echo ""
    print_subsection "Tor Service Management"
    echo ""
    
    printf "      %s%-40s%s %s%s%s\n" "${C_CYAN}" "service tor status" "${C_RESET}" "${C_DIM}" "Check service status" "${C_RESET}"
    printf "      %s%-40s%s %s%s%s\n" "${C_CYAN}" "service tor start" "${C_RESET}" "${C_DIM}" "Start Tor" "${C_RESET}"
    printf "      %s%-40s%s %s%s%s\n" "${C_CYAN}" "service tor stop" "${C_RESET}" "${C_DIM}" "Stop Tor" "${C_RESET}"
    printf "      %s%-40s%s %s%s%s\n" "${C_CYAN}" "service tor restart" "${C_RESET}" "${C_DIM}" "Restart Tor" "${C_RESET}"
    printf "      %s%-40s%s %s%s%s\n" "${C_CYAN}" "service tor reload" "${C_RESET}" "${C_DIM}" "Reload configuration" "${C_RESET}"
    
    echo ""
    print_subsection_end
    echo ""
    
    print_subsection "Logs & Monitoring"
    echo ""
    
    printf "      %s%-40s%s %s%s%s\n" "${C_GREEN}" "tail -f ${LOG_DIR}/notices.log" "${C_RESET}" "${C_DIM}" "View live Tor logs" "${C_RESET}"
    printf "      %s%-40s%s %s%s%s\n" "${C_GREEN}" "cat ${IP_LIST_PATH} | wc -l" "${C_RESET}" "${C_DIM}" "Count blocked IPs" "${C_RESET}"
    printf "      %s%-40s%s %s%s%s\n" "${C_GREEN}" "sockstat -4l | grep tor" "${C_RESET}" "${C_DIM}" "Check Tor ports" "${C_RESET}"
    printf "      %s%-40s%s %s%s%s\n" "${C_GREEN}" "ps aux | grep tor" "${C_RESET}" "${C_DIM}" "Check Tor process" "${C_RESET}"
    
    echo ""
    print_subsection_end
    echo ""
    
    print_subsection "Configuration & Troubleshooting"
    echo ""
    
    printf "      %s%-40s%s %s%s%s\n" "${C_YELLOW}" "tor --verify-config -f ${TORRC_PATH}" "${C_RESET}" "${C_DIM}" "Verify configuration" "${C_RESET}"
    printf "      %s%-40s%s %s%s%s\n" "${C_YELLOW}" "cat ${TORRC_PATH}" "${C_RESET}" "${C_DIM}" "View configuration" "${C_RESET}"
    printf "      %s%-40s%s %s%s%s\n" "${C_YELLOW}" "${SCRIPT_DIR}/antizapret.pl" "${C_RESET}" "${C_DIM}" "Update IP list manually" "${C_RESET}"
    printf "      %s%-40s%s %s%s%s\n" "${C_YELLOW}" "cat ${TOR_RC_CONF}" "${C_RESET}" "${C_DIM}" "View rc.conf.d settings" "${C_RESET}"
    
    echo ""
    print_subsection_end
    
    # Configuration Files
    print_section_header "Configuration Files" "${SYM_FILE}"
    
    echo ""
    print_key_value "Tor Configuration" "${TORRC_PATH}" "${SYM_FILE}" "${C_CYAN}"
    print_key_value "Tor RC Script" "${TOR_RC_SCRIPT}" "${SYM_FILE}" "${C_CYAN}"
    print_key_value "Tor RC Config" "${TOR_RC_CONF}" "${SYM_FILE}" "${C_CYAN}"
    print_key_value "IP Blocklist" "${IP_LIST_PATH}" "${SYM_FILE}" "${C_GREEN}"
    print_key_value "Tor Logs" "${LOG_DIR}/notices.log" "${SYM_FILE}" "${C_YELLOW}"
    print_key_value "Tor Data" "${DATA_DIR}" "${SYM_FILE}" "${C_MAGENTA}"
    print_key_value "AntiZapret Script" "${SCRIPT_DIR}/antizapret.pl" "${SYM_FILE}" "${C_BLUE}"
    
    echo ""
    
    # Bridge hint if not using bridges
    if [ "$USE_BRIDGES" != "yes" ]; then
        echo ""
        print_subsection "Adding Bridges Later"
        echo ""
        printf "      %sIf you need to add bridges in the future:%s\n" "${C_DIM}" "${C_RESET}"
        echo ""
        printf "      %s1.%s Install transport plugins:\n" "${C_BWHITE}" "${C_RESET}"
        printf "         %s# Enable FreeBSD repo temporarily and install%s\n" "${C_DIM}" "${C_RESET}"
        printf "         %spkg add %s/obfs4proxy-tor-VERSION.pkg%s\n" "${C_CYAN}" "${PKG_FREEBSD_URL}" "${C_RESET}"
        printf "         %spkg add %s/webtunnel-tor-VERSION.pkg%s\n" "${C_CYAN}" "${PKG_FREEBSD_URL}" "${C_RESET}"
        echo ""
        printf "      %s2.%s Edit configuration:\n" "${C_BWHITE}" "${C_RESET}"
        printf "         %snano %s%s\n" "${C_CYAN}" "${TORRC_PATH}" "${C_RESET}"
        echo ""
        printf "      %s3.%s Set UseBridges 1 and add bridge lines\n" "${C_BWHITE}" "${C_RESET}"
        echo ""
        printf "      %s4.%s Restart Tor:\n" "${C_BWHITE}" "${C_RESET}"
        printf "         %sservice tor restart%s\n" "${C_CYAN}" "${C_RESET}"
        echo ""
        printf "      %s5.%s Restore OPNsense pkg (IMPORTANT!):\n" "${C_BWHITE}" "${C_RESET}"
        printf "         %spkg-static install -r OPNsense -fy pkg%s\n" "${C_CYAN}" "${C_RESET}"
        printf "         %spkg update -f%s\n" "${C_CYAN}" "${C_RESET}"
        echo ""
        print_subsection_end
    fi
    
    # Final warning
    echo ""
    printf "%s%s" "${C_BG_YELLOW}" "${C_BLACK}"
    printf "    ⚠  IMPORTANT: Don't forget to configure firewall rules in OPNsense GUI!  ⚠    "
    printf "%s\n" "${C_RESET}"
    echo ""
    
    # Footer
    print_gradient_line 70
    echo ""
    printf "    %sThank you for using AntiZapret Installer v%s%s\n" "${C_DIM}" "${VERSION}" "${C_RESET}"
    printf "    %sFor issues and updates: %shttps://github.com/Limych/antizapret%s\n" "${C_DIM}" "${C_CYAN}" "${C_RESET}"
    echo ""
    print_gradient_line 70
    echo ""
}

# ════════════════════════════════════════════════════════════════════════════
# CLEANUP
# ════════════════════════════════════════════════════════════════════════════

cleanup() {
    print_action "Performing cleanup..."
    
    # Always restore repository configurations
    if [ -n "$FREEBSD_REPO_BACKUP" ] || [ -n "$OPNSENSE_REPO_BACKUP" ]; then
        restore_repo_configs
    fi
    
    # Ensure FreeBSD repo is disabled
    if [ "$FREEBSD_REPO_ENABLED" = "yes" ]; then
        disable_freebsd_repo
    fi
    
    # Restore OPNsense pkg if needed
    if [ "$PKG_REINSTALL_NEEDED" = "yes" ] && [ "$IS_OPNSENSE" = "yes" ]; then
        restore_opnsense_pkg
    fi
    
    print_success "Cleanup completed"
}

# Set trap for cleanup
trap cleanup EXIT INT TERM HUP

# ════════════════════════════════════════════════════════════════════════════
# MAIN EXECUTION
# ════════════════════════════════════════════════════════════════════════════

main() {
    # Initialize variables
    FREEBSD_REPO_ENABLED="no"
    FREEBSD_REPO_BACKUP=""
    OPNSENSE_REPO_BACKUP=""
    PKG_REINSTALL_NEEDED="no"
    
    # Setup colors
    setup_colors
    
    # Print banner
    print_banner
    
    # Pre-flight checks
    print_section_header "Pre-Installation Checks" "${SYM_GEAR}"
    check_root
    detect_system
    detect_network
    
    # Confirmation
    echo ""
    print_gradient_line 70
    echo ""
    
    if ! prompt_yes_no "Install AntiZapret with Tor?" "Y"; then
        echo ""
        print_info "Installation cancelled by user"
        echo ""
        exit 0
    fi
    
    # Installation steps
    install_optional_packages
    install_tor_packages
    ask_about_bridges
    configure_ipv6
    generate_torrc
    setup_autostart
    install_antizapret
    configure_opnsense
    
    # Restore OPNsense pkg if we installed from FreeBSD repo
    # This is critical step to fix pkg compatibility
    if [ "$PKG_REINSTALL_NEEDED" = "yes" ] && [ "$IS_OPNSENSE" = "yes" ]; then
        restore_opnsense_pkg
    fi
    
    # Start and verify
    start_tor_service
    verify_installation
    
    # Show summary
    print_final_summary
}

# Run main function
main "$@"

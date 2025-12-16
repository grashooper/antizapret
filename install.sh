#!/bin/sh
#
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                                                                           ║
# ║                    AntiZapret Installation Script                         ║
# ║                      for OPNsense / FreeBSD                               ║
# ║                                                                           ║
# ║                           Version 3.0                                     ║
# ║                                                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#

set -e

# ════════════════════════════════════════════════════════════════════════════
# CONFIGURATION & CONSTANTS
# ════════════════════════════════════════════════════════════════════════════

VERSION="3.0"
SCRIPT_NAME="AntiZapret Installer"

# Paths
TORRC_PATH="/usr/local/etc/tor/torrc"
SCRIPT_DIR="/root/antizapret"
LOG_DIR="/var/log/tor"
PID_DIR="/var/run/tor"
IP_LIST_PATH="/usr/local/www/ipfw_antizapret.dat"
ACTIONS_DIR="/usr/local/opnsense/service/conf/actions.d"

# Default settings
USE_IPV6="yes"
OBFS4_BRIDGES=""
WEBTUNNEL_BRIDGES=""
SELECTED_PACKAGES=""
LOCAL_IP=""

# Package URLs base
PKG_BASE_URL="https://pkg.freebsd.org/FreeBSD"

# ════════════════════════════════════════════════════════════════════════════
# COLOR DEFINITIONS
# ════════════════════════════════════════════════════════════════════════════

setup_colors() {
    # Check if colors are supported
    if [ -t 1 ] && [ "${TERM:-dumb}" != "dumb" ]; then
        # Basic colors - using printf to properly interpret escape sequences
        C_RESET=$(printf '\033[0m')
        C_BOLD=$(printf '\033[1m')
        C_DIM=$(printf '\033[2m')
        C_ITALIC=$(printf '\033[3m')
        C_UNDERLINE=$(printf '\033[4m')
        C_BLINK=$(printf '\033[5m')
        C_REVERSE=$(printf '\033[7m')
        
        # Foreground colors
        C_BLACK=$(printf '\033[0;30m')
        C_RED=$(printf '\033[0;31m')
        C_GREEN=$(printf '\033[0;32m')
        C_YELLOW=$(printf '\033[0;33m')
        C_BLUE=$(printf '\033[0;34m')
        C_MAGENTA=$(printf '\033[0;35m')
        C_CYAN=$(printf '\033[0;36m')
        C_WHITE=$(printf '\033[0;37m')
        
        # Bright foreground colors
        C_BRED=$(printf '\033[1;31m')
        C_BGREEN=$(printf '\033[1;32m')
        C_BYELLOW=$(printf '\033[1;33m')
        C_BBLUE=$(printf '\033[1;34m')
        C_BMAGENTA=$(printf '\033[1;35m')
        C_BCYAN=$(printf '\033[1;36m')
        C_BWHITE=$(printf '\033[1;37m')
        
        # Background colors
        C_BG_BLACK=$(printf '\033[40m')
        C_BG_RED=$(printf '\033[41m')
        C_BG_GREEN=$(printf '\033[42m')
        C_BG_YELLOW=$(printf '\033[43m')
        C_BG_BLUE=$(printf '\033[44m')
        C_BG_MAGENTA=$(printf '\033[45m')
        C_BG_CYAN=$(printf '\033[46m')
        C_BG_WHITE=$(printf '\033[47m')
        
        # 256 color support (for gradients)
        C_ORANGE=$(printf '\033[38;5;208m')
        C_PINK=$(printf '\033[38;5;213m')
        C_PURPLE=$(printf '\033[38;5;141m')
        C_LIME=$(printf '\033[38;5;154m')
        C_TEAL=$(printf '\033[38;5;80m')
        C_GOLD=$(printf '\033[38;5;220m')
        C_CORAL=$(printf '\033[38;5;209m')
        C_SKY=$(printf '\033[38;5;117m')
        
        COLORS_ENABLED=1
    else
        # No colors
        C_RESET='' C_BOLD='' C_DIM='' C_ITALIC='' C_UNDERLINE=''
        C_BLINK='' C_REVERSE=''
        C_BLACK='' C_RED='' C_GREEN='' C_YELLOW='' C_BLUE=''
        C_MAGENTA='' C_CYAN='' C_WHITE=''
        C_BRED='' C_BGREEN='' C_BYELLOW='' C_BBLUE=''
        C_BMAGENTA='' C_BCYAN='' C_BWHITE=''
        C_BG_BLACK='' C_BG_RED='' C_BG_GREEN='' C_BG_YELLOW=''
        C_BG_BLUE='' C_BG_MAGENTA='' C_BG_CYAN='' C_BG_WHITE=''
        C_ORANGE='' C_PINK='' C_PURPLE='' C_LIME=''
        C_TEAL='' C_GOLD='' C_CORAL='' C_SKY=''
        COLORS_ENABLED=0
    fi
}

# ════════════════════════════════════════════════════════════════════════════
# UI ELEMENTS & FORMATTING
# ════════════════════════════════════════════════════════════════════════════

# Box drawing characters
BOX_TL='╔' BOX_TR='╗' BOX_BL='╚' BOX_BR='╝'
BOX_H='═' BOX_V='║'
BOX_LT='╠' BOX_RT='╣' BOX_TT='╦' BOX_BT='╩' BOX_X='╬'

# Single line box
SBOX_TL='┌' SBOX_TR='┐' SBOX_BL='└' SBOX_BR='┘'
SBOX_H='─' SBOX_V='│'

# Symbols
SYM_CHECK='✓'
SYM_CROSS='✗'
SYM_ARROW='➜'
SYM_BULLET='●'
SYM_DIAMOND='◆'
SYM_STAR='★'
SYM_CIRCLE='○'
SYM_SQUARE='■'
SYM_TRIANGLE='▶'
SYM_INFO='ℹ'
SYM_WARN='⚠'
SYM_GEAR='⚙'
SYM_LOCK='🔒'
SYM_GLOBE='🌐'
SYM_ROCKET='🚀'
SYM_PACKAGE='📦'
SYM_FOLDER='📁'
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

print_step() {
    local step_num="$1"
    local message="$2"
    printf "    %s%s STEP %s %s %s%s%s %s%s%s\n" "${C_BG_MAGENTA}" "${C_BWHITE}" "$step_num" "${C_RESET}" "${C_BMAGENTA}" "${SYM_ARROW}" "${C_RESET}" "${C_BOLD}" "$message" "${C_RESET}"
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

print_bullet() {
    printf "      %s%s%s %s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "$1"
}

print_diamond() {
    printf "      %s%s%s %s\n" "${C_GOLD}" "${SYM_DIAMOND}" "${C_RESET}" "$1"
}

print_numbered() {
    local num="$1"
    local text="$2"
    printf "      %s%s %s %s %s\n" "${C_BG_CYAN}" "${C_BLACK}" "$num" "${C_RESET}" "$text"
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
    local status="$3"  # "ok", "warn", "error"
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

# ════════════════════════════════════════════════════════════════════════════
# ANIMATED ELEMENTS
# ════════════════════════════════════════════════════════════════════════════

spinner_frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

spinner() {
    local pid=$1
    local message="${2:-Processing...}"
    local delay=0.1
    local i=0
    local frame
    local color
    
    printf "      "
    
    while ps -p "$pid" > /dev/null 2>&1; do
        local frame_idx=$((i % 10))
        frame=$(echo "$spinner_frames" | cut -c$((frame_idx + 1)))
        
        case $((i % 6)) in
            0) color="${C_CYAN}" ;;
            1) color="${C_BBLUE}" ;;
            2) color="${C_MAGENTA}" ;;
            3) color="${C_BRED}" ;;
            4) color="${C_BYELLOW}" ;;
            5) color="${C_BGREEN}" ;;
        esac
        
        printf "\r      %s%s%s %s%s%s   " "$color" "$frame" "${C_RESET}" "${C_DIM}" "$message" "${C_RESET}"
        sleep $delay
        i=$((i + 1))
    done
    
    printf "\r      %s%s%s %s%s%s   \n" "${C_BGREEN}" "${SYM_CHECK}" "${C_RESET}" "${C_GREEN}" "$message" "${C_RESET}"
}

progress_bar() {
    local current=$1
    local total=$2
    local message="${3:-}"
    local width=40
    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    local i
    
    printf "\r      %s[%s" "${C_DIM}" "${C_RESET}"
    
    # Gradient progress bar
    i=0
    while [ $i -lt $filled ]; do
        case $((i * 6 / width)) in
            0) printf "%s█" "${C_RED}" ;;
            1) printf "%s█" "${C_ORANGE}" ;;
            2) printf "%s█" "${C_YELLOW}" ;;
            3) printf "%s█" "${C_GREEN}" ;;
            4) printf "%s█" "${C_CYAN}" ;;
            5) printf "%s█" "${C_BLUE}" ;;
        esac
        i=$((i + 1))
    done
    
    printf "%s" "${C_DIM}"
    i=0
    while [ $i -lt $empty ]; do
        printf "░"
        i=$((i + 1))
    done
    
    printf "%s%s]%s %s%3d%%%s" "${C_RESET}" "${C_DIM}" "${C_RESET}" "${C_BWHITE}" "$percent" "${C_RESET}"
    
    if [ -n "$message" ]; then
        printf " %s%s%s" "${C_DIM}" "$message" "${C_RESET}"
    fi
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

prompt_multiline() {
    local prompt_prefix="$1"
    local var_name="$2"
    local result=""
    local line
    
    while true; do
        printf "      %s%s%s%s>%s " "${C_PURPLE}" "$prompt_prefix" "${C_RESET}" "${C_DIM}" "${C_RESET}"
        read line
        [ -z "$line" ] && break
        result="${result}${line}\n"
    done
    
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
        if [ -f "/usr/local/opnsense/version/core" ]; then
            OPNSENSE_VERSION=$(cat /usr/local/opnsense/version/core 2>/dev/null)
        else
            OPNSENSE_VERSION="unknown"
        fi
    else
        IS_OPNSENSE="no"
        OPNSENSE_VERSION=""
    fi
    
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
    
    # Get default interface
    DEFAULT_IFACE=$(route -n get default 2>/dev/null | grep interface | awk '{print $2}')
    
    # Get all interfaces with IPs
    ALL_INTERFACES=$(ifconfig | grep -E "^[a-z]" | cut -d: -f1)
    
    echo ""
    print_subsection "Network Interfaces"
    echo ""
    
    local found_lan=0
    
    for iface in $ALL_INTERFACES; do
        local ip=$(ifconfig "$iface" 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | head -1)
        
        if [ -n "$ip" ]; then
            local marker=""
            local status_color="${C_GREEN}"
            local status_icon="${SYM_BULLET}"
            
            if [ "$iface" = "$DEFAULT_IFACE" ]; then
                marker=" (default)"
                status_color="${C_YELLOW}"
                status_icon="${SYM_CIRCLE}"
            fi
            
            if echo "$ip" | grep -qE "^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)"; then
                print_key_value "$iface" "${ip}${marker}" "${status_icon}" "${status_color}"
                [ $found_lan -eq 0 ] && LOCAL_IP="$ip" && found_lan=1
            else
                print_key_value "$iface" "${ip}${marker}" "${SYM_CIRCLE}" "${C_YELLOW}"
            fi
        fi
    done
    
    echo ""
    print_subsection_end
    
    # Confirm or change IP
    if [ -n "$LOCAL_IP" ]; then
        echo ""
        printf "    %s%s%s Detected LAN IP: %s%s%s\n" "${C_BCYAN}" "${SYM_INFO}" "${C_RESET}" "${C_BWHITE}" "${LOCAL_IP}" "${C_RESET}"
        
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
# PACKAGE MANAGEMENT
# ════════════════════════════════════════════════════════════════════════════

show_package_menu() {
    print_section_header "Package Selection" "${SYM_PACKAGE}"
    
    print_info "Select optional packages to install alongside Tor"
    echo ""
    
    print_subsection "Available Packages"
    echo ""
    
    printf "      %s%s 1 %s %smc%s        %sMidnight Commander - Visual file manager%s\n" "${C_BG_CYAN}" "${C_BLACK}" "${C_RESET}" "${C_BCYAN}" "${C_RESET}" "${C_DIM}" "${C_RESET}"
    printf "      %s%s 2 %s %sgit%s       %sGit - Version control system%s\n" "${C_BG_GREEN}" "${C_BLACK}" "${C_RESET}" "${C_BGREEN}" "${C_RESET}" "${C_DIM}" "${C_RESET}"
    printf "      %s%s 3 %s %scurl%s      %scURL - Data transfer tool%s\n" "${C_BG_YELLOW}" "${C_BLACK}" "${C_RESET}" "${C_BYELLOW}" "${C_RESET}" "${C_DIM}" "${C_RESET}"
    printf "      %s%s 4 %s %swget%s      %sWget - File download utility%s\n" "${C_BG_MAGENTA}" "${C_BLACK}" "${C_RESET}" "${C_BMAGENTA}" "${C_RESET}" "${C_DIM}" "${C_RESET}"
    printf "      %s%s 5 %s %snano%s      %sNano - Text editor%s\n" "${C_BG_BLUE}" "${C_BLACK}" "${C_RESET}" "${C_BBLUE}" "${C_RESET}" "${C_DIM}" "${C_RESET}"
    echo ""
    printf "      %s%s A %s %sAll%s       %sInstall all packages%s\n" "${C_BG_WHITE}" "${C_BLACK}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}" "${C_DIM}" "${C_RESET}"
    printf "      %s%s 0 %s %sNone%s      %sSkip optional packages%s\n" "${C_BG_RED}" "${C_BLACK}" "${C_RESET}" "${C_RED}" "${C_RESET}" "${C_DIM}" "${C_RESET}"
    
    echo ""
    print_subsection_end
    echo ""
    
    prompt_input "Enter selection (e.g., 1 2 3 or A for all)" PACKAGE_SELECTION "A"
    
    SELECTED_PACKAGES=""
    
    case "$PACKAGE_SELECTION" in
        *[Aa]*)
            SELECTED_PACKAGES="mc git curl wget nano"
            ;;
        *0*)
            SELECTED_PACKAGES=""
            ;;
        *)
            echo "$PACKAGE_SELECTION" | grep -q "1" && SELECTED_PACKAGES="$SELECTED_PACKAGES mc"
            echo "$PACKAGE_SELECTION" | grep -q "2" && SELECTED_PACKAGES="$SELECTED_PACKAGES git"
            echo "$PACKAGE_SELECTION" | grep -q "3" && SELECTED_PACKAGES="$SELECTED_PACKAGES curl"
            echo "$PACKAGE_SELECTION" | grep -q "4" && SELECTED_PACKAGES="$SELECTED_PACKAGES wget"
            echo "$PACKAGE_SELECTION" | grep -q "5" && SELECTED_PACKAGES="$SELECTED_PACKAGES nano"
            ;;
    esac
    
    SELECTED_PACKAGES=$(echo "$SELECTED_PACKAGES" | xargs)
    
    echo ""
    if [ -n "$SELECTED_PACKAGES" ]; then
        printf "    %s%s%s Selected packages: %s%s%s\n" "${C_BGREEN}" "${SYM_CHECK}" "${C_RESET}" "${C_BWHITE}" "${SELECTED_PACKAGES}" "${C_RESET}"
    else
        print_info "No optional packages selected"
    fi
}

get_latest_package_url() {
    local package_name=$1
    local base_url="${PKG_BASE_URL}:${OS_VERSION}:${ARCH}/latest/All"
    
    local pkg_file=$(fetch -qo - "${base_url}/" 2>/dev/null | \
                     grep -o "href=\"${package_name}-[^\"]*\.pkg\"" | \
                     sed 's/href="//;s/"//' | sort -V | tail -n 1)
    
    if [ -n "$pkg_file" ]; then
        echo "${base_url}/${pkg_file}"
    fi
}

install_package() {
    local pkg_name="$1"
    local pkg_desc="${2:-$pkg_name}"
    
    if pkg info "$pkg_name" >/dev/null 2>&1; then
        printf "    %s%s%s %s%s %s(already installed)%s\n" "${C_BGREEN}" "${SYM_CHECK}" "${C_RESET}" "${C_GREEN}" "$pkg_desc" "${C_DIM}" "${C_RESET}"
        return 0
    fi
    
    local pkg_url=$(get_latest_package_url "$pkg_name")
    
    if [ -n "$pkg_url" ]; then
        pkg add "$pkg_url" >/dev/null 2>&1 &
        spinner $! "Installing ${pkg_desc}..."
    else
        pkg install -y "$pkg_name" >/dev/null 2>&1 &
        spinner $! "Installing ${pkg_desc}..."
    fi
    
    if pkg info "$pkg_name" >/dev/null 2>&1; then
        return 0
    else
        print_warning "Failed to install ${pkg_desc}"
        return 1
    fi
}

install_packages() {
    print_section_header "Installing Packages" "${SYM_PACKAGE}"
    
    local total_packages=0
    local current=0
    
    # Count packages
    for pkg in $SELECTED_PACKAGES; do
        total_packages=$((total_packages + 1))
    done
    total_packages=$((total_packages + 4))  # Add Tor packages
    
    # Install optional packages
    if [ -n "$SELECTED_PACKAGES" ]; then
        print_action "Installing optional packages..."
        echo ""
        
        for pkg in $SELECTED_PACKAGES; do
            current=$((current + 1))
            progress_bar $current $total_packages "$pkg"
            echo ""
            install_package "$pkg"
        done
        
        echo ""
    fi
    
    # Install Tor packages
    print_action "Installing Tor and plugins..."
    echo ""
    
    local tor_packages="zstd tor obfs4proxy-tor webtunnel-tor"
    
    for pkg in $tor_packages; do
        current=$((current + 1))
        progress_bar $current $total_packages "$pkg"
        echo ""
        
        case "$pkg" in
            zstd) install_package "$pkg" "Zstandard compression" ;;
            tor) install_package "$pkg" "Tor anonymity network" ;;
            obfs4proxy-tor) install_package "$pkg" "OBFS4 transport plugin" ;;
            webtunnel-tor) install_package "$pkg" "WebTunnel transport plugin" ;;
            *) install_package "$pkg" ;;
        esac
    done
    
    echo ""
    print_success "All packages installed successfully"
}

# ════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ════════════════════════════════════════════════════════════════════════════

configure_ipv6() {
    print_section_header "IPv6 Configuration" "${SYM_GLOBE}"
    
    print_info "IPv6 can improve Tor connectivity in many networks"
    echo ""
    
    printf "      %s%s%s Recommended for most modern networks\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}"
    printf "      %s%s%s Disable if your ISP blocks IPv6\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}"
    printf "      %s%s%s Can be changed later in %s/usr/local/etc/tor/torrc%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_CYAN}" "${C_RESET}"
    
    echo ""
    
    if prompt_yes_no "Enable IPv6 support in Tor?" "Y"; then
        USE_IPV6="yes"
        printf "    %s%s%s IPv6 support: %sEnabled%s\n" "${C_BGREEN}" "${SYM_CHECK}" "${C_RESET}" "${C_BGREEN}" "${C_RESET}"
    else
        USE_IPV6="no"
        printf "    %s%s%s IPv6 support: %sDisabled%s\n" "${C_BCYAN}" "${SYM_INFO}" "${C_RESET}" "${C_YELLOW}" "${C_RESET}"
    fi
}

configure_bridges() {
    print_section_header "Tor Bridge Configuration" "${SYM_LOCK}"
    
    echo ""
    print_box_message "Bridges help bypass Tor censorship in restricted regions" "$C_CYAN"
    echo ""
    
    print_info "You only need bridges if:"
    printf "      %s%s%s Direct Tor connections are blocked in your country\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}"
    printf "      %s%s%s Your ISP actively blocks Tor traffic\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}"
    printf "      %s%s%s You're in a high-censorship environment\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}"
    
    echo ""
    
    if ! prompt_yes_no "Configure Tor bridges?" "N"; then
        OBFS4_BRIDGES=""
        WEBTUNNEL_BRIDGES=""
        echo ""
        print_info "Skipping bridges - Tor will connect directly"
        return
    fi
    
    echo ""
    print_subsection "Bridge Information"
    echo ""
    
    printf "    %s%s%s %sGet bridges from:%s\n" "${C_GOLD}" "${SYM_STAR}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
    printf "      %s%s%s Web:   %s%shttps://bridges.torproject.org/%s\n" "${C_CYAN}" "${SYM_GLOBE}" "${C_RESET}" "${C_UNDERLINE}" "${C_BBLUE}" "${C_RESET}"
    printf "      %s%s%s Email: %sbridges@torproject.org%s\n" "${C_MAGENTA}" "${SYM_INFO}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    
    echo ""
    print_subsection_end
    echo ""
    
    printf "    %sPress Enter when you have your bridge lines ready...%s" "${C_DIM}" "${C_RESET}"
    read dummy
    
    # OBFS4 bridges
    echo ""
    printf "    %s%s%s Enter OBFS4 bridge lines %s(empty line to finish)%s\n" "${C_BCYAN}" "${SYM_TRIANGLE}" "${C_RESET}" "${C_DIM}" "${C_RESET}"
    echo ""
    
    OBFS4_BRIDGES=""
    while true; do
        printf "      %sobfs4%s%s>%s " "${C_PURPLE}" "${C_RESET}" "${C_DIM}" "${C_RESET}"
        read bridge_line
        [ -z "$bridge_line" ] && break
        
        if echo "$bridge_line" | grep -q "^Bridge"; then
            OBFS4_BRIDGES="${OBFS4_BRIDGES}${bridge_line}\n"
        else
            OBFS4_BRIDGES="${OBFS4_BRIDGES}Bridge obfs4 ${bridge_line}\n"
        fi
    done
    
    # WebTunnel bridges
    echo ""
    printf "    %s%s%s Enter WebTunnel bridge lines %s(empty line to finish)%s\n" "${C_BCYAN}" "${SYM_TRIANGLE}" "${C_RESET}" "${C_DIM}" "${C_RESET}"
    echo ""
    
    WEBTUNNEL_BRIDGES=""
    while true; do
        printf "      %swebtunnel%s%s>%s " "${C_CYAN}" "${C_RESET}" "${C_DIM}" "${C_RESET}"
        read bridge_line
        [ -z "$bridge_line" ] && break
        
        if echo "$bridge_line" | grep -q "^Bridge"; then
            WEBTUNNEL_BRIDGES="${WEBTUNNEL_BRIDGES}${bridge_line}\n"
        else
            WEBTUNNEL_BRIDGES="${WEBTUNNEL_BRIDGES}Bridge webtunnel ${bridge_line}\n"
        fi
    done
    
    echo ""
    if [ -n "$OBFS4_BRIDGES" ] || [ -n "$WEBTUNNEL_BRIDGES" ]; then
        print_success "Bridges configured successfully"
    else
        print_warning "No bridges entered - using direct connection"
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
    
    # Create directories
    print_action "Creating directories..."
    mkdir -p "$LOG_DIR" "$PID_DIR"
    chown _tor:_tor "$LOG_DIR" "$PID_DIR"
    print_success "Directories created"
    
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
# LOGGING
# ─────────────────────────────────────────────────────────────────────────────
Log notice file ${LOG_DIR}/notices.log

# ─────────────────────────────────────────────────────────────────────────────
# DNS CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────
# Uncomment the line below if you want Tor to handle DNS on port 53
# DNSPort ${LOCAL_IP}:53

DNSPort 127.0.0.1:9053
DNSPort ${LOCAL_IP}:9053

# ─────────────────────────────────────────────────────────────────────────────
# VIRTUAL ADDRESS MAPPING
# ─────────────────────────────────────────────────────────────────────────────
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1

# ─────────────────────────────────────────────────────────────────────────────
# DAEMON MODE
# ─────────────────────────────────────────────────────────────────────────────
RunAsDaemon 1

# ─────────────────────────────────────────────────────────────────────────────
# SOCKS PROXY
# ─────────────────────────────────────────────────────────────────────────────
SocksPort 127.0.0.1:9050
SocksPort ${LOCAL_IP}:9050

# ─────────────────────────────────────────────────────────────────────────────
# TRANSPARENT PROXY
# ─────────────────────────────────────────────────────────────────────────────
TransPort 9040

# ─────────────────────────────────────────────────────────────────────────────
# EXIT POLICY (Relay disabled - client only)
# ─────────────────────────────────────────────────────────────────────────────
ExitPolicy reject *:*
ExitPolicy reject6 *:*
ExitRelay 0

# ─────────────────────────────────────────────────────────────────────────────
# NODE RESTRICTIONS
# Exclude CIS and nearby countries for privacy
# ─────────────────────────────────────────────────────────────────────────────
ExcludeNodes {RU}, {BY}, {KG}, {KZ}, {UZ}, {TJ}, {TM}, {TR}, {AZ}, {AM}
ExcludeExitNodes {RU}, {BY}, {KG}, {KZ}, {UZ}, {TJ}, {TM}, {TR}, {AZ}, {AM}

# Prefer Polish exit nodes (can be changed)
ExitNodes {PL}
StrictNodes 1

# ─────────────────────────────────────────────────────────────────────────────
# MISC SETTINGS
# ─────────────────────────────────────────────────────────────────────────────
HeartbeatPeriod 1 hours

# ─────────────────────────────────────────────────────────────────────────────
# TRANSPORT PLUGINS
# ─────────────────────────────────────────────────────────────────────────────
ClientTransportPlugin obfs4 exec /usr/local/bin/obfs4proxy managed
ClientTransportPlugin webtunnel exec /usr/local/bin/webtunnel-tor-client

EOF

    # Add IPv6 configuration
    if [ "$USE_IPV6" = "yes" ]; then
        cat >> "$TORRC_PATH" << 'EOF'
# ─────────────────────────────────────────────────────────────────────────────
# IPv6 CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────
ClientUseIPv6 1
ClientUseIPv4 1
ClientPreferIPv6ORPort 1
ClientPreferIPv6DirPort 0

EOF
    fi

    # Add bridge configuration
    if [ -n "$OBFS4_BRIDGES" ] || [ -n "$WEBTUNNEL_BRIDGES" ]; then
        cat >> "$TORRC_PATH" << 'EOF'
# ─────────────────────────────────────────────────────────────────────────────
# BRIDGE CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────
UseBridges 1

EOF
        [ -n "$OBFS4_BRIDGES" ] && printf "%b" "$OBFS4_BRIDGES" >> "$TORRC_PATH"
        [ -n "$WEBTUNNEL_BRIDGES" ] && printf "%b" "$WEBTUNNEL_BRIDGES" >> "$TORRC_PATH"
    else
        cat >> "$TORRC_PATH" << 'EOF'
# ─────────────────────────────────────────────────────────────────────────────
# BRIDGE CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────
UseBridges 0

# To add bridges later:
#   1. Get bridges from: https://bridges.torproject.org/
#   2. Change UseBridges to 1
#   3. Add bridge lines below:
#
# Bridge obfs4 <IP:PORT> <FINGERPRINT> cert=<CERT> iat-mode=0
# Bridge webtunnel <IP:PORT> <FINGERPRINT> url=<URL>
#
EOF
    fi

    printf "    %s%s%s Configuration written to: %s%s%s\n" "${C_BGREEN}" "${SYM_CHECK}" "${C_RESET}" "${C_CYAN}" "${TORRC_PATH}" "${C_RESET}"
}

setup_autostart() {
    print_action "Setting up autostart service..."
    
    local rc_script="/usr/local/etc/rc.d/tor"
    
    cat > "$rc_script" << 'RCEOF'
#!/bin/sh
#
# PROVIDE: tor
# REQUIRE: DAEMON
# BEFORE: LOGIN
# KEYWORD: shutdown
#
# AntiZapret Tor Service Script
#

. /etc/rc.subr

name="tor"
rcvar="tor_enable"
command="/usr/local/bin/tor"
tor_user="_tor"
pidfile="/var/run/tor/tor.pid"
required_files="/usr/local/etc/tor/torrc"
extra_commands="reload"

load_rc_config $name
: ${tor_enable:="YES"}

run_rc_command "$1"
RCEOF

    chmod +x "$rc_script"
    sysrc tor_enable="YES" >/dev/null 2>&1
    
    print_success "Autostart service configured"
}

install_antizapret() {
    print_section_header "Installing AntiZapret" "${SYM_SHIELD}"
    
    print_action "Setting up AntiZapret IP list updater..."
    
    if [ ! -d "$SCRIPT_DIR" ]; then
        print_subaction "Cloning repository..."
        cd /root
        git clone https://github.com/Limych/antizapret.git >/dev/null 2>&1 &
        spinner $! "Cloning AntiZapret repository..."
    else
        print_subaction "Updating existing repository..."
        cd "$SCRIPT_DIR"
        git pull >/dev/null 2>&1 &
        spinner $! "Updating AntiZapret repository..."
    fi
    
    chmod +x "${SCRIPT_DIR}/antizapret.pl"
    
    print_action "Running initial IP list update..."
    "${SCRIPT_DIR}/antizapret.pl" > "$IP_LIST_PATH" 2>&1 &
    spinner $! "Downloading blocked IP list..."
    
    if [ -f "$IP_LIST_PATH" ]; then
        local ip_count=$(wc -l < "$IP_LIST_PATH" | tr -d ' ')
        printf "    %s%s%s IP list updated: %s%s%s entries\n" "${C_BGREEN}" "${SYM_CHECK}" "${C_RESET}" "${C_BWHITE}" "${ip_count}" "${C_RESET}"
    else
        print_warning "Could not create IP list"
    fi
}

configure_opnsense() {
    if [ "$IS_OPNSENSE" != "yes" ]; then
        print_info "Skipping OPNsense integration (not detected)"
        return
    fi
    
    print_section_header "OPNsense Integration" "${SYM_GEAR}"
    
    print_action "Creating OPNsense action scripts..."
    
    # AntiZapret action
    cat > "${ACTIONS_DIR}/actions_antizapret.conf" << 'EOF'
[cron-iplist-renew]
command:/root/antizapret/antizapret.pl | tee /usr/local/www/ipfw_antizapret.dat | xargs pfctl -t AntiZapret_IPs -T add
parameters:
type:script
message:Renew AntiZapret IP-list
description:Renew AntiZapret IP-list
EOF
    print_success "AntiZapret cron action created"

    # Tor service actions
    cat > "${ACTIONS_DIR}/actions_tor.conf" << 'EOF'
[start]
command:service tor start
parameters:
type:script
message:Starting TOR service
description:Start TOR anonymity service

[stop]
command:service tor stop
parameters:
type:script
message:Stopping TOR service
description:Stop TOR anonymity service

[restart]
command:service tor restart
parameters:
type:script
message:Restarting TOR service
description:Restart TOR anonymity service

[status]
command:service tor status
parameters:
type:script
message:TOR service status
description:Check TOR service status
EOF
    print_success "Tor service actions created"

    print_action "Reloading configd..."
    service configd restart >/dev/null 2>&1 &
    spinner $! "Reloading OPNsense configuration daemon..."
    
    print_success "OPNsense integration complete"
}

# ════════════════════════════════════════════════════════════════════════════
# SERVICE MANAGEMENT
# ════════════════════════════════════════════════════════════════════════════

start_tor_service() {
    print_section_header "Starting Tor Service" "${SYM_ROCKET}"
    
    # Stop if running
    if pgrep -x tor >/dev/null 2>&1; then
        print_action "Stopping existing Tor process..."
        service tor stop >/dev/null 2>&1 || true
        sleep 2
    fi
    
    print_action "Starting Tor service..."
    service tor start >/dev/null 2>&1
    
    # Wait and verify
    countdown 5 "Waiting for Tor to initialize"
    
    if pgrep -x tor >/dev/null 2>&1; then
        print_success "Tor service started successfully!"
    else
        print_error "Failed to start Tor service"
        printf "    %s%s%s Check logs: %stail -f %s/notices.log%s\n" "${C_BCYAN}" "${SYM_INFO}" "${C_RESET}" "${C_CYAN}" "${LOG_DIR}" "${C_RESET}"
        return 1
    fi
}

verify_installation() {
    print_section_header "Verification" "${SYM_CHECK}"
    
    local errors=0
    local warnings=0
    
    echo ""
    print_subsection "Service Status"
    echo ""
    
    # Check Tor process
    if pgrep -x tor >/dev/null 2>&1; then
        local tor_pid=$(pgrep -x tor)
        print_key_value_status "Tor Process" "Running (PID: ${tor_pid})" "ok"
    else
        print_key_value_status "Tor Process" "Not running" "error"
        errors=$((errors + 1))
    fi
    
    # Check ports
    if sockstat -4l 2>/dev/null | grep -q ":9050"; then
        print_key_value_status "SOCKS Proxy" "Listening on port 9050" "ok"
    else
        print_key_value_status "SOCKS Proxy" "Not detected" "warn"
        warnings=$((warnings + 1))
    fi
    
    if sockstat -4l 2>/dev/null | grep -q ":9053"; then
        print_key_value_status "DNS Proxy" "Listening on port 9053" "ok"
    else
        print_key_value_status "DNS Proxy" "Not detected" "warn"
        warnings=$((warnings + 1))
    fi
    
    if sockstat -4l 2>/dev/null | grep -q ":9040"; then
        print_key_value_status "Transparent Proxy" "Listening on port 9040" "ok"
    else
        print_key_value_status "Transparent Proxy" "Not detected" "warn"
        warnings=$((warnings + 1))
    fi
    
    echo ""
    print_subsection_end
    echo ""
    
    print_subsection "Files & Configuration"
    echo ""
    
    # Check config file
    if [ -f "$TORRC_PATH" ]; then
        print_key_value_status "Tor Config" "Present" "ok"
    else
        print_key_value_status "Tor Config" "Missing" "error"
        errors=$((errors + 1))
    fi
    
    # Check IP list
    if [ -f "$IP_LIST_PATH" ]; then
        local count=$(wc -l < "$IP_LIST_PATH" | tr -d ' ')
        print_key_value_status "IP List" "${count} entries" "ok"
    else
        print_key_value_status "IP List" "Not found" "warn"
        warnings=$((warnings + 1))
    fi
    
    # Check autostart
    if grep -q 'tor_enable="YES"' /etc/rc.conf 2>/dev/null; then
        print_key_value_status "Autostart" "Enabled" "ok"
    else
        print_key_value_status "Autostart" "Disabled" "warn"
        warnings=$((warnings + 1))
    fi
    
    echo ""
    print_subsection_end
    echo ""
    
    # Summary
    if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
        print_success "All checks passed!"
    elif [ $errors -eq 0 ]; then
        print_warning "${warnings} warning(s) - installation mostly successful"
    else
        print_error "${errors} error(s) found - please check logs"
    fi
    
    return $errors
}

# ════════════════════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ════════════════════════════════════════════════════════════════════════════

print_final_summary() {
    echo ""
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
    
    # Configuration Summary
    echo ""
    print_subsection "Installation Summary"
    echo ""
    
    print_key_value "LAN IP Address" "${LOCAL_IP}" "${SYM_GLOBE}" "${C_BLUE}"
    
    local ipv6_status
    [ "$USE_IPV6" = "yes" ] && ipv6_status="Enabled" || ipv6_status="Disabled"
    print_key_value "IPv6 Support" "${ipv6_status}" "${SYM_GEAR}" "${C_MAGENTA}"
    
    local bridge_status
    [ -n "$OBFS4_BRIDGES" ] || [ -n "$WEBTUNNEL_BRIDGES" ] && bridge_status="Configured" || bridge_status="Direct connection"
    print_key_value "Bridges" "${bridge_status}" "${SYM_LOCK}" "${C_PURPLE}"
    
    local opnsense_status
    [ "$IS_OPNSENSE" = "yes" ] && opnsense_status="Integrated" || opnsense_status="N/A"
    print_key_value "OPNsense" "${opnsense_status}" "${SYM_SHIELD}" "${C_GREEN}"
    
    echo ""
    print_subsection_end
    
    # Next Steps
    print_section_header "Next Steps - OPNsense Configuration" "${SYM_INFO}"
    
    echo ""
    printf "    %s%s STEP 1 %s %sCreate Firewall Alias%s\n" "${C_BG_BLUE}" "${C_BWHITE}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
    echo ""
    printf "      %s%s%s Navigate to: %sFirewall → Aliases → Add%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_CYAN}" "${C_RESET}"
    printf "      %s%s%s Name: %sAntiZapret_IPs%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    printf "      %s%s%s Type: %sExternal (advanced)%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    printf "      %s%s%s Content URL: %s%shttps://%s/ipfw_antizapret.dat%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_UNDERLINE}" "${C_BBLUE}" "${LOCAL_IP}" "${C_RESET}"
    
    echo ""
    printf "    %s%s STEP 2 %s %sSetup NAT Port Forward%s\n" "${C_BG_GREEN}" "${C_BWHITE}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
    echo ""
    printf "      %s%s%s Navigate to: %sFirewall → NAT → Port Forward → Add%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_CYAN}" "${C_RESET}"
    printf "      %s%s%s Interface: %sLAN%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    printf "      %s%s%s Protocol: %sTCP%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    printf "      %s%s%s Destination: %sAntiZapret_IPs%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    printf "      %s%s%s Redirect target IP: %s127.0.0.1%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    printf "      %s%s%s Redirect target port: %s9040%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    
    echo ""
    printf "    %s%s STEP 3 %s %sSchedule Daily Updates%s\n" "${C_BG_YELLOW}" "${C_BLACK}" "${C_RESET}" "${C_BOLD}" "${C_RESET}"
    echo ""
    printf "      %s%s%s Navigate to: %sSystem → Settings → Cron → Add%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_CYAN}" "${C_RESET}"
    printf "      %s%s%s Command: %sRenew AntiZapret IP-list%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    printf "      %s%s%s Schedule: %sDaily (e.g., 4:00 AM)%s\n" "${C_MAGENTA}" "${SYM_BULLET}" "${C_RESET}" "${C_BWHITE}" "${C_RESET}"
    
    # Commands Reference
    print_section_header "Command Reference" "${SYM_GEAR}"
    
    echo ""
    print_subsection "Tor Service Management"
    echo ""
    
    printf "      %s%-35s%s %s%s%s\n" "${C_CYAN}" "service tor status" "${C_RESET}" "${C_DIM}" "Check service status" "${C_RESET}"
    printf "      %s%-35s%s %s%s%s\n" "${C_CYAN}" "service tor start" "${C_RESET}" "${C_DIM}" "Start Tor" "${C_RESET}"
    printf "      %s%-35s%s %s%s%s\n" "${C_CYAN}" "service tor stop" "${C_RESET}" "${C_DIM}" "Stop Tor" "${C_RESET}"
    printf "      %s%-35s%s %s%s%s\n" "${C_CYAN}" "service tor restart" "${C_RESET}" "${C_DIM}" "Restart Tor" "${C_RESET}"
    
    echo ""
    print_subsection_end
    echo ""
    
    print_subsection "Logs & Monitoring"
    echo ""
    
    printf "      %s%-35s%s %s%s%s\n" "${C_GREEN}" "tail -f ${LOG_DIR}/notices.log" "${C_RESET}" "${C_DIM}" "View live Tor logs" "${C_RESET}"
    printf "      %s%-35s%s %s%s%s\n" "${C_GREEN}" "cat ${IP_LIST_PATH} | wc -l" "${C_RESET}" "${C_DIM}" "Count blocked IPs" "${C_RESET}"
    
    echo ""
    print_subsection_end
    echo ""
    
    print_subsection "AntiZapret Updates"
    echo ""
    
    printf "      %s%-35s%s %s%s%s\n" "${C_MAGENTA}" "${SCRIPT_DIR}/antizapret.pl" "${C_RESET}" "${C_DIM}" "Update IP list manually" "${C_RESET}"
    
    echo ""
    print_subsection_end
    
    # Configuration Files
    print_section_header "Configuration Files" "${SYM_FILE}"
    
    echo ""
    print_key_value "Tor Configuration" "${TORRC_PATH}" "${SYM_FILE}" "${C_CYAN}"
    print_key_value "IP Blocklist" "${IP_LIST_PATH}" "${SYM_FILE}" "${C_GREEN}"
    print_key_value "Autostart Script" "/usr/local/etc/rc.d/tor" "${SYM_FILE}" "${C_MAGENTA}"
    print_key_value "Tor Logs" "${LOG_DIR}/notices.log" "${SYM_FILE}" "${C_YELLOW}"
    print_key_value "AntiZapret Script" "${SCRIPT_DIR}/antizapret.pl" "${SYM_FILE}" "${C_BLUE}"
    
    echo ""
    
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
# MAIN EXECUTION
# ════════════════════════════════════════════════════════════════════════════

main() {
    # Initialize
    setup_colors
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
    
    if ! prompt_yes_no "Ready to install AntiZapret with Tor. Continue?" "Y"; then
        echo ""
        print_info "Installation cancelled by user"
        echo ""
        exit 0
    fi
    
    # Package selection
    show_package_menu
    
    # Installation
    install_packages
    
    # Configuration
    configure_ipv6
    configure_bridges
    generate_torrc
    setup_autostart
    install_antizapret
    configure_opnsense
    
    # Start and verify
    start_tor_service
    verify_installation
    
    # Show summary
    print_final_summary
}

# Run main function with all arguments
main "$@"

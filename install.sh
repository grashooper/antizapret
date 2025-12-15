#!/bin/sh

set -e

COLOR_RESET='\033[0m'
COLOR_GREEN='\033[0;32m'
COLOR_BLUE='\033[0;34m'
COLOR_YELLOW='\033[1;33m'
COLOR_RED='\033[0;31m'
COLOR_CYAN='\033[0;36m'
COLOR_BOLD='\033[1m'

print_header() {
    echo ""
    echo "${COLOR_BOLD}${COLOR_CYAN}========================================${COLOR_RESET}"
    echo "${COLOR_BOLD}${COLOR_CYAN}  AntiZapret Installation Script${COLOR_RESET}"
    echo "${COLOR_BOLD}${COLOR_CYAN}========================================${COLOR_RESET}"
    echo ""
}

print_step() {
    echo "${COLOR_BOLD}${COLOR_BLUE}==>${COLOR_RESET} ${COLOR_BOLD}$1${COLOR_RESET}"
}

print_success() {
    echo "${COLOR_GREEN}[OK]${COLOR_RESET} $1"
}

print_warning() {
    echo "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $1"
}

print_error() {
    echo "${COLOR_RED}[ERROR]${COLOR_RESET} $1"
}

print_info() {
    echo "${COLOR_CYAN}[INFO]${COLOR_RESET} $1"
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

check_root() {
    if [ "$(id -u)" != "0" ]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

detect_system() {
    print_step "Detecting system information..."

    OS_TYPE=$(uname -s)
    OS_VERSION=$(uname -r | cut -d. -f1)
    ARCH=$(uname -m)

    if [ "$OS_TYPE" != "FreeBSD" ]; then
        print_error "This script is designed for FreeBSD/OPNsense only"
        print_info "Detected OS: $OS_TYPE"
        exit 1
    fi

    print_success "System: FreeBSD ${OS_VERSION} (${ARCH})"
}

detect_local_ip() {
    print_step "Detecting local IP address..."

    LOCAL_IP=$(ifconfig | grep "inet " | grep -v "127.0.0.1" | head -n 1 | awk '{print $2}')

    if [ -z "$LOCAL_IP" ]; then
        print_warning "Could not auto-detect local IP"
        printf "${COLOR_YELLOW}Enter your LAN IP address: ${COLOR_RESET}"
        read LOCAL_IP
    else
        print_success "Detected LAN IP: $LOCAL_IP"
        printf "${COLOR_YELLOW}Is this correct? (Y/n): ${COLOR_RESET}"
        read confirm
        if [ "$confirm" = "n" ] || [ "$confirm" = "N" ]; then
            printf "${COLOR_YELLOW}Enter your LAN IP address: ${COLOR_RESET}"
            read LOCAL_IP
        fi
    fi

    print_info "Using LAN IP: $LOCAL_IP"
}

get_latest_package_url() {
    local package_name=$1
    local base_url="https://pkg.freebsd.org/FreeBSD:${OS_VERSION}:${ARCH}/latest/All"

    print_info "Searching for latest version of $package_name..."

    local pkg_list=$(fetch -qo - "${base_url}/" 2>/dev/null | grep -o "href=\"${package_name}-[^\"]*\.pkg\"" | sed 's/href="//;s/"//' | sort -V | tail -n 1)

    if [ -n "$pkg_list" ]; then
        echo "${base_url}/${pkg_list}"
    else
        echo ""
    fi
}

install_dependencies() {
    print_step "Installing dependencies..."

    print_info "Installing nano..."
    pkg install -y nano > /dev/null 2>&1 &
    spinner $!
    print_success "nano installed"

    print_info "Fetching package information..."

    ZSTD_URL=$(get_latest_package_url "zstd")
    TOR_URL=$(get_latest_package_url "tor")
    OBFS4_URL=$(get_latest_package_url "obfs4proxy-tor")
    WEBTUNNEL_URL=$(get_latest_package_url "webtunnel-tor")

    if [ -z "$ZSTD_URL" ]; then
        ZSTD_URL="https://pkg.freebsd.org/FreeBSD:${OS_VERSION}:${ARCH}/latest/All/zstd-1.5.6.pkg"
        print_warning "Using fallback URL for zstd"
    fi

    if [ -z "$TOR_URL" ]; then
        TOR_URL="https://pkg.freebsd.org/FreeBSD:${OS_VERSION}:${ARCH}/latest/All/tor-0.4.8.12.pkg"
        print_warning "Using fallback URL for tor"
    fi

    if [ -z "$OBFS4_URL" ]; then
        OBFS4_URL="https://pkg.freebsd.org/FreeBSD:${OS_VERSION}:${ARCH}/latest/All/obfs4proxy-tor-0.0.14_17.pkg"
        print_warning "Using fallback URL for obfs4proxy-tor"
    fi

    if [ -z "$WEBTUNNEL_URL" ]; then
        WEBTUNNEL_URL="https://pkg.freebsd.org/FreeBSD:${OS_VERSION}:${ARCH}/latest/All/webtunnel-tor-0.0.1_10.pkg"
        print_warning "Using fallback URL for webtunnel-tor"
    fi

    print_info "Installing zstd..."
    echo "   URL: $ZSTD_URL"
    pkg add $ZSTD_URL > /dev/null 2>&1 &
    spinner $!
    print_success "zstd installed"

    print_info "Installing tor..."
    echo "   URL: $TOR_URL"
    pkg add $TOR_URL > /dev/null 2>&1 &
    spinner $!
    print_success "tor installed"

    print_info "Installing obfs4proxy-tor..."
    echo "   URL: $OBFS4_URL"
    pkg add $OBFS4_URL > /dev/null 2>&1 &
    spinner $!
    print_success "obfs4proxy-tor installed"

    print_info "Installing webtunnel-tor..."
    echo "   URL: $WEBTUNNEL_URL"
    pkg add $WEBTUNNEL_URL > /dev/null 2>&1 &
    spinner $!
    print_success "webtunnel-tor installed"
}

configure_bridges() {
    print_step "Configuring Tor bridges..."

    echo ""
    print_info "You need to obtain Tor bridges for obfs4 and webtunnel"
    print_info "Visit: https://bridges.torproject.org/"
    print_info "Or send email to: bridges@torproject.org"
    echo ""
    print_warning "Please prepare your bridge lines before continuing"
    echo ""
    printf "${COLOR_YELLOW}Press Enter when ready to input bridges...${COLOR_RESET}"
    read dummy

    echo ""
    print_info "Enter your obfs4 bridge lines (one per line, empty line to finish):"
    OBFS4_BRIDGES=""
    while true; do
        printf "${COLOR_CYAN}Bridge obfs4 > ${COLOR_RESET}"
        read bridge_line
        if [ -z "$bridge_line" ]; then
            break
        fi
        if echo "$bridge_line" | grep -q "^Bridge"; then
            OBFS4_BRIDGES="${OBFS4_BRIDGES}${bridge_line}\n"
        else
            OBFS4_BRIDGES="${OBFS4_BRIDGES}Bridge obfs4 ${bridge_line}\n"
        fi
    done

    echo ""
    print_info "Enter your webtunnel bridge lines (one per line, empty line to finish):"
    WEBTUNNEL_BRIDGES=""
    while true; do
        printf "${COLOR_CYAN}Bridge webtunnel > ${COLOR_RESET}"
        read bridge_line
        if [ -z "$bridge_line" ]; then
            break
        fi
        if echo "$bridge_line" | grep -q "^Bridge"; then
            WEBTUNNEL_BRIDGES="${WEBTUNNEL_BRIDGES}${bridge_line}\n"
        else
            WEBTUNNEL_BRIDGES="${WEBTUNNEL_BRIDGES}Bridge webtunnel ${bridge_line}\n"
        fi
    done

    if [ -z "$OBFS4_BRIDGES" ] && [ -z "$WEBTUNNEL_BRIDGES" ]; then
        print_error "No bridges configured. At least one bridge is required!"
        exit 1
    fi
}

configure_tor() {
    print_step "Configuring Tor..."

    TORRC_PATH="/usr/local/etc/tor/torrc"

    if [ -f "$TORRC_PATH" ]; then
        print_info "Backing up existing torrc..."
        cp "$TORRC_PATH" "${TORRC_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
        rm -f "$TORRC_PATH"
    fi

    print_info "Creating new torrc configuration..."

    cat > "$TORRC_PATH" << EOF
DNSPort ${LOCAL_IP}:53
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1
RunAsDaemon 1
TransPort 9040
ExcludeNodes {RU}, {BY}, {KG}, {KZ}, {UZ}, {TJ}, {TM}, {TR}, {AZ}, {AM}
ExcludeExitNodes {RU}, {BY}, {KG}, {KZ}, {UZ}, {TJ}, {TM}, {TR}, {AZ}, {AM}
HeartbeatPeriod 1 hours
ExitRelay 0

ClientTransportPlugin obfs4 exec /usr/local/bin/obfs4proxy managed

ClientTransportPlugin webtunnel exec /usr/local/bin/webtunnel-tor-client

UseBridges 1

EOF

    if [ -n "$OBFS4_BRIDGES" ]; then
        printf "$OBFS4_BRIDGES" >> "$TORRC_PATH"
    fi

    if [ -n "$WEBTUNNEL_BRIDGES" ]; then
        printf "$WEBTUNNEL_BRIDGES" >> "$TORRC_PATH"
    fi

    print_success "torrc configured at $TORRC_PATH"
}

setup_autostart() {
    print_step "Setting up autostart..."

    AUTOSTART_SCRIPT="/usr/local/etc/rc.d/tor.sh"

    if [ -f "$AUTOSTART_SCRIPT" ]; then
        print_info "Removing existing autostart script..."
        rm -f "$AUTOSTART_SCRIPT"
    fi

    cat > "$AUTOSTART_SCRIPT" << 'EOF'
#!/bin/sh
/usr/local/bin/tor
EOF

    chmod +x "$AUTOSTART_SCRIPT"

    print_success "Autostart configured at $AUTOSTART_SCRIPT"
}

install_antizapret_script() {
    print_step "Installing AntiZapret IP list updater..."

    SCRIPT_DIR="/root/antizapret"

    if [ ! -d "$SCRIPT_DIR" ]; then
        print_info "Cloning AntiZapret repository..."
        cd /root
        git clone https://github.com/Limych/antizapret.git > /dev/null 2>&1 &
        spinner $!
        print_success "Repository cloned"
    else
        print_info "AntiZapret directory already exists, updating..."
        cd "$SCRIPT_DIR"
        git pull > /dev/null 2>&1 &
        spinner $!
        print_success "Repository updated"
    fi

    chmod +x "${SCRIPT_DIR}/antizapret.pl"

    print_info "Running initial IP list update..."
    "${SCRIPT_DIR}/antizapret.pl" > /usr/local/www/ipfw_antizapret.dat 2>&1 &
    spinner $!
    print_success "IP list updated"
}

configure_opnsense() {
    print_step "Configuring OPNsense integration..."

    ACTIONS_CONF="/usr/local/opnsense/service/conf/actions.d/actions_antizapret.conf"

    if [ -d "/usr/local/opnsense/service/conf/actions.d/" ]; then
        print_info "Setting up OPNsense actions..."

        cat > "$ACTIONS_CONF" << 'EOF'
[cron-iplist-renew]
command:/root/antizapret/antizapret.pl | tee /usr/local/www/ipfw_antizapret.dat | xargs pfctl -t AntiZapret_IPs -T add
parameters:
type:script
message:Renew AntiZapret IP-list
description:Renew AntiZapret IP-list
EOF

        print_info "Reloading configd..."
        service configd restart > /dev/null 2>&1 &
        spinner $!

        print_success "OPNsense actions configured"
        print_info "You can now add a cron job via System > Settings > Cron"
        print_info "Command: Renew AntiZapret IP-list"
    else
        print_warning "OPNsense service directory not found"
        print_info "You may need to manually set up cron job:"
        print_info "  /root/antizapret/antizapret.pl | tee /usr/local/www/ipfw_antizapret.dat | xargs pfctl -t AntiZapret_IPs -T add"
    fi
}

start_tor() {
    print_step "Starting Tor..."

    if pgrep -x tor > /dev/null; then
        print_info "Stopping existing Tor process..."
        pkill tor
        sleep 2
    fi

    /usr/local/bin/tor > /dev/null 2>&1 &
    sleep 3

    if pgrep -x tor > /dev/null; then
        print_success "Tor started successfully"
    else
        print_error "Failed to start Tor"
        print_info "Check logs with: tail -f /var/log/tor/notices.log"
        exit 1
    fi
}

print_next_steps() {
    echo ""
    print_header
    print_success "Installation completed successfully!"
    echo ""
    print_step "Next steps:"
    echo ""
    print_info "1. Configure firewall rules in OPNsense:"
    echo "   - Go to Firewall > Aliases"
    echo "   - Create alias: Name=AntiZapret_IPs, Type=External (advanced)"
    echo "   - Content URL: https://${LOCAL_IP}/ipfw_antizapret.dat"
    echo ""
    print_info "2. Set up NAT Port Forward rule:"
    echo "   - Go to Firewall > NAT > Port Forward"
    echo "   - Interface: LAN"
    echo "   - Protocol: TCP"
    echo "   - Destination: AntiZapret_IPs"
    echo "   - Redirect target IP: 127.0.0.1"
    echo "   - Redirect target port: 9040"
    echo ""
    print_info "3. Add cron job for daily updates:"
    echo "   - Go to System > Settings > Cron"
    echo "   - Add task: Command = Renew AntiZapret IP-list"
    echo ""
    print_info "Configuration files:"
    echo "   - Tor config: /usr/local/etc/tor/torrc"
    echo "   - IP list: /usr/local/www/ipfw_antizapret.dat"
    echo "   - Autostart: /usr/local/etc/rc.d/tor.sh"
    echo ""
    print_info "Useful commands:"
    echo "   - Check Tor status: ps aux | grep tor"
    echo "   - View Tor logs: tail -f /var/log/tor/notices.log"
    echo "   - Restart Tor: pkill tor && /usr/local/bin/tor"
    echo "   - Update IP list: /root/antizapret/antizapret.pl"
    echo ""
    print_warning "Don't forget to configure your firewall rules in OPNsense GUI!"
    echo ""
}

main() {
    print_header

    check_root
    detect_system
    detect_local_ip

    printf "\n${COLOR_YELLOW}Ready to install AntiZapret. Continue? (Y/n): ${COLOR_RESET}"
    read confirm
    if [ "$confirm" = "n" ] || [ "$confirm" = "N" ]; then
        print_info "Installation cancelled"
        exit 0
    fi

    install_dependencies
    configure_bridges
    configure_tor
    setup_autostart
    install_antizapret_script
    configure_opnsense
    start_tor
    print_next_steps
}

main

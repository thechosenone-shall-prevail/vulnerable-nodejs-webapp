#!/bin/bash

# Setup script for flag protection system
# Configures cronjob and initial flag backups

CTF_DIR="/opt/ctf"
SCRIPT_DIR="$CTF_DIR/scripts"
CRON_FILE="/etc/cron.d/ctf-flag-monitor"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_status $RED "Error: This script must be run as root"
        exit 1
    fi
}

# Function to create directory structure
create_directories() {
    print_status $YELLOW "Creating directory structure..."
    
    mkdir -p "$CTF_DIR"/{scripts,flags/backup,logs}
    mkdir -p "$CTF_DIR/uploads"
    
    # Set proper permissions
    chown -R root:root "$CTF_DIR"
    chmod 755 "$CTF_DIR"
    chmod 755 "$CTF_DIR/scripts"
    chmod 700 "$CTF_DIR/flags"
    chmod 700 "$CTF_DIR/flags/backup"
    chmod 755 "$CTF_DIR/logs"
    
    print_status $GREEN "✓ Directory structure created"
}

# Function to install flag monitoring script
install_monitor_script() {
    print_status $YELLOW "Installing flag monitoring script..."
    
    # Copy the monitoring script
    if [[ -f "flag_integrity.sh" ]]; then
        cp flag_integrity.sh "$SCRIPT_DIR/"
    else
        print_status $RED "Error: flag_integrity.sh not found in current directory"
        exit 1
    fi
    
    # Make it executable
    chmod +x "$SCRIPT_DIR/flag_integrity.sh"
    chown root:root "$SCRIPT_DIR/flag_integrity.sh"
    
    print_status $GREEN "✓ Flag monitoring script installed"
}

# Function to setup cronjob
setup_cronjob() {
    print_status $YELLOW "Setting up cronjob..."
    
    # Create cron entry - run every 2 minutes
    cat > "$CRON_FILE" << EOF
# CTF Flag Integrity Monitor
# Runs every 2 minutes to check and restore flag integrity
*/2 * * * * root $SCRIPT_DIR/flag_integrity.sh >/dev/null 2>&1

# Hourly comprehensive check
0 * * * * root $SCRIPT_DIR/flag_integrity.sh >> $CTF_DIR/logs/hourly_check.log 2>&1
EOF
    
    # Set proper permissions
    chmod 644 "$CRON_FILE"
    chown root:root "$CRON_FILE"
    
    # Reload cron service
    if command -v systemctl >/dev/null 2>&1; then
        systemctl reload cron 2>/dev/null || systemctl reload crond 2>/dev/null
    elif command -v service >/dev/null 2>&1; then
        service cron reload 2>/dev/null || service crond reload 2>/dev/null
    fi
    
    print_status $GREEN "✓ Cronjob configured"
}

# Function to create initial flag backups
create_initial_backups() {
    print_status $YELLOW "Creating initial flag backups..."
    
    # Look for ALL flag files based on CTF scoring system
    local flag_files=(
        # Critical Flags (80 points total)
        "flag_root.txt"                                    # 40 points - Root RCE flag
        "uploads/secret_backup.sql"                        # 20 points - Database backup
        "secrets/.env.bak"                                 # 10 points - Environment backup
        "secrets/odd_words.txt"                            # 10 points - Secret words
        
        # Application Flags (40 points total)
        "public/images/flag_weird.svg"                      # 20 points - Public image flag
        "uploads/student_records.csv"                       # 10 points - Student records
        "uploads/secret_notes.txt"                          # 10 points - Secret notes
    )
    
    for flag in "${flag_files[@]}"; do
        if [[ -f "$flag" ]]; then
            # Create directory structure in CTF dir if needed
            flag_dir="$CTF_DIR/$(dirname "$flag")"
            mkdir -p "$flag_dir"
            cp "$flag" "$CTF_DIR/$flag"
            chown root:root "$CTF_DIR/$flag"
            chmod 644 "$CTF_DIR/$flag"
            print_status $GREEN "✓ Copied $flag to CTF directory"
        fi
    done
    
    # Run initial backup creation
    if [[ -f "$SCRIPT_DIR/flag_integrity.sh" ]]; then
        "$SCRIPT_DIR/flag_integrity.sh"
        print_status $GREEN "✓ Initial flag backups created"
    fi
}

# Function to setup log rotation
setup_log_rotation() {
    print_status $YELLOW "Setting up log rotation..."
    
    cat > "/etc/logrotate.d/ctf-flags" << EOF
$CTF_DIR/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        # Optional: send alert if logs were rotated
        # echo "CTF logs rotated on \$(date)" | mail -s "CTF Log Rotation" admin@example.com
    endscript
}
EOF
    
    print_status $GREEN "✓ Log rotation configured"
}

# Function to create monitoring dashboard
create_monitoring_dashboard() {
    print_status $YELLOW "Creating monitoring dashboard..."
    
    cat > "$CTF_DIR/flag_monitor.py" << 'EOF'
#!/usr/bin/env python3
import os
import json
from datetime import datetime, timedelta

def parse_log_file(log_file):
    events = []
    try:
        with open(log_file, 'r') as f:
            for line in f:
                if 'ALERT:' in line:
                    events.append(line.strip())
    except FileNotFoundError:
        pass
    return events

def main():
    ctf_dir = os.environ.get('CTF_DIR', '/opt/ctf')
    log_file = f"{ctf_dir}/logs/flag_monitor.log"
    alert_file = f"{ctf_dir}/logs/flag_alerts.log"
    
    print("=== CTF Flag Protection Status ===")
    print(f"Last check: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Show recent alerts
    alerts = parse_log_file(alert_file)
    if alerts:
        print("Recent Alerts:")
        for alert in alerts[-10:]:  # Last 10 alerts
            print(f"  {alert}")
    else:
        print("✓ No recent alerts")
    
    print()
    
    # Show flag file status
    flag_files = ['flag_root.txt', 'flag_user.txt', 'flag_admin.txt']
    print("Flag Files Status:")
    for flag in flag_files:
        flag_path = f"{ctf_dir}/{flag}"
        if os.path.exists(flag_path):
            stat = os.stat(flag_path)
            modified = datetime.fromtimestamp(stat.st_mtime)
            print(f"  ✓ {flag} - Last modified: {modified.strftime('%Y-%m-%d %H:%M:%S')}")
        else:
            print(f"  ✗ {flag} - Missing")

if __name__ == "__main__":
    main()
EOF
    
    chmod +x "$CTF_DIR/flag_monitor.py"
    chown root:root "$CTF_DIR/flag_monitor.py"
    
    print_status $GREEN "✓ Monitoring dashboard created"
}

# Function to display setup summary
show_summary() {
    print_status $GREEN "=== Setup Complete ==="
    echo
    echo "Flag protection system has been installed with:"
    echo "  • Flag integrity monitoring (runs every 2 minutes)"
    echo "  • Automatic flag restoration from backups"
    echo "  • Comprehensive logging and alerting"
    echo "  • Log rotation (7-day retention)"
    echo "  • Monitoring dashboard"
    echo
    echo "Important files:"
    echo "  • Monitor script: $SCRIPT_DIR/flag_integrity.sh"
    echo "  • Cronjob: $CRON_FILE"
    echo "  • Logs: $CTF_DIR/logs/"
    echo "  • Flag backups: $CTF_DIR/flags/backup/"
    echo "  • Dashboard: $CTF_DIR/flag_monitor.py"
    echo
    echo "To check status: $CTF_DIR/flag_monitor.py"
    echo "To view logs: tail -f $CTF_DIR/logs/flag_monitor.log"
    echo
    print_status $YELLOW "Note: Make sure your flag files are in $CTF_DIR/"
}

# Main execution
main() {
    print_status $GREEN "=== CTF Flag Protection Setup ==="
    echo
    
    check_root
    create_directories
    install_monitor_script
    setup_cronjob
    create_initial_backups
    setup_log_rotation
    create_monitoring_dashboard
    show_summary
}

# Run main function
main "$@"

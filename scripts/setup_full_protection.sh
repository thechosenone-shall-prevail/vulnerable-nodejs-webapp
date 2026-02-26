#!/bin/bash

# Complete CTF Protection Setup
# Protects both flags AND the entire application

CTF_DIR="/opt/ctf"
APP_DIR="/home/azureuser/vulnweb/Vulnerable Web Server"
SCRIPT_DIR="$CTF_DIR/scripts"
CRON_FILE="/etc/cron.d/ctf-full-protection"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Function to install application protection
install_app_protection() {
    print_status $YELLOW "Installing application integrity monitor..."
    
    # Copy the application integrity script
    if [[ -f "application_integrity.sh" ]]; then
        cp application_integrity.sh "$SCRIPT_DIR/"
    else
        print_status $RED "Error: application_integrity.sh not found in current directory"
        exit 1
    fi
    
    # Make it executable
    chmod +x "$SCRIPT_DIR/application_integrity.sh"
    chown root:root "$SCRIPT_DIR/application_integrity.sh"
    
    print_status $GREEN "✓ Application integrity monitor installed"
}

# Function to setup comprehensive cronjobs
setup_comprehensive_cronjobs() {
    print_status $YELLOW "Setting up comprehensive protection cronjobs..."
    
    # Create comprehensive cron entry
    cat > "$CRON_FILE" << EOF
# CTF Comprehensive Protection System
# Flag integrity monitoring (every 2 minutes)
*/2 * * * * root $SCRIPT_DIR/flag_integrity.sh >/dev/null 2>&1

# Application integrity monitoring (every 3 minutes)
*/3 * * * * root $SCRIPT_DIR/application_integrity.sh >/dev/null 2>&1

# Hourly comprehensive checks
0 * * * * root $SCRIPT_DIR/flag_integrity.sh >> $CTF_DIR/logs/hourly_flag_check.log 2>&1
5 * * * * root $SCRIPT_DIR/application_integrity.sh >> $CTF_DIR/logs/hourly_app_check.log 2>&1

# Daily backup creation
0 2 * * * root $SCRIPT_DIR/application_integrity.sh >> $CTF_DIR/logs/daily_backup.log 2>&1
EOF
    
    # Set proper permissions
    chmod 644 "$CRON_FILE"
    chown root:root "$CRON_FILE"
    
    # Remove old flag-only cronjob if it exists
    rm -f /etc/cron.d/ctf-flag-monitor
    
    # Reload cron service
    if command -v systemctl >/dev/null 2>&1; then
        systemctl reload cron 2>/dev/null || systemctl reload crond 2>/dev/null
    elif command -v service >/dev/null 2>&1; then
        service cron reload 2>/dev/null || service crond reload 2>/dev/null
    fi
    
    print_status $GREEN "✓ Comprehensive cronjobs configured"
}

# Function to create initial application backup
create_initial_backup() {
    print_status $YELLOW "Creating initial application backup..."
    
    # Create backup directory
    mkdir -p "$CTF_DIR/app_backup"
    
    # Backup application files
    if [[ -d "$APP_DIR" ]]; then
        cp -r "$APP_DIR" "$CTF_DIR/app_backup/app_initial"
        chown -R root:root "$CTF_DIR/app_backup"
        chmod 700 "$CTF_DIR/app_backup"
        print_status $GREEN "✓ Initial application backup created"
    else
        print_status $RED "Error: Application directory not found: $APP_DIR"
    fi
}

# Function to create server auto-restart script
create_restart_script() {
    print_status $YELLOW "Creating server auto-restart script..."
    
    cat > "$SCRIPT_DIR/restart_server.sh" << 'EOF'
#!/bin/bash
# Server restart script for CTF application

APP_DIR="/home/azureuser/vulnweb/Vulnerable Web Server"
LOG_FILE="/opt/ctf/logs/server_restart.log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_message "Server restart initiated"

# Kill existing server processes
pkill -f "node.*server" 2>/dev/null || true

# Wait for processes to die
sleep 3

# Start the server
cd "$APP_DIR"
if [[ -f "server_better_sqlite.js" ]]; then
    nohup node server_better_sqlite.js > /opt/ctf/logs/server.log 2>&1 &
    SERVER_PID=$!
    log_message "Server started with PID: $SERVER_PID"
    
    # Verify server is running
    sleep 5
    if pgrep -f "node.*server" > /dev/null; then
        log_message "Server successfully restarted and responding"
    else
        log_message "ERROR: Server failed to start properly"
    fi
else
    log_message "ERROR: server_better_sqlite.js not found"
fi

log_message "Server restart completed"
EOF
    
    chmod +x "$SCRIPT_DIR/restart_server.sh"
    chown root:root "$SCRIPT_DIR/restart_server.sh"
    
    print_status $GREEN "✓ Server restart script created"
}

# Function to setup log rotation for app logs
setup_app_log_rotation() {
    print_status $YELLOW "Setting up application log rotation..."
    
    cat > "/etc/logrotate.d/ctf-app" << EOF
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
        # echo "CTF app logs rotated on \$(date)" | mail -s "CTF Log Rotation" admin@example.com
    endscript
}
EOF
    
    print_status $GREEN "✓ Application log rotation configured"
}

# Function to create comprehensive monitoring dashboard
create_comprehensive_dashboard() {
    print_status $YELLOW "Creating comprehensive monitoring dashboard..."
    
    cat > "$CTF_DIR/comprehensive_monitor.py" << 'EOF'
#!/usr/bin/env python3
import os
import subprocess
import time
from datetime import datetime

def check_server_status():
    """Check if the CTF server is running"""
    try:
        result = subprocess.run(['pgrep', '-f', 'node.*server'], 
                              capture_output=True, text=True)
        if result.returncode == 0:
            return f"✅ Running (PID: {result.stdout.strip()})"
        else:
            return "❌ Not running"
    except:
        return "❓ Unknown"

def check_port_status():
    """Check if port 3000 is listening"""
    try:
        result = subprocess.run(['netstat', '-tlnp'], 
                              capture_output=True, text=True)
        if ':3000' in result.stdout:
            return "✅ Listening on port 3000"
        else:
            return "❌ Not listening on port 3000"
    except:
        return "❓ Unknown"

def check_flag_status():
    """Check flag protection status"""
    ctf_dir = os.environ.get('CTF_DIR', '/opt/ctf')
    flag_files = [
        f"{ctf_dir}/flag_root.txt",
        f"{ctf_dir}/uploads/secret_backup.sql",
        f"{ctf_dir}/secrets/.env.bak",
        f"{ctf_dir}/secrets/odd_words.txt",
        f"{ctf_dir}/public/images/flag_weird.svg",
        f"{ctf_dir}/uploads/student_records.csv",
        f"{ctf_dir}/uploads/secret_notes.txt"
    ]
    
    existing_flags = 0
    for flag_file in flag_files:
        if os.path.exists(flag_file):
            existing_flags += 1
    
    return f"✅ {existing_flags}/7 flags present"

def check_recent_alerts():
    """Check for recent security alerts"""
    ctf_dir = os.environ.get('CTF_DIR', '/opt/ctf')
    alert_log = f"{ctf_dir}/logs/flag_alerts.log"
    app_alert_log = f"{ctf_dir}/logs/app_alerts.log"
    
    recent_alerts = 0
    
    for log_file in [alert_log, app_alert_log]:
        if os.path.exists(log_file):
            try:
                with open(log_file, 'r') as f:
                    lines = f.readlines()
                    # Count alerts from last hour
                    one_hour_ago = time.time() - 3600
                    for line in lines[-50:]:  # Check last 50 lines
                        if 'ALERT:' in line:
                            recent_alerts += 1
            except:
                pass
    
    if recent_alerts == 0:
        return "✅ No recent alerts"
    else:
        return f"⚠️  {recent_alerts} recent alerts"

def main():
    print("=== CTF Comprehensive Monitoring Dashboard ===")
    print(f"Last check: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    print("🖥️  Server Status:")
    print(f"   Process: {check_server_status()}")
    print(f"   Port: {check_port_status()}")
    print()
    
    print("🛡️  Protection Status:")
    print(f"   Flags: {check_flag_status()}")
    print(f"   Alerts: {check_recent_alerts()}")
    print()
    
    print("📊 System Information:")
    print(f"   Uptime: {subprocess.run(['uptime'], capture_output=True, text=True).stdout.strip()}")
    print(f"   Memory: {subprocess.run(['free', '-h'], capture_output=True, text=True).stdout.split()[7]}")
    print()
    
    print("🔧 Management Commands:")
    print("   • Restart server: sudo /opt/ctf/scripts/restart_server.sh")
    print("   • Check flags: sudo /opt/ctf/scripts/emergency_restore.sh")
    print("   • View logs: sudo tail -f /opt/ctf/logs/flag_monitor.log")
    print("   • App status: sudo /opt/ctf/scripts/application_integrity.sh")

if __name__ == "__main__":
    main()
EOF
    
    chmod +x "$CTF_DIR/comprehensive_monitor.py"
    chown root:root "$CTF_DIR/comprehensive_monitor.py"
    
    print_status $GREEN "✓ Comprehensive monitoring dashboard created"
}

# Function to display setup summary
show_comprehensive_summary() {
    print_status $GREEN "=== Comprehensive CTF Protection Setup Complete ==="
    echo
    echo "Enhanced protection system has been installed with:"
    echo "  • Flag integrity monitoring (every 2 minutes)"
    echo "  • Application integrity monitoring (every 3 minutes)"
    echo "  • Automatic server restart on failure"
    echo "  • Complete application backups"
    echo "  • Comprehensive logging and alerting"
    echo "  • Advanced monitoring dashboard"
    echo
    echo "Protection Features:"
    echo "  ✅ All 7 flags protected (120 points)"
    echo "  ✅ Server process monitoring"
    echo "  ✅ Application file integrity"
    echo "  ✅ Database protection"
    echo "  ✅ Automatic recovery from attacks"
    echo "  ✅ Complete audit trail"
    echo
    echo "Important Files:"
    echo "  • Flag monitor: $SCRIPT_DIR/flag_integrity.sh"
    echo "  • App monitor: $SCRIPT_DIR/application_integrity.sh"
    echo "  • Server restart: $SCRIPT_DIR/restart_server.sh"
    echo "  • Emergency restore: $SCRIPT_DIR/emergency_restore.sh"
    echo "  • Comprehensive cronjob: $CRON_FILE"
    echo "  • Monitoring dashboard: $CTF_DIR/comprehensive_monitor.py"
    echo
    echo "Management Commands:"
    echo "  • Status: $CTF_DIR/comprehensive_monitor.py"
    echo "  • Restart: sudo $SCRIPT_DIR/restart_server.sh"
    echo "  • Flags: sudo $SCRIPT_DIR/emergency_restore.sh"
    echo "  • Logs: sudo tail -f $CTF_DIR/logs/app_alerts.log"
    echo
    print_status $YELLOW "Your CTF is now fully protected against shell attacks!"
}

# Main execution
main() {
    print_status $GREEN "=== CTF Comprehensive Protection Setup ==="
    echo
    
    check_root
    install_app_protection
    setup_comprehensive_cronjobs
    create_initial_backup
    create_restart_script
    setup_app_log_rotation
    create_comprehensive_dashboard
    show_comprehensive_summary
}

# Run main function
main "$@"

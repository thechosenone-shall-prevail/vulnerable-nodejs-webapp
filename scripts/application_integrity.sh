#!/bin/bash

# Application Integrity Monitor for CTF Environment
# Protects the entire application, not just flags

CTF_DIR="/opt/ctf"
APP_DIR="/home/azureuser/vulnweb/Vulnerable Web Server"
LOG_FILE="$CTF_DIR/logs/app_integrity.log"
ALERT_LOG="$CTF_DIR/logs/app_alerts.log"
BACKUP_DIR="$CTF_DIR/app_backup"

# Create directories if they don't exist
mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$ALERT_LOG")"

# Function to log with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to log alerts
log_alert() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: $1" >> "$ALERT_LOG"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: $1" >> "$LOG_FILE"
}

# Function to create application backup
create_app_backup() {
    log_message "Creating application backup"
    
    # Backup critical files
    cp -r "$APP_DIR" "$BACKUP_DIR/app_$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    
    # Backup database
    if [[ -f "$APP_DIR/data.db" ]]; then
        cp "$APP_DIR/data.db" "$BACKUP_DIR/data.db" 2>/dev/null || true
    fi
    
    log_message "Application backup completed"
}

# Function to restore application
restore_application() {
    log_alert "Restoring application from backup"
    
    # Find latest backup
    local latest_backup=$(ls -t "$BACKUP_DIR"/app_* 2>/dev/null | head -1)
    
    if [[ -n "$latest_backup" ]]; then
        # Restore application files
        cp -r "$latest_backup"/* "$APP_DIR/" 2>/dev/null || true
        
        # Restore database
        if [[ -f "$BACKUP_DIR/data.db" ]]; then
            cp "$BACKUP_DIR/data.db" "$APP_DIR/" 2>/dev/null || true
        fi
        
        # Fix permissions
        chown -R azureuser:azureuser "$APP_DIR" 2>/dev/null || true
        chmod +x "$APP_DIR"/scripts/*.sh 2>/dev/null || true
        
        log_alert "Application restored from $latest_backup"
        
        # Restart the server
        restart_server
    else
        log_alert "No application backup found for restoration"
    fi
}

# Function to restart server
restart_server() {
    log_message "Attempting to restart server"
    
    # Kill any existing node processes
    pkill -f "node.*server" 2>/dev/null || true
    
    # Wait a moment
    sleep 2
    
    # Start the server
    cd "$APP_DIR"
    nohup node server_better_sqlite.js > "$CTF_DIR/logs/server.log" 2>&1 &
    
    # Check if server started
    sleep 3
    if pgrep -f "node.*server" > /dev/null; then
        log_message "Server restarted successfully (PID: $(pgrep -f 'node.*server'))"
    else
        log_alert "Failed to restart server"
    fi
}

# Function to check application integrity
check_app_integrity() {
    local issues_found=0
    
    # Check if application directory exists
    if [[ ! -d "$APP_DIR" ]]; then
        log_alert "Application directory missing: $APP_DIR"
        ((issues_found++))
    fi
    
    # Check critical files
    local critical_files=(
        "$APP_DIR/server_better_sqlite.js"
        "$APP_DIR/package.json"
        "$APP_DIR/data.db"
        "$APP_DIR/public"
        "$APP_DIR/uploads"
        "$APP_DIR/secrets"
    )
    
    for file in "${critical_files[@]}"; do
        if [[ ! -e "$file" ]]; then
            log_alert "Critical file/directory missing: $file"
            ((issues_found++))
        fi
    done
    
    # Check if server is running
    if ! pgrep -f "node.*server" > /dev/null; then
        log_alert "Server process not running"
        ((issues_found++))
    fi
    
    # Check if server is responding on port 3000
    if ! netstat -tlnp 2>/dev/null | grep -q ":3000"; then
        log_alert "Server not listening on port 3000"
        ((issues_found++))
    fi
    
    return $issues_found
}

# Function to check dependencies
check_dependencies() {
    local issues_found=0
    
    # Check if Node.js is available
    if ! command -v node >/dev/null 2>&1; then
        log_alert "Node.js not found"
        ((issues_found++))
    fi
    
    # Check if better-sqlite3 is installed
    if ! node -e "require('better-sqlite3')" 2>/dev/null; then
        log_alert "better-sqlite3 module not available"
        ((issues_found++))
    fi
    
    return $issues_found
}

# Main monitoring function
monitor_application() {
    log_message "Starting application integrity check"
    
    local total_issues=0
    
    # Check application integrity
    check_app_integrity
    local app_issues=$?
    ((total_issues += app_issues))
    
    # Check dependencies
    check_dependencies
    local dep_issues=$?
    ((total_issues += dep_issues))
    
    # Take action if issues found
    if [[ $total_issues -gt 0 ]]; then
        log_alert "Found $total_issues application integrity issues"
        
        # Create backup before restoration (if possible)
        if [[ -d "$APP_DIR" ]]; then
            create_app_backup
        fi
        
        # Restore application
        restore_application
        
        log_message "Application recovery completed"
    else
        log_message "Application integrity check passed"
    fi
    
    log_message "Application integrity check completed"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

# Set directories if not provided
if [[ -z "$CTF_DIR" ]]; then
    CTF_DIR="/opt/ctf"
fi

if [[ -z "$APP_DIR" ]]; then
    APP_DIR="/home/azureuser/vulnweb/Vulnerable Web Server"
fi

# Run monitoring
monitor_application

exit 0

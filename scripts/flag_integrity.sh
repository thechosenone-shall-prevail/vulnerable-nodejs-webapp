#!/bin/bash

# Flag Integrity Monitor for CTF Environment
# Protects against unauthorized flag modifications

CTF_DIR="/opt/ctf"
LOG_FILE="$CTF_DIR/logs/flag_monitor.log"
FLAG_BACKUP_DIR="$CTF_DIR/flags/backup"
ALERT_LOG="$CTF_DIR/logs/flag_alerts.log"

# Create directories if they don't exist
mkdir -p "$FLAG_BACKUP_DIR"
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

# Function to calculate file hash
calculate_hash() {
    sha256sum "$1" | cut -d' ' -f1
}

# Function to restore flag from backup
restore_flag() {
    local flag_file="$1"
    local flag_name=$(basename "$flag_file")
    local backup_file="$FLAG_BACKUP_DIR/$flag_name"
    
    if [[ -f "$backup_file" ]]; then
        cp "$backup_file" "$flag_file"
        chown root:root "$flag_file"
        chmod 644 "$flag_file"
        log_alert "Restored $flag_name from backup"
        return 0
    else
        log_alert "No backup found for $flag_name"
        return 1
    fi
}

# Function to create initial backup
create_backup() {
    local flag_file="$1"
    local flag_name=$(basename "$flag_file")
    
    if [[ -f "$flag_file" ]]; then
        cp "$flag_file" "$FLAG_BACKUP_DIR/$flag_name"
        chown root:root "$FLAG_BACKUP_DIR/$flag_name"
        chmod 600 "$FLAG_BACKUP_DIR/$flag_name"
        log_message "Created backup for $flag_name"
    fi
}

# Function to verify flag integrity
verify_flag() {
    local flag_file="$1"
    local flag_name=$(basename "$flag_file")
    local hash_file="$FLAG_BACKUP_DIR/${flag_name}.hash"
    
    if [[ ! -f "$flag_file" ]]; then
        log_alert "$flag_name is missing"
        restore_flag "$flag_file"
        return 1
    fi
    
    if [[ ! -f "$hash_file" ]]; then
        calculate_hash "$flag_file" > "$hash_file"
        chown root:root "$hash_file"
        chmod 600 "$hash_file"
        log_message "Created hash for $flag_name"
        return 0
    fi
    
    local current_hash=$(calculate_hash "$flag_file")
    local stored_hash=$(cat "$hash_file")
    
    if [[ "$current_hash" != "$stored_hash" ]]; then
        log_alert "$flag_name has been modified!"
        log_alert "Current hash: $current_hash"
        log_alert "Expected hash: $stored_hash"
        
        # Log modification details
        local stat_output=$(stat -c "%y %U %G %a" "$flag_file" 2>/dev/null || stat -f "%Sm %Su %Sg %Lp" "$flag_file" 2>/dev/null)
        log_alert "File info: $stat_output"
        
        restore_flag "$flag_file"
        return 1
    fi
    
    return 0
}

# Main monitoring function
monitor_flags() {
    log_message "Starting flag integrity check"
    
    # Define ALL flag files to monitor based on CTF scoring system
    local flag_files=(
        # Critical Flags (80 points total)
        "$CTF_DIR/flag_root.txt"                                    # 40 points - Root RCE flag
        "$CTF_DIR/uploads/secret_backup.sql"                        # 20 points - Database backup
        "$CTF_DIR/secrets/.env.bak"                                 # 10 points - Environment backup
        "$CTF_DIR/secrets/odd_words.txt"                            # 10 points - Secret words
        
        # Application Flags (40 points total)
        "$CTF_DIR/public/images/flag_weird.svg"                      # 20 points - Public image flag
        "$CTF_DIR/uploads/student_records.csv"                       # 10 points - Student records
        "$CTF_DIR/uploads/secret_notes.txt"                          # 10 points - Secret notes
    )
    
    local issues_found=0
    
    for flag_file in "${flag_files[@]}"; do
        if [[ -f "$flag_file" ]]; then
            # Create backup if it doesn't exist
            if [[ ! -f "$FLAG_BACKUP_DIR/$(basename "$flag_file")" ]]; then
                create_backup "$flag_file"
            fi
            
            # Verify integrity
            if ! verify_flag "$flag_file"; then
                ((issues_found++))
            fi
        else
            log_message "Flag file not found: $flag_file"
        fi
    done
    
    if [[ $issues_found -eq 0 ]]; then
        log_message "All flags verified - integrity intact"
    else
        log_alert "Found and fixed $issues_found flag integrity issues"
    fi
    
    log_message "Flag integrity check completed"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

# Set CTF directory if not provided
if [[ -z "$CTF_DIR" ]]; then
    CTF_DIR="$(dirname "$(readlink -f "$0")")/.."
fi

# Run monitoring
monitor_flags

exit 0

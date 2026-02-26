#!/bin/bash

# Emergency Flag Restore Script
# Manual restoration of flags from secure backup

CTF_DIR="/opt/ctf"
FLAG_BACKUP_DIR="$CTF_DIR/flags/backup"
LOG_FILE="$CTF_DIR/logs/emergency_restore.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_status $RED "Error: This script must be run as root"
        exit 1
    fi
}

# Function to backup current flags before restore
backup_current_flags() {
    print_status $YELLOW "Backing up current flags..."
    
    local backup_timestamp=$(date +%Y%m%d_%H%M%S)
    local emergency_backup_dir="$CTF_DIR/flags/emergency_backup_$backup_timestamp"
    
    mkdir -p "$emergency_backup_dir"
    
    local flag_files=(
        "$CTF_DIR/flag_root.txt"
        "$CTF_DIR/flag_user.txt"
        "$CTF_DIR/flag_admin.txt"
    )
    
    for flag_file in "${flag_files[@]}"; do
        if [[ -f "$flag_file" ]]; then
            cp "$flag_file" "$emergency_backup_dir/"
            print_status $GREEN "✓ Backed up $(basename "$flag_file")"
        fi
    done
    
    log_message "Created emergency backup in $emergency_backup_dir"
    print_status $GREEN "✓ Emergency backup created: $emergency_backup_dir"
}

# Function to restore from backup
restore_from_backup() {
    local backup_timestamp="$1"
    
    if [[ -z "$backup_timestamp" ]]; then
        print_status $YELLOW "Available backups:"
        ls -la "$CTF_DIR/flags/" | grep "emergency_backup_"
        echo
        read -p "Enter backup timestamp (e.g., 20240126_143000): " backup_timestamp
    fi
    
    local backup_dir="$CTF_DIR/flags/emergency_backup_$backup_timestamp"
    
    if [[ ! -d "$backup_dir" ]]; then
        print_status $RED "Error: Backup directory not found: $backup_dir"
        return 1
    fi
    
    print_status $YELLOW "Restoring from backup: $backup_dir"
    
    local restored_files=0
    for flag_file in "$backup_dir"/*.txt; do
        if [[ -f "$flag_file" ]]; then
            local flag_name=$(basename "$flag_file")
            local target_path="$CTF_DIR/$flag_name"
            
            cp "$flag_file" "$target_path"
            chown root:root "$target_path"
            chmod 644 "$target_path"
            
            print_status $GREEN "✓ Restored $flag_name"
            ((restored_files++))
        fi
    done
    
    if [[ $restored_files -gt 0 ]]; then
        log_message "Restored $restored_files flags from backup $backup_timestamp"
        print_status $GREEN "✓ Successfully restored $restored_files flag files"
    else
        print_status $YELLOW "No flag files found in backup"
    fi
}

# Function to restore from original secure backup
restore_from_original() {
    print_status $YELLOW "Restoring from original secure backup..."
    
    if [[ ! -d "$FLAG_BACKUP_DIR" ]]; then
        print_status $RED "Error: Original backup directory not found"
        return 1
    fi
    
    local restored_files=0
    
    # Define ALL flag files to restore based on CTF scoring system
    local flag_files=(
        # Critical Flags (80 points total)
        "flag_root.txt"                                    # 40 points - Root RCE flag
        "secret_backup.sql"                                # 20 points - Database backup
        ".env.bak"                                         # 10 points - Environment backup
        "odd_words.txt"                                    # 10 points - Secret words
        
        # Application Flags (40 points total)
        "flag_weird.svg"                                   # 20 points - Public image flag
        "student_records.csv"                              # 10 points - Student records
        "secret_notes.txt"                                 # 10 points - Secret notes
    )
    
    for flag_name in "${flag_files[@]}"; do
        local backup_file="$FLAG_BACKUP_DIR/$flag_name"
        local target_path
        
        # Determine target path based on flag type
        case "$flag_name" in
            "flag_root.txt")
                target_path="$CTF_DIR/$flag_name"
                ;;
            "secret_backup.sql"|"student_records.csv"|"secret_notes.txt")
                target_path="$CTF_DIR/uploads/$flag_name"
                mkdir -p "$(dirname "$target_path")"
                ;;
            ".env.bak"|"odd_words.txt")
                target_path="$CTF_DIR/secrets/$flag_name"
                mkdir -p "$(dirname "$target_path")"
                ;;
            "flag_weird.svg")
                target_path="$CTF_DIR/public/images/$flag_name"
                mkdir -p "$(dirname "$target_path")"
                ;;
            *)
                target_path="$CTF_DIR/$flag_name"
                ;;
        esac
        
        if [[ -f "$backup_file" ]]; then
            cp "$backup_file" "$target_path"
            chown root:root "$target_path"
            chmod 644 "$target_path"
            
            print_status $GREEN "✓ Restored $flag_name to $target_path"
            ((restored_files++))
        fi
    done
    
    if [[ $restored_files -gt 0 ]]; then
        log_message "Restored $restored_files flags from original backup"
        print_status $GREEN "✓ Successfully restored $restored_files flag files"
    else
        print_status $YELLOW "No flag files found in original backup"
    fi
}

# Function to recreate flags from template
recreate_flags() {
    print_status $YELLOW "Recreating flags from template..."
    
    # Create directories
    mkdir -p "$CTF_DIR/uploads"
    mkdir -p "$CTF_DIR/secrets"
    mkdir -p "$CTF_DIR/public/images"
    
    # Recreate Critical Flags (80 points total)
    
    # Root Flag (40 points)
    cat > "$CTF_DIR/flag_root.txt" << 'EOF'
FLAG_ROOT: WU{root-2-shell-AcQuIrEd}
Note: Intended to be read only via RCE (e.g., uploaded shell) or traversal if you reach the filesystem root of the app.
note from the author : Things you owe, end up owing you back.
final note from the author : this brain melting session, this knowledge, this constant GPT iterations is what builds you, use your precious time purely for gaining persistent knowledge :)
EOF

    # Database Backup Flag (20 points)
    cat > "$CTF_DIR/uploads/secret_backup.sql" << 'EOF'
-- Database backup with hidden flag
-- Contains a "flag" for the exercise
-- FLAG: FLAG{HiDEe_WhAt_YoU_STorE_9f2b}
SELECT * FROM users;
EOF

    # Environment Backup Flag (10 points)
    cat > "$CTF_DIR/secrets/.env.bak" << 'EOF'
# backup env
API_KEY=westbridge-secret-123-condoms-are-like-abstractions-you-only-wear-one
FLAG=FLAG{eNv_bACkuP_flAG}
EOF

    # Secret Words Flag (10 points)
    cat > "$CTF_DIR/secrets/odd_words.txt" << 'EOF'
weird_word_stash: flibbertigibbet
FLAG: FLAG{gIbBeRuSh_sEcReTs_11d9}
EOF

    # Recreate Application Flags (40 points total)
    
    # Public Image Flag (20 points)
    cat > "$CTF_DIR/public/images/flag_weird.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 40" role="img" aria-label="flag weird">
  <rect width="200" height="40" fill="#0a1f3f"/>
  <text x="10" y="26" fill="#FFD700" font-family="IBM Plex Sans, sans-serif" font-size="16">FLAG{quAsI_wYrD_pUbl1c_42}</text>
</svg>
EOF

    # Student Records Flag (10 points)
    cat > "$CTF_DIR/uploads/student_records.csv" << 'EOF'
id,username,full_name,gpa,note
1,mchen,Michael Chen,3.8,Member of Security Club
2,spatel,Sara Patel,3.4,TA for Math
3,dkim,David Kim,3.1,"FLAG: FLAG{LeAKeD_BroThEd_SeMEN_7a1}"
4,lgomez,Laura Gomez,3.9,Scholarship
EOF

    # Secret Notes Flag (10 points)
    cat > "$CTF_DIR/uploads/secret_notes.txt" << 'EOF'
Found this note tucked inside an older directory. Might be useful.
Hint: sometimes the debug endpoint contains surprising data.
FLAG: FLAG{n0t_a_dr1ll_b9c3}
EOF

    # Set proper permissions for all flags
    chmod 644 "$CTF_DIR/flag_root.txt"
    chmod 644 "$CTF_DIR/uploads/secret_backup.sql"
    chmod 644 "$CTF_DIR/uploads/student_records.csv"
    chmod 644 "$CTF_DIR/uploads/secret_notes.txt"
    chmod 644 "$CTF_DIR/secrets/.env.bak"
    chmod 644 "$CTF_DIR/secrets/odd_words.txt"
    chmod 644 "$CTF_DIR/public/images/flag_weird.svg"
    
    chown root:root "$CTF_DIR/flag_root.txt"
    chown root:root "$CTF_DIR/uploads/secret_backup.sql"
    chown root:root "$CTF_DIR/uploads/student_records.csv"
    chown root:root "$CTF_DIR/uploads/secret_notes.txt"
    chown root:root "$CTF_DIR/secrets/.env.bak"
    chown root:root "$CTF_DIR/secrets/odd_words.txt"
    chown root:root "$CTF_DIR/public/images/flag_weird.svg"
    
    log_message "Recreated all flag files from template (7 flags total: 120 points)"
    print_status $GREEN "✓ All 7 flag files recreated from template"
}

# Function to verify flag integrity
verify_flags() {
    print_status $YELLOW "Verifying flag integrity..."
    
    # Define ALL flag files to verify based on CTF scoring system
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
    
    local all_good=true
    
    for flag_file in "${flag_files[@]}"; do
        if [[ -f "$flag_file" ]]; then
            local flag_name=$(basename "$flag_file")
            local size=$(stat -c%s "$flag_file" 2>/dev/null || stat -f%z "$flag_file" 2>/dev/null)
            local perms=$(stat -c "%a" "$flag_file" 2>/dev/null || stat -f "%Lp" "$flag_file" 2>/dev/null)
            local owner=$(stat -c "%U:%G" "$flag_file" 2>/dev/null || stat -f "%Su:%Sg" "$flag_file" 2>/dev/null)
            
            if [[ "$perms" == "644" && "$owner" == "root:root" && $size -gt 0 ]]; then
                print_status $GREEN "✓ $flag_name - OK (size: $size, perms: $perms, owner: $owner)"
            else
                print_status $RED "✗ $flag_name - ISSUE (size: $size, perms: $perms, owner: $owner)"
                all_good=false
            fi
        else
            print_status $RED "✗ $(basename "$flag_file") - MISSING"
            all_good=false
        fi
    done
    
    if $all_good; then
        print_status $GREEN "✓ All flags verified successfully"
        return 0
    else
        print_status $RED "✗ Flag verification failed"
        return 1
    fi
}

# Function to show menu
show_menu() {
    echo
    print_status $BLUE "=== Emergency Flag Restore Menu ==="
    echo "1) Backup current flags"
    echo "2) Restore from emergency backup"
    echo "3) Restore from original secure backup"
    echo "4) Recreate flags from template"
    echo "5) Verify flag integrity"
    echo "6) Show current flag status"
    echo "7) Exit"
    echo
}

# Function to show current status
show_status() {
    print_status $BLUE "=== Current Flag Status (CTF Scoring System) ==="
    echo
    
    # Define ALL flag files to check based on CTF scoring system
    local flag_files=(
        # Critical Flags (80 points total)
        "$CTF_DIR/flag_root.txt:40:Root RCE Flag"
        "$CTF_DIR/uploads/secret_backup.sql:20:Database Backup Flag"
        "$CTF_DIR/secrets/.env.bak:10:Environment Backup Flag"
        "$CTF_DIR/secrets/odd_words.txt:10:Secret Words Flag"
        
        # Application Flags (40 points total)
        "$CTF_DIR/public/images/flag_weird.svg:20:Public Image Flag"
        "$CTF_DIR/uploads/student_records.csv:10:Student Records Flag"
        "$CTF_DIR/uploads/secret_notes.txt:10:Secret Notes Flag"
    )
    
    local total_points=0
    local found_points=0
    
    for flag_info in "${flag_files[@]}"; do
        IFS=':' read -r flag_file points flag_description <<< "$flag_info"
        
        if [[ -f "$flag_file" ]]; then
            local flag_name=$(basename "$flag_file")
            local size=$(stat -c%s "$flag_file" 2>/dev/null || stat -f%z "$flag_file" 2>/dev/null)
            local modified=$(stat -c "%y" "$flag_file" 2>/dev/null || stat -f "%Sm" "$flag_file" 2>/dev/null)
            local perms=$(stat -c "%a" "$flag_file" 2>/dev/null || stat -f "%Lp" "$flag_file" 2>/dev/null)
            local owner=$(stat -c "%U:%G" "$flag_file" 2>/dev/null || stat -f "%Su:%Sg" "$flag_file" 2>/dev/null)
            
            echo "✅ $flag_description ($points points)"
            echo "   📁 File: $flag_file"
            echo "   📊 Size: $size bytes | 🔒 Permissions: $perms | 👤 Owner: $owner"
            echo "   📅 Modified: $modified"
            echo
            ((found_points += points))
        else
            echo "❌ $flag_description ($points points) - NOT FOUND"
            echo "   📁 Expected: $flag_file"
            echo
        fi
        ((total_points += points))
    done
    
    echo "📈 Summary: $found_points/$total_points points available"
    echo
    
    # Show backup directory status
    if [[ -d "$FLAG_BACKUP_DIR" ]]; then
        echo "📦 Original backup directory: $FLAG_BACKUP_DIR"
        ls -la "$FLAG_BACKUP_DIR" 2>/dev/null || echo "   (empty or inaccessible)"
        echo
    fi
    
    # Show emergency backups
    local emergency_backups=($(ls -d "$CTF_DIR/flags/emergency_backup_"* 2>/dev/null))
    if [[ ${#emergency_backups[@]} -gt 0 ]]; then
        echo "📦 Emergency backups:"
        for backup in "${emergency_backups[@]}"; do
            local backup_name=$(basename "$backup")
            echo "   $backup_name"
        done
        echo
    fi
}

# Main function
main() {
    check_root
    
    # Create log directory
    mkdir -p "$(dirname "$LOG_FILE")"
    
    log_message "Emergency restore script started"
    
    while true; do
        show_menu
        read -p "Enter your choice (1-7): " choice
        
        case $choice in
            1)
                backup_current_flags
                ;;
            2)
                restore_from_backup
                ;;
            3)
                restore_from_original
                ;;
            4)
                recreate_flags
                ;;
            5)
                verify_flags
                ;;
            6)
                show_status
                ;;
            7)
                print_status $GREEN "Exiting emergency restore script"
                log_message "Emergency restore script exited"
                exit 0
                ;;
            *)
                print_status $RED "Invalid choice. Please enter 1-7."
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Run main function
main "$@"

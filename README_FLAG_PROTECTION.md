# CTF Flag Protection System

This document describes the comprehensive flag protection system implemented for your Linux CTF environment to prevent unauthorized flag modifications and ensure integrity during Azure VM hosting.

## Overview

The flag protection system consists of multiple layers working together:

1. **Real-time Monitoring** - Continuous flag integrity checking
2. **Automatic Restoration** - Immediate flag recovery from secure backups
3. **Comprehensive Logging** - Detailed audit trail of all flag activities
4. **Emergency Recovery** - Manual restoration capabilities
5. **Azure Integration** - Optimized for Azure VM deployment

## Components

### 1. Flag Integrity Monitor (`flag_integrity.sh`)

**Purpose**: Continuously monitors flag files and automatically restores them if modifications are detected.

**Features**:
- SHA256 hash verification
- Automatic backup creation
- Real-time restoration
- Detailed logging and alerting
- Permission and ownership verification

**Usage**:
```bash
sudo /opt/ctf/scripts/flag_integrity.sh
```

### 2. Setup Script (`setup_flag_protection.sh`)

**Purpose**: One-time installation and configuration of the flag protection system.

**Features**:
- Creates directory structure
- Installs monitoring scripts
- Configures cronjobs
- Sets up log rotation
- Creates monitoring dashboard

**Usage**:
```bash
sudo ./setup_flag_protection.sh
```

### 3. Azure Deployment Script (`azure_deploy.sh`)

**Purpose**: Automated deployment of the entire CTF environment to Azure VM.

**Features**:
- Creates Azure resources (VM, NSG, etc.)
- Configures security groups and firewall
- Deploys application and protection system
- Sets up monitoring and logging

**Usage**:
```bash
./azure_deploy.sh
```

### 4. Emergency Restore Script (`emergency_restore.sh`)

**Purpose**: Manual flag restoration and recovery operations.

**Features**:
- Interactive menu system
- Multiple restore options
- Status verification
- Emergency backup creation

**Usage**:
```bash
sudo /opt/ctf/scripts/emergency_restore.sh
```

## Directory Structure

```
/opt/ctf/
├── scripts/
│   ├── flag_integrity.sh          # Main monitoring script
│   ├── setup_flag_protection.sh   # Installation script
│   └── emergency_restore.sh       # Emergency recovery
├── flags/
│   ├── flag_root.txt              # Root flag
│   ├── flag_user.txt              # User flag
│   ├── flag_admin.txt             # Admin flag
│   └── backup/                    # Secure flag backups
├── logs/
│   ├── flag_monitor.log           # Monitoring logs
│   ├── flag_alerts.log            # Alert logs
│   └── hourly_check.log           # Hourly verification
├── app/                           # CTF application
└── flag_monitor.py               # Monitoring dashboard
```

## Cronjob Configuration

The system installs two cronjobs:

### High-Frequency Monitoring (Every 2 minutes)
```bash
*/2 * * * * root /opt/ctf/scripts/flag_integrity.sh >/dev/null 2>&1
```

### Comprehensive Check (Hourly)
```bash
0 * * * * root /opt/ctf/scripts/flag_integrity.sh >> /opt/ctf/logs/hourly_check.log 2>&1
```

## Security Features

### 1. File Permissions
- Flag files: `644` (root:root)
- Backup directory: `700` (root:root)
- Scripts: `755` (root:root)
- Log files: `644` (root:root)

### 2. Hash Verification
- SHA256 hashes stored securely
- Automatic hash generation for new flags
- Immediate detection of any modifications

### 3. Access Control
- Scripts require root privileges
- Backup directory restricted access
- Comprehensive audit logging

### 4. Network Security
- Azure NSG rules for required ports only
- UFW firewall configuration
- Fail2ban intrusion prevention

## Monitoring and Alerting

### Log Files
- **flag_monitor.log**: All monitoring activities
- **flag_alerts.log**: Security alerts and violations
- **hourly_check.log**: Detailed hourly verification

### Alert Types
- Flag file modifications
- Missing flag files
- Permission changes
- Hash mismatches
- Restoration activities

### Monitoring Dashboard
```bash
/opt/ctf/flag_monitor.py
```

Provides:
- Current flag status
- Recent security alerts
- File modification history
- System health overview

## Deployment Instructions

### 1. Local Setup
```bash
# Clone or copy your CTF application
cd /path/to/your/ctf

# Make scripts executable
chmod +x scripts/*.sh

# Run setup (requires root)
sudo ./scripts/setup_flag_protection.sh
```

### 2. Azure Deployment
```bash
# Ensure Azure CLI is installed and logged in
az login

# Run deployment script
./scripts/azure_deploy.sh
```

### 3. Manual Flag Management
```bash
# Emergency restore
sudo /opt/ctf/scripts/emergency_restore.sh

# Manual integrity check
sudo /opt/ctf/scripts/flag_integrity.sh

# View monitoring dashboard
/opt/ctf/flag_monitor.py
```

## Troubleshooting

### Common Issues

1. **Cronjob not running**
   ```bash
   sudo systemctl status cron
   sudo tail -f /var/log/cron.log
   ```

2. **Permission denied errors**
   ```bash
   sudo chown -R root:root /opt/ctf/flags/
   sudo chmod 700 /opt/ctf/flags/backup/
   ```

3. **Missing flag backups**
   ```bash
   sudo /opt/ctf/scripts/flag_integrity.sh
   ```

4. **Azure VM connectivity issues**
   ```bash
   # Check NSG rules
   az network nsg rule list --resource-group ctf-rg --nsg-name <vm-name>-nsg
   
   # Check VM status
   az vm show --resource-group ctf-rg --name <vm-name> --show-details
   ```

### Recovery Procedures

1. **Automatic Recovery**: The system automatically restores flags within 2 minutes of detection.

2. **Manual Recovery**: Use the emergency restore script for immediate intervention.

3. **Complete Reset**: Recreate flags from templates if backups are compromised.

## Best Practices

### 1. Regular Monitoring
- Check monitoring dashboard daily
- Review alert logs weekly
- Verify backup integrity monthly

### 2. Security Maintenance
- Update Azure VM regularly
- Monitor access logs
- Review firewall rules

### 3. Backup Management
- Test restoration procedures
- Verify backup integrity
- Maintain offline backups

### 4. Incident Response
- Document all security incidents
- Analyze attack patterns
- Update protection mechanisms

## Customization

### Adding New Flags
1. Place flag file in `/opt/ctf/`
2. Run integrity check to create backup
3. Update monitoring script if needed

### Modifying Check Frequency
Edit `/etc/cron.d/ctf-flag-monitor`:
```bash
# Change */2 to */5 for 5-minute intervals
*/5 * * * * root /opt/ctf/scripts/flag_integrity.sh >/dev/null 2>&1
```

### Custom Alerting
Add email notifications to `flag_integrity.sh`:
```bash
log_alert() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: $1" >> "$ALERT_LOG"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: $1" >> "$LOG_FILE"
    # Add email notification
    echo "$1" | mail -s "CTF Flag Alert" admin@example.com
}
```

## Support

For issues with the flag protection system:

1. Check log files in `/opt/ctf/logs/`
2. Run emergency restore script
3. Verify Azure VM configuration
4. Review this documentation

The system is designed to be resilient and self-healing, but manual intervention may be necessary in extreme cases.

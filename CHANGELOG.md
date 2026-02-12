# Changelog

All notable changes to the Neo VPS project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.0.0] - 2026-02-10

### 🎉 Major Release - Multi-Panel Support

### Added
- **Multi-Panel Architecture**: Support for CyberPanel, cPanel, DirectAdmin, and clean servers
- **Golden AMI System**: Single clean AMI for all deployments, panels installed via User Data
- **CyberPanel Support**: FREE OpenLiteSpeed-based control panel with full automation
- **DirectAdmin Support**: Budget-friendly panel option with guided setup
- **Clean Server Option**: No panel installation for custom setups
- **User Data Templates**: Separate installation scripts for each panel type
- **Dynamic Panel Selection**: Customer chooses panel at provision time
- **Enhanced Documentation**: Comprehensive guides for each panel type
- **Cost Comparison Tools**: Detailed pricing analysis for each panel
- **Post-Deployment Instructions**: Panel-specific setup guides in outputs

### Changed
- **Architecture**: Moved from pre-baked AMIs to dynamic installation model
- **Module Name**: Renamed `cpanel-server` to `panel-server` for clarity
- **Installation Process**: Panels now install on first boot via User Data
- **AMI Strategy**: One clean base AMI instead of multiple panel-specific AMIs
- **Deployment Speed**: Faster deployment, installation happens in background
- **Maintenance**: Easier updates by modifying scripts instead of rebuilding AMIs

### Improved
- **Cost Efficiency**: No need to store multiple AMIs
- **Flexibility**: Easy to add new panels or update existing ones
- **Documentation**: Added panel comparison guides and troubleshooting
- **User Experience**: Clear post-deployment instructions for each panel
- **Security**: Enhanced security configurations for all panel types

### Technical Details
- Golden AMI now only contains clean OS (AlmaLinux/Ubuntu)
- User Data scripts handle all panel-specific installation
- Fixed MariaDB dependency issue in CyberPanel installation
- Added comprehensive error logging for installations
- Improved backup integration for all panels

---

## [1.0.0] - 2026-02-09

### Initial Release - cPanel Focus

### Added
- **cPanel/WHM Support**: Full cPanel infrastructure automation
- **Modular Architecture**: Separate modules for network, security, and server
- **Remote State Management**: S3 backend with DynamoDB locking
- **Complete Networking**: VPC, subnets, NAT gateway, Internet gateway
- **Security Groups**: All cPanel ports properly configured
- **Automated Backups**: S3 bucket with versioning and lifecycle policies
- **IAM Roles**: Proper permission management for EC2 instances
- **Monitoring**: CloudWatch metrics and alarms
- **EBS Snapshots**: Daily automated snapshots with retention policies
- **Automation Script**: One-command customer provisioning
- **Multi-OS Support**: AlmaLinux, Rocky Linux, Ubuntu
- **Elastic IPs**: Optional static IP allocation
- **SSM Support**: Secure shell access via AWS Systems Manager

### Infrastructure Components
- Network Module: Complete VPC setup
- Security Module: Security group with cPanel ports
- cPanel Server Module: EC2, IAM, S3, monitoring
- Backend Module: Terraform state management

### Features
- Three hosting plans (Basic, Standard, Premium)
- Cost optimization options
- Detailed cost breakdown
- Comprehensive documentation
- Environment separation
- Customer isolation

---

## Development Roadmap

### [2.1.0] - Planned
- [ ] Plesk panel support
- [ ] Web interface for provisioning
- [ ] Automatic DNS configuration via Route53
- [ ] Cost tracking and reporting dashboard
- [ ] Multi-region support
- [ ] Advanced monitoring dashboards
- [ ] Automated scaling options

### [2.2.0] - Future
- [ ] Kubernetes panel support
- [ ] Docker-based deployments
- [ ] API for programmatic provisioning
- [ ] Customer portal integration
- [ ] Billing system integration
- [ ] Advanced backup strategies
- [ ] Disaster recovery automation

---

## Migration Guide

### Upgrading from v1.0 to v2.0

**For New Deployments:**
- Simply use the new modules and scripts
- Choose your preferred control panel
- Follow the updated Quick Start guide

**For Existing cPanel Deployments:**
- No action required - v1.0 deployments continue working
- To migrate to v2.0 architecture:
  1. Backup all customer data
  2. Export cPanel accounts
  3. Provision new server with v2.0
  4. Restore cPanel accounts
  5. Update DNS records
  6. Destroy old infrastructure

**Important Notes:**
- v1.0 and v2.0 can coexist
- No forced migration required
- New features only in v2.0
- v1.0 will receive security updates only

---

## Support

For questions about specific versions:
- v2.0: See main README.md
- v1.0: See docs/V1_README.md

---

## Contributors

- Primary Developer: Neo VPS Team
- Architecture Design: Claude + Neo Team
- Testing: Community Contributors

---

## Links

- [GitHub Repository](#)
- [Documentation](docs/)
- [Issue Tracker](#)
- [Changelog](CHANGELOG.md)

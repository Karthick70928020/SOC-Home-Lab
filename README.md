# SOC Home Lab

An isolated detection lab built in VMware Workstation: a segmented network,
Active Directory, Sysmon telemetry and a Wazuh SIEM, used to simulate attacks
and write detections.

## Architecture

| Role | Host | IP | OS |
|---|---|---|---|
| Firewall / router | pfSense | 10.10.10.1, 10.10.20.1 | pfSense 2.6 |
| Domain controller | DC01 | 10.10.10.10 | Windows Server 2022 |
| Workstation | WS01 | 10.10.10.20 | Windows 10 Pro |
| SIEM | wazuh | 10.10.10.50 | Ubuntu 24.04, Wazuh 4.14 |

Networks: LAN `10.10.10.0/24`, attack segment `10.10.20.0/24`.
Both are isolated host-only networks. Only pfSense reaches the internet.

## Telemetry pipeline

Sysmon (SwiftOnSecurity config) → Wazuh agent → Wazuh manager → dashboard

## Build notes

Step-by-step notes with screenshots are in [`setup/`](setup/).

## Status

- [x] Segmented network and firewall
- [x] Active Directory domain with OUs and test users
- [x] Sysmon and Wazuh agents on DC01 and WS01
- [ ] Attack simulations and detections
- [ ] Incident reports

## Lessons learned

- The Wazuh OVA hung at boot, so I installed Wazuh on Ubuntu Server instead.
- A large package timed out through the NAT path, so I downloaded it with a
  resumable transfer and let the installer use the cached file.
- Snapshots of running VMs filled my disk, so I now snapshot powered-off VMs.

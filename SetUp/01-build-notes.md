# Build notes

Environment: VMware Workstation, isolated host-only networks, no real credentials
shown in any image.

## 1. Isolated networks

Two private networks with no DHCP and no host adapter: LAN (VMnet2, 10.10.10.0/24)
and attack segment (VMnet3, 10.10.20.0/24). Only pfSense connects them and
reaches the internet through NAT.

![Virtual Network Editor](images/01-vmware-virtual-network-editor.png)
*VMnet2 selected: host-only, host adapter and DHCP both disabled, subnet 10.10.10.0/24.*

## 2. pfSense firewall

pfSense 2.6 with three interfaces: WAN (NAT), LAN and an attack-segment interface.

![pfSense console](images/03-pfsense-console-interfaces.png)
*WAN on NAT, LAN 10.10.10.1/24, attack network 10.10.20.1/24.*

![pfSense dashboard](images/06-pfsense-webgui-dashboard.png)
*Web interface reached from the domain controller (10.10.10.10), all three interfaces up.*

## 3. Domain controller (DC01)

Windows Server 2022 on the LAN at 10.10.10.10, routed through pfSense.

![DC01 VM settings](images/05-dc-vm-settings.png)
*Initial build: 2 vCPU, 3 GB RAM (later reduced to 2 GB), 50 GB disk, VMnet2.*

![Ping to pfSense](images/04-dc-ping-pfsense.png)
*DC01 reaches the firewall, 0% packet loss.*

![Internet test](images/07-dc-internet-test.png)
*Routing and DNS through pfSense work: 8.8.8.8 and google.com both reply.*

![Rename](images/08-dc-renamed-dc01.png)
*Server renamed to DC01 before promotion.*

![AD DS installed](images/09-dc-ad-ds-installed.png)
*Active Directory Domain Services and DNS roles installed.*

![Domain verified](images/10-dc-domain-verified.png)
*lab.local resolves to 10.10.10.10 and the user domain is LAB.*

## 4. Active Directory structure

A small organisation (LabCorp) with OUs, two security groups and five test users,
created with a PowerShell script ([02-create-ad-structure.ps1](02-create-ad-structure.ps1)).

![OUs](images/11-ad-ous-powershell.png)
*OUs created under lab.local.*

![Users](images/13-ad-users-powershell.png)
*Five test users in LabCorp/Users.*

## 5. Windows 10 endpoint (WS01)

Windows 10 Pro joined to lab.local at 10.10.10.20.

![WS01 in Workstations OU](images/12-ad-ws01-in-workstations.png)
*WS01 moved into LabCorp/Workstations.*

![Domain login](images/14-ws01-domain-joined.png)
*Signed in as lab\alice.morgan, domain resolves, internet reachable.*

## 6. Sysmon telemetry

Sysmon with the SwiftOnSecurity configuration on DC01 and WS01.

![Sysmon events on WS01](images/15-ws01-sysmon-events.png)
*Sysmon operational log in Event Viewer on WS01 (process creation, file create, DNS query).*

## 7. Wazuh SIEM

Wazuh 4.14 (indexer, manager, dashboard) on Ubuntu Server 24.04 at 10.10.10.50.
Agents on DC01 and WS01 forward Windows events and the Sysmon log.

![Wazuh overview](images/19-wazuh-overview.png)
*Agents summary: two active agents, alerts by severity for the last 24 hours.*

![Agents](images/20-wazuh-agents-active.png)
*DC01 and WS01 both active, version 4.14.10.*

## 8. Events reaching the SIEM

![DC01 Windows events](images/21-wazuh-dc01-windows-events.png)
*Windows security events (logon, logoff) from DC01.*

![DC01 dashboard](images/22-wazuh-dc01-dashboard.png)
*Threat Hunting dashboard for DC01.*

![DC01 Sysmon detections](images/24-wazuh-dc01-sysmon-detections.png)
*Sysmon-based alerts from DC01. Rules 92039 and 92033 are my test commands
(net user /domain, PowerShell). The executable-dropped alerts are under review.*

![WS01 Sysmon alerts](images/23-wazuh-ws01-sysmon-detections.png)
*291 Sysmon-based alerts from WS01 in 24 hours. The visible rows are rule 92217
(executable dropped in the Windows folder), which I'm triaging as likely
Windows servicing noise.*

## Problems and fixes

| Problem | Cause | Fix |
|---|---|---|
| Wazuh OVA hung at the boot logo | VM stuck, 0% CPU | Installed Wazuh on Ubuntu Server instead |
| Wazuh indexer install timed out | 875 MB download stalled through NAT | Downloaded the package with a resumable transfer, let the installer use the cached file |
| Internet names failed from WS01 | DC01 had no DNS forwarder | Added a forwarder to pfSense and 8.8.8.8 |
| Sysmon events missing in Wazuh | Sysmon log source not in the agent config | Added the Sysmon channel to ossec.conf and restarted the agent |
| VM disk filled up | Snapshots taken while VMs were running | Deleted old snapshots, now snapshot powered-off VMs |

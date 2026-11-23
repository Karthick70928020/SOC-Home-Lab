## 1. Isolated networks and pfSense

Two host-only networks with no DHCP and no host adapter: LAN (VMnet2)
and attack (VMnet3). pfSense routes between them and gives internet via NAT.

![pfSense console](images/03-pfsense-console-interfaces.png)
*pfSense console: WAN on NAT, LAN 10.10.10.1/24, attack network 10.10.20.1/24.*

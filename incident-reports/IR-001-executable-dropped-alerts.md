# IR-001: Executable-dropped alerts on WS01

| Field | Value |
|---|---|
| Date | 2026-11-23 |
| Analyst | [your name] |
| Source | Wazuh rule 92217 (level 6), host WS01 (10.10.10.20) |
| Verdict | Benign: .NET Framework native image generation |

## Summary
Wazuh repeatedly alerted on WS01 with "Executable dropped in Windows root folder".
I investigated to decide whether it was malicious. The creating process was
mscorsvw.exe, a Microsoft .NET component, running as SYSTEM.

## Timeline (IST)
| Time | Event |
|---|---|
| [time I powered on WS01] | WS01 started |
| 11:25 | Burst of 92217 alerts, each for a DLL created by mscorsvw.exe |

## Investigation
1. Searched `agent.name:WS01 and rule.id:92217` in Wazuh Threat Hunting.
2. Opened an alert and read the Sysmon fields (event 11, file created).
3. Verified the creating binary on the host: signature [Valid, signer Microsoft ...],
   service ".NET Runtime Optimization Service" present.

## Evidence
- Creating process: `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\mscorsvw.exe`
- File created: `C:\Windows\assembly\NativeImages_v4.0.30319_64\Temp\4a0-0\TaskScheduler.dll`
- Account: NT AUTHORITY\SYSTEM
- Sysmon event ID 11 (file created), rule name "DLL"

![Alert details](../setup/images/25-ir001-alert-details.png)
![Verification](../setup/images/26-ir001-verification.png)

## Analysis
mscorsvw.exe is the .NET Native Image Generator. It precompiles .NET libraries into
the NativeImages folder as SYSTEM, usually after boot, updates or installs, creating
many DLLs in a row. This matches the burst of alerts. The binary is in its
legitimate location and [is signed by Microsoft].

## Verdict and response
Benign. No containment needed.

## Detection improvement
Rule 92217 fires on any DLL written under C:\Windows, including this normal
behaviour. A tuning option is to lower its level when the creating process is
mscorsvw.exe running as SYSTEM, while keeping the alert for cmd.exe, powershell.exe
and unknown processes.

## Open item
The level-15 alert (rule 92213) is investigated separately in IR-002.

# IR-002: Level-15 "executable dropped" alert on WS01

| Field | Value |
|---|---|
| Incident ID | IR-002 |
| Date | 2026-11-23 |
| Analyst | Karthick A. |
| Detection source | Wazuh rule 92213, "Executable file dropped in folder commonly used by malware" (level 15, the highest level) |
| Rule MITRE mapping | T1105 Ingress Tool Transfer (tactic: Command and Control), as assigned by the rule |
| Host | WS01 (10.10.10.20), Windows 10 Pro, domain lab.local |
| Account | LAB\Administrator |
| Verdict | Benign (false positive) for the two alerts investigated |
| Status | Closed, with follow-ups listed below |

## Summary

On 2026-11-23 at about 12:11 IST, Wazuh raised its highest-severity alert on WS01
for a script file written to the Temp folder. I investigated whether it indicated
tool delivery or malware. The file was created by the standard `powershell.exe`
running under the administrator account. The alert reproduced when I opened a new
PowerShell window, with a new process ID and a new random file name, which is
consistent with PowerShell's own script-policy self-test file. I classified it as a
false positive and recorded a tuning proposal.

## Scope

This report covers the two level-15 alerts in the evidence below (12:11 and 12:21 IST).
Earlier level-15 alerts the same day (DC01 at about 10:53 and WS01 at about 10:57 IST)
were visible in the dashboard but were not individually examined here. Confirming
that they share this cause is listed under follow-ups.

## Timeline (IST)

Sysmon records times in UTC. IST is UTC+5:30.

| Time | Event |
|---|---|
| 12:11 | Sysmon event 11 (file created): `__PSScriptPolicyTest_bcor0uir.uim.ps1` in the administrator's Temp folder, created by `powershell.exe` (PID 2856). Wazuh raises 92213, level 15 |
| 12:21 | I opened a new PowerShell window. Second alert: `__PSScriptPolicyTest_iizuhwno.o3k.ps1`, created by `powershell.exe` (PID 1496) |

## Investigation

1. Opened the alert in Wazuh Threat Hunting and read the Sysmon fields: creating
   process, target file, account and event ID.
2. Checked who created the file. The image path is the standard Windows PowerShell
   location, and the account is a named administrator, not SYSTEM or an unknown user.
3. Reproduced the alert by opening a new PowerShell window. A second level-15 alert
   fired about ten minutes later with a different process ID and a different random
   file name.

## Evidence

| | First alert | Reproduction |
|---|---|---|
| Time (IST) | 12:11 | 12:21 |
| Creating process | `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe` | Same |
| Process ID | 2856 | 1496 |
| File created | `C:\Users\Administrator\AppData\Local\Temp\__PSScriptPolicyTest_bcor0uir.uim.ps1` | `C:\Users\Administrator\AppData\Local\Temp\__PSScriptPolicyTest_iizuhwno.o3k.ps1` |
| Account | LAB\Administrator | LAB\Administrator |
| Sysmon event | 11 (file created) | 11 (file created) |
| Wazuh rule | 92213, level 15, T1105 | Same |

![First alert details](../setup/images/27-ir002-alert-details.png)
*First alert: powershell.exe created a `__PSScriptPolicyTest_` file in Temp.*

![Reproduction](../setup/images/28-ir002-reproduction.png)
*Reproduction: a new PowerShell window produced a new alert, new process ID and new file name.*

## Analysis

- The `__PSScriptPolicyTest_` prefix matches the temporary file PowerShell creates at
  startup to test script policy. Rules that alert on any script written to Temp
  commonly flag it.
- The creating process is `powershell.exe` from its standard System32 location,
  running as a named administrator account in an interactive session.
- The behaviour follows PowerShell starting, not a one-off drop: a new window
  produced a new alert, each with a new process ID and a new random suffix.
- The alerts record file creation only. They show no network download and no
  execution of the created file. The T1105 mapping is the rule's generic mapping,
  and nothing in this evidence shows a tool being transferred.
- Limits: I did not inspect the contents of the created files.

## Verdict and response

Benign, false positive, for the two alerts investigated. No containment, credential
reset or host isolation was needed. The alert is recorded here so the same pattern
is recognised quickly next time.

## Follow-ups

1. Search for level-15 alerts that do not match the self-test file pattern
   (`rule.id:92213 and not data.win.eventdata.targetFilename:*PSScriptPolicyTest*`)
   to confirm the earlier alerts have the same cause, and update this report with
   the result.
2. Implement and test the tuning rule below, and add the results to this report.

## Detection improvement (proposed, not yet implemented)

Rule 92213 assigns level 15 to any script or executable written to Temp, so every
PowerShell start by an administrator raises a critical alert. This buries real
alerts and trains analysts to ignore level 15.

Proposal: a child rule of 92213 that lowers the level (not suppresses it) only when
all three conditions hold:

1. The creating process is the System32 `powershell.exe`.
2. The file name matches `__PSScriptPolicyTest_<random>.<random>.ps1`.
3. The file is in a user Temp folder.

The alert stays at level 15 for any other file. Requiring all three conditions
limits the risk that an attacker hides behind the same file name.

Test plan:

| Test | Expected result |
|---|---|
| Open PowerShell | Alert drops to the lower level |
| Write a different `.ps1` file into Temp from `cmd.exe` | Stays at level 15 |
| Write a file named like the self-test from `cmd.exe` | Stays at level 15 (creating process differs) |

Results of the implementation and tests will be added as an update to this report.

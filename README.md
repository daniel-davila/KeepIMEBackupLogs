# About KeepIMEBackupLogs

I'm a Design Architect for Dell and one of my roles is supporting customers leveraging Microsoft's Autopilot provisioning with Intune. 
One of the main issues with troubleshooting Autopilot are Win32 application installations; the backup logs gets overwritten and there's no way to control how big or how many backup logs are retained.

This project was created to overcome those limitations and it all started with Oliver Kieselbach - a Microsoft MVP out of Germany.

Oliver posted a method to support retaining IME logs based on his research with ProcMon, which he found at the time of his post could be managed via registry keys, however this ability was undocumented/unsupported. At some point in early 2021, Microsoft updated their agent and the registry hacks stopped working. Here's my twitter thread with Oliver for the historical context:
https://twitter.com/okieselb/status/1308428824879812608


## Usage

The code is fairly simple, to use it download the PS1 file and upload to your tenant as a Powershell script (this is the link in the console: https://endpoint.microsoft.com/#blade/Microsoft_Intune_DeviceSettings/DevicesMenu/powershell

Once there, assign it to any group you currently use for Autopilot deployments. The code is currently configured to backup the backups made by the Intune Agent not the current IME log itself, all files remain unmodified, only copies are made.


Any file with a .log extension in the IME logs directory can be retreived with MDMDiagnosticsTool.exe or the Remote Diagnostics action in the MEM console:
https://docs.microsoft.com/en-us/windows/client-management/mdm/diagnose-mdm-failures-in-windows-10

This script creates a copy of itself to the IME log directory, then it creates a scheduled task that is triggered every 5 minutes and system startup until the backup threshold is met ($MaxNumberofBackups). You can edit as needed, but 5 backups is usually enough to have visibility on how the initial Win32 and Powershell tasks were processed during Autopilot provisioning. This includes information on Delivery Optimization, access to the Microsoft Content Delivery Network, System reboots, Exit codes and detections, the status of software dependencies / supercedence, and more. 

## Support

This script is provided as-is, read the script code and adjust as necessary. Use at your own risk.

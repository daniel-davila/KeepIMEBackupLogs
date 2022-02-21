# About The Project

The IntuneManagementExtension.log documents Win32 app and Powershell installations, among other things like reboots and reporting. The fatal flaw for the log is that it gets overwritten, and there's no way to control how big or how many backup logs are retained.

This code was code was created to overcome those limitations.

Oliver Kieselbach - a Microsoft MVP out of Germany had posted a method to support this based on his research with ProcMon, at the time the IME logs could be managed via registry keys, however this ability was undocumented/unsupported. At some point in early 2021, Microsoft updated their agent and the registry hacks stopped working. Here's my twitter thread with Oliver:
https://twitter.com/okieselb/status/1308428824879812608


## Usage

The code is fairly simple, to use it download the PS1 file and upload to your tenant as a Powershell script: https://endpoint.microsoft.com/#blade/Microsoft_Intune_DeviceSettings/DevicesMenu/powershell

Once there, assign it to any group you currently use for Autopilot deployments. The code is currently configured to backup the backups made by the Intune Agent not the current IME log itself, all files remain unmodified, only copies are made.


Any file with a .log extension in the IME logs directory can be retreived with MDMDiagnosticsTool.exe or the Remote Diagnostics action in the MEM console:
https://docs.microsoft.com/en-us/windows/client-management/mdm/diagnose-mdm-failures-in-windows-10

This script creates a copy of itself to the IME log directory, then it creates a scheduled task that is triggered every 5 minutes and system startup until the backup threshold is met ($MaxNumberofBackups). You can edit as needed, but 5 backups is usually enough to have visibility on the initial Win32 and Powersehll tasks were processed during Autopilot provisioning. This includes information on Delivery Optimization, access to the Microsoft Content Delivery Network, System reboots, Exit codes and detetections, the status of software depedendcies and supercedence, and more. 

## Support

This script is provided as-is, read the script code and adjust as necessary. Use at your own risk.

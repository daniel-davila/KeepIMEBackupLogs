<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.162
	 Created on:   	11/18/2021 6:53 PM
	 Created by:   	Daniel Davila
	 Organization: 	Dell Technologies
	 Filename:     	IMEBackups.ps1
	===========================================================================
	.DESCRIPTION
		A script to be run as system and deployed during Autopilot 
		so additional copies of the IntuneManagementExtension.log file can be retained

	.SETUP
		Upload this script to execute as a PowerShell script in Intune: https://endpoint.microsoft.com/#blade/Microsoft_Intune_DeviceSettings/DevicesMenu/powershell
		Assign to any devices that are used to process Autopilot provisioning (Azure AD, Hybrid join and Self-Deploy, User-Driven scenarios are all valid)
		
#>

$PSFileName = "IMEBackups.ps1"
$MaxNumberofBackups = 5
$TaskName = "Dell Custom - Retain additional IME Logs"
$IMEPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
$logFile = "$IMEPath\IMEBackups.log"

Start-Transcript -Path $logFile -Append -Force

Write-Host "Starting IMEBackup Task Schedule prep at $((get-date).datetime)"


$script = @'
$IMEPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
$logFile = "$IMEPath\IMEBackups.log"
$MaxNumberofBackups = 5

Start-Transcript -Path $logFile -Append -Force

Write-Host "Starting IMEBackup script at $((get-date).datetime)"
if (Test-Path $IMEPath)
{
	# Get a list of the current IME backup logs
	$IMEList = Get-ChildItem "$IMEPath\IntuneManagementExtension-*.log" -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime
	
	# Copy the current IME backup files with the default naming convention and rename to something else
	foreach ($file in $IMEList)
	{
		$compare = (Get-ChildItem $("$IMEPath\IMEBackup_" + $file.Name) -ErrorAction SilentlyContinue).name
		if ($compare) { $compare = $compare.Substring(10) }
		if ($compare -ne $file.name)
		{
			Write-Host "Backup $($file.name) to $("$IMEPath\IMEBackup_" + $file.Name)"
			Copy-Item -path $file.FullName -Destination $("$IMEPath\IMEBackup_" + $file.Name)
		}
		else
		{
			# If the log was previously backed up but the source has a bigger version for some reason, copy that source file again with overwrite
			$IMEBackupFileLength = (Get-ChildItem $("$IMEPath\IMEBackup_" + $file.Name) -ErrorAction SilentlyContinue).Length
			if ($file.length -gt $IMEBackupFileLength)
			{
				Write-Host "Force backup $($file.name) due to greater size"
				Copy-Item -path $file.FullName -Destination $("$IMEPath\IMEBackup_" + $file.Name) -Force
			}
		}
	}
	
	# Delete task if we reach the backup goal
	$IMEBackups = Get-ChildItem "$IMEPath\*" -Include IMEBackup_IntuneManagementExtension-* -ErrorAction SilentlyContinue
	if ($IMEBackups.Count -ge $MaxNumberofBackups)
	{
		Write-Host "Reached maximum number of backups: $MaxNumberofBackups. Removing Scheduled task"
		Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false
		Stop-Transcript; Exit
	}
}
else
{
	Write-Host "IME Log path doesn't exist. Exiting."; Stop-Transcript; Exit
}

Stop-Transcript
'@

$script | out-file "$($IMEPath)\$($PSFileName)" -Force

# Create the schedule task if it doesn't already exist
if (!(Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue))
{
	$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -NoProfile -File $($IMEPath)\$($PSFileName)"
	$TaskTrigger = @()
	$TaskTrigger += New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5) -RepetitionInterval (New-TimeSpan -Minutes 5)
	$TaskTrigger += New-ScheduledTaskTrigger -AtStartup
	$TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -Hidden -DontStopIfGoingOnBatteries -Compatibility "Win8" -RunOnlyIfNetworkAvailable -MultipleInstances "IgnoreNew"
	$TaskPrincipal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType "ServiceAccount" -RunLevel "Highest"
	$ScheduledTask = New-ScheduledTask -Action $TaskAction -Principal $TaskPrincipal -Settings $TaskSettings -Trigger $TaskTrigger
	Register-ScheduledTask -InputObject $ScheduledTask -TaskName $TaskName -TaskPath "\" -ErrorAction Stop
	Write-Host "Starting IMEBackup Scheduled Task at $((get-date).datetime)"
	Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue | Start-ScheduledTask
}
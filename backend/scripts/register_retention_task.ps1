param(
    [string]$Python = (Join-Path $PSScriptRoot "..\.venv\Scripts\python.exe"),
    [string]$Time = "02:00"
)

$resolvedPython = (Resolve-Path -LiteralPath $Python).Path
$retentionScript = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "apply_retention.py")).Path
$backendRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$action = New-ScheduledTaskAction -Execute $resolvedPython -Argument "`"$retentionScript`"" -WorkingDirectory $backendRoot
$trigger = New-ScheduledTaskTrigger -Daily -At $Time
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable
Register-ScheduledTask -TaskName "MindShield Data Retention" -Action $action -Trigger $trigger -Settings $settings -Description "Apply configured Mind Shield data retention periods." -Force | Out-Null
Write-Output "Scheduled Mind Shield retention daily at $Time."

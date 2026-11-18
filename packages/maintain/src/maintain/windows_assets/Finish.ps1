$ErrorActionPreference = 'Stop'
Start-Transcript -Path 'C:\Windows\Temp\maintain-image.log' -Force
try {
    $drivers = Get-ChildItem -LiteralPath "$PSScriptRoot\drivers" -Filter '*.inf' -File -Recurse
    if (!$drivers) { throw 'No VirtIO drivers found on the installation media' }
    foreach ($driver in $drivers) {
        & pnputil.exe /add-driver $driver.FullName /install
        # 259 means no matching device or Windows already has a better driver.
        if ($LASTEXITCODE -notin @(0, 259, 3010)) {
            throw "Driver installation failed for $($driver.Name): $LASTEXITCODE"
        }
    }
    $installer = Start-Process msiexec.exe -ArgumentList @('/i', "`"$PSScriptRoot\qemu-ga-x86_64.msi`"", '/qn', '/norestart') -Wait -PassThru
    if ($installer.ExitCode -notin @(0, 3010)) { throw "QEMU guest agent installation failed: $($installer.ExitCode)" }

    # Incus supplies a per-instance agent/config CD. Bootstrap its official
    # installer on the first Incus boot, rather than baking host secrets in.
    New-Item -ItemType Directory -Path 'C:\ProgramData\maintain' -Force | Out-Null
    Copy-Item "$PSScriptRoot\IncusBootstrap.ps1" 'C:\ProgramData\maintain\IncusBootstrap.ps1'
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File C:\ProgramData\maintain\IncusBootstrap.ps1'
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $trigger.Delay = 'PT30S'
    $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    Register-ScheduledTask -TaskName 'Maintain Incus bootstrap' -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null

    # The initial installer autologon must not survive in the finished image.
    $winlogon = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    Set-ItemProperty $winlogon AutoAdminLogon '0'
    Remove-ItemProperty $winlogon DefaultPassword -ErrorAction SilentlyContinue
    Remove-Item 'C:\Windows\Panther\unattend.xml', 'C:\Windows\Panther\Unattend\unattend.xml', 'C:\Windows\System32\Sysprep\unattend.xml' -Force -ErrorAction SilentlyContinue

    # The builder only publishes disks which explicitly completed provisioning.
    $serial = [System.IO.Ports.SerialPort]::new('COM1', 115200)
    $serial.Open()
    $serial.WriteLine('MAINTAIN_WINDOWS_IMAGE_READY')
    $serial.Close()
    Stop-Transcript
    & shutdown.exe /s /t 5
} catch {
    Write-Error $_ -ErrorAction Continue
    Stop-Transcript
    exit 1
}

$ErrorActionPreference = 'Stop'
for ($attempt = 0; $attempt -lt 20; $attempt++) {
    $volume = Get-Volume -FileSystemLabel 'incus-agent' -ErrorAction SilentlyContinue
    if ($volume -and $volume.DriveLetter) {
        $installer = $volume.DriveLetter + ':\install.ps1'
        if (Test-Path $installer) {
            & $installer
            if (!(Get-Service 'Incus-Agent' -ErrorAction SilentlyContinue)) {
                throw 'Incus agent installation did not create the service'
            }
            Unregister-ScheduledTask -TaskName 'Maintain Incus bootstrap' -Confirm:$false
            exit 0
        }
    }
    Start-Sleep -Seconds 3
}
throw 'The Incus agent:config CD was not found'

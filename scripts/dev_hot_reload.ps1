<#
Pornește `flutter run` într-un proces resident și citește comenzi din
`mobile/car_tracker_app/.hot_reload_cmd`:
  reload  -> hot reload (r)
  restart -> hot restart (R)
  quit    -> oprește aplicația (q)
#>
param(
    [string]$Device = "5MKUN25801G02227",
    [string]$ApiBaseUrl = "http://127.0.0.1:8010/api/v1"
)

$ErrorActionPreference = "Stop"
$project = (Resolve-Path (Join-Path $PSScriptRoot "..\mobile\car_tracker_app")).Path
$cmdFile = Join-Path $project ".hot_reload_cmd"
$logFile = Join-Path $project "flutter_run.log"

Remove-Item $cmdFile -ErrorAction SilentlyContinue
New-Item -ItemType File -Path $cmdFile -Force | Out-Null
Set-Content -Path $cmdFile -Value "" -NoNewline

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "cmd.exe"
$psi.Arguments = "/c flutter run -d $Device --dart-define=API_BASE_URL=$ApiBaseUrl > `"$logFile`" 2>&1"
$psi.WorkingDirectory = $project
$psi.RedirectStandardInput = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true

$process = New-Object System.Diagnostics.Process
$process.StartInfo = $psi
$null = $process.Start()

try {
    while (-not $process.HasExited) {
        if (Test-Path $cmdFile) {
            $command = Get-Content -Path $cmdFile -Raw -ErrorAction SilentlyContinue
            if ($command) {
                $command = $command.Trim()
                Set-Content -Path $cmdFile -Value "" -NoNewline
                switch ($command) {
                    "reload" {
                        $process.StandardInput.WriteLine("r")
                        $process.StandardInput.Flush()
                    }
                    "restart" {
                        $process.StandardInput.WriteLine("R")
                        $process.StandardInput.Flush()
                    }
                    "quit" {
                        $process.StandardInput.WriteLine("q")
                        $process.StandardInput.Flush()
                    }
                }
            }
        }
        Start-Sleep -Milliseconds 400
    }
}
finally {
    if (-not $process.HasExited) {
        $process.Kill()
    }
}

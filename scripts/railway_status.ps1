<#
Afiseaza ultimele deployment-uri Railway si logurile de build.
Tokenul este citit din fisier si nu este afisat.
#>
param(
    [string]$ProjectId = "9262e9be-18d1-49cb-8ccc-0652ff2d6578",
    [string]$Environment = "production",
    [string]$Service = "car-stats-tracking",
    [string]$TokenFile = (Join-Path $HOME ".railway_token")
)

$ErrorActionPreference = "Continue"
$env:RAILWAY_TOKEN = (Get-Content -Path $TokenFile -Raw).Trim()
$railwayExe = Join-Path $env:APPDATA "npm\node_modules\@railway\cli\bin\railway.exe"
if (-not (Test-Path $railwayExe)) {
    $railwayExe = "railway"
}

Write-Host "=== Ultimele deployment-uri ==="
& $railwayExe deployment list -p $ProjectId -e $Environment -s $Service --limit 5 --json 2>$null

Write-Host "`n=== Loguri de build (ultimele 80 de linii) ==="
& $railwayExe logs -p $ProjectId -e $Environment -s $Service --build --lines 80 2>$null

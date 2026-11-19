<#
Configureaza serviciul Railway pentru aplicatia Car Tracker:
- seteaza DATABASE_URL (referinta catre Postgres), SECRET_KEY si expirarea JWT;
- genereaza un domeniu public;
- redeployeaza din ultimul commit.

Tokenul este citit securizat din consola (sau din -TokenFile) si nu este
scris pe disc de catre script.
Rulare:
  powershell -ExecutionPolicy Bypass -File scripts\railway_setup.ps1
#>
param(
    [string]$ProjectId = "9262e9be-18d1-49cb-8ccc-0652ff2d6578",
    [string]$Environment = "production",
    [string]$Service = "car-stats-tracking",
    [string]$DatabaseService = "Postgres",
    [string]$TokenFile = ""
)

$ErrorActionPreference = "Continue"

$railwayExe = Join-Path $env:APPDATA "npm\node_modules\@railway\cli\bin\railway.exe"
if (-not (Test-Path $railwayExe)) {
    $railwayExe = "railway"
}
if (-not (Get-Command $railwayExe -ErrorAction SilentlyContinue) -and -not (Test-Path $railwayExe)) {
    throw "Railway CLI lipseste. Ruleaza: npm install -g @railway/cli --allow-scripts=@railway/cli"
}
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw "Python lipseste din PATH."
}

if ($TokenFile) {
    $env:RAILWAY_TOKEN = (Get-Content -Path $TokenFile -Raw).Trim()
}
else {
    Write-Host "Railway project token pentru proiectul ${ProjectId}:"
    $secure = Read-Host -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        $env:RAILWAY_TOKEN = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

Write-Host "Setez variabilele aplicatiei..."
& $railwayExe variable set -p $ProjectId -e $Environment -s $Service --skip-deploys `
    "DATABASE_URL=`${{$DatabaseService.DATABASE_URL}}" `
    "ACCESS_TOKEN_EXPIRE_MINUTES=60" 2>$null | Out-Host

Write-Host "Generez SECRET_KEY..."
python -c "import secrets; print(secrets.token_urlsafe(48))" |
    & $railwayExe variable set SECRET_KEY --stdin -p $ProjectId -e $Environment -s $Service --skip-deploys 2>$null |
    Out-Host

Write-Host "Verific domeniul public..."
$domain = $null
$rawDomains = & $railwayExe domain list --project $ProjectId -e $Environment -s $Service --json 2>$null
try {
    $parsed = $rawDomains | ConvertFrom-Json
    if ($parsed.domains -and $parsed.domains.Count -gt 0) {
        $domain = $parsed.domains[0].domain
    }
}
catch {
    # lista nu a putut fi interpretata; incercam crearea
}

if (-not $domain) {
    $domainOutput = & $railwayExe domain --project $ProjectId -e $Environment -s $Service 2>$null
    $domainOutput | ForEach-Object { Write-Host $_ }
    $match = [regex]::Match(($domainOutput -join "`n"), "https://[^\s]+")
    if ($match.Success) {
        $domain = $match.Value
    }
}

Write-Host "Pornesc deploy-ul din ultimul commit..."
& $railwayExe redeploy -p $ProjectId -e $Environment -s $Service --from-source --yes 2>$null | Out-Host

if ($domain) {
    $domain = $domain.TrimEnd('/')
    Write-Host "Domeniu: $domain"
    Write-Host "Health: $domain/api/v1/health"
    Write-Host "Astept ca serviciul sa raspunda (max. 5 minute)..."
    for ($i = 0; $i -lt 60; $i++) {
        try {
            $response = Invoke-WebRequest -UseBasicParsing `
                -Uri "$domain/api/v1/health" -TimeoutSec 10
            if ($response.StatusCode -eq 200) {
                Write-Host "Serviciul raspunde: $($response.Content)"
                break
            }
        }
        catch {
            # serviciul inca porneste
        }
        Start-Sleep -Seconds 5
    }
}
else {
    Write-Host "Domeniul nu a putut fi generat automat. Genereaza-l din Railway: Settings -> Networking -> Generate Domain."
}

Write-Host "Gata. Trimite domeniul afisat mai sus."

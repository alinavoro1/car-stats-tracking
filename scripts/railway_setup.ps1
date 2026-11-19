<#
Configurează serviciul Railway pentru aplicația Car Tracker:
- setează DATABASE_URL (referință către Postgres), SECRET_KEY și expirarea JWT;
- generează un domeniu public;
- redeployează din ultimul commit.

Tokenul este citit securizat din consolă și nu este scris pe disc.
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

$ErrorActionPreference = "Stop"

if (-not (Get-Command railway -ErrorAction SilentlyContinue)) {
    throw "Railway CLI lipsește. Rulează: npm install -g @railway/cli --allow-scripts=@railway/cli"
}
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw "Python lipsește din PATH."
}

if ($TokenFile) {
    $env:RAILWAY_TOKEN = (Get-Content -Path $TokenFile -Raw).Trim()
}
else {
    Write-Host "Railway project token pentru proiectul $ProjectId:"
    $secure = Read-Host -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        $env:RAILWAY_TOKEN = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

Write-Host "`nSetez variabilele aplicației..."
railway variable set -p $ProjectId -e $Environment -s $Service --skip-deploys `
    "DATABASE_URL=`${{$DatabaseService.DATABASE_URL}}" `
    "ACCESS_TOKEN_EXPIRE_MINUTES=60"

Write-Host "`nGenerez SECRET_KEY..."
python -c "import secrets; print(secrets.token_urlsafe(48))" |
    railway variable set SECRET_KEY --stdin -p $ProjectId -e $Environment -s $Service --skip-deploys

Write-Host "`nGenerez domeniul public..."
$domainOutput = railway domain --project $ProjectId -e $Environment -s $Service 2>&1
$domainOutput | ForEach-Object { Write-Host $_ }
$domain = (($domainOutput | Select-String -Pattern "https://[^\s]+" -AllMatches).Matches.Value |
    Select-Object -First 1)

Write-Host "`nPornesc deploy-ul din ultimul commit..."
railway redeploy -p $ProjectId -e $Environment -s $Service --from-source --yes

if ($domain) {
    Write-Host "`nDomeniu: $domain"
    Write-Host "Health: $domain/api/v1/health"
    Write-Host "Aștept ca serviciul să răspundă (max. 5 minute)..."
    for ($i = 0; $i -lt 60; $i++) {
        try {
            $response = Invoke-WebRequest -UseBasicParsing `
                -Uri "$domain/api/v1/health" -TimeoutSec 10
            if ($response.StatusCode -eq 200) {
                Write-Host "Serviciul răspunde: $($response.Content)"
                break
            }
        }
        catch {
            # serviciul încă pornește
        }
        Start-Sleep -Seconds 5
    }
}

Write-Host "`nGata. Trimite domeniul afișat mai sus."

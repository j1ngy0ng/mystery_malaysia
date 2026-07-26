$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $projectRoot '.env.local.json'

if (-not (Test-Path -LiteralPath $configPath)) {
    throw 'Missing .env.local.json. Copy .env.example.json and paste your Supabase values.'
}

$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
if (
    [string]::IsNullOrWhiteSpace($config.SUPABASE_URL) -or
    [string]::IsNullOrWhiteSpace($config.SUPABASE_PUBLISHABLE_KEY) -or
    $config.SUPABASE_URL -like 'PASTE_*' -or
    $config.SUPABASE_PUBLISHABLE_KEY -like 'PASTE_*'
) {
    throw 'Paste your Supabase URL and publishable key into .env.local.json first.'
}

Push-Location -LiteralPath $projectRoot
try {
    $supabaseDefines = @(
        "--dart-define=SUPABASE_URL=$($config.SUPABASE_URL)"
        "--dart-define=SUPABASE_PUBLISHABLE_KEY=$($config.SUPABASE_PUBLISHABLE_KEY)"
    )
    flutter run @supabaseDefines
}
finally {
    Pop-Location
}

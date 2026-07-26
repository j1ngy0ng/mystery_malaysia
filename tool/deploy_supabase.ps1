$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $projectRoot '.env.local.json'
if (-not (Test-Path -LiteralPath $configPath)) {
    throw 'Missing .env.local.json.'
}

$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
if (
    [string]::IsNullOrWhiteSpace($config.SUPABASE_URL) -or
    $config.SUPABASE_URL -like 'PASTE_*'
) {
    throw 'Paste a valid Supabase URL into .env.local.json first.'
}
$projectUri = [Uri]$config.SUPABASE_URL
$isSupabaseProject = $projectUri.IsAbsoluteUri -and
    $projectUri.Host.EndsWith('.supabase.co')
if (-not $isSupabaseProject) {
    throw 'SUPABASE_URL must be a hosted Supabase project URL.'
}
$projectRef = $projectUri.Host.Split('.')[0]
if ([string]::IsNullOrWhiteSpace($projectRef)) {
    throw 'Paste a valid Supabase URL into .env.local.json first.'
}

Push-Location -LiteralPath $projectRoot
try {
    & npx.cmd --yes supabase@latest projects list --output-format text --agent no
    if ($LASTEXITCODE -ne 0) {
        throw 'Supabase login is required. Run tool\login_supabase.cmd first.'
    }

    & npx.cmd --yes supabase@latest link --project-ref $projectRef --output-format text --agent no
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not link the Supabase project.'
    }

    & npx.cmd --yes supabase@latest db push --output-format text --agent no
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not apply the database migrations.'
    }

    & npx.cmd --yes supabase@latest functions deploy generate-mission --output-format text --agent no
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not deploy the generate-mission Edge Function.'
    }
}
finally {
    Pop-Location
}

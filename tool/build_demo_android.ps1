$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$previousDemoMode = $env:MYSTERY_MALAYSIA_DEMO

Push-Location -LiteralPath $projectRoot
try {
    $env:MYSTERY_MALAYSIA_DEMO = 'true'
    flutter build apk --debug --dart-define=DEMO_MODE=true

    $source = Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-debug.apk'
    $target = Join-Path $projectRoot 'build\app\outputs\flutter-apk\mystery-malaysia-ui-demo.apk'
    Copy-Item -LiteralPath $source -Destination $target -Force
    Write-Output "UI demo APK: $target"
}
finally {
    if ($null -eq $previousDemoMode) {
        Remove-Item Env:MYSTERY_MALAYSIA_DEMO -ErrorAction SilentlyContinue
    }
    else {
        $env:MYSTERY_MALAYSIA_DEMO = $previousDemoMode
    }
    Pop-Location
}

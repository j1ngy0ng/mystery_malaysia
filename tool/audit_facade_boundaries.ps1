$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$lib = Join-Path $projectRoot 'lib'
$view = Join-Path $lib 'view'
$controller = Join-Path $lib 'controller'

$actualLayers = @(
    Get-ChildItem -LiteralPath $lib -Directory |
        ForEach-Object Name |
        Sort-Object
)
$expectedLayers = @('app', 'controller', 'model', 'theme', 'view', 'widgets')
if (Compare-Object $expectedLayers $actualLayers) {
    throw "lib may contain only the three MVC folders and the approved app, theme, and widgets support folders. Found: $($actualLayers -join ', ')"
}

$forbiddenImports = & rg -n -P `
    "^import '.*controller/.*(?:_controller|_service|(?<!_interface)_facade)\.dart';" `
    $view
if ($LASTEXITCODE -eq 0) {
    throw "Views bypass facade interfaces:`n$($forbiddenImports -join "`n")"
}
if ($LASTEXITCODE -ne 1) {
    throw 'Could not audit View imports.'
}

$interfaceImports = & rg -l "_facade_interface\.dart';" $view
if ($LASTEXITCODE -ne 0 -or @($interfaceImports).Count -lt 6) {
    throw 'Expected interactive Views to import controller-layer facade interfaces.'
}

$misplacedInterfaces = & rg -l 'abstract interface class' $lib |
    Where-Object { -not $_.StartsWith($controller, [System.StringComparison]::OrdinalIgnoreCase) }
if (@($misplacedInterfaces).Count -gt 0) {
    throw "Interfaces must be inside an MVC layer:`n$($misplacedInterfaces -join "`n")"
}

Write-Output (
    "MVC boundary audit passed: lib contains the three MVC folders and approved support folders; " +
    "$(@($interfaceImports).Count) Views use controller-layer interfaces."
)

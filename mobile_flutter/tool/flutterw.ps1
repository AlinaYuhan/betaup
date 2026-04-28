param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArgs,
    [string]$FlutterRoot = $env:FLUTTER_ROOT
)

$ErrorActionPreference = "Stop"

$candidateRoots = @(
    $FlutterRoot,
    "F:\flutter",
    "C:\src\flutter",
    "$HOME\flutter"
) | Where-Object { $_ -and $_.Trim() }

$resolvedRoot = $null
foreach ($candidate in $candidateRoots) {
    $snapshot = Join-Path $candidate "bin\cache\flutter_tools.snapshot"
    $dart = Join-Path $candidate "bin\cache\dart-sdk\bin\dart.exe"
    $packages = Join-Path $candidate "packages\flutter_tools\.dart_tool\package_config.json"
    if ((Test-Path $snapshot) -and (Test-Path $dart) -and (Test-Path $packages)) {
        $resolvedRoot = $candidate
        break
    }
}

if (-not $resolvedRoot) {
    throw "Unable to locate a usable Flutter SDK. Set FLUTTER_ROOT or pass -FlutterRoot."
}

$env:FLUTTER_ROOT = $resolvedRoot

$dartExe = Join-Path $resolvedRoot "bin\cache\dart-sdk\bin\dart.exe"
$packageConfig = Join-Path $resolvedRoot "packages\flutter_tools\.dart_tool\package_config.json"
$snapshotPath = Join-Path $resolvedRoot "bin\cache\flutter_tools.snapshot"

& $dartExe "--packages=$packageConfig" $snapshotPath @FlutterArgs
exit $LASTEXITCODE

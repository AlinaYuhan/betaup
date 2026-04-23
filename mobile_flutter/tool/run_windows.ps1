param(
    [string]$MirrorPath = "C:\betaup_mobile_ascii",
    [switch]$BuildOnly,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArgs
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$windowsDir = Join-Path $projectRoot "windows"

if (-not (Test-Path $windowsDir)) {
    throw "Windows runner not found: $windowsDir"
}

if (Test-Path $MirrorPath) {
    $item = Get-Item -LiteralPath $MirrorPath -Force
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) {
        throw "Mirror path exists and is not a junction: $MirrorPath"
    }
    cmd /c rmdir "$MirrorPath" | Out-Null
}

cmd /c mklink /J "$MirrorPath" "$projectRoot" | Out-Null

try {
    Push-Location $MirrorPath

    flutter clean
    flutter pub get

    if ($BuildOnly) {
        flutter build windows --debug @FlutterArgs
    } elseif ($FlutterArgs.Count -eq 0) {
        flutter run -d windows
    } else {
        flutter run -d windows @FlutterArgs
    }
}
finally {
    Pop-Location
}

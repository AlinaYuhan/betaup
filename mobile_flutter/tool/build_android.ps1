param(
    [string]$MirrorPath = "C:\betaup_mobile_android_ascii",
    [Parameter(ValueFromRemainingArguments = $true, Position = 0)]
    [string[]]$FlutterArgs
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$androidDir = Join-Path $projectRoot "android"

if (-not (Test-Path $androidDir)) {
    throw "Android runner not found: $androidDir"
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

    if ($FlutterArgs.Count -eq 0) {
        $FlutterArgs = @("build", "apk", "--release")
    } elseif ($FlutterArgs[0].StartsWith("-")) {
        $FlutterArgs = @("build", "apk") + $FlutterArgs
    }

    powershell -ExecutionPolicy Bypass -File .\tool\flutterw.ps1 @FlutterArgs
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}

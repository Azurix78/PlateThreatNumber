[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$AddOnsPath = 'C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns'
)

$ErrorActionPreference = 'Stop'

try {
    $sourceRoot = Split-Path -Parent $PSScriptRoot
    $addonName = 'PlateThreatNumber'
    $tocName = "$addonName.toc"
    $tocPath = Join-Path $sourceRoot $tocName

    if (-not (Test-Path -LiteralPath $AddOnsPath -PathType Container)) {
        throw "The AddOns folder does not exist: $AddOnsPath"
    }

    # Copy only the manifest, documentation and files loaded by the game.
    $files = @($tocName, 'README.md') + @(
        Get-Content -LiteralPath $tocPath -Encoding UTF8 |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -and -not $_.StartsWith('#') }
    )
    foreach ($file in $files) {
        # This addon currently uses a flat directory layout.
        if ($file -ne [System.IO.Path]::GetFileName($file) -or $file.Contains(':')) {
            throw "Expected a file name without a directory in the TOC: $file"
        }
        if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot $file) -PathType Leaf)) {
            throw "Missing source file: $file"
        }
    }

    $destination = Join-Path (Resolve-Path -LiteralPath $AddOnsPath).Path $addonName
    if ($PSCmdlet.ShouldProcess($destination, "Deploy $($files.Count) addon files")) {
        [System.IO.Directory]::CreateDirectory($destination) | Out-Null
        foreach ($file in $files) {
            Copy-Item -LiteralPath (Join-Path $sourceRoot $file) `
                -Destination (Join-Path $destination $file) -Force
        }
        Write-Host "Deployed $($files.Count) files to: $destination" -ForegroundColor Green
        Write-Host 'Restart WoW for a first installation, or use /reload for an update.'
    }
}
catch {
    Write-Error -Message $_.Exception.Message -ErrorAction Continue
    Write-Host 'If Windows denied access, right-click Deploy.cmd and choose Run as administrator.'
    exit 1
}

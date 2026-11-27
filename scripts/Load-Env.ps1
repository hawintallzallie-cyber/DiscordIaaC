<#
.SYNOPSIS
    Loads .env into the current PowerShell session.

.DESCRIPTION
    Terraform reads DISCORD_TOKEN, TF_CLOUD_ORGANIZATION and TF_WORKSPACE from
    the environment. PowerShell does not read .env files on its own, so this
    sets them for the current session only -- nothing is written to the user or
    machine environment, and the values disappear when the terminal closes.

    Variable names are printed. Values are not.

.EXAMPLE
    .\scripts\Load-Env.ps1
#>

[CmdletBinding()]
param(
    [string]$Path = ".env"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Path)) {
    Write-Error "No '$Path' found. Copy .env.example to .env and fill it in (see docs/runbooks/bootstrap.md)."
    exit 1
}

$loaded = @()

foreach ($line in Get-Content -LiteralPath $Path) {
    $trimmed = $line.Trim()

    if ($trimmed -eq "" -or $trimmed.StartsWith("#")) {
        continue
    }

    $separator = $trimmed.IndexOf("=")
    if ($separator -lt 1) {
        Write-Warning "Skipping line without a name=value pair: $trimmed"
        continue
    }

    $name = $trimmed.Substring(0, $separator).Trim()
    $value = $trimmed.Substring($separator + 1).Trim().Trim('"').Trim("'")

    if ($value -eq "") {
        Write-Warning "$name is present but empty."
        continue
    }

    Set-Item -Path "env:$name" -Value $value
    $loaded += $name
}

if ($loaded.Count -eq 0) {
    Write-Warning "Nothing was loaded from '$Path'."
}
else {
    Write-Host "Loaded into this session: $($loaded -join ', ')"
}

$missing = @("DISCORD_TOKEN", "TF_CLOUD_ORGANIZATION", "TF_WORKSPACE") |
    Where-Object { -not (Test-Path "env:$_") }

if ($missing.Count -gt 0) {
    Write-Warning "Still unset, and Terraform needs these: $($missing -join ', ')"
}

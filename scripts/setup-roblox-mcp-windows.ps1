#Requires -Version 5.1
<#
.SYNOPSIS
  Configure Roblox Studio MCP for Cursor on Windows.

.DESCRIPTION
  1. Verifies Roblox Studio / mcp.bat are present
  2. Merges Roblox_Studio into %USERPROFILE%\.cursor\mcp.json
  3. Prints Studio-side steps (Assistant MCP + HTTP requests)

  Run in PowerShell (as your user, not Admin required):
    Set-ExecutionPolicy -Scope Process Bypass -Force
    .\scripts\setup-roblox-mcp-windows.ps1
#>

$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Write-Ok([string]$Message) {
    Write-Host "  OK  $Message" -ForegroundColor Green
}

function Write-Warn([string]$Message) {
    Write-Host "  !!  $Message" -ForegroundColor Yellow
}

function Write-Fail([string]$Message) {
    Write-Host "  XX  $Message" -ForegroundColor Red
}

$robloxMcpBat = Join-Path $env:LOCALAPPDATA "Roblox\mcp.bat"
$cursorDir = Join-Path $env:USERPROFILE ".cursor"
$cursorMcpJson = Join-Path $cursorDir "mcp.json"

$robloxServer = @{
    command = "cmd.exe"
    args    = @("/c", "%LOCALAPPDATA%\Roblox\mcp.bat")
}

Write-Step "Checking Roblox Studio MCP files"

if (Test-Path $robloxMcpBat) {
    Write-Ok "Found mcp.bat at $robloxMcpBat"
} else {
    Write-Fail "mcp.bat not found at $robloxMcpBat"
    Write-Warn "Install or update Roblox Studio, open it once, then re-run this script."
    Write-Warn "Download: https://www.roblox.com/create"
    exit 1
}

$studioMcpCandidates = Get-ChildItem -Path (Join-Path $env:LOCALAPPDATA "Roblox\Versions") -Filter "StudioMCP.exe" -Recurse -ErrorAction SilentlyContinue
if ($studioMcpCandidates) {
    Write-Ok "Found StudioMCP.exe ($($studioMcpCandidates.Count) copy/copies)"
} else {
    Write-Warn "StudioMCP.exe not found under Versions — mcp.bat may still work after a Studio update."
}

Write-Step "Configuring Cursor MCP (%USERPROFILE%\.cursor\mcp.json)"

if (-not (Test-Path $cursorDir)) {
    New-Item -ItemType Directory -Path $cursorDir | Out-Null
    Write-Ok "Created $cursorDir"
}

$config = @{ mcpServers = @{} }

if (Test-Path $cursorMcpJson) {
    try {
        $raw = Get-Content -Raw -Path $cursorMcpJson | ConvertFrom-Json
        if ($raw.mcpServers) {
            $raw.mcpServers.PSObject.Properties | ForEach-Object {
                $config.mcpServers[$_.Name] = $_.Value
            }
        }
        Write-Ok "Loaded existing mcp.json"
    } catch {
        Write-Warn "Could not parse existing mcp.json — backing up and creating a fresh file."
        Copy-Item $cursorMcpJson "$cursorMcpJson.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        $config = @{ mcpServers = @{} }
    }
}

$config.mcpServers["Roblox_Studio"] = $robloxServer

$json = $config | ConvertTo-Json -Depth 10
Set-Content -Path $cursorMcpJson -Value $json -Encoding UTF8
Write-Ok "Wrote $cursorMcpJson"

Write-Step "Roblox Studio (manual — ~30 seconds)"

Write-Host @"

  In Roblox Studio:
    1. Open Assistant (top bar)
    2. Click ... > Manage MCP Servers
    3. Turn ON "Enable Studio as MCP server"
    4. Optional quick connect: Assistant Settings > MCP Servers > Quick connect > Cursor

  Security (required for MCP):
    Home > Game Settings > Security
      - Allow HTTP Requests = ON
      - Allow local ports to access Studio = ON (if shown)

  Then:
    1. Fully quit Cursor (tray icon too) and reopen
    2. Open this project in Cursor (not Cloud Agent only)
    3. Settings > Tools & MCP — Roblox_Studio should show green / tools listed

  Verify in Studio: Manage MCP Servers shows a green connected-client indicator.

"@

Write-Step "Done"
Write-Ok "Cursor config is ready. Complete the Studio steps above, then restart Cursor."

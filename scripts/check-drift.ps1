param(
  [Parameter(Mandatory = $false)]
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$ErrorActionPreference = 'Stop'
$governanceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$files = @('AGENTS.md', 'ARCHITECTURE.md', 'DECISIONS.md', 'PROJECT_RULES.md', 'TODO.md', 'WORKFLOW.md')
$drift = $false

Write-Host "Governance workspace: $WorkspaceRoot"
Write-Host "Versioned governance: $governanceRoot"

foreach ($file in $files) {
  $workspaceFile = Join-Path $WorkspaceRoot $file
  $versionedFile = Join-Path $governanceRoot $file
  if (-not (Test-Path $workspaceFile) -or -not (Test-Path $versionedFile)) {
    Write-Host "FILE MISSING: $file"
    $drift = $true
    continue
  }
  $workspaceHash = (Get-FileHash -Algorithm SHA256 $workspaceFile).Hash
  $versionedHash = (Get-FileHash -Algorithm SHA256 $versionedFile).Hash
  if ($workspaceHash -eq $versionedHash) {
    Write-Host "FILE OK: $file"
  } else {
    Write-Host "FILE DRIFT: $file"
    $drift = $true
  }
}

$architecture = Get-Content -Raw (Join-Path $governanceRoot 'ARCHITECTURE.md')
$frontendRecorded = [regex]::Match($architecture, 'Frontend main: `([0-9a-f]{40})`').Groups[1].Value
$backendRecorded = [regex]::Match($architecture, 'Backend main: `([0-9a-f]{40})`').Groups[1].Value

$frontendActual = (& git -C (Join-Path $WorkspaceRoot 'GlossyPOS-Frontend') rev-parse main).Trim()
$backendActual = (& git -C (Join-Path $WorkspaceRoot 'GlossyPOS-Backend') rev-parse main).Trim()

if ($frontendRecorded -eq $frontendActual) {
  Write-Host "FRONTEND SHA OK: $frontendActual"
} else {
  Write-Host "FRONTEND SHA DRIFT: recorded=$frontendRecorded actual=$frontendActual"
  $drift = $true
}

if ($backendRecorded -eq $backendActual) {
  Write-Host "BACKEND SHA OK: $backendActual"
} else {
  Write-Host "BACKEND SHA DRIFT: recorded=$backendRecorded actual=$backendActual"
  $drift = $true
}

if ($drift) {
  Write-Error 'Governance drift detected.'
  exit 1
}

Write-Host 'Governance drift check passed.'

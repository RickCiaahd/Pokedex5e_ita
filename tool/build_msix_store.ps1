param(
  [Parameter(Mandatory = $true)]
  [string]$IdentityName,

  [Parameter(Mandatory = $true)]
  [string]$Publisher,

  [Parameter(Mandatory = $true)]
  [string]$PublisherDisplayName,

  [string]$Version,
  [string]$OutputDirectory = "dist\microsoft-store",
  [switch]$SkipChecks
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Resolve-Executable([string]$Name, [string[]]$Fallbacks) {
  $command = Get-Command $Name -ErrorAction SilentlyContinue
  if ($command) { return $command.Source }

  foreach ($candidate in $Fallbacks) {
    if (Test-Path $candidate) { return $candidate }
  }

  throw "Impossibile trovare $Name. Installa Windows SDK/Visual Studio e riprova."
}

function Get-PubspecVersion {
  $line = Select-String -Path "pubspec.yaml" -Pattern '^version:\s*([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)\s*$' | Select-Object -First 1
  if (-not $line) {
    throw "La versione in pubspec.yaml deve essere nel formato major.minor.patch+build."
  }
  return "$($line.Matches[0].Groups[1].Value).$($line.Matches[0].Groups[2].Value).$($line.Matches[0].Groups[3].Value).$($line.Matches[0].Groups[4].Value)"
}

if (-not $Version) { $Version = Get-PubspecVersion }
if ($Version -notmatch '^\d+\.\d+\.\d+\.\d+$') {
  throw "Version deve avere quattro componenti numeriche, per esempio 1.3.2.8."
}

if (-not (Test-Path "pubspec.yaml")) {
  throw "Esegui lo script dalla radice della repository."
}

$buildDirectory = Resolve-Path "."
$releaseDirectory = Join-Path $buildDirectory "build\windows\x64\runner\Release"
$templatePath = Join-Path $buildDirectory "packaging\msix\Package.Store.appxmanifest.template.xml"
$assetsSource = Join-Path $buildDirectory "packaging\msix\Assets"
$stageDirectory = Join-Path $buildDirectory "build\msix_store_stage"
$outputPath = Join-Path $buildDirectory $OutputDirectory

if (-not $SkipChecks) {
  flutter pub get
  flutter analyze
  flutter test test/data_integrity_test.dart
  flutter test
}

flutter build windows --release

if (-not (Test-Path (Join-Path $releaseDirectory "Pokedex5eITA.exe"))) {
  throw "Build Windows non trovata in $releaseDirectory."
}
if (-not (Test-Path $templatePath)) {
  throw "Manifest template non trovato: $templatePath"
}
if (-not (Test-Path $assetsSource)) {
  throw "Asset MSIX non trovati: $assetsSource"
}

Remove-Item $stageDirectory -Recurse -Force -ErrorAction SilentlyContinue
New-Item $stageDirectory -ItemType Directory -Force | Out-Null
Copy-Item (Join-Path $releaseDirectory "*") $stageDirectory -Recurse -Force
Copy-Item $assetsSource (Join-Path $stageDirectory "Assets") -Recurse -Force

$manifest = Get-Content $templatePath -Raw
$manifest = $manifest.Replace("STORE_IDENTITY_NAME", $IdentityName)
$manifest = $manifest.Replace("STORE_PUBLISHER_DISPLAY_NAME", $PublisherDisplayName)
$manifest = $manifest.Replace("STORE_PUBLISHER", $Publisher)
$manifest = $manifest.Replace("STORE_VERSION", $Version)
Set-Content -Path (Join-Path $stageDirectory "AppxManifest.xml") -Value $manifest -Encoding utf8

$makeAppx = Resolve-Executable "makeappx.exe" @(
  "${env:ProgramFiles(x86)}\Windows Kits\10\bin\10.0.26100.0\x64\makeappx.exe",
  "${env:ProgramFiles(x86)}\Windows Kits\10\bin\10.0.22621.0\x64\makeappx.exe",
  "${env:ProgramFiles(x86)}\Windows Kits\10\bin\x64\makeappx.exe"
)

New-Item $outputPath -ItemType Directory -Force | Out-Null
$packageName = "TrainerAtlas5e-$Version-x64.msix"
$packagePath = Join-Path $outputPath $packageName
Remove-Item $packagePath -Force -ErrorAction SilentlyContinue

& $makeAppx pack /d $stageDirectory /p $packagePath /o
if ($LASTEXITCODE -ne 0) { throw "makeappx ha restituito il codice $LASTEXITCODE." }

$hash = Get-FileHash $packagePath -Algorithm SHA256
"$($hash.Hash.ToLowerInvariant())  $packageName" | Set-Content "$packagePath.sha256" -Encoding ascii

Write-Host ""
Write-Host "Pacchetto creato: $packagePath"
Write-Host "SHA-256: $($hash.Hash)"
Write-Host "Il pacchetto usa l'identità del Partner Center ed è destinato al caricamento nello Store."

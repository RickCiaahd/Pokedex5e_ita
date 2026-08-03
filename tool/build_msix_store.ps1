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

function Invoke-Checked {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Description,

    [Parameter(Mandatory = $true)]
    [scriptblock]$Command
  )

  & $Command
  $exitCode = $LASTEXITCODE
  if ($null -ne $exitCode -and $exitCode -ne 0) {
    throw "$Description non riuscito (codice $exitCode)."
  }
}

function Resolve-MakeAppx {
  $command = Get-Command "makeappx.exe" -ErrorAction SilentlyContinue
  if ($command) { return $command.Source }

  $kitsRoot = Join-Path ${env:ProgramFiles(x86)} "Windows Kits\10"
  $binRoot = Join-Path $kitsRoot "bin"

  if (Test-Path $binRoot) {
    $candidates = Get-ChildItem -Path $binRoot -Filter "makeappx.exe" -File -Recurse -ErrorAction SilentlyContinue |
      Where-Object { $_.FullName -match '\\x64\\makeappx\.exe$' } |
      Sort-Object -Property @{
        Expression = {
          $versionDirectory = Split-Path (Split-Path $_.DirectoryName -Parent) -Leaf
          try { [version]$versionDirectory } catch { [version]"0.0.0.0" }
        }
        Descending = $true
      }

    $candidate = $candidates | Select-Object -First 1
    if ($candidate) { return $candidate.FullName }
  }

  $certificationKitCandidate = Join-Path $kitsRoot "App Certification Kit\makeappx.exe"
  if (Test-Path $certificationKitCandidate) {
    return $certificationKitCandidate
  }

  throw "Impossibile trovare makeappx.exe. Apri Visual Studio Installer, modifica l'installazione e aggiungi un Windows 10/11 SDK; quindi verifica che il file esista sotto 'C:\Program Files (x86)\Windows Kits\10\bin\<versione>\x64'."
}

function Assert-WindowsToolchain {
  $doctorLines = & flutter doctor -v 2>&1
  $exitCode = $LASTEXITCODE
  $doctorLines | ForEach-Object { Write-Host $_ }

  if ($null -ne $exitCode -and $exitCode -ne 0) {
    throw "flutter doctor non riuscito (codice $exitCode)."
  }

  $doctorText = $doctorLines -join "`n"
  if (
    $doctorText -match 'Unable to find suitable Visual Studio toolchain' -or
    $doctorText -match '(?m)^\[[X!]\]\s+Visual Studio - develop Windows apps'
  ) {
    throw "Toolchain Windows incompleta. Installa o modifica Visual Studio 2022 aggiungendo il workload 'Sviluppo di applicazioni desktop con C++', CMake e un Windows SDK, quindi riapri il terminale e verifica con 'flutter doctor -v'."
  }
}

function Get-PubspecVersion {
  $line = Select-String -Path "pubspec.yaml" -Pattern '^version:\s*([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)\s*$' | Select-Object -First 1
  if (-not $line) {
    throw "La versione in pubspec.yaml deve essere nel formato major.minor.patch+build."
  }
  return "$($line.Matches[0].Groups[1].Value).$($line.Matches[0].Groups[2].Value).$($line.Matches[0].Groups[3].Value).$($line.Matches[0].Groups[4].Value)"
}

if (-not (Test-Path "pubspec.yaml")) {
  throw "Esegui lo script dalla radice della repository."
}

if (-not $Version) { $Version = Get-PubspecVersion }
if ($Version -notmatch '^\d+\.\d+\.\d+\.\d+$') {
  throw "Version deve avere quattro componenti numeriche, per esempio 1.3.2.8."
}

$buildDirectory = Resolve-Path "."
$releaseDirectory = Join-Path $buildDirectory "build\windows\x64\runner\Release"
$templatePath = Join-Path $buildDirectory "packaging\msix\Package.Store.appxmanifest.template.xml"
$assetsSource = Join-Path $buildDirectory "packaging\msix\Assets"
$stageDirectory = Join-Path $buildDirectory "build\msix_store_stage"
$outputPath = Join-Path $buildDirectory $OutputDirectory
$makeAppx = Resolve-MakeAppx

Write-Host "MakeAppx rilevato: $makeAppx"

Invoke-Checked "Abilitazione del desktop Windows" { flutter config --enable-windows-desktop }
Invoke-Checked "Preparazione degli asset legali GPL e NOTICE" { python tooling/prepare_release_legal_assets.py }

if (-not $SkipChecks) {
  Invoke-Checked "Risoluzione delle dipendenze Flutter" { flutter pub get }
  Invoke-Checked "Analisi Flutter" { flutter analyze }
  Invoke-Checked "Test di integrità dei dati" { flutter test test/data_integrity_test.dart }
  Invoke-Checked "Suite completa dei test" { flutter test }
}

Assert-WindowsToolchain
Invoke-Checked "Build Windows release" { flutter build windows --release }

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

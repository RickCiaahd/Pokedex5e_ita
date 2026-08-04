[CmdletBinding()]
param(
    [string]$DestinationRoot,
    [switch]$Overwrite
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($DestinationRoot)) {
    $repositoryRoot = Split-Path -Parent $PSScriptRoot
    $DestinationRoot = Join-Path $repositoryRoot 'assets\textures\textures_webapp\pokemon'
}

$sourceCommit = '5841d46f1a0d2b8918a29a7376b1424878b86b59'
$sourceRoot = "https://raw.githubusercontent.com/PokeAPI/sprites/$sourceCommit/sprites/pokemon"
$types = @(
    'bug',
    'dark',
    'dragon',
    'electric',
    'fairy',
    'fighting',
    'fire',
    'flying',
    'ghost',
    'grass',
    'ground',
    'ice',
    'poison',
    'psychic',
    'rock',
    'steel',
    'water'
)
$species = @(
    @{ Name = 'arceus'; Number = 493 },
    @{ Name = 'silvally'; Number = 773 }
)

$downloaded = 0
$skipped = 0

foreach ($pokemon in $species) {
    $targetDirectory = Join-Path $DestinationRoot $pokemon.Name
    New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null

    foreach ($type in $types) {
        $sourceStem = "$($pokemon.Number)-$type.png"
        $files = @(
            @{
                Name = "main-$type.png"
                Url = "$sourceRoot/other/home/$sourceStem"
            },
            @{
                Name = "main-$type-shiny.png"
                Url = "$sourceRoot/other/home/shiny/$sourceStem"
            },
            @{
                Name = "sprite-$type.png"
                Url = "$sourceRoot/$sourceStem"
            },
            @{
                Name = "sprite-$type-shiny.png"
                Url = "$sourceRoot/shiny/$sourceStem"
            }
        )

        foreach ($file in $files) {
            $targetPath = Join-Path $targetDirectory $file.Name
            if ((Test-Path $targetPath) -and -not $Overwrite) {
                Write-Host "Già presente: $targetPath"
                $skipped++
                continue
            }

            Write-Host "Scarico $($file.Url)"
            Invoke-WebRequest -Uri $file.Url -OutFile $targetPath
            $downloaded++
        }
    }
}

Write-Host "Completato. File scaricati: $downloaded. File già presenti: $skipped."
Write-Host 'Controlla visivamente gli asset e i relativi diritti prima di distribuirli.'

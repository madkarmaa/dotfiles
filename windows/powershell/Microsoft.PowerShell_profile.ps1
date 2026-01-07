Clear-Host

function touch {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    if (Test-Path $Path) {
        (Get-Item $Path).LastWriteTime = Get-Date
    } else {
        New-Item -ItemType File -Force -Path $Path | Out-Null
    }
}

function prompt {
    $currentDir = $(Get-Location).Path
    $currentDir = $currentDir.ToLower() -replace '^([a-z]):', '/$1' -replace '\\', '/'

    Write-Host $currentDir -ForegroundColor Magenta
    Write-Host "> " -NoNewline -ForegroundColor Magenta
}

fastfetch
Write-Host
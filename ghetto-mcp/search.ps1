# PowerShell version of search script
# Usage: .\search.ps1 "search term"

param(
    [Parameter(Mandatory=$true)]
    [string]$Query
)

$JACKETT_URL = $env:JACKETT_URL
$JACKETT_API = $env:JACKETT_API
$RESULTS_FILE = "magnets.txt"

Write-Host "Searching for: $Query" -ForegroundColor Blue

# Simple URL encoding without System.Web
$EncodedQuery = $Query -replace ' ', '%20' -replace '&', '%26' -replace '#', '%23'

# Search Jackett
$SearchUrl = "${JACKETT_URL}?apikey=${JACKETT_API}&t=search&q=${EncodedQuery}"

try {
    $Results = Invoke-WebRequest -Uri $SearchUrl -UseBasicParsing
    $XmlContent = $Results.Content
} catch {
    Write-Host "Error searching Jackett: $_" -ForegroundColor Red
    exit 1
}

# Clear previous results
Clear-Content -Path $RESULTS_FILE -ErrorAction SilentlyContinue

# Collect all items
$AllItems = @()
$Lines = $XmlContent -split "`n"
$CurrentItem = @{}

foreach ($Line in $Lines) {
    if ($Line -match "<item>") {
        $CurrentItem = @{
            Title = ""
            Magnet = ""
            Size = ""
            SizeBytes = 0
            Seeders = 0
            Peers = 0
        }
    }
    elseif ($Line -match "<title><!\[CDATA\[(.*?)\]\]></title>") {
        $CurrentItem.Title = $Matches[1]
    }
    elseif ($Line -match "<title>(.*?)</title>") {
        $CurrentItem.Title = $Matches[1]
    }
    elseif ($Line -match "<link>(.*?)</link>") {
        $CurrentItem.Magnet = $Matches[1]
    }
    elseif ($Line -match "<size>(\d+)</size>") {
        $SizeBytes = [long]$Matches[1]
        $CurrentItem.SizeBytes = $SizeBytes
        if ($SizeBytes -gt 0) {
            $SizeGB = [math]::Round($SizeBytes / 1GB, 1)
            $SizeMB = [math]::Round($SizeBytes / 1MB, 0)
            if ($SizeGB -gt 1) {
                $CurrentItem.Size = "${SizeGB}GB"
            } else {
                $CurrentItem.Size = "${SizeMB}MB"
            }
        }
    }
    elseif ($Line -match 'name="seeders".*?value="(\d+)"') {
        $CurrentItem.Seeders = [int]$Matches[1]
    }
    elseif ($Line -match 'name="peers".*?value="(\d+)"') {
        $CurrentItem.Peers = [int]$Matches[1]
    }
    elseif ($Line -match "</item>" -and $CurrentItem.Title -and $CurrentItem.Magnet) {
        $AllItems += [PSCustomObject]$CurrentItem
    }
}

if ($AllItems.Count -eq 0) {
    Write-Host "No results found" -ForegroundColor Red
    Remove-Item -Path $RESULTS_FILE -ErrorAction SilentlyContinue
} else {
    # Sort by seeders descending
    $Sorted = $AllItems | Sort-Object -Property Seeders -Descending

    # Only show top 12 unless -All flag is set
    $ShowAll = $false
    if ($args.Count -gt 0 -and $args[0] -eq "-All") {
        $ShowAll = $true
    }
    $DisplayList = if ($ShowAll) { $Sorted } else { $Sorted | Select-Object -First 12 }

    # Output terse results
    $Counter = 1
    foreach ($Item in $DisplayList) {
        $SizeInfo = if ($Item.Size) { $Item.Size } else { "?" }
        $SeedInfo = if ($Item.Seeders -ne $null) { $Item.Seeders } else { "?" }
        $PeerInfo = if ($Item.Peers -ne $null) { $Item.Peers } else { "?" }
        Write-Host ("{0,2}. {1} [{2} | S:{3} P:{4}]" -f $Counter, $Item.Title, $SizeInfo, $SeedInfo, $PeerInfo) -ForegroundColor Yellow
        Add-Content -Path $RESULTS_FILE -Value $Item.Magnet
        $Counter++
    }

    if (-not $ShowAll -and $Sorted.Count -gt 12) {
        Write-Host ("...({0} more results, use -All to show all)" -f ($Sorted.Count - 12)) -ForegroundColor Cyan
    }

    # Find best under 1.5GB
    $BestSmall = $Sorted | Where-Object { $_.SizeBytes -le 1.5GB } | Sort-Object -Property Seeders -Descending | Select-Object -First 1
    if ($BestSmall) {
        $BestNum = 1 + ($DisplayList | ForEach-Object {$_.Title + $_.Size}).IndexOf($BestSmall.Title + $BestSmall.Size)
        Write-Host ("Best under 1.5GB: #$BestNum $($BestSmall.Title) [$($BestSmall.Size) | S:$($BestSmall.Seeders) P:$($BestSmall.Peers)]") -ForegroundColor Green
    }
    Write-Host "Magnets: $RESULTS_FILE" -ForegroundColor Cyan
    Write-Host "Run '.\add.ps1 [numbers]' to add torrents to Deluge" -ForegroundColor Cyan
}
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$LineNumbers
)

if (-not (Test-Path "magnets.txt")) {
    Write-Host "Error: magnets.txt not found. Run search.ps1 first." -ForegroundColor Red
    exit 1
}

$Content = Get-Content "magnets.txt"
if ($Content.Length -eq 0) {
    Write-Host "Error: magnets.txt is empty" -ForegroundColor Red
    exit 1
}


function Connect-ToDeluge {
    Write-Host "Connecting to Deluge..." -ForegroundColor Blue
    
    try {
        $loginBody = @{
            method = "auth.login"
            params = @("")
            id = 1
        } | ConvertTo-Json -Depth 3

        $loginResponse = Invoke-RestMethod -Uri "http://192.168.0.61:8112/json" -Method Post -Body $loginBody -ContentType "application/json" -SessionVariable session

        if ($loginResponse.result -eq $true) {
            Write-Host "[OK] Authenticated with Deluge" -ForegroundColor Green
            return $session
        } else {
            Write-Host "[FAIL] Failed to authenticate with Deluge" -ForegroundColor Red
            Write-Host "Login response: $($loginResponse | ConvertTo-Json)" -ForegroundColor Yellow
            return $null
        }
    } catch {
        Write-Host "[ERROR] Error connecting to Deluge: $_" -ForegroundColor Red
        return $null
    }
}

function Add-ToDeluge {
    param(
        [string]$MagnetLink,
        [Microsoft.PowerShell.Commands.WebRequestSession]$Session
    )

    $CleanLink = $MagnetLink -replace '&amp;', '&'
    
    # Handle different link types
    if ($CleanLink.StartsWith("magnet:")) {
        Write-Host "Adding magnet: $CleanLink" -ForegroundColor Blue
        $method = "core.add_torrent_magnet"
        $params = @($CleanLink, @{})
    } elseif ($CleanLink.StartsWith("http")) {
        Write-Host "Following redirect to get magnet link..." -ForegroundColor Blue
        try {
            # Follow redirect to get the actual magnet link
            $Response = Invoke-WebRequest -Uri $CleanLink -UseBasicParsing -MaximumRedirection 0 -ErrorAction SilentlyContinue
            
            # Check if we got a redirect
            if ($Response.StatusCode -eq 302 -and $Response.Headers.Location) {
                $MagnetLink = $Response.Headers.Location
                if ($MagnetLink.StartsWith("magnet:")) {
                    # Write-Host "Found magnet link: $MagnetLink" -ForegroundColor Green
                    $method = "core.add_torrent_magnet"
                    $params = @($MagnetLink, @{})
                } else {
                    Write-Host "[ERROR] Redirect didn't lead to magnet link: $MagnetLink" -ForegroundColor Red
                    return $false
                }
            } else {
                Write-Host "[ERROR] No redirect found or unexpected response" -ForegroundColor Red
                return $false
            }
        } catch {
            Write-Host "[ERROR] Failed to follow redirect: $_" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "[SKIP] Unknown link type: $CleanLink" -ForegroundColor Yellow
        return $false
    }

    try {
        $addBody = @{
            method = $method
            params = $params
            id = 2
        } | ConvertTo-Json -Depth 3

        $Response = Invoke-RestMethod -Uri "http://192.168.0.61:8112/json" -Method Post -Body $addBody -ContentType "application/json" -WebSession $Session

        if ($Response.result -and -not $Response.error) {
            Write-Host "[SUCCESS] Added successfully (Hash: $($Response.result))" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[FAIL] Failed to add torrent" -ForegroundColor Red
            if ($Response.error) {
                Write-Host "Error: $($Response.error.message)" -ForegroundColor Yellow
            } else {
                Write-Host "Response: $($Response | ConvertTo-Json)" -ForegroundColor Yellow
            }
            return $false
        }
    } catch {
        Write-Host "[ERROR] Failed to add: $_" -ForegroundColor Red
        return $false
    }
}

$session = Connect-ToDeluge
if (-not $session) {
    Write-Host "Cannot proceed without Deluge connection" -ForegroundColor Red
    exit 1
}

$TotalLines = $Content.Length

if ($LineNumbers[0] -eq "all") {
    Write-Host "Adding all $TotalLines torrents..." -ForegroundColor Cyan
    foreach ($Magnet in $Content) {
        Add-ToDeluge $Magnet $session | Out-Null
    }
} else {
    foreach ($LineNum in $LineNumbers) {
        $Num = [int]$LineNum
        if ($Num -ge 1 -and $Num -le $TotalLines) {
            $Magnet = $Content[$Num - 1]
            Add-ToDeluge $Magnet $session | Out-Null
        } else {
            Write-Host "Invalid line number: $LineNum (valid range: 1-$TotalLines)" -ForegroundColor Red
        }
    }
}

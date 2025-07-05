# TMDb Movie Data Script
# General purpose movie search and discovery using The Movie Database API
# Usage: .\tmdb-movie-data.ps1 -Action search|popular|trending|top_rated|upcoming [-Query "movie name"] [-Count 20]

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("search", "popular", "trending", "top_rated", "upcoming", "now_playing", "torrent_ready")]
    [string]$Action,
    
    [string]$Query = "",      # Search query for movies
    [int]$Count = 20,         # Number of results
    [switch]$AutoSearch,      # Automatically search torrents
    [switch]$JsonOutput,      # Output as JSON
    [int]$Year = 0,           # Filter by year (optional)
    [double]$MinRating = 6.0  # Minimum rating filter (default: 6.0)
)

# TMDb API Configuration
$API_KEY = $env:TMDB_API_KEY
$BASE_URL = "https://api.themoviedb.org/3"

function Get-TmdbData {
    param(
        [string]$Endpoint,
        [hashtable]$Parameters = @{}
    )
    
    try {
        # Build URL with parameters
        $Url = "$BASE_URL$Endpoint"
        $QueryParams = @("api_key=$API_KEY")
        
        foreach ($Key in $Parameters.Keys) {
            $QueryParams += "$Key=$($Parameters[$Key])"
        }
        
        if ($QueryParams.Count -gt 0) {
            $Url += "?" + ($QueryParams -join "&")
        }
        
        Write-Host "Fetching from TMDb API..." -ForegroundColor Blue
        $Response = Invoke-RestMethod -Uri $Url -Method Get -TimeoutSec 30
        return $Response
    }
    catch {
        Write-Host "Error fetching data: $_" -ForegroundColor Red
        return $null
    }
}

function Search-Movies {
    param([string]$Query, [int]$Count = 20, [int]$Year = 0)
    
    if (-not $Query) {
        Write-Host "Please provide a search query" -ForegroundColor Red
        return @()
    }
    
    Write-Host "=== Searching for '$Query' ===" -ForegroundColor Cyan
    Write-Host ""
    
    $Parameters = @{
        "query" = $Query
        "page" = "1"
    }
    
    if ($Year -gt 0) {
        $Parameters["year"] = $Year
    }
    
    $SearchResults = Get-TmdbData -Endpoint "/search/movie" -Parameters $Parameters
    
    if (-not $SearchResults -or -not $SearchResults.results) {
        Write-Host "No movies found for '$Query'" -ForegroundColor Yellow
        return @()
    }
    
    return $SearchResults.results | Select-Object -First $Count
}

function Get-PopularMovies {
    param([int]$Count = 20)
    
    Write-Host "=== Popular Movies ===" -ForegroundColor Cyan
    Write-Host ""
    
    $PopularMovies = Get-TmdbData -Endpoint "/movie/popular" -Parameters @{
        "page" = "1"
    }
    
    if ($PopularMovies -and $PopularMovies.results) {
        return $PopularMovies.results | Select-Object -First $Count
    }
    
    return @()
}

function Get-TrendingMovies {
    param([int]$Count = 20)
    
    Write-Host "=== Trending Movies (This Week) ===" -ForegroundColor Cyan
    Write-Host ""
    
    $TrendingMovies = Get-TmdbData -Endpoint "/trending/movie/week" -Parameters @{}
    
    if ($TrendingMovies -and $TrendingMovies.results) {
        return $TrendingMovies.results | Select-Object -First $Count
    }
    
    return @()
}

function Get-TopRatedMovies {
    param([int]$Count = 20)
    
    Write-Host "=== Top Rated Movies ===" -ForegroundColor Cyan
    Write-Host ""
    
    $TopRatedMovies = Get-TmdbData -Endpoint "/movie/top_rated" -Parameters @{
        "page" = "1"
    }
    
    if ($TopRatedMovies -and $TopRatedMovies.results) {
        return $TopRatedMovies.results | Select-Object -First $Count
    }
    
    return @()
}

function Get-UpcomingMovies {
    param([int]$Count = 20)
    
    Write-Host "=== Upcoming Movies ===" -ForegroundColor Cyan
    Write-Host ""
    
    $UpcomingMovies = Get-TmdbData -Endpoint "/movie/upcoming" -Parameters @{
        "page" = "1"
    }
    
    if ($UpcomingMovies -and $UpcomingMovies.results) {
        return $UpcomingMovies.results | Select-Object -First $Count
    }
    
    return @()
}

function Get-NowPlayingMovies {
    param([int]$Count = 20)
    
    Write-Host "=== Now Playing in Theaters ===" -ForegroundColor Cyan
    Write-Host ""
    
    $NowPlayingMovies = Get-TmdbData -Endpoint "/movie/now_playing" -Parameters @{
        "page" = "1"
    }
    
    if ($NowPlayingMovies -and $NowPlayingMovies.results) {
        return $NowPlayingMovies.results | Select-Object -First $Count
    }
    
    return @()
}

function Get-TorrentReadyMovies {
    param([int]$Count = 20, [double]$MinRating = 6.0)
    
    Write-Host "=== Movies Likely Available for Torrenting ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Calculate date ranges for movies likely to be available for torrenting
    $Today = Get-Date
    $MinReleaseDate = $Today.AddMonths(-8).ToString("yyyy-MM-dd")  # 8 months ago
    $MaxReleaseDate = $Today.AddMonths(-2).ToString("yyyy-MM-dd")  # 2 months ago
    
    Write-Host "Looking for movies released between $MinReleaseDate and $MaxReleaseDate" -ForegroundColor Gray
    Write-Host "(Movies typically become available for torrenting 2-6 months after theatrical release)" -ForegroundColor Gray
    Write-Host ""
    
    # Get popular movies and filter by release date
    $AllMovies = @()
    
    # Fetch multiple pages to get more results
    for ($Page = 1; $Page -le 3; $Page++) {
        $PopularMovies = Get-TmdbData -Endpoint "/movie/popular" -Parameters @{
            "page" = $Page
        }
        
        if ($PopularMovies -and $PopularMovies.results) {
            $AllMovies += $PopularMovies.results
        }
    }
    
    # Also get top rated movies from the same period
    for ($Page = 1; $Page -le 2; $Page++) {
        $TopRatedMovies = Get-TmdbData -Endpoint "/movie/top_rated" -Parameters @{
            "page" = $Page
        }
        
        if ($TopRatedMovies -and $TopRatedMovies.results) {
            $AllMovies += $TopRatedMovies.results
        }
    }
    
    # Filter movies by release date and other criteria
    $TorrentReadyMovies = $AllMovies | Where-Object {
        $_.release_date -and
        $_.release_date -ne "" -and
        [DateTime]$_.release_date -ge [DateTime]$MinReleaseDate -and
        [DateTime]$_.release_date -le [DateTime]$MaxReleaseDate -and
        $_.vote_count -gt 100 -and        # Has enough votes (popular enough)
        $_.vote_average -ge $MinRating    # User-specified minimum rating
    } | Sort-Object { [DateTime]$_.release_date } -Descending |
        Sort-Object title, release_date -Unique |  # Remove duplicates
        Select-Object -First $Count
    
    if ($TorrentReadyMovies.Count -eq 0) {
        Write-Host "No movies found in the optimal torrenting window." -ForegroundColor Yellow
        Write-Host "Try expanding the date range or checking 'popular' movies instead." -ForegroundColor Gray
        return @()
    }
    
    Write-Host "Found $($TorrentReadyMovies.Count) movies likely available for torrenting:" -ForegroundColor Green
    Write-Host ""
    
    return $TorrentReadyMovies
}

function Display-Movies {
    param($Movies)
    
    if (-not $Movies -or $Movies.Count -eq 0) {
        Write-Host "No movies found" -ForegroundColor Yellow
        return
    }
    
    foreach ($Movie in $Movies) {
        $ReleaseYear = if ($Movie.release_date) { 
            ([DateTime]$Movie.release_date).Year 
        } else { 
            "Unknown" 
        }
        
        Write-Host "$($Movie.title) ($ReleaseYear)" -ForegroundColor White
        Write-Host "  Release Date: $($Movie.release_date)" -ForegroundColor Gray
        Write-Host "  Rating: $($Movie.vote_average)/10 (from $($Movie.vote_count) votes)" -ForegroundColor Gray
        Write-Host "  Popularity Score: $($Movie.popularity)" -ForegroundColor Gray
        
        if ($Movie.overview) {
            $Overview = if ($Movie.overview.Length -gt 200) {
                $Movie.overview.Substring(0, 200) + "..."
            } else {
                $Movie.overview
            }
            Write-Host "  Overview: $Overview" -ForegroundColor Yellow
        }
        
        Write-Host ""
    }
    
    Write-Host "Found $($Movies.Count) movies" -ForegroundColor Green
}

function Auto-SearchTorrents {
    param($Movies)
    
    if (-not $Movies -or $Movies.Count -eq 0) {
        Write-Host "No movies provided for torrent search" -ForegroundColor Red
        return
    }
    
    Write-Host ""
    Write-Host "=== Auto-Searching Torrents ===" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($Movie in $Movies | Select-Object -First 5) {  # Limit to first 5 to avoid spam
        $ReleaseYear = if ($Movie.release_date) { 
            ([DateTime]$Movie.release_date).Year 
        } else { 
            "" 
        }
        
        $SearchTerm = if ($ReleaseYear) {
            "$($Movie.title) $ReleaseYear"
        } else {
            $Movie.title
        }
        
        Write-Host "Searching torrents for: $SearchTerm" -ForegroundColor Blue
        
        # Call existing search script
        if (Test-Path ".\search.ps1") {
            & ".\search.ps1" $SearchTerm
            Write-Host ""
        } else {
            Write-Host "search.ps1 not found - cannot auto-search torrents" -ForegroundColor Red
            Write-Host "You can manually search for: $SearchTerm" -ForegroundColor Yellow
            break
        }
    }
}

function Show-Usage {
    Write-Host ""
    Write-Host "=== TMDb Movie Data Script ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "General purpose movie search using The Movie Database API" -ForegroundColor White
    Write-Host ""
    Write-Host "Usage Examples:" -ForegroundColor Yellow
    Write-Host "  .\tmdb-movie-data.ps1 -Action search -Query 'John Wick' -Count 10" -ForegroundColor Gray
    Write-Host "  .\tmdb-movie-data.ps1 -Action search -Query 'Marvel' -Year 2024" -ForegroundColor Gray
    Write-Host "  .\tmdb-movie-data.ps1 -Action popular -Count 15" -ForegroundColor Gray
    Write-Host "  .\tmdb-movie-data.ps1 -Action trending -AutoSearch" -ForegroundColor Gray
    Write-Host "  .\tmdb-movie-data.ps1 -Action top_rated -JsonOutput" -ForegroundColor Gray
    Write-Host "  .\tmdb-movie-data.ps1 -Action upcoming -Count 10" -ForegroundColor Gray
    Write-Host "  .\tmdb-movie-data.ps1 -Action now_playing" -ForegroundColor Gray
    Write-Host "  .\tmdb-movie-data.ps1 -Action torrent_ready -MinRating 7.0 -AutoSearch" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Actions:" -ForegroundColor Yellow
    Write-Host "  search       - Search for specific movies by title" -ForegroundColor Gray
    Write-Host "  popular      - Get currently popular movies" -ForegroundColor Gray
    Write-Host "  trending     - Get trending movies this week" -ForegroundColor Gray
    Write-Host "  top_rated    - Get highest rated movies" -ForegroundColor Gray
    Write-Host "  upcoming     - Get upcoming movie releases" -ForegroundColor Gray
    Write-Host "  now_playing  - Get movies currently in theaters" -ForegroundColor Gray
    Write-Host "  torrent_ready - Get movies likely available for torrenting (2-8 months old)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -Query      - Movie title to search for (required for search action)" -ForegroundColor Gray
    Write-Host "  -Count      - Number of results to return (default: 20)" -ForegroundColor Gray
    Write-Host "  -Year       - Filter search results by release year" -ForegroundColor Gray
    Write-Host "  -MinRating  - Minimum TMDb rating filter (default: 6.0)" -ForegroundColor Gray
    Write-Host "  -AutoSearch - Automatically search torrents for found movies" -ForegroundColor Gray
    Write-Host "  -JsonOutput - Save results as JSON file" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Data Source: The Movie Database (TMDb) API" -ForegroundColor Green
}

# Main execution
Write-Host "=== TMDb Movie Data Script ===" -ForegroundColor Cyan
Write-Host "Using The Movie Database API for real movie data" -ForegroundColor White
Write-Host ""

# Define action handlers
$ActionHandlers = @{
    "search" = { Search-Movies -Query $Query -Count $Count -Year $Year }
    "popular" = { Get-PopularMovies -Count $Count }
    "trending" = { Get-TrendingMovies -Count $Count }
    "top_rated" = { Get-TopRatedMovies -Count $Count }
    "upcoming" = { Get-UpcomingMovies -Count $Count }
    "now_playing" = { Get-NowPlayingMovies -Count $Count }
    "torrent_ready" = { Get-TorrentReadyMovies -Count $Count -MinRating $MinRating }
}

# Execute the selected action
$Results = $null
if ($ActionHandlers.ContainsKey($Action)) {
    $Results = & $ActionHandlers[$Action]
    Display-Movies $Results
    
    if ($AutoSearch -and $Results) {
        Auto-SearchTorrents $Results
    }
} else {
    Write-Host "Unknown action: $Action" -ForegroundColor Red
}

# Save results to JSON if requested
if ($JsonOutput -and $Results) {
    $OutputFile = "tmdb-results.json"
    $Results | ConvertTo-Json -Depth 10 | Set-Content $OutputFile
    Write-Host ""
    Write-Host "Results saved to $OutputFile" -ForegroundColor Green
}

# Show usage if no results
if (-not $Results) {
    Show-Usage
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
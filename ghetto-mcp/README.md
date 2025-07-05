# Jackett to Deluge Automation

Simple automation to search torrents via Jackett and add them to Deluge.

## Usage

### Fetch movie data from TMDb

```powershell
# Search for a movie by title
.\tmdb-movie-data.ps1 -Action search -Query "Movie Title"

# Get popular movies
.\tmdb-movie-data.ps1 -Action popular

# Get trending movies (optionally as JSON)
.\tmdb-movie-data.ps1 -Action trending -JsonOutput

# Additional options:
#   -Count <number>      # Number of results (default: 20)
#   -Year <year>         # Filter by year
#   -MinRating <rating>  # Minimum rating filter

# See script for all available actions: search, popular, trending, top_rated, upcoming, now_playing, torrent_ready
```
**Arguments:**
- `-Action` (required): One of `search`, `popular`, `trending`, `top_rated`, `upcoming`, `now_playing`, `torrent_ready`
- `-Query` (optional): Search string for movies (used with `search`)
- `-Count` (optional): Number of results to return (default: 20)
- `-Year`, `-MinRating`, `-AutoSearch`, `-JsonOutput` (optional): See script for details

This script fetches movie metadata from The Movie Database (TMDb) using your `TMDB_API_KEY` environment variable.

### Search for torrents
```powershell
.\search.ps1 "Movie Name"
```

### Add torrents to Deluge
```powershell
# Add single torrent
.\add.ps1 5

# Add multiple torrents  
.\add.ps1 1 3 7

# Add all torrents
.\add.ps1 all
```


## Configuration

This project now uses environment variables for sensitive configuration.

Set these in your PowerShell session (or user/system environment):

```powershell
$env:JACKETT_URL = "http://your-jackett-server:9117/api/v2.0/indexers/knaben/results/torznab/"
$env:JACKETT_API = "your-jackett-api-key"
$env:TMDB_API_KEY = "your-tmdb-api-key"
```

You can add these lines to your PowerShell profile for persistence.

- `search.ps1` uses `JACKETT_URL` and `JACKETT_API` from the environment.
- `tmdb-movie-data.ps1` uses `TMDB_API_KEY` from the environment.
- Edit the URL in `add.ps1` for your Deluge Web API endpoint (default: `http://192.168.0.61:8112/json`).

## Files

- `search.ps1` - Search Jackett and save results
- `add.ps1` - Add selected torrents to Deluge
- `tmdb-movie-data.ps1` - Fetches movie data from TMDb
- `magnets.txt` - Generated file with magnet links (transient, gitignored)

## Requirements

- PowerShell 5.0+
- Jackett running with API access
- Deluge with Web UI enabled

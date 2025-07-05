# Bulk Torrent Management Ideas

## Current State
- `search.ps1` - searches and saves results to magnets.txt
- `add.ps1` - adds individual torrents by number
- Works well but requires manual selection for each movie

## Proposed Enhancements

### 1. Intelligent Selection Algorithm

**Scoring System:**
- **Seeders/Peers Ratio** (40% weight) - Higher is better
- **File Size** (30% weight) - Prefer reasonable sizes (500MB-2GB range)
- **Quality Indicators** (20% weight) - 720p/1080p, BluRay > WEBRip > DVDRip
- **Release Group Reputation** (10% weight) - YIFY, UTR, QxR get bonus points

**Selection Logic:**
```
Score = (Seeders/10) + SizeScore + QualityScore + GroupScore
- SizeScore: 10 for 700MB-1.5GB, scaling down outside range
- QualityScore: 1080p=10, 720p=8, 480p=5, etc.
- GroupScore: Known good groups get +2 bonus
```

### 2. Review Modes

**Quick Review Mode:**
- Show top 3 candidates per movie with scores
- Simple Y/N/Skip prompt for each
- `.\queue.ps1 --review-quick movies.txt`

**Detailed Review Mode:**
- Show full search results with intelligent ranking
- Allow manual override of selections
- `.\queue.ps1 --review-detailed movies.txt`

**Auto Mode:**
- No review, just add best matches automatically
- `.\queue.ps1 --auto movies.txt --min-score 15`

### 3. Configuration System

**Config File (torrent-config.json):**
```json
{
  "preferences": {
    "maxSizeGB": 2.0,
    "minSeeders": 5,
    "preferredQuality": ["1080p", "720p"],
    "avoidKeywords": ["CAM", "TS", "HDCAM"],
    "trustedGroups": ["YIFY", "UTR", "QxR", "Joy"]
  },
  "scoring": {
    "seedersWeight": 0.4,
    "sizeWeight": 0.3,
    "qualityWeight": 0.2,
    "groupWeight": 0.1
  }
}
```

### 4. New Script Architecture

**queue.ps1 - Master Script:**
- Combines search, filter, score, review, and add
- Supports multiple input methods
- Handles batch operations

**Input Methods:**
1. **File-based:** `.\queue.ps1 --file movies.txt`
2. **Command-line:** `.\queue.ps1 "Spy Kids" "Tintin" "Dragon"`
3. **Interactive:** `.\queue.ps1 --interactive` (prompts for movies)
4. **Wishlist:** `.\queue.ps1 --wishlist` (reads from wishlist.txt)

### 5. Enhanced Features

**Smart Filtering:**
- Duplicate detection (same movie, different quality)
- Size-based filtering (avoid huge 4K files)
- Language filtering (English audio priority)
- Format preferences (x265 > x264 for size efficiency)

**Batch Operations:**
- `.\queue.ps1 --file movies.txt --auto --max-size 1GB`
- `.\queue.ps1 --wishlist --review-quick --min-seeders 10`
- `.\queue.ps1 "Movie Name" --show-options` (search only, no add)

**Progress Tracking:**
- Show download progress summary
- Track which movies from wishlist are found/added
- Generate reports of successful/failed searches

### 6. User Experience Improvements

**Review Interface:**
```
Movie: Spy Kids (2001)
Top Candidates:
[1] ⭐ Spy Kids (2001) 720p BrRip x264 YIFY [651MB | S:46 P:61] Score: 18.5
[2]    Spy Kids (2001) 1080p BrRip x264 YIFY [1.3GB | S:24 P:29] Score: 16.2
[3]    Spy Kids 2001 1080p BluRay DD+ 5.1 x265 [2.5GB | S:18 P:21] Score: 14.8

Add option [1]? (Y/n/2/3/skip): 
```

**Summary Reports:**
- Total size of queued downloads
- Estimated download time based on seeders
- Success rate of searches
- Storage space impact

### 7. Advanced Features (Future)

**Machine Learning:**
- Learn from user selections to improve scoring
- Adapt preferences based on what gets downloaded vs skipped

**Integration:**
- Check existing collection to avoid duplicates
- Integration with Plex/Jellyfin to verify what's already available
- TMDB/IMDB integration for better movie matching

**Scheduling:**
- Periodic wishlist processing
- Bandwidth-aware queuing (add more during off-peak hours)

## Implementation Priority

1. **Phase 1:** Basic intelligent selection + quick review mode
2. **Phase 2:** Configuration system + detailed review
3. **Phase 3:** Advanced filtering + batch operations
4. **Phase 4:** Progress tracking + reporting
5. **Phase 5:** ML and external integrations

## Example Workflows

**Daily Wishlist Check:**
```bash
.\queue.ps1 --wishlist --auto --max-total-size 5GB --min-score 15
```

**Manual Movie Night Planning:**
```bash
.\queue.ps1 --interactive --review-detailed --max-size 1.5GB
```

**Bulk Collection Building:**
```bash
.\queue.ps1 --file "kids-movies-2000s.txt" --review-quick --prefer-quality 720p
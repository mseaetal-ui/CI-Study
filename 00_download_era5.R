# =============================================================================
# download_era5.R — ERA5 wind data download via ecmwfr
# =============================================================================
# Downloads ERA5 U and V wind components at 225, 250, 300 hPa
# for January, March, June, November 2023
#
# BEFORE RUNNING:
#   1. Register at https://cds.climate.copernicus.eu
#   2. Get your UID and API key from your CDS profile
#   3. Set YOUR_CDS_UID and YOUR_CDS_KEY below
#   4. Set DATA_PATH to your desired output directory
#
# Files are ~15 MB each. Download takes 5-15 minutes per file.
# =============================================================================

library(ecmwfr)

# ── USER CONFIGURATION ────────────────────────────────────────────────────────
YOUR_CDS_UID <- "YOUR_CDS_UID_HERE"   # from https://cds.climate.copernicus.eu
YOUR_CDS_KEY <- "YOUR_CDS_KEY_HERE"   # from your CDS profile page
DATA_PATH    <- "data/raw"            # output directory
# ─────────────────────────────────────────────────────────────────────────────

dir.create(DATA_PATH, showWarnings = FALSE, recursive = TRUE)

# Store credentials
wf_set_key(user   = YOUR_CDS_UID,
           key    = YOUR_CDS_KEY,
           service = "cds")

# Geographic bounding box covering all five corridors
# North: 62°N (covers C5 Scandinavia)
# South: 34°N (covers C4 Iberia)
# West:  22°W (covers C3 North Atlantic)
# East:  22°E (covers C2 Central Europe)
AREA <- c(62, -22, 34, 22)  # N, W, S, E

# Time steps: 06:00, 08:00, 10:00, 12:00 UTC
# 10:00 UTC is the primary analysis hour (maps exactly in ERA5)
TIMES <- c("06:00", "08:00", "10:00", "12:00")

download_era5_month <- function(year, month, outfile) {
  days <- format(seq(as.Date(paste(year, month, "01", sep="-")),
                     as.Date(paste(year, month,
                                   lubridate::days_in_month(
                                     as.Date(paste(year, month, "01",
                                                   sep="-"))),
                                   sep="-")),
                     by = "day"), "%d")

  request <- list(
    dataset_short_name = "reanalysis-era5-pressure-levels",
    product_type       = "reanalysis",
    variable           = c("u_component_of_wind",
                            "v_component_of_wind"),
    pressure_level     = c("225", "250", "300"),
    year               = as.character(year),
    month              = sprintf("%02d", month),
    day                = days,
    time               = TIMES,
    area               = AREA,
    format             = "netcdf",
    target             = outfile
  )

  cat("Downloading:", outfile, "...\n")
  wf_request(
    user     = YOUR_CDS_UID,
    request  = request,
    transfer = TRUE,
    path     = DATA_PATH
  )
  cat("Done:", outfile, "\n")
}

# Download all four months
download_era5_month(2023,  1, "era5_wind_jan2023.nc")
download_era5_month(2023,  3, "era5_wind_mar2023.nc")
download_era5_month(2023,  6, "era5_wind_jun2023.nc")
download_era5_month(2023, 11, "era5_wind_nov2023.nc")

cat("\nAll ERA5 files downloaded to:", DATA_PATH, "\n")

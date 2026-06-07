# =============================================================================
# 01_load_and_wind_correct.R
# =============================================================================
# Study: Wind-corrected cruise-speed variation in European aviation
# Author: Joan Tarradellas, EADA Business School
#
# This script:
#   1. Loads all corridor CSVs extracted from OpenSky Trino
#   2. Applies ERA5 wind correction at 250 hPa, 10:00 UTC
#   3. Computes TAS = GS - W_parallel
#   4. Applies TAS filter and daily outlier removal
#   5. Computes P10 benchmark and CO2 penalty
#   6. Saves workspace
#
# BEFORE RUNNING:
#   - Place all *_utf8.csv files in DATA_PATH
#   - Place all era5_wind_*.nc files in DATA_PATH
#   - Set DATA_PATH and OUTPUT_PATH below
# =============================================================================

library(tidyverse)
library(ncdf4)

# ── USER CONFIGURATION ────────────────────────────────────────────────────────
DATA_PATH   <- "data/raw"        # directory containing CSV and .nc files
OUTPUT_PATH <- "data/processed"  # directory for saved workspace
# ─────────────────────────────────────────────────────────────────────────────

dir.create(OUTPUT_PATH, showWarnings = FALSE, recursive = TRUE)

# =============================================================================
# STEP 1: LOAD ERA5 FILES
# =============================================================================
# ERA5 files contain U and V wind components at 225, 250, 300 hPa
# 4 time steps per day: 06:00, 08:00, 10:00, 12:00 UTC
# 10:00 UTC is used as representative of the main European operating window

load_era5 <- function(filepath) {
  nc     <- nc_open(filepath)
  lons   <- ncvar_get(nc, "longitude")
  lats   <- ncvar_get(nc, "latitude")
  levels <- ncvar_get(nc, "pressure_level")
  times  <- ncvar_get(nc, "valid_time")
  U      <- ncvar_get(nc, "u")
  V      <- ncvar_get(nc, "v")
  nc_close(nc)
  list(lons=lons, lats=lats, levels=levels,
       times=times, U=U, V=V)
}

cat("Loading ERA5 files...\n")
era5_jan <- load_era5(file.path(DATA_PATH, "era5_wind_jan2023.nc"))
era5_mar <- load_era5(file.path(DATA_PATH, "era5_wind_mar2023.nc"))
era5_jun <- load_era5(file.path(DATA_PATH, "era5_wind_jun2023.nc"))
era5_nov <- load_era5(file.path(DATA_PATH, "era5_wind_nov2023.nc"))
cat("ERA5 loaded. Time steps per month:", length(era5_jan$times), "\n")
cat("Pressure levels:", paste(era5_jan$levels, collapse=", "), "\n")

# =============================================================================
# STEP 2: WIND LOOKUP FUNCTION
# =============================================================================
# For each flight, extract U and V at 250 hPa, nearest grid point, 10:00 UTC
# Along-track wind component: W_parallel = U*sin(theta) + V*cos(theta)
# where theta = mean ADS-B track heading
# Positive W_parallel = tailwind; negative = headwind
# TAS = GS - W_parallel

get_wind_10am <- function(era5, lat, lon, flight_date) {
  target_epoch <- as.numeric(
    as.POSIXct(paste(flight_date, "10:00:00"), tz="UTC"))
  i_lon   <- which.min(abs(era5$lons - lon))
  i_lat   <- which.min(abs(era5$lats - lat))
  i_level <- which.min(abs(era5$levels - 250))   # 250 hPa ~ FL340
  i_time  <- which.min(abs(era5$times - target_epoch))
  u <- era5$U[i_lon, i_lat, i_level, i_time] * 1.94384  # m/s to kts
  v <- era5$V[i_lon, i_lat, i_level, i_time] * 1.94384
  c(u=u, v=v)
}

apply_wind_correction <- function(df, era5_obj) {
  cat("Applying wind correction to", nrow(df), "flights...\n")
  result <- mapply(
    function(lat, lon, date) {
      tryCatch(
        get_wind_10am(era5_obj, lat, lon, date),
        error = function(e) c(u=NA_real_, v=NA_real_)
      )
    },
    df$avg_lat,
    df$avg_lon,
    as.character(df$flight_date)
  )
  df |> mutate(
    era5_u_kts   = result["u", ],
    era5_v_kts   = result["v", ],
    # Along-track wind component W_parallel
    headwind_kts = era5_u_kts * sin(track_deg * pi/180) +
                   era5_v_kts * cos(track_deg * pi/180),
    # TAS = GS - W_parallel
    tas_kts      = groundspeed_kts - headwind_kts
  )
}

# =============================================================================
# STEP 3: LOAD CORRIDOR CSVs
# =============================================================================

airline_map <- tribble(
  ~prefix, ~airline,
  "AFR", "Air France",
  "BAW", "British Airways",
  "DLH", "Lufthansa",
  "EZY", "easyJet",
  "IBE", "Iberia",
  "IBS", "Iberia Express",
  "VLG", "Vueling",
  "EWG", "Eurowings",
  "AUA", "Austrian",
  "KLM", "KLM",
  "RYR", "Ryanair",
  "TAP", "TAP Portugal",
  "SAS", "SAS",
  "NAX", "Norwegian",
  "NOZ", "Norwegian",
  "FIN", "Finnair",
  "WZZ", "Wizz Air",
  "VIR", "Virgin Atlantic",
  "ACA", "Air Canada",
  "SWR", "Swiss"
)

read_corridor <- function(file, corridor, month) {
  read_csv(file.path(DATA_PATH, file),
           show_col_types = FALSE) |>
    mutate(
      corridor_code = corridor,
      month_code    = factor(month,
                             levels = c("Jan","Mar","Jun","Nov"))
    )
}

cat("Loading corridor CSVs...\n")
flights_raw <- bind_rows(
  read_corridor("C1_jan2023_utf8.csv", "C1", "Jan"),
  read_corridor("C1_mar2023_utf8.csv", "C1", "Mar"),
  read_corridor("C1_jun2023_utf8.csv", "C1", "Jun"),
  read_corridor("C1_nov2023_utf8.csv", "C1", "Nov"),
  read_corridor("C2_jan2023_utf8.csv", "C2", "Jan"),
  read_corridor("C2_mar2023_utf8.csv", "C2", "Mar"),
  read_corridor("C2_jun2023_utf8.csv", "C2", "Jun"),
  read_corridor("C2_nov2023_utf8.csv", "C2", "Nov"),
  read_corridor("C3_mar2023_utf8.csv", "C3", "Mar"),
  read_corridor("C4_jan2023_utf8.csv", "C4", "Jan"),
  read_corridor("C4_mar2023_utf8.csv", "C4", "Mar"),
  read_corridor("C4_jun2023_utf8.csv", "C4", "Jun"),
  read_corridor("C4_nov2023_utf8.csv", "C4", "Nov"),
  read_corridor("C5_jan2023_utf8.csv", "C5", "Jan"),
  read_corridor("C5_mar2023_utf8.csv", "C5", "Mar"),
  read_corridor("C5_jun2023_utf8.csv", "C5", "Jun"),
  read_corridor("C5_nov2023_utf8.csv", "C5", "Nov")
) |>
  mutate(airline_prefix = substr(callsign, 1, 3)) |>
  left_join(airline_map, by = c("airline_prefix" = "prefix")) |>
  mutate(airline = ifelse(is.na(airline), airline_prefix, airline))

cat("Raw flights loaded:", nrow(flights_raw), "\n")

# =============================================================================
# STEP 4: APPLY ERA5 WIND CORRECTION BY MONTH
# =============================================================================

cat("\nApplying ERA5 wind correction by month...\n")
f_jan <- apply_wind_correction(
  filter(flights_raw, month_code == "Jan"), era5_jan)
f_mar <- apply_wind_correction(
  filter(flights_raw, month_code == "Mar"), era5_mar)
f_jun <- apply_wind_correction(
  filter(flights_raw, month_code == "Jun"), era5_jun)
f_nov <- apply_wind_correction(
  filter(flights_raw, month_code == "Nov"), era5_nov)

# =============================================================================
# STEP 5: COMBINE, TAS FILTER, DAILY OUTLIER REMOVAL
# =============================================================================
# TAS filter: 380-530 kts removes non-jet aircraft and extreme values
# Outlier removal: ±3 SD of ground speed per corridor-day

flights_2023_full <- bind_rows(f_jan, f_mar, f_jun, f_nov) |>
  filter(
    !is.na(tas_kts),
    tas_kts >= 380,
    tas_kts <= 530
  ) |>
  group_by(corridor_code, month_code, flight_date) |>
  mutate(
    daily_mean_gs = mean(groundspeed_kts, na.rm = TRUE),
    daily_sd_gs   = sd(groundspeed_kts,   na.rm = TRUE)
  ) |>
  filter(abs(groundspeed_kts - daily_mean_gs) <= 3 * daily_sd_gs) |>
  ungroup()

cat("\nAfter TAS filter and outlier removal:",
    nrow(flights_2023_full), "\n")
cat("TAS range:", round(range(flights_2023_full$tas_kts)), "\n")

# =============================================================================
# STEP 6: PRIMARY AND CONTROL CORRIDORS
# =============================================================================

# Primary corridors: C1, C2, C4, C5 (radar-controlled European airspace)
# Control corridor:  C3 (North Atlantic — procedural Mach assignment)
primary_2023 <- flights_2023_full |>
  filter(corridor_code %in% c("C1","C2","C4","C5"))

control_2023 <- flights_2023_full |>
  filter(corridor_code == "C3")

cat("Primary flights:", nrow(primary_2023), "\n")
cat("Control flights:", nrow(control_2023), "\n")

# =============================================================================
# STEP 7: P10 BENCHMARK AND CO2 PENALTY
# =============================================================================
# P10 = daily 10th percentile TAS within each corridor-day
# Used as empirical lower-speed frontier
#
# CO2 penalty calculation:
#   base_fuel_kg = 3,200 kg (A320-family mean fuel load)
#   co2_factor   = 3.16 (CO2 per kg jet fuel, IPCC)
#   0.3% fuel burn per CI unit per 10 kts TAS (BADA approximation)
#   0.36 kts TAS per CI unit (BADA A320 at FL350)

primary_2023 <- primary_2023 |>
  group_by(corridor_code, month_code, flight_date) |>
  mutate(p10_tas = quantile(tas_kts, 0.10, na.rm = TRUE)) |>
  ungroup() |>
  mutate(
    ci_above_p10    = pmax(0, (tas_kts - p10_tas) / 0.36),
    implied_CI_p10  = (tas_kts - p10_tas) / 0.36,
    base_fuel_kg    = 3200,
    co2_factor      = 3.16,
    fuel_pen_p10_kg = base_fuel_kg * 0.003 * ci_above_p10 / 10,
    co2_pen_p10_kg  = fuel_pen_p10_kg * co2_factor
  )

cat("\nMean CO2 penalty above P10:",
    round(mean(primary_2023$co2_pen_p10_kg, na.rm = TRUE), 1),
    "kg/flight\n")
cat("% flights above P10:",
    round(mean(primary_2023$implied_CI_p10 > 0) * 100, 1), "%\n")

# =============================================================================
# STEP 8: DAILY CV
# =============================================================================

daily_cv_2023 <- primary_2023 |>
  group_by(corridor_code, month_code, flight_date) |>
  summarise(
    n        = n(),
    cv_pct   = sd(tas_kts) / mean(tas_kts) * 100,
    mean_tas = mean(tas_kts),
    .groups  = "drop"
  ) |>
  filter(n >= 5)

cat("\nDaily CV observations:", nrow(daily_cv_2023), "\n")
cat("Overall mean CV:",
    round(mean(daily_cv_2023$cv_pct), 2), "%\n")

cat("\nCV by corridor and season:\n")
daily_cv_2023 |>
  group_by(corridor_code, month_code) |>
  summarise(
    n_days  = n(),
    mean_cv = round(mean(cv_pct), 2),
    .groups = "drop"
  ) |>
  print(n = 16)

# =============================================================================
# SAVE WORKSPACE
# =============================================================================

save(flights_2023_full, primary_2023, control_2023,
     daily_cv_2023, airline_map,
     file = file.path(OUTPUT_PATH, "ci_workspace.RData"))

cat("\nWorkspace saved to:", file.path(OUTPUT_PATH, "ci_workspace.RData"), "\n")

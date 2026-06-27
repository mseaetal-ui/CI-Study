Wind-Corrected Cruise-Speed Variation Suggests Near-Term Aviation Emissions-Reduction Potential
Authors:
Target journal:
Status: Revision in preparation (resubmission)
---
Overview
This repository contains the data-extraction queries, analysis code, figure-generation
scripts, and derived datasets supporting the paper. The study combines ADS-B state-vector
data from the OpenSky Network with ERA5 atmospheric reanalysis to isolate wind-corrected
True Air Speed (TAS) across European airline corridors, tests whether observed within-day
speed dispersion exceeds what aircraft weight alone can explain, attributes the residual to
airline-level operational policy, and scales the result to a conservative network-wide CO2
abatement estimate using OAG schedules and EEA/ICAO emission factors.
Headline result: within-day TAS dispersion exceeded a 2% weight-only benchmark in 15 of
16 corridor-season cells (mean daily CV 2.85%); scaling the discretionary component across the
EU-connected fleet yields a central abatement estimate of 0.681 Mt CO2 yr⁻¹ (sensitivity
range 0.607–0.803 Mt).
---
Repository structure
```
├── README.md
├── LICENSE                          # MIT (code)
├── DATA_LICENSE.md                  # data terms (OpenSky, Copernicus, OAG, BADA)
│
├── 01_trino_queries/
│   └── extract_corridors.ps1        # ADS-B extraction (OpenSky Trino)
├── 02_data_processing/
│   ├── 00_download_era5.R           # ERA5 download (request parameters)
│   └── 01_load_and_wind_correct.R   # wind correction, filtering
├── 03_analysis/
│   ├── 01_cv_analysis.R             # within-day CV, t-tests vs benchmark
│   └── 02_statistical_analysis.R    # Kruskal–Wallis, OLS regression, correlation
├── 04_figures/
│   └── generate_all_figures.R       # all figure scripts
├── 05_supplementary/
│   ├── supplementary_tables.R                        # Tables S1–S3
│   ├── supplementary_table_S3_aircraft_CI_capability.R
│   ├── supplementary_table_S4_corridor_census.R      # corridor-month census
│   └── c3_control_significance_test.R                # control-corridor statistics
│
└── data/
    ├── derived/
    │   ├── flight_level_primary.csv        # 5,774 primary-corridor flights (TAS, wind, etc.)
    │   ├── flight_level_all.csv            # all flights incl. C3 control
    │   ├── daily_cv.csv                    # daily CV per corridor-day
    │   └── route_emissions_censored.csv    # OAG-derived, semi-censored (see below)
    ├── era5/
    │   └── README.md                       # download instructions (not the .nc files)
    └── DATA_DICTIONARY.md                  # every column in every file, defined
```
---
Data files included in this repository
All derived data products below are released openly. They are sufficient to reproduce every
figure and the headline abatement estimate.
`data/derived/flight_level_primary.csv`  (5,774 rows)
One row per flight in the four primary corridors (C1, C2, C4, C5), after wind correction and
quality filtering. Key columns: `corridor_code`, `month_code`, `flight_date`, `airline`,
`groundspeed_kts`, `headwind_kts` (along-track wind W∥), `tas_kts` (wind-corrected TAS),
`altitude_ft`, `ping_count`, `p10_tas`, `implied_CI_p10`, `co2_pen_p10_kg`.
`data/derived/flight_level_all.csv`
As above, plus the North Atlantic control corridor (C3). Use this file to reproduce the
control-corridor analysis.
`data/derived/daily_cv.csv`
One row per corridor-day with the within-day coefficient of variation of TAS. This is the
basis for the headline 2.85% figure and the benchmark significance tests.
`data/derived/route_emissions_censored.csv`  (42,244 rows)
Route-level CO2 and abatement potential for the EU-connected network, derived from OAG
schedules. This is a semi-censored product (see "Data licensing" below): exact annual
frequencies are replaced by coarse bands, named carriers by carrier groups, and emissions are
rounded to 3 significant figures. It reproduces the network totals (≈192 Mt total CO2; 1.14 Mt
raw / 0.71 Mt deduplicated saving) without redistributing OAG's proprietary schedule.
---
Data sources (raw)
Source	Access	Used for
OpenSky Network ADS-B	Free academic access, https://opensky-network.org (Trino SQL)	Aircraft trajectories
ERA5 reanalysis	Free, Copernicus CDS, https://cds.climate.copernicus.eu	Wind correction (U, V at 250 hPa)
OAG Schedules	Proprietary, https://www.oag.com	Network CO2 scaling
EUROCONTROL BADA	Licensed, https://www.eurocontrol.int/model/bada	Performance parameters
Study period: January, March, June, November 2023
Corridors: C1 Central France · C2 Central Europe · C3 North Atlantic (control) · C4 Iberia · C5 Scandinavia
ERA5 `.nc` files are not hosted here (size + licence). The download script with exact
request parameters is in `02_data_processing/00_download_era5.R`.
---
Data licensing
Code is released under the MIT License. Derived flight-level data (from public OpenSky data)
are released openly. The route-level emissions file is a semi-censored derivative of
proprietary OAG schedule data: it omits exact frequencies and named carriers and rounds all
emissions, and does not permit reconstruction of the underlying commercial schedule. Users
requiring the full route-level data should contact OAG (https://www.oag.com) directly. See
`DATA_LICENSE.md` for full terms.
---
Requirements
```r
install.packages(c("tidyverse", "ncdf4", "ggplot2",
                   "dunn.test", "lubridate", "ecmwfr"))
```
OpenSky Trino access requires a free account and a Java runtime.
ERA5 download requires a free Copernicus CDS account and the `ecmwfr` API key.
---
Reproducibility notes
File paths in the scripts use the project root; set your working directory accordingly.
ADS-B filtering: cruise band FL300–FL400; |vertical rate| < 1.5 m/s; ground speed 380–650 kt;
minimum 30 valid position reports per flight; daily ±3 SD outlier removal.
Within-day CV is computed per corridor-day (days with ≥5 valid flights), then averaged —
this is the basis for the 2.85% headline and reconciles with Supplementary Table S4.
The validation approach follows the FDR-validated ADS-B + ERA5 + BADA method of
Antulov-Fantulin (2024); the North Atlantic control corridor (C3) serves as a procedural
negative control.
---
How to cite
> Tarradellas, J. & Sismanidou, A. (2025). Wind-corrected cruise-speed variation suggests
> near-term aviation emissions-reduction potential. *Scientific Reports* [under review].
A `CITATION.cff` machine-readable citation is included.
---
License
MIT License (code) — see `LICENSE`. Data terms — see `DATA_LICENSE.md`.

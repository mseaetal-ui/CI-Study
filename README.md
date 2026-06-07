Wind-Corrected Cruise-Speed Variation Suggests Near-Term Aviation Emissions-Reduction Potential
Author:  
Target journal: 
Status: Pre-submission revision
---
Overview
This repository contains all data extraction queries, analysis code, and figure generation scripts for the paper. The study uses ADS-B state-vector data from the OpenSky Network combined with ERA5 atmospheric reanalysis to isolate wind-corrected True Air Speed (TAS) variation across European airline corridors, testing whether observed speed dispersion is consistent with Cost Index heterogeneity across airlines.
---
Repository Structure
```
├── README.md
├── 01_trino_queries/
│   ├── extract_corridors.ps1        # PowerShell: all corridor extractions
│   └── corridor_definitions.md     # Corridor geographic and heading specs
├── 02_data_processing/
│   ├── 01_load_and_wind_correct.R   # Load CSVs, apply ERA5 wind correction
│   ├── 02_outlier_filter.R          # Daily outlier removal, TAS filter
│   └── 03_p10_co2_penalty.R        # P10 benchmark, CO2 penalty calculation
├── 03_analysis/
│   ├── 01_cv_analysis.R             # Within-day CV, t-tests vs benchmark
│   ├── 02_kruskal_wallis.R          # Inter-airline KW and Dunn tests
│   ├── 03_regression_model.R        # OLS multivariable regression
│   ├── 04_headwind_correlation.R    # Pearson correlation, Figure 7
│   └── 05_sensitivity_benchmarks.R # Sensitivity Table S1
├── 04_figures/
│   └── generate_all_figures.R       # All figure generation scripts
└── 05_supplementary/
    └── supplementary_tables.R       # Tables S1, S2, S3
```
---
Data Sources
ADS-B Data — OpenSky Network
Access: Free academic access at https://opensky-network.org
Table: `state_vectors_data4` (Trino SQL interface)
Study period: January, March, June, November 2023
Corridors: C1 (Central France), C2 (Central Europe), C3 (North Atlantic control), C4 (Iberia), C5 (Scandinavia)
Note: OpenSky Network requires registration. Trino access available at https://trino.opensky-network.org
ERA5 Wind Reanalysis
Access: Free via Copernicus Climate Data Store https://cds.climate.copernicus.eu
Product: `reanalysis-era5-pressure-levels`
Variables: U and V wind components at 225, 250, 300 hPa
Time steps: 06:00, 08:00, 10:00, 12:00 UTC daily
Resolution: 0.25° horizontal
OAG Route Frequency Database
Access: Proprietary — derived aggregated statistics available from corresponding author upon request
Used for: Network-level CO₂ scaling only
---
Requirements
R packages
```r
install.packages(c(
  "tidyverse",
  "ncdf4",
  "ggplot2",
  "dunn.test",
  "lubridate"
))
```
ERA5 download (R)
```r
install.packages("ecmwfr")
```
OpenSky Trino access
Java Runtime Environment (JRE) required
Trino CLI: download from https://trino.io/download.html
OpenSky account: register at https://opensky-network.org/index.php?option=com_users&view=registration
---
Reproducibility Notes
All file paths in the R scripts use relative paths from the project root. Set your working directory accordingly.
ERA5 `.nc` files are not included in this repository due to size. Download scripts are provided.
The Trino queries use external authentication (OAuth browser login). Run each query separately from PowerShell/Terminal.
A minimum of 20 ADS-B position reports per flight is required in the Trino HAVING clause; a further minimum of 30 is applied in R during post-processing.
---
Citation
If you use this code or data pipeline, please cite:
. Wind-corrected cruise-speed variation suggests near-term aviation emissions-reduction potential.  [under review].
---
License
MIT License — see LICENSE file.

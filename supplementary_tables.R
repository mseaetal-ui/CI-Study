# =============================================================================
# supplementary_tables.R
# =============================================================================
# Generates:
#   Table S1: Sensitivity of CV significance to benchmark (1.5-3.0%)
#   Table S2: Implied CI per 10kt headwind by corridor
#   Table S3: Aircraft type classification (manual — edit as needed)
# =============================================================================

library(tidyverse)

OUTPUT_PATH <- "data/processed"
load(file.path(OUTPUT_PATH, "ci_workspace.RData"))

# =============================================================================
# TABLE S1: Sensitivity of CV significance to benchmark choice
# =============================================================================

benchmarks <- c(1.5, 2.0, 2.5, 3.0)

table_s1 <- map_dfr(benchmarks, function(bm) {
  map_dfr(c("C1","C2","C4","C5"), function(corr) {
    map_dfr(c("Jan","Mar","Jun","Nov"), function(mon) {
      d <- daily_cv_2023 |>
        filter(corridor_code == corr, month_code == mon)
      if (nrow(d) < 5) return(NULL)
      tt <- t.test(d$cv_pct, mu = bm, alternative = "greater")
      tibble(
        Benchmark   = paste0(bm, "%"),
        Corridor    = corr,
        Season      = mon,
        N_days      = nrow(d),
        Mean_CV_pct = round(mean(d$cv_pct), 2),
        t_statistic = round(tt$statistic, 2),
        p_value     = format(tt$p.value, scientific = TRUE, digits = 3),
        Significance = case_when(
          tt$p.value < 0.001 ~ "***",
          tt$p.value < 0.01  ~ "**",
          tt$p.value < 0.05  ~ "*",
          TRUE               ~ "ns"
        )
      )
    })
  })
})

write_csv(table_s1, file.path(OUTPUT_PATH, "Table_S1_CV_sensitivity.csv"))
cat("Table S1 saved.\n")
print(table_s1)

# =============================================================================
# TABLE S2: Implied CI per 10kt headwind by corridor
# =============================================================================

table_s2 <- map_dfr(c("C1","C2","C3","C4","C5"), function(corr) {
  d <- flights_2023_full |>
    filter(corridor_code == corr,
           !is.na(headwind_kts), !is.na(tas_kts))
  ct  <- cor.test(d$headwind_kts, d$tas_kts)
  lm1 <- lm(tas_kts ~ headwind_kts, data = d)
  slope       <- coef(lm1)[2]
  tas_per_10  <- round(slope * -10, 1)
  ci_per_10   <- round(slope * -10 / 0.36, 0)
  tibble(
    Corridor              = corr,
    N                     = nrow(d),
    r                     = round(ct$estimate, 3),
    p_value               = format(ct$p.value,
                                   scientific = TRUE, digits = 3),
    TAS_per_10kt_HW_kts   = tas_per_10,
    CI_equiv_per_10kt_HW  = ci_per_10,
    Note = ifelse(corr == "C3",
                  "Thermodynamic effect at constant Mach — not CI discretion",
                  "Indicative CI-equivalent under BADA A320 assumptions")
  )
})

write_csv(table_s2, file.path(OUTPUT_PATH, "Table_S2_CI_per_10kt.csv"))
cat("Table S2 saved.\n")
print(table_s2)

# =============================================================================
# TABLE S3: Aircraft type classification
# (Edit this table to match the aircraft types in your OAG dataset)
# =============================================================================

table_s3 <- tribble(
  ~Aircraft_Type,  ~Category,           ~Rationale,
  "A319",          "Modelled",          "Airbus FMS with CI function; BADA parameters used",
  "A320",          "Modelled",          "Airbus FMS with CI function; primary reference aircraft",
  "A321",          "Modelled",          "Airbus FMS with CI function; BADA parameters available",
  "A320neo",       "Modelled",          "Airbus FMS with CI function; BADA parameters available",
  "A321neo",       "Modelled",          "Airbus FMS with CI function; BADA parameters available",
  "B737-700",      "Modelled",          "Boeing FMS with CI function; comparable BADA parameters",
  "B737-800",      "Modelled",          "Boeing FMS with CI function; comparable BADA parameters",
  "B737-900",      "Modelled",          "Boeing FMS with CI function; comparable BADA parameters",
  "B737 MAX 8",    "Modelled",          "Boeing FMS with CI function; comparable BADA parameters",
  "A330-200",      "Modelled (WB)",     "Widebody; Airbus FMS with CI function; widebody factors applied",
  "A330-300",      "Modelled (WB)",     "Widebody; Airbus FMS with CI function; widebody factors applied",
  "A350-900",      "Modelled (WB)",     "Widebody; Airbus FMS with CI function; widebody factors applied",
  "B777-200",      "Modelled (WB)",     "Widebody; Boeing FMS with CI function; widebody factors applied",
  "B787-8",        "Modelled (WB)",     "Widebody; Boeing FMS with CI function; widebody factors applied",
  "B787-9",        "Modelled (WB)",     "Widebody; Boeing FMS with CI function; widebody factors applied",
  "ATR-72",        "Excluded",          "Turboprop; no jet FMS CI function",
  "Dash-8 Q400",   "Excluded",          "Turboprop; no jet FMS CI function",
  "E170",          "Excluded",          "Regional jet; BADA parameters not used in primary analysis",
  "E190",          "Excluded",          "Regional jet; BADA parameters not used in primary analysis",
  "CRJ-900",       "Excluded",          "Regional jet; BADA parameters not used in primary analysis"
)

write_csv(table_s3,
          file.path(OUTPUT_PATH, "Table_S3_aircraft_classification.csv"))
cat("Table S3 saved.\n")
cat("\nNote: Edit Table S3 to match the exact aircraft types\n")
cat("in your OAG dataset. Categories:\n")
cat("  'Modelled'     = narrowbody; primary saving factors applied\n")
cat("  'Modelled (WB)'= widebody; separate widebody factors applied\n")
cat("  'Excluded'     = not included in CI modelling framework\n")

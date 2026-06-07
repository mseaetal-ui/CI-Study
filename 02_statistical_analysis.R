# =============================================================================
# 02_kruskal_wallis.R — Inter-airline TAS differences
# =============================================================================

library(tidyverse)
library(dunn.test)

OUTPUT_PATH <- "data/processed"
load(file.path(OUTPUT_PATH, "ci_workspace.RData"))

cat("==============================================\n")
cat("KRUSKAL-WALLIS: INTER-AIRLINE TAS DIFFERENCES\n")
cat("==============================================\n")

for (corr in c("C1","C2","C4","C5")) {
  d <- primary_2023 |> filter(corridor_code == corr)
  kw <- kruskal.test(tas_kts ~ airline, data = d)
  cat("\n", corr, "— KW chi-sq =", round(kw$statistic, 1),
      "df =", kw$parameter,
      "p =", format(kw$p.value, scientific = TRUE, digits = 3), "\n")

  # Airlines with >= 10 observations
  airlines_keep <- d |>
    count(airline) |>
    filter(n >= 10) |>
    pull(airline)

  d_filtered <- d |> filter(airline %in% airlines_keep)

  cat("Mean TAS by airline:\n")
  d_filtered |>
    group_by(airline) |>
    summarise(
      n        = n(),
      mean_tas = round(mean(tas_kts), 1),
      sd_tas   = round(sd(tas_kts), 1),
      .groups  = "drop"
    ) |>
    arrange(desc(mean_tas)) |>
    print()
}

# Dunn post-hoc for C2 (strongest corridor)
cat("\n\nDUNN POST-HOC TEST — C2 (strongest corridor)\n")
d_c2 <- primary_2023 |>
  filter(corridor_code == "C2") |>
  filter(airline %in% (count(filter(primary_2023,
                                     corridor_code == "C2"),
                              airline) |>
                         filter(n >= 10) |> pull(airline)))

dunn.test(d_c2$tas_kts, d_c2$airline,
          method = "bonferroni", kw = TRUE)


# =============================================================================
# 03_regression_model.R — Multivariable OLS regression
# =============================================================================

cat("\n\n==============================================\n")
cat("MULTIVARIABLE REGRESSION: TAS ~ AIRLINE + COVARIATES\n")
cat("==============================================\n")
cat("Model: TAS ~ airline + corridor + month + altitude\n")
cat("Controls for meteorological confounding via wind-corrected TAS\n\n")

model_with_airline <- lm(
  tas_kts ~ airline + corridor_code + month_code + scale(altitude_ft),
  data = primary_2023
)

model_without_airline <- lm(
  tas_kts ~ corridor_code + month_code + scale(altitude_ft),
  data = primary_2023
)

# F-test: joint significance of airline
f_test <- anova(model_without_airline, model_with_airline)
cat("F-test for joint airline significance:\n")
print(f_test)

# R-squared
cat("\nR-squared with airline:",
    round(summary(model_with_airline)$r.squared, 3))
cat("\nR-squared without airline:",
    round(summary(model_without_airline)$r.squared, 3))
cat("\nVariance explained by airline alone:",
    round((summary(model_with_airline)$r.squared -
             summary(model_without_airline)$r.squared) * 100, 1), "%\n")

# Airline coefficients
cat("\nAirline coefficients (vs reference — Air Canada):\n")
coefs <- coef(summary(model_with_airline))
airline_rows <- grep("^airline", rownames(coefs))
print(round(coefs[airline_rows, c(1, 2, 4)], 3))

cat("\nNote: aircraft type, airport pair, and route distance\n")
cat("not available in state-vector extraction. Airline\n")
cat("coefficients capture combined effect of operational\n")
cat("speed policy and associated fleet characteristics.\n")


# =============================================================================
# 04_headwind_correlation.R — Pearson correlation W_parallel vs TAS
# =============================================================================

cat("\n\n==============================================\n")
cat("HEADWIND-TAS CORRELATION\n")
cat("==============================================\n")
cat("Note: TAS is algebraically derived from GS and ERA5 wind.\n")
cat("Correlation is partly mechanical and not treated as\n")
cat("independent causal evidence. Used descriptively only.\n\n")

corridor_labels <- c(
  "C1" = "C1: Central France (Northbound)",
  "C2" = "C2: Central Europe (Westbound)",
  "C3" = "C3: North Atlantic (Control)",
  "C4" = "C4: Iberia (Southbound)",
  "C5" = "C5: Scandinavia (Northbound)"
)

corr_results <- map_dfr(c("C1","C2","C3","C4","C5"), function(corr) {
  d <- flights_2023_full |>
    filter(corridor_code == corr,
           !is.na(headwind_kts),
           !is.na(tas_kts))
  ct  <- cor.test(d$headwind_kts, d$tas_kts)
  lm1 <- lm(tas_kts ~ headwind_kts, data = d)
  tas_per_10 <- round(coef(lm1)[2] * -10, 1)
  ci_per_10  <- round(coef(lm1)[2] * -10 / 0.36, 0)
  tibble(
    corridor       = corr,
    n              = nrow(d),
    r              = round(ct$estimate, 3),
    p_value        = ct$p.value,
    tas_per_10kt   = tas_per_10,
    ci_equiv_per_10kt = ci_per_10
  )
})

print(corr_results)
cat("\nImplied CI per 10kt headwind are INDICATIVE ONLY\n")
cat("under BADA A320 assumptions. Not direct FMS observations.\n")


# =============================================================================
# 05_sensitivity_benchmarks.R — Sensitivity Table S1
# =============================================================================

cat("\n\n==============================================\n")
cat("SUPPLEMENTARY TABLE S1: SENSITIVITY OF CV SIGNIFICANCE\n")
cat("==============================================\n")

benchmarks <- c(1.5, 2.0, 2.5, 3.0)

sensitivity_table <- map_dfr(benchmarks, function(bm) {
  map_dfr(c("C1","C2","C4","C5"), function(corr) {
    map_dfr(c("Jan","Mar","Jun","Nov"), function(mon) {
      d <- daily_cv_2023 |>
        filter(corridor_code == corr, month_code == mon)
      if (nrow(d) < 5) return(NULL)
      tt <- t.test(d$cv_pct, mu = bm, alternative = "greater")
      tibble(
        benchmark     = bm,
        corridor      = corr,
        season        = mon,
        n_days        = nrow(d),
        mean_cv       = round(mean(d$cv_pct), 2),
        t_stat        = round(tt$statistic, 2),
        p_value       = tt$p.value,
        significant   = tt$p.value < 0.05,
        sig_label     = case_when(
          tt$p.value < 0.001 ~ "***",
          tt$p.value < 0.01  ~ "**",
          tt$p.value < 0.05  ~ "*",
          TRUE               ~ "ns"
        )
      )
    })
  })
})

# Summary: significant cells per benchmark
sensitivity_table |>
  group_by(benchmark) |>
  summarise(
    n_significant = sum(significant),
    n_total       = n(),
    .groups = "drop"
  ) |>
  mutate(label = paste0(n_significant, "/", n_total, " significant")) |>
  print()

# Full table
cat("\nFull sensitivity table:\n")
sensitivity_table |>
  select(benchmark, corridor, season, mean_cv, sig_label) |>
  pivot_wider(names_from = season,
              values_from = c(mean_cv, sig_label)) |>
  print()

# Save
write_csv(sensitivity_table,
          file.path(OUTPUT_PATH, "table_S1_sensitivity.csv"))
cat("\nTable S1 saved.\n")

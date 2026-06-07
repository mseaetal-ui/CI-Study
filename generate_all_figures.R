# =============================================================================
# generate_all_figures.R — Figure generation
# =============================================================================
# Generates Figure 7: Along-track wind component vs TAS, all five corridors
# (Other figures follow same pattern — add as needed)
# =============================================================================

library(tidyverse)
library(ggplot2)

OUTPUT_PATH  <- "data/processed"
FIGURES_PATH <- "figures"
dir.create(FIGURES_PATH, showWarnings = FALSE)

load(file.path(OUTPUT_PATH, "ci_workspace.RData"))

# =============================================================================
# SHARED THEME
# =============================================================================

theme_paper <- theme_minimal(base_size = 12) +
  theme(
    plot.title       = element_text(face = "bold", size = 13),
    plot.subtitle    = element_text(size = 10, color = "grey40"),
    plot.caption     = element_text(size = 8,  color = "grey50"),
    legend.position  = "bottom",
    panel.grid.minor = element_blank(),
    plot.background  = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

airline_colors <- c(
  "Air France"      = "#002395",
  "British Airways" = "#003399",
  "Lufthansa"       = "#FFD700",
  "easyJet"         = "#FF6600",
  "Iberia"          = "#CC0000",
  "Iberia Express"  = "#FF4444",
  "Vueling"         = "#FF6B00",
  "Eurowings"       = "#6B0F1A",
  "Austrian"        = "#E4002B",
  "KLM"             = "#00A1DE",
  "Ryanair"         = "#003580",
  "TAP Portugal"    = "#006600",
  "SAS"             = "#000080",
  "Norwegian"       = "#CC0000",
  "Finnair"         = "#003580",
  "Wizz Air"        = "#C6007E",
  "Virgin Atlantic" = "#E60026",
  "Air Canada"      = "#CC0000",
  "Swiss"           = "#FF0000"
)

corridor_labels <- c(
  "C1" = "C1: Central France (Northbound)",
  "C2" = "C2: Central Europe (Westbound)",
  "C3" = "C3: North Atlantic (Control)",
  "C4" = "C4: Iberia (Southbound)",
  "C5" = "C5: Scandinavia (Northbound)"
)

# =============================================================================
# FIGURE 7: Headwind-TAS Correlation
# =============================================================================

# Compute per-corridor correlations for annotations
corr_annotations <- map_dfr(c("C1","C2","C3","C4","C5"), function(corr) {
  d  <- flights_2023_full |>
    filter(corridor_code == corr,
           !is.na(headwind_kts), !is.na(tas_kts))
  ct <- cor.test(d$headwind_kts, d$tas_kts)
  tibble(
    corridor_code  = corr,
    corridor_label = factor(corridor_labels[corr],
                             levels = corridor_labels),
    r     = round(ct$estimate, 3),
    p_val = ct$p.value,
    label = paste0("r=", round(ct$estimate, 3),
                   "\np=", format(ct$p.value,
                                  scientific = TRUE, digits = 3))
  )
})

fig7 <- flights_2023_full |>
  mutate(corridor_label = factor(corridor_labels[corridor_code],
                                  levels = corridor_labels)) |>
  ggplot(aes(x = headwind_kts, y = tas_kts)) +
  geom_point(aes(color = airline), alpha = 0.4, size = 1.5) +
  geom_smooth(method = "lm", color = "black",
              linewidth = 1.2, se = TRUE, fill = "grey80") +
  geom_vline(xintercept = 0, linetype = "dashed",
             color = "grey50", linewidth = 0.8) +
  annotate("text", x =  40, y = -Inf,
           hjust = 0.5, vjust = -0.5, size = 2.8, color = "grey50",
           label = "W\u2225 > 0\n(tailwind)") +
  annotate("text", x = -40, y = -Inf,
           hjust = 0.5, vjust = -0.5, size = 2.8, color = "grey50",
           label = "W\u2225 < 0\n(headwind)") +
  geom_text(
    data = corr_annotations,
    aes(label = label),
    x = -Inf, y = Inf,
    hjust = -0.1, vjust = 1.3,
    size = 3.2, fontface = "bold", color = "grey20",
    inherit.aes = FALSE
  ) +
  scale_color_manual(values = airline_colors, guide = "none") +
  facet_wrap(~corridor_label, ncol = 2, scales = "free") +
  labs(
    title    = paste0("Along-Track Wind Component vs True Air Speed",
                      " \u2014 All Five Corridors 2023"),
    subtitle = paste0(
      "Significant negative correlations in all corridors: ",
      "higher TAS observed under stronger headwinds.\n",
      "Negative W\u2225 = headwind; positive W\u2225 = tailwind.\n",
      "C3 correlation reflects thermodynamic TAS variation at",
      " constant Mach \u2014 not discretionary CI behaviour."),
    x        = paste0("Along-track wind component W\u2225 (knots)",
                       " [\u2212 headwind, + tailwind]"),
    y        = "Wind-corrected TAS (knots)",
    caption  = paste0(
      "W\u2225 = U\u00b7sin(\u03b8) + V\u00b7cos(\u03b8). ",
      "Positive W\u2225 = tailwind; negative W\u2225 = headwind. ",
      "TAS = GS \u2212 W\u2225.\n",
      "Scalar along-track approximation; ",
      "max crosswind error <1 kt at observed corridor headings.\n",
      "Source: OpenSky Network ADS-B + ERA5 reanalysis, 2023.")
  ) +
  theme_paper +
  theme(strip.text = element_text(face = "bold", size = 9))

ggsave(file.path(FIGURES_PATH, "Fig07_headwind_TAS_correlation.png"),
       fig7, width = 14, height = 12, dpi = 300, bg = "white")

cat("Figure 7 saved to:", FIGURES_PATH, "\n")

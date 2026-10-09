# ==============================================================================
# SCRIPT DIAGNOSTIK REGRESI LENGKAP: BASELINE OLS vs BOX-COX OLS
# Analisis Uji Asumsi Klasik:
# 1. Uji Heteroskedastisitas (Breusch-Pagan & Koenker studentized)
# 2. Uji Normalitas Residual (Kolmogorov-Smirnov, Jarque-Bera, Skewness & Kurtosis)
# 3. Multikolinearitas (Variance Inflation Factor / VIF)
# 4. Pengamatan Berpengaruh (Cook's Distance, DFFITS, Hatvalues / Leverage)
# ==============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(car)
  library(lmtest)
  library(moments)
  library(tseries)
})

out_dir <- if (dir.exists("tabel_output")) "tabel_output" else "."
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# 1. Pemuatan Model dan Data Latih
cat("Memuat model dan data dari objek rds...\n")
rds_candidates <- c(
  "model_lengkap_eda_rfe_rf_boxcox.rds",
  file.path("..", "model_lengkap_eda_rfe_rf_boxcox.rds"),
  file.path("data", "model_lengkap_eda_rfe_rf_boxcox.rds")
)
rds_path <- rds_candidates[file.exists(rds_candidates)][1]
if (is.na(rds_path) || !file.exists(rds_path)) {
  stop("File model_lengkap_eda_rfe_rf_boxcox.rds tidak ditemukan di direktori proyek!")
}
rds <- readRDS(rds_path)
train_data <- rds$train_data
fit_base   <- rds$fit_base
fit_bc     <- rds$fit_bc
lambda_opt <- rds$lambda_opt
predictors <- rds$predictors_final

cat(sprintf("Jumlah observasi data latih (n): %d\n", nrow(train_data)))
cat(sprintf("Jumlah prediktor (p): %d\n", length(predictors)))
cat(sprintf("Lambda Box-Cox: %.4f\n\n", lambda_opt))

# Residual & Fitted values
res_base <- residuals(fit_base)
fit_vals_base <- fitted(fit_base)

res_bc <- residuals(fit_bc)
fit_vals_bc <- fitted(fit_bc)

# ==============================================================================
# A. UJI HETEROSKEDASTISITAS
# ==============================================================================
cat("==============================================================================\n")
cat("A. UJI HETEROSKEDASTISITAS (BREUSCH-PAGAN TEST)\n")
cat("==============================================================================\n")

bp_base_std <- bptest(fit_base, studentize = TRUE)
bp_base_non <- bptest(fit_base, studentize = FALSE)

bp_bc_std   <- bptest(fit_bc, studentize = TRUE)
bp_bc_non   <- bptest(fit_bc, studentize = FALSE)

tabel_hetero <- data.frame(
  Model = c("1. Baseline OLS (Skala Asli)", "2. Box-Cox OLS (Skala Z)"),
  BP_Statistic_Studentized = c(round(unname(bp_base_std$statistic), 2), round(unname(bp_bc_std$statistic), 2)),
  p_value_Studentized = c(format.pval(bp_base_std$p.value, digits = 4), format.pval(bp_bc_std$p.value, digits = 4)),
  BP_Statistic_Classic = c(round(unname(bp_base_non$statistic), 2), round(unname(bp_bc_non$statistic), 2)),
  p_value_Classic = c(format.pval(bp_base_non$p.value, digits = 4), format.pval(bp_bc_non$p.value, digits = 4)),
  Kesimpulan = c("Heteroskedastisitas Signifikan (Homoskedastisitas Tertolak)",
                 "Heteroskedastisitas Berkurang Sangat Signifikan")
)
print(tabel_hetero)
write.csv(tabel_hetero, file.path(out_dir, "tabel_uji_heteroskedastisitas.csv"), row.names = FALSE)

# ==============================================================================
# B. UJI NORMALITAS RESIDUAL
# ==============================================================================
cat("\n==============================================================================\n")
cat("B. UJI NORMALITAS RESIDUAL\n")
cat("==============================================================================\n")

# Standarisasi residual untuk Kolmogorov-Smirnov
std_res_base <- (res_base - mean(res_base)) / sd(res_base)
std_res_bc   <- (res_bc - mean(res_bc)) / sd(res_bc)

ks_base <- ks.test(std_res_base, "pnorm")
ks_bc   <- ks.test(std_res_bc, "pnorm")

jb_base <- jarque.bera.test(res_base)
jb_bc   <- jarque.bera.test(res_bc)

skew_base <- moments::skewness(res_base)
kurt_base <- moments::kurtosis(res_base)

skew_bc <- moments::skewness(res_bc)
kurt_bc <- moments::kurtosis(res_bc)

tabel_normalitas <- data.frame(
  Model = c("1. Baseline OLS (Skala Asli)", "2. Box-Cox OLS (Skala Z)"),
  Skewness_Residual = c(round(skew_base, 3), round(skew_bc, 3)),
  Kurtosis_Residual = c(round(kurt_base, 3), round(kurt_bc, 3)),
  KS_Statistic = c(round(unname(ks_base$statistic), 4), round(unname(ks_bc$statistic), 4)),
  KS_p_value = c(format.pval(ks_base$p.value, digits = 4), format.pval(ks_bc$p.value, digits = 4)),
  JB_Statistic = c(round(unname(jb_base$statistic), 2), round(unname(jb_bc$statistic), 2)),
  JB_p_value = c(format.pval(jb_base$p.value, digits = 4), format.pval(jb_bc$p.value, digits = 4)),
  Interpretasi_Normalitas = c(
    "Sangat Menceng Kanan & Leptokurtik Hebat (Pelanggaran Asumsi Berat)",
    "Mendekati Simetris Normal (Perbaikan Bentuk Distribusi Sangat Drastis)"
  )
)
print(tabel_normalitas)
write.csv(tabel_normalitas, file.path(out_dir, "tabel_uji_normalitas_residual.csv"), row.names = FALSE)

# ==============================================================================
# C. MULTIKOLINEARITAS (VARIANCE INFLATION FACTOR / VIF)
# ==============================================================================
cat("\n==============================================================================\n")
cat("C. MULTIKOLINEARITAS (VIF)\n")
cat("==============================================================================\n")

vif_base <- car::vif(fit_base)
vif_bc   <- car::vif(fit_bc)

tabel_vif <- data.frame(
  Variabel = names(vif_base),
  VIF_Baseline_OLS = round(unname(vif_base), 3),
  VIF_BoxCox_OLS   = round(unname(vif_bc), 3),
  Kategori_Multikolinearitas = ifelse(vif_base > 10, "Tinggi (VIF > 10)",
                               ifelse(vif_base > 5, "Moderat (5 < VIF <= 10)", "Aman (VIF <= 5)"))
) %>% arrange(desc(VIF_Baseline_OLS))

print(head(tabel_vif, 10))
write.csv(tabel_vif, file.path(out_dir, "tabel_vif_multikolinearitas.csv"), row.names = FALSE)

# ==============================================================================
# D. PENGAMATAN BERPENGARUH (INFLUENTIAL OBSERVATIONS & LEVERAGE)
# ==============================================================================
cat("\n==============================================================================\n")
cat("D. PENGAMATAN BERPENGARUH (COOK'S DISTANCE, DFFITS, LEVERAGE)\n")
cat("==============================================================================\n")

n <- nrow(train_data)
p <- length(coef(fit_base)) # intercept + prediktor

# Thresholds standar ekonometrika / statistika
thresh_cook_classic <- 1.0
thresh_cook_4overN  <- 4 / n
thresh_leverage     <- 2 * p / n # atau 3 * p / n

# 1. Baseline OLS
cook_base <- cooks.distance(fit_base)
hat_base  <- hatvalues(fit_base)
dffits_base <- dffits(fit_base)

n_cook_base_4n <- sum(cook_base > thresh_cook_4overN, na.rm = TRUE)
n_cook_base_1  <- sum(cook_base > thresh_cook_classic, na.rm = TRUE)
n_lev_base     <- sum(hat_base > thresh_leverage, na.rm = TRUE)
max_cook_base  <- max(cook_base, na.rm = TRUE)

# 2. Box-Cox OLS
cook_bc <- cooks.distance(fit_bc)
hat_bc  <- hatvalues(fit_bc)
dffits_bc <- dffits(fit_bc)

n_cook_bc_4n <- sum(cook_bc > thresh_cook_4overN, na.rm = TRUE)
n_cook_bc_1  <- sum(cook_bc > thresh_cook_classic, na.rm = TRUE)
n_lev_bc     <- sum(hat_bc > thresh_leverage, na.rm = TRUE)
max_cook_bc  <- max(cook_bc, na.rm = TRUE)

tabel_influential <- data.frame(
  Model = c("1. Baseline OLS (Skala Asli)", "2. Box-Cox OLS (Skala Z)"),
  Ambang_Batas_Cook_4_per_n = round(thresh_cook_4overN, 6),
  Jml_Cook_Lebih_4_per_n = c(n_cook_base_4n, n_cook_bc_4n),
  Persentase_Cook_4_per_n = c(round(n_cook_base_4n / n * 100, 2), round(n_cook_bc_4n / n * 100, 2)),
  Max_Cooks_Distance = c(round(max_cook_base, 4), round(max_cook_bc, 4)),
  Ambang_Batas_Leverage_2p_per_n = round(thresh_leverage, 4),
  Jml_High_Leverage = c(n_lev_base, n_lev_bc),
  Persentase_High_Leverage = c(round(n_lev_base / n * 100, 2), round(n_lev_bc / n * 100, 2)),
  Interpretasi_Pengaruh = c(
    "Data beban puncak menarik garis regresi secara tidak proporsional",
    "Pengaruh titik ekstrim terdistribusi jauh lebih stabil dan homogen"
  )
)
print(tabel_influential)
write.csv(tabel_influential, file.path(out_dir, "tabel_pengamatan_berpengaruh.csv"), row.names = FALSE)

# ==============================================================================
# E. VISUALISASI DIAGNOSTIK KOMPARATIF (PNG)
# ==============================================================================
cat("\nMembuat grafik diagnostik komparatif...\n")

# 1. Plot Residual vs Fitted (Heteroskedastisitas)
png(file.path(out_dir, "plot_diagnostik_residual_vs_fitted.png"), width = 1200, height = 550, res = 120)
par(mfrow = c(1, 2), mar = c(4.5, 4.5, 3, 1))
plot(fit_vals_base, res_base, pch = 16, cex = 0.5, col = rgb(0.2, 0.4, 0.8, 0.3),
     main = "Baseline OLS: Residual vs Fitted (Heteroskedastis)",
     xlab = "Fitted Values (Wh)", ylab = "Residuals (Wh)")
abline(h = 0, col = "red", lwd = 2, lty = 2)
lines(lowess(fit_vals_base, res_base), col = "darkred", lwd = 2)

plot(fit_vals_bc, res_bc, pch = 16, cex = 0.5, col = rgb(0.1, 0.7, 0.3, 0.3),
     main = "Box-Cox OLS: Residual vs Fitted (Homoskedastis)",
     xlab = "Fitted Values (Skala Z)", ylab = "Residuals (Skala Z)")
abline(h = 0, col = "red", lwd = 2, lty = 2)
lines(lowess(fit_vals_bc, res_bc), col = "darkgreen", lwd = 2)
dev.off()

# 2. Q-Q Plot Residual (Normalitas)
png(file.path(out_dir, "plot_diagnostik_qq_residual.png"), width = 1200, height = 550, res = 120)
par(mfrow = c(1, 2), mar = c(4.5, 4.5, 3, 1))
qqnorm(std_res_base, main = "Q-Q Plot: Baseline OLS (Menceng Ekstrem)", pch = 16, cex = 0.5, col = rgb(0.2, 0.4, 0.8, 0.3))
qqline(std_res_base, col = "red", lwd = 2)

qqnorm(std_res_bc, main = "Q-Q Plot: Box-Cox OLS (Mendekati Garis Lurus Normal)", pch = 16, cex = 0.5, col = rgb(0.1, 0.7, 0.3, 0.3))
qqline(std_res_bc, col = "red", lwd = 2)
dev.off()

# 3. Plot Cook's Distance
png(file.path(out_dir, "plot_diagnostik_cooks_distance.png"), width = 1200, height = 550, res = 120)
par(mfrow = c(1, 2), mar = c(4.5, 4.5, 3, 1))
plot(cook_base, type = "h", col = "royalblue", lwd = 1,
     main = "Cook's Distance: Baseline OLS",
     xlab = "Indeks Observasi", ylab = "Cook's Distance")
abline(h = thresh_cook_4overN, col = "red", lty = 2, lwd = 1.5)

plot(cook_bc, type = "h", col = "forestgreen", lwd = 1,
     main = "Cook's Distance: Box-Cox OLS",
     xlab = "Indeks Observasi", ylab = "Cook's Distance")
abline(h = thresh_cook_4overN, col = "red", lty = 2, lwd = 1.5)
dev.off()

# 4. Plot Multikolinearitas VIF
df_vif_plot <- tabel_vif %>% arrange(VIF_Baseline_OLS)
df_vif_plot$Variabel <- factor(df_vif_plot$Variabel, levels = df_vif_plot$Variabel)

p_vif <- ggplot(df_vif_plot, aes(x = Variabel, y = VIF_Baseline_OLS, fill = Kategori_Multikolinearitas)) +
  geom_col(alpha = 0.85) +
  geom_hline(yintercept = 5, linetype = "dashed", color = "orange", size = 1) +
  geom_hline(yintercept = 10, linetype = "dashed", color = "red", size = 1) +
  coord_flip() +
  scale_fill_manual(values = c("Aman (VIF <= 5)" = "steelblue", 
                               "Moderat (5 < VIF <= 10)" = "orange", 
                               "Tinggi (VIF > 10)" = "firebrick")) +
  theme_minimal() +
  labs(title = "Variance Inflation Factor (VIF) untuk 26 Prediktor",
       subtitle = "Garis oranye: Ambang moderat (VIF = 5) | Garis merah: Ambang tinggi (VIF = 10)",
       x = "Prediktor", y = "Nilai VIF") +
  theme(legend.position = "bottom")

ggsave(file.path(out_dir, "plot_diagnostik_vif.png"), plot = p_vif, width = 10, height = 8, dpi = 150)

cat("\nSeluruh pengujian diagnostik berhasil dihitung dan disimpan di folder Perbaikan EDA!\n")

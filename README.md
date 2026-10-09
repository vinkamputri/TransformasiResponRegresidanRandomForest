# Analisis Regresi Lanjutan: Transformasi Respon Box-Cox & Evaluasi Model Prediksi Konsumsi Energi Rumah Tangga

[![R Version](https://img.shields.io/badge/R-%3E%3D%204.0-blue.svg)](https://www.r-project.org/)
[![Shiny](https://img.shields.io/badge/Shiny-Live%20Dashboard-orange.svg)](https://vnka.shinyapps.io/dashboard_transformasi_respon_vinka_intania/)
[![Status](https://img.shields.io/badge/Status-Completed-success.svg)](#)
[![Institution](https://img.shields.io/badge/UNPAD-Universitas%20Padjadjaran-yellow.svg)](https://unpad.ac.id)

> **Proyek Akhir Mata Kuliah Analisis Regresi Lanjutan**  
> **Program Studi Statistika / Magister Statistika Terapan**  
> **Fakultas Matematika dan Ilmu Pengetahuan Alam (FMIPA) - Universitas Padjadjaran**  
> 
> **Penyusun:**  
> - **Vinka Marisa Putri**  
> - **Intania Bungan Apui**  

---

## 🌐 Live Interactive Dashboard
Dashboard interaktif visualisasi diagnostik regresi dan simulator prediksi 4 model dapat diakses secara daring melalui tautan berikut:  
👉 **[https://vnka.shinyapps.io/dashboard_transformasi_respon_vinka_intania/](https://vnka.shinyapps.io/dashboard_transformasi_respon_vinka_intania/)**

---

## 📌 Ringkasan Eksekutif (Executive Summary)

Dalam pemodelan regresi data deret waktu konsumsi energi (*Appliances Energy Prediction* - UCI Machine Learning Repository, $N = 19.735$), variabel respon beban daya peralatan rumah tangga ($Y$) memiliki distribusi menceng kanan ekstrem (*skewness* $+3.42$, *kurtosis* $16.51$). Penerapan model regresi linier standar (OLS) secara langsung menghasilkan pelanggaran asumsi klasik yang parah:
1. **Heteroskedastisitas Ekstrem**: Nilai Breusch-Pagan mencapai $827.18$ ($p < 0.001$), di mana varians residual melebar secara proporsional terhadap nilai prediksi (*funnel shape*).
2. **Residual Tidak Berdistribusi Normal**: Titik-titik residual pada Normal Q-Q plot melengkung tajam menjauhi garis diagonal teoretis.
3. **Multikolinearitas Tinggi**: Suhu luar ruangan (`T_out`) dan titik embun (`Tdewpoint`) memiliki VIF $> 80$ akibat korelasi termal lingkungan.
4. **Autokorelasi Positif**: Uji Durbin-Watson menunjukkan $\text{DW} = 0.3013$ ($p < 0.001$) karena adanya memori konsumsi energi pada interval 10 menit.

Untuk mengatasi permasalahan tersebut, dilakukan pemodelan terintegrasi dengan **Transformasi Respon Box-Cox** parameter optimal $\lambda = -0.531$ (mendekati invers akar kuadrat $Y^{-0.5}$) yang dikombinasikan dengan **Recursive Feature Elimination (RFE)** serta perbandingan terhadap algoritma ensemble **Random Forest**.

---

## 📊 Metodologi & Tahapan Analisis

```
┌────────────────────────────────────────┐
│     UCI Appliances Energy Dataset      │
│  (19.735 observasi, 29 fitur mentah)   │
└───────────────────┬────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────┐
│      Pembersihan & Feature Eng.        │
│   (Drop rv1/rv2 acak, ekstraksi waktu) │
└───────────────────┬────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────┐
│    Recursive Feature Elimination (RFE) │
│     Terpilih 26 Prediktor Optimal      │
└───────────────────┬────────────────────┘
                    │
          ┌─────────┴─────────┐
          ▼                   ▼
┌──────────────────┐ ┌───────────────────────────┐
│  Baseline OLS    │ │ Transformasi Box-Cox      │
│  (Skala Asli Wh) │ │ (λ = -0.531 -> Skala Z)   │
└─────────┬────────┘ └─────────────┬─────────────┘
          │                        │
          │                        ├──────────────────────────┐
          │                        ▼                          ▼
          │               ┌──────────────────┐      ┌──────────────────┐
          │               │  Box-Cox OLS     │      │ Random Forest    │
          │               │  (Diagnostik)    │      │ (Dengan Box-Cox) │
          │               └────────┬─────────┘      └────────┬─────────┘
          ▼                        │                         │
┌──────────────────────────────────┴─────────────────────────┴──────────┐
│ Evaluasi Performa 4 Model pada Testing Set Fisik Watt-hour (N = 4.907)│
└───────────────────────────────────────────────────────────────────────┘
```

### 1. Transformasi Respon Box-Cox
Formulasi Box-Cox standar yang diterapkan:
$$Y^{(\lambda)} = \begin{cases} \dfrac{Y^\lambda - 1}{\lambda \cdot \dot{y}^{\lambda - 1}}, & \lambda \neq 0 \\ \dot{y} \ln(Y), & \lambda = 0 \end{cases}$$

Estimasi *Maximum Likelihood Estimation* (MLE) menghasilkan parameter optimal **$\lambda = -0.531$**. Transformasi ini berhasil:
- Menormalkan *skewness* dari **$+3.42$** menjadi **$-0.06$** (hampir simetris sempurna).
- Menurunkan *kurtosis* dari **$16.51$** menjadi **$3.08$** (sangat mendekati distribusi normal teoretis $3.00$).

---

## 📈 Ringkasan Hasil Uji Asumsi Klasik OLS

| Asumsi Klasik | Metode Pengujian | OLS Baseline (Skala Asli) | Box-Cox OLS (Skala Z) | Kesimpulan |
|---|---|:---:|:---:|---|
| **Homoskedastisitas** | Breusch-Pagan Test | BP = 827.18 ($p < 0.001$) | BP = 67.44 ($p < 0.001$) | Heteroskedastisitas berkurang sangat drastis; pola residual vs fitted jauh lebih merata |
| **Normalitas Residual**| Skewness & Kurtosis | Skew = 2.45, Kurt = 11.23 | Skew = 0.12, Kurt = 3.25 | Residual Box-Cox mendekati garis lurus pada Normal Q-Q Plot |
| **Multikolinearitas** | Variance Inflation Factor (VIF) | 15 Prediktor $\text{VIF} > 10$ | 15 Prediktor $\text{VIF} > 10$ | Multikolinearitas tetap ada pada suhu internal/eksternal karena transformasi respon tidak mengubah matriks $\mathbf{X}$ |
| **Autokorelasi** | Durbin-Watson Test | $\text{DW} = 0.3013$ ($p < 0.001$) | $\text{DW} = 0.3421$ ($p < 0.001$) | Autokorelasi positif akibat dinamika deret waktu frekuensi tinggi (10 menit) |

---

## 🏆 Hasil Evaluasi Performa 4 Model (Testing Set $N = 4.907$)

Evaluasi performa dihitung setelah menginversi kembali seluruh prediksi ke **skala fisik nyata (Watt-hour / Wh)**:

| No | Model Prediksi | Skala Estimasi | RMSE (Wh) | MAE (Wh) | MAPE (%) | $R^2$ Skala Model |
|:---:|---|:---:|:---:|:---:|:---:|:---:|
| 1 | **Baseline OLS** | Skala Asli Wh | 92.45 | 50.82 | 61.16% | 17.28% |
| 2 | **Box-Cox OLS** | Skala $Z$ ($\lambda = -0.53$) | 96.12 | 44.15 | 38.45% | 31.22% |
| 3 | **Random Forest (Tanpa Box-Cox)** | Skala Asli Wh | 65.80 | 31.50 | 28.10% | 58.40% |
| 4 | **Random Forest (Dengan Box-Cox)** | Skala $Z$ ($\lambda = -0.53$) | **66.14** | **29.36** | **21.20%** | **72.46%** |

### 💡 Temuan Utama:
- **Box-Cox Memangkas Galat Relatif**: Transformasi Box-Cox memangkas persentase kesalahan relatif (MAPE) dari **$61.16\%$** menjadi **$38.45\%$** pada model linier OLS, dan mencapai rekor terendah **$21.20\%$** pada Random Forest.
- **Random Forest Box-Cox Merupakan Model Terbaik**: Menghasilkan MAE terendah ($29.36\text{ Wh}$) dan $R^2$ skala model tertinggi ($72.46\%$), menjadikannya model paling akurat untuk mengestimasi beban konsumsi listrik rumah pintar (*smart home*).

---

## 📁 Struktur Berkas Repository

```
├── README.md                                                     <- Dokumentasi utama repository GitHub
├── .gitignore                                                    <- Berkas pengabaian file sementara R & binary besar
├── analisis_full_eda_rfe_rf_boxcox_dan_diagnostik.Rmd            <- Skrip lengkap analisis R Markdown
├── analisis_full_eda_rfe_rf_boxcox_dan_diagnostik.html           <- Laporan interaktif standalone HTML
├── jalankan_diagnostik_eda_lengkap.R                             <- Skrip eksekusi analisis diagnostik
├── hitung_uji_autokorelasi.R                                     <- Skrip uji autokorelasi residual
├── publish_to_shinyapps.R                                        <- Skrip deploy aplikasi ke shinyapps.io
├── Laporan Akhir Tugas Transformasi Respon Vinka dan Intania.pdf <- Dokumen laporan akhir formal (PDF)
├── File Presentasi Akhir Transformasi Respons...slide fix.pptx   <- Slide materi presentasi akhir (PPTX)
│
├── shiny_app/                                                    <- Direktori Dashboard R Shiny
│   ├── app.R                                                     <- Antarmuka (UI) & server logic Shiny
│   ├── generate_shiny_data.R                                     <- Skrip regenerasi data precomputed RDS
│   └── www/
│       └── logo-unpad1.png                                       <- Logo resmi Universitas Padjadjaran
│
├── plots/                                                        <- Ekspor grafik diagnostik model (PNG)
│   ├── plot_diagnostik_residual_vs_fitted.png
│   ├── plot_diagnostik_qq_residual.png
│   ├── plot_diagnostik_cooks_distance.png
│   ├── plot_diagnostik_vif.png
│   └── plot_diagnostik_acf_residual.png
│
└── tabel_output/                                                 <- Ekspor tabel pengujian numerik (CSV)
    ├── tabel_uji_heteroskedastisitas.csv
    ├── tabel_uji_normalitas_residual.csv
    ├── tabel_vif_multikolinearitas.csv
    ├── tabel_uji_autokorelasi.csv
    └── tabel_pengamatan_berpengaruh.csv
```

---

## 💻 Panduan Replikasi (How to Run Locally)

### 1. Kloning Repository
```bash
git clone https://github.com/<username>/<repo-name>.git
cd <repo-name>
```

### 2. Instalasi Paket R yang Diperlukan
Jalankan perintah berikut di console R / RStudio:
```r
install.packages(c(
  "shiny", "bslib", "ggplot2", "dplyr", "lubridate",
  "MASS", "randomForest", "car", "lmtest", "base64enc", "rsconnect"
))
```

### 3. Menjalankan Dashboard Shiny Secara Lokal
```r
shiny::runApp("shiny_app")
```
Aplikasi akan membuka antarmuka bernuansa putih-oranye dengan panel kontrol simulator konsumsi daya peralatan.

### 4. Merender Dokumen R Markdown
```r
rmarkdown::render("analisis_full_eda_rfe_rf_boxcox_dan_diagnostik.Rmd")
```

---

## 📜 Lisensi & Kontak
Proyek ini dibuat untuk keperluan akademis mata kuliah **Analisis Regresi Lanjutan**, Departemen Statistika, Fakultas MIPA, Universitas Padjadjaran.  
Lisensi: **MIT License**.

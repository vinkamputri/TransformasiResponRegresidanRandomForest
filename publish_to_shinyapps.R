

library(rsconnect)

# 1. Konfigurasi Autentikasi Akun (Mengambil dari Environment atau Konsol)
account_name   <- Sys.getenv("SHINYAPPS_NAME", unset = "")
account_token  <- Sys.getenv("SHINYAPPS_TOKEN", unset = "")
account_secret <- Sys.getenv("SHINYAPPS_SECRET", unset = "")

if (nzchar(account_token) && nzchar(account_secret)) {
  rsconnect::setAccountInfo(
    name   = account_name,
    token  = account_token,
    secret = account_secret
  )
}

# 2. Direktori Aplikasi Shiny (Menggunakan path relatif portabel)
app_dir <- if (dir.exists("shiny_app")) "shiny_app" else "."

# Opsi batas ukuran bundle untuk file model
options(rsconnect.max.bundle.size = 3145728000)

# 3. Proses Deploy ke shinyapps.io
message("Memulai proses deployment ke shinyapps.io...")
rsconnect::deployApp(
  appDir      = app_dir,
  appName     = "<isikan disini>",
  appTitle    = "<isikan disini>",
  forceUpdate = TRUE
)

message("Deploy berhasil diselesaikan!")

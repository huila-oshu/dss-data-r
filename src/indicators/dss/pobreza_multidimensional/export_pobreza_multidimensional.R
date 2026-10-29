# Run from the package root: Rscript src/indicators/dss/pobreza_multidimensional/export_pobreza_multidimensional.R
library(readxl)
library(dplyr)
library(tidyr)

local({
  source(here::here("src", "indicators", "dss", "pobreza_multidimensional", "pobreza_multidimensional.R"), local = TRUE)
  stopifnot(nrow(IPM_Huila_total) == 8L,
            all(IPM_Huila_total$Departamento == "Huila"),
            identical(as.numeric(IPM_Huila_total$anio), as.numeric(2018:2025)),
            !anyNA(IPM_Huila_total$valor),
            all(IPM_Huila_total$valor >= 0 & IPM_Huila_total$valor <= 100))
  csv_dir <- here::here("outputs", "csv")
  parquet_dir <- here::here("outputs", "parquet")
  dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(parquet_dir, recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(IPM_Huila_total, file.path(csv_dir, "pobreza_multidimensional_huila_total.csv"))
  arrow::write_parquet(IPM_Huila_total, file.path(parquet_dir, "pobreza_multidimensional_huila_total.parquet"))
})

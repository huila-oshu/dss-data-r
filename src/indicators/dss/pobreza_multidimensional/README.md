# Huila multidimensional poverty: departmental total

Source: DANE, https://www.dane.gov.co/files/operaciones/PM/anex-PMultidimensional-Departamental-2025.xlsx
Sheet: `IPM_Departamentos`; range: `A14:Y46`.
Territory: Huila. Years: 2018–2025. Unit: percent.

`pobreza_multidimensional.R` is the uploaded user script, preserved byte for byte.
It selects the Total columns; it does not export the urban/rural series.
Run from the package root:

```sh
Rscript src/indicators/dss/pobreza_multidimensional/export_pobreza_multidimensional.R
```

The executor loads readxl, dplyr and tidyr, then exports using the existing here, readr and arrow dependencies.
Outputs: `outputs/csv/pobreza_multidimensional_huila_total.csv` and `outputs/parquet/pobreza_multidimensional_huila_total.parquet`.
Columns: Departamento (string), anio (numeric), valor (numeric percentage).

Validation on 2026-10-29: downloaded the official workbook, verified a single Huila row and eight total observations, checked non-missing values in [0,100], and verified Parquet round-trip equality. R is unavailable in the execution environment: the initial outputs were extracted with Python/openpyxl and pandas/pyarrow using exactly the same range, row filter and Total column positions as the supplied R script. The R executor has not been executed.
Source workbook SHA-256: 73caab08046d6b35f80326b1b6f2e9b1cb8ad75a2ac4946515fda320ffaaf447.

These files are versioned at the user's explicit request. They do not replace the existing `pobreza_huila_oshu` dataset. Dashboard integration and batch registry integration are not included; no automatic synchronization to huila-oshu/tablero is configured by this change.

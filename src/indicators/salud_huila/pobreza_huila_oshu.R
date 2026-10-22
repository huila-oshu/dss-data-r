# ================================================
# DSS Indicator: Pobreza - Huila
# ================================================
# Source: Observatorio de Salud del Huila
# Indicator: Pobreza Multidimensional
# Stratifier: Area, sexo, jefe del hogar,
#             privaciones y dimensiones
# ================================================

library(writexl)
library(here)
library(readxl)
library(dplyr)
library(arrow)
library(readr)
library(fs)
library(glue)


process_pobreza_huila <- function(output_dir = here("outputs")) {
  
  # ================================================
  # 1. Load data
  # ================================================
  
  archivo <- here("datos", "ipm_huila.xlsx")
  
  if (!file.exists(archivo)) {
    stop(glue("❌ File not found: {archivo}"))
  }
  
  message("📥 Loading poverty data from Huila Observatory...")
  
  # Identify Excel sheets
  hojas <- readxl::excel_sheets(archivo)
  
  # Load all Excel sheets
  ipm_completo <- lapply(
    hojas,
    function(hoja) {
      
      readxl::read_excel(
        archivo,
        sheet = hoja,
        col_names = hoja != "Fuentes"
      )
      
    }
  )
  
  names(ipm_completo) <- hojas
  
  message(glue("✅ Loaded {length(hojas)} Excel sheets"))
  
  
  # ================================================
  # 2. Processing data
  # ================================================
  
  message("📋 Processing poverty data...")
  
  # Function to standardize variables
  procesar_hoja <- function(
    hoja,
    columna_valor,
    medida,
    tipo_desagregacion,
    columna_area = NULL,
    columna_sexo = NULL,
    columna_jefe = NULL,
    columna_privaciones = NULL,
    columna_dimension = NULL) {
    
    datos <- ipm_completo[[hoja]]
    
    if (is.null(datos)) {
      stop(glue("❌ Sheet not found: {hoja}"))
    }
    
    # Validate required columns
    columnas_requeridas <- c(
      "Territorio",
      "Año",
      columna_valor,
      columna_area,
      columna_sexo,
      columna_jefe,
      columna_privaciones,
      columna_dimension
    )
    
    faltantes <- setdiff(
      columnas_requeridas,
      names(datos)
    )
    
    if (length(faltantes) > 0) {
      stop(
        glue(
          "❌ Missing columns in {hoja}: ",
          "{paste(faltantes, collapse = ', ')}"
        )
      )
    }
    
    # Extract stratification variables
    obtener_variable <- function(columna) {
      
      if (is.null(columna)) {
        return(rep(NA_character_, nrow(datos)))
      }
      
      as.character(datos[[columna]])
    }
    
    # Estandarizar los valores porcentuales
    valores <- as.numeric(datos[[columna_valor]])
    
    # Convertir proporciones a porcentajes en IPM área
    if (hoja == "IPM área") {
      valores <- valores * 100
    }
    
    # Standardized structure
    resultado <- data.frame(
      iso3 = "COL",
      territorio = as.character(datos[["Territorio"]]),
      anio = as.integer(datos[["Año"]]),
      sexo = obtener_variable(columna_sexo),
      area = obtener_variable(columna_area),
      sexo_jefe_hogar = obtener_variable(columna_jefe),
      privaciones = obtener_variable(columna_privaciones),
      dimension = obtener_variable(columna_dimension),
      valor = valores,
      indicador = "Pobreza multidimensional",
      medida = medida,
      tipo_desagregacion = tipo_desagregacion,
      hoja_origen = hoja
    )
    
    return(resultado)
  }
  
  
  # ================================================
  # 3. Process poverty indicator
  # ================================================
  
  ipm <- dplyr::bind_rows(
    
    # IPM by area
    procesar_hoja(
      hoja = "IPM área",
      columna_valor = "Porcentaje de Pobreza Multidimensional",
      medida = "Incidencia del IPM",
      tipo_desagregacion = "Área",
      columna_area = "Área"
    ),
    
    # IPM by sex
    procesar_hoja(
      hoja = "IPM sexo",
      columna_valor = "Porcentaje de Pobreza Multidimensional según sexo",
      medida = "Incidencia del IPM",
      tipo_desagregacion = "Sexo",
      columna_sexo = "Sexo"
    ),
    
    # IPM by sex of household head
    procesar_hoja(
      hoja = "IPM jefe sexo",
      columna_valor = "Porcentaje de Pobreza Multidimensional según sexo del jefe de hogar",
      medida = "Incidencia del IPM",
      tipo_desagregacion = "Sexo del jefe del hogar",
      columna_jefe = "Sexo del jefe del hogar"
    ),
    
    # IPM by household deprivations
    procesar_hoja(
      hoja = "IPM privaciones",
      columna_valor = "Porcentaje de Pobreza Multidimensional",
      medida = "Porcentaje de privación",
      tipo_desagregacion = "Privaciones por hogar y área",
      columna_area = "Área",
      columna_privaciones = "Privaciones por hogar"
    ),
    
    # Total deprivations
    procesar_hoja(
      hoja = "IPM privaciones total",
      columna_valor = "Porcentaje de privaciones entre las personas en situación de pobreza multidimensional",
      medida = "Porcentaje de privaciones en personas en pobreza multidimensional",
      tipo_desagregacion = "Sin desagregación"
    ),
    
    # Contributions by dimension
    procesar_hoja(
      hoja = "IPM contribuciones",
      columna_valor = "Porcentaje de Contribuciones",
      medida = "Contribución por dimensión al IPM",
      tipo_desagregacion = "Dimensión",
      columna_dimension = "Dimensión"
    )
    
  )
  
  
  # ================================================
  # 4. Organize variables
  # ================================================
  
  ipm <- ipm |>
    select(
      iso3,
      territorio,
      anio,
      sexo,
      area,
      sexo_jefe_hogar,
      privaciones,
      dimension,
      valor,
      indicador,
      medida,
      tipo_desagregacion,
      hoja_origen
    ) |>
    arrange(
      anio,
      hoja_origen
    )
  
  
  # ================================================
  # 5. Create output directories
  # ================================================
  
  dir_create(file.path(output_dir, "csv"))
  dir_create(file.path(output_dir, "parquet"))
  
  
  # ================================================
  # 6. Save outputs
  # ================================================

  pobreza_csv_file <- file.path(output_dir, "csv", "pobreza_huila_oshu.csv")
  pobreza_parquet_file <- file.path(output_dir, "parquet", "pobreza_huila_oshu.parquet")

  # Export consolidated data
  write_csv(ipm, pobreza_csv_file)
  write_parquet(ipm, pobreza_parquet_file)

  # ================================================
  # Export Excel with multiple sheets
  # ================================================
  
  # Create Excel directory
  dir_create(file.path(output_dir, "excel"))
  
  # Excel file path
  pobreza_excel_file <- file.path(
    output_dir,
    "excel",
    "pobreza_huila_oshu.xlsx"
  )
  
  # Consolidated data and original Excel sheets
  hojas_excel <- c(
    list("Consolidado" = ipm),
    ipm_completo
  )
  
  # Organize source information
  if ("Fuentes" %in% names(hojas_excel)) {
    if (ncol(hojas_excel[["Fuentes"]]) == 1) {
      names(hojas_excel[["Fuentes"]]) <- "Fuente"
    }
  }
  
  # Save Excel workbook
  write_xlsx(
    hojas_excel,
    pobreza_excel_file
  )
  
  message(glue("💾 Excel: {pobreza_excel_file}"))
  
  # ================================================
  # 7. Save source information
  # ================================================
  
  fuentes_file <- file.path(
    output_dir,
    "fuentes_pobreza_huila_oshu.txt"
  )
  
  fuentes <- ipm_completo[["Fuentes"]]
  
  if (!is.null(fuentes)) {
    
    fuentes_texto <- as.character(
      unlist(fuentes, use.names = FALSE)
    )
    
    fuentes_texto <- fuentes_texto[
      !is.na(fuentes_texto)
    ]
    
    writeLines(
      fuentes_texto,
      fuentes_file,
      useBytes = TRUE
    )
    
  }
  
  
  # ================================================
  # 8. Processing summary
  # ================================================
  
  message(glue("✅ Processed {nrow(ipm)} rows"))
  message(glue("📅 Years: {min(ipm$anio, na.rm = TRUE)} - {max(ipm$anio, na.rm = TRUE)}"))
  message(glue("📊 Indicator: Pobreza multidimensional"))
  message(glue("📁 Excel sheets: {length(ipm_completo)}"))
  message(glue("📊 Data sheets: {length(ipm_completo) - 1}"))
  message(glue("💾 CSV: {pobreza_csv_file}"))
  message(glue("💾 Parquet: {pobreza_parquet_file}"))
  
  
  # ================================================
  # 9. Return results
  # ================================================
  
  return(list(
    data = ipm,
    hojas = ipm_completo,
    output_files = c(
      pobreza_csv_file,
      pobreza_parquet_file,
      pobreza_excel_file,
      fuentes_file
    )
  ))
  
}


# ================================================
# Main execution - called from Turborepo
# or command line
# ================================================

if (!interactive()) {
  
  result <- process_pobreza_huila()
  
  cat("✅ Poverty (Huila) processing completed\n")
  
}
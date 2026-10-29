url="https://www.dane.gov.co/files/operaciones/PM/anex-PMultidimensional-Departamental-2025.xlsx"
archivo2 = tempfile(fileext = ".xlsx")
download.file(
  url = url,
  destfile = archivo2,
  mode = "wb"
)
IPM=read_excel(archivo2, sheet="IPM_Departamentos",range="A14:Y46",col_names = FALSE)
names(IPM) <- c(
  "Departamento",
  
  "2018_Total", "2018_Cabecera", "2018_Rural",
  "2019_Total", "2019_Cabecera", "2019_Rural",
  "2020_Total", "2020_Cabecera", "2020_Rural",
  "2021_Total", "2021_Cabecera", "2021_Rural",
  "2022_Total", "2022_Cabecera", "2022_Rural",
  "2023_Total", "2023_Cabecera", "2023_Rural",
  "2024_Total", "2024_Cabecera", "2024_Rural",
  "2025_Total", "2025_Cabecera", "2025_Rural"
)

IPM_Huila_total=IPM %>% 
  filter(Departamento=="Huila" ) %>% 
  select(Departamento, ends_with("_Total")) %>% 
  pivot_longer(
    cols=ends_with("_Total"),
    names_to="anio",
    values_to="valor"
  ) %>% 
  mutate(anio=as.numeric(gsub("_Total","",anio)),
         valor=as.numeric(valor)
  )


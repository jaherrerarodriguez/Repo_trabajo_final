library(sparr)

# Cargar el set de datos de fiebre aftosa
data(fmd)

# Ver el resumen de casos y controles
summary(fmd$cases)
summary(fmd$controls)

# Graficar los puntos en el espacio
plot(fmd$cases, main = "Casos de Fiebre Aftosa (2001)")
plot(fmd$controls, main = "Controles")



# Convertir los casos a dataframe y agregar la columna estatus
df_cases <- data.frame(
  x = fmd$cases$x,
  y = fmd$cases$y,
  estatus = "caso"
)

# Convertir los controles a dataframe y agregar la columna estatus
df_controls <- data.frame(
  x = fmd$controls$x,
  y = fmd$controls$y,
  estatus = "control"
)

# Unir ambos dataframes en uno solo
fmd_completo <- rbind(df_cases, df_controls)

# Ver las primeras filas y la estructura del resultado
head(fmd_completo)
table(fmd_completo$estatus)

library(rio)

export(fmd_completo, "fmd_completo.csv")

# Cargar librerías necesarias
library(tidyverse)

# Configurar una semilla para reproducibilidad
set.seed(2026)

 
# Asegúrate de que las columnas se llamen exactamente: x, y, estatus
df_original <- read.csv("fmd_completo.csv", stringsAsFactors = FALSE)

# Estandarizar la columna estatus a minúsculas para evitar errores de escritura
df_original <- df_original %>% 
  mutate(estatus = tolower(trimws(estatus)))

# Número de filas (debe ser 2276)
n_registros <- nrow(df_original)



df_simulado <- df_original %>%
  mutate(
    # Crear ID Único
    ID_Predio = sprintf("P%04d", row_number()),
    
    # Monoespecie o Multiespecie
    Tipo_Explotacion = sample(c("Monoespecie", "Multiespecie"), n_registros, replace = TRUE, prob = c(0.4, 0.6)),
    
    # Simulación de censos
    Bovinos_Adultos = round(rlnorm(n_registros, meanlog = 3.5, sdlog = 1.0)),
    Bovinos_Jovenes = round(Bovinos_Adultos * runif(n_registros, 0.4, 0.8)),
    
    Ovinos_Adultos  = round(rlnorm(n_registros, meanlog = 4.5, sdlog = 1.2)),
    Ovinos_Jovenes  = round(Ovinos_Adultos * runif(n_registros, 0.6, 1.2)),
    
    Porcinos_Adultos = round(rlnorm(n_registros, meanlog = 2.5, sdlog = 1.5)),
    Porcinos_Jovenes = round(Porcinos_Adultos * runif(n_registros, 2.0, 5.0)),
    
    # Especies NO susceptibles
    Aves    = round(ifelse(runif(n_registros) > 0.7, rlnorm(n_registros, 5, 2), 0)),
    Equinos = round(ifelse(runif(n_registros) > 0.5, rpois(n_registros, lambda = 3), 0))
  ) %>%
  # Forzar que los "caso" tengan especies susceptibles
  mutate(
    Bovinos_Adultos = ifelse(estatus == "caso" & (Bovinos_Adultos + Ovinos_Adultos + Porcinos_Adultos) == 0, sample(20:100, 1), Bovinos_Adultos),
    Bovinos_Jovenes = ifelse(estatus == "caso" & Bovinos_Adultos > 0 & Bovinos_Jovenes == 0, round(Bovinos_Adultos * 0.5), Bovinos_Jovenes)
  ) %>%
  # Si se definió como Monoespecie, nos quedamos con una sola especie dominante
  rowwise() %>%
  mutate(
    tot_bov = Bovinos_Adultos + Bovinos_Jovenes,
    tot_ovi = Ovinos_Adultos + Ovinos_Jovenes,
    tot_por = Porcinos_Adultos + Porcinos_Jovenes,
    
    # Identificar cuál es la especie con más animales en este predio
    Especie_Principal = case_when(
      tot_bov >= tot_ovi & tot_bov >= tot_por ~ "Bovinos",
      tot_ovi >= tot_bov & tot_ovi >= tot_por ~ "Ovinos",
      TRUE ~ "Porcinos"
    )
  ) %>%
  ungroup() %>%
  mutate(
    # Si es Monoespecie, ponemos en 0 las otras especies susceptibles que no sean la principal
    # (Para los casos positivos, conservamos al menos la especie principal)
    Bovinos_Adultos = ifelse(Tipo_Explotacion == "Monoespecie" & Especie_Principal != "Bovinos", 0, Bovinos_Adultos),
    Bovinos_Jovenes = ifelse(Tipo_Explotacion == "Monoespecie" & Especie_Principal != "Bovinos", 0, Bovinos_Jovenes),
    Ovinos_Adultos  = ifelse(Tipo_Explotacion == "Monoespecie" & Especie_Principal != "Ovinos", 0, Ovinos_Adultos),
    Ovinos_Jovenes  = ifelse(Tipo_Explotacion == "Monoespecie" & Especie_Principal != "Ovinos", 0, Ovinos_Jovenes),
    Porcinos_Adultos = ifelse(Tipo_Explotacion == "Monoespecie" & Especie_Principal != "Porcinos", 0, Porcinos_Adultos),
    Porcinos_Jovenes = ifelse(Tipo_Explotacion == "Monoespecie" & Especie_Principal != "Porcinos", 0, Porcinos_Jovenes)
  ) %>%
  # Orientación Productiva basada en la Especie Principal
  mutate(
    orientacion_productiva = case_when(
      (Bovinos_Adultos + Bovinos_Jovenes) > 0 & Especie_Principal == "Bovinos" ~ sample(c("Bov_Carne", "Bov_Leche", "Bov_Mixto"), n(), replace = TRUE, prob = c(0.4, 0.4, 0.2)),
      (Ovinos_Adultos + Ovinos_Jovenes) > 0 & Especie_Principal == "Ovinos"   ~ sample(c("Ovi_Carne", "Ovi_Lana", "Ovi_Mixto"), n(), replace = TRUE, prob = c(0.5, 0.3, 0.2)),
      TRUE ~ "Mixtos"
    )
  ) %>%
  # Limpiar columnas temporales de cálculo
  select(-tot_bov, -tot_ovi, -tot_por, -Especie_Principal)



fecha_inicio_brote <- as.Date("2001-02-15")

df_simulado <- df_simulado %>%
  mutate(
    Fecha_Sospecha = as.Date(ifelse(estatus == "caso", fecha_inicio_brote + round(rgamma(n_registros, shape = 4, scale = 10)), NA), origin = "1970-01-01"),
    Fecha_Positividad = as.Date(ifelse(estatus == "caso", Fecha_Sospecha + sample(1:4, n_registros, replace = TRUE), NA), origin = "1970-01-01"),
    
    Sacrificio_Contiguo = ifelse(estatus == "control" & runif(n_registros) < 0.15, TRUE, FALSE),
    
    Fecha_Sacrificio = as.Date(case_when(
      estatus == "caso" ~ Fecha_Positividad + sample(1:2, n_registros, replace = TRUE),
      Sacrificio_Contiguo ~ fecha_inicio_brote + sample(20:60, n_registros, replace = TRUE),
      TRUE ~ NA
    ), origin = "1970-01-01"),
    
    Bovinos_Afectados = ifelse(estatus == "caso" & (Bovinos_Adultos + Bovinos_Jovenes) > 0, round((Bovinos_Adultos + Bovinos_Jovenes) * runif(n_registros, 0.1, 0.6)), 0),
    Ovinos_Afectados  = ifelse(estatus == "caso" & (Ovinos_Adultos + Ovinos_Jovenes) > 0, round((Ovinos_Adultos + Ovinos_Jovenes) * runif(n_registros, 0.05, 0.3)), 0),
    Porcinos_Afectados = ifelse(estatus == "caso" & (Porcinos_Adultos + Porcinos_Jovenes) > 0, round((Porcinos_Adultos + Porcinos_Jovenes) * runif(n_registros, 0.2, 0.8)), 0)
  ) %>%
  select(-Sacrificio_Contiguo)

# Agrega parámetros de red

df_simulado <- df_simulado %>%
  mutate(
    In_Degree  = round(rlnorm(n_registros, meanlog = 1.2, sdlog = 0.6) + (estatus == "caso") * runif(n_registros, 1, 5)),
    Out_Degree = round(rlnorm(n_registros, meanlog = 1.1, sdlog = 0.6) + (estatus == "caso") * runif(n_registros, 1, 6)),
    
    Ingoing_Contact_Chain  = round(In_Degree * runif(n_registros, 2, 8)),
    Outgoing_Contact_Chain = round(Out_Degree * runif(n_registros, 2, 10)),
    
    Betweenness_Centrality = round(runif(n_registros, 0, 0.05) + (estatus == "caso") * runif(n_registros, 0, 0.25), 5),
    Closeness_Centrality   = round(runif(n_registros, 0.1, 0.4) + (estatus == "caso") * runif(n_registros, 0, 0.2), 5)
  ) %>%
  mutate(
    Betweenness_Centrality = pmin(Betweenness_Centrality, 1),
    Closeness_Centrality   = pmin(Closeness_Centrality, 1)
  )

# Exporta archivo final

write.csv(df_simulado, "fmd_2001_simulado_completo.csv", row.names = FALSE)

cat("¡Simulación modificada con éxito! Archivo guardado como 'fmd_2001_simulado_completo.csv'\n")


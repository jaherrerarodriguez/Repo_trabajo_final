


library(tidyverse)

# 2. Cargar los datos simulados 
df <- read.csv("fmd_2001_simulado_completo.csv", stringsAsFactors = FALSE)


df_totales <- df %>%
  mutate(
    Bovinos   = Bovinos_Adultos + Bovinos_Jovenes,
    Ovinos    = Ovinos_Adultos + Ovinos_Jovenes,
    Porcinos  = Porcinos_Adultos + Porcinos_Jovenes,
    Aves      = Aves,
    Equinos   = Equinos
  ) %>%
  select(estatus, Bovinos, Ovinos, Porcinos, Aves, Equinos)


df_largo <- df_totales %>%
  pivot_longer(cols = -estatus, names_to = "Especie", values_to = "Poblacion")



# Construir el gráfico de violín agrupando por Especie y dividiendo por Estatus
grafico_violines_todos <- ggplot(df_largo, aes(x = Especie, y = log1p(Poblacion), fill = estatus)) +
  geom_violin(alpha = 0.6, position = position_dodge(0.8), color = "black") +
  geom_boxplot(width = 0.1, position = position_dodge(0.8), color = "black", outlier.shape = NA) +
  scale_fill_manual(values = c("caso" = "#d95f02", "control" = "#7570b3")) +
  labs(
    title = "EDA Inicial: Distribución de Poblaciones Pre-Brote (Todas las Especies)",
    x = "Especie",
    y = "Población (Escala Logarítmica log1p)",
    fill = "Estatus"
  ) +
  theme_minimal() +
  theme(legend.position = "top")

# Mostrar el gráfico en la pestaña 'Plots' de RStudio
print(grafico_violines_todos)



# Calcular las medidas
tabla_descriptiva <- df_largo %>%
  group_by(estatus, Especie) %>%
  summarise(
    Predios_Con_Animales = sum(Poblacion > 0),
    Media_Poblacion      = mean(Poblacion),
    Desviacion_Estandar  = sd(Poblacion),
    Minimo               = min(Poblacion),
    Mediana              = median(Poblacion),
    Maximo               = max(Poblacion),
    .groups = "drop"
  ) %>%
  # Ordenar  por especie y luego por estatus 
  arrange(Especie, estatus)



print(as.data.frame(tabla_descriptiva), row.names = FALSE)



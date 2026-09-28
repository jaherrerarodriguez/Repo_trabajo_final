# Base de Datos Simulada: Epidemia de Fiebre Aftosa (FMD)

## 1. Origen de los Datos Primarios
Los datos base utilizados para esta simulación provienen del paquete estadístico **`sparr`** (Spatial Relative Risk) del entorno de programación **R**. Específicamente, se extrajo el conjunto de datos de puntos espaciales denominado **`fmd`**, el cual registra las coordenadas geográficas de los predios ganaderos y su estatus epidemiológico real durante el brote histórico de Fiebre Aftosa (FMD) ocurrido en el Reino Unido (UK) en el año 2001.

La base original cuenta con **2,276 registros** y consta estrictamente de tres variables empíricas:
*   `x`: Coordenada de longitud / proyección este (coordenadas planas).
*   `y`: Coordenada de latitud / proyección norte (coordenadas planas).
*   `estatus`: Condición sanitaria del predio categorizada en **caso** (Infected Premises - IP) o **control** (Susceptible).

---

## 2. Metodología de Simulación y Enriquecimiento
Con el objetivo de evaluar un plan de trabajo de investigación epidemiológica y control sanitario, se desarrolló un script estocástico en R para simular una estructura poblacional pre-brote, una cronología epidemiológica coherente y métricas de Análisis de Redes Sociales (SNA) de movimiento de ganado. Los datos simulados no buscaron en ningún momento recrear la situación real de los predios de Reino Unido al momento del caso de FMD en el año 2001.

El proceso de simulación aplicó las siguientes reglas biológicas y matemáticas:

### A. Estructura Poblacional Pre-Brote (Censo Base)
*   **Tipo de Explotación:** Clasificación de los predios en *Monoespecie* (40%) o *Multiespecie* (60%).
*   **Distribución Pecuaria:** Simulación de censos iniciales de animales mediante distribuciones log-normales y de Poisson para emular la heterogeneidad real del campo:
    *   **Especies Susceptibles a FMD:** Bovinos (Adultos/Jóvenes), Ovinos (Adultos/Jóvenes) y Porcinos (Adultos/Jóvenes).
    *   **Especies No Susceptibles :** Aves y Equinos.
*   **Consistencia Biológica:** Se forzó a que el 100% de los registros catalogados como `caso` contaran obligatoriamente con una población base de especies susceptibles superior a cero. Para los predios asignados como `Monoespecie`, se eliminó cualquier población secundaria para preservar la condición del sistema productivo.
*   **Orientación Productiva:** Se categorizó automáticamente al azar cada predio según su inventario dominante en: `Bov_Carne`, `Bov_Leche`, `Bov_Mixto`, `Ovi_Carne`, `Ovi_Lana`, `Ovi_Mixto` o `Mixtos`.

### B. Cronología y Dinámica del Brote
*   **Lógica Temporal:** Se estableció el inicio del brote simulado el 15 de febrero de 2001. Las fechas de sospecha siguen una distribución Gamma para emular una curva epidémica natural de tres meses.
*   **Políticas de Control Sanitario :**
    *   Para los **casos**, la fecha de positividad se fijó entre 1 y 4 días post-sospecha, y la fecha de sacrificio obligatorio (*culling*) ocurrió estrictamente dentro de las 24-48 horas posteriores.
    *   Para los **controles**, se simuló de forma realista una tasa del 15% de sacrificio preventivo por vecindad (*Ring Culling* o Sacrificio Contiguo).
*   **Animales Afectados:** El volumen de animales enfermos en los focos se extrajo de forma estocástica (proporciones del censo inicial) sin superar jamás la población base disponible en el predio.

### C. Parámetros de Análisis de Redes (SNA)
Para evaluar la conectividad comercial como factor de riesgo, se simularon métricas estáticas ponderadas según el estatus epidemiológico (asumiendo que los nodos infectados poseen mayor centralidad comercial):
*   `In_Degree` / `Out_Degree`: Volumen de predios origen/destino con transacciones directas.
*   `Ingoing_Contact_Chain` (ICC) / `Outgoing_Contact_Chain` (OCC): Cadenas de contacto indirecto acumuladas en la red.
*   `Betweenness_Centrality` / `Closeness_Centrality`: Índices normalizados (0-1) para identificar puentes epidemiológicos y velocidades de difusión teóricas.

---

## 3. Diccionario de Datos del Archivo Final (`fmd_simulado_completo.csv`)

| Nombre de la Columna | Tipo de Dato | Descripción |
| :--- | :--- | :--- |
| **x** | Numérico | Coordenada espacial X (Origen: paquete `sparr`). |
| **y** | Numérico | Coordenada espacial Y (Origen: paquete `sparr`). |
| **estatus** | Carácter | Clasificación sanitaria original: `caso` o `control`. |
| **ID_Predio** | Carácter | Identificador único secuencial del predio (P0001 - P2276). |
| **Tipo_Explotacion** | Carácter | Sistema de producción: `Monoespecie` o `Multiespecie`. |
| **Bovinos_Adultos** | Entero | Número de bovinos adultos en el censo pre-brote. |
| **Bovinos_Jovenes** | Entero | Número de bovinos jóvenes en el censo pre-brote. |
| **Ovinos_Adultos** | Entero | Número de ovinos adultos en el censo pre-brote. |
| **Ovinos_Jovenes** | Entero | Número de ovinos jóvenes en el censo pre-brote. |
| **Porcinos_Adultos** | Entero | Número de porcinos adultos en el censo pre-brote. |
| **Porcinos_Jovenes** | Entero | Número de porcinos jóvenes en el censo pre-brote. |
| **Aves** | Entero | Población avícola (fómite mecánico potencial). |
| **Equinos** | Entero | Población de equinos (fómite mecánico potencial). |
| **orientacion_productiva**| Carácter | Especialización comercial del predio según su censo mayoritario. |
| **Fecha_Sospecha** | Fecha (AAAA-MM-DD)| Fecha en que se notifica la sospecha oficial (Solo casos). |
| **Fecha_Positividad** | Fecha (AAAA-MM-DD)| Fecha de confirmación laboratorial del virus (Solo casos). |
| **Fecha_Sacrificio** | Fecha (AAAA-MM-DD)| Fecha de despoblación sanitaria (Casos y Contiguos). |
| **Bovinos_Afectados** | Entero | Cantidad de bovinos clínicamente afectados/enfermos. |
| **Ovinos_Afectados** | Entero | Cantidad de ovinos clínicamente afectados/enfermos. |
| **Porcinos_Afectados** | Entero | Cantidad de porcinos clínicamente afectados/enfermos. |
| **In_Degree** | Entero | Número de predios proveedores directos de ganado. |
| **Out_Degree** | Entero | Número de predios compradores directos de ganado. |
| **Ingoing_Contact_Chain** | Entero | Alcance total de la cadena de movimientos de entrada. |
| **Outgoing_Contact_Chain**| Entero | Alcance total de la cadena de movimientos de salida. |
| **Betweenness_Centrality**| Numérico (0-1) | Centralidad de intermediación (Importancia como puente vial). |
| **Closeness_Centrality**  | Numérico (0-1) | Centralidad de cercanía (Proximidad promedio a la red). |

---
## 4. Uso Previsto
Este conjunto de datos está diseñado exclusivamente para fines académicos y de simulación metodológica. Permite validar algoritmos de detección temprana, evaluar planes de contingencia basados en la estructura de redes (SNA) y entrenar modelos predictivos de regresión o machine learning para la identificación de factores de riesgo ambientales y comerciales en enfermedades vesiculares transfronterizas.

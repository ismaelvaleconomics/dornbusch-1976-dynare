# DORNBUSCH (1976) — IMPLEMENTACION EN MATLAB/DYNARE
> "Expectations and Exchange Rate Dynamics"  
> Rudiger Dornbusch, *Journal of Political Economy*, Vol. 84, No. 6 (1976)

---

## Archivos incluidos

| Archivo | Descripción |
|--------|-------------|
| `run_dornbusch.m` | Punto de entrada. Correr este script primero. |
| `dornbusch_baseline.mod` | Modelo base con output fijo (Secciones II–IV del paper). |
| `dornbusch_variable_output.mod` | Extensión con output variable (Sección V). |
| `dornbusch_estimation.mod` | Versión para estimación bayesiana con datos reales. |

---

## Requisitos

- MATLAB R2018b o superior (por `tiledlayout` y compatibilidad con Dynare)
- Dynare 5.x — descargar en: https://www.dynare.org/download/

Una vez instalado Dynare, agregarlo al path de MATLAB antes de correr:

```matlab
addpath('C:/dynare/5.5/matlab')    % Windows — ajustar según versión
addpath('/usr/lib/dynare/matlab')  % Linux / Mac
```

---

## Cómo correr

1. Abrir MATLAB y navegar al directorio donde están los archivos.
2. Agregar Dynare al path (ver arriba).
3. Ejecutar en la Command Window:

```matlab
>> run_dornbusch
```

El script hace lo siguiente en orden:

1. Calcula θ̃ (Ec. 15) y verifica automáticamente que θ = ν (consistencia de expectativas).
2. Genera las trayectorias analíticas de e(t), p(t) y r(t) usando las soluciones cerradas de las Ecs. (12) y (13).
3. Produce el diagrama de fase con las curvas QQ y ṗ=0, los puntos A→B→C, y vectores de campo.
4. Hace análisis de sensibilidad: cómo cambia de/dm según λ, π y δ.
5. Compara overshooting vs under-shooting con tres escenarios de γ (Ec. 20).
6. Lanza los tres archivos `.mod` en Dynare para obtener las IRFs formales.

Para saltar Dynare y solo ver las gráficas MATLAB, cambiar en `run_dornbusch.m`:

```matlab
run_dynare = false;
```

---

## Calibración base

| Parámetro | Valor | Descripción |
|-----------|-------|-------------|
| $\lambda$ (lambda) | 0.50 | Semielasticidad-interés de la demanda de dinero |
| $\phi$ (phi) | 1.00 | Elasticidad-ingreso de la demanda de dinero |
| $\delta$ (delta) | 0.60 | Elasticidad precio-relativo de la demanda de bienes |
| $\sigma$ (sigma) | 0.30 | Sensibilidad de la demanda de bienes a la tasa de interés |
| $\pi$ (pi_p) | 0.40 | Velocidad de ajuste de precios |
| $r^{*}$ (rstar) | 0.04 | Tasa de interés mundial (4% anual) |
| $\rho_{m}$ (rho_m) | 0.90 | Persistencia del proceso monetario AR(1) |

Con estos valores el script reportará en la Command Window:
- θ̃ ≈ 0.50, ν ≈ 0.50 — verificación θ = ν satisfecha.
- de/dm ≈ 5.00 → por cada 1% de expansión monetaria, el tipo de cambio se deprecia 5% en el impacto antes de corregirse hacia el largo plazo.

---

## Ecuaciones de referencia rápida

| Ecuación | Fórmula | Nombre |
|----------|---------|--------|
| (1) | r = r* + x | Paridad descubierta (UIP) |
| (2) | x = θ(ē − e) | Formación de expectativas |
| (3) | −λr + φy = m − p | Equilibrio mercado monetario |
| (6) | e = ē − (1/λθ)(p − p̄) | Curva QQ (asset market schedule) |
| (8) | ṗ = π[δ(e−p) − σ(r−r*)] | Ajuste de precios |
| (12) | p(t) = p̄ + (p₀ − p̄)exp(−νt) | Trayectoria de precios |
| (13) | e(t) = ē + (e₀ − ē)exp(−νt) | Trayectoria del tipo de cambio |
| (15) | θ̃ = π(σ/λ+δ)/2 + √[(π(σ/λ+δ)/2)² + πδ/λ] | Expectativas racionales |
| (16) | de/dm = 1 + 1/(λθ) | Overshooting |
| (20) | 1 − φμδ ≶ 0 | Over vs under-shooting (output variable) |

---

## Para estimación con datos reales

El archivo `dornbusch_estimation.mod` está listo para estimación bayesiana. Solo necesita datos. Los pasos son:

1. Construir una base de datos trimestral con cuatro series (en el orden en que aparecen en `varobs`):
   - `d_e_obs`: variación del log del tipo de cambio nominal
   - `d_p_obs`: tasa de inflación trimestral (log IPC_t − log IPC_{t-1})
   - `r_obs`: tasa de interés de política monetaria dividida entre 4 (para trimestralizarla)
   - `d_m_obs`: crecimiento del agregado monetario M1

2. Guardar la base como `dornbusch_data.mat` en el mismo directorio.

3. En `dornbusch_estimation.mod`, descomentar el bloque `estimation(...)` y comentar el bloque `stoch_simul(...)` al final.

4. Correr `dynare dornbusch_estimation` directamente o vía `run_dornbusch.m`.

Los resultados de la estimación se guardan automáticamente en las subcarpetas `TeX/` y `graphs/` que Dynare crea en el directorio de trabajo.

**Fuentes de datos sugeridas para México:**

| Variable | Fuente | Serie |
|----------|--------|-------|
| Tipo de cambio FIX (USD/MXN) | Banxico | SF60653 |
| IPC general | INEGI / Banxico | SP1 |
| CETES 28 días | Banxico | SF60679 |
| M1 (billetes + cuentas de cheques) | Banxico | SF311408 |

---

## Gráficas que genera el script

| Archivo | Contenido |
|---------|-----------|
| `Fig1_Trayectorias_Analiticas.png` | Paneles de e(t), p(t), r(t) y la trayectoria en el espacio (e, p). |
| `Fig2_Diagrama_Fase.png` | Diagrama de fase completo con curvas QQ, ṗ=0 y puntos A, B, C. |
| `Fig3_Sensibilidad_Overshooting.png` | de/dm como función de λ, π y δ. |
| `Fig4_Over_vs_Under.png` | Comparación de los tres regímenes según la condición de la Ec. (20). |

---

## Repository structure

```text
.
├── CITATION.cff
├── LICENSE
├── README.md
├── CONTRIBUTING.md
├── .gitignore
├── models/
│   ├── run_dornbusch.m
│   ├── dornbusch_baseline.mod
│   ├── dornbusch_estimation.mod
│   └── dornbusch_variable_output.mod
└── scripts/
    └── README.md
```

## Requirements

- MATLAB R2018b or newer
- Dynare 5.x

## Referencias

**Paper principal:**

Dornbusch, R. (1976). "Expectations and Exchange Rate Dynamics." *Journal of Political Economy*, 84(6), 1161–1176.

**Lecturas complementarias recomendadas:**

- Obstfeld, M. & Rogoff, K. (1995). "Exchange Rate Dynamics Redux." *JPE*, 103(3), 624–660. — Extiende el modelo con microfundamentos y competencia monopolística.
- Clarida, R., Galí, J. & Gertler, M. (2002). "A Simple Framework for International Monetary Policy Analysis." *JME*, 49(5), 879–904. — Versión New Keynesian con curva IS y regla de Taylor.
- Frankel, J. (1979). "On the Mark: A Theory of Floating Exchange Rates Based on Real Interest Rate Differentials." *AER*, 69(4), 610–622. — Extensión del modelo de Dornbusch con diferenciales de inflación esperada.

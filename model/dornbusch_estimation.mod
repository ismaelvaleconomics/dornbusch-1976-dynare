% =========================================================================
% DORNBUSCH (1976) - VERSION PARA ESTIMACION BAYESIANA
% "Expectations and Exchange Rate Dynamics"
%
% Archivo: dornbusch_estimation.mod
% Descripcion: Extiende el modelo base para estimacion bayesiana de
%              los parametros estructurales (lambda, delta, sigma, pi_p).
%              Se agregan ecuaciones de observacion para ligar las
%              variables del modelo con datos reales.
%
% Variables observables (necesitan datos externos):
%   d_e_obs  = variacion del log tipo de cambio (datos: e.g., USD/MXN)
%   d_p_obs  = inflacion (datos: IPC)
%   r_obs    = tasa de interes de corto plazo (datos: CETES 28d)
%   d_m_obs  = crecimiento monetario (datos: M1 o M2)
%
% Uso: dynare dornbusch_estimation
%      Requiere archivo de datos: dornbusch_data.mat (ver script driver)
% =========================================================================

%--------------------------------------------------------------------------
% 1. VARIABLES
%--------------------------------------------------------------------------

var
    e           % Log tipo de cambio (nivel)
    p           % Log precios (nivel)
    r           % Tasa de interes
    x           % Depreciacion esperada
    m           % Log oferta monetaria
    ebar        % Tipo de cambio largo plazo
    pbar        % Precios largo plazo

    % Variables de medicion (observables)
    d_e_obs     % Delta log tipo de cambio (observable)
    d_p_obs     % Inflacion (observable)
    r_obs       % Tasa de interes (observable)
    d_m_obs     % Crecimiento monetario (observable)
;

varexo
    eps_m       % Choque monetario
    eps_e       % Error de medicion: tipo de cambio
    eps_pi      % Error de medicion: inflacion
    eps_r       % Error de medicion: tasa de interes
;

parameters
    % Parametros estructurales (a estimar)
    lambda
    delta
    sigma
    pi_p
    phi
    gamma_y
    rstar
    rho_m
    theta_val

    % Varianzas de los choques (a estimar)
    % Se declaran como parametros para la prior
;

%--------------------------------------------------------------------------
% 2. PARAMETROS INICIALES (punto de partida para la estimacion)
%--------------------------------------------------------------------------

lambda   = 0.50;
delta    = 0.60;
sigma    = 0.30;
pi_p     = 0.40;
phi      = 1.00;
gamma_y  = 0.40;
rstar    = 0.04;
rho_m    = 0.90;
theta_val = 0.50;

%--------------------------------------------------------------------------
% 3. MODELO
%--------------------------------------------------------------------------

model;

% Ecuaciones estructurales (igual que modelo base)
r    = rstar + x;
x    = theta_val * (ebar - e);
p - m = -phi*0 + lambda*rstar + lambda*theta_val*(ebar - e);
pbar = m + lambda*rstar;
ebar = pbar + sigma*rstar/delta;
p    = p(-1) + pi_p*(delta*(e(-1) - p(-1)) - sigma*(r(-1) - rstar));
m    = rho_m * m(-1) + eps_m;

% -------------------------------------------------------------------
% Ecuaciones de observacion
% Ligan variables del modelo con datos observables
% La constante absorbe medias muestrales de los datos
% -------------------------------------------------------------------

% Cambio porcentual en el tipo de cambio
d_e_obs = (e - e(-1)) + eps_e;

% Tasa de inflacion
d_p_obs = (p - p(-1)) + eps_pi;

% Tasa de interes (nivel, no diferencia)
r_obs = r + eps_r;

% Crecimiento monetario
d_m_obs = (m - m(-1));

end;

%--------------------------------------------------------------------------
% 4. ESTADO ESTACIONARIO
%--------------------------------------------------------------------------

steady_state_model;
    m      = 0;
    p      = 0;
    pbar   = 0;
    r      = rstar;
    x      = 0;
    ebar   = sigma*rstar/delta;
    e      = ebar;
    d_e_obs  = 0;
    d_p_obs  = 0;
    r_obs    = rstar;
    d_m_obs  = 0;
end;

steady;
check;

%--------------------------------------------------------------------------
% 5. CHOQUES (varianzas a priori para la estimacion)
%--------------------------------------------------------------------------

shocks;
    var eps_m  = 0.01^2;    % Choque monetario
    var eps_e  = 0.005^2;   % Error de medicion tipo de cambio
    var eps_pi = 0.002^2;   % Error de medicion inflacion
    var eps_r  = 0.002^2;   % Error de medicion tasa de interes
end;

%--------------------------------------------------------------------------
% 6. DISTRIBUCIONES A PRIORI (Bayesian estimation)
%--------------------------------------------------------------------------
% Sintaxis: parameter_name, prior_mean, prior_std, prior_distribution,
%           lower_bound, upper_bound;
%
% Distribuciones disponibles: beta, gamma, normal, uniform, inv_gamma
%
% Justificacion de las priors:
%   lambda ~ Gamma(0.50, 0.20): debe ser positivo; media 0.5 estandar en lit.
%   delta  ~ Gamma(0.60, 0.20): elasticidad precio, debe ser positiva
%   sigma  ~ Gamma(0.30, 0.15): sensibilidad a tasa de interes
%   pi_p   ~ Gamma(0.40, 0.20): velocidad de ajuste precios
%   rho_m  ~ Beta(0.80, 0.10):  persistencia AR(1), en (0,1)

estimated_params;
    lambda,    0.50, 0.20, gamma_pdf,    0.05,   2.00;
    delta,     0.60, 0.20, gamma_pdf,    0.10,   2.00;
    sigma,     0.30, 0.15, gamma_pdf,    0.05,   1.50;
    pi_p,      0.40, 0.20, gamma_pdf,    0.05,   2.00;
    rho_m,     0.80, 0.10, beta_pdf,     0.50,   0.99;

    % Desviaciones estandar de los choques
    stderr eps_m,   0.01, 0.005, inv_gamma_pdf, 0.001, 0.10;
    stderr eps_e,   0.005, 0.003, inv_gamma_pdf, 0.001, 0.05;
    stderr eps_pi,  0.003, 0.002, inv_gamma_pdf, 0.001, 0.03;
    stderr eps_r,   0.002, 0.001, inv_gamma_pdf, 0.0005, 0.02;
end;

%--------------------------------------------------------------------------
% 7. VARIABLES OBSERVABLES
%--------------------------------------------------------------------------

varobs d_e_obs d_p_obs r_obs d_m_obs;

%--------------------------------------------------------------------------
% 8. ESTIMACION BAYESIANA
% (Solo se ejecuta si se proveen datos reales - ver script driver)
%--------------------------------------------------------------------------
% Para activar, descomentar y proveer archivo de datos:
%
% estimation(datafile=dornbusch_data,
%            mh_replic=100000,
%            mh_nblocks=2,
%            mh_jscale=0.30,
%            mode_compute=4,
%            order=1,
%            irf=40,
%            bayesian_irf,
%            graph_format=fig)
%            lambda delta sigma pi_p rho_m;

%--------------------------------------------------------------------------
% 9. SIMULACION BASICA (sin datos, para verificar el modelo)
%--------------------------------------------------------------------------

shocks;
    var eps_m = 0.01^2;
    var eps_e = 0.005^2;
    var eps_pi = 0.002^2;
    var eps_r = 0.002^2;
end;

stoch_simul(order=1,
            irf=40,
            periods=200,
            nograph=false,
            graph_format=fig)
            e p r m d_e_obs d_p_obs;

%--------------------------------------------------------------------------
% NOTAS
%--------------------------------------------------------------------------
% Para usar este archivo con datos reales:
%
% 1. Preparar datos en frecuencia trimestral (recomendado):
%    - d_e_obs: log(e_t/e_{t-1}) del tipo de cambio nominal
%    - d_p_obs: log(P_t/P_{t-1}) del IPC
%    - r_obs:   tasa de interes de politica monetaria / 4 (trimestralizar)
%    - d_m_obs: log(M1_t/M1_{t-1})
%
% 2. Guardar como dornbusch_data.mat con columnas en el orden de varobs
%
% 3. Descomentar el bloque estimation() arriba
%
% 4. Los resultados de la estimacion se guardan en:
%    TeX/dornbusch_estimation_MH_mode.tex  (moda posterior)
%    TeX/dornbusch_estimation_posterior.tex (distribucion posterior)
%--------------------------------------------------------------------------

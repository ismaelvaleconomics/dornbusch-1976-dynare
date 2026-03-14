% =========================================================================
% DORNBUSCH (1976) - MODELO EXTENDIDO CON OUTPUT VARIABLE
% "Expectations and Exchange Rate Dynamics"
% Journal of Political Economy, Vol. 84, No. 6, pp. 1161-1176
%
% Archivo: dornbusch_variable_output.mod
% Descripcion: Extension de la Seccion V del paper. El output se determina
%              por la demanda en el corto plazo (Ec. 18). La inflacion sigue
%              una curva de Phillips basada en la brecha del producto (Ec. 19).
%              El overshooting puede convertirse en under-shooting dependiendo
%              de los parametros (condicion Ec. 20 del paper).
%
% Nuevas variables (respecto al modelo base):
%   y    = log del output real (determinado por la demanda en el CP)
%   ybar = log del output potencial (full-employment, exogeno)
%
% Ecuaciones adicionales:
%   Ec. (18): y = u + delta*(e-p) + gamma*y - sigma*r  [goods market eq.]
%   Ec. (19): dp/dt = pi*(y - ybar)                    [Phillips curve]
%   Ec. (A1): y = mu*[u + delta*(e-p) - sigma*r]       mu = 1/(1-gamma)
%   Ec. (A8): e - ebar = -[(1 - phi*mu*delta)/Delta]*(p - pbar)
%
% Condicion overshooting vs under-shooting (Ec. 20):
%   1 - phi*delta/(1-gamma) < 0  =>  under-shooting
%   1 - phi*delta/(1-gamma) > 0  =>  over-shooting (caso base)
%
% Uso: dynare dornbusch_variable_output
% =========================================================================

%--------------------------------------------------------------------------
% 1. DECLARACION DE VARIABLES
%--------------------------------------------------------------------------

var
    e       % Log tipo de cambio spot
    p       % Log nivel de precios domestico
    r       % Tasa de interes domestica nominal
    x       % Tasa esperada de depreciacion
    y       % Log output real (variable en el CP)
    ebar    % Log tipo de cambio de largo plazo
    pbar    % Log nivel de precios de largo plazo
    ybar_v  % Log output de largo plazo/potencial (puede variar con choques reales)
    m       % Log oferta monetaria nominal
;

varexo
    eps_m   % Choque monetario
    eps_d   % Choque de demanda (shift parameter u en Ec. 7)
;

parameters
    lambda      % Semielasticidad-interes demanda de dinero
    phi         % Elasticidad-ingreso demanda de dinero
    delta       % Elasticidad precio-relativo demanda bienes
    sigma       % Sensibilidad demanda bienes a tasa de interes
    gamma_y     % Propension marginal al consumo de bienes domesticos
    pi_p        % Velocidad de ajuste de precios (curva de Phillips)
    theta_val   % Coeficiente de expectativas racionales
    rstar       % Tasa de interes mundial
    rho_m       % Persistencia proceso monetario
    rho_d       % Persistencia choque de demanda
;

%--------------------------------------------------------------------------
% 2. CALIBRACION
%--------------------------------------------------------------------------
% Parametros comunes con el modelo base

lambda   = 0.50;
phi      = 1.00;
delta    = 0.60;
sigma    = 0.30;
gamma_y  = 0.40;   % Propension marginal al consumo de bienes domesticos
pi_p     = 0.40;
rstar    = 0.04;
rho_m    = 0.90;
rho_d    = 0.70;

% Calcular mu = 1/(1-gamma_y) [multiplicador del gasto, Ec. A1]
% mu = 1/(1-0.40) = 1.667

% Verificacion de la condicion de overshooting/undershooting (Ec. 20):
% 1 - phi*mu*delta = 1 - 1.0*(1/0.6)*0.6 = 1 - 1.0 = 0.0  (caso limite)
% Con gamma_y=0.40: mu=1.667, phi*mu*delta = 1.0*1.667*0.6 = 1.0 => caso limite
% Ajustamos gamma_y o phi para ver ambos casos en el script driver

% Coeficiente de expectativas: calculado en steady_state_model
theta_val = 0.50;

%--------------------------------------------------------------------------
% 3. MODELO
%--------------------------------------------------------------------------

model;

% -------------------------------------------------------------------
% UIP (igual que modelo base)
% -------------------------------------------------------------------
r = rstar + x;

% -------------------------------------------------------------------
% Expectativas regresivas (igual que modelo base)
% -------------------------------------------------------------------
x = theta_val * (ebar - e);

% -------------------------------------------------------------------
% Equilibrio en el mercado monetario (Ec. 3, ahora y es variable)
%   -lambda*r + phi*y = m - p
% -------------------------------------------------------------------
-lambda*r + phi*y = m - p;

% -------------------------------------------------------------------
% Equilibrio en el mercado de bienes (Ec. 18) - NUEVA EN ESTE MODELO
%   y = u + delta*(e-p) + gamma*y - sigma*r
%   => y*(1-gamma) = delta*(e-p) - sigma*r    [u=0 en SS]
%   => y = mu*[delta*(e-p) - sigma*r]          [Ec. A1]
% -------------------------------------------------------------------
y = (1/(1-gamma_y)) * (delta*(e - p) - sigma*r);

% -------------------------------------------------------------------
% Curva de Phillips (Ec. 19) - NUEVA EN ESTE MODELO
%   dp/dt = pi*(y - ybar)
%   En tiempo discreto:
%   p - p(-1) = pi_p*(y(-1) - ybar_v(-1))
% -------------------------------------------------------------------
p = p(-1) + pi_p * (y(-1) - ybar_v(-1));

% -------------------------------------------------------------------
% Output potencial (largo plazo, determinado por oferta)
% Permanece en su nivel de estado estacionario ante choques monetarios
% -------------------------------------------------------------------
ybar_v = 0;   % Normalizado en logs

% -------------------------------------------------------------------
% Nivel de precios de largo plazo (Ec. 5)
%   pbar = m + lambda*r* - phi*ybar
% -------------------------------------------------------------------
pbar = m + lambda*rstar - phi*ybar_v;

% -------------------------------------------------------------------
% Tipo de cambio de largo plazo (Ec. 9, ahora con y variable en SS)
%   ebar = pbar + (sigma*r* + (1-gamma)*ybar) / delta
%   Simplificado para SS con ybar=0:
% -------------------------------------------------------------------
ebar = pbar + sigma*rstar/delta;

% -------------------------------------------------------------------
% Proceso AR(1) para oferta monetaria
% -------------------------------------------------------------------
m = rho_m * m(-1) + eps_m;

end;

%--------------------------------------------------------------------------
% 4. ESTADO ESTACIONARIO
%--------------------------------------------------------------------------

steady_state_model;
    m      = 0;
    p      = 0;
    pbar   = 0;
    ybar_v = 0;
    y      = 0;
    r      = rstar;
    x      = 0;
    ebar   = sigma*rstar/delta;
    e      = ebar;
end;

steady;
check;

%--------------------------------------------------------------------------
% 5. CHOQUES
%--------------------------------------------------------------------------

shocks;
    var eps_m = 0.01;   % Choque monetario 1%
    var eps_d = 0.00;   % Choque de demanda (inactivo por default)
    corr eps_m, eps_d = 0;
end;

%--------------------------------------------------------------------------
% 6. SIMULACION
%--------------------------------------------------------------------------

stoch_simul(order=1,
            irf=40,
            periods=500,
            nograph=false,
            contemporaneous_correlation=true,
            graph_format=fig)
            e p r y m x;

%--------------------------------------------------------------------------
% 7. NOTAS
%--------------------------------------------------------------------------
% DIFERENCIA CLAVE CON EL MODELO BASE:
%   En el modelo base, de/dm = 1 + 1/(lambda*theta) > 1 siempre (overshooting)
%
%   Con output variable (Ec. A11 del paper):
%   de/dm = 1 + (1 - phi*mu*delta)/Delta
%   donde Delta = phi*mu*(delta + sigma*theta) + theta*lambda
%
%   El signo de (1 - phi*mu*delta) determina over vs under-shooting:
%   - phi*mu*delta > 1  =>  de/dm < 1  =>  UNDER-SHOOTING
%   - phi*mu*delta < 1  =>  de/dm > 1  =>  OVER-SHOOTING
%   - phi*mu*delta = 1  =>  de/dm = 1  =>  AJUSTE EXACTO (caso limite)
%
% Con la calibracion actual (phi=1, mu=1.667, delta=0.6): phi*mu*delta = 1.0
% Para ver under-shooting: aumentar phi a 1.2 en el script driver
% Para ver over-shooting:  reducir gamma_y a 0.20 (mu=1.25, phi*mu*delta=0.75)
%--------------------------------------------------------------------------

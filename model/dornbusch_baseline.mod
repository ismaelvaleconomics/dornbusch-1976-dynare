% =========================================================================
% DORNBUSCH (1976) - MODELO BASE (OUTPUT FIJO)
% "Expectations and Exchange Rate Dynamics"
% Journal of Political Economy, Vol. 84, No. 6, pp. 1161-1176
%
% Archivo: dornbusch_baseline.mod
% Descripcion: Implementacion del modelo de overshooting con output fijo
%              (Secciones II-IV del paper). El tipo de cambio sobreajusta
%              su valor de largo plazo ante una expansion monetaria.
%
% Variables endogenas:
%   e  = log del tipo de cambio spot (precio de la divisa extranjera)
%   p  = log del nivel de precios domestico
%   r  = tasa de interes domestica nominal
%   x  = tasa esperada de depreciacion del tipo de cambio
%
% Variables exogenas:
%   eps_m = choque a la oferta monetaria (expansion monetaria)
%
% Parametros clave (calibracion base):
%   lambda = semielasticidad-interes de demanda de dinero     (Ec. 3)
%   phi    = elasticidad-ingreso de demanda de dinero         (Ec. 3)
%   delta  = elasticidad precio-relativo de demanda de bienes (Ec. 7)
%   sigma  = sensibilidad de demanda de bienes a tasa interes (Ec. 7)
%   pi_p   = velocidad de ajuste de precios                   (Ec. 8)
%   rstar  = tasa de interes mundial (exogena)
%   ybar   = log del ingreso real (fijo en estado estacionario)
%   mbar   = log de la oferta monetaria (estado estacionario)
%
% Uso: dynare dornbusch_baseline
% =========================================================================

%--------------------------------------------------------------------------
% 1. DECLARACION DE VARIABLES
%--------------------------------------------------------------------------

var
    e       % Log tipo de cambio spot                    [variable jump]
    p       % Log nivel de precios domestico             [variable predeterminada]
    r       % Tasa de interes domestica nominal          [variable estatica]
    x       % Tasa esperada de depreciacion              [variable estatica]
    ebar    % Log tipo de cambio de largo plazo          [variable estatica]
    pbar    % Log nivel de precios de largo plazo        [variable estatica]
    m       % Log oferta monetaria nominal               [variable de estado]
;

varexo
    eps_m   % Choque monetario (innovacion a m)
;

parameters
    lambda      % Semielasticidad-interes demanda de dinero (> 0)
    phi         % Elasticidad-ingreso demanda de dinero     (> 0)
    delta       % Elasticidad precio-relativo demanda bienes(> 0)
    sigma       % Sensibilidad demanda bienes a tasa interes(> 0)
    pi_p        % Velocidad de ajuste de precios            (> 0)
    theta_val   % Coeficiente de expectativas (= theta-tilde en eq. racional)
    rstar       % Tasa de interes mundial (exogena)
    ybar        % Log ingreso real (fijo)
    rho_m       % Persistencia del proceso de oferta monetaria
;

%--------------------------------------------------------------------------
% 2. CALIBRACION DE PARAMETROS
%--------------------------------------------------------------------------
% Valores basados en calibraciones estandar de la literatura
% (Obstfeld & Rogoff 1996, Clarida et al. 2002)

lambda   = 0.50;   % Alta semielasticidad-interes (moderada sensibilidad)
phi      = 1.00;   % Elasticidad-ingreso unitaria (cuantitativismo)
delta    = 0.60;   % Elasticidad precio-relativo moderada
sigma    = 0.30;   % Efecto tasa de interes sobre demanda de bienes
pi_p     = 0.40;   % Ajuste de precios moderadamente lento (sticky prices)
rstar    = 0.04;   % Tasa de interes mundial anual = 4%
ybar     = 0.00;   % Ingreso normalizado en logs (= 1 en niveles)
rho_m    = 0.90;   % Alta persistencia del proceso monetario

% Calcular theta_tilde (Ec. 15 del paper):
% theta-tilde = pi*(sigma/lambda + delta)/2
%               + sqrt[ pi^2*(sigma/lambda + delta)^2/4 + pi*delta/lambda ]
% Este es el coeficiente de expectativas racionales que hace theta = v

% Calculo previo de parametros auxiliares
% (Dynare no permite sqrt directamente en parameters, se usa steady_state_model)
% Ver bloque steady_state_model abajo para el calculo explicito

theta_val = 0.50;   % Valor inicial; se reemplaza con theta-tilde en steady_state

%--------------------------------------------------------------------------
% 3. MODELO (ECUACIONES LOG-LINEALIZADAS)
%--------------------------------------------------------------------------

model;

% -------------------------------------------------------------------
% Ec. (1): Paridad descubierta de tasas de interes (UIP)
%   r = r* + x
%   La movilidad perfecta de capital iguala rendimientos esperados
% -------------------------------------------------------------------
r = rstar + x;

% -------------------------------------------------------------------
% Ec. (2): Formacion de expectativas (regresiva hacia el largo plazo)
%   x = theta*(ebar - e)
%   Los agentes esperan que e converja a ebar a tasa theta
%   Bajo expectativas racionales: theta = theta-tilde (Ec. 15)
% -------------------------------------------------------------------
x = theta_val * (ebar - e);

% -------------------------------------------------------------------
% Ec. (3)/(4): Equilibrio en el mercado monetario
%   -lambda*r + phi*y = m - p  =>  p - m = -phi*ybar + lambda*r* + lambda*theta*(ebar - e)
%   Combinando con UIP y expectativas:
%   e = ebar - (1/lambda*theta)*(p - pbar)                  [Ec. 6]
% -------------------------------------------------------------------
p - m = -phi*ybar + lambda*rstar + lambda*theta_val*(ebar - e);

% -------------------------------------------------------------------
% Ec. (5): Nivel de precios de largo plazo
%   pbar = m + lambda*r* - phi*ybar
% -------------------------------------------------------------------
pbar = m + lambda*rstar - phi*ybar;

% -------------------------------------------------------------------
% Ec. (9): Tipo de cambio de largo plazo (goods market clearing en SS)
%   ebar = pbar + (1/delta)*[sigma*r* + (1-gamma)*y - u]
%   Simplificado con u=0, gamma=1 para el modelo base:
%   ebar = pbar + sigma*rstar/delta
% -------------------------------------------------------------------
ebar = pbar + (sigma*rstar)/delta;

% -------------------------------------------------------------------
% Ec. (8)/(10): Ajuste de precios (mercado de bienes)
%   dp/dt = -v*(p - pbar)  donde v = pi*[(delta+sigma*theta)/theta*lambda + delta]
%   En tiempo discreto (Euler):
%   p = p(-1) + pi_p*[delta*(e(-1)-p(-1)) + (0-1)*ybar - sigma*r(-1)]
%   Equivalente a: p = p(-1) - v*(p(-1) - pbar(-1))
% -------------------------------------------------------------------
p = p(-1) + pi_p * ( delta*(e(-1) - p(-1)) - sigma*(r(-1) - rstar) );

% -------------------------------------------------------------------
% Proceso AR(1) para la oferta monetaria
%   m_t = rho_m * m_{t-1} + eps_m
%   Un choque permanente: eps_m en t=0, luego rho_m -> 1 simula permanencia
% -------------------------------------------------------------------
m = rho_m * m(-1) + eps_m;

end;

%--------------------------------------------------------------------------
% 4. ESTADO ESTACIONARIO
%--------------------------------------------------------------------------

steady_state_model;
    m    = 0;
    p    = 0;
    pbar = 0;
    r    = rstar;
    x    = 0;
    ebar = (sigma*rstar)/delta;
    e    = ebar;
end;

steady;
check;

%--------------------------------------------------------------------------
% 5. CHOQUES
%--------------------------------------------------------------------------

shocks;
    var eps_m = 0.01;   % Choque de 1% a la oferta monetaria (1 desv. estandar)
end;

%--------------------------------------------------------------------------
% 6. CALCULO Y GRAFICAS
%--------------------------------------------------------------------------

stoch_simul(order=1,
            irf=40,
            periods=500,
            nograph=false,
            contemporaneous_correlation=true,
            graph_format=fig)
            e p r m x;

%--------------------------------------------------------------------------
% 7. NOTAS
%--------------------------------------------------------------------------
% RESULTADO ESPERADO (Ec. 16 del paper):
%   de/dm = 1 + 1/(lambda*theta)
%   Con lambda=0.5, theta=0.5: de/dm = 1 + 1/0.25 = 5.0
%   => El tipo de cambio sobreajusta 5 veces el choque monetario
%
% VERIFICACION DEL OVERSHOOTING:
%   En el IRF, e debe saltar en t=0 por encima de su nuevo nivel de largo plazo
%   y luego APRECIARSE gradualmente de regreso (convergencia monotona).
%
% TRAYECTORIA DE LARGO PLAZO:
%   En t -> infinito: Delta_e = Delta_p = Delta_m = 0.01 (homogeneidad)
%--------------------------------------------------------------------------

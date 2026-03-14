% =========================================================================
% DORNBUSCH (1976) - SCRIPT DRIVER PRINCIPAL
% "Expectations and Exchange Rate Dynamics"
%
% Archivo: run_dornbusch.m
% Descripcion: Orquesta los tres modelos Dynare y genera:
%   1. IRFs del modelo base (overshooting garantizado)
%   2. IRFs del modelo con output variable (over vs under-shooting)
%   3. Diagrama de fase completo (curvas QQ y p-dot=0)
%   4. Analisis de sensibilidad del overshooting
%   5. Graficas de trayectorias analiticas (Ec. 12 y 13 del paper)
%
% Uso: Correr este script desde MATLAB con Dynare instalado y en el PATH
%      >> run_dornbusch
%
% Requisitos:
%   - Dynare 5.x o superior instalado
%   - Archivos .mod en el mismo directorio
%   - MATLAB R2018b o superior (para tiledlayout)
% =========================================================================

clear; clc; close all;

%==========================================================================
% CONFIGURACION GLOBAL
%==========================================================================

% Asegurarse de que Dynare este en el path
% addpath('C:/dynare/5.5/matlab')   % <-- Ajustar segun instalacion

% Paleta de colores para graficas (compatible con daltonia)
C.blue    = [0.122, 0.306, 0.490];
C.orange  = [0.773, 0.349, 0.067];
C.green   = [0.216, 0.522, 0.216];
C.red     = [0.690, 0.129, 0.129];
C.gray    = [0.500, 0.500, 0.500];
C.lblue   = [0.678, 0.788, 0.902];
C.lorange = [0.988, 0.898, 0.851];

% Parametros del modelo (deben coincidir con los .mod)
params.lambda  = 0.50;
params.phi     = 1.00;
params.delta   = 0.60;
params.sigma   = 0.30;
params.pi_p    = 0.40;
params.gamma_y = 0.40;
params.rstar   = 0.04;
params.rho_m   = 0.90;

% Calcular theta-tilde (Ec. 15 del paper)
% theta = pi*(sigma/lambda + delta)/2
%         + sqrt(pi^2*(sigma/lambda + delta)^2/4 + pi*delta/lambda)
A = params.sigma/params.lambda + params.delta;
params.theta = params.pi_p*A/2 + sqrt((params.pi_p*A/2)^2 + params.pi_p*params.delta/params.lambda);

% Calcular tasa de convergencia v (Ec. 11)
params.v = params.pi_p * ((params.delta + params.sigma*params.theta)/(params.theta*params.lambda) + params.delta);

% Calcular overshooting teorico (Ec. 16)
params.de_dm = 1 + 1/(params.lambda * params.theta);

fprintf('\n=== PARAMETROS DEL MODELO ===\n')
fprintf('lambda  = %.4f  (semielasticidad-interes demanda de dinero)\n', params.lambda)
fprintf('delta   = %.4f  (elasticidad precio-relativo demanda bienes)\n', params.delta)
fprintf('sigma   = %.4f  (efecto tasa de interes sobre demanda bienes)\n', params.sigma)
fprintf('pi_p    = %.4f  (velocidad de ajuste de precios)\n', params.pi_p)
fprintf('\n')
fprintf('theta-tilde = %.4f  (coeficiente expectativas racionales, Ec. 15)\n', params.theta)
fprintf('v (nu)      = %.4f  (tasa de convergencia al largo plazo, Ec. 11)\n', params.v)
fprintf('Verificacion theta=v: %.4f = %.4f  [%s]\n', params.theta, params.v, ...
    ternary(abs(params.theta - params.v) < 1e-10, 'OK', 'ERROR'))
fprintf('\n')
fprintf('de/dm = %.4f  (overshooting teorico, Ec. 16)\n', params.de_dm)
fprintf('Interpretacion: por cada 1%% de expansion monetaria, el tipo de cambio\n')
fprintf('se deprecia en un %.1f%% en el impacto antes de corregirse.\n', params.de_dm*100)

%==========================================================================
% SECCION 1: TRAYECTORIAS ANALITICAS (Ec. 12 y 13 del paper)
%==========================================================================
% No requiere Dynare. Resuelve directamente las soluciones cerradas.

fprintf('\n\n=== SECCION 1: TRAYECTORIAS ANALITICAS ===\n')

T      = 0:0.1:20;        % Horizonte temporal (periodos)
dm     = 0.01;            % Choque monetario = 1%
e0_ss  = 0;               % Tipo de cambio inicial (estado estacionario)
p0_ss  = 0;               % Precios iniciales

% Nuevos valores de largo plazo tras expansion monetaria de dm
delta_ebar = dm;          % Ec. 9: e-barra sube 1-a-1 con m (largo plazo)
delta_pbar = dm;          % Ec. 5: p-barra sube 1-a-1 con m

% Salto inicial del tipo de cambio (overshooting, Ec. 16)
delta_e0 = params.de_dm * dm;   % e sube mas que e-barra en el impacto

% Valores iniciales despues del choque (t=0+)
e_new_ss = e0_ss + delta_ebar;  % Nuevo estado estacionario de e
p_new_ss = p0_ss + delta_pbar;  % Nuevo estado estacionario de p
e0_impact = e0_ss + delta_e0;   % Valor impacto de e (overshooting)
p0_after  = p0_ss;              % Precio no cambia en el impacto

% Trayectorias (Ec. 12 y 13):
%   p(t) = p-barra_new + (p0 - p-barra_new)*exp(-v*t)
%   e(t) = e-barra_new + (e0 - e-barra_new)*exp(-v*t)
p_t = p_new_ss + (p0_after  - p_new_ss) .* exp(-params.v .* T);
e_t = e_new_ss + (e0_impact - e_new_ss) .* exp(-params.v .* T);
r_t = params.rstar + params.theta .* (e_new_ss - e_t);  % r = r* + theta*(ebar-e)

fig1 = figure('Name', 'Trayectorias Analiticas - Dornbusch 1976', ...
              'Position', [100 100 1200 800]);

subplot(2,2,1)
hold on
plot(T, e_t*100, 'Color', C.orange, 'LineWidth', 2.5, 'DisplayName', 'e(t) - Tipo de cambio')
yline(e_new_ss*100, '--', 'Color', C.blue, 'LineWidth', 1.5, 'DisplayName', 'Nuevo largo plazo \bar{e}')
yline(e0_ss*100, ':', 'Color', C.gray, 'LineWidth', 1.2, 'DisplayName', 'Largo plazo inicial')
xline(0, 'k--', 'LineWidth', 1)
xlabel('Tiempo', 'FontSize', 11)
ylabel('Variacion % respecto al SS', 'FontSize', 11)
title('Tipo de cambio e(t)', 'FontSize', 12, 'FontWeight', 'bold')
legend('Location', 'northeast', 'FontSize', 9)
annotation_overshooting(params.de_dm, dm, C)
grid on; box on

subplot(2,2,2)
hold on
plot(T, p_t*100, 'Color', C.blue, 'LineWidth', 2.5, 'DisplayName', 'p(t) - Nivel de precios')
yline(p_new_ss*100, '--', 'Color', C.blue, 'LineWidth', 1.5, 'DisplayName', 'Nuevo largo plazo \bar{p}')
yline(p0_ss*100, ':', 'Color', C.gray, 'LineWidth', 1.2, 'DisplayName', 'Largo plazo inicial')
xline(0, 'k--', 'LineWidth', 1)
xlabel('Tiempo', 'FontSize', 11)
ylabel('Variacion % respecto al SS', 'FontSize', 11)
title('Nivel de precios p(t)', 'FontSize', 12, 'FontWeight', 'bold')
legend('Location', 'southeast', 'FontSize', 9)
grid on; box on

subplot(2,2,3)
hold on
plot(T, (r_t - params.rstar)*100, 'Color', C.red, 'LineWidth', 2.5, 'DisplayName', 'r(t) - r*')
yline(0, '--', 'Color', C.gray, 'LineWidth', 1.5, 'DisplayName', 'Largo plazo (r = r*)')
xlabel('Tiempo', 'FontSize', 11)
ylabel('Diferencial de tasas (%)', 'FontSize', 11)
title('Diferencial de tasa de interes r(t) - r*', 'FontSize', 12, 'FontWeight', 'bold')
legend('Location', 'northeast', 'FontSize', 9)
grid on; box on

subplot(2,2,4)
hold on
plot(e_t*100, p_t*100, 'Color', C.orange, 'LineWidth', 2.5, 'DisplayName', 'Senda de ajuste')
plot(e0_impact*100, p0_after*100, 'o', 'MarkerSize', 10, 'MarkerFaceColor', C.orange, ...
    'Color', C.orange, 'DisplayName', 'Punto B (impacto)')
plot(e_new_ss*100, p_new_ss*100, 's', 'MarkerSize', 10, 'MarkerFaceColor', C.blue, ...
    'Color', C.blue, 'DisplayName', 'Punto C (nuevo SS)')
plot(e0_ss*100, p0_ss*100, 'd', 'MarkerSize', 10, 'MarkerFaceColor', C.green, ...
    'Color', C.green, 'DisplayName', 'Punto A (SS inicial)')
xlabel('Tipo de cambio e (%)', 'FontSize', 11)
ylabel('Nivel de precios p (%)', 'FontSize', 11)
title('Trayectoria en el espacio (e, p)', 'FontSize', 12, 'FontWeight', 'bold')
legend('Location', 'northwest', 'FontSize', 9)
grid on; box on

sgtitle(sprintf(['Dornbusch (1976): Respuesta ante Expansion Monetaria (\\Deltam = %.0f%%)\n' ...
    'Overshooting: \\Deltae_{impacto}/\\Deltam = %.2f  |  v = %.3f  |  \\theta = %.3f'], ...
    dm*100, params.de_dm, params.v, params.theta), ...
    'FontSize', 13, 'FontWeight', 'bold')

saveas(fig1, 'Fig1_Trayectorias_Analiticas.png')
fprintf('Figura 1 guardada: Fig1_Trayectorias_Analiticas.png\n')

%==========================================================================
% SECCION 2: DIAGRAMA DE FASE COMPLETO
%==========================================================================

fprintf('\n\n=== SECCION 2: DIAGRAMA DE FASE ===\n')

fig2 = figure('Name', 'Diagrama de Fase - Dornbusch 1976', 'Position', [100 100 1000 800]);

% Rango de valores para las curvas
e_range = linspace(-0.03, 0.05, 300);
p_range = linspace(-0.02, 0.03, 300);

% CURVA QQ (Ec. 6): e = ebar - (1/lambda*theta)*(p - pbar)
% Despejando p: p = pbar - lambda*theta*(e - ebar)
% En desviaciones del SS inicial (ebar=0, pbar=0):
% p_QQ = -lambda*theta*e
p_QQ_inicial = -params.lambda * params.theta * e_range;

% Curva QQ nueva (tras choque dm=0.01: ebar_new = dm, pbar_new = dm)
ebar_new = dm; pbar_new = dm;
p_QQ_nueva = pbar_new - params.lambda * params.theta * (e_range - ebar_new);

% CURVA p-dot = 0 (Ec. 8 en SS):
% 0 = delta*(e - p) - sigma*(r - r*)
% r - r* = theta*(ebar - e) => sustituir
% 0 = delta*(e - p) - sigma*theta*(ebar - e)
% p = e - (sigma*theta/delta)*(ebar - e)
% En desviaciones (ebar=0): p = e*(1 + sigma*theta/delta)
slope_pdot0 = 1 + params.sigma * params.theta / params.delta;
p_pdot0_inicial = slope_pdot0 * e_range;
p_pdot0_nueva   = pbar_new + slope_pdot0 * (e_range - ebar_new);

% Puntos clave
A_e = 0; A_p = 0;                          % Equilibrio inicial
B_e = delta_e0; B_p = 0;                    % Impacto (overshooting)
C_e = ebar_new; C_p = pbar_new;             % Nuevo equilibrio largo plazo

hold on

% Curvas QQ
h1 = plot(e_range*100, p_QQ_inicial*100, '-', 'Color', C.blue, 'LineWidth', 2.5, ...
    'DisplayName', 'QQ inicial');
h2 = plot(e_range*100, p_QQ_nueva*100,   '--', 'Color', C.blue, 'LineWidth', 2.5, ...
    'DisplayName', 'QQ nueva (tras \Deltam)');

% Curvas p-dot = 0
h3 = plot(e_range*100, p_pdot0_inicial*100, '-', 'Color', C.green, 'LineWidth', 2.5, ...
    'DisplayName', '\dot{p}=0 inicial');
h4 = plot(e_range*100, p_pdot0_nueva*100,   '--', 'Color', C.green, 'LineWidth', 2.5, ...
    'DisplayName', '\dot{p}=0 nueva');

% Linea de 45 grados (referencia)
plot(e_range*100, e_range*100, ':', 'Color', C.gray, 'LineWidth', 1.2, 'DisplayName', '45°')

% Trayectoria de ajuste B -> C
e_adj = ebar_new + (B_e - ebar_new) * exp(-params.v * linspace(0,20,200));
p_adj = pbar_new + (B_p - pbar_new) * exp(-params.v * linspace(0,20,200));
plot(e_adj*100, p_adj*100, '-', 'Color', C.orange, 'LineWidth', 3, ...
    'DisplayName', 'Senda de ajuste B\rightarrowC')

% Flecha de impacto A -> B (salto instantaneo)
annotation('arrow', ...
    [0.5 + A_e/0.08*0.12, 0.5 + B_e/0.08*0.12], ...
    [0.5 + A_p/0.05*0.15, 0.5 + B_p/0.05*0.15])

% Puntos de equilibrio
plot(A_e*100, A_p*100, 'd', 'MarkerSize', 14, 'MarkerFaceColor', C.green, ...
    'MarkerEdgeColor', 'k', 'LineWidth', 1.5, 'DisplayName', 'A: SS inicial')
plot(B_e*100, B_p*100, 'o', 'MarkerSize', 14, 'MarkerFaceColor', C.orange, ...
    'MarkerEdgeColor', 'k', 'LineWidth', 1.5, 'DisplayName', 'B: Impacto (overshooting)')
plot(C_e*100, C_p*100, 's', 'MarkerSize', 14, 'MarkerFaceColor', C.blue, ...
    'MarkerEdgeColor', 'k', 'LineWidth', 1.5, 'DisplayName', 'C: Nuevo SS largo plazo')

% Etiquetas
text(A_e*100-0.15, A_p*100+0.05, 'A', 'FontSize', 14, 'FontWeight', 'bold', 'Color', C.green)
text(B_e*100+0.05, B_p*100+0.05, 'B', 'FontSize', 14, 'FontWeight', 'bold', 'Color', C.orange)
text(C_e*100+0.05, C_p*100+0.05, 'C', 'FontSize', 14, 'FontWeight', 'bold', 'Color', C.blue)
text(B_e*100+0.05, B_p*100-0.10, sprintf('Overshooting:\n\\Deltae_0 = %.2f\\Deltam', params.de_dm), ...
    'FontSize', 9, 'Color', C.orange)

xlabel('Tipo de cambio log e (%)', 'FontSize', 13)
ylabel('Nivel de precios log p (%)', 'FontSize', 13)
title({'Diagrama de Fase: Dornbusch (1976)'; ...
    sprintf('Expansion monetaria \\Deltam = %.0f%%', dm*100)}, ...
    'FontSize', 14, 'FontWeight', 'bold')
legend('Location', 'northwest', 'FontSize', 10)
xlim([min(e_range)*100-0.2, max(e_range)*100+0.2])
ylim([min(p_pdot0_inicial)*100-0.2, max(p_pdot0_nueva)*100+0.2])
grid on; box on

% Vectores de campo (direccion del movimiento fuera del equilibrio)
[E_grid, P_grid] = meshgrid(linspace(-0.01, 0.04, 8), linspace(-0.01, 0.025, 8));
% dp/dt < 0 si p > p-dot=0 locus, dp/dt > 0 si p < p-dot=0 locus
dP = -params.pi_p * (E_grid - P_grid) * params.delta;
dE = -(1/(params.lambda*params.theta)) .* dP;  % e se mueve con p via QQ
scale = 0.002;
quiver(E_grid*100, P_grid*100, dE*100*scale, dP*100*scale, 0, ...
    'Color', [0.7 0.7 0.7], 'LineWidth', 0.8, 'MaxHeadSize', 0.3)

saveas(fig2, 'Fig2_Diagrama_Fase.png')
fprintf('Figura 2 guardada: Fig2_Diagrama_Fase.png\n')

%==========================================================================
% SECCION 3: ANALISIS DE SENSIBILIDAD DEL OVERSHOOTING
%==========================================================================

fprintf('\n\n=== SECCION 3: ANALISIS DE SENSIBILIDAD ===\n')

fig3 = figure('Name', 'Sensibilidad del Overshooting', 'Position', [100 100 1200 500]);

% 3a: de/dm como funcion de lambda
lambda_vec = linspace(0.1, 2.0, 100);
theta_vec_lambda = zeros(size(lambda_vec));
de_dm_lambda = zeros(size(lambda_vec));
for i = 1:length(lambda_vec)
    A_i = params.sigma/lambda_vec(i) + params.delta;
    theta_i = params.pi_p*A_i/2 + sqrt((params.pi_p*A_i/2)^2 + params.pi_p*params.delta/lambda_vec(i));
    de_dm_lambda(i) = 1 + 1/(lambda_vec(i) * theta_i);
end

subplot(1,3,1)
plot(lambda_vec, de_dm_lambda, 'Color', C.blue, 'LineWidth', 2.5)
yline(1, '--', 'Color', C.gray, 'LineWidth', 1.5, 'DisplayName', 'Ajuste exacto (de/dm=1)')
xline(params.lambda, '--', 'Color', C.red, 'LineWidth', 1.5, 'DisplayName', 'Calibracion base')
xlabel('\lambda (semielasticidad-interes dm)', 'FontSize', 11)
ylabel('de/dm (overshooting)', 'FontSize', 11)
title({'Overshooting vs \lambda'; '(mayor \lambda => menor overshooting)'}, 'FontSize', 11)
grid on; box on; ylim([1, 15])
legend({'de/dm', 'Ajuste exacto', 'Base: \lambda=0.5'}, 'Location', 'northeast', 'FontSize', 8)

% 3b: de/dm como funcion de pi_p
pi_vec = linspace(0.05, 2.0, 100);
de_dm_pi = zeros(size(pi_vec));
for i = 1:length(pi_vec)
    A_i = params.sigma/params.lambda + params.delta;
    theta_i = pi_vec(i)*A_i/2 + sqrt((pi_vec(i)*A_i/2)^2 + pi_vec(i)*params.delta/params.lambda);
    de_dm_pi(i) = 1 + 1/(params.lambda * theta_i);
end

subplot(1,3,2)
plot(pi_vec, de_dm_pi, 'Color', C.orange, 'LineWidth', 2.5)
yline(1, '--', 'Color', C.gray, 'LineWidth', 1.5)
xline(params.pi_p, '--', 'Color', C.red, 'LineWidth', 1.5)
xlabel('\pi (velocidad ajuste precios)', 'FontSize', 11)
ylabel('de/dm (overshooting)', 'FontSize', 11)
title({'Overshooting vs \pi'; '(mayor \pi => menor overshooting)'}, 'FontSize', 11)
grid on; box on; ylim([1, 8])
legend({'de/dm', 'Ajuste exacto', 'Base: \pi=0.4'}, 'Location', 'northeast', 'FontSize', 8)

% 3c: de/dm como funcion de delta
delta_vec = linspace(0.1, 1.5, 100);
de_dm_delta = zeros(size(delta_vec));
for i = 1:length(delta_vec)
    A_i = params.sigma/params.lambda + delta_vec(i);
    theta_i = params.pi_p*A_i/2 + sqrt((params.pi_p*A_i/2)^2 + params.pi_p*delta_vec(i)/params.lambda);
    de_dm_delta(i) = 1 + 1/(params.lambda * theta_i);
end

subplot(1,3,3)
plot(delta_vec, de_dm_delta, 'Color', C.green, 'LineWidth', 2.5)
yline(1, '--', 'Color', C.gray, 'LineWidth', 1.5)
xline(params.delta, '--', 'Color', C.red, 'LineWidth', 1.5)
xlabel('\delta (elasticidad precio-relativo)', 'FontSize', 11)
ylabel('de/dm (overshooting)', 'FontSize', 11)
title({'Overshooting vs \delta'; '(mayor \delta => menor overshooting)'}, 'FontSize', 11)
grid on; box on; ylim([1, 8])
legend({'de/dm', 'Ajuste exacto', 'Base: \delta=0.6'}, 'Location', 'northeast', 'FontSize', 8)

sgtitle('Analisis de Sensibilidad: Overshooting de/dm vs Parametros Estructurales', ...
    'FontSize', 13, 'FontWeight', 'bold')

saveas(fig3, 'Fig3_Sensibilidad_Overshooting.png')
fprintf('Figura 3 guardada: Fig3_Sensibilidad_Overshooting.png\n')

%==========================================================================
% SECCION 4: COMPARACION OVER vs UNDER-SHOOTING (output variable)
%==========================================================================

fprintf('\n\n=== SECCION 4: OVER vs UNDER-SHOOTING (Output Variable) ===\n')

fig4 = figure('Name', 'Over vs Under-Shooting', 'Position', [100 100 1200 500]);

% Tres escenarios para gamma_y (propension marginal)
gamma_scenarios = [0.20, 0.40, 0.65];
labels = {'Over-shooting (\gamma=0.20, \phi\mu\delta=0.50)', ...
          'Limite (\gamma=0.40, \phi\mu\delta=1.00)', ...
          'Under-shooting (\gamma=0.65, \phi\mu\delta=1.71)'};
colors_sc = {C.orange, C.green, C.blue};

T_plot = 0:0.1:25;

for sc = 1:3
    g = gamma_scenarios(sc);
    mu_sc = 1/(1 - g);
    phi_mu_delta = params.phi * mu_sc * params.delta;

    % Con output variable, la Ec. (A8) del paper cambia el coeficiente:
    % e - ebar = -[(1 - phi*mu*delta)/Delta]*(p - pbar)
    % donde Delta = phi*mu*(delta + sigma*theta) + theta*lambda
    % Recalcular theta para este escenario
    % (Usando la condicion theta = pi*w de la Ec. A10)
    w_sc = (mu_sc*(params.delta + params.sigma*params.theta) + params.delta*params.lambda) / ...
           (params.lambda*(1 + params.phi*mu_sc));
    theta_sc = params.pi_p * w_sc;  % Aproximacion lineal

    Delta_sc = params.phi * mu_sc * (params.delta + params.sigma*theta_sc) + theta_sc*params.lambda;
    coef_ep = (1 - phi_mu_delta) / Delta_sc;
    de_dm_sc = 1 + coef_ep;

    % Velocidad de convergencia ajustada
    v_sc = params.pi_p * w_sc;

    % Trayectorias
    e_new_sc = dm; p_new_sc = dm;
    e0_sc = e_new_sc + (de_dm_sc - 1)*dm;  % impacto
    e_sc = e_new_sc + (e0_sc - e_new_sc)*exp(-v_sc*T_plot);
    p_sc = p_new_sc + (0 - p_new_sc)*exp(-v_sc*T_plot);

    subplot(1,3,sc)
    hold on
    plot(T_plot, e_sc*100, 'Color', colors_sc{sc}, 'LineWidth', 2.5, 'DisplayName', 'e(t)')
    plot(T_plot, p_sc*100, '--', 'Color', C.blue, 'LineWidth', 2.0, 'DisplayName', 'p(t)')
    yline(dm*100, ':', 'Color', C.gray, 'LineWidth', 1.5, 'DisplayName', 'Nuevo SS')
    xlabel('Tiempo', 'FontSize', 10)
    ylabel('Variacion % respecto al SS', 'FontSize', 10)
    title({labels{sc}; sprintf('de/dm = %.3f | \\phimu\\delta = %.2f', de_dm_sc, phi_mu_delta)}, ...
        'FontSize', 9)
    legend('Location', 'northeast', 'FontSize', 8)
    grid on; box on

    fprintf('Escenario %d: gamma=%.2f, phi*mu*delta=%.3f, de/dm=%.4f => %s\n', ...
        sc, g, phi_mu_delta, de_dm_sc, ternary(de_dm_sc > 1, 'OVER-SHOOTING', 'UNDER-SHOOTING'))
end

sgtitle({'Comparacion: Overshooting vs Under-shooting con Output Variable'; ...
    'Segun condicion de la Ec. (20): 1 - \phi\mu\delta \gtrless 0'}, ...
    'FontSize', 12, 'FontWeight', 'bold')

saveas(fig4, 'Fig4_Over_vs_Under.png')
fprintf('Figura 4 guardada: Fig4_Over_vs_Under.png\n')

%==========================================================================
% SECCION 5: CORRER LOS MODELOS DYNARE
%==========================================================================

fprintf('\n\n=== SECCION 5: EJECUTANDO MODELOS DYNARE ===\n')
fprintf('Asegurate de que Dynare este en el MATLAB path.\n\n')

run_dynare = true;  % Cambiar a false para saltar Dynare y solo ver graficas MATLAB

if run_dynare
    try
        fprintf('>> Corriendo dornbusch_baseline.mod...\n')
        dynare dornbusch_baseline noclearall
        fprintf('   [OK] Modelo base completado.\n')

        fprintf('>> Corriendo dornbusch_variable_output.mod...\n')
        dynare dornbusch_variable_output noclearall
        fprintf('   [OK] Modelo output variable completado.\n')

        fprintf('>> Corriendo dornbusch_estimation.mod (simulacion sin datos)...\n')
        dynare dornbusch_estimation noclearall
        fprintf('   [OK] Modelo de estimacion completado.\n')

    catch ME
        fprintf('\n[AVISO] Error al correr Dynare: %s\n', ME.message)
        fprintf('Revisa que Dynare este correctamente instalado y en el path.\n')
        fprintf('Las graficas MATLAB ya estan guardadas.\n')
    end
else
    fprintf('[INFO] Dynare saltado. Graficas MATLAB disponibles.\n')
end

%==========================================================================
% RESUMEN FINAL
%==========================================================================

fprintf('\n\n==========================================\n')
fprintf('RESUMEN: RESULTADOS DEL MODELO DORNBUSCH\n')
fprintf('==========================================\n')
fprintf('\nParametros estructurales:\n')
fprintf('  lambda = %.2f  |  delta = %.2f  |  sigma = %.2f  |  pi = %.2f\n', ...
    params.lambda, params.delta, params.sigma, params.pi_p)
fprintf('\nResultados clave:\n')
fprintf('  theta-tilde (Ec. 15)  = %.4f\n', params.theta)
fprintf('  v, tasa convergencia  = %.4f\n', params.v)
fprintf('  de/dm (Ec. 16)        = %.4f  => %.1f%% de depreciacion por 1%% de choque monetario\n', ...
    params.de_dm, params.de_dm*100)
fprintf('\nArchivos generados:\n')
fprintf('  Fig1_Trayectorias_Analiticas.png\n')
fprintf('  Fig2_Diagrama_Fase.png\n')
fprintf('  Fig3_Sensibilidad_Overshooting.png\n')
fprintf('  Fig4_Over_vs_Under.png\n')
if run_dynare
    fprintf('  (Resultados Dynare en subcarpetas /dornbusch_*/)\n')
end

%==========================================================================
% FUNCIONES AUXILIARES
%==========================================================================

function out = ternary(cond, a, b)
    if cond; out = a; else; out = b; end
end

function annotation_overshooting(de_dm, dm, C)
    % Agrega texto explicativo en la grafica de e(t)
    text(0.5, de_dm*dm*100*0.95, ...
        sprintf('Overshooting:\n\\Deltae_0/\\Deltam = %.2f', de_dm), ...
        'FontSize', 8, 'Color', C.orange, 'BackgroundColor', 'white', ...
        'EdgeColor', C.orange)
end

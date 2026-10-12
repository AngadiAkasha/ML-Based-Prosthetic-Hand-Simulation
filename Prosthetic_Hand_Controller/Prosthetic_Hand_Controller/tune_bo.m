
function [Kp,Ki,Kd,info] = tune_bo(G_plant)
% Bayesian Optimization PID tuning for prosthetic hand
% Requires Control System Toolbox and Statistics and Machine Learning Toolbox

    if nargin < 1 || isempty(G_plant)
        G_plant = plant_modeling();
    end

    % Define search ranges for PID gains (same as tune_ga.m)
    vars = [
        optimizableVariable('Kp',[0 500])
        optimizableVariable('Ki',[0 500])
        optimizableVariable('Kd',[0 500])
    ];

    % Objective function
    objectiveFcn = @(x) boObjective(x,G_plant);

    % Run Bayesian Optimization
    results = bayesopt(objectiveFcn,vars, ...
        'MaxObjectiveEvaluations',30, ...
        'NumSeedPoints',8, ...
        'AcquisitionFunctionName','expected-improvement-plus', ...
        'IsObjectiveDeterministic',true, ...
        'UseParallel',false, ...
        'Verbose',1, ...
        'PlotFcn',[]);

    % Extract best gains
    best = results.XAtMinObjective;
    Kp = best.Kp(1);
    Ki = best.Ki(1);
    Kd = best.Kd(1);

    % Evaluate final controller
    C = pid(Kp,Ki,Kd);
    T = feedback(C*G_plant,1);
    S = stepinfo(T,'RiseTimeLimits',[0 1]);

    info.cost = results.MinObjective;
    info.stepinfo = S;
    info.results = results;

    fprintf('\nBayesian Optimization PID Results:\n');
    fprintf('Kp = %.6f\nKi = %.6f\nKd = %.6f\n',Kp,Ki,Kd);
    fprintf('Cost = %.6f\n',info.cost);
    fprintf('Rise Time = %.4f s\n',S.RiseTime);
    fprintf('Settling Time = %.4f s\n',S.SettlingTime);
    fprintf('Overshoot = %.4f %%\n',S.Overshoot);
end

function J = boObjective(x,G_plant)
% Minimize rise time, settling time, and overshoot

    J = 1e6;

    try
        C = pid(x.Kp,x.Ki,x.Kd);
        T = feedback(C*G_plant,1);

        % Penalize unstable systems
        if ~isstable(T)
            return;
        end

        S = stepinfo(T,'RiseTimeLimits',[0 1]);

        RT = S.RiseTime;
        ST = S.SettlingTime;
        OS = S.Overshoot;

        if any(~isfinite([RT,ST,OS])) || ...
                any([RT,ST,OS] < 0)
            return;
        end

        % Same objective function as tune_ga.m
        J = RT + ST + 3*(OS^2)/100;

    catch
        J = 1e6;
    end
end

function [Kp,Ki,Kd,info] = tune_ga(G_plant)
%TUNE_GA  Genetic-Algorithm PID tuning (Section III-B-4 of the paper).
%
%   [Kp,Ki,Kd,info] = tune_ga(G_plant)
%
%   Minimises a weighted cost of rise time, settling time and overshoot,
%   mirroring the paper's stated aim: "minimum rise time, settling time,
%   and zero overshoot". The paper's reported result (Table 4) is
%   rise = 0.1579 s, settling = 0.7181 s, overshoot = 0%; this script's
%   cost function is built so driving overshoot to zero dominates the
%   search, matching that outcome.
%
%   Requires Global Optimization Toolbox (ga) and Control System Toolbox.

    if nargin < 1 || isempty(G_plant)
        G_plant = plant_modeling();
    end

    costFcn = @(x) pidCost(x, G_plant);

    nVars = 3;                 % [Kp Ki Kd]
    lb = [0 0 0];
    ub = [500 500 500];        % same bounds as the paper's optimtool setup (Fig.9)

    opts = optimoptions('ga', ...
        'PopulationSize',   60, ...
        'MaxGenerations',   150, ...
        'FunctionTolerance', 1e-8, ...
        'UseParallel',      false, ...
        'Display',          'iter');

    [x, fval] = ga(costFcn, nVars, [],[],[],[], lb, ub, [], opts);

    Kp = x(1); Ki = x(2); Kd = x(3);

    C = pid(Kp,Ki,Kd);
    T = feedback(C*G_plant,1);
    S = stepinfo(T,'RiseTimeLimits',[0 1]);

    info = struct('cost',fval,'stepinfo',S);

    fprintf('\nGenetic Algorithm PID tuning:\n');
    fprintf('  Kp = %.6g    Ki = %.6g    Kd = %.6g\n', Kp, Ki, Kd);
    fprintf('  Rise time     : %.4f s   (paper: 0.1579 s)\n', S.RiseTime);
    fprintf('  Settling time : %.4f s   (paper: 0.7181 s)\n', S.SettlingTime);
    fprintf('  Overshoot     : %.4f %%  (paper: 0%%)\n', S.Overshoot);

    if nargout == 0
        figure('Name','GA-tuned PID step response');
        step(T); grid on;
        title(sprintf('GA PID (Kp=%.3g, Ki=%.3g, Kd=%.3g)',Kp,Ki,Kd));
    end
end

function J = pidCost(x, G_plant)
    Kp = x(1); Ki = x(2); Kd = x(3);
    C  = pid(Kp,Ki,Kd);
    T  = feedback(C*G_plant,1);

    if ~isstable(T)
        J = 1e6;
        return;
    end

    try
        S = stepinfo(T,'RiseTimeLimits',[0 1]);
    catch
        J = 1e6;
        return;
    end

    rt = S.RiseTime;      if isnan(rt) || isinf(rt), rt = 5; end
    st = S.SettlingTime;  if isnan(st) || isinf(st), st = 5; end
    os = S.Overshoot;     if isnan(os), os = 100; end

    % Rise time and settling time contribute linearly; overshoot is
    % penalised quadratically so the optimiser strongly favours 0%
    % overshoot, matching the paper's Table 4 result.
    J = 1.0*rt + 1.0*st + 3.0*(os^2)/100;
end

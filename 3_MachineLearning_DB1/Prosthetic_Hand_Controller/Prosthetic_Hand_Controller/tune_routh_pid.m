
function [Kp, Ki, Kd, info] = tune_routh_pid(G_plant)
% TUNE_ROUTH_PID
% PID tuning using:
%   1. Candidate gain search
%   2. Routh-Hurwitz closed-loop stability check
%   3. Settling-time and overshoot minimization
%
% Requires Control System Toolbox.
% Uses fminsearch from base MATLAB.
%
% Example:
%   G = plant_modeling();
%   [Kp,Ki,Kd,info] = tune_routh_pid(G);

    if nargin < 1 || isempty(G_plant)
        G_plant = plant_modeling();
    end

    G_plant = minreal(tf(G_plant));
    [num, den] = tfdata(G_plant, 'v');

    % This implementation assumes a SISO plant with real coefficients.
    if ~issiso(G_plant) || ~isreal(num) || ~isreal(den)
        error('Provide a real-coefficient SISO transfer function.');
    end

    % Search limits: adjust if your application needs different ranges.
    lb = [1e-4, 1e-5, 1e-4];   % Kp, Ki, Kd
    ub = [100, 100, 100];

    % Start from reasonable positive gains.
    initial = [0.2, 0.15, 10];

    % Include the initial candidate and a log-spaced random search.
    rng(7, 'twister');
    nCandidates = 400;
    candidates = lb .* (ub ./ lb).^rand(nCandidates, 3);
    candidates(1,:) = min(max(initial, lb), ub);

    bestScore = inf;
    bestGains = [];

    % Search for a stable initial solution.
    for i = 1:size(candidates, 1)
        g = candidates(i,:);
        score = pidObjective(log(g), G_plant, lb, ub);

        if isfinite(score) && score < bestScore
            bestScore = score;
            bestGains = g;
        end
    end

    if isempty(bestGains)
        error(['No stable PID candidate found. Try widening the gain ', ...
               'ranges or checking the plant model.']);
    end

    % Refine the best candidate using unconstrained local optimization.
    options = optimset('Display', 'iter', ...
                       'MaxIter', 500, ...
                       'MaxFunEvals', 1500, ...
                       'TolX', 1e-5, ...
                       'TolFun', 1e-5);

    z0 = log(bestGains);
    zOpt = fminsearch(@(z) pidObjective(z, G_plant, lb, ub), ...
                      z0, options);

    gains = min(max(exp(zOpt), lb), ub);
    Kp = gains(1);
    Ki = gains(2);
    Kd = gains(3);

    % Final verification.
    C = pid(Kp, Ki, Kd);
    T = feedback(C * G_plant, 1);
    charPoly = closedLoopPolynomial(num, den, Kp, Ki, Kd);
    [routhStable, firstColumn] = routhCheck(charPoly);

    if ~isstable(T) || ~routhStable
        error('Final candidate failed the closed-loop stability check.');
    end

    metrics = stepinfo(T);
    info.Kp = Kp;
    info.Ki = Ki;
    info.Kd = Kd;
    info.SettlingTime = metrics.SettlingTime;
    info.RiseTime = metrics.RiseTime;
    info.Overshoot = metrics.Overshoot;
    info.RouthStable = routhStable;
    info.RouthFirstColumn = firstColumn;
    info.CharacteristicPolynomial = charPoly;
    info.Objective = bestScore;
    info.ClosedLoop = T;

    fprintf('\n===== Routh-Hurwitz PID Results =====\n');
    fprintf('Kp              : %.8g\n', Kp);
    fprintf('Ki              : %.8g\n', Ki);
    fprintf('Kd              : %.8g\n', Kd);
    fprintf('Settling time   : %.6g seconds\n', info.SettlingTime);
    fprintf('Rise time       : %.6g seconds\n', info.RiseTime);
    fprintf('Overshoot       : %.4f %%\n', info.Overshoot);
    fprintf('Routh stable    : %d\n', info.RouthStable);
    fprintf('=====================================\n');
end


function J = pidObjective(z, G, lb, ub)
% Objective: minimize settling time and overshoot.
% Unstable candidates receive a large penalty.

    J = 1e12;

    if any(~isfinite(z))
        return;
    end

    % Keep optimization inside the allowed gain ranges.
    z = min(max(z, log(lb)), log(ub));
    gains = exp(z);

    Kp = gains(1);
    Ki = gains(2);
    Kd = gains(3);

    [num, den] = tfdata(G, 'v');
    p = closedLoopPolynomial(num, den, Kp, Ki, Kd);

    [rhStable, ~] = routhCheck(p);
    if ~rhStable
        return;
    end

    try
        T = feedback(pid(Kp, Ki, Kd) * G, 1);

        if ~isstable(T)
            return;
        end

        m = stepinfo(T);

        if ~isfinite(m.SettlingTime) || ...
           ~isfinite(m.Overshoot) || m.SettlingTime <= 0
            return;
        end

        % Settling time plus overshoot penalty.
        % Overshoot above 10% receives an additional penalty.
        J = m.SettlingTime ...
            + 0.05 * m.Overshoot ...
            + 20 * max(0, m.Overshoot - 10)^2;

    catch
        J = 1e12;
    end
end


function p = closedLoopPolynomial(num, den, Kp, Ki, Kd)
% Unity-feedback characteristic polynomial:
% s*den(s) + num(s)*(Kd*s^2 + Kp*s + Ki) = 0

    controllerNumerator = [Kd, Kp, Ki];
    p1 = conv([1, 0], den);
    p2 = conv(num, controllerNumerator);

    % Align polynomial vectors before adding.
    n = max(length(p1), length(p2));
    p1 = [zeros(1, n-length(p1)), p1];
    p2 = [zeros(1, n-length(p2)), p2];

    p = p1 + p2;

    % Remove negligible leading coefficients only.
    while length(p) > 1 && abs(p(1)) < 1e-12
        p(1) = [];
    end
end


function [stable, firstColumn] = routhCheck(coeff)
% Routh-Hurwitz test using the first column of the Routh array.
% A near-zero first-column entry is replaced by a small positive epsilon.
% An all-zero row is handled using the auxiliary polynomial.

    coeff = coeff(:).';
    coeff = coeff / max(abs(coeff));

    n = length(coeff) - 1;
    rows = n + 1;
    cols = ceil(length(coeff) / 2);
    R = zeros(rows, cols);

    R(1, 1:length(coeff(1:2:end))) = coeff(1:2:end);
    if length(coeff) >= 2
        R(2, 1:length(coeff(2:2:end))) = coeff(2:2:end);
    end

    epsR = 1e-9;

    for i = 3:rows
        if all(abs(R(i-1,:)) < epsR)
            % Auxiliary polynomial from the row above.
            power = n - (i - 2);
            for j = 1:cols
                exponent = power - 2*(j-1);
                if exponent >= 1
                    R(i-1,j) = R(i-2,j) * exponent;
                else
                    R(i-1,j) = 0;
                end
            end
        end

        if abs(R(i-1,1)) < epsR
            R(i-1,1) = epsR;
        end

        for j = 1:cols-1
            R(i,j) = (R(i-1,1)*R(i-2,j+1) ...
                     - R(i-2,1)*R(i-1,j+1)) / R(i-1,1);
        end
    end

    firstColumn = R(:,1);
    stable = all(isfinite(firstColumn)) && ...
             all(firstColumn > epsR);
end

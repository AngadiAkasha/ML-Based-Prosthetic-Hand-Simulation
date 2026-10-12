function [Kp,Ki,Kd,Kcr,Pcr] = tune_zn(G_plant)
%TUNE_ZN  Ziegler-Nichols closed-loop (2nd-method) PID tuning.
%
%   [Kp,Ki,Kd,Kcr,Pcr] = tune_zn(G_plant)
%
%   Reproduces Section III-A / Fig. 5 / Table 3 of the reference paper:
%     1) Raise a pure-proportional gain K until the closed loop is on the
%        verge of sustained oscillation -> critical gain Kcr.
%     2) Read the oscillation period at that point -> Pcr.
%     3) Apply the paper's Table 3 PID row: Kp = 0.6 Kcr,
%        Ti = 0.5 Pcr, Td = 0.125 Pcr.
%
%   Requires Control System Toolbox.

    if nargin < 1 || isempty(G_plant)
        G_plant = plant_modeling();
    end

    % The gain that drives the loop to the verge of instability is the
    % plant's gain margin; the frequency at which that happens (phase
    % crossover) sets the oscillation period Pcr = 2*pi/Wcp.
    [Gm, ~, Wcp, ~] = margin(G_plant);

    if isempty(Wcp) || isnan(Gm) || isinf(Gm) || Gm <= 0
        error(['tune_zn:noCrossover', newline, ...
               'No finite phase crossover was found for this plant, so ', ...
               'proportional-only feedback never sustains oscillation. ', ...
               'This mirrors the paper''s own caveat (Section III-A): ', ...
               '"Whatever the taken Kp value this method cannot be applied ', ...
               'if the exhibition of output response not sustained ', ...
               'oscillations." Use tune_ga.m instead.']);
    end

    Kcr = Gm;
    Pcr = 2*pi / Wcp;

    Kp = 0.6  * Kcr;
    Ti = 0.5  * Pcr;
    Td = 0.125 * Pcr;

    Ki = Kp / Ti;
    Kd = Kp * Td;

    fprintf('Ziegler-Nichols (closed-loop) PID tuning:\n');
    fprintf('  Kcr = %.6g    Pcr = %.6g s\n', Kcr, Pcr);
    fprintf('  Kp  = %.6g    Ki  = %.6g    Kd = %.6g\n', Kp, Ki, Kd);

    if nargout == 0
        C  = pid(Kp,Ki,Kd);
        T  = feedback(C*G_plant,1);
        S  = stepinfo(T,'RiseTimeLimits',[0 1]); %#ok<NASGU>
        figure('Name','Ziegler-Nichols PID step response');
        step(T); grid on;
        title(sprintf('ZN PID (Kp=%.3g, Ki=%.3g, Kd=%.3g)',Kp,Ki,Kd));
    end
end

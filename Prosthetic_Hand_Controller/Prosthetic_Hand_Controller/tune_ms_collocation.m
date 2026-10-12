
function [Kp,Ki,Kd,info] = tune_ms_collocation(G_plant)
% TUNE_MS_COLLOCATION
% Multiple-shooting PID tuning using constrained direct transcription.
%
% Requires Control System Toolbox and Optimization Toolbox (fmincon).
% This is a discrete-time multiple-shooting prototype, not a reproduction
% of the paper's exact finite-element collocation implementation.

    if nargin < 1 || isempty(G_plant)
        G_plant = plant_modeling();
    end

    % Discretize the plant for the finite-horizon optimization.
    Ts = 0.02;
    N  = 100;                 % 2-second tuning horizon

    Gss = ss(G_plant);
    Gd = c2d(Gss,Ts,'zoh');
    [A,B,C,D] = ssdata(Gd);

    nx = size(A,1);

    if norm(D,'fro') > 1e-9
        error('This prototype assumes a plant with zero direct feedthrough.');
    end

    % Decision variables:
    % z = [Kp Ki Kd, X(:), I(:)]
    % X contains all shooting-node plant states.
    % I contains integral-error states at all nodes.
    nX = nx*(N+1);
    nI = N+1;
    nZ = 3+nX+nI;

    x0 = zeros(nZ,1);
    x0(1:3) = [1 1 0.01];

    % Gain bounds; states and integral states are unrestricted.
    lb = [-0*ones(3,1); -inf(nX+nI,1)];
    ub = [500*ones(3,1); inf(nX+nI,1)];

    opts = optimoptions('fmincon', ...
        'Algorithm','sqp', ...
        'Display','iter', ...
        'MaxIterations',200, ...
        'MaxFunctionEvaluations',50000, ...
        'ConstraintTolerance',1e-6);

    objective = @(z) msObjective(z,A,B,C,D,Ts,N,nx);
    constraints = @(z) msConstraints(z,A,B,C,D,Ts,N,nx);

    fprintf('Starting multiple-shooting PID optimization...\n');
    [z,fval,exitflag,output] = fmincon( ...
        objective,x0,[],[],[],[],lb,ub,constraints,opts);

    Kp = z(1);
    Ki = z(2);
    Kd = z(3);

    % Evaluate the optimized continuous-time closed loop.
    T = feedback(pid(Kp,Ki,Kd)*G_plant,1);
    S = stepinfo(T,'RiseTimeLimits',[0 1]);

    info = struct();
    info.cost = fval;
    info.exitflag = exitflag;
    info.output = output;
    info.stepinfo = S;
    info.closedLoop = T;
    info.sampleTime = Ts;
    info.horizon = N*Ts;

    fprintf('\nMultiple-Shooting PID Results:\n');
    fprintf('Kp = %.6f\nKi = %.6f\nKd = %.6f\n',Kp,Ki,Kd);
    fprintf('Cost = %.6f\n',fval);
    fprintf('Rise time = %.4f s\n',S.RiseTime);
    fprintf('Settling time = %.4f s\n',S.SettlingTime);
    fprintf('Overshoot = %.4f %%\n',S.Overshoot);

    if nargout == 0
        figure('Name','Multiple-Shooting PID Response');
        step(T); grid on;
        title('Multiple-Shooting Optimized PID');
    end
end


function J = msObjective(z,A,B,C,D,Ts,N,nx)
% Minimize finite-horizon tracking error and control effort.

    [Kp,Ki,Kd,X,I] = unpack(z,N,nx);
    r = ones(1,N+1);
    y = C*X + D*zeros(1,N+1);
    e = r-y;

    u = zeros(1,N);
    for k = 1:N
        de = (e(k+1)-e(k))/Ts;
        u(k) = Kp*e(k) + Ki*I(k) + Kd*de;
    end

    J = Ts*sum(e.^2) + 1e-4*Ts*sum(u.^2);
end


function [c,ceq] = msConstraints(z,A,B,C,D,Ts,N,nx)
% Equality constraints enforce the plant and integral-state dynamics.

    [Kp,Ki,Kd,X,I] = unpack(z,N,nx);

    r = ones(1,N+1);
    y = C*X + D*zeros(1,N+1);
    e = r-y;

    u = zeros(1,N);
    for k = 1:N
        de = (e(k+1)-e(k))/Ts;
        u(k) = Kp*e(k) + Ki*I(k) + Kd*de;
    end

    % Initial states are zero.
    ceq = [X(:,1); I(1)];

    % Multiple-shooting continuity constraints.
    for k = 1:N
        plantResidual = X(:,k+1) - A*X(:,k) - B*u(k);
        integralResidual = I(k+1) - I(k) - Ts*e(k);

        ceq = [ceq; plantResidual; integralResidual]; %#ok<AGROW>
    end

    % No additional inequality constraints in this prototype.
    c = [];
end


function [Kp,Ki,Kd,X,I] = unpack(z,N,nx)
% Convert the decision vector into controller gains and trajectories.

    Kp = z(1);
    Ki = z(2);
    Kd = z(3);

    nX = nx*(N+1);
    X = reshape(z(4:3+nX),nx,N+1);
    I = z(4+nX:3+nX+N+1).';
end

function setup_prosthetic_controller()
%SETUP_PROSTHETIC_CONTROLLER  One-shot setup for the prosthetic-hand
%controller.
%
%   Tunes the PID controller with BOTH methods from the paper
%   (Ziegler-Nichols and Genetic Algorithm), prints the same rise-time /
%   settling-time / overshoot comparison as the paper's Table 4, then
%   keeps the GA gains as the controller's operating point - the paper
%   found GA to dominate ZN on every metric (rise time, settling time,
%   AND overshoot). Saves PIDGains.mat for runController.m.
%
%   Usage:
%       setup_prosthetic_controller
%       runController
%       visualizeRandomForest        % 3-D hand, from your existing script

    clc;
    fprintf('=== Prosthetic Hand Controller Setup (Ninapro DB1) ===\n\n');

    G_plant = plant_modeling();

    fprintf('--- Ziegler-Nichols closed-loop tuning ---\n');
    [KpZN,KiZN,KdZN,KcrZN,PcrZN] = tune_zn(G_plant); %#ok<ASGLU>

    fprintf('\n--- Genetic Algorithm tuning ---\n');
    [KpGA,KiGA,KdGA,gaInfo] = tune_ga(G_plant);

    % Operating gains = GA result (best per the paper's comparison).
    Kp = KpGA; Ki = KiGA; Kd = KdGA; %#ok<NASGU>
    save('PIDGains.mat','Kp','Ki','Kd','KpZN','KiZN','KdZN','gaInfo');

    %% Side-by-side comparison, mirroring paper Table 4 -------------------
    CzN = pid(KpZN,KiZN,KdZN);  TzN = feedback(CzN*G_plant,1);
    CgA = pid(KpGA,KiGA,KdGA);  TgA = feedback(CgA*G_plant,1);
    SzN = stepinfo(TzN,'RiseTimeLimits',[0 1]);
    SgA = stepinfo(TgA,'RiseTimeLimits',[0 1]);

    fprintf('\n%-16s %14s %14s\n','Metric','Ziegler-Nichols','Genetic Algo.');
    fprintf('%-16s %14.4f %14.4f\n','Rise time (s)',   SzN.RiseTime,     SgA.RiseTime);
    fprintf('%-16s %14.4f %14.4f\n','Settling time (s)',SzN.SettlingTime,SgA.SettlingTime);
    fprintf('%-16s %14.4f %14.4f\n','Overshoot (%)',   SzN.Overshoot,    SgA.Overshoot);

    figure('Name','ZN vs GA step response');
    step(TzN,TgA); grid on; legend('Ziegler-Nichols','Genetic Algorithm');
    title('Finger position step response: tuning-method comparison');

    fprintf('\nSaved PIDGains.mat. Next: run runController.m\n');
end

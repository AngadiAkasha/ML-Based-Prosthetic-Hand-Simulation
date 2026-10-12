function G_plant = plant_modeling()
%PLANT_MODELING  DC-motor + finger-joint plant model for the prosthetic hand.
%
%   G_plant = plant_modeling()
%
%   Reproduces the plant described in:
%     Orban, Zhang, Lu, Marcal, Emad, Masengo, "Precise Control Method on
%     Prosthetic Hand Using sEMG Signals," ICCTA 2020 (Section II-B,
%     Table 2, Eq. 1-2).
%
%   All five fingers are driven by identical FAULHABER 1024-SR DC motors,
%   so this single plant model is reused for every finger channel in
%   runController.m.
%
%   -------------------------------------------------------------------
%   Eq. 1 (raw DC-motor model, voltage -> shaft angle) is:
%
%       theta(s)/V(s) = kt / [ La*Jm*s^3 + (Ra + La*Bm)*s^2 + (Ra*Bm + Kb*Ksh)*s ]
%
%   Table 2 gives Va, Ra, La, Ia, omega, J, Ksh and Kb numerically, but it
%   does NOT give Bm (viscous friction coefficient), so Eq. 1 cannot be
%   evaluated from the paper alone. This is exactly why the paper says
%   "Design by using analytical methods is not applicable especially
%   when the system plant mathematical model does not exist" and instead
%   identifies the OVERALL plant (motor + gearing/tendon wiring) directly
%   from voltage/angle data using MATLAB's System Identification Toolbox.
%   That identified result is Eq. 2 below, and it is what the paper's PID
%   design (and this controller) actually uses.
%   -------------------------------------------------------------------

    %% Table 2 - DC motor / mechanical parameters (kept for reference,
    %  e.g. if you later re-identify the plant from your own hardware)
    motorParams.Va  = 12;       % armature voltage        (V)
    motorParams.Ra  = 1.36;     % armature resistance     (ohm)
    motorParams.La  = 0.016;    % armature inductance     (H)
    motorParams.Ia  = 0.016;    % armature current        (A)
    motorParams.w   = 1277;     % angular speed           (rad/s)
    motorParams.J   = 0.012;    % rotor inertia           (kg m^2)
    motorParams.Ksh = 0.00233;  % torque constant         (Nm/A)
    motorParams.Kb  = 0.00244;  % back-emf constant       (Vs/rad)
    assignin('base','motorParams',motorParams);

    %% Eq. 2 - overall identified plant, voltage -> finger joint angle
    num = [1.228e-05, -0.00826, 4.168, 0.1582];
    den = [1, 2.036, 0.6095, 0.02007, 6.027e-07];
    G_plant = tf(num, den);

    %% --- How to re-identify this plant from your own hardware ---------
    % If/when you have real Simulink "To Workspace" logs of applied
    % voltage vs. measured finger angle (see setup_prosthetic_controller.m
    % and Fig.7/Fig.8 of the paper), replace the block above with:
    %
    %   data = iddata(measuredAngle, appliedVoltage, Ts);
    %   sysID = tfest(data, 3, 2);      % 3 poles, 2 zeros -> matches Eq.2 order
    %   G_plant = tf(sysID);
    %
    % (System Identification Toolbox required.)

    if nargout == 0
        figure('Name','Open-loop step response (no controller)');
        step(G_plant);
        grid on;
        title('Open-loop finger response - unstable without a controller (paper Fig. 10)');
    end
end

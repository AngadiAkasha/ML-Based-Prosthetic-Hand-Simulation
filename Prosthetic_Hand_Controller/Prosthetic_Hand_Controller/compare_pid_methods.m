
function compare_pid_methods()
% COMPARE_PID_METHODS
% Compare five PID tuning methods on the same plant.
%
% Methods:
%   1. Ziegler-Nichols
%   2. Genetic Algorithm
%   3. Bayesian Optimization
%   4. Multiple-Shooting Optimization
%   5. Routh-Hurwitz optimization
%
% Outputs:
%   - Step response comparison
%   - Settling-time comparison
%   - Overshoot comparison
%   - PID gain comparison
%   - ComparisonResults.mat
%   - ComparisonResults.csv

    clc;
    close all;

    fprintf('=== Five PID Tuning Methods Comparison ===\n\n');

    %% 1. Initialize plant

    G = plant_modeling();

    methodNames = {
        'Ziegler-Nichols'
        'Genetic Algorithm'
        'Bayesian Optimization'
        'Multiple-Shooting'
        'Routh-Hurwitz'
    };

    methodFunctions = {
        'ZN'
        'GA'
        'BO'
        'MS'
        'ROUTH'
    };

    nMethods = numel(methodNames);

    Kp = nan(nMethods, 1);
    Ki = nan(nMethods, 1);
    Kd = nan(nMethods, 1);

    SettlingTime = nan(nMethods, 1);
    RiseTime = nan(nMethods, 1);
    Overshoot = nan(nMethods, 1);
    PeakTime = nan(nMethods, 1);
    Stable = false(nMethods, 1);

    closedLoopSystems = cell(nMethods, 1);
    errors = cell(nMethods, 1);

    %% 2. Run all five tuning methods

    for i = 1:nMethods

        fprintf('\n------------------------------------\n');
        fprintf('Method %d: %s\n', i, methodNames{i});
        fprintf('------------------------------------\n');

        try
            switch methodFunctions{i}

                case 'ZN'
                    [kp, ki, kd] = tune_zn(G);

                case 'GA'
                    [kp, ki, kd] = tune_ga(G);

                case 'BO'
                    [kp, ki, kd] = tune_bo(G);

                case 'MS'
                    [kp, ki, kd] = tune_ms_collocation(G);

                case 'ROUTH'
                    [kp, ki, kd] = tune_routh_pid(G);

            end

            gains = double([kp, ki, kd]);

            if numel(gains) ~= 3 || any(~isfinite(gains))
                error('Tuning method returned invalid PID gains.');
            end

            Kp(i) = gains(1);
            Ki(i) = gains(2);
            Kd(i) = gains(3);

            % Construct unity-feedback closed-loop system.
            C = pid(Kp(i), Ki(i), Kd(i));
            T = minreal(feedback(C * G, 1));

            closedLoopSystems{i} = T;

            % Never rank an unstable response as a successful result.
            if ~isstable(T)
                warning('%s produced an unstable closed-loop system.', ...
                    methodNames{i});
                errors{i} = 'Unstable closed-loop system';
                continue;
            end

            Stable(i) = true;

            % Calculate unit-step response metrics.
            info = stepinfo(T);

            SettlingTime(i) = info.SettlingTime;
            RiseTime(i) = info.RiseTime;
            Overshoot(i) = info.Overshoot;
            PeakTime(i) = info.PeakTime;

            fprintf('Kp             = %.6g\n', Kp(i));
            fprintf('Ki             = %.6g\n', Ki(i));
            fprintf('Kd             = %.6g\n', Kd(i));
            fprintf('Rise time      = %.6g s\n', RiseTime(i));
            fprintf('Settling time  = %.6g s\n', SettlingTime(i));
            fprintf('Overshoot      = %.4f %%\n', Overshoot(i));
            fprintf('Stable         = Yes\n');

        catch ME
            errors{i} = ME.message;

            warning('%s failed: %s', ...
                methodNames{i}, ME.message);
        end
    end

    %% 3. Display comparison table

    Results = table( ...
        methodNames, Kp, Ki, Kd, Stable, ...
        RiseTime, SettlingTime, Overshoot, PeakTime, ...
        'VariableNames', { ...
        'Method', 'Kp', 'Ki', 'Kd', 'Stable', ...
        'RiseTime_s', 'SettlingTime_s', ...
        'Overshoot_percent', 'PeakTime_s'});

    fprintf('\n\n========== COMPARISON RESULTS ==========\n');
    disp(Results);

    %% 4. Plot unit-step responses

    % Use a common simulation time based on the plant's dynamics.
    % The upper limit prevents excessively long plotting runs.
    t = linspace(0, 30, 1500);

    figure('Name', 'PID Step Response Comparison', ...
           'Color', 'w');

    hold on;
    grid on;

    responseCount = 0;
    legendNames = {};

    for i = 1:nMethods

        if ~Stable(i)
            continue;
        end

        try
            [y, tout] = step(closedLoopSystems{i}, t);

            y = squeeze(y);

            plot(tout, y(:), 'LineWidth', 1.5);

            responseCount = responseCount + 1;
            legendNames{responseCount} = methodNames{i};

        catch ME
            warning('Could not plot %s: %s', ...
                methodNames{i}, ME.message);
        end
    end

    yline(1, '--k', 'Target = 1');

    xlabel('Time (seconds)');
    ylabel('Normalized output');
    title('Closed-Loop Unit-Step Response');
    
    if responseCount > 0
        legend([legendNames, {'Target'}], ...
            'Location', 'best');
    end

    %% 5. Plot settling-time comparison

    figure('Name', 'Settling Time Comparison', ...
           'Color', 'w');

    valid = Stable & isfinite(SettlingTime);

    bar(SettlingTime(valid));
    grid on;

    set(gca, 'XTick', 1:sum(valid), ...
        'XTickLabel', methodNames(valid));

    xtickangle(25);
    ylabel('Settling time (seconds)');
    title('Settling Time Comparison');

    %% 6. Plot overshoot comparison

    figure('Name', 'Overshoot Comparison', ...
           'Color', 'w');

    valid = Stable & isfinite(Overshoot);

    bar(Overshoot(valid));
    grid on;

    set(gca, 'XTick', 1:sum(valid), ...
        'XTickLabel', methodNames(valid));

    xtickangle(25);
    ylabel('Overshoot (%)');
    title('Percentage Overshoot Comparison');

    %% 7. Plot PID gain comparison

    figure('Name', 'PID Gain Comparison', ...
           'Color', 'w');

    gainMatrix = [Kp, Ki, Kd];

    bar(gainMatrix);
    grid on;

    set(gca, 'XTick', 1:nMethods, ...
        'XTickLabel', methodNames);

    xtickangle(25);
    ylabel('Gain value');
    title('PID Gain Comparison');
    legend('Kp', 'Ki', 'Kd', 'Location', 'best');

    %% 8. Save results

    outputDir = fileparts(mfilename('fullpath'));

    if isempty(outputDir)
        outputDir = pwd;
    end

    save(fullfile(outputDir, 'ComparisonResults.mat'), ...
        'Results', 'Kp', 'Ki', 'Kd', 'Stable', ...
        'RiseTime', 'SettlingTime', 'Overshoot', ...
        'PeakTime', 'methodNames', 'closedLoopSystems', 'errors');

    writetable(Results, ...
        fullfile(outputDir, 'ComparisonResults.csv'));

    fprintf('\nResults saved:\n');
    fprintf('ComparisonResults.mat\n');
    fprintf('ComparisonResults.csv\n');

    %% 9. Identify best stable results

    valid = Stable & isfinite(SettlingTime) & ...
            isfinite(Overshoot);

    if any(valid)

        validIndices = find(valid);

        % This ranks by settling time first, then overshoot.
        ranking = table( ...
            methodNames(valid), ...
            SettlingTime(valid), ...
            Overshoot(valid), ...
            'VariableNames', ...
            {'Method', 'SettlingTime_s', 'Overshoot_percent'});

        ranking = sortrows(ranking, ...
            {'SettlingTime_s', 'Overshoot_percent'});

        fprintf('\n===== RANKING: SETTLING TIME FIRST =====\n');
        disp(ranking);

        fprintf(['Note: the ranking above prioritizes settling time. ', ...
            'Use overshoot and tracking error to make the final decision.\n']);

    else
        fprintf('\nNo successful stable controller was found.\n');
    end

    fprintf('\nComparison completed.\n');

end

% Create Fuzzy Inference System
fis = mamfis('Name', 'ThrottleControl');

% Define Input: Distance
fis = addInput(fis, [0 100], 'Name', 'Distance');
fis = addMF(fis, 'Distance', 'gaussmf', [10 0], 'Name', 'Near');    % Gaussian MF
fis = addMF(fis, 'Distance', 'gaussmf', [10 30], 'Name', 'Medium'); % Gaussian MF
fis = addMF(fis, 'Distance', 'gaussmf', [15 70], 'Name', 'Far');    % Gaussian MF

% Define Input: Speed
fis = addInput(fis, [0 120], 'Name', 'Speed');
fis = addMF(fis, 'Speed', 'sigmf', [0.1 30], 'Name', 'Slow');        % Sigmoidal MF
fis = addMF(fis, 'Speed', 'sigmf', [-0.1 60], 'Name', 'Medium');     % Sigmoidal MF (inverted slope)
fis = addMF(fis, 'Speed', 'sigmf', [-0.05 100], 'Name', 'Fast');     % Sigmoidal MF (gentler slope)

% Define Output: Throttle
fis = addOutput(fis, [0 100], 'Name', 'Throttle');
fis = addMF(fis, 'Throttle', 'trapmf', [0 0 10 30], 'Name', 'NoThrottle'); % Trapezoidal MF
fis = addMF(fis, 'Throttle', 'trapmf', [20 40 50 60], 'Name', 'LowThrottle'); % Trapezoidal MF
fis = addMF(fis, 'Throttle', 'trapmf', [50 70 80 90], 'Name', 'ModerateThrottle'); % Trapezoidal MF
fis = addMF(fis, 'Throttle', 'trapmf', [80 90 100 100], 'Name', 'HighThrottle'); % Trapezoidal MF

% Add Rules
ruleList = [
    1 1 1 1 1; % If Distance is Near AND Speed is Slow THEN No Throttle
    1 2 2 1 1; % If Distance is Near AND Speed is Medium THEN Low Throttle
    1 3 3 1 1; % If Distance is Near AND Speed is Fast THEN Moderate Throttle
    
    2 1 2 1 1; % If Distance is Medium AND Speed is Slow THEN Low Throttle
    2 2 3 1 1; % If Distance is Medium AND Speed is Medium THEN Moderate Throttle
    2 3 4 1 1; % If Distance is Medium AND Speed is Fast THEN High Throttle
    
    3 1 3 1 1; % If Distance is Far AND Speed is Slow THEN Moderate Throttle
    3 2 4 1 1; % If Distance is Far AND Speed is Medium THEN High Throttle
    3 3 4 1 1; % If Distance is Far AND Speed is Fast THEN High Throttle
];
fis = addRule(fis, ruleList);

% Evaluate for Crisp Inputs
input = [30 30]; % Distance = 30m, Speed = 30km/h
output = evalfis(fis, input);

% Display Results
disp(['Throttle Percentage: ', num2str(output), '%']);

% Visualizations
ruleview(fis);   % Rule Viewer
surfview(fis);   % Surface Viewer
mfedit(fis);     % Membership functions


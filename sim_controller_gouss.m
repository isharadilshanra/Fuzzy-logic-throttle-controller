clear; clc; close all;

%% Fuzzy Inference System (FIS) Design
fis = mamfis('Name', 'ThrottleController');

% Input: Distance to Obstacle
fis = addInput(fis, [0 100], 'Name', 'Distance');
fis = addMF(fis, 'Distance', 'gaussmf', [10 0], 'Name', 'Near');
fis = addMF(fis, 'Distance', 'gaussmf', [15 50], 'Name', 'Medium');
fis = addMF(fis, 'Distance', 'gaussmf', [20 100], 'Name', 'Far');

% Input: Speed
fis = addInput(fis, [0 120], 'Name', 'Speed');
fis = addMF(fis, 'Speed', 'gaussmf', [10 0], 'Name', 'Slow');
fis = addMF(fis, 'Speed', 'gaussmf', [20 60], 'Name', 'Medium');
fis = addMF(fis, 'Speed', 'gaussmf', [30 120], 'Name', 'Fast');

% Output: Throttle
fis = addOutput(fis, [0 100], 'Name', 'Throttle');
fis = addMF(fis, 'Throttle', 'gaussmf', [5 0], 'Name', 'Brake');
fis = addMF(fis, 'Throttle', 'gaussmf', [15 25], 'Name', 'Low');
fis = addMF(fis, 'Throttle', 'gaussmf', [20 50], 'Name', 'Moderate');
fis = addMF(fis, 'Throttle', 'gaussmf', [15 80], 'Name', 'High');

% Fuzzy Rules
ruleList = [
    1 3 1 1 1; % If Distance is Near AND Speed is Fast THEN Brake
    1 2 1 1 1; % If Distance is Near AND Speed is Medium THEN Brake
    1 1 1 1 1; % If Distance is Near AND Speed is Slow THEN Brake
    2 3 2 1 1; % If Distance is Medium AND Speed is Fast THEN Low Throttle
    2 2 2 1 1; % If Distance is Medium AND Speed is Medium THEN Low Throttle
    2 1 3 1 1; % If Distance is Medium AND Speed is Slow THEN Moderate Throttle
    3 3 3 1 1; % If Distance is Far AND Speed is Fast THEN Moderate Throttle
    3 2 4 1 1; % If Distance is Far AND Speed is Medium THEN High Throttle
    3 1 4 1 1; % If Distance is Far AND Speed is Slow THEN High Throttle
];
fis = addRule(fis, ruleList);

%% Simulation Parameters
dt = 0.1; % Time step (seconds)
time = 0:dt:20; % Simulation time
vehicle_pos = zeros(size(time)); % Vehicle position
vehicle_speed = 2.5; % Initial speed (m/s)
obstacle_pos = 30; % Obstacle position (m)
throttle = zeros(size(time)); % Throttle values
acceleration = 0; % Initial acceleration

% Constants
deceleration_rate_brake = -8; % Strong deceleration rate for braking

%% Simulation Loop
for t = 2:length(time)
    % Calculate Distance to Obstacle
    distance_to_obstacle = obstacle_pos - vehicle_pos(t-1);
    
    % Fuzzy Inference System Evaluation
    throttle(t) = evalfis([distance_to_obstacle, vehicle_speed * 3.6], fis); % Speed in km/h
    
    % Update Acceleration Based on Throttle
    if throttle(t) <= 5 % Brake Condition
        acceleration = deceleration_rate_brake; % Strong deceleration for braking
    elseif throttle(t) > 5
        acceleration = (throttle(t) / 100) * 2; % Proportional acceleration
    else
        acceleration = 0; % No acceleration
    end
    
    % Update Speed (Ensure it Doesn't Go Below 0)
    vehicle_speed = max(0, vehicle_speed + acceleration * dt);
    
    % Update Position
    vehicle_pos(t) = vehicle_pos(t-1) + vehicle_speed * dt;
    
    % Stop Simulation if Vehicle Reaches or Surpasses the Obstacle
    if vehicle_pos(t) >= obstacle_pos
        vehicle_pos(t:end) = obstacle_pos;
        break;
    end
end

%% Visualization

% Initial Map Setup
figure;
subplot(3, 1, 1);
plot(obstacle_pos, 0, 'rx', 'MarkerSize', 10, 'LineWidth', 2); hold on;
plot(vehicle_pos(1), 0, 'bo', 'MarkerSize', 8, 'LineWidth', 2);
xlim([0, obstacle_pos + 20]);
ylim([-1, 1]);
xlabel('Position (m)');
ylabel('Environment');
title('Initial Map Setup');
legend('Obstacle', 'Vehicle');

% Vehicle Position Over Time
subplot(3, 1, 2);
plot(time, vehicle_pos, 'b-', 'LineWidth', 2);
xlabel('Time (s)');
ylabel('Position (m)');
title('Vehicle Position Over Time');
grid on;

% Throttle and Speed Profiles
subplot(3, 1, 3);
yyaxis left;
plot(time, throttle, 'r-', 'LineWidth', 2);
ylabel('Throttle (%)');
yyaxis right;
plot(time, vehicle_speed, 'g-', 'LineWidth', 2);
ylabel('Speed (m/s)');
xlabel('Time (s)');
title('Throttle and Speed Profiles');
legend('Throttle');
grid on;

% Visualizations
ruleview(fis);   % Rule Viewer
surfview(fis);   % Surface Viewer
mfedit(fis);     % Membership functions

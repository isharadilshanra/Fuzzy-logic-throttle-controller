% Parameters
dt = 0.1; % Time step (s)
total_time = 20; % Total simulation time (s)
time_steps = total_time / dt; % Number of steps
obstacle_position = 100; % Position of the obstacle (m)

% Initial Conditions
vehicle_position = 0; % Initial position (m)
vehicle_speed = 50; % Initial speed (km/h) -> convert to m/s
vehicle_speed = vehicle_speed / 3.6; % Convert to m/s
throttle = 0; % Initial throttle percentage
acceleration_max = 2; % Max acceleration (m/s^2)
braking_max = -5; % Max braking (m/s^2)

% Fuzzy Logic Controller
fis = mamfis('Name', 'ThrottleControl');

% Define Input: Distance
fis = addInput(fis, [0 100], 'Name', 'Distance');
fis = addMF(fis, 'Distance', 'gaussmf', [10 0], 'Name', 'Near');
fis = addMF(fis, 'Distance', 'gaussmf', [10 30], 'Name', 'Medium');
fis = addMF(fis, 'Distance', 'gaussmf', [15 70], 'Name', 'Far');

% Define Input: Speed
fis = addInput(fis, [0 120], 'Name', 'Speed');
fis = addMF(fis, 'Speed', 'sigmf', [0.1 30], 'Name', 'Slow');
fis = addMF(fis, 'Speed', 'sigmf', [-0.1 60], 'Name', 'Medium');
fis = addMF(fis, 'Speed', 'sigmf', [-0.05 100], 'Name', 'Fast');

% Define Output: Throttle
fis = addOutput(fis, [0 100], 'Name', 'Throttle');
fis = addMF(fis, 'Throttle', 'trapmf', [0 0 10 30], 'Name', 'NoThrottle');
fis = addMF(fis, 'Throttle', 'trapmf', [20 40 50 60], 'Name', 'LowThrottle');
fis = addMF(fis, 'Throttle', 'trapmf', [50 70 80 90], 'Name', 'ModerateThrottle');
fis = addMF(fis, 'Throttle', 'trapmf', [80 90 100 100], 'Name', 'HighThrottle');

% Add Rules
ruleList = [
    1 3 1 1 1; % If Distance is Near AND Speed is Fast THEN No Throttle
    1 2 2 1 1; % If Distance is Near AND Speed is Medium THEN Low Throttle
    2 2 3 1 1; % If Distance is Medium AND Speed is Medium THEN Moderate Throttle
    2 1 4 1 1; % If Distance is Medium AND Speed is Slow THEN High Throttle
    3 1 4 1 1; % If Distance is Far AND Speed is Slow THEN High Throttle
    3 2 4 1 1; % If Distance is Far AND Speed is Medium THEN High Throttle
];
fis = addRule(fis, ruleList);

% Simulation
position_history = zeros(1, time_steps);
speed_history = zeros(1, time_steps);
throttle_history = zeros(1, time_steps);
distance_to_obstacle = zeros(1, time_steps);

for t = 1:time_steps
    % Calculate distance to obstacle
    distance = obstacle_position - vehicle_position;
    if distance <= 0
        break; % Stop if collision or obstacle is reached
    end
    distance_to_obstacle(t) = distance;

    % Evaluate Fuzzy Controller
    input = [distance vehicle_speed * 3.6]; % Speed converted back to km/h
    throttle = evalfis(fis, input);
    throttle_history(t) = throttle;

    % Calculate Acceleration
    if throttle > 50
        acceleration = (throttle / 100) * acceleration_max; % Acceleration
    else
        acceleration = (throttle / 100) * braking_max; % Braking
    end

    % Update Speed and Position
    vehicle_speed = max(vehicle_speed + acceleration * dt, 0); % Speed can't be negative
    speed_history(t) = vehicle_speed * 3.6; % Store speed in km/h
    vehicle_position = vehicle_position + vehicle_speed * dt;
    position_history(t) = vehicle_position;
end

% Plot Results
time = 0:dt:(length(position_history) - 1) * dt;

figure;
subplot(3, 1, 1);
plot(time, position_history, 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Position (m)');
title('Vehicle Position Over Time');

subplot(3, 1, 2);
plot(time, speed_history, 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Speed (km/h)');
title('Vehicle Speed Over Time');

subplot(3, 1, 3);
plot(time, throttle_history, 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Throttle (%)');
title('Throttle Output Over Time');

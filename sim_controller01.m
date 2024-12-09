% Fuzzy Logic Controller Setup
fis = mamfis('Name', 'ThrottleController');

% Input 1: Distance to Obstacle
fis = addInput(fis, [0 100], 'Name', 'Distance');
fis = addMF(fis, 'Distance', 'trimf', [0 0 50], 'Name', 'Near');
fis = addMF(fis, 'Distance', 'trimf', [25 50 75], 'Name', 'Medium');
fis = addMF(fis, 'Distance', 'trimf', [50 100 100], 'Name', 'Far');

% Input 2: Speed
fis = addInput(fis, [0 120], 'Name', 'Speed');
fis = addMF(fis, 'Speed', 'trimf', [0 0 60], 'Name', 'Slow');
fis = addMF(fis, 'Speed', 'trimf', [30 60 90], 'Name', 'Medium');
fis = addMF(fis, 'Speed', 'trimf', [60 120 120], 'Name', 'Fast');

% Output: Throttle
fis = addOutput(fis, [0 100], 'Name', 'Throttle');
fis = addMF(fis, 'Throttle', 'trimf', [0 0 0], 'Name', 'Low');
fis = addMF(fis, 'Throttle', 'trimf', [25 25 50], 'Name', 'Moderate');
fis = addMF(fis, 'Throttle', 'trimf', [50 70 90], 'Name', 'High');

% Define Fuzzy Rules
ruleList = [
    1 3 1 1 1; % If Distance is Near AND Speed is Fast THEN Low Throttle
    1 2 1 1 1; % If Distance is Near AND Speed is Medium THEN Low Throttle
    1 1 1 1 1; % If Distance is Near AND Speed is Slow THEN Low Throttle
    2 3 2 1 1; % If Distance is Medium AND Speed is Fast THEN Moderate Throttle
    2 2 2 1 1; % If Distance is Medium AND Speed is Medium THEN Moderate Throttle
    2 1 3 1 1; % If Distance is Medium AND Speed is Slow THEN High Throttle
    3 3 3 1 1; % If Distance is Far AND Speed is Fast THEN High Throttle
    3 2 3 1 1; % If Distance is Far AND Speed is Medium THEN High Throttle
    3 1 3 1 1; % If Distance is Far AND Speed is Slow THEN High Throttle
];
fis = addRule(fis, ruleList);

% Parameters for Simulation
map_length = 100; % Length of the 1D trajectory
obstacle_pos = map_length; % Obstacle at the end of the map
initial_speed = 30; % Initial speed in km/h
initial_pos = 0; % Initial position of the vehicle
dt = 0.1; % Time step in seconds
time_limit = 10; % Simulation time in seconds
deceleration_rate = -2; % Deceleration rate (m/s^2) when throttle is 0

% Initialize Variables
time = 0:dt:time_limit; % Time vector
vehicle_pos = zeros(size(time)); % Vehicle position
vehicle_speed = initial_speed / 3.6; % Convert initial speed from km/h to m/s
vehicle_pos(1) = initial_pos; % Start position
throttle = zeros(size(time)); % Throttle percentage

% Simulation Loop
for t = 2:length(time)
    % Calculate Distance to Obstacle
    distance_to_obstacle = obstacle_pos - vehicle_pos(t-1);
    
    % Fuzzy Inference System Evaluation
    throttle(t) = evalfis([distance_to_obstacle, vehicle_speed * 3.6], fis); % Speed in km/h
    
    % Update Acceleration Based on Throttle
    if throttle(t) > 0
        acceleration = throttle(t) * 0.01; % Proportional acceleration
    else
        acceleration = deceleration_rate; % Deceleration if throttle is zero
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

% Plot Results
figure;

% Subplot 1: Map Setup
subplot(3,1,1);
plot([0, map_length], [0, 0], 'k-', 'LineWidth', 2); hold on;
scatter(obstacle_pos, 0, 100, 'r', 'filled'); % Obstacle
scatter(vehicle_pos(1), 0, 100, 'b', 'filled'); % Initial Vehicle Position
title('Initial Map Setup');
xlabel('Position (m)');
ylabel('Trajectory');
legend('Trajectory', 'Obstacle', 'Vehicle');
axis([0 map_length -1 1]);

% Subplot 2: Vehicle Trajectory
subplot(3,1,2);
plot(time, vehicle_pos, 'b-', 'LineWidth', 2);
title('Vehicle Position vs. Time');
xlabel('Time (s)');
ylabel('Position (m)');
grid on;

% Subplot 3: Throttle Output
subplot(3,1,3);
plot(time, throttle, 'r-', 'LineWidth', 2);
title('Throttle Percentage vs. Time');
xlabel('Time (s)');
ylabel('Throttle (%)');
grid on;

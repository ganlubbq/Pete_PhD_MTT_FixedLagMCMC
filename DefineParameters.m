% Define constant parameters for target tracker execution

global Par;

% Set random seed
Par.rand_seed = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Flags                                                               %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Par.FLAG_ObsMod = 1;                % 0 = cartesian, 1 = polar,

Par.FLAG_DyingTargs = false;        % Targets die at random
Par.FLAG_AppearingTargs = false;    % Targets appear at random
Par.FLAG_InitTargs = true;          % Initialise targets at t=0 so they don't have to be sought

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Scene parameters                                                    %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Par.T = 50;                             % Number of frames
Par.P = 1; P = Par.P;                   % Sampling period
Par.Xmax = 500;                         % Scene limit (half side or radius depending on observation model)
Par.Vmax = 10;                          % Maximum velocity


Par.UnifVelDens = 1/(2*Par.Vmax)^2;             % Uniform density on velocity

if Par.FLAG_ObsMod == 0
    Par.UnifPosDens = 1/(2*Par.Xmax)^2;         % Uniform density on position
    Par.ClutDens = Par.UnifPosDens;             % Clutter density in observation space
elseif Par.FLAG_ObsMod == 1
    Par.UnifPosDens = 1/(pi*Par.Xmax^2);        % Uniform density on position
    Par.ClutDens = (1/Par.Xmax)*(1/(2*pi));     % Clutter density in observation space
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Scenario parameters                                                 %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Par.NumTgts = 5;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Target dynamic model parameters                                     %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Par.ProcNoiseVar = 1;                                                      % Gaussian process noise variance (random accelerations)
Par.A = [1 0 P 0; 0 1 0 P; 0 0 1 0; 0 0 0 1];                              % 2D transition matrix using near CVM model
Par.B = [P^2/2*eye(2); P*eye(2)];                                          % 2D input transition matrix (used in track generation when we impose a deterministic acceleration)
Par.Q = Par.ProcNoiseVar * ...
    [P^3/3 0 P^2/2 0; 0 P^3/3 0 P^2/2; P^2/2 0 P 0; 0 P^2/2 0 P];          % Gaussian motion covariance matrix (discretised continous random model)
%     [P^4/4 0 P^3/2 0; 0 P^4/4 0 P^3/2; P^3/2 0 P^2 0; 0 P^3/2 0 P^2];      % Gaussian motion covariance matrix (piecewise constant acceleration discrete random model)
Par.ExpBirth = 0.1;                                                        % Expected number of new targets in a frame (poisson deistributed)
Par.PDeath = 0.01;                                                          % Probability of a (given) target death in a frame
if ~Par.FLAG_DyingTargs, Par.PDeath = 0; end
if ~Par.FLAG_AppearingTargs, Par.ExpBirth = 0; end

Par.Qchol = chol(Par.Q);                                                   % Cholesky decompostion of Par.Q

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Observation model parameters                                        %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Par.ExpClutObs = 1000;                      % Number of clutter objects expected in scene - 1000 is dense for Xmax=500, 160 for Xmax=200
Par.PDetect = 0.75;                         % Probability of detecting a target in a given frame

if Par.FLAG_ObsMod == 0
    Par.ObsNoiseVar = 1;                % Observation noise variance
    Par.R = Par.ObsNoiseVar * eye(2);   % Observation covariance matrix
    Par.C = [1 0 0 0; 0 1 0 0];         % 2D Observation matrix
elseif Par.FLAG_ObsMod == 1
    Par.BearingNoiseVar = 1E-4;                                 % Bearing noise variance
    Par.RangeNoiseVar = 1;                                      % Range noise variance
    Par.R = [Par.BearingNoiseVar 0; 0 Par.RangeNoiseVar];       % Observation covariance matrix
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Algorithm parameters                                                %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Par.L = 7;                              % Length of rolling window
Par.S = 5;                              % Max distance previously from which particles are sampled
Par.NumIt = 2500;                        % Number of iterations
Par.Restart = 10000;

Par.BurnIn = floor(0.1*Par.NumIt);      % Length of burn-in

Par.Vlimit = 1.5*Par.Vmax;              % Limit above which we do not accept velocity (lh=0)
Par.KFInitVar = 1E-20;                  % Variance with which to initialise Kalman Filters (scaled identity matrix)

Par.PRemove = 0;                        % Probability of attempting to remove a track
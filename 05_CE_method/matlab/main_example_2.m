%% Cross entropy method: Ex. 2 Ref. 2 - linear function of independent exponential
%{
---------------------------------------------------------------------------
Created by:
Sebastian Geyer (s.geyer@tum.de)
Matthias Willer (matthias.willer@tum.de)
Engineering Risk Analysis Group   
Technische Universitat Munchen
www.era.bgu.tum.de
---------------------------------------------------------------------------
Version 2018-03
---------------------------------------------------------------------------
Based on:

---------------------------------------------------------------------------
%}
clear; close all; clc;

%% definition of the random variables
d      = 100;         % number of dimensions
pi_pdf = repmat(ERADist('exponential','PAR',1),d,1);   % n independent rv

% correlation matrix
% R = eye(n);   % independent case

% object with distribution information
% pi_pdf = ERANataf(pi_pdf,R);    % if you want to include dependence

%% limit-state function
Ca = 140;
g  = @(x) Ca - sum(x);

%% CE-method
N   = 1000;         % Total number of samples for each level
rho = 0.1;          % Probability of each subset, chosen adaptively

fprintf('CE-based IS stage: \n');
% [Pr, l, N_tot, gamma_hat, samplesU, samplesX, k_fin] = CEIS_SG(N,rho,g,pi_pdf);     % single gaussian 
[Pr, l, N_tot, gamma_hat, samplesU, samplesX, k_fin] = CEIS_GM(N,rho,g,pi_pdf);    % gaussian mixture
% [Pr, l, N_tot, gamma_hat, samplesU, samplesX, k_fin] = CEIS_vMFNM(N,rho,g,pi_pdf); % adaptive vMFN mixture


% exact solution
lambda   = 1;
pf_ex    = 1 - gamcdf(Ca,d,lambda);
Pf_exact = @(gg) 1-gamcdf(Ca-gg,d,lambda);
gg       = 0:0.1:30;

% show p_f results
fprintf('\n***Exact Pf: %g ***', pf_ex);
fprintf('\n***CEIS Pf: %g ***\n\n', Pr);

%%END
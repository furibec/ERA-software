function [mu, si, pi] = EMGM(X,W,nGM)
% Perform soft EM algorithm for fitting the Gaussian mixture model.
%   X: d x N data matrix (dimensions x Number of samples)
%   W: N x 1 vector of sample weights
%   nGM: Number of Gaussians in the mixture
                             

%% initialization
R = initialization(X,nGM);

tol       = 1e-5;
maxiter   = 500;
llh       = -inf(1,maxiter);
converged = false;
t         = 1;

%% soft EM algorithm
while ~converged && t < maxiter
    
    [~,label(:)] = max(R,[],2);
    u = unique(label);   % non-empty components
    if size(R,2) ~= size(u,2)
        R = R(:,u);   % remove empty components
    elseif t>1
        converged = abs(llh(t)-llh(t-1)) < tol*abs(llh(t));
    end
    t = t+1;   

    
    [mu, si, pi] = maximization(X, W, R);
    [R, llh(t)] = expectation(X, W, mu, si, pi);
end

if converged
    fprintf('Converged in %d steps.\n',t-1);
else
    fprintf('Not converged in %d steps.\n',maxiter);
end

return;
%% END EMGM ----------------------------------------------------------------

% --------------------------------------------------------------------------
% Initialization with k-means algorithm 
% --------------------------------------------------------------------------
function R = initialization(X, nGM)
   
% Initialization with k-means algorithm 
idx = kmeans(X',nGM,'Replicates',10);
R   = dummyvar(idx);
return;

% --------------------------------------------------------------------------
% ...
% --------------------------------------------------------------------------
function [R, llh] = expectation(X, W, mu, si, pi)

n = size(X,2);
k = size(mu,2);

logpdf = zeros(n,k);
for i = 1:k
    logpdf(:,i) = loggausspdf(X,mu(:,i),si(:,:,i));
end

logpdf = bsxfun(@plus,logpdf,log(pi));
T = logsumexp(logpdf,2);
llh = sum(W.*T)/sum(W);
logR = bsxfun(@minus,logpdf,T);
R = exp(logR);
return;

% --------------------------------------------------------------------------
% ...
% --------------------------------------------------------------------------
function [mu, Sigma, w] = maximization(X,W,R)
R = repmat(W,1,size(R,2)).*R;
[d,~] = size(X);
k = size(R,2);

nk = sum(R,1);
w = nk/sum(W);
mu = bsxfun(@times, X*R, 1./nk);

Sigma = zeros(d,d,k);
sqrtR = sqrt(R);
for i = 1:k
    Xo = bsxfun(@minus,X,mu(:,i));
    Xo = bsxfun(@times,Xo,sqrtR(:,i)');
    Sigma(:,:,i) = Xo*Xo'/nk(i);
    Sigma(:,:,i) = Sigma(:,:,i)+eye(d)*(1e-6); % add a prior for numerical stability
end

return;

% --------------------------------------------------------------------------
% ...
% --------------------------------------------------------------------------
function y = loggausspdf(X, mu, Sigma)
d = size(X,1);
X = bsxfun(@minus,X,mu);
[U,~]= chol(Sigma);
Q = U'\X;
q = dot(Q,Q,1);  % quadratic term (M distance)
c = d*log(2*pi)+2*sum(log(diag(U)));   % normalization constant
y = -(c+q)/2;
return;

% --------------------------------------------------------------------------
% ...
% --------------------------------------------------------------------------
function s = logsumexp(x, dim)
% Compute log(sum(exp(x),dim)) while avoiding numerical underflow.
%   By default dim = 1 (columns).
% Written by Michael Chen (sth4nth@gmail.com).
if nargin == 1
    % Determine which dimension sum will use
    dim = find(size(x)~=1,1);
    if isempty(dim), dim = 1; end
end

% subtract the largest in each column
y = max(x,[],dim);
x = bsxfun(@minus,x,y);
s = y + log(sum(exp(x),dim));
i = find(~isfinite(y));
if ~isempty(i)
    s(i) = y(i);
end
return;
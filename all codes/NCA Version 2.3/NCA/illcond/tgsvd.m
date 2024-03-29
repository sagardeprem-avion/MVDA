function [x_k,rho,eta] = tgsvd(U,sm,X,b,k) 
%TGSVD Truncated GSVD regularization. 
% 
% [x_k,rho,eta] = tgsvd(U,sm,X,b,k) ,  sm = [sigma,mu] 
% 
% Computes the truncated GSVD solution 
%            [ 0              0                 0    ] 
%    x_k = X*[ 0  inv(diag(sigma(p-k+1:p)))     0    ]*U'*b . 
%            [ 0              0             eye(n-p) ] 
% If k is a vector, then x_k is a matrix such that 
%    x_k = [ x_k(1), x_k(2), ... ] . 
% 
% The solution and residual norms are returned in eta and rho. 
 
% Reference: P. C. Hansen, "Regularization, GSVD and truncated GSVD", 
% BIT 29 (1989), 491-504. 
 
% Per Christian Hansen, IMM, 12/21/97. 
 
% Initialization. 
n = size(X,1); p = length(sm(:,1)); lk = length(k); 
if (min(k)<0 | max(k)>p) 
  error('Illegal truncation parameter k') 
end 
x_k = zeros(n,lk); 
eta = zeros(lk,1); rho = zeros(lk,1); 
beta = U(:,1:n)'*b; 
xi = beta(1:p)./sm(:,1); 
 
% Treat each k separately. 
if (p==n) 
  x_0 = zeros(n,1); 
else 
  x_0 = X(:,p+1:n)*(U(:,p+1:n)'*b); 
end 
for j=1:lk 
  i = k(j); pi1 = p-i+1; 
  if(i==0) 
    x_k(:,j) = x_0; 
  else 
    x_k(:,j) = X(:,pi1:p)*xi(pi1:p) + x_0; 
 end 
  if (nargout>1), rho(j) = norm(beta(1:p-i)); end 
  if (nargout==3), eta(j) = norm(x_k(:,j)); end 
end 
 
if (nargout > 1 & size(U,1) > p) 
   rho = sqrt(rho.^2 + norm(b - U(:,1:n)*beta)^2); 
end
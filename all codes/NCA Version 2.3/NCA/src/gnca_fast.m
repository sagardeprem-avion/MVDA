% (c) 2005 University of California Los Angeles, All Rights Reserved.
% The NCA Toolbox was written by Simon J Galbraith (sgalbrai@cs.ucla.edu)
% and Linh Tran (ltran@seas.ucla.edu).
%
% GNCA_CC - Generalized Network Component Analysis.  Checking third
%           criterion during iteration
%
% [A,P]= GNCA(E,A0,P0) - computes the sparse decomposition E = A*P by using 
%     the EM algorithm, where the sparsity pattern specified by the input 
%     argument 'A0' and 'P0' are preserved.
%    
%     Parameters
%     ----------
%
%        E - Log-ratio gene expression levels matrix, from cDNA microarray
%            data. Each row of E contains the expression levels for a given
%             gene. Size= [NxM].
%
%        A - This matrix relates the level of transcriptional regulators 
%            with the gene expression levels. Size= [NxL]. 
%            The input 'A0' provides the following information:
%
%           1. Initial guess for 'A'
%           2. Sparsity pattern to be preserved
%
%        P - matrix of transcriptional regulators levels. Size= [LxM]
%            The input 'P0' provides the following information:
%
%           1. Initial guess for 'P'
%           2. Sparsity pattern to be preserved
% ------------------------------------------------------------------------------------------
% Last revision August 24, 2005
% Check condition of reduced matrices P during iteration (Condition 3).
% If the third condition is violated, new random initial guesses is used,
% and iteration starts over.
% ------------------------------------------------------------------------------------------

function [A,P,iter,ss]= gnca_fast(E,A0,P0)

% Input parameter check
if (nargin < 2)
    error('Usage: [A,P]= gnca_fast(E,A0,P0)');
end

if (nargin < 3 | isempty(P0))
    flag = 3;      %forward NCA
else
    flag = 1;
end


% Variable initialization
[N,M]= size(E);
L= size(A0,2);

if (size(A0,1) ~= N)
    error('The matrices E and A0 must have the same number of rows.');
end

A= rand(size(A0)).*A0;
%for i=1:size(A0,1),
%  z=find(A0(i,:)~=0);  
%  for j=1:z,
%      A(i,j)=rand();
%  end
%end


if flag  == 3
    P0= rand(L,M);
    P=P0;
else
    P=P0;
end

%Check the rank condition
R= RC1(A0,P0);   % --> initialize rank of the augmented sparse system
if (R < L*(L-1))
        fprintf(1,'\n\nWarning: rank(B) < # L*(L-1)\n');
        error('The system specified by ''A0'' and ''P0'' is NOT identifiable. Abort.');
end

% Parameters and constraints for the EM algorithm
epsl= 1.0e-5;           % --> convergence threshold
%stopeval=1.0e3;         %stop evaluation afer iteration >stopeval

% Identify the sparsity pattern of 'alpha'
sp_patternA = sign(A0);
sp_patternP = sign(P0);

% EM algorithm - main loop
delta_ssr_rel= 1.0;
ssr_old=0;
ssr= 1e6; 
iter = 1;
ss=[];
c=50;
while (abs(ssr_old -ssr) > epsl)  % & (iter < stopeval)
    % Step 1 - Re-estimation of 'P'
    R= RC1(A,P);   % Check the 2nd criterion
    if (R < L*(L-1))
        A=rand(N,L).*sp_patternA;   %if it is violated, start over
    end
    for k = 1:M
        index_P = find(sp_patternP(:,k) ~=0);
        A_red = A(:,index_P);
        P(index_P,k)= A_red\E(:,k);
    end
    
    % Step 2 - Re-estimation of 'A' solving a sequence of least squares problems
    f=0;  %flag for the 3rd criterion
    n=1;
    c=50;
    while (f==0 & n<=N)
        % Build the low-dimension least square problem for the n_th gene
        index_A = find(sp_patternA(n,:) ~= 0);
        P_red= P(index_A,:); 
        cP_red=cond(P_red);
        nTFs=length(index_A);
       
        if cP_red > c*nTFs
            A(n,index_A).*rand(size(A(n,index_A)));
            %A=rand(N,L).*sp_patternA;
            f=1;  %exit loop for fast approximation.
            %c=c+50;
        else
            A(n,index_A)= E(n,:)/P_red;
            n=n+1;           
        end
    end
    iter = iter + 1;
    % (c) - Evaluate the current mismatch
    err = E-A*P;
    ssr_old = ssr;
    ssr = sum(abs(err(:)));
    ss=[ss;ssr];
    delta_ssr_rel= abs(ssr_old - ssr)/ssr_old;
    if 0==mod(iter,1000), 
        fprintf(1,'ssr= %.8f, delta_ssr_rel=%.10f\n',ssr,delta_ssr_rel);
    end
    
end
%-----------------------------------------------------------
function R=RC1(A0,P0)

% RC - Checks the rank of the augmented system matrix after pruning for
%       non-zero entries in A and P.
% 
%  R = RC(A0,P0) - Returns the rank of B form from A0 and P0 after pruning rows and columns
%                  of corresponding nonzero entries in A0 and P0 respectively
% Note that condition number is used instead of matlab rank function
%
%Linh Tran, UCLA.  Last reversion August 24, 2005.

L=size(A0,2);

if (size(P0,1) ~= L)
    error('The number of columns of A0 must be equal to the same number of rows of P0.');
end

if (rank(A0)<L)
    error('A0 is not full column rank.');
end

R= 0;   % --> initialize rank of the augmented sparse system
%nz= 0;  % --> initialize total # of zeros in the augmented system

for l = 1:L
    B=[];
    %Construct reduced matrix P
    pr = [];
    for i = 1:L
        nr = 0;
        if i ~= l
            r = find(P0(i,:) == 0);
            nr = length(r);
            pl = zeros(nr,L);
            pl(:,i)=P0(l,r)';
            %nz=nz+nr;
            pr=[pr;pl];    
        end;         
    end

    v= find(A0(:,l)==0);
    B=[A0(v,:);pr];
    %nz= nz+length(v);
    if l==1
        B=B(:,2:L);
    else
        B=B(:,[1:l-1 l+1:L]);
    end
    c=cond(B);
    if c>1E7
        rank_=L-2;
    else
        rank_=L-1;
    end
    R= R+ rank_;
end
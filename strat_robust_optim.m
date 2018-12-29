function  [x_optimal, cash_optimal, w] = strat_robust_optim(x_init, cash_init, mu, Q, cur_prices, period, init_value)
n = length(x_init);
 
% Initial portfolio ("equally weighted" or "1/n") 
w0 =cur_prices'.*x_init./(cur_prices*x_init); 
ret_init = dot(mu, w0); % 1/n portfolio return 
var_init = w0' * Q * w0; % 1/n portfolio variance 


% Bounds on variables 
A=ones(1,n);
b=1;
lb_rMV = zeros(n,1); ub_rMV = inf*ones(n,1); 
% Target portfolio return estimation error 

var_matr = diag(diag(Q)); 
rob_init = w0' * var_matr * w0; % r.est.err. of 1/n portf 
rob_bnd = rob_init; % target return estimation error 
% Compute minimum variance portfolio (MVP) 
cplex_minVar = Cplex('MinVar');
cplex_minVar.addCols(zeros(1,n)', [], lb_rMV, ub_rMV);
cplex_minVar.addRows(1, ones(1,n), 1);
cplex_minVar.Model.Q = 2*Q;
cplex_minVar.Param.qpmethod.Cur = 7;
cplex_minVar.DisplayFunc = []; % disable output to screen
cplex_minVar.solve();
cplex_minVar.Solution;
w_minVar = cplex_minVar.Solution.x; % asset weights
ret_minVar = dot(mu, w_minVar);
var_minVar = w_minVar' * Q * w_minVar;
rob_minVar = w_minVar' * var_matr * w_minVar;
% Target portfolio return = return of MVP 
Portf_Retn = ret_minVar; 

% Formulate and solve robust mean-variance problem 
f_rMV = zeros(n,1); % objective function 
% Constraints 
A_rMV = sparse([ mu'; ones(1,n)]); lhs_rMV = [Portf_Retn; 1]; rhs_rMV = [inf; 1]; 
% Create CPLEX model 
cplex_rMV = Cplex('Robust_MV'); 
cplex_rMV.addCols(f_rMV, [], lb_rMV, ub_rMV); 
cplex_rMV.addRows(lhs_rMV, A_rMV, rhs_rMV); 

% Add quadratic objective 
cplex_rMV.Model.Q = 2*Q; 
% Add quadratic constraint on return estimation error (robustness constraint) 
Qq_rMV = var_matr;
cplex_rMV.addQCs(zeros(size(f_rMV)), var_matr, 'L', rob_bnd, {'qc_robust'}); 
% Solve 
% Set CPLEX parameters
cplex_rMV.Param.threads.Cur = 4;
cplex_rMV.Param.timelimit.Cur = 60;
cplex_rMV.Param.barrier.qcpconvergetol.Cur = 1e-12; % solution tolerance
cplex_rMV.DisplayFunc = []; % disable output to screen
cplex_rMV.solve();   
cplex_rMV.Solution;
if(isfield(cplex_rMV.Solution, 'x'))
    w_rMV = cplex_rMV.Solution.x;
    card_rMV = nnz(w_rMV);
    ret_rMV  = dot(mu, w_rMV);
    var_rMV = w_rMV' * Q * w_rMV;
    rob_rMV = w_rMV' * var_matr * w_rMV;
end

% Round near-zero portfolio weights
w_rMV_nonrnd = w_rMV;
w_rMV(find(w_rMV<=1e-6)) = 0;
w_rMV = w_rMV / sum(w_rMV);
[w_rMV_nonrnd w_rMV];

w=w_rMV;

%Calculating portfolio value for 
port_value = (cur_prices*x_init);
x_optimal = (((w') * port_value)./ cur_prices)' ;  
   
%cash account function 
cash_optimal = cash_acc(x_optimal, cur_prices, x_init, cash_init);
      
 
end

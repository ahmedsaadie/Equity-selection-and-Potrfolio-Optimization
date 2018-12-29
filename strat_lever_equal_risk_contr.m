function  [x_optimal, cash_optimal, w] = strat_lever_equal_risk_contr(x_init, cash_init, mu, Q, cur_prices, period, init_value)

global Q A_eq A_ineq
warning('off');

n = length(x_init);  
% Equality constraints 
A_eq = ones(1,n); b_eq = 1; 
% Inequality constraints 
A_ineq = []; b_ineql = []; b_inequ = []; 

% Define initial portfolio ("1/n portfolio") 
w0 = cur_prices'.*x_init./(cur_prices*x_init);

 options.lb = zeros(1,n); % lower bounds on variables
 options.lu = ones (1,n); % upper bounds on variables 
 options.cl = [b_eq' b_ineql']; % lower bounds on constraints 
 options.cu = [b_eq' b_inequ']; % upper bounds on constraints 
 
 % Set the IPOPT options 
 options.ipopt.jac_c_constant = 'yes'; 
 options.ipopt.hessian_approximation = 'limited-memory'; 
 options.ipopt.mu_strategy = 'adaptive'; 
 options.ipopt.tol = 1e-10; 
 options.ipopt.print_level=0;
 
 % The callback functions 
 funcs.objective = @computeObjERC; 
 funcs.constraints = @computeConstraints; 
 funcs.gradient = @computeGradERC; 
 funcs.jacobian = @computeJacobian; 
 funcs.jacobianstructure = @computeJacobian; 

% Run IPOPT
[wsol info] = ipopt(w0',funcs,options);

% Make solution a column vector
if(size(wsol,1)==1)
    w_erc = wsol';
else
    w_erc = wsol;
end

w = w_erc;


%Calculating portfolio value for 
port_value = (cur_prices*x_init)*2;
x_optimal = (((w') * port_value)./ cur_prices)' ;  

%cash account function 
cash_optimal = (cash_acc(x_optimal, cur_prices, x_init, cash_init)) ;
      
end
clc;
clear all;
format long

% Input files
input_file_prices  = 'Daily_closing_prices.csv';

% Read daily prices
if(exist(input_file_prices,'file'))
  fprintf('\nReading daily prices datafile - %s\n', input_file_prices)
  fid = fopen(input_file_prices);
     % Read instrument tickers
     hheader  = textscan(fid, '%s', 1, 'delimiter', '\n');
     headers = textscan(char(hheader{:}), '%q', 'delimiter', ',');
     tickers = headers{1}(2:end);
     % Read time periods
     vheader = textscan(fid, '%[^,]%*[^\n]');
     dates = vheader{1}(1:end);
  fclose(fid);
  data_prices = dlmread(input_file_prices, ',', 1, 1);
else
  error('Daily prices datafile does not exist')
end

% Convert dates into array [year month day]
format_date = 'mm/dd/yyyy';
dates_array = datevec(dates, format_date);
dates_array = dates_array(:,1:3);

% Find the number of trading days in Nov-Dec 2014 and
% compute expected return and covariance matrix for period 1
day_ind_start0 = 1;
day_ind_end0 = length(find(dates_array(:,1)==2014));
cur_returns0 = data_prices(day_ind_start0+1:day_ind_end0,:) ./ data_prices(day_ind_start0:day_ind_end0-1,:) - 1;
mu = mean(cur_returns0)';
Q = cov(cur_returns0);

% Remove datapoints for year 2014
data_prices = data_prices(day_ind_end0+1:end,:);
dates_array = dates_array(day_ind_end0+1:end,:);
dates = dates(day_ind_end0+1:end,:);

% Initial positions in the portfolio
init_positions = [5000 950 2000 0 0 0 0 2000 3000 1500 0 0 0 0 0 0 1001 0 0 0]';



% Number of periods, assets, trading days
N_periods = 6*length(unique(dates_array(:,1))); % 6 periods per year
N = length(tickers);
N_days = length(dates);

% Initial value of the portfolio

init_value = data_prices(1,:) * init_positions;



fprintf('\nInitial portfolio value = $ %10.2f\n\n', init_value);

% Initial portfolio weights
w_init = (data_prices(1,:) .* init_positions')' / init_value;

%w_init = ones(20,1)*(1/20);


% Annual risk-free rate for years 2015-2016 is 2.5%
r_rf = 0.025;

% Number of strategies
strategy_functions = {'strat_buy_and_hold' 'strat_equally_weighted' 'strat_min_variance' 'strat_max_Sharpe' 'strat_equal_risk_contr' 'strat_lever_equal_risk_contr' 'strat_robust_optim'};
strategy_names     = {'Buy and Hold' 'Equally Weighted Portfolio' 'Mininum Variance Portfolio' 'Maximum Sharpe Ratio Portfolio' 'strat_equal_risk_contr' 'strat_lever_equal_risk_contr' 'strat_robust_optim' };
%N_strat = 1;  comment this in your code
N_strat = length(strategy_functions); % uncomment this in your code
fh_array = cellfun(@str2func, strategy_functions, 'UniformOutput', false);



 
 

for (period = 1:12)
   % Compute current year and month, first and last day of the period
   if(dates_array(1,1)==15)
       cur_year  = 15 + floor(period/7);
   else
       cur_year  = 2015 + floor(period/7);
   end
   cur_month = 2*rem(period-1,6) + 1;
   day_ind_start = find(dates_array(:,1)==cur_year & dates_array(:,2)==cur_month, 1, 'first');
   day_ind_end = find(dates_array(:,1)==cur_year & dates_array(:,2)==(cur_month+1), 1, 'last');
   fprintf('\nPeriod %d: start date %s, end date %s\n', period, char(dates(day_ind_start)), char(dates(day_ind_end)));

   % Prices for the current day
   cur_prices = data_prices(day_ind_start,:);
   
       
   % Execute portfolio selection strategies
      for(strategy = 1:N_strat)

      % Get current portfolio positions
      if(period==1)
         curr_positions = init_positions;
         curr_cash = 0;
         portf_value{strategy} = zeros(N_days,1);
         
              
      else
         curr_positions = x{strategy,period-1};
         
         curr_cash = cash{strategy,period-1};
      end

      % Compute strategy
      [x{strategy,period}, cash{strategy,period} , w{strategy, period}] = fh_array{strategy}(curr_positions, curr_cash, mu, Q, cur_prices,period, init_value);
      
       
         
         
      % Verify that strategy is feasible (you have enough budget to re-balance portfolio)
      % Check that cash account is >= 0
      % Check that we can buy new portfolio subject to transaction costs

      %%%%%%%%%%% Insert your code here %%%%%%%%%%%%
      b = (ones(20,39));
      % Compute portfolio value
      portf_value{strategy}(day_ind_start:day_ind_end) = data_prices(day_ind_start:day_ind_end,:) * x{strategy,period} + cash{strategy,period};
       
      fprintf('   Strategy "%s", value begin = $ %10.2f, value end = $ %10.2f\n', char(strategy_names{strategy}), portf_value{strategy}(day_ind_start), portf_value{strategy}(day_ind_end));
      
   end
      
   % Compute expected returns and covariances for the next period
   cur_returns = data_prices(day_ind_start+1:day_ind_end,:) ./ data_prices(day_ind_start:day_ind_end-1,:) - 1;
   mu = mean(cur_returns)';
   Q = cov(cur_returns);
  
end

k = figure ; 
plot( datetime(dates) ,  portf_value{1}(1:day_ind_end))
hold on 
plot( datetime(dates) ,  portf_value{2}(1:day_ind_end))
hold on
plot( datetime(dates) ,  portf_value{3}(1:day_ind_end))
hold on
plot( datetime(dates) ,  portf_value{4}(1:day_ind_end))
hold on 
plot( datetime(dates) ,  portf_value{5}(1:day_ind_end))
hold on 
plot( datetime(dates) ,  portf_value{6}(1:day_ind_end))
hold on 
plot( datetime(dates) ,  portf_value{7}(1:day_ind_end))
title("Portfolio Performance")
xlabel("Time") 
ylabel("Portfolio Value (in millions")
legend(strategy_names, 'Location','northwest','NumColumns',1)

hold off


y = [];
%for plotting 'weights vs time' for strategy 3 and 4 
 for (j = 1: N)    
    for (i = 1:N_periods)  
    y(i,j) =  w{3,i}(j,1);
    m (i,j) = w{4,i}(j,1);
    
   
   
    end 
    
   
 end
f = figure;


%plotting weights for min variance 
for (i = 1:N) 
       title(" Min Variance Weights")
        xlabel("Period") 
        ylabel("Individual Asset weights")    
        plot( (1:N_periods) ,  y(:,i), 'LineWidth', 1)
        
    
        if i==N
        hold off 
    
        else 
            hold on
        end 
    end 
    
g = figure;

%plotting weights for sharpe ratio        
for (i = 1:N) 
        title("SharpeRatioWeights")
        xlabel("Period") 
        ylabel("Individual Asset weights")
        plot( (1:N_periods) ,  m(:,i), 'LineWidth', 1)    
    
        if i==N
        hold off 
    
        else 
            hold on
        end 
end 


 
 
function  [x_optimal, cash_optimal, w] = strat_buy_and_hold(x_init, cash_init, mu, Q, cur_prices, period, init_value)
   
   x_optimal = x_init;
   
   %cash account function
   cash_optimal = cash_acc(x_optimal, cur_prices, x_init, cash_init);
   
   w=x_init;
   
   
   
   

end
 
function  [x_optimal, cash_optimal, w] = strat_equally_weighted(x_init, cash_init, mu, Q, cur_prices,period, init_value)
      
   Port_weights = ones(1,20)*(1/20);
   port_value =(cur_prices*x_init);
   x_optimal = ((Port_weights * port_value) ./ cur_prices)';
   w = Port_weights';
   
   cash_optimal = cash_acc(x_optimal, cur_prices, x_init, cash_init); 
      

end


function  [x_optimal, cash_optimal, w] = strat_min_variance(x_init, cash_init, mu, Q, cur_prices,period, init_value)


% Cplexfunction for calculating minvar weights
w_minVar = cplex_minvar(Q,mu,20); 

%uncomment for allowing short selling and comment the one above - 
%fcat function calculate min_variance without xi>0 constraint. 

%w_minVar = fact(mu, Q, 20,5);

%Calculating portfolio value for 
port_value = (cur_prices*x_init);
x_optimal = (((w_minVar') * port_value)./ cur_prices)' ;  
w = w_minVar  ;    




%cash account function 
cash_optimal = cash_acc(x_optimal, cur_prices, x_init, cash_init);
      
   
end

function  [x_optimal, cash_optimal, w] = strat_max_Sharpe(x_init, cash_init, mu, Q, cur_prices, period, init_value)
   
% Optimization problem data
lb = zeros(20,1);
ub = inf*ones(20,1);
A  = ones(1,20);
b  = 1;

% Compute minimum variance portfolio
cplex1 = Cplex('min_Variance');
cplex1.addCols(zeros(20,1), [], lb, ub);
cplex1.addRows(b, A, b);
cplex1.Model.Q = 2*Q;
cplex1.Param.qpmethod.Cur = 6; % concurrent algorithm
cplex1.Param.barrier.crossover.Cur = 1; % enable crossover
cplex1.DisplayFunc = []; % disable output to screen
cplex1.solve();

% Display minimum variance portfolio
w_minVar = cplex1.Solution.x;
var_minVar = w_minVar' * Q * w_minVar;
ret_minVar = mu' * w_minVar;
%fprintf ('Minimum variance portfolio:\n');
%fprintf ('Solution status = %s\n', cplex1.Solution.statusstring);
%fprintf ('Solution value = %f\n', cplex1.Solution.objval);
%fprintf ('Return = %f\n', sqrt(ret_minVar));
%fprintf ('Standard deviation = %f\n\n', sqrt(var_minVar));

% Compute maximum return portfolio
cplex2 = Cplex('max_Return');
cplex2.Model.sense = 'maximize';
cplex2.addCols(mu, [], lb, ub);
cplex2.addRows(b, A, b);
cplex2.Param.lpmethod.Cur = 6; % concurrent algorithm
cplex2.Param.barrier.crossover.Cur = 1; % enable crossover
cplex2.DisplayFunc = []; % disable output to screen
cplex2.solve();

% Display maximum return portfolio
w_maxRet = cplex2.Solution.x;
var_maxRet = w_maxRet' * Q * w_maxRet;
ret_maxRet = mu' * w_maxRet;
%fprintf ('Maximum return portfolio:\n');
%fprintf ('Solution status = %s\n', cplex2.Solution.statusstring);
%fprintf ('Solution value = %f\n', cplex2.Solution.objval);
%fprintf ('Return = %f\n', sqrt(ret_maxRet));
%fprintf ('Standard deviation = %f\n\n', sqrt(var_maxRet));

% Target returns
targetRet = linspace(ret_minVar,ret_maxRet,20);

% Compute efficient frontier
cplex3 = Cplex('Efficient_Frontier');
cplex3.addCols(zeros(20,1), [], lb, ub);
cplex3.addRows(targetRet(1), mu', inf);
cplex3.addRows(b, A, b);
cplex3.Model.Q = 2*Q;
cplex3.Param.qpmethod.Cur = 6; % concurrent algorithm
cplex3.Param.barrier.crossover.Cur = 1; % enable crossover
cplex3.DisplayFunc = []; % disable output to screen

w_front = [];
for i=1:length(targetRet)
    cplex3.Model.lhs(1) = targetRet(i);
    cplex3.solve();
    w_front = [w_front cplex3.Solution.x];
    var_front(i) = w_front(:,i)' * Q * w_front(:,i);
    ret_front(i) = mu' * w_front(:,i);
    sr_ratio (i) = ret_front(i)/ ((var_front(i)).^0.5);
end

%finding weights for max sharpe ratio 
    [M,L] = max(sr_ratio);
    r = w_front(:,L);
    w = r;
    
    port_value = (cur_prices*x_init);
    x_optimal = (((r') * port_value)./ cur_prices)' ;  
     
   cash_optimal = cash_acc(x_optimal, cur_prices, x_init, cash_init);
      
   
   
   

end
 

 

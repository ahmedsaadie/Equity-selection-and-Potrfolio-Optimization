
%UNTITLED20 Summary of this function goes here
%   Detailed explanation goes here
function cash_optimal = cash_acc(x_optimal, cur_prices, x_init, cash_init) 
    

    for (i = 1:20) 
       if x_optimal(i) > 0
           floor(x_optimal(i));
         else
          ceil(x_optimal(i));
       end
    end

    fees = (cur_prices*abs(x_init - x_optimal)*.005);
    buy_sell = (cur_prices*(x_init - x_optimal));
   
    cash_optimal = round(buy_sell - fees + cash_init); 

   
end


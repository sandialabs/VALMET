function [s,ceq] = form_shearlayer_constraint(c,x,y,sse)
% compute the sum-squared-error for a coefficient vector c and a 
% regression form y(x) = 1+c(1)*(1/(1+c(2)*x ^ c(3)) - 1).
% x,y are the original data.
% c is varied by function fmincon to find values for which s = 0.

ceq = [];
s = sum((form_shearlayer(c,x) - y).^2) - sse;

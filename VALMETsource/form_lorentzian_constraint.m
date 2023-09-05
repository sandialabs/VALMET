function [s,ceq] = form_lorentzian_constraint(c,x,y,sse)
% compute the sum-squared-error for a coefficient vector c and a 
% regression form y(x) = c(1) + c(2))/(1 + (x - c(3))^2)
% x,y are the original data.
% c is varied by function fmincon to find values for which s = 0.

ceq = [];
s = sum((form_lorentzian(c,x) - y).^2) - sse;

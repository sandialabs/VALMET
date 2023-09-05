function [s,ceq] = form110_constraint(c,x,y,sse)
% compute the sum-squared-error for a coefficient vector c and a 
% regression form y(x) = coef(2)*e^(coef(1)*x).
% x,y are the original data.
% c is varied by function fmincon to find values for which s = 0.

ceq = [];
s = sum((form110(c,x) - y).^2) - sse;

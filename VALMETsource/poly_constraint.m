function [s,ceq] = poly_constraint(c,x,y,sse)
% compute the sum-squared-error for a coefficient vector c and a 
% polynomial  c(n)*x^(n-1) + c(n-1)*x^(n-2) + ... + c(1).
% x,y are the original data.
% c is varied by function fmincon to find values for which s = 0.

ceq = [];
s = sum((polyval(c,x) - y).^2) - sse;

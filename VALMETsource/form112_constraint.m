function [s,ceq] = form112_constraint(c,x,y,sse)
% compute the sum-squared-error for a coefficient vector c and a 
% regression form log(y(x)) = c1*log(x) + c2       (log() is log base 10)
% x,y are the original data.
% c is varied by function fmincon to find values for which s = 0.

ceq = [];
s = sum((form112(c,x) - y).^2) - sse;

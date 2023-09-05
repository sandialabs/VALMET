function [s,ceq] = form111_constraint(c,x,y,sse)
% compute the sum-squared-error for a coefficient vector c and a 
% regression form y(x) = c2 * x^c1.
% x,y are the original data.
% c is varied by function fmincon to find values for which s = 0.

ceq = [];
s = sum((form111(c,x) - y).^2) - sse;

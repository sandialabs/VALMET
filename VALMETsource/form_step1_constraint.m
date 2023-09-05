function [s,ceq] = form_step1_constraint(c,x,y,sse)
% compute the sum-squared-error for a coefficient vector c and a 
% regression form y(x) = (c(1) + x ^ c(3))/(c(2) + x ^ c(3)).
% x,y are the original data.
% c is varied by function fmincon to find values for which s = 0.

ceq = [];
s = sum((form_step1(c,x) - y).^2) - sse;

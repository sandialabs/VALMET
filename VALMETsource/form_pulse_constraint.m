function [s,ceq] = form_pulse_constraint(c,x,y,sse)
% compute the sum-squared-error for a coefficient vector c and a 
% regression form y(x) = c(1) + c(2)*(1/(1 + exp(c(3)*(x-c(4)))) -
%                                    (1/(1 + exp(c(5)*(x-c(6)))) ).
% x,y are the original data.
% c is varied by function fmincon to find values for which s = 0.

ceq = [];
s = sum((form_pulse(c,x) - y).^2) - sse;
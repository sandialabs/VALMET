function [vals] = form109(coefs,x)
%  Regression form y(x) = a + b/(1 + c*x) 

vals = coefs(1) + coefs(2)./(1. + coefs(3).*x);

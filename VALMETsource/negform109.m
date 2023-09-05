function [vals] = negform109(coefs,x)
%  Negative of regression form y(x) = a + b/(1 + c*x) 

vals = - coefs(1) - coefs(2)./(1. + coefs(3).*x);
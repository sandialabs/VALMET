function [vals] = form110(coefs,x)
%  Regression form y(x) =c3 + c2*exp(c1*x) 

vals = coefs(3) + coefs(2).*exp(coefs(1)*x);
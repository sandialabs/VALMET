function [cval] = negpolyval(c,x)
%  Evaluate the negative of the polynomial 
%            c(n)*x^(n-1) + c(n-1)*x^(n-2) + ... + c(1)
%
cval = -polyval(c,x);

function [vals] = form_shearlayer(coefs,x)
%  Regression form y(x) = 1 + c1*(1/(1+c2*x^c3) -1)
%  where x > 0 if c3 < 0  or x >= 0 if c3 > 0.

vals = 1 + coefs(1) .* (1 ./ (1+coefs(2) .* x .^ coefs(3)) -1);

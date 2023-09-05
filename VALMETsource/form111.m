function [vals] = form111(coefs,x)
%  Regression form y(x) = c2 * x^c1
%  where x > 0  if  c1 < 0  or x >= 0 if c1 > 0.

vals = coefs(2) * x .^ coefs(1);

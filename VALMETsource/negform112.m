function [vals] = negform112(coefs,x)
%  Negative of regression form log(y(x)) = c1 * log(x) + c2   where x > 0.

vals = -coefs(1) * log10(x) - coefs(2);

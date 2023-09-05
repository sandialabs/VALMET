function [vals] = form112(coefs,x)
%  Regression form log(y(x)) = c1*log(x) + c2   (log() is log base 10)
%  where x > 0  if  c1 < 0  or x >= 0 if c1 > 0.

vals = coefs(1) * log10(x) + coefs(2);

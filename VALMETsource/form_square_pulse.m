function [vals] = form_square_pulse(coefs,x)
%  Regression form y(x) = c1 + c2*(1/(1+exp(c3*(x-c4))) -
%                                  1/(1+exp(c5*(x-c6))) )
% 
%  If six coefficents are sent, use all six.  If only two coefficients
%  are sent, use the last four send on a previous call.

global h_rb c3 c4 c5 c6;

c1 = coefs(1);
c2 = coefs(2);
if length(coefs) == 6
    c3 = coefs(3);
    c4 = coefs(4);
    c5 = coefs(5);
    c6 = coefs(6);
end
vals = c1 + c2*(1 ./ (1 + exp(c3.*(x-c4))) ...
                         -  1 ./ (1 + exp(c5.*(x-c6))) );
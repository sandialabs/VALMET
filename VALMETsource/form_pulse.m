function [vals] = form_pulse(coefs,x)
%  This is a revision of form_square_pulse with some scaling included:
%  Regression form 
%        y(x) = ymagn*(c1 + c2*(1/(1+exp(c3*c3c5magn*(x-c4*xmagn))) -
%                               1/(1+exp(c5*c3c5magn*(x-c6*xmagn))) ))
% 

global h_rb xmagn ymagn c3c5magn;

c1 = coefs(1);
c2 = coefs(2);
c3 = coefs(3);
c4 = coefs(4);
c5 = coefs(5);
c6 = coefs(6);
% Globals do not appear to pass from the main program to this routine, so
% save them on a special call with length(coefs) = 9:
if length(coefs) == 9
    xmagn = coefs(7);
    ymagn = coefs(8);
    c3c5magn = coefs(9);
end

vals = ymagn.*(c1 + c2.*(1 ./ (1 + exp(c3c5magn.*c3.*(x-c4*xmagn))) ...
                      -  1 ./ (1 + exp(c3c5magn.*c5.*(x-c6*xmagn))) ));
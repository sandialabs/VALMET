function regression_eqn = request_regression_eqn(ndims)
%  Offer choices for a regression equation.  The choices are grouped 
%  by the number of independent variables (dimensions).

%  Revision log:
%   4/19/06  HJI  Added y = a*x^b  (form111) and log(y) = a*log(x) + b 
%                 (form112).
%   4/26/06  HJI  Temporarily supressed the log(y)=a*log(x)+b choice
%                 (the coding is not completely correct yet).
%   7/02/06  HJI  Added square pulse regression fit.  
%   4/23/07  HJI  Added the Lorentzian fit.

h1 = figure('visible','on');
instr_string = 'Select a regression form y=f(x) for your data:'; 
if ndims == 1 
%  The first 8 choices are polynomials of degree 1 through 8:
    prefixes{1} = 'polynomial, degree = ';
    eqn{1} = '1 ';
    prefixes{2} = ' ';
    eqn{2} = '2 ';
    prefixes{3} = ' ';
    eqn{3} = '3 ';
    prefixes{4} = ' ';
    eqn{4} = '4 ';
    prefixes{5} = ' ';
    eqn{5} = '5 ';
    prefixes{6} = ' ';
    eqn{6} = '6 ';
    prefixes{7} = ' ';
    eqn{7} = '7 ';
    prefixes{8} = ' ';
    eqn{8} = '8 ';
%  Non-polynomial choices start here:
    prefixes{9} = ' hyperbola: ';
    eqn{9} = ' y = a + b/(1 + c*x)   ';
    prefixes{10} = ' exponential: ';
    eqn{10} = ' y = c + b*exp(a*x)   ';
    prefixes{11} = ' ';
    eqn{11} = ' y = b * x^a     ';
%    prefixes{12} = ' ';
%    eqn{12} = ' log(y) = a * log(x) + b';
%    prefixes{13} = ' for x >= 0 ';
%    eqn{13} = ' y = (a + x^c)/(b + x^c)  (step function: y approaches 1 at one end)';
    prefixes{12} = ' Fermi-Dirac function: ';
    eqn{12} = ' y = (a + x^c)/(b + x^c)  (for x >= 0, y approaches 1 at one end)';

    prefixes{13} = ' pulse function: ';
    eqn{13} = ' y = a + b*(1/(1+exp(c*(x-d))) - 1/(1+exp(e*(x-f))) ) ';

    prefixes{14} = ' Lorentz function: ';
    eqn{14} = ' y = a + b/(1 + ((x - c)/d)^2) ';
    
    prefixes{15} = ' Fermi-Dirac variant: ';
    eqn{15} = ' y = 1 + a*(1/(1+b*x^c) - 1)';
    
    regression_eqn = chooseonetextbutton_ps(instr_string,prefixes,eqn, ...
        h1,0.,0.9);
 
elseif ndims == 2
    eqn{1} = ' z = a + b*x + c*y    ';
    eqn{2} = ' z = a + b*x + c*x*y + d*y    ';
    regression_eqn = chooseonetextbutton(instr_string,eqn, h1,0.,0.9);
end 
pause(1);
close (h1);

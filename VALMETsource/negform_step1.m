function [vals,grad] = negform_step1(coefs,x)
%  Negative of regression form y(x) = (c1 + x^c3)/(c2 + x^c3)
%  where x > 0 if c3 < 0  or x >= 0 if c3 > 0.

%vals = -(coefs(1) + x ^ coefs(3)) ./ (coefs(2) + x ^ coefs(3));

vals = -(coefs(1) + x .^ coefs(3)) ./ (coefs(2) + x .^ coefs(3));
if nargout > 1  % function is called with two output arguments
% Compute the gradient evaluated at x
   grad = [-1 ./  (coefs(2) + x .^ coefs(3)), ...
    (coefs(1) + x .^ coefs(3)) ./ (coefs(2) + x .^ coefs(3)).^2, ...
    - (coefs(2)-coefs(1)) .* x.^ coefs(3) .* log(x) ./ ...
               (coefs(2) + x.^coefs(3)).^2]';

end
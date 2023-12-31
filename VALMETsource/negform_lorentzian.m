function [vals, grad] = negform_lorentzian(coefs,x)
%  Negative of regression form y(x) = c1 + c2/(1. + ((x - c3)/c4)^2)

vals = -coefs(1) - coefs(2) ./ (1 + ((x - coefs(3))./coefs(4)).^2);

if nargout > 1  % function is called with two output arguments
% Compute the gradient evaluated at x
   grad = [-1; ...
    -1 ./ (1 + ((x - coefs(3))./coefs(4)) .^ 2); ...
    -2*coefs(2) .* (x - coefs(3)) ./ ...
          (coefs(4) + (x - coefs(3)) .^2 ./coefs(4)).^2; ...
    -2*coefs(2) .* (x - coefs(3)) ./ ...
      (coefs(4) .* (coefs(4) + (x - coefs(3)) .^2 ./coefs(4)).^2) ];
end
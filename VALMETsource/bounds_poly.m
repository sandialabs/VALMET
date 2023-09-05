function [flower,fupper, flower_n,fupper_n,cc_l,cc_u,sse_l,sse_u] = ...
        bounds_poly(c0min,c0max,xpoints, xi,yi,sse, tolcon,tolfun)
%  procedure to find upper and lower bounds on a polynomial regression:
%    y = c(n)*x^(n-1) + c(n-1)*x^(n-2) + ... + c(2)*x + c(1)
%
%  Initial guesses for c(1),c(2),c(3), ..., c(n) are in arrays c0min and 
%  c0max.  
%  The extrema are returned in arrays flower and fupper. 
%
%  For convergence debugging purposes, the results for each initial guess 
%  are in flower_n and fupper_n, convergence points in cc_l and cc_u, and 
%  summed-squared-errors in sse_l and sse_u.   

%  Revision log:
%   4/23/07 HJI Modified to allow different numbers of initial guesses in 
%               c0min and c0max.    
%   5/21/07 HJI If nipl = 2 and c0min(2,:) = [0,0,0], then clower0(2,:) will
%               be set to the previous convergence point.
%               If nipu = 2 and c0max(2,:) = [0,0,0], then cupper0(2,:) will
%               be set to the previous convergence point.
%   9/09/07 HJI Added arguments tolcon and tolfun to get values from the
%               main program.

options = optimset('MaxFunEvals',5000,'MaxIter',5000, ...
        'LargeScale','off', 'TolCon',tolcon,'TolFun',tolfun);
%options = optimset('GradObj','on','MaxFunEvals',5000,'MaxIter',5000, ...
%        'LargeScale','off', 'TolCon',1.0E-6,'TolFun',1.0E-7);
  
tolcon = optimget(options,'tolcon')
tolfun = optimget(options,'tolFun')
%maxfevals = optimget(options,'MaxFunEvals');

np = length(xpoints);
flower = zeros(1,np);
fupper = zeros(1,np);

[nipu,ncoords] = size(c0max);
[nipl,ncoords] = size(c0min);
clower0 = c0min;
cc_l = zeros(nipl*np,ncoords);
flower_nip = zeros(1,nipl);
flower_n = zeros(1,nipl*np);
sse_l = zeros(1,nipl*np);
use_previous_lower = (nipl == 2 || nipl == 3) && ~any(c0min(2,:));
if (use_previous_lower)
   clower0(2,:) = clower0(1,:);
end

cupper0 = c0max;
cc_u = zeros(nipu*np,ncoords);
fupper_nip = zeros(1,nipu);
fupper_n = zeros(1,nipu*np);
sse_u = zeros(1,nipu*np);
use_previous_upper = (nipu == 2 || nipu == 3) && ~any(c0max(2,:));
if (use_previous_upper)
   cupper0(2,:) = cupper0(1,:);
end

% Try nipl lower and nipu upper initial coefficient guesses for each of np 
% x-values:
for i = 1:np;
   for j = 1:nipl
      flower_nip(j) = NaN;
      sse_l(j+(i-1)*nipl) = NaN;
      retry_count = 0;
      flag = 0;
      current_x_lower = xpoints(i)
      while isnan(flower_nip(j)) || isnan(sse_l(j+(i-1)*nipl)) || flag == 0
         [c_lower,fval,flag] = fmincon(@(c) polyval(c,xpoints(i)), ...
             clower0(j,:), [],[],[],[],[],[], ...
             @(c) poly_constraint(c,xi,yi,sse),options);
         flower_nip(j) = polyval(c_lower,xpoints(i));
         sse_l(j+(i-1)*nipl) = sumsqerr_poly(c_lower,xi,yi);
         if retry_count < 10
            if isnan(flower_nip(j)) || isnan(sse_l(j+(i-1)*nipl)) || flag == 0
               retry_count = retry_count + 1
               if c0min(j,:) == zeros(1,ncoords)
                  clower0(j,:) = 0.0909*(11-retry_count)*ones(1,ncoords);
               else
                  clower0(j,:) = 0.0909*(11-retry_count)*c0min(j,:);
               end
            end
         end
         if (use_previous_lower && j == 1 && i > 1)
            clower0(2,:) = cc_l(nipl*i-nipl,:);
         end
      end
%      lower_exit_flag = flag
      flower_n(j+(i-1)*nipl) = flower_nip(j); 
      cc_l(j+(i-1)*nipl,:) = c_lower;     
   end

   for j = 1:nipu
      fupper_nip(j) = NaN;
      sse_u(j+(i-1)*nipu) = NaN;
      retry_count = 0;
      flag = 0;
      current_x_upper = xpoints(i)
      while isnan(fupper_nip(j)) || isnan(sse_u(j+(i-1)*nipu)) || flag == 0
         [c_upper,fval,flag] = fmincon(@(c) negpolyval(c,xpoints(i)), ...
             cupper0(j,:), [],[],[],[],[],[], ...
             @(c) poly_constraint(c,xi,yi,sse),options);
         fupper_nip(j) = polyval(c_upper,xpoints(i));
         sse_u(j+(i-1)*nipu) = sumsqerr_poly(c_upper,xi,yi);          
         if retry_count < 10
            if isnan(fupper_nip(j)) || isnan(sse_u(j+(i-1)*nipu)) || flag == 0
               retry_count = retry_count + 1
               if c0max(j,:) == zeros(1,ncoords)
                  cupper0(j,:) = 0.0909*(11-retry_count)*ones(1,ncoords);
               else
                  cupper0(j,:) = 0.0909*(11-retry_count)*c0max(j,:);
               end
            end
         end
         if (use_previous_upper && j == 1 && i > 1)
            cupper0(2,:) = cc_u(nipu*i-nipu,:);
         end
      end
%      upper_exit_flag = flag
      fupper_n(j+(i-1)*nipu) = fupper_nip(j);
      cc_u(j+(i-1)*nipu,:) = c_upper;
   end
% Save the smallest flower and the largest fupper for each x-value:
   flower(i) = min(flower_nip);
   fupper(i) = max(fupper_nip);
end
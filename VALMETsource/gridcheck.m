function [dx1 xstart1 xstop1 nx1] = gridcheck(dx,xstart,xstop,nx,...
    xmin,xmax,changed)
%
dx1 = dx;
xstart1 = xstart;
xstop1 = xstop;
nx1 = nx;

if (xstart < xmin)
    xstart1 = xmin;
end
if (xstop > xmax) 
    xstop1 = xmax;
end

if (abs(xstop1-xstart1-(nx1-1)*dx1) < 1.e-4)
%  The parameters are ok, but improvements might be possible.
%   consistent = 1
   if ((changed(2) > 0 || changed(3)) > 0)
      return
   else
      if (changed(1) > 0 && changed(4) > 0)
         return
      end
% Allow a change in the the start and stop values and in the number of
% steps if the step size has been changed or if the number of steps 
% has not been changed
      if (changed(1) > 0 || changed(4) == 0) 
         xstart1 = dx1*ceil(xstart/dx1);
         xstop1 = dx1*floor(xstop/dx1);
         nx1 = fix((xstop1-xstart1)/dx1 + 1.0001);
      else
         dxmax = (xstop1-xstart1)/(nx1-1);
% keep only the first two significant digits of dxmax
         expon = floor(log10(dxmax));
         base = 10.^expon;
         dx1 =  0.01*base*fix(100*dxmax/base);
         xstart1 = dx1*ceil(xstart/dx1);
         xstop1 = dx1*floor(xstop/dx1);
         nx1 = fix((xstop1-xstart1)/dx1 + 1.0001);
      end
   end
else
% The parameters are not ok.  Change something.
%   inconsistent = 1
   if (isequal(changed,[1 1 1 1]) || changed(1) == 0)
      dx1 = (xstop1-xstart1)/(nx1-1);
   elseif (changed(3) == 0)
      if (xstart1 + (nx1-1)*dx1 >= xmax)
         nx1 = fix((xmax-xstart1)/dx1 + 1.0001);
      end
      xstop1 = xstart1 + (nx1-1)*dx1;
   elseif (changed(2) == 0)
      if (xstop1-(nx1-1)*dx1 <= xmin)
         nx1 = fix((xstop1-xmin)/dx1 + 1.0001);
      end
      xstart1 = xstop1 - (nx1-1)*dx1;          
   elseif (changed(4) == 0)
      nx1 = fix((xstop1 - xstart1)/dx1 + 1.0001);
      if (nx1 < 2)
         nx1 = 2;
         dx1 = (xstop1-xstart1);
      end
   end
end
%  end gridcheck

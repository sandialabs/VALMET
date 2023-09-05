function [coef] = baseline_step_levels(x,v)
% Compute approximate regression coefficients for a square pulse
%  x and v must be one-dimensional arrays.

np = length(x);
ndims = size(v);
if (ndims(1) == 1)
    vv = v';
else
    vv = v;
end
v_min = min(vv);
v_max = max(vv);
dv_10 = 0.9*v_min + 0.1*v_max;
dv_90 = 0.1*v_min + 0.9*v_max;
n1pct = int32(1 + 0.05*np);
% Estimate baseline from first and last 5% of points:
baseline = mean([vv(1:n1pct);vv(np-n1pct:np)]);
% Next, estimate the baseline and step using the points below/above
% dv_10 and below/above dv_90.

if abs(baseline - v_min) < abs(baseline - v_max)
    stepdir = +1;
    baseline =  mean(vv(logical(vv<dv_10)));
    steplevel = mean(vv(logical(vv>dv_90)));
else
    stepdir = -1;
    baseline  = mean(vv(logical(vv>dv_10)));
    steplevel = mean(vv(logical(vv<dv_90)));
end
midlevel = 0.5*(baseline + steplevel);

%  Average the midlevel crossing x-values before reaching steplevel to
%  estimate the midpoint of the first incline.
leadmid = 0.;
leadx10 = 0.;
leadx90 = 0.;
ncrossmid= 0;
ncross10 = 0;
ncross90 = 0;
i = 2;
while (vv(i)-steplevel)*stepdir < 0
   if (vv(i)-dv_10)*(dv_10-vv(i-1))> 0
      x10 = x(i-1)+(x(i)-x(i-1))*(dv_10-vv(i-1))/(vv(i)-vv(i-1));
      leadx10 = leadx10 + x10;
      ncross10 = ncross10 + 1;
   end
   if (vv(i)-midlevel)*(midlevel-vv(i-1))> 0
      xmid = x(i-1)+(x(i)-x(i-1))*(midlevel-vv(i-1))/(vv(i)-vv(i-1));
      leadmid = leadmid + xmid;
      ncrossmid = ncrossmid + 1;
   end
   if (vv(i)-dv_90)*(dv_90-vv(i-1))> 0
      x90 = x(i-1)+(x(i)-x(i-1))*(dv_90-vv(i-1))/(vv(i)-vv(i-1));
      leadx90 = leadx90 + x90;
      ncross90 = ncross90 + 1;
   end
   i = i+1;
end
leadx10 = leadx10/ncross10;
leadx90 = leadx90/ncross90;
leadmid = leadmid/ncrossmid;
leadslope = -6*(dv_90-dv_10)/(leadx90-leadx10)/(steplevel-baseline);

trailmid = 0.;
trailx10 = 0.;
trailx90 = 0.;
ncrossmid = 0;
ncross10  = 0;
ncross90  = 0;
while (vv(i)-baseline)*stepdir > 0
   if (vv(i)-dv_10)*(dv_10-vv(i-1))> 0
      x10 = x(i-1)+(x(i)-x(i-1))*(dv_10-vv(i-1))/(vv(i)-vv(i-1));
      trailx10 = trailx10 + x10;
      ncross10 = ncross10 + 1;
   end
   if (vv(i)-midlevel)*(midlevel-vv(i-1))> 0
      xmid = x(i-1)+(x(i)-x(i-1))*(midlevel-vv(i-1))/(vv(i)-vv(i-1));
      trailmid = trailmid + xmid;
      ncrossmid = ncrossmid + 1;
   end
   if (vv(i)-dv_90)*(dv_90-vv(i-1))> 0
      x90 = x(i-1)+(x(i)-x(i-1))*(dv_90-vv(i-1))/(vv(i)-vv(i-1));
      trailx90 = trailx90 + x90;
      ncross90 = ncross90 + 1;
   end
   i = i+1;
end
trailmid = trailmid/ncrossmid;
trailx10 = trailx10/ncross10;
trailx90 = trailx90/ncross90;
trailslope = 6*(dv_90-dv_10)/(trailx90-trailx10)/(steplevel-baseline);

coef(1) = baseline;
coef(2) = steplevel;
coef(3) = leadslope;
coef(4) = leadmid;
coef(5) = trailslope;
coef(6) = trailmid;
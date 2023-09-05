function [vstart,vstop,vtic] = roundbounds(vmin,vmax,frext)
%  Compute round number axis endpoints from data limits.
%  Inputs: vmin, vmax
%  Outputs: vstart, vstop, vtic (= a good tic mark spacing).
%  Revision log:
%   9/18/72 HJI Almost original version.
%   8/11/77 HJI Modified to allow 1 percent overrun at endpoints.
%  12/18/89 HJI Endpoints forced to some multiple of 10*vtic.
%  12/22/92 HJI Added error processing when VMIN=VMAX.
%   4/23/06 HJI Rewritten as a MATLAB script.  Replaced the one percent
%               overrun with input parameter frext to specify the fraction
%               of extension to be added to each end of the axis.

%  Error checking:
vmx = vmax;
if (vmin == vmax) 
    if (vmin < 0) 
        vmx = max(vmin+1,0.5*vmin)
    else
        vmx = max(vmin+1,1.5*vmin)
    end
end

del = frext*(vmx-vmin);
fexp = log10(abs(1+2*frext)*(vmx-vmin))-1;
nexp = fix(fexp - 0.1);
if fexp < 0
    nexp = nexp - 1;
end
vtic = 10 ^ nexp;
tt = 10*vtic;
vstart = vmin;
if (vmin*(vmin-del) > 0)
    vstart = tt*fix((vmin - del)/tt);
    if (vstart > vmin - del) 
        vstart = vstart - tt;
    end
else
% zero falls between vmin and vmin-del, so use vstart=0 instead of 
% vstart = vmin - del
    vstart = 0.;
end
vstop = vmx;
if (vmx*(vmx + del) > 0)
    vstop = tt*fix((vmx + del)/tt);
    if (vstop < vmx + del)
        vstop = vstop + tt;
    end
else
% zero falls between vmin and vmin-del, so use vstart=0 instead of 
% vstart = vmin - del
    vstart = 0.;
end

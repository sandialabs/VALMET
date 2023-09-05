function scalar = sumsqerr_pulse(coefs,xx,yy)
%
%
fit = form_pulse(coefs,xx);
errs = fit - yy;
scalar = errs'*errs;
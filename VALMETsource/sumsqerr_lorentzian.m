function scalar = sumsqerr_lorentzian(coefs,xx,yy)
%
%
fit = form_lorentzian(coefs,xx);
errs = fit - yy;
scalar = errs'*errs;
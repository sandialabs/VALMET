function scalar = sumsqerr_step1(coefs,xx,yy)
%
%
fit = form_step1(coefs,xx);
errs = fit - yy;
scalar = errs'*errs;
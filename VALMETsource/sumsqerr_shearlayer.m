function scalar = sumsqerr_shearlayer(coefs,xx,yy)
%
%
fit = form_shearlayer(coefs,xx);
errs = fit - yy;
scalar = errs'*errs;
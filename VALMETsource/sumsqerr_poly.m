function scalar = sumsqerr_poly(coefs,xx,yy)
%
%
fit = polyval(coefs,xx);
errs = fit - yy;
scalar = errs'*errs;
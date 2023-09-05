function scalar = sumsqerr111(coefs,xx,yy)
%
%
fit = form111(coefs,xx);
errs = fit - yy;
scalar = errs'*errs;
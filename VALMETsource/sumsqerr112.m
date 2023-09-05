function scalar = sumsqerr112(coefs,xx,yy)
%
%
fit = form112(coefs,xx);
errs = fit - yy;
scalar = errs'*errs;